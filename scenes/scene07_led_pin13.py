# scenes/scene07_led_pin13.py — wacht eerst op USB-IN, dan LED D13 (met safety)
# Keys: [o] ON  [f] OFF  [b] blink (safe)  [p] pulse  [q] quit
import os, sys, time, argparse

# --- UI: core.rt als het kan; anders een kleine fallback ---
try:
    from core.rt import fast_render, BRIGHT, DIM, HIDE, SHOW
except Exception:
    ESC = "\x1b"
    HIDE = ESC + "[?25l"
    SHOW = ESC + "[?25h"
    BRIGHT = ESC + "[1m"
    DIM = ESC + "[2m"
    RESET = ESC + "[0m"
    def fast_render(lines, style=""):
        sys.stdout.write(ESC + "[2J" + ESC + "[H")
        if style: sys.stdout.write(style)
        for ln in lines: sys.stdout.write(ln + "\n")
        if style: sys.stdout.write(RESET)
        sys.stdout.flush()

# --- serial deps ---
try:
    import serial, serial.tools.list_ports as lp
except Exception:
    serial = None; lp = None

SAFE_DUTY = 0.2          # 20% duty tijdens blink
HARD_ON_MAX_SEC = 10.0   # auto-cutoff voor hard ON (bescherming)

def ports_non_bt():
    if not lp: return []
    out=[]
    for p in lp.comports():
        desc = (p.description or '').lower()
        if "bluetooth" in desc: 
            continue
        out.append((p.device, getattr(p,"vid",None), getattr(p,"pid",None), p.description or p.device))
    return out

def choose_arduino(prefer=""):
    prefer = (prefer or "").upper()
    cand = ports_non_bt()
    # score Arduino/CH340/CP210x etc.
    best = None
    for dev, vid, pid, desc in cand:
        s = 0
        if prefer and dev.upper()==prefer: s += 1000
        if vid == 0x2341: s += 400          # Arduino
        if pid in (0x0043, 0x7523): s += 200 # Uno/CH340
        if "arduino" in (desc or "").lower(): s += 150
        item = (s, dev, desc)
        if best is None or item > best: best = item
    return (best[1], best[2]) if best else (None, None)

def ui_usb(status_text, note="", bright=False):
    title = "  Scene 07: USB OUT -> IN (wait)  |  daarna LED D13"
    lines = [title, ""]
    if bright:
        lines += ["USB  IN", "============================================================", ""]
    else:
        lines += ["USB  OUT", "------------------------------------------------------------", ""]
    if note: lines.append(note)
    lines += ["", "keys: [u] force USB IN   [q] quit"]
    fast_render(lines, BRIGHT if bright else DIM)

def ui_led(state, dev, note="", bright=True):
    lines = [
        "  Scene 07: LED via pin 13 (echte ON/OFF)",
        "",
        f"device : {dev or '-'}",
        f"state  : {state}",
        ""
    ]
    if note: lines.append(note)
    lines += ["", "keys: [o] ON   [f] OFF   [b] blink (safe)   [p] pulse   [q] quit"]
    fast_render(lines, BRIGHT if bright else DIM)

def open_serial(dev):
    s = serial.Serial(dev, baudrate=115200, timeout=0.25, write_timeout=0.25, dsrdtr=True, rtscts=False)
    time.sleep(1.0)       # Uno reset
    s.reset_input_buffer()
    try:
        s.write(b"H\n"); s.flush(); time.sleep(0.2)
        _ = s.read(64)
    except Exception:
        pass
    return s

def wait_for_usb(prefer="", timeout=0):  # timeout=0 => eindeloos wachten
    sys.stdout.write(HIDE); sys.stdout.flush()
    try:
        start = time.perf_counter()
        forced = False
        while True:
            # key handling: u => force IN, q => quit
            try:
                import msvcrt
                if msvcrt.kbhit():
                    ch = msvcrt.getch()
                    if ch in (b'q', b'Q', b'\x1b'):
                        return None
                    if ch in (b'u', b'U'):
                        forced = True
            except Exception:
                pass

            dev, desc = choose_arduino(prefer)
            if dev or forced:
                # korte BRIGHT flash
                t1 = time.perf_counter()
                while time.perf_counter() - t1 < 0.8:
                    ui_usb("IN", f"(found: {dev or 'forced'})", bright=True)
                    time.sleep(0.05)
                return dev

            # timeout?
            if timeout and (time.perf_counter() - start) > timeout:
                # auto door (sim IN)
                t1 = time.perf_counter()
                while time.perf_counter() - t1 < 0.6:
                    ui_usb("IN", "(auto)", bright=True)
                    time.sleep(0.05)
                return None

            # show OUT + hint
            current = ", ".join(d for d,_,_,_ in ports_non_bt()) or "-"
            ui_usb("OUT", f"seen ports: {current}", bright=False)
            time.sleep(0.15)
    finally:
        pass  # cursor blijft verborgen tot LED-fase begint

def main():
    # argparse: accepteer runner-flags
    ap = argparse.ArgumentParser(add_help=False)
    ap.add_argument('-port', type=str, default=os.getenv('ARDUINO_PORT',''))
    ap.add_argument('--force-on', action='store_true')
    ap.add_argument('-bpm', type=int, default=84)
    ap.add_argument('-minutes', type=int, default=5)
    ap.add_argument('-label', type=str, default='D')
    args, _ = ap.parse_known_args()

    # 0) vereisten
    if serial is None:
        fast_render(["pyserial ontbreekt (pip install pyserial)"], DIM); time.sleep(2); return

    # 1) USB OUT -> IN: wachten op device
    prefer = args.port
    dev = wait_for_usb(prefer=prefer, timeout=0)  # eindeloos wachten tot IN (of 'u')
    # als dev None door 'forced', proberen alsnog een poort te kiezen
    if not dev:
        dev, _ = choose_arduino(prefer)

    # 2) LED-fase: probeer te openen; als het niet lukt, toon melding en stop netjes
    try:
        ser = open_serial(dev) if dev else None
    except Exception as e:
        sys.stdout.write(SHOW); sys.stdout.flush()
        fast_render([f"open failed on {dev or '-'}: {e.__class__.__name__}"], DIM); time.sleep(2)
        return

    # 3) LED-control loop
    try:
        state = "OFF"
        blinking = False
        on_since = None

        # optionele show: start direct ON (met safety)
        if args.force_on and ser:
            try: ser.write(b'L1\n'); ser.flush()
            except: pass
            state = "ON"; on_since = time.perf_counter()

        ui_led(state, dev or '-', "SAFE: blink duty limited; hard ON auto-cutoff na 10s.", bright=(state=="ON"))
        while True:
            now = time.perf_counter()

            # blink SAFE
            if blinking and ser:
                period = 0.5
                on_dur = SAFE_DUTY * period
                phase = (now % period)
                want_on = phase < on_dur
                if want_on and state != "ON":
                    try: ser.write(b'L1\n'); ser.flush()
                    except: pass
                    state="ON"; on_since=now; ui_led(state, dev, "(blink SAFE)", True)
                elif (not want_on) and state != "OFF":
                    try: ser.write(b'L0\n'); ser.flush()
                    except: pass
                    state="OFF"; on_since=None; ui_led(state, dev, "(blink SAFE)", False)

            # safety cutoff
            if state=="ON" and on_since and (now - on_since) > HARD_ON_MAX_SEC and not blinking:
                try: ser.write(b'L0\n'); ser.flush()
                except: pass
                state="OFF"; on_since=None
                ui_led(state, dev, f"auto-cutoff after {int(HARD_ON_MAX_SEC)}s", False)

            # keys
            try:
                import msvcrt
                if msvcrt.kbhit():
                    ch = msvcrt.getch()
                    if ch in (b'q', b'Q', b'\x1b'):
                        break
                    elif ch in (b'o', b'O'):
                        if ser:
                            try: ser.write(b'L1\n'); ser.flush()
                            except: pass
                        state="ON"; blinking=False; on_since=time.perf_counter()
                        ui_led(state, dev, "HARD ON (use briefly); cutoff active.", True)
                    elif ch in (b'f', b'F'):
                        if ser:
                            try: ser.write(b'L0\n'); ser.flush()
                            except: pass
                        state="OFF"; blinking=False; on_since=None
                        ui_led(state, dev, "", False)
                    elif ch in (b'b', b'B'):
                        blinking = not blinking
                        on_since=None
                        ui_led(state, dev, "(blink SAFE)" if blinking else "", state=="ON")
                    elif ch in (b'p', b'P'):
                        if ser:
                            try: ser.write(b'L1\n'); ser.flush()
                            except: pass
                            ui_led("ON", dev, "(pulse)", True); time.sleep(0.2)
                            try: ser.write(b'L0\n'); ser.flush()
                            except: pass
                            ui_led("OFF", dev, "", False)
            except Exception:
                pass

            time.sleep(0.01)
    finally:
        try:
            if ser:
                ser.write(b'L0\n'); ser.flush(); ser.close()
        except Exception:
            pass
        sys.stdout.write(SHOW); sys.stdout.flush()

if __name__ == '__main__':
    main()
