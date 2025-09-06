# scenes/scene04_choice.py
# Scene 04: Choice — schaakbord + keuze A/B/C/D, met "beste zet" banner
# A=Software, B=Hardware, C=Economie, D=#route-4
# keys: A/B/C/D om te kiezen, q om te stoppen

import time, sys, msvcrt, os, datetime

ESC = '\x1b'
CLS = ESC + '[2J' + ESC + '[H'
HIDE = ESC + '[?25l'
SHOW = ESC + '[?25h'
BRIGHT = ESC + '[1m'
DIM = ESC + '[2m'
RESET = ESC + '[0m'
UNDER = ESC + '[4m'

def render(board_lines, banner, hint_blink=False):
    sys.stdout.write(CLS)
    sys.stdout.write(BRIGHT)
    for ln in board_lines:
        sys.stdout.write(ln + '\n')
    sys.stdout.write(RESET)

    # banner
    sys.stdout.write('\n')
    if hint_blink:
        sys.stdout.write(BRIGHT + UNDER + banner + RESET + '\n')
    else:
        sys.stdout.write(banner + '\n')

    # menu
    sys.stdout.write('\n')
    sys.stdout.write(' kies: [A] Software   [B] Hardware   [C] Economie   [D] #route-4   |   [q] stop\n')
    sys.stdout.flush()

def make_start_board():
    # ascii bord met coördinaten
    files = '  a   b   c   d   e   f   g   h  '
    hline = '  +' + '---+'*8
    def row(r, pieces):
        cells = []
        for p in pieces.split():
            cells.append((' ' + (p if p != '.' else ' ') + ' '))
        return f'{r} |' + '|'.join(cells) + f'| {r}'

    # startstelling
    r8 = 'r n b q k b n r'
    r7 = 'p p p p p p p p'
    r6 = '. . . . . . . .'
    r5 = '. . . . . . . .'
    r4 = '. . . . . . . .'
    r3 = '. . . . . . . .'
    r2 = 'P P P P P P P P'
    r1 = 'R N B Q K B N R'

    lines = []
    lines.append('  Scene 04: Choice  —  schaakbord + keuze')
    lines.append(hline); lines.append(row('8', r8)); lines.append(hline)
    lines.append(row('7', r7)); lines.append(hline)
    lines.append(row('6', r6)); lines.append(hline)
    lines.append(row('5', r5)); lines.append(hline)
    lines.append(row('4', r4)); lines.append(hline)
    lines.append(row('3', r3)); lines.append(hline)
    lines.append(row('2', r2)); lines.append(hline)
    lines.append(row('1', r1)); lines.append(hline)
    lines.append('    ' + files)
    return lines

def log_choice(key_char, label):
    try:
        root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        data = os.path.join(root, 'data')
        os.makedirs(data, exist_ok=True)
        path = os.path.join(data, 'choices_log.txt')
        ts = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        with open(path, 'a', encoding='utf-8') as f:
            f.write(f'{ts}\t{key_char}\t{label}\n')
    except Exception:
        pass

def main():
    sys.stdout.write(HIDE)
    try:
        board = make_start_board()
        banner_text = 'Beste zet voor jou (White): e4  —  (principe: centrum pakken, lijnen openen)'
        choice = None
        blink = False
        t0 = time.perf_counter()

        while True:
            blink = int((time.perf_counter() - t0) * 2) % 2 == 0  # ~2 Hz
            render(board, banner_text, hint_blink=blink)

            # input
            if msvcrt.kbhit():
                ch = msvcrt.getch()
                if ch in (b'q', b'Q', b'\x1b'):
                    break
                up = ch.upper()
                if up in (b'A', b'B', b'C', b'D'):
                    choice = up.decode('ascii')
                    break
            time.sleep(0.05)

        if choice:
            label_map = {'A': 'Software', 'B': 'Hardware', 'C': 'Economie', 'D': '#route-4'}
            label = label_map.get(choice, '?')
            # bevestiging
            sys.stdout.write(CLS)
            sys.stdout.write(BRIGHT + f'Keuze: {choice}  →  {label}\n' + RESET)
            sys.stdout.write('\nGa door…\n')
            sys.stdout.flush()
            log_choice(choice, label)
            # hint voor engine/ketting-lezer
            print(f'CHOICE:{choice}:{label}')
            time.sleep(0.6)

    finally:
        sys.stdout.write(SHOW); sys.stdout.flush()

if __name__ == '__main__':
    main()
