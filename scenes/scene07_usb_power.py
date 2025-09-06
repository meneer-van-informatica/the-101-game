# scenes/scene07_usb_power.py — 3.3V ON/OFF (best-effort via USB device disable/enable)
# Eerlijk: dit schakelt op veel PC's géén fysieke 3.3V uit; voor échte ON/OFF gebruik pin 13 + weerstand of switchable hub.
import time, sys, os, subprocess, shutil
from core.rt import fast_render, BRIGHT, DIM, HIDE, SHOW

def powershell(args:list[str]):
    pwsh = shutil.which("powershell") or "powershell"
    return subprocess.run([pwsh, "-NoProfile", "-ExecutionPolicy", "Bypass"] + args,
                          capture_output=True, text=True, encoding="utf-8")

def get_instance_id():
    code = "Get-PnpDevice -Class Ports | Where-Object { $_.InstanceId -match 'VID_2341|VID_1A86' -or $_.FriendlyName -match 'Arduino' } | Select-Object -First 1 -Expand InstanceId"
    r = powershell(["-Command", code])
    out = (r.stdout or "").strip()
    return out if out else None

def hud(title, lines, bright):
    msg = [f"  Scene 07: {title}", ""]
    msg += lines
    msg += ["", "keys: [Enter] cycle USB  |  [q] quit"]
    fast_render(msg, BRIGHT if bright else DIM)

def cycle_usb(instance_id:str):
    script = os.path.join(os.path.dirname(__file__), "..", "scripts", "usb_try_power_cycle.ps1")
    script = os.path.abspath(script)
    args = ["-File", script, "-InstanceId", instance_id]
    r = powershell(args)
    return r.returncode, (r.stdout or "") + (r.stderr or "")

def main():
    sys.stdout.write(HIDE)
    try:
        inst = get_instance_id()
        lines = []
        if not inst:
            lines = ["USB-toggle (disable/enable) vereist Admin én het device-id.",
                     "Ik kon geen Arduino vinden bij Ports (VID_2341/1A86).",
                     "Tip: sluit 'm aan, upload de sketch, sluit Serial Monitor, en run opnieuw.",
                     "Voor ECHTE 3.3V ON/OFF: gebruik D13 + 220Ω + LED → GND."]
            hud("3.3V ON/OFF (best-effort)", lines, False)
            time.sleep(3.0)
            return

        # UI-loop: druk Enter voor cycle; auto-run 1x bij start (demo)
        did = False
        t0 = time.perf_counter()
        while True:
            title = "3.3V ON/OFF (USB device cycle) — InstanceId aanwezig"
            hint = [
              f"Device: {inst}",
              "",
              "Let op: veel hosts laten 3.3V/5V aan bij disable; dit is geen garantie voor echt power-off.",
              "Aanbevolen: zet LED op D13 met weerstand; dat kun je 100% softwarematig schakelen."
            ]
            hud(title, hint, did)
            # auto 1x run na 1s
            if not did and (time.perf_counter()-t0) > 1.0:
                rc, log = cycle_usb(inst); did = True
                lines = ["USB cycle uitgevoerd.", "Log:", *log.strip().splitlines()[:6]]
                hud(title, lines, True)
                time.sleep(1.8)
            # key handling
            try:
                import msvcrt
                if msvcrt.kbhit():
                    ch = msvcrt.getch()
                    if ch in (b'q', b'Q', b'\x1b'): break
                    if ch in (b'\r', b'\n'):
                        rc, log = cycle_usb(inst)
                        lines = ["USB cycle uitgevoerd.", "Log:", *log.strip().splitlines()[:6]]
                        hud(title, lines, True)
                        time.sleep(1.2)
            except Exception:
                pass
            time.sleep(0.05)
    finally:
        sys.stdout.write(SHOW); sys.stdout.flush()

if __name__=='__main__': main()
