# scenes/scene08_dr_bibber.py — Dr. Bibber: kijk live mee in elevated acties (probe/cycle) met oscilloscoopbalk
import os, sys, time, subprocess, shutil
from core.rt import fast_render, BRIGHT, DIM, HIDE, SHOW

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
LOG  = os.path.join(ROOT, 'data', 'logs', 'dr_bibber.log')

def tail_reader(path, max_keep=200):
    last_size = 0
    buf = []
    while True:
        try:
            size = os.path.getsize(path)
            if size < last_size:
                # file truncated/rotated
                last_size = 0
            if size > last_size:
                with open(path, 'r', encoding='utf-8', errors='ignore') as f:
                    f.seek(last_size)
                    chunk = f.read()
                    if chunk:
                        for line in chunk.splitlines():
                            buf.append(line)
                            if len(buf) > max_keep: buf = buf[-max_keep:]
                last_size = size
        except FileNotFoundError:
            pass
        yield buf
        time.sleep(0.05)

def call_admin(action):
    pwsh = shutil.which('powershell') or 'powershell'
    script = os.path.join(ROOT, 'scripts', 'dr_bibber_act.ps1')
    args = [pwsh, '-NoProfile', '-ExecutionPolicy', 'Bypass',
            '-File', script, '-Action', action, '-LogPath', LOG]
    # start zonder te wachten
    try:
        subprocess.Popen(args,
                         stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        pass

def monitor_bar(t):
    cols = 60
    phase = (t % 2.0) / 2.0
    idx   = int(phase * cols)
    chars = ['·']*cols
    if 0 <= idx < cols: chars[idx] = '█'
    return '['+''.join(chars)+']'

def doctor():
    # mini-ascii van Dr. Bibber ;)
    return [
        r"   ____   Dr. Bibber",
        r"  (o  o)  steady hands...",
        r"   \__/ "
    ]

def render(lines, bright):
    head = ["  Scene 08: Dr. Bibber — elevated log & tools", monitor_bar(time.perf_counter()), ""]
    body = doctor() + [""] + lines[-18:]
    keys = ["", "keys: [p] probe   [c] cycle USB   [q] quit"]
    fast_render(head + body + keys, BRIGHT if bright else DIM)

def main():
    os.makedirs(os.path.dirname(LOG), exist_ok=True)
    sys.stdout.write(HIDE)
    try:
        # initial hint
        with open(LOG, 'a', encoding='utf-8') as f:
            f.write("[{}] viewer: hello\n".format(time.strftime('%Y-%m-%d %H:%M:%S')))
        reader = tail_reader(LOG)
        bright = False
        t0 = time.perf_counter()
        while True:
            buf = next(reader)
            # bright pulse kort na een actie (heuristiek: recente '=== ' lijn)
            bright = any('=== Dr.Bibber/' in x for x in buf[-5:])
            render(buf, bright)
            # keys
            try:
                import msvcrt
                if msvcrt.kbhit():
                    ch = msvcrt.getch()
                    if ch in (b'q', b'Q', b'\x1b'):
                        break
                    elif ch in (b'p', b'P'):
                        call_admin('probe')
                    elif ch in (b'c', b'C'):
                        call_admin('cycle')
            except Exception:
                pass
            time.sleep(0.05)
    finally:
        sys.stdout.write(SHOW); sys.stdout.flush()

if __name__ == '__main__':
    main()
