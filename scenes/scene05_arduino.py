# scenes/scene05_arduino.py
# Scene 05: Arduino — sync blink met onboard LED via serial; valt terug op demo-mode zonder Arduino
import time, sys, os, argparse
try:
    import serial, serial.tools.list_ports
except Exception:
    serial = None
from core.rt import fast_render, BRIGHT, DIM, HIDE, SHOW

def ports():
    if not serial: return []
    return [p.device for p in serial.tools.list_ports.comports()]

def try_open(preferred=None, baud=115200, timeout=1.0):
    if not serial: return None, None
    cand = []
    if preferred: cand.append(preferred)
    cand += [p for p in ports() if p not in cand]
    for dev in cand:
        try:
            s = serial.Serial(dev, baudrate=baud, timeout=timeout, write_timeout=timeout, dsrdtr=False, rtscts=False)
            time.sleep(0.3)             # Uno reset na open
            s.reset_input_buffer()
            s.write(b'H\n'); s.flush()   # handshake
            time.sleep(0.3)
            resp = s.read(64).decode('utf-8','ignore')
            if 'OK' in resp or resp == '':
                return s, dev
            s.close()
        except Exception:
            pass
    return None, None

def banner(lines, status):
    out = ["  Scene 05: Arduino — sync blink (Hardware)"] + lines + ["", status, "", " keys: [+]/[-] tempo  |  [space] start/stop  |  [p] pulse  |  [q] quit" ]
    return out

def bars(bpm, running, connected, portlabel, tick):
    period_ms = max(50, int(60000/max(1,bpm)))
    left = f" tempo: {bpm} BPM  ({period_ms} ms)"
    run = "running" if running else "stopped"
    conn = "Arduino: {}{}".format("OK" if connected else "NO", f" @ {portlabel}" if connected else "")
    tmark = "■" if tick else " "
    return [left, f" state: {run}   |   {conn}   |   tick: {tmark}"]

def frame_visual(t, bpm, running):
    cols = 60
    period = 60.0/max(1,bpm)
    phase = (t % period) / period
    fill = int(phase * cols)
    bar = "■"*fill + "·"*(cols-fill)
    if running and phase < 0.5:
        bar = bar[:-1] + "█"
    return [" ["+bar+"] "]

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('-bpm', type=int, default=84)
    ap.add_argument('-minutes', type=int, default=3)
    ap.add_argument('-label', type=str, default='D')
    ap.add_argument('-port', type=str, default='')
    args = ap.parse_args()

    bpm = max(20, min(220, args.bpm))
    period_ms = max(50, int(60000/max(1,bpm)))
    total = max(1, args.minutes*60)
    start = time.perf_counter()

    sys.stdout.write(HIDE)
    ser, used = try_open(args.port or os.getenv('ARDUINO_PORT'))
    connected = ser is not None
    running = False
    tick_state = False
    last_tick = time.perf_counter()
    last_cmd_period = None

    try:
        if connected:
            ser.write(f"T{period_ms}\n".encode('ascii')); ser.flush()
            last_cmd_period = period_ms

        while True:
            now = time.perf_counter()
            elapsed = now - start
            remain = max(0.0, total - elapsed)
            if remain <= 0: break

            if running and now - last_tick >= (period_ms/1000.0)/2.0:
                last_tick = now
                tick_state = not tick_state

            if connected:
                new_period = max(50, int(60000/max(1,bpm)))
                if new_period != last_cmd_period:
                    ser.write(f"T{new_period}\n".encode('ascii')); ser.flush()
                    last_cmd_period = new_period

            lines = []
            lines += frame_visual(now - start, bpm, running)
            lines += bars(bpm, running, connected, used if used else '-', tick_state)
            status = " demo-mode: geen Arduino" if not connected else (" Arduino @ " + used)
            fast_render(banner(lines, status), BRIGHT if running else DIM)

            try:
                import msvcrt
                if msvcrt.kbhit():
                    ch = msvcrt.getch()
                    if ch in (b'q', b'Q', b'\x1b'):
                        break
                    elif ch in (b'+', b'='):
                        bpm = min(220, bpm+2); period_ms = int(60000/bpm)
                    elif ch in (b'-', b'_'):
                        bpm = max(20, bpm-2);  period_ms = int(60000/bpm)
                    elif ch == b' ':
                        running = not running
                        if connected:
                            ser.write(b'S1\n' if running else b'S0\n'); ser.flush()
                    elif ch in (b'p', b'P'):
                        if connected: ser.write(b'P\n'); ser.flush()
            except Exception:
                pass

            time.sleep(0.01)
    finally:
        try:
            if ser:
                ser.write(b'S0\n'); ser.flush(); ser.close()
        except Exception:
            pass
        sys.stdout.write(SHOW); sys.stdout.flush()

if __name__ == '__main__':
    main()
