# scenes/d_frame.py
# scene: D frame
# chained after: d_minor
import time, sys, math, shutil, msvcrt, argparse

ANSI_CLEAR = '\x1b[2J\x1b[H'
ANSI_HIDE = '\x1b[?25l'
ANSI_SHOW = '\x1b[?25h'

def clamp(n,a,b):
    return a if n<a else b if n>b else n

def draw_bar(width, fill, head='â–ˆ', body='â–“', empty=' '):
    fill = clamp(fill, 0, width)
    if fill<=0: return empty*width
    if fill>=width: return body*(width-1)+head
    return body*(fill-1)+head+empty*(width-fill)

def mmss(sec):
    m = int(sec)//60
    s = int(sec)%60
    return f'{m:02d}:{s:02d}'

def main():
    ap = argparse.ArgumentParser(description='D frame')
    ap.add_argument('-bpm', type=int, default=84)
    ap.add_argument('-minutes', type=int, default=5)
    ap.add_argument('-label', type=str, default='D')
    args = ap.parse_args()

    bpm = args.bpm
    total_s = max(1, args.minutes*60)
    label = args.label
    start = time.perf_counter()
    last = start
    interval = 60.0/max(1,bpm)
    beat = 0
    running = True
    met = True

    try:
        sys.stdout.write(ANSI_HIDE)
        while running:
            now = time.perf_counter()
            elapsed = now - start
            remain = max(0.0, total_s - elapsed)
            cols = shutil.get_terminal_size((100,30)).columns
            cols = max(60, cols)
            inner = cols - 2

            if met and (now - last) >= interval:
                last += interval
                beat += 1

            while msvcrt.kbhit():
                ch = msvcrt.getch()
                if ch in (b'q', b'Q', b'\x1b'):
                    running = False
                elif ch == b' ':
                    met = not met
                elif ch in (b'+', b'='):
                    bpm = clamp(bpm+2, 20, 220); interval = 60.0/bpm
                elif ch in (b'-', b'_'):
                    bpm = clamp(bpm-2, 20, 220); interval = 60.0/bpm
                elif ch in (b'n', b'N'):
                    print('NEXT:')
                    running = False

            sys.stdout.write(ANSI_CLEAR)
            sys.stdout.write(' scene: D frame | key: d_frame | after: d_minor | bpm: ' + str(bpm) + ' | tijd: ' + mmss(remain) + '\n')
            sys.stdout.write(' keys: [q]=quit  [space]=metronoom  [+]/[-]=bpm  [n]=next\n\n')

            bar_w = inner
            fill = int((elapsed/interval) % 1 * bar_w) if met else 0
            bar = draw_bar(bar_w, fill)

            for i in range(4):
                pos = int(i*(bar_w/4))
                if pos < len(bar):
                    bar = bar[:pos] + ('â”ƒ' if i==0 else 'â”‚') + bar[pos+1:]

            sys.stdout.write(' [' + bar + ']\n')

            amp = 6
            width = min(80, inner)
            wave = []
            for x in range(width):
                t = elapsed + x/(width*2.0)
                y = math.sin(2*math.pi*(bpm/60.0)*t)
                lvl = int((y+1)*0.5*amp)
                wave.append('â–â–‚â–ƒâ–„â–…â–†â–‡'[lvl])
            sys.stdout.write(' hook: ' + ''.join(wave) + '\n')

            prog_fill = int((elapsed/total_s)*bar_w)
            sys.stdout.write(' tijd: [' + draw_bar(bar_w, prog_fill, head='â– ', body='â– ', empty='Â·') + ']\n')

            sys.stdout.flush()
            if not running or remain <= 0: break
            time.sleep(0.01)
    finally:
        sys.stdout.write('\n klaar.\n')
        sys.stdout.write(ANSI_SHOW)
        sys.stdout.flush()

if __name__ == '__main__':
    main()
