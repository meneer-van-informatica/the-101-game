# scenes/scene00_title.py
# Scene 00: Titlecard — "BIT WORLD"
import time, sys, os
ESC='\x1b'; CLS=ESC+'[2J'+ESC+'[H'; HIDE=ESC+'[?25l'; SHOW=ESC+'[?25h'; BRIGHT=ESC+'[1m'; RESET=ESC+'[0m'
DEBUG = os.getenv('GAME_DEV') == '1'
ART = [
"██████╗ ██╗████████╗    ██╗    ██╗ ██████╗ ██████╗ ██╗     ██████╗ ██╗     ██████╗ ██████╗ ██████╗ ",
"██╔══██╗██║╚══██╔══╝    ██║    ██║██╔═══██╗██╔══██╗██║     ██╔══██╗██║     ██╔══██╗██╔══██╗██╔══██╗",
"██████╔╝██║   ██║       ██║ █╗ ██║██║   ██║██████╔╝██║     ██████╔╝██║     ██║  ██║██████╔╝██████╔╝",
"██╔═══╝ ██║   ██║       ██║███╗██║██║   ██║██╔═══╝ ██║     ██╔═══╝ ██║     ██║  ██║██╔══██╗██╔══██╗",
"██║     ██║   ██║       ╚███╔███╔╝╚██████╔╝██║     ███████╗██║     ███████╗██████╔╝██║  ██║██║  ██║",
"╚═╝     ╚═╝   ╚═╝        ╚══╝╚══╝  ╚═════╝ ╚═╝     ╚══════╝╚═╝     ╚══════╝╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝",
]
def render():
    if DEBUG: sys.stdout.write('\n' + ('-'*80) + '\n')
    else:     sys.stdout.write(CLS)
    sys.stdout.write(BRIGHT + '\n'.join(ART) + RESET + '\n')
    sys.stdout.write('\n  press [q] to skip • auto-continue…\n'); sys.stdout.flush()
def main():
    sys.stdout.write(HIDE)
    try:
        for _ in range(3):
            render()
            t0=time.time()
            while time.time()-t0<0.6:
                if msvcr(): return
                time.sleep(0.02)
    finally:
        sys.stdout.write(SHOW); sys.stdout.flush()
def msvcr():
    try:
        import msvcrt
        if msvcrt.kbhit():
            ch=msvcrt.getch()
            if ch in (b'q',b'Q',b'\x1b'): return True
    except Exception: pass
    return False
if __name__=='__main__': main()
