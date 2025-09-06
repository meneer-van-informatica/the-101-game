import os
import sys
import time
import json
import urllib.request

def _tone(freq: int, ms: int) -> None:
    try:
        import winsound
        winsound.Beep(freq, ms)
    except Exception:
        sys.stdout.write('\a')
        sys.stdout.flush()
        time.sleep(ms / 1000.0)

def _post(url: str, payload: dict) -> bool:
    try:
        req = urllib.request.Request(url, data=json.dumps(payload).encode('utf-8'), headers={'Content-Type':'application/json'}, method='PUT')
        urllib.request.urlopen(req, timeout=3).read()
        return True
    except Exception:
        return False

def _hue_xy(xy, bri=254, on=True) -> bool:
    bridge = os.environ.get('HUE_BRIDGE')
    token = os.environ.get('HUE_TOKEN')
    lights = os.environ.get('HUE_LIGHTS','').split(',')
    if not bridge or not token or not any(l.strip() for l in lights):
        return False
    base = f'http://{bridge}/api/{token}'
    ok = False
    for lid in [l.strip() for l in lights if l.strip()]:
        ok = _post(f'{base}/lights/{lid}/state', {'on': on, 'xy': xy, 'bri': bri}) or ok
    return ok

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
    _hue_xy([0.4571,0.4104], 254, True)

def lamp_off() -> None:
    print('[ok] lampje uit.')
    _hue_xy([0.4571,0.4104], 1, False)

def green() -> None:
    print('[ok] lamp groen.')
    _hue_xy([0.17,0.7], 254, True)
