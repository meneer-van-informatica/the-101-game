# scenes/sceneC2_hue_status.py — Level 2: Hue status + snelle acties
# keys:
#   r  refresh
#   [digits]+Enter  selecteer lamp-id (ook 2-cijferig)
#   g  groen (selected)   |   G  groen (alle)
#   o  aan (selected)     |   f  uit (selected)
#   + / -  brightness up/down (selected)
#   a  toggle alle (groups/0)
#   q  quit

import os, sys, time, json, urllib.request

# core-fallback
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

def api_get(path, timeout=5):
    with open(CFG, "r", encoding="utf-8") as f:
        cfg = json.load(f)
    url = f"http://{cfg['ip']}/api/{cfg['username']}/{path}"
    with urllib.request.urlopen(url, timeout=timeout) as resp:
        return json.loads(resp.read().decode("utf-8"))

def api_put(path, body, timeout=5):
    with open(CFG, "r", encoding="utf-8") as f:
        cfg = json.load(f)
    url = f"http://{cfg['ip']}/api/{cfg['username']}/{path}"
    data = json.dumps(body).encode("utf-8")
    req = urllib.request.Request(url, data=data, method="PUT")
    req.add_header("Content-Type", "application/json")
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return json.loads(resp.read().decode("utf-8"))

def load_lights():
    # 1) normaal: /lights
    try:
        L = api_get("lights")
        if isinstance(L, dict) and len(L)>0:
            return L
    except Exception:
        pass
    # 2) fallback: pak ids via groups/0
    try:
        G = api_get("groups")
        g0 = G.get("0") or {}
        ids = g0.get("lights", [])
        out = {}
        for lid in ids:
            try:
                out[lid] = api_get(f"lights/{lid}")
            except Exception:
                pass
        return out
    except Exception:
        return {}

def to_rows(lights):
    rows=[]
    for lid in sorted(lights, key=lambda x:int(x)):
        L = lights[lid]; st=L.get("state",{})
        rows.append((lid, "ON " if st.get("on") else "off",
                     "{:3}".format(st.get("bri",0)) if st.get("bri") is not None else "  -",
                     L.get("name","-")))
    return rows

def render(lights, sel="", note="", pulse=False):
    lines = []
    lines.append("  Level C/2: Hue status (selecteer id, stuur acties)")
    lines.append("")
    if not lights:
        lines.append("[info] geen lampen gevonden (check Hue-app en Bridge).")
    else:
        lines.append(" id  on   bri   name")
        lines.append(" --  ---  ----  -------------------------")
        for lid, on, bri, name in to_rows(lights):
            label = f" {lid:<2}  {on}  {bri}   {name}"
            if str(lid)==str(sel):
                lines.append(BRIGHT + label + RESET)
            else:
                lines.append(label)
    if note: lines += ["", note]
    lines += ["", "keys: r refresh | digits+Enter select | g/G groen | o/f aan/uit | +/- bri | a toggle alle | q quit"]
    fast_render(lines, BRIGHT if pulse else DIM)

def clamp(v, lo, hi): return max(lo, min(hi, v))

def set_green_selected(lid):
    return api_put(f"lights/{lid}/state", {"on": True, "bri": 254, "hue": 25500, "sat": 254})

def set_bri_selected(lid, lights, delta):
    st = lights[str(lid)].get("state", {})
    cur = int(st.get("bri", 254))
    return api_put(f"lights/{lid}/state", {"bri": clamp(cur+delta, 1, 254)})

def toggle_all():
    # haal groups/0 state op en flip
    G = api_get("groups")
    g0 = G.get("0") or {}
    now_on = bool(g0.get("state",{}).get("any_on", False))
    return api_put("groups/0/action", {"on": (not now_on)})

def main():
    if not os.path.exists(CFG):
        fast_render(["Geen hue_config.json; run eerst C1 (pair)."], DIM); time.sleep(1.2); return

    sys.stdout.write(HIDE); sys.stdout.flush()
    try:
        lights = load_lights()
        selected = next(iter(sorted(lights, key=lambda x:int(x))), "") if lights else ""
        buf = ""  # digits buffer
        render(lights, selected, pulse=True)
        last_pulse = time.perf_counter(); pulse=False
        note = ""

        while True:
            # pulse
            if time.perf_counter()-last_pulse > 0.6:
                pulse = not pulse; last_pulse = time.perf_counter()
                render(lights, selected, note, pulse); note=""

            # input
            try:
                import msvcrt
                while msvcrt.kbhit():
                    b = msvcrt.getch()
                    if b in (b'\x1b', b'q', b'Q'): raise KeyboardInterrupt
                    if b in (b'r', b'R'):
                        lights = load_lights(); render(lights, selected, "[ok] refreshed", True); continue
                    if b in (b'\r', b'\n'):
                        if buf:
                            selected = buf; buf=""
                            render(lights, selected, f"[ok] geselecteerd: {selected}", True)
                        continue
                    ch = b.decode("utf-8","ignore")
                    if ch.isdigit():
                        buf += ch; render(lights, selected, f"select buffer: {buf}", True); continue
                    if ch in ('g','G'):
                        if ch=='G':
                            api_put("groups/0/action", {"on": True, "bri": 254, "hue": 25500, "sat": 254})
                            render(lights, selected, "[ok] alles -> groen", True)
                        elif selected:
                            set_green_selected(selected); lights = load_lights()
                            render(lights, selected, f"[ok] lamp {selected} -> groen", True)
                        continue
                    if ch in ('o','O') and selected:
                        api_put(f"lights/{selected}/state", {"on": True}); lights=load_lights()
                        render(lights, selected, f"[ok] lamp {selected} -> ON", True); continue
                    if ch in ('f','F') and selected:
                        api_put(f"lights/{selected}/state", {"on": False}); lights=load_lights()
                        render(lights, selected, f"[ok] lamp {selected} -> off", True); continue
                    if ch in ('+','=') and selected:
                        set_bri_selected(selected, lights, +20); lights=load_lights()
                        render(lights, selected, f"[ok] bri +", True); continue
                    if ch in ('-','_') and selected:
                        set_bri_selected(selected, lights, -20); lights=load_lights()
                        render(lights, selected, f"[ok] bri -", True); continue
                    if ch in ('a','A'):
                        toggle_all(); lights=load_lights()
                        render(lights, selected, "[ok] toggle alle", True); continue
            except KeyboardInterrupt:
                break
            except Exception:
                pass
            time.sleep(0.02)
    finally:
        sys.stdout.write(SHOW); sys.stdout.flush()

if __name__ == "__main__":
    main()
