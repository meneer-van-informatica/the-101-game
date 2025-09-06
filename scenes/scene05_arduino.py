# scenes/scene05_arduino.py — strict detect + auto-advance
import time, sys, os, argparse
try:
    import serial, serial.tools.list_ports
except Exception:
    serial = None

from core.rt import fast_render, BRIGHT, DIM, HIDE, SHOW

def ports():
    if not serial: return []
    return [p.device for p in serial.tools.list_ports.comports()]

def try_open_strict(preferred=None, baud=115200, timeout=0.6):
    """Alleen 'connected' als we écht 'OK' terugkrijgen op 'H\\n'."""
    if not serial: return None, None
    cand = []
    if preferred: cand.append(preferred)
    cand += [p for p in ports() if p not in cand]
    for dev in cand:
        try:
            s = serial.Serial(
                dev, baudrate=baud, timeout=timeout, write_timeout=timeout,
                dsrdtr=True, rtscts=False
            )
            time.sleep(0.35)                   # Uno reset na open
            s.reset_input_buffer()
            s.write(b'H\n'); s.flush()
            time.sleep(0.35)
            resp = s.read(64).decode('utf-8','ignore')
            if 'OK' in resp:                   # <-- ECHT bewijs
                return s, dev
            s.close()
        except Exception:
            try: s.close()
            except: pass
    return None, None

def banner(lines, status):
    return ["  Scene 05: Arduino — sync blink (Hardware)"] + lines + ["", status, "", " keys: [+]/[-] tempo  |  [space] start/stop  |  [p] pulse  |  [q] quit" ]

def bars(bpm, running, connected, portlabel, tick):
    period_ms = max(50, int(60000/max(1,bpm)))
    left = f" tempo: {bpm} BPM  ({period_ms} ms)"
    run  = "running" if running else "stopped"
    conn = ("Arduino: OK @ "+portlabel) if connected else "Arduino: NO"
    tmark = "■" if tick else " "
    return [left, f" state: {run}   |   {conn}   |   tick: {tmark}"]

def frame_visual(t, bpm, running):
    cols = 60
    period = 60.0/max(1,bpm)
    phase = (t % period) / period
    fill = int(phase * cols)
    bar = "■"*fill + "·"*(cols-fill)
    if running and phase < 0.5: bar = bar[:-1] + "█"
    return [" ["+bar+"] "]

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('-bpm', type=int, default=84)
    ap.add_argument('-minutes', type=int, default=3)
    ap.add_argument('-label', type=str, default='D')
    ap.add_argument('-port', type=str, default='')
    ap.add_argument('--advance-on-connect', action='store_true', default=True)
    args = ap.parse_args()

    bpm = max(20, min(220, args.bpm))
    period_ms = max(50, int(60000/max(1,bpm)))
    total = max(1, args.minutes*60)

    sys.stdout.write(HIDE)

    want = args.port or os.getenv('ARDUINO_PORT') or ''
    ser, used = try_open_strict(want)
    connected = ser is not None
    running   = False
    tick_state= False
    last_tick = time.perf_counter()
    last_try  = 0.0
    start     = time.perf_counter()
    flash_until = 0.0
    connected_once = connected  # voor auto-advance

    try:
        while True:
            now = time.perf_counter()
            if (now - start) >= total: break

            # probe every 0.8s wanneer niet connected
            if not connected and (now - last_try) > 0.8:
                last_try = now
                ser, used = try_open_strict(want)
                if ser: 
                    connected = True
                    connected_once = True
                    flash_until = now + 0.8    # korte highlight
                    # zet tempo op device
                    try:
                        ser.write(f"T{period_ms}\n".encode('ascii')); ser.flush()
                    except Exception: pass

            # disconnect detectie
            if connected:
                try:
                    # hou lijn in sync (zeldzaam sturen, hier volstaat)
                    ser.write(f"T{period_ms}\n".encode('ascii')); ser.flush()
                except Exception:
                    try: ser.close()
                    except: pass
                    ser = None
                    connected = False
                    running = False

            # tick (alleen UI; device knippert via S1/S0)
            if running:
                half = (period_ms/1000.0)/2.0
                if now - last_tick >= half:
                    last_tick = now
                    tick_state = not tick_state

            # UI
            lines = frame_visual(now-start, bpm, running) + bars(bpm, running, connected, used if connected else '-', tick_state)
            status = (" Arduino @ " + used) if connected else " demo-mode: geen Arduino"
            style  = BRIGHT if (connected or now < flash_until) else DIM
            fast_render(banner(lines, status), style)

            # input
            try:
                import msvcrt
                if msvcrt.kbhit():
                    ch = msvcrt.getch()
                    if ch in (b'q', b'Q', b'\x1b'): break
                    elif ch in (b'+', b'='): bpm = min(220, bpm+2); period_ms = int(60000/bpm)
                    elif ch in (b'-', b'_'): bpm = max(20, bpm-2); period_ms = int(60000/bpm)
                    elif ch == b' ':
                        running = not running
                        if connected:
                            try: ser.write(b'S1\n' if running else b'S0\n'); ser.flush()
                            except Exception: pass
                    elif ch in (b'p', b'P'):
                        if connected:
                            try: ser.write(b'P\n'); ser.flush()
                            except Exception: pass
            except Exception:
                pass

            # auto-advance: zodra USB voor het eerst is gezien, na flash → door
            if args.advance_on_connect and connected_once and (not connected or now >= flash_until) and connected:
                # korte extra adem en door
                time.sleep(0.2)
                break

            time.sleep(0.01)

    finally:
        try:
            if ser: ser.write(b'S0\n'); ser.flush(); ser.close()
        except Exception:
            pass
        sys.stdout.write(SHOW); sys.stdout.flush()

if __name__ == '__main__':
    main()
