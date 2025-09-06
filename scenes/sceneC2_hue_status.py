# scenes/sceneC2_hue_status.py — Level 2: Hue status lezen en simpele toggle
# keys: [r] refresh  | [1-9] toggle lamp id  | [q] quit
import os, sys, time, json, urllib.request

# core fallback
try:
    from core.rt import fast_render, BRIGHT, DIM, HIDE, SHOW
except Exception:
    ESC="\x1b"; HIDE=ESC+"[?25l"; SHOW=ESC+"[?25h"; BRIGHT=ESC+"[1m"; DIM=ESC+"[2m"; RESET="\x1b[0m"
    def fast_render(lines, style=""):
        sys.stdout.write(ESC+"[2J"+ESC+"[H")
        if style: sys.stdout.write(style)
        for ln in lines: sys.stdout.write(ln+"\n")
        if style: sys.stdout.write(RESET)
        sys.stdout.flush()

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
CFG  = os.path.join(ROOT, "data", "hue_config.json")

def api_get(path):
    with open(CFG, "r", encoding="utf-8") as f:
        cfg = json.load(f)
    url = f"http://{cfg['ip']}/api/{cfg['username']}/{path}"
    with urllib.request.urlopen(url, timeout=5) as resp:
        return json.loads(resp.read().decode("utf-8"))

def api_put(path, body):
    with open(CFG, "r", encoding="utf-8") as f:
        cfg = json.load(f)
    url = f"http://{cfg['ip']}/api/{cfg['username']}/{path}"
    data = json.dumps(body).encode("utf-8")
    req = urllib.request.Request(url, data=data, method="PUT")
    req.add_header("Content-Type", "application/json")
    with urllib.request.urlopen(req, timeout=5) as resp:
        return json.loads(resp.read().decode("utf-8"))

def render(lights, note="", pulse=False):
    lines = []
    lines.append("  Level C/2: Hue status")
    lines.append("")
    if not lights:
        lines.append("[info] geen lampen gevonden.")
    else:
        lines.append(" id  on   bri   name")
        lines.append(" --  ---  ----  -------------------------")
        for lid in sorted(lights, key=lambda x: int(x)):
            L = lights[lid]
            st = L.get("state", {})
            on = "ON " if st.get("on") else "off"
            bri= "{:3}".format(st.get("bri", 0)) if st.get("bri") is not None else "  -"
            nm = L.get("name","-")
            label = f" {lid:<2}  {on}  {bri}   {nm}"
            lines.append((BRIGHT + label + RESET) if pulse and st.get("on") else label)
    if note: lines += ["", note]
    lines += ["", "keys: [r] refresh   |  [1-9] toggle lamp-id  |  [q] quit"]
    fast_render(lines, BRIGHT if pulse else DIM)

def load_lights():
    try:
        return api_get("lights")
    except Exception as e:
        return {}

def toggle(lid, lights):
    try:
        L = lights.get(lid)
        if not L: return "lamp niet gevonden"
        current = bool(L.get("state",{}).get("on"))
        new = not current
        api_put(f"lights/{lid}/state", {"on": new})
        return f"lamp {lid} -> {'ON' if new else 'off'}"
    except Exception as e:
        return f"toggle fout: {e.__class__.__name__}"

def main():
    if not os.path.exists(CFG):
        fast_render(["Geen hue_config.json; run eerst C1 (pair)."], DIM); time.sleep(1.2); return

    sys.stdout.write(HIDE); sys.stdout.flush()
    try:
        lights = load_lights()
        render(lights, note="Druk [r] om te refreshen of [1-9] om snel een lamp te togglen.", pulse=True)
        last_pulse = time.perf_counter()
        pulse=False

        while True:
            # klein pulse-effect
            if time.perf_counter()-last_pulse > 0.6:
                pulse = not pulse
                last_pulse = time.perf_counter()
                render(lights, pulse=pulse)

            # input
            try:
                import msvcrt
                if msvcrt.kbhit():
                    b = msvcrt.getch()
                    if b in (b'\x1b', b'q', b'Q'):
                        break
                    if b in (b'r', b'R'):
                        lights = load_lights()
                        render(lights, note="[ok] ververst.", pulse=True)
                        continue
                    ch = b.decode("utf-8","ignore")
                    if ch and ch.isdigit() and ch != '0':
                        msg = toggle(ch, lights)
                        lights = load_lights()
                        render(lights, note=msg, pulse=True)
                        continue
            except Exception:
                pass
            time.sleep(0.02)
    finally:
        sys.stdout.write(SHOW); sys.stdout.flush()

if __name__ == "__main__":
    main()
