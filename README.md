hier is je nieuwe ‘README.md’, strak, Windows-first, toetsenbord-only, zonder ‘play.bat’. plak ’m letterlijk.

````markdown
# The 101 Game — zero-friction start (Windows)

**Pull → Run → Play.** Geen `play.bat` meer. Puur PowerShell, venv auto-setup, en draaien.

_Nederlands?_ Zie `README.nl.md`.

---

## TL;DR — begin hier

1. Open PowerShell. _Sneltoets_: Win+R → typ `powershell` → Enter.
2. Plak dit blok en druk Enter na elke regel:

```powershell
winget install --id Git.Git -e --source winget
git clone https://github.com/meneer-van-informatica/the-101-game.git
Set-Location .\the-101-game

# eenmalig in deze sessie, voor het activeren van venv-scripts
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# maak en activeer venv (Python 3.12 aanbevolen)
py -3.12 -m venv .venv
. .\.venv\Scripts\Activate.ps1

# deps en run
python -m pip install --upgrade pip
pip install -r .\requirements.txt
python .\main.py
````

> Werkt `py` niet? Vervang de venv-regel door: `python -m venv .venv`.

---

## Wat doet dit?

* **Maakt `.venv`** als die nog niet bestaat en **installeert `requirements.txt`**.
* **Start het spel** via `main.py`. Heb je `game.py` of `app.py`? Run dan:

  * `python .\game.py` *of* `python .\app.py`.

---

## Waarom geen `play.bat`?

* PowerShell is **veiliger en transparanter**.
* Je ziet **precies** wat er gebeurt en kunt elke stap herstellen.
* Eén README-blok werkt op **elke** standaard Windows-installatie.

---

## Visie (WIP, compact)

* **Plan**: 10 werelden × 10 levels + 1 finale = **101**.
* **Ritme per level**: Hook 5s → Do 40s → Proof 15s → Next 1s.
* **Format**: titel (1 regel) + test(s) + mini-check → Enter voor volgende.
* **Auteur-regel**: elk level leert **exact 1** ding.

**Wereldkaart (voorbeeld)**
W0 Bits & Logic → binary, XOR, K-map, adder
W1 Algorithms → linear/binary, sort, invariant
W2 Data & DB → ER, 1–3NF, select/project/join
W3 Machines → FSM, fetch-decode-execute, pipeline
W4 Networks → packet, DNS, HTTP, idempotent
W5 AI-Basics → split, loss, metric, bias
W6 Robot-Choreo → states, millis-timing, tempo
W7 Sensing & Control → noise, Kalman-intuition, PID
W8 Product & Pitch → BOM, margin, poster, consent
W9 Ethics & Show → safety, no-face, audience
L100 Finale → ‘all together’ bossfight met 3 checks

---

## Voor beginners — ‘Hee Domme Robot’ (Windows)

Je bent hier nieuw. Mooi. Open PowerShell: **Win+R → `powershell` → Enter**.
Kopieer dan het **TL;DR-blok** hierboven. Dat is **Stap 0**.
Computer is snel in rekenen, jij wordt slim door **te proberen**. Klaar? **Run.**

---

## Contribute

Zie `CONTRIBUTING.md`. Nieuwe dev-flow: **AI-assisted**, **Windows PowerShell**, **minimal VS Code**.

---

## Contact

Zie `CONTACT.md`.

---

## License

MIT — zie `LICENSE`.

````

### plus: mini ‘scripts\w0.ps1’ (optioneel, maar handig)
Wil je toch ‘één commando’? Maak dit script aan en roep ’m zo aan: `powershell -File .\scripts\w0.ps1`

```powershell
param([switch]$Upgrade)

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
if (-not (Test-Path '.\.venv\Scripts\Activate.ps1')) { py -3.12 -m venv .venv }
. .\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
if ($Upgrade -or -not (Test-Path '.\rich_installed.flag')) {
  pip install -r .\requirements.txt
  New-Item -ItemType File -Path .\rich_installed.flag -Force | Out-Null
}
if (Test-Path '.\main.py') { python .\main.py }
elseif (Test-Path '.\game.py') { python .\game.py }
elseif (Test-Path '.\app.py') { python .\app.py }
else { Write-Host 'geen entry file gevonden (main.py/game.py/app.py)'; exit 1 }
````

### keuzemenu

\[A] ik maak meteen `README.nl.md` met identieke stappen in het Nederlands
\[B] ik voeg `scripts\w0.ps1` toe en update `README.md` met de one-liner start
\[C] ik zet CI op Windows aan met `ruff + pytest` bij elke push
\[D] #route4: ik voeg ‘/docs/kern10.html’ toe aan je site en link ’m vanaf home

Volg Mij en het Komt Goed, lul. Namens LMW.

```powershell
git add README.md
git commit -m 'docs: zero-friction Windows README; remove play.bat path'
git push
```
