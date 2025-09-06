def candidates(preferred=None):
    # combineer pyserial-lijst met brute-force COM3..COM20 en filter bluetooth
    out = []
    seen = set()
    pref = (preferred or '').upper()

    # 1) pyserial
    if serial is not None:
        for p in serial.tools.list_ports.comports():
            dev = p.device
            if dev in seen: 
                continue
            seen.add(dev)
            score = 0
            desc = p.description or dev
            vid = getattr(p, "vid", None)
            pid = getattr(p, "pid", None)
            if pref and dev.upper()==pref: score += 1000
            if vid == 0x2341: score += 400   # Arduino
            if pid in (0x0043, 0x7523): score += 200  # Uno/CH340
            if "Bluetooth" in desc: score -= 500
            out.append((dev, score, desc))

    # 2) brute force COM3..COM20 (voor als pyserial niets/niet alles ziet)
    for n in range(3, 21):
        dev = f"COM{n}"
        if dev in seen: 
            continue
        # sla BT COM3/COM4 vaak over, maar we voegen ze toch met lage score toe
        score = -200 if dev in ("COM3","COM4") else 10
        if pref and dev.upper()==pref: score += 1000
        out.append((dev, score, dev))

    # sorteer
    out.sort(key=lambda r: (-r[1], r[0]))
    return out
