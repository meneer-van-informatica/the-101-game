# scenes/scene04_choice.py — keuze zet de chain om via scripts/switch_route.ps1
import os, sys, subprocess, time

from core.rt import fast_render, BRIGHT, DIM, HIDE, SHOW

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
PS   = 'powershell'

def draw_board():
    # simpele statische ascii (geen engine nodig), focus is op keuze
    board = [
        "  Scene 04: Choice — Software / Hardware / Economie / Route-4",
        "",
        "  a b c d e f g h",
        "8 r n b q k b n r 8",
        "7 p p p p p p p p 7",
        "6 . . . . . . . . 6",
        "5 . . . . . . . . 5",
        "4 . . . . . . . . 4",
        "3 . . . . . . . . 3",
        "2 P P P P P P P P 2",
        "1 R N B Q K B N R 1",
        "  a b c d e f g h",
        "",
        "Beste zet voor jou (White): e4   (principe: centrum pakken, lijnen openen)",
        "",
        "Kies: [A] Software   [B] Hardware   [C] Economie   [D] route-4   |   [Q] stop",
        ""
    ]
    return board

def apply_route(letter):
    route = letter.upper()
    script = os.path.join(ROOT, 'scripts', 'switch_route.ps1')
    args = [PS, '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', script, '-Route', route]
    try:
        subprocess.run(args, check=False)
    except Exception:
        pass

def main():
    sys.stdout.write(HIDE)
    try:
        fast_render(draw_board(), BRIGHT)
        while True:
            ch = None
            try:
                import msvcrt
                if msvcrt.kbhit():
                    ch = msvcrt.getch()
            except Exception:
                pass
            if not ch:
                time.sleep(0.02)
                continue
            c = chr(ch[0]).lower()
            if c in ('q', '\x1b'):
                break
            if c in ('a','b','c','d'):
                apply_route(c)
                # korte confirm en terug naar film-runner
                fast_render(["Route gekozen: " + c.upper(), "", "Film gaat verder met de nieuwe chain..."], BRIGHT)
                time.sleep(0.7)
                break
    finally:
        sys.stdout.write(SHOW); sys.stdout.flush()

if __name__ == '__main__':
    main()
