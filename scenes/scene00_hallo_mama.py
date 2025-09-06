# scenes/scene00_hallo_mama.py — korte intro
import sys, time
try:
    from core.rt import fast_render, BRIGHT, DIM, HIDE, SHOW
except Exception:
    ESC="\x1b"; HIDE=ESC+"[?25l"; SHOW=ESC+"[?25h"; BRIGHT=ESC+"[1m"; DIM=ESC+"[2m"; RESET="\x1b[0m"
    def fast_render(lines, style=""):
        sys.stdout.write(ESC+"[2J"+ESC+"[H")
        if style: sys.stdout.write(style)
        for ln in lines: sys.stdout.write(ln+"\n")
        if style: sys.stdout.write(RESET)
        sys.stdout.flush()

def main():
    sys.stdout.write(HIDE); sys.stdout.flush()
    try:
        fast_render([""], DIM); time.sleep(0.3)
        fast_render(["", "", "Hallo Mama"], BRIGHT); time.sleep(1.2)
    finally:
        sys.stdout.write(SHOW); sys.stdout.flush()

if __name__ == "__main__":
    main()
