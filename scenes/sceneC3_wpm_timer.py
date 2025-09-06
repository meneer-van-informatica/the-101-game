# scenes/sceneC3_wpm_timer.py — 1-minuut WPM/BPM timer met "TikTok"-achtige ticks
# - Countdown van 60s (of via -minutes)
# - BPM aanpasbaar met +/-  (accent op elke 4e beat)
# - Mute/unmute met 'm'
# - Realtime WPM = (getelde chars / 5) / (verstreken_minuten)
# - Any key telt als 1 char (optioneel: spatie telt ook)
# - ASCII-safe; core.rt fallback

import os, sys, time, argparse

# UI: core.rt of fallback
try:
    from core.rt import fast_render, BRIGHT, DIM, HIDE, SHOW
except Exception:
    ESC = "\x1b"; HIDE=ESC+"[?25l"; SHOW=ESC+"[?25h"; BRIGHT=ESC+"[1m"; DIM=ESC+"[2m"; RESET=ESC+"[0m"
    def fast_render(lines, style=""):
        sys.stdout.write(ESC+"[2J"+ESC+"[H")
        if style: sys.stdout.write(style)
        for ln in lines: sys.stdout.write(ln + "\n")
        if style: sys.stdout.write(RESET)
        sys.stdout.flush()

# Beep: winsound (Windows) -> fallback naar '\a'
def do_beep(freq=880, dur_ms=35):
    try:
        import winsound
        winsound.Beep(int(freq), int(dur_ms))
    except Exception:
        try:
            sys.stdout.write("\a"); sys.stdout.flush()
        except Exception:
            pass

def progress_bar(p, width=50, on_char="#", off_char="-"):
    fill = max(0, min(width, int(p * width)))
    return "[" + (on_char * fill) + (off_char * (width - fill)) + "]"

def render(title, secs_left, bpm, muted, chars, wpm, beat_pulse=False):
    lines = []
    lines.append("  " + title)
    lines.append("")
    # countdown en bar
    total = max(1, STATE['total_secs'])
    done = total - max(0, secs_left)
    p = done / float(total)
    bar = progress_bar(p, width=60, on_char=("#" if beat_pulse else "="), off_char="-")
    mm = secs_left // 60
    ss = secs_left % 60
    lines.append(bar)
    lines.append("time left: {0:02d}:{1:02d}    BPM: {2}   sound: {3}".format(mm, ss, bpm, ("OFF" if muted else "ON")))
    lines.append("")
    lines.append("keystrokes: {0}    WPM: {1:.1f}".format(chars, wpm))
    lines.append("")
    lines.append("keys: [+]/[-] BPM  |  m mute/unmute  |  q/Esc stop  |  (elke toets telt mee)")
    fast_render(lines, BRIGHT if beat_pulse else DIM)

STATE = {'total_secs': 60}

def main():
    ap = argparse.ArgumentParser(add_help=False)
    ap.add_argument('-minutes', type=int, default=1)  # standaard 1 minuut
    ap.add_argument('-bpm', type=int, default=120)    # standaard 120 BPM
    ap.add_argument('-label', type=str, default='C3')
    ap.add_argument('--mute', action='store_true', help='start muted')
    args, _ = ap.parse_known_args()

    total_secs = max(10, int(args.minutes*60))   # minimaal 10s
    STATE['total_secs'] = total_secs
    bpm = max(40, min(240, int(args.bpm)))
    muted = bool(args.mute)

    sys.stdout.write(HIDE); sys.stdout.flush()
    try:
        # timing
        start = time.perf_counter()
        last_beat = start
        beat_interval = 60.0 / bpm
        beat_count = 0

        # tellers
        chars = 0
        wpm = 0.0

        # init draw
        render("Scene C3: WPM/BPM minute timer", total_secs, bpm, muted, chars, wpm, beat_pulse=False)

        while True:
            now = time.perf_counter()
            elapsed = now - start
            left = max(0, int(total_secs - elapsed))
            if elapsed >= total_secs:
                break

            # Beat (met accent op elke 4e)
            pulse = False
            if (now - last_beat) >= beat_interval:
                last_beat += beat_interval
                beat_count += 1
                pulse = True
                if not muted:
                    if (beat_count % 4) == 0:
                        do_beep(1200, 55)  # accent
                    else:
                        do_beep(900, 35)

            # Input
            try:
                import msvcrt
                while msvcrt.kbhit():
                    b = msvcrt.getch()
                    if b in (b'\x1b', b'q', b'Q'):   # Esc / q
                        raise KeyboardInterrupt
                    elif b in (b'+', b'='):
                        bpm = min(240, bpm+2); beat_interval = 60.0 / bpm
                    elif b in (b'-', b'_'):
                        bpm = max(40, bpm-2); beat_interval = 60.0 / bpm
                    elif b in (b'm', b'M'):
                        muted = not muted
                    elif b in (b'\r', b'\n'):
                        # Enter telt ook als "actie"
                        chars += 1
                    else:
                        # alle andere toetsaanslagen tellen als 1 char
                        chars += 1
            except Exception:
                # geen msvcrt? dan geen live input
                pass

            # Realtime WPM (gemiddelde tot nu toe)
            minutes = max(1e-6, elapsed/60.0)
            wpm = (chars/5.0) / minutes

            # Render
            render("Scene C3: WPM/BPM minute timer", left, bpm, muted, chars, wpm, beat_pulse=pulse)

            time.sleep(0.01)

        # Einde: samenvatting
        total_minutes = max(1e-6, (time.perf_counter()-start)/60.0)
        final_wpm = (chars/5.0) / total_minutes
        fast_render([
            "  Scene C3: WPM/BPM minute timer — klaar",
            "",
            "resultaat:",
            "  keystrokes: {0}".format(chars),
            "  WPM       : {0:.1f}".format(final_wpm),
            "  BPM eind  : {0}".format(bpm),
            "",
            "Goed gedaan. Door naar de volgende scene..."
        ], BRIGHT)
        time.sleep(0.8)

    except KeyboardInterrupt:
        fast_render(["Gestopt."], DIM); time.sleep(0.4)
    finally:
        sys.stdout.write(SHOW); sys.stdout.flush()

if __name__ == '__main__':
    main()
