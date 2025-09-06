# scenes/scene03_life.py
# Scene 03: Life — Conway mini: 10 auto-frames
# seed: 1 glider + 1 blinker op de plek waar '1' eindigde

import time, sys, msvcrt

ESC = '\x1b'
CLS = ESC + '[2J' + ESC + '[H'
HIDE = ESC + '[?25l'
SHOW = ESC + '[?25h'
BRIGHT = ESC + '[1m'
RESET = ESC + '[0m'

W, H = 64, 24
ALIVE = '█'
DEAD  = ' '

def make_grid():
    return [[False]*W for _ in range(H)]

def render(grid):
    sys.stdout.write(CLS)
    sys.stdout.write(BRIGHT)
    for y in range(H):
        row = ''.join(ALIVE if grid[y][x] else DEAD for x in range(W))
        sys.stdout.write(row + '\n')
    sys.stdout.write(RESET)
    sys.stdout.flush()

def count_n(grid, x, y):
    # torus (wrap) zodat het blijft bewegen
    c = 0
    for dy in (-1,0,1):
        for dx in (-1,0,1):
            if dx==0 and dy==0: continue
            nx = (x+dx) % W
            ny = (y+dy) % H
            if grid[ny][nx]: c += 1
    return c

def step(grid):
    nxt = make_grid()
    for y in range(H):
        for x in range(W):
            n = count_n(grid, x, y)
            if grid[y][x]:
                nxt[y][x] = (n==2 or n==3)
            else:
                nxt[y][x] = (n==3)
    return nxt

def seed_life():
    g = make_grid()
    # eindplek van Scene01 '1' ~ rechtsboven, zet daar glider + blinker
    ox, oy = W-18, 6

    # glider (klassiek)
    gl = [(1,0),(2,1),(0,2),(1,2),(2,2)]
    for dx,dy in gl:
        x = (ox+dx) % W; y = (oy+dy) % H
        g[y][x] = True

    # blinker onder de glider (3 in een rij)
    bx, by = W-18, 14
    for dx in (0,1,2):
        g[(by)%H][(bx+dx)%W] = True
    return g

def main():
    sys.stdout.write(HIDE)
    try:
        grid = seed_life()
        frames = 10
        for i in range(frames):
            if msvcrt.kbhit():
                ch = msvcrt.getch()
                if ch in (b'q', b'Q', b'\x1b'): break
            render(grid)
            sys.stdout.write('\n scene 03 • life  |  frame {}/{}  |  q=quit\n'.format(i+1, frames))
            sys.stdout.flush()
            time.sleep(0.18)
            grid = step(grid)

        # kleine eindloop: nog 6 snelle stappen
        for k in range(6):
            render(grid)
            sys.stdout.write('\n scene 03 • life (flow)\n')
            sys.stdout.flush()
            time.sleep(0.12)
            grid = step(grid)
    finally:
        sys.stdout.write(SHOW)
        sys.stdout.flush()

if __name__ == '__main__':
    main()
