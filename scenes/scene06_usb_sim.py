# scenes/scene06_usb_sim.py — USB OUT -> IN (simulatie + zachte detectie)
import time, sys, os
try:
    import serial, serial.tools.list_ports as lp
except Exception:
    serial = None; lp = None

from core.rt import fast_render, BRIGHT, DIM, HIDE, SHOW

def list_non_bt():
    if not lp: return []
    out=[]
    for p in lp.comports():
        desc = (p.description or '').lower()
        if 'bluetooth' in desc: 
            continue
        out.append(p.device)
    return sorted(out)

def screen(title, lines, bright=False):
    msg = [f"  {title}", ""]
    msg += lines
    msg += ["",
            "keys: [u] force USB IN   [q] quit",
            "hint: dit is een simulatie; echte USB-power is OS/hardware-gebonden."]
    fast_render(msg, BRIGHT if bright else DIM)

def main():
    sys.stdout.write(HIDE)
    try:
        title = "Scene 06: USB presence (OUT -> IN)"
        baseline = list_non_bt()
        connected = False
        t0 = time.perf_counter()
        force_env = os.getenv('FORCE_USB_IN') == '1'

        while True:
            # 1) check user force
            forced = force_env
            try:
                import msvcrt
                if msvcrt.kbhit():
                    ch = msvcrt.getch()
                    if ch in (b'q', b'Q', b'\x1b'): break
                    if ch in (b'u', b'U'): forced = True
            except Exception:
                pass

            # 2) zachte detectie: als aantal non-BT COM-poorten stijgt, neem "USB IN"
            now_ports = list_non_bt()
            gained = len(now_ports) > len(baseline)

            # 3) automatische timeout: na 3s gewoon IN (film moet door)
            auto = (time.perf_counter() - t0) > 3.0

            connected = forced or gained or auto

            if not connected:
                lines = ["USB  OUT",
                         "────────────────────────────────────────────────────────",
                         *(f"seen: {', '.join(now_ports) or '-'}",)]
                screen(title, lines, bright=False)
                time.sleep(0.08)
            else:
                # korte BRIGHT flash en klaar
                lines = ["USB  IN",
                         "████████████████████████████████████████████████████████",
                         f"(sim) ports: {', '.join(now_ports) or '-'}"]
                t1 = time.perf_counter()
                while time.perf_counter() - t1 < 0.8:
                    screen(title, lines, bright=True)
                    time.sleep(0.05)
                break
    finally:
        sys.stdout.write(SHOW); sys.stdout.flush()

if __name__=='__main__': main()
