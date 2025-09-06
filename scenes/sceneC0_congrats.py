# scenes/sceneC0_congrats.py — leeg frame, daarna boodschap
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

def main():
    ap = argparse.ArgumentParser(add_help=False)
    ap.add_argument('-bpm', type=int, default=84)
    ap.add_argument('-minutes', type=int, default=1)
    ap.add_argument('-label', type=str, default='C')
    _, _ = ap.parse_known_args()

    sys.stdout.write(HIDE); sys.stdout.flush()
    try:
        # 1) leeg scherm (dim)
        fast_render([""], DIM)
        time.sleep(0.8)
        # 2) boodschap (bright)
        msg = [
            "",
            "",
            "Gefeliciteerd! Je mag naar Werk!",
            "",
            ""
        ]
        fast_render(msg, BRIGHT)
        time.sleep(1.5)
    finally:
        sys.stdout.write(SHOW); sys.stdout.flush()

if __name__ == '__main__':
    main()
