# scenes/sceneC2_mcq.py — Meerkeuzevraag (A/B/C/D), highlight keuze, Enter = bevestigen
# Accept generic runner flags en core-fallback.

import os, sys, time, argparse

# UI: core.rt als mogelijk; anders fallback
try:
    from core.rt import fast_render, BRIGHT, DIM, HIDE, SHOW
except Exception:
    ESC = "\x1b"; HIDE = ESC+"[?25l"; SHOW = ESC+"[?25h"; BRIGHT = ESC+"[1m"; DIM = ESC+"[2m"; RESET = ESC+"[0m"
    def fast_render(lines, style=""):
        sys.stdout.write(ESC+"[2J"+ESC+"[H")
        if style: sys.stdout.write(style)
        for ln in lines: sys.stdout.write(ln+"\n")
        if style: sys.stdout.write(RESET)
        sys.stdout.flush()

QUESTION = "Meerkeuze • Kies jouw route voor vandaag:"
CHOICES = [
    ("A", "Software — maak, ship, leer"),
    ("B", "Hardware — bouwen, testen, blink"),
    ("C", "Werk/Economie — leveren, leren, verdienen"),
    ("D", "Route-4 — later ontgrendelen"),
]

def render(selected=None, pulse=False):
    lines = []
    lines.append("  Scene C2: Meerkeuzevraag (A/B/C/D)")
    lines.append("")
    lines.append(QUESTION)
    lines.append("")
    for key, text in CHOICES:
        label = f"[{key}] {text}"
        if selected == key:
            lines.append(BRIGHT + label + RESET)
        else:
            lines.append(label)
    lines.append("")
    if selected:
        lines.append(f"Keuze: {selected}  — druk Enter om te bevestigen, of kies opnieuw.")
    else:
        lines.append("Druk A, B, C of D om te kiezen.")
    lines.append("")
    lines.append(("q/Esc: stop" if not pulse else BRIGHT + "q/Esc: stop" + RESET))
    fast_render(lines, BRIGHT if (selected or pulse) else DIM)

def main():
    # argparse: slik runner-flags door
    ap = argparse.ArgumentParser(add_help=False)
    ap.add_argument('-bpm', type=int, default=84)
    ap.add_argument('-minutes', type=int, default=1)
    ap.add_argument('-label', type=str, default='C2')
    args, _ = ap.parse_known_args()

    sys.stdout.write(HIDE); sys.stdout.flush()
    try:
        selected = None
        pulse = False
        last = time.perf_counter()
        render(selected, pulse)

        while True:
            # kleine pulse voor levendigheid
            now = time.perf_counter()
            if now - last > 0.6:
                pulse = not pulse
                last = now
                render(selected, pulse)

            # input
            try:
                import msvcrt
                if msvcrt.kbhit():
                    b = msvcrt.getch()
                    if b in (b'\x1b', b'q', b'Q'):  # Esc/Q
                        break
                    if b in (b'\r', b'\n'):        # Enter
                        if selected:
                            # log de keuze en klaar
                            try:
                                root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
                                os.makedirs(os.path.join(root, 'data'), exist_ok=True)
                                with open(os.path.join(root, 'data', 'mcq_answers.log'), 'a', encoding='utf-8') as f:
                                    ts = time.strftime('%Y-%m-%d %H:%M:%S')
                                    f.write(f"{ts} C2:{selected}\n")
                            except Exception:
                                pass
                            fast_render([
                                "  Scene C2: Meerkeuzevraag",
                                "",
                                BRIGHT + f"Keuze bevestigd: {selected}" + RESET,
                                "",
                                "Ga door naar het volgende level..."
                            ], BRIGHT)
                            time.sleep(0.7)
                            break
                        else:
                            continue
                    # letters
                    try:
                        ch = b.decode('utf-8','ignore').upper()
                    except Exception:
                        ch = ''
                    if ch in ('A','B','C','D'):
                        selected = ch
                        render(selected, True)
            except Exception:
                pass

            time.sleep(0.02)
    finally:
        sys.stdout.write(SHOW); sys.stdout.flush()

if __name__ == '__main__':
    # RESET voor fallback
    RESET = "\x1b[0m"
    main()
