# core/rt.py — lichte runtime voor snelle frame renders (Afterglow-stijl)
import sys

ESC = '\x1b'
CLS = ESC + '[2J' + ESC + '[H'
HIDE = ESC + '[?25l'
SHOW = ESC + '[?25h'
BRIGHT = ESC + '[1m'
DIM = ESC + '[2m'
UNDER = ESC + '[4m'
RESET = ESC + '[0m'

def hide_cursor():
    sys.stdout.write(HIDE)

def show_cursor():
    sys.stdout.write(SHOW); sys.stdout.flush()

def fast_render(lines, style=''):
    """Volledige frame redraw: CLS + (optioneel) stijl + alle regels in één write + reset."""
    out = [CLS]
    if style:
        out.append(style)
    out.append('\n'.join(lines))
    if style:
        out.append(RESET)
    sys.stdout.write(''.join(out))
    sys.stdout.flush()
