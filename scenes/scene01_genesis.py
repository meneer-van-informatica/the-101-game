# scenes/scene01_genesis.py
# Scene 01: Genesis — 10 auto-frames
# Grote '1' ziet kleine '0', eet hem op, en knippert.
import time, sys, shutil, msvcrt

ESC = '\x1b'
CLS = ESC + '[2J' + ESC + '[H'
HIDE = ESC + '[?25l'
SHOW = ESC + '[?25h'
BRIGHT = ESC + '[1m'
RESET = ESC + '[0m'

WIDTH, HEIGHT = 64, 20

def blank():
    return [[' ']*WIDTH for _ in range(HEIGHT)]

def put(canvas, x, y, ch):
    if 0 <= x < WIDTH and 0 <= y < HEIGHT:
        canvas[y][x] = ch

def draw_big_one(canvas, ox, oy, bright=False, visible=True):
    if not visible: 
        return
    # 5x9 '1'
    one = [
        '  █  ',
        ' ██  ',
        '  █  ',
        '  █  ',
        '  █  ',
        '  █  ',
        '  █  ',
        '  █  ',
        ' ███ '
    ]
    for j, row in enumerate(one):
        for i, ch in enumerate(row):
            if ch != ' ':
                put(canvas, ox+i, oy+j, ch)

def draw_small_zero(canvas, ox, oy):
    # 3x3 '0'
    zero = [
        '███',
        '█ █',
        '███'
    ]
    for j, row in enumerate(zero):
        for i, ch in enumerate(row):
            if ch != ' ':
                put(canvas, ox+i, oy+j, ch)

def render(canvas, bright=False):
    sys.stdout.write(CLS)
    if bright:
        sys.stdout.write(BRIGHT)
    for row in canvas:
        sys.stdout.write(''.join(row) + '\n')
    if bright:
        sys.stdout.write(RESET)
    sys.stdout.flush()

def main():
    sys.stdout.write(HIDE)
    try:
        # posities
        one_x = 2
        one_y = 5
        zero_x = WIDTH - 8
        zero_y = 9

        frames = []

        # frames 0-5: '1' loopt naar rechts richting '0'
        step = max(1, (zero_x - one_x) // 6)
        for k in range(6):
            c = blank()
            draw_big_one(c, one_x + step*k, one_y, bright=False, visible=True)
            draw_small_zero(c, zero_x, zero_y)
            frames.append((c, False))

        # frame 6: happen (sterretjes)
        c = blank()
        draw_big_one(c, zero_x - 4, one_y, bright=True, visible=True)
        # hap-effect
        for dx in range(-1, 4):
            put(c, zero_x+dx, zero_y, '*')
        draw_small_zero(c, zero_x, zero_y)  # laatste zichtbare fractie
        frames.append((c, True))

        # frame 7-9: knipperen (1 zichtbaar/helder afwisselend)
        for k in range(3):
            c_on = blank()
            draw_big_one(c_on, zero_x - 4, one_y, bright=(k % 2 == 0), visible=True)
            frames.append((c_on, k % 2 == 0))

        # speel af: 10 frames totaal
        for idx, (canvas, bright) in enumerate(frames):
            if msvcrt.kbhit():
                ch = msvcrt.getch()
                if ch in (b'q', b'Q', b'\x1b'):
                    break
            render(canvas, bright=bright)
            sys.stdout.write('\n scene 01 • frame ' + str(idx+1) + '/10  |  keys: q=quit\n')
            sys.stdout.flush()
            time.sleep(0.35)

        # eindbeeld: knipper nog 4x
        for k in range(4):
            c = blank()
            draw_big_one(c, zero_x - 4, one_y, bright=(k % 2 == 0), visible=True)
            render(c, bright=(k % 2 == 0))
            sys.stdout.write('\n scene 01 • blink\n')
            sys.stdout.flush()
            time.sleep(0.20)

    finally:
        sys.stdout.write(SHOW)
        sys.stdout.flush()

if __name__ == '__main__':
    main()
