# scenes/scene06_usb_watch.py — USB OUT->IN detector (strict OK), auto-exit bij connect
import time, sys, os
try:
    import serial, serial.tools.list_ports
except Exception:
    serial = None
from core.rt import fast_render, BRIGHT, DIM, HIDE, SHOW

BAUDS = [115200, 9600]
HANDSHAKE = (b'H\r\n', b'H\n')

def candidates(preferred=None):
    if serial is None: return []
    pref = (preferred or '').upper()
    found = []
    for p in serial.tools.list_ports.comports():
        score = 0
        if pref and p.device.upper()==pref: score += 1000
        if getattr(p,'vid',None)==0x2341: score += 400  # Arduino
        if getattr(p,'pid',None) in (0x0043,0x7523): score += 200  # Uno/CH340
        if 'Bluetooth' in (p.description or ''): score -= 500
        found.append((p.device, score, p.description or p.device))
    found.sort(key=lambda r: (-r[1], r[0]))
    return found

def try_open_strict(preferred=None, notes=None):
    if serial is None: return None, None
    for dev,_,label in candidates(preferred):
        for baud in BAUDS:
            try:
                s = serial.Serial(dev, baudrate=baud, timeout=0.25, write_timeout=0.25, dsrdtr=True, rtscts=False)
                # Uno reset → wacht
                time.sleep(1.8)
                s.reset_input_buffer()
                ok=False
                t0=time.perf_counter()
                while time.perf_counter()-t0<1.2 and not ok:
                    for pay in HANDSHAKE:
                        s.write(pay); s.flush(); time.sleep(0.15)
                        resp = s.read(128).decode('utf-8','ignore')
                        if 'OK' in resp: ok=True; break
                if ok: return s, f"{dev} @ {baud}"
                s.close()
                if notes is not None: notes.append(f"probe: {dev} @ {baud} → geen OK")
            except Exception as e:
                try: s.close()
                except: pass
                if notes is not None: notes.append(f"probe: {dev} @ {baud} → {e.__class__.__name__}")
    return None, None

def frame(status:str, notes:list[str], bright:bool):
    msg = ["  Scene 06: USB presence (OUT → IN)", ""]
    big = "USB  IN" if bright else "USB  OUT"
    bar = "██████████████████████████████████████████████"
    msg += [big, bar, ""]
    msg += notes[:5]  # laat de laatste probe-regels zien
    return msg, (BRIGHT if bright else DIM)

def main():
    want = (os.getenv('ARDUINO_PORT') or '').upper()
    sys.stdout.write(HIDE)
    try:
        notes=[]
        ser, label = try_open_strict(want, notes)
        # loop tot connect
        start=time.perf_counter()
        while ser is None:
            lines, style = frame("OUT", notes[-6:], False)
            fast_render(lines, style)
            time.sleep(0.5)
            notes=[]
            ser, label = try_open_strict(want, notes)
            if time.perf_counter()-start > 180:  # 3 min timeout
                break
        # connected → flash BRIGHT en exit
        if ser:
            try:
                ser.write(b'S0\n'); ser.flush()
            except: pass
            t0=time.perf_counter()
            while time.perf_counter()-t0 < 0.8:
                lines, style = frame(f"IN @ {label}", [], True)
                fast_render(lines, style)
                time.sleep(0.05)
            try: ser.close()
            except: pass
    finally:
        sys.stdout.write(SHOW); sys.stdout.flush()

if __name__=='__main__': main()
