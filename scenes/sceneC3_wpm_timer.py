# scenes/sceneC3_wpm_timer.py — Typ bepaalt Tijd: sneller typen = sneller klaar
# - Virtuele tijd: 60s totaal (aanpasbaar met -minutes)
# - Elke toetsaanslag voegt virtuele seconden toe (default 0.5s per key; --sec-per-key)
# - Beeps versnellen automatisch (BPM schaalt met voortgang)
# - +/- past max BPM aan; m mute/unmute; q/Esc stopt
# - WPM live (op basis van echte verstreken tijd)
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

def do_beep(freq=880, dur_ms=35):
    try:
        import winsound
        winsound.Beep(int(freq), int(dur_ms))
    except Exception:
        try:
            sys.stdout.write("\a"); sys.stdout.flush()
        except Exception:
            pass

def progress_bar(p, width=60, on_char="=", off_char="-"):
    fill = max(0, min(width, int(p * width)))
    return "[" + (on_char * fill) + (off_char * (width - fill)) + "]"

def render(secs_left, total_secs, chars, wpm, bpm_now, muted, pulse=False):
    done = total_secs - max(0, secs_left)
    p = done / float(total_secs)
    bar = progress_bar(p, width=60, on_char=("#" if pulse else "="), off_char="-")
    mm = max(0, int(secs_left)) // 60
    ss = max(0, int(secs_left)) % 60
    lines = []
    lines.append("  Scene C3: WPM/BPM minute timer (type vult de tijd)")
    lines.append("")
    lines.append(bar)
    lines.append("virtuele tijd over: {0:02d}:{1:02d}   BPM: {2}   sound: {3}".format(mm, ss, int(bpm_now), ("OFF" if muted else "ON")))
    lines.append("")
    lines.append("keystrokes: {0}   WPM(real-time): {1:.1f}".format(chars, wpm))
    lines.append("")
    lines.append("keys: [+]/[-] BPM-max  |  m mute/unmute  |  q/Esc stop  |  (elke toets telt mee)")
    fast_render(lines, BRIGHT if pulse else DIM)

def main():
    ap = argparse.ArgumentParser(add_help=False)
    ap.add_argument('-minutes', type=int, default=1)        # totale virtuele minuten
    ap.add_argument('-bpm', type=int, default=80)           # start/min BPM
    ap.add_argument('--bpm-max', type=int, default=200)     # max BPM bij volle balk
    ap.add_argument('--sec-per-key', type=float, default=0.5, help='virtuele seconden per toetsaanslag')
    ap.add_argument('--mute', action='store_true')
    # slik runner-flags door:
    ap.add_argument('-label', type=str, default='C3')
    args, _ = ap.parse_known_args()

    total_secs = max(10, int(args.minutes*60))
    bpm_min = max(30, min(240, int(args.bpm)))
    bpm_max = max(bpm_min+10, min(400, int(args.bpm_max)))
    sec_per_key = max(0.05, float(args.sec_per_key))
    muted = bool(args.mute)

    sys.stdout.write(HIDE); sys.stdout.flush()
    try:
        start_real = time.perf_counter()
        # virtuele klok
        virt_elapsed = 0.0
        last_beat_time = time.perf_counter()
        beat_count = 0

        chars = 0
        wpm = 0.0

        # init draw
        render(total_secs-virt_elapsed, total_secs, chars, wpm, bpm_min, muted, pulse=False)

        while virt_elapsed < total_secs:
            now = time.perf_counter()
            # input: elke toetsaanslag => virtuele tijd erbij
            key_presses = 0
            try:
                import msvcrt
                while msvcrt.kbhit():
                    b = msvcrt.getch()
                    if b in (b'\x1b', b'q', b'Q'):
                        raise KeyboardInterrupt
                    elif b in (b'+', b'='):
                        bpm_max = min(400, bpm_max + 5)
                    elif b in (b'-', b'_'):
                        bpm_max = max(bpm_min+10, bpm_max - 5)
                    elif b in (b'm', b'M'):
                        muted = not muted
                        key_presses += 1  # telt als actie
                    else:
                        key_presses += 1
            except Exception:
                pass

            if key_presses > 0:
                chars += key_presses
                virt_elapsed += sec_per_key * key_presses
                if virt_elapsed > total_secs:
                    virt_elapsed = total_secs

            # BPM schaalt met voortgang van de virtuele klok
            progress = virt_elapsed / float(total_secs) if total_secs > 0 else 1.0
            bpm_now = bpm_min + (bpm_max - bpm_min) * progress
            beat_interval = 60.0 / bpm_now

            # Beat (versnelt naarmate progress stijgt); accent op elke 4e
            pulse = False
            if (now - last_beat_time) >= beat_interval:
                last_beat_time += beat_interval
                beat_count += 1
                pulse = True
                if not muted:
                    if (beat_count % 4) == 0:
                        do_beep(1200, 55)
                    else:
                        do_beep(900, 35)

            # WPM (op echte tijd, klassieke definitie)
            real_elapsed_min = max(1e-6, (time.perf_counter() - start_real)/60.0)
            wpm = (chars/5.0) / real_elapsed_min

            # Render
            render(total_secs-virt_elapsed, total_secs, chars, wpm, bpm_now, muted, pulse)

            time.sleep(0.01)

        # klaar
        final_real_min = max(1e-6, (time.perf_counter()-start_real)/60.0)
        final_wpm = (chars/5.0)/final_real_min
        fast_render([
            "  Scene C3: klaar",
            "",
            "resultaat:",
            "  keystrokes : {0}".format(chars),
            "  WPM(real)  : {0:.1f}".format(final_wpm),
            "  BPM eind   : {0}".format(int(bpm_max)),
            "",
            "Door naar het volgende level..."
        ], BRIGHT)
        time.sleep(0.8)

    except KeyboardInterrupt:
        fast_render(["Gestopt."], DIM); time.sleep(0.4)
    finally:
        sys.stdout.write(SHOW); sys.stdout.flush()

if __name__ == '__main__':
    main()
