# scenes/scene05_arduino.py — FAST SCAN (non-blocking), no hang, quick skip if not found
import time, sys, os, argparse
try:
    import serial, serial.tools.list_ports
except Exception:
    serial = None

from core.rt import fast_render, BRIGHT, DIM, HIDE, SHOW

BAUDS = [115200, 9600]   # probeer snelste eerst
HANDSHAKES = (b'H\n', b'H\r\n')

def list_candidates(prefer=''):
    prefer = (prefer or '').upper()
    out = []
    if serial is None: return out
    seen = set()
    for p in serial.tools.list_ports.comports():
        dev = p.device
        if dev in seen: continue
        seen.add(dev)
        score = 0
        if prefer and dev.upper() == prefer: score += 1000
        if getattr(p, 'vid', None) == 0x2341: score += 400  # Arduino
        if getattr(p, 'pid', None) in (0x0043, 0x7523): score += 200  # Uno/CH340
        if 'Bluetooth' in (p.description or ''): score -= 500
        out.append((dev, score, p.description or dev))
    out.sort(key=lambda r: (-r[1], r[0]))
    return out

def try_probe(dev, baud, per_port_deadline, notes):
    """Open non-blocking; kort wachten op UNO-reset; schrijf handshake; poll in_waiting (geen blok!)."""
    try:
        s = serial.Serial(dev, baudrate=baud, timeout=0, write_timeout=0, dsrdtr=True, rtscts=False)
    except Exception as e:
        notes.append(f"probe: {dev} @ {baud} → open fail: {e.__class__.__name__}")
        return None
    try:
        # UNO reset → kleine wacht, maar breek op deadline
        t0 = time.perf_counter()
        while time.perf_counter() - t0 < 0.6 and time.perf_counter() < per_port_deadline:
            time.sleep(0.02)
        s.reset_input_buffer()
        # 2 handshake varianten, korte polls
        for payload in HANDSHAKES:
            try:
                s.write(payload); s.flush()
            except Exception:
                pass
            t1 = time.perf_counter()
            while time.perf_counter() - t1 < 0.35 and time.perf_counter() < per_port_deadline:
                n = 0
                try: n = s.in_waiting
                except Exception: n = 0
                if n:
                    try:
                        resp = s.read(n).decode('utf-8','ignore')
                        if 'OK' in resp:
                            return s
                    except Exception:
                        pass
                time.sleep(0.02)
        # geen OK → close en fail
        try: s.close()
        except Exception: pass
        notes.append(f"probe: {dev} @ {baud} → geen OK")
        return None
    except Exception as e:
        try: s.close()
        except Exception: pass
        notes.append(f"probe: {dev} @ {baud} → {e.__class__.__name__}")
        return None

def hud(title, lines, bright):
    fast_render([f"  {title}", "", *lines, "", "keys: [q] quit"], BRIGHT if bright else DIM)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('-bpm', type=int, default=84)          # behouden (UI)
    ap.add_argument('-minutes', type=int, default=1)       # max looptijd (safety)
    ap.add_argument('-label', type=str, default='D')
    ap.add_argument('-port', type=str, default='')
    ap.add_argument('--scan-seconds', type=float, default=6.0, help='totale scantijd vóór we doorlopen')
    args = ap.parse_args()

    want = args.port or os.getenv('ARDUINO_PORT') or ''
    total_deadline = time.perf_counter() + max(1.0, args.scan_seconds)

    sys.stdout.write(HIDE)
    try:
        connected = False
        ser = None
        portlabel = '-'
        notes = []

        while time.perf_counter() < total_deadline and not connected:
            notes = []
            cands = list_candidates(want)
            if not cands:
                hud("Scene 05: Arduino — zoeken…", ["geen COM-poorten"], False)
                time.sleep(0.2)
                continue
            for dev, _, desc in cands:
                per_port_deadline = time.perf_counter() + 1.0  # max 1s per poort
                for baud in BAUDS:
                    if time.perf_counter() >= total_deadline: break
                    ser = try_probe(dev, baud, per_port_deadline, notes)
                    if ser:
                        connected = True
                        portlabel = f"{dev} @ {baud}"
                        break
                if connected or time.perf_counter() >= total_deadline: break

            # UI update tijdens scan
            title = "Scene 05: Arduino — USB OUT (scannen…)" if not connected else "Scene 05: Arduino — USB IN"
            lines = [("Arduino: OK @ " + portlabel) if connected else "Arduino: NO", ""]
            lines += notes[-6:]
            hud(title, lines, connected)
            # kleine adempauze
            time.sleep(0.05)

        if connected and ser:
            # korte BRIGHT flash, dan door
            try:
                ser.write(b'S0\n'); ser.flush()
            except Exception:
                pass
            t0 = time.perf_counter()
            while time.perf_counter() - t0 < 0.6:
                hud("Scene 05: Arduino — USB IN", [f"Arduino: OK @ {portlabel}"], True)
                time.sleep(0.05)
            try: ser.close()
            except Exception: pass
        # geen connect? gewoon door (niet hangen)
    finally:
        sys.stdout.write(SHOW); sys.stdout.flush()

if __name__ == '__main__':
    main()
