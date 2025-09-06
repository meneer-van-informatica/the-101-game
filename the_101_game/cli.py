# E:\the-101-game\the_101_game\cli.py
import sys
import time

def _tone(freq: int, ms: int) -> None:
    try:
        import winsound
        winsound.Beep(freq, ms)
    except Exception:
        sys.stdout.write('\a')
        sys.stdout.flush()
        time.sleep(ms / 1000.0)

def blink() -> None:
    print('[ok] blink (alert) klaar.')

def bleep() -> None:
    print('[ok] bleep (alert) klaar.')
    _tone(1000, 200)

def bloop() -> None:
    print('[ok] bloop (alert) klaar.')
    _tone(400, 200)

def lamp_on() -> None:
    print('[ok] lampje aan.')

def lamp_off() -> None:
    print('[ok] lampje uit.')

if __name__ == '__main__':
    blink()
    bleep()
    bloop()
    lamp_on()
    lamp_off()
