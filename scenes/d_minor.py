# scenes/d_minor.py
# console visual: d-minor sessie (ASCII, no deps)
import time, sys, math, argparse, shutil, msvcrt

ANSI_CLEAR = '\x1b[2J\x1b[H'
ANSI_HIDE = '\x1b[?25l'
ANSI_SHOW = '\x1b[?25h'

LABELS = ['storm','mist','leeg','paniek','flow','D']

def clamp(n,a,b): return a if n<a else b if n>b else n

def draw_bar(width, fill, head_char='█', body_char='▓', empty_char=' '):
    fill = clamp(fill, 0, width)
    if fill<=0: return empty_char*width
    if fill>=width: return body_char*(width-1)+head_char
    return body_char*(fill-1)+head_char+empty_char*(width-fill)

def fmt_mmss(sec):
    m = int(sec)//60
    s = int(sec)%60
    return f'{m:02d}:{s:02d}'

def main():
    ap = argparse.ArgumentParser(description='D-minor console visual')
    ap.add_argument('-bpm', type=int, default=84)
    ap.add_argument('-minutes', type=int, default=10)
    ap.add_argument('-label', type=str, default='D')
    args = ap.parse_args()

    bpm = args.bpm
    total_s = max(1, args.minutes*60)
    label = args.label if args.label else 'D'

    start = time.perf_counter()
    last_beat = start
    beat_interval = 60.0/max(1,bpm)
    beat_idx = 0
    running = True
    beat_on = True

    try:
        sys.stdout.write(ANSI_HIDE)
        while True:
            now = time.perf_counter()
            elapsed = now - start
            remain = max(0.0, total_s - elapsed)
            cols = shutil.get_terminal_size((100,30)).columns
            cols = max(60, cols)
            inner = cols - 2

            if beat_on and (now - last_beat) >= beat_interval:
                last_beat += beat_interval
                beat_idx += 1

            while msvcrt.kbhit():
                ch = msvcrt.getch()
                if ch in (b'q', b'Q', b'\x1b'):
                    running = False
                elif ch == b' ':
                    beat_on = not beat_on
                elif ch in (b'+', b'='):
                    bpm = clamp(bpm+2, 20, 220); beat_interval = 60.0/bpm
                elif ch in (b'-', b'_'):
                    bpm = clamp(bpm-2, 20, 220); beat_interval = 60.0/bpm
                elif ch in (b'l', b'L'):
                    try:
                        i = (LABELS.index(label)+1) % len(LABELS)
                    except ValueError:
                        i = 0
                    label = LABELS[i]

            sys.stdout.write(ANSI_CLEAR)
            sys.stdout.write(' d-minor sessie | label: ' + label + ' | bpm: ' + str(bpm) + ' | tijd: ' + fmt_mmss(remain) + '\n')
            sys.stdout.write(' keys: [q]=quit  [space]=metronoom  [+]/[-]=bpm  [l]=label\n\n')

            bar_w = inner
            four_phase = beat_idx % 4
            fill = int((elapsed/beat_interval) % 1 * bar_w) if beat_on else 0
            bar = draw_bar(bar_w, fill)
            for i in range(4):
                pos = int(i*(bar_w/4))
                if pos < len(bar):
                    bar = bar[:pos] + ('┃' if i==0 else '│') + bar[pos+1:]

            sys.stdout.write(' [' + bar + ']\n')

            pulse = ['    ','    ','    ','    ']
            if beat_on:
                if four_phase == 0:
                    pulse[0] = 'KICK'
                elif four_phase == 2:
                    pulse[2] = 'SNRE'
            sys.stdout.write(' 1:' + pulse[0] + '  2:' + pulse[1] + '  3:' + pulse[2] + '  4:' + pulse[3] + '\n')

            amp = 6
            width = min(80, inner)
            wave = []
            for x in range(width):
                t = elapsed + x/(width*2.0)
                y = math.sin(2*math.pi*(bpm/60.0)*t)
                lvl = int((y+1)*0.5*amp)
                wave.append('▁▂▃▄▅▆▇'[lvl])
            sys.stdout.write(' hook: ' + ''.join(wave) + '\n')

            prog_fill = int((elapsed/total_s)*bar_w)
            sys.stdout.write(' tijd: [' + draw_bar(bar_w, prog_fill, head_char='■', body_char='■', empty_char='·') + ']\n')

            sys.stdout.write('\n status: ' + ('loopt' if running else 'stop verzoek') + ' | beat ' + str(beat_idx) + ' | 4/4 fase ' + str(four_phase+1) + '\n')

            sys.stdout.flush()
            if not running or remain <= 0: break
            time.sleep(0.01)
    finally:
        sys.stdout.write('\n klaar.\n')
        sys.stdout.write(ANSI_SHOW)
        sys.stdout.flush()

if __name__ == '__main__':
    main()

# NEXT: d_frame

# NEXT: d_frame
