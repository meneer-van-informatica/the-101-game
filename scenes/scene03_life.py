# scenes/scene03_life.py — Conway mini, Afterglow-stijl redraw
import time, sys, msvcrt
from core.rt import fast_render, BRIGHT, RESET, HIDE, SHOW

W,H = 64,24
ALIVE='█'; DEAD=' '

def make(): return [[False]*W for _ in range(H)]
def to_lines(g): return [''.join(ALIVE if g[y][x] else DEAD for x in range(W)) for y in range(H)]

def seed():
    g=make()
    ox,oy=W-18,6
    for dx,dy in ((1,0),(2,1),(0,2),(1,2),(2,2)): g[(oy+dy)%H][(ox+dx)%W]=True  # glider
    bx,by=W-18,14
    for dx in (0,1,2): g[by%H][(bx+dx)%W]=True  # blinker
    return g

def n(g,x,y):
    c=0
    for dy in (-1,0,1):
        for dx in (-1,0,1):
            if dx==0 and dy==0: continue
            if g[(y+dy)%H][(x+dx)%W]: c+=1
    return c

def step(g):
    nxt=make()
    for y in range(H):
        gy=g[y]; ny=nxt[y]
        for x in range(W):
            nn=n(g,x,y)
            ny[x] = (gy[x] and (nn==2 or nn==3)) or ((not gy[x]) and nn==3)
    return nxt

def main():
    sys.stdout.write(HIDE)
    try:
        g=seed()
        frames=10
        for i in range(frames):
            fast_render(to_lines(g), BRIGHT)
            sys.stdout.write('\n scene 03 • life  |  frame {}/{}\n'.format(i+1,frames)); sys.stdout.flush()
            t0=time.time()
            while time.time()-t0<0.18:
                if msvcrt.kbhit():
                    ch=msvcrt.getch()
                    if ch in (b'q',b'Q',b'\x1b'): return
            g=step(g)
        for _ in range(6):
            fast_render(to_lines(g), BRIGHT)
            sys.stdout.write('\n scene 03 • life (flow)\n'); sys.stdout.flush()
            time.sleep(0.12); g=step(g)
    finally:
        sys.stdout.write(SHOW); sys.stdout.flush()

if __name__=='__main__': main()
