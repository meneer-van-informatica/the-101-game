# scenes/scene07_power_sim.py — 3.3V ON/OFF simulatie (grote balk + korte auto-cycle)
import time, sys
from core.rt import fast_render, BRIGHT, DIM, HIDE, SHOW

def draw(state, note=""):
    title = "Scene 07: 3.3V ON/OFF (sim)"
    bar_on  = "████████████████████████████████████████████████████████"
    bar_off = "────────────────────────────────────────────────────────"
    lines = [
        f"state: {state}",
        bar_on if state=="ON" else bar_off,
    ]
    if note: lines += ["", note]
    lines += ["", "keys: [o] ON   [f] OFF   [b] blink   [q] quit"]
    fast_render([f"  {title}","",*lines], BRIGHT if state=="ON" else DIM)

def main():
    sys.stdout.write(HIDE)
    try:
        state="OFF"
        # auto: korte demo OFF->ON->OFF->ON en dan interactief
        for s,wait in (("OFF",0.4),("ON",0.4),("OFF",0.4),("ON",0.4)):
            state=s; draw(state, "(auto demo)"); time.sleep(wait)

        draw(state, "")
        blinking=False; last=time.perf_counter()
        while True:
            # blink
            if blinking and time.perf_counter()-last>0.25:
                state = "OFF" if state=="ON" else "ON"
                last  = time.perf_counter()
                draw(state,"(blink)")
            # keys
            try:
                import msvcrt
                if msvcrt.kbhit():
                    ch=msvcrt.getch()
                    if ch in (b'q',b'Q',b'\x1b'): break
                    if ch in (b'o',b'O'): state="ON";  blinking=False; draw(state,"")
                    if ch in (b'f',b'F'): state="OFF"; blinking=False; draw(state,"")
                    if ch in (b'b',b'B'): blinking=not blinking; last=time.perf_counter(); draw(state,"(blink)" if blinking else "")
            except Exception:
                pass
            time.sleep(0.02)
    finally:
        sys.stdout.write(SHOW); sys.stdout.flush()

if __name__=='__main__': main()
