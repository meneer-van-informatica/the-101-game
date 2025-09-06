# scenes/sceneC1_wait.py — Keuze 1: wacht op IN van Speler (druk een toets)
import sys, time, argparse

# core-fallback
try:
    from core.rt import fast_render, BRIGHT, DIM, HIDE, SHOW
except Exception:
    ESC="\x1b"; HIDE=ESC+"[?25l"; SHOW=ESC+"[?25h"; BRIGHT=ESC+"[1m"; DIM=ESC+"[2m"; RESET=ESC+"[0m"
    def fast_render(lines, style=""):
        sys.stdout.write(ESC+"[2J"+ESC+"[H")
        if style: sys.stdout.write(style)
        for ln in lines: sys.stdout.write(ln+"\n")
        if style: sys.stdout.write(RESET)
        sys.stdout.flush()

def draw(pulse_on):
    lines = [
        "Keuze 1",
        "",
        ("Wachten op IN van Speler ..." if pulse_on else "Wachten op IN van Speler"),
        "",
        "Druk een toets om door te gaan. (q of Esc om te stoppen)"
    ]
    fast_render(lines, BRIGHT if pulse_on else DIM)

def main():
    ap = argparse.ArgumentParser(add_help=False)
    ap.add_argument('-bpm', type=int, default=84)
    ap.add_argument('-minutes', type=int, default=1)
    ap.add_argument('-label', type=str, default='C1')
    _, _ = ap.parse_known_args()

    sys.stdout.write(HIDE); sys.stdout.flush()
    try:
        pulse = False
        last = time.perf_counter()
        draw(pulse)
        while True:
            # kleine pulse
            now = time.perf_counter()
            if now - last > 0.5:
                pulse = not pulse
                last = now
                draw(pulse)
            # toetsen
            try:
                import msvcrt
                if msvcrt.kbhit():
                    ch = msvcrt.getch()
                    if ch in (b'\x1b', b'q', b'Q'): break
                    # elke andere toets = IN -> scene klaar
                    break
            except Exception:
                pass
            time.sleep(0.02)
    finally:
        sys.stdout.write(SHOW); sys.stdout.flush()

if __name__ == '__main__':
    main()
