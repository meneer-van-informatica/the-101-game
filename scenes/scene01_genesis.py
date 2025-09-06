# scenes/scene01_genesis.py  — Afterglow-stijl redraw
import time, sys, math, shutil, msvcrt
from core.rt import CLS, HIDE, SHOW, BRIGHT, RESET, fast_render

WIDTH, HEIGHT = 64, 20
def blank(): return [[' ']*WIDTH for _ in range(HEIGHT)]
def put(c,x,y,ch):
    if 0<=x<WIDTH and 0<=y<HEIGHT: c[y][x]=ch

def draw_big_one(c,ox,oy):
    rows=['  █  ',' ██  ','  █  ','  █  ','  █  ','  █  ','  █  ','  █  ',' ███ ']
    for j,row in enumerate(rows):
        for i,ch in enumerate(row):
            if ch!=' ': put(c,ox+i,oy+j,ch)

def draw_small_zero(c,ox,oy):
    rows=['███','█ █','███']
    for j,row in enumerate(rows):
        for i,ch in enumerate(row):
            if ch!=' ': put(c,ox+i,oy+j,ch)

def to_lines(c): return [''.join(r) for r in c]

def main():
    sys.stdout.write(HIDE)
    try:
        one_x,one_y = 2,5
        zero_x,zero_y = WIDTH-8,9
        frames=[]

        step=max(1,(zero_x-one_x)//6)
        for k in range(6):
            c=blank(); draw_big_one(c,one_x+step*k,one_y); draw_small_zero(c,zero_x,zero_y)
            frames.append((to_lines(c), ''))

        c=blank(); draw_big_one(c,zero_x-4,one_y)
        for dx in range(-1,4): put(c,zero_x+dx,zero_y,'*'); draw_small_zero(c,zero_x,zero_y)
        frames.append((to_lines(c), BRIGHT))

        for k in range(3):
            c=blank(); draw_big_one(c,zero_x-4,one_y)
            frames.append((to_lines(c), BRIGHT if k%2==0 else ''))

        for idx,(lines,style) in enumerate(frames):
            fast_render(lines, style)
            sys.stdout.write('\n scene 01 • frame {}/10  |  q=quit\n'.format(idx+1)); sys.stdout.flush()
            t0=time.time()
            while time.time()-t0<0.35:
                if msvcrt.kbhit():
                    ch=msvcrt.getch()
                    if ch in (b'q',b'Q',b'\x1b'): return
            # continue
    finally:
        sys.stdout.write(SHOW); sys.stdout.flush()

if __name__=='__main__': main()
