Hier is een **vernieuwde `README.md`** die je 1-op-1 kunt plakken. Windows-first, toetsenbord-only, geen `play.bat`, alles in simpele stappen.

````
# The 101 Game — zero-friction start (Windows)

**Pull → Run → Play.** Geen 'play.bat' meer. Puur PowerShell, venv auto-setup, en draaien.

_Nederlands?_ Zie 'README.nl.md'.

---

## TL;DR — begin hier

1. Open PowerShell. _Sneltoets_: Win+R → typ 'powershell' → Enter.
2. Plak dit blok en druk Enter na elke regel:

```powershell
winget install --id Git.Git -e --source winget
git clone https://github.com/meneer-van-informatica/the-101-game.git
Set-Location .\the-101-game

# eenmalig in deze sessie, om venv-scripts te activeren
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# maak en activeer venv (Python 3.12 aanbevolen)
py -3.12 -m venv .venv
. .\.venv\Scripts\Activate.ps1

# deps en run
python -m pip install --upgrade pip
pip install -r .\requirements.txt
python .\main.py
````

> Werkt 'py' niet? Vervang de venv-regel door: `python -m venv .venv`.

---

## Wat doet dit?

* **Maakt '.venv'** als die nog niet bestaat en **installeert 'requirements.txt'**.
* **Start het spel** via 'main.py'. Heb je 'game.py' of 'app.py'? Run dan:

  * `python .\game.py` of `python .\app.py`.

---

## Eén-commando start (optioneel)

Wil je een snelstart? Maak 'scripts\w0.ps1' met onderstaande inhoud en start met:
`powershell -File .\scripts\w0.ps1`

```powershell
param([switch]$Upgrade)

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
if (-not (Test-Path '.\.venv\Scripts\Activate.ps1')) { py -3.12 -m venv .venv }
. .\.venv\Scripts\Activate.ps1

python -m pip install --upgrade pip
if ($Upgrade -or -not (Test-Path '.\deps_ok.flag')) {
  pip install -r .\requirements.txt
  New-Item -ItemType File -Path .\deps_ok.flag -Force | Out-Null
}

if (Test-Path '.\main.py')      { python .\main.py }
elseif (Test-Path '.\game.py')  { python .\game.py }
elseif (Test-Path '.\app.py')   { python .\app.py }
else {
  Write-Host 'geen entry file gevonden (main.py/game.py/app.py)' -ForegroundColor Yellow
  exit 1
}
```

---

## Voor beginners — 'Hee Domme Robot' (Windows)

Nieuw hier? Mooi. Open PowerShell: **Win+R → 'powershell' → Enter**.
Kopieer dan het **TL;DR-blok** hierboven. Dat is **Stap 0**.
De computer rekent snel; jij wordt slim door **te proberen**. Klaar? **Run.**

---

## Troubleshooting (Windows)

* **'py' bestaat niet**: gebruik `python -m venv .venv` in plaats van `py -3.12 -m venv .venv`.
* **ExecutionPolicy-fout**: zet tijdelijk alleen voor deze sessie:
  `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force`
* **exFAT/USB 'dubious ownership'**:
  `git config --global --add safe.directory (git rev-parse --show-toplevel)`
* **Virtuele omgeving vergeten te activeren**: run
  `. .\.venv\Scripts\Activate.ps1` en probeer opnieuw.

---

## Visie (compact)

* **Plan**: 10 werelden × 10 levels + 1 finale = **101**.
* **Ritme per level**: Hook 5s → Do 40s → Proof 15s → Next 1s.
* **Format**: titel (1 regel) + tests + mini-check → Enter voor de volgende.
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
L100 Finale → 'all together' bossfight met 3 checks

---

## Contribute

Zie 'CONTRIBUTING.md'. Nieuwe dev-flow: **AI-assisted**, **Windows PowerShell**, **minimal VS Code**.

---

## Contact

Zie 'CONTACT.md'.

---

## License

MIT — zie 'LICENSE'.

````

### Keuzemenu
[A] ik lever meteen ‘README.nl.md’ met identieke stappen in het Nederlands  
[B] ik voeg ‘scripts\w0.ps1’ toe en koppel de one-liner in de README  
[C] ik zet CI op Windows aan met ‘ruff + pytest’ bij elke push  
[D] #route4: ik publiceer ‘/docs/kern10.html’ en link ’m vanaf de homepage

Volg Mij en het Komt Goed, lul. Namens LMW.

```powershell
git add README.md
git commit -m 'docs: zero-friction Windows README (PowerShell-first, no play.bat)'
git push
````
