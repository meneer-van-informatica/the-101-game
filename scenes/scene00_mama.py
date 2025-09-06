# scenes/scene00_mama.py
# Titlecard: HALLO MAMA (pulse)
import time, sys, os
ESC='\x1b'; CLS=ESC+'[2J'+ESC+'[H'; HIDE=ESC+'[?25l'; SHOW=ESC+'[?25h'; BRIGHT=ESC+'[1m'; DIM=ESC+'[2m'; RESET=ESC+'[0m'
DEBUG = os.getenv('GAME_DEV') == '1'

def letters():
    # 6-hoog blokletters
    H=[ "██  ██","██  ██","██████","██  ██","██  ██","      " ]
    A=[ " ███ ","█   █","█████","█   █","█   █","     " ]
    L=[ "█    ","█    ","█    ","█    ","█████","     " ]
    O=[ " ███ ","█   █","█   █","█   █"," ███ ","     " ]
    M=[ "█   █","██ ██","█ █ █","█   █","█   █","     " ]
    space=["  ","  ","  ","  ","  ","  "]
    word1=[H,space,A,space,L,space,L,space,O]
    word2=[M,space,A,space,M,space,A]
    def join(seq):
        rows=['']*6
        for ch in seq:
            for i in range(6): rows[i]+=ch[i]+'  '
        return rows
    return join(word1), join(word2)

HEART = [
"   ██   ██   ",
"  █████████  ",
"  █████████  ",
"   ███████   ",
"    █████    ",
"     ███     ",
]

def render(pulse=False):
    if DEBUG: sys.stdout.write('\n' + ('-'*80) + '\n')
    else:     sys.stdout.write(CLS)
    line1,line2 = letters()
    style = BRIGHT if pulse else DIM
    sys.stdout.write(style + '\n'.join(line1) + RESET + '\n')
    sys.stdout.write(style + '\n'.join(line2) + RESET + '\n\n')
    # hartje
    sys.stdout.write(style + '\n'.join(HEART) + RESET + '\n')
    sys.stdout.write('\n  [q] skip  •  auto-continue…\n')
    sys.stdout.flush()

def main():
    sys.stdout.write(HIDE)
    try:
        t0=time.time()
        for i in range(10):
            pulse = (i%2==0)
            render(pulse=pulse)
            # kleine wacht, maar sta skip toe
            t1=time.time()
            while time.time()-t1<0.25:
                try:
                    import msvcrt
                    if msvcrt.kbhit():
                        ch=msvcrt.getch()
                        if ch in (b'q',b'Q',b'\x1b'): return
                except: pass
                time.sleep(0.02)
    finally:
        sys.stdout.write(SHOW); sys.stdout.flush()

if __name__=='__main__': main()
