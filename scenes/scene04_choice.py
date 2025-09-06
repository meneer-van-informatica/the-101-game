# scenes/scene04_choice.py — schaakbord + keuze, Afterglow-stijl redraw
import time, sys, msvcrt, os, datetime
from core.rt import fast_render, BRIGHT, RESET, HIDE, SHOW, UNDER

def make_board():
    files='  a   b   c   d   e   f   g   h  '
    hline='  +'+'---+'*8
    def row(r, p): return f'{r} |'+'|'.join((' '+(x if x!='.' else ' ')+' ') for x in p.split())+f'| {r}'
    lines=['  Scene 04: Choice  —  schaakbord + keuze',
           hline,row('8','r n b q k b n r'),hline,
           row('7','p p p p p p p p'),hline,
           row('6','. . . . . . . .'),hline,
           row('5','. . . . . . . .'),hline,
           row('4','. . . . . . . .'),hline,
           row('3','. . . . . . . .'),hline,
           row('2','P P P P P P P P'),hline,
           row('1','R N B Q K B N R'),hline,
           '    '+files]
    return lines

def render(lines, banner, blink):
    out=list(lines)+['', (BRIGHT+UNDER if blink else '')+banner+(RESET if blink else ''), '',
                     ' kies: [A] Software   [B] Hardware   [C] Economie   [D] #route-4   |   [q] stop']
    fast_render(out)

def log_choice(ch,label):
    try:
        root=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        os.makedirs(os.path.join(root,'data'),exist_ok=True)
        with open(os.path.join(root,'data','choices_log.txt'),'a',encoding='utf-8') as f:
            f.write(f"{datetime.datetime.now():%Y-%m-%d %H:%M:%S}\t{ch}\t{label}\n")
    except: pass

def main():
    sys.stdout.write(HIDE)
    try:
        board=make_board()
        banner='Beste zet voor jou (White): e4  —  (principe: centrum pakken, lijnen openen)'
        t0=time.perf_counter()
        choice=None
        while True:
            blink = int((time.perf_counter()-t0)*2)%2==0
            render(board, banner, blink)
            if msvcrt.kbhit():
                ch=msvcrt.getch()
                if ch in (b'q',b'Q',b'\x1b'): break
                up=ch.upper()
                if up in (b'A',b'B',b'C',b'D'):
                    choice = up.decode('ascii'); break
            time.sleep(0.04)
        if choice:
            label={'A':'Software','B':'Hardware','C':'Economie','D':'#route-4'}[choice]
            fast_render([f'Keuze: {choice} → {label}','','Ga door…'], BRIGHT)
            print(f'CHOICE:{choice}:{label}')
            log_choice(choice,label)
            time.sleep(0.6)
    finally:
        sys.stdout.write(SHOW); sys.stdout.flush()

if __name__=='__main__': main()
