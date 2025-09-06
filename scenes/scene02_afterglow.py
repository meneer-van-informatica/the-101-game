# scenes/scene02_afterglow.py
# Scene 02: Afterglow — de '1' staat op de eindplek en laat een korte trail/knipper zien
import time, sys, shutil

ESC='\x1b'; CLS=ESC+'[2J'+ESC+'[H'; HIDE=ESC+'[?25l'; SHOW=ESC+'[?25h'; BRIGHT=ESC+'[1m'; DIM=ESC+'[2m'; RESET=ESC+'[0m'
W,H=64,20
def blank(): return [[' ']*W for _ in range(H)]
def put(c,x,y,ch): 
    if 0<=x<W and 0<=y<H: c[y][x]=ch
def draw_one(c,ox,oy,ink='█'):
    glyph=['  '+ink+'  ',' '+ink+ink+'  ','  '+ink+'  ']*3+[' '+ink+ink+ink+' ']
    # net als Scene01: 5x9
    rows=[
        '  █  ',' ██  ','  █  ','  █  ','  █  ','  █  ','  █  ','  █  ',' ███ '
    ]
    for j,row in enumerate(rows):
        for i,ch in enumerate(row):
            if ch!=' ': put(c,ox+i,oy+j,ink)

def render(c,style=''):
    sys.stdout.write(CLS)
    if style: sys.stdout.write(style)
    for r in c: sys.stdout.write(''.join(r)+'\n')
    if style: sys.stdout.write(RESET)
    sys.stdout.flush()

def main():
    sys.stdout.write(HIDE)
    try:
        x,y = 64-8-4,5  # zelfde eindpositie als Scene01
        trail = []
        for t in range(12):
            c=blank()
            # trail punten (faden)
            trail.append((x-1-t, y+4))
            for i,(tx,ty) in enumerate(trail[-8:]):
                put(c,tx,ty,'.' if i<6 else '·')
            # 1 knippert zacht/helder
            style = BRIGHT if t%2==0 else DIM
            draw_one(c,x,y)
            render(c,style)
            sys.stdout.write('\n scene 02 • afterglow  |  q=quit\n'); sys.stdout.flush()
            time.sleep(0.25)
    finally:
        sys.stdout.write(SHOW); sys.stdout.flush()

if __name__=='__main__': main()
