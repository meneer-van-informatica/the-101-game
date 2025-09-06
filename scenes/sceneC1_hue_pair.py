# scenes/sceneC1_hue_pair.py — Level 1: Hue Bridge pair (roept jouw PS bootstrap aan)
import os, sys, time, subprocess

# core fallback
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

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
CFG  = os.path.join(ROOT, "data", "hue_config.json")

def render(step="ready", note="", bright=False):
    lines = [
        "  Level C/1: Hue Bridge koppelen",
        "",
        "Doel: pair met je Hue Bridge. Dit moet altijd eerst.",
        "",
        "Stappen:",
        "  1) Druk op de ronde link-knop op de Bridge.",
        "  2) Druk [Enter] hier om de pairing te starten.",
        "",
    ]
    if os.path.exists(CFG):
        lines += [f"[ok] config gevonden: {CFG}"]
    else:
        lines += ["[info] nog geen config gevonden."]
    if note: lines += ["", note]
    lines += ["", "keys: [Enter] pair   |   [q]/[Esc] stop"]
    fast_render(lines, BRIGHT if bright else DIM)

def main():
    sys.stdout.write(HIDE); sys.stdout.flush()
    try:
        render()
        while True:
            try:
                import msvcrt
                if msvcrt.kbhit():
                    b = msvcrt.getch()
                    if b in (b'q', b'Q', b'\x1b'):
                        break
                    if b in (b'\r', b'\n'):
                        # run jouw PowerShell bootstrap in-plaats
                        render("pair", "Pair start... volg instructies in hetzelfde venster.", True)
                        ps = "powershell"
                        script = os.path.join(ROOT, "scripts", "hue_bootstrap.ps1")
                        # laat output gewoon in dezelfde console lopen
                        subprocess.call([ps, "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", script])
                        # terug in de scene:
                        ok = os.path.exists(CFG)
                        note = "[ok] gepaird! Druk nogmaals [Enter] voor Level 2." if ok else "[! ] geen config gevonden; probeer opnieuw."
                        render("done", note, ok)
                        # wacht op enter om door te gaan (alleen als ok)
                        if ok:
                            #
