## Quick Start

**Run de game**
```powershell
.\play.bat

### World shortcuts
- **Start W0 (first world):**
  ```powershell
  .\w0.bat

# The 101 Game — Open Project

**Meedoen? Leuk!** Dit is een open project voor leerlingen en makers. Je mag features voorstellen en bouwen — **merge gebeurt alleen na akkoord van de maintainer (👑 jij).**

## Hoe voeg je een feature toe?

1) **Bespreek eerst**  
   - Maak een Issue met label **proposal**.  
   - Titel: `feat: <korte titel>`  
   - Beschrijf: *Waarom*, *Wat is de UX*, *Wat is “Done”*, *Screens/shots (schetsen oké)*.

2) **Fork & Branch**  
   - Fork de repo.  
   - Branch: `feat/<korte-naam>` (bijv. `feat/w0_f4_gol-oscillator`).

3) **Bouw minimaal, werkend, testbaar**  
   - Nieuwe scene? Plaats ‘m in `scenes/` met duidelijke naam (bijv. `w0_f4_*.py`).  
   - Houd scenes **klein** (één doel). Gebruik bestaande services uit `engine.py` (`audio`, `tts`, `progress`).  
   - Assets → `data/sfx/`, `data/music/` (noem bron/licentie in de PR).  
   - UI-tekst: simpel, leesbaar; toetsen altijd onderin tonen.  
   - Zorg dat het **zonder internet** draait.

4) **Check & bewijs**  
   - Lokale sanity: `.\scripts\sanity.ps1` (PNG’s in `screenshots\sanity_*`).  
   - Shots: `shot <scene>` en voeg 1–2 PNG’s toe aan de PR als bewijs.  
   - Startflows die werken:
     - `python engine.py --start w0_f0_square`
     - `python engine.py --start w0_f1` / `w0_f2` / `w0_f3`
     - `python engine.py --start w0 --snapshot`
   - Geen tracebacks; console schoon (behalve bekende pygame-warning).

5) **Maak je PR**  
   - Titel: `feat: <korte titel>`  
   - Beschrijf: *Wat is nieuw*, *Controls*, *Hoe te testen*, *Screenshots*.  
   - Beperk diff tot wat je nodig hebt (geen screenshots of .bak in Git).  
   - Voeg je Issue-nummer toe: `Closes #123`.

6) **Review & akkoord**  
   - Maintainer checkt UX, code & performance.  
   - Eventuele aanpassingen → pushen op dezelfde branch.  
   - **Merge pas na maintainer-akkoord.**

### Definition of Done (acceptatiecriteria)

- [ ] Start en werkt met: `python engine.py --start <jouw-scene>`  
- [ ] **Controls** in beeld en consistent met rest (L-click, Space, N, C, Esc, etc.)  
- [ ] **Geen crashes**; `.\scripts\sanity.ps1` levert PNG’s op  
- [ ] Shots toegevoegd in de PR-beschrijving  
- [ ] Geen grote dependency erbij; geen zware assets  
- [ ] Licenties voor meegeleverde assets vermeld

### Richtlijnen (kort)

- **Naamgeving**: `w0_fN_<onderwerp>.py` voor W0; losse frames `frame_<naam>.py`.  
- **Kleine PR’s** > grote PR’s. Houd engine-wijzigingen minimaal.  
- **Code style**: Python 3.11+, geen zware frameworks; Pygame API; heldere functies.  
- **Persist**: gebruik `Progress()` alleen als het echt nodig is (bijv. level-unlocks).  
- **Audio**: gebruik synth-bleeps/sfx in `data/sfx`; volumes via `data/settings.json` (`sfx_volume`).  
- **Niet committen**: `screenshots/`, `logs/`, `*.bak` (zie `.gitignore`).  

> Tip: Gebruik `ts` om snel een timestamp-commit te pushen (handig voor CI en activiteit).

---

*Maintainer note (alleen informatief):*  
Je kunt jezelf als verplichte reviewer instellen via **CODEOWNERS**:

