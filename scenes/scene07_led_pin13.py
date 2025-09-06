# scenes/scene07_led_pin13.py — echte LED-sturing via D13 (UNO)
# Keys:  [o] ON  [f] OFF  [b] blink  [p] pulse  [q] quit
# Show-mode: duty-limit + safety cutoff als je geen weerstand gebruikt.
import os, sys, time, argparse

try:
    import serial, serial.tools.list_ports as lp
except Exception:
    serial = None; lp = None

from core.rt import fast_render, BRIGHT, DIM, HIDE, SHOW

SAFE_DUTY = 0.2           # 20% duty voor blink-mode (veilig(er) voor LED zonder R)
HARD_ON_MAX_SEC = 10.0    # safety cutoff voor continu ON zonder R

def find_port(prefer=''):
    prefer = (prefer or '').upper()
    best = None
    if lp:
        for p in lp.comports():
            desc = (p.description or '')
            if 'Bluetooth' in desc: 
                continue
            score = 0
            if prefer and p.device.upper()==prefer: score += 1000
            if getattr(p,'vid',None) == 0x2341: score += 400   # Arduino
            if getattr(p,'pid',None) in (0x0043,0x7523): score += 200  # Uno / CH340
            if 'Arduino' in desc: score += 100
            item = (score, p.device, desc)
            if best is None or item > best: best = item
    return best[1] if best else None

def open_serial(dev):
    s = serial.Serial(dev, baudrate=115200, timeout=0.25, write_timeout=0.25, dsrdtr=True, rtscts=False)
    # Uno reset → even wachten
    time.sleep(1.0)
    s.reset_input_buffer()
    try:
        s.write(b'H\n'); s.flush()
        time.sleep(0.2)
        _ = s.read(64)
    except Exception:
        pass
    return s

def hud(state, dev, note='', bright=True):
    lines = [
        "  Scene 07: LED via pin 13 (echte ON/OFF)",
        "",
        f"device : {dev or '-'}",
        f"state  : {state}",
        ""
    ]
    if note: lines.append(note)
    lines += [
        "",
        "keys: [o] ON   [f] OFF   [b] blink (safe duty)   [p] pulse   [q] quit"
    ]
    fast_render(lines, BRIGHT if bright else DIM)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('-port', type=str, default=os.getenv('ARDUINO_PORT',''))
    ap.add_argument('--force-on', action='store_true', help='start direct ON (on your own risk)')
    args = ap.parse_args()

    sys.stdout.write(HIDE)
    try:
        if serial is None:
            hud("no-serial", "-", "pyserial ontbreekt (pip install pyserial)", bright=False)
            time.sleep(2); return

        dev = args.port or find_port('')
        if not dev:
            hud("no-port", "-", "Geen Arduino gevonden; selecteer juiste COM in IDE, sluit Serial Monitor.", bright=False)
            time.sleep(2); return

        try:
            ser = open_serial(dev)
        except Exception as e:
            hud("open-fail", dev, f"{e.__class__.__name__}", bright=False)
            time.sleep(2); return

        state = "OFF"
        blinking = False
        last = time.perf_counter()
        on_since = None

        # optioneel show: force ON (met safety cutoff timer)
        if args.force_on:
            try: ser.write(b'L1\n'); ser.flush()
            except: pass
            state = "ON"; on_since = time.perf_counter()

        hud(state, dev, "SAFE: blink duty limited; hard ON auto-cutoff na 10s.", bright=(state=="ON"))

        while True:
            now = time.perf_counter()

            # blink engine met duty limit
            if blinking:
                period = 0.5  # 120 BPM
                on_dur = SAFE_DUTY * period
                phase = (now % period)
                want_on = phase < on_dur
                if want_on and state != "ON":
                    try: ser.write(b'L1\n'); ser.flush()
                    except: pass
                    state = "ON"; on_since = now
                    hud(state, dev, "(blink SAFE)", bright=True)
                elif (not want_on) and state != "OFF":
                    try: ser.write(b'L0\n'); ser.flush()
                    except: pass
                    state = "OFF"; on_since = None
                    hud(state, dev, "(blink SAFE)", bright=False)

            # safety cutoff voor hard ON
            if state == "ON" and on_since and (now - on_since) > HARD_ON_MAX_SEC and not blinking:
                try: ser.write(b'L0\n'); ser.flush()
                except: pass
                state = "OFF"; on_since = None
                hud(state, dev, f"auto-cutoff na {HARD_ON_MAX_SEC:.0f}s (bescherming)", bright=False)

            # input
            try:
                import msvcrt
                if msvcrt.kbhit():
                    ch = msvcrt.getch()
                    if ch in (b'q', b'Q', b'\x1b'):
                        break
                    elif ch in (b'o', b'O'):
                        try: ser.write(b'L1\n'); ser.flush()
                        except: pass
                        state = "ON"; blinking = False; on_since = time.perf_counter()
                        hud(state, dev, "HARD ON — gebruik kort; auto-cutoff actief.", bright=True)
                    elif ch in (b'f', b'F'):
                        try: ser.write(b'L0\n'); ser.flush()
                        except: pass
                        state = "OFF"; blinking = False; on_since = None
                        hud(state, dev, "", bright=False)
                    elif ch in (b'b', b'B'):
                        blinking = not blinking
                        on_since = None
                        hud(state, dev, "(blink SAFE)" if blinking else "", bright=(state=="ON"))
                    elif ch in (b'p', b'P'):
                        # korte veilige pulse
                        try: ser.write(b'L1\n'); ser.flush()
                        except: pass
                        state = "ON"; hud(state, dev, "(pulse)", bright=True)
                        time.sleep(0.2)
                        try: ser.write(b'L0\n'); ser.flush()
                        except: pass
                        state = "OFF"; hud(state, dev, "", bright=False)
            except Exception:
                pass

            time.sleep(0.01)

        try:
            ser.write(b'L0\n'); ser.flush()
        except: 
            pass
        ser.close()

    finally:
        sys.stdout.write(SHOW); sys.stdout.flush()

if __name__=='__main__':
    main()
