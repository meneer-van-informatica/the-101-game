# the-101-game

Rammen-mode: je game eerst. Audio is onderliggend. Je krijgt 1) een **scene-runner** (W0–W9 in 1 woord), 2) **CLI-start per wereld** in de engine, 3) **must-have PS-commands** die je overal kunt plakken, 4) bonus: **F12 screenshot** en snelle settings-tweaks. Alles PowerShell-only, no mouse.

# 1) CLI: start elke wereld direct uit de engine

Voeg **scene-keuze** en **F12 screenshot** toe. Open `engine.py` en maak deze kleine patches.

**A. args: voeg `--scene` en `--shotdir` toe**

```python
def parse_args():
    p = argparse.ArgumentParser(description='The 101 Game')
    p.add_argument('--silent', action='store_true', help='skip audio init but still render/update')
    p.add_argument('--windowed', action='store_true', help='force windowed mode (override settings)')
    p.add_argument('--scene', type=str, default='', help='start scene by key (e.g. level_story_one) or index (e.g. 0..9)')
    p.add_argument('--shotdir', type=str, default='screenshots', help='folder for F12 screenshots')
    return p.parse_args()
```

**B. helper om een scene te resolven (index of naam)**
Zet dit boven je `class Game:` of als staticmethod in Game.

```python
def resolve_scene_key(requested: str, default_key: str = 'scene_picker'):
    if not requested:
        return default_key
    # index? probeer data/worlds.json in te lezen
    try:
        with open(os.path.join('data', 'worlds.json'), 'r', encoding='utf-8') as f:
            worlds = json.load(f) or []
    except Exception:
        worlds = []
    if requested.isdigit():
        i = int(requested)
        if 0 <= i < len(worlds):
            return worlds[i]
        return default_key
    # anders neem de string als key
    return requested
```

**C. gebruik ‘m bij je startscene**
In `Game.__init__` (na `self.scene_classes = import_scenes()`):

```python
start_key = resolve_scene_key(getattr(args, 'scene', ''), 'scene_picker')
self.scene_key, self.scene = make_scene(start_key, self.scene_classes, self.services)
```

**D. F12 screenshot in je event-loop**
In `Game.run()` binnen `if e.type == pygame.KEYDOWN:` voeg toe:

```python
if e.key == pygame.K_F12:
    os.makedirs(getattr(args, 'shotdir', 'screenshots'), exist_ok=True)
    ts = pygame.time.get_ticks()
    path = os.path.join(getattr(args, 'shotdir', 'screenshots'), f'{self.scene_key}_{ts}.png')
    pygame.image.save(self.screen, path)
    print('[SHOT]', path)
    continue
```

Nu kun je elke wereld direct starten:

```
python engine.py --scene 0      # W0 via index uit data/worlds.json
python engine.py --scene typing_ad
python engine.py --scene dev_settings --windowed
```

# 2) Eén PS-script dat jouw flow turbo maakt

Maak `tools\game-dev.ps1` (new folder **tools**).

```powershell
# tools\game-dev.ps1  — rammen toolkit (importeer met: . .\tools\game-dev.ps1)

$script:ROOT = (Get-Location).Path

function _read-worlds {
  if (Test-Path "$script:ROOT\data\worlds.json") {
    try { (Get-Content "$script:ROOT\data\worlds.json" -Raw | ConvertFrom-Json) } catch { @() }
  } else { @() }
}

function w {
  param([Parameter(ValueFromRemainingArguments=$true)][string[]]$Args)
  $target = if ($Args.Count) { $Args[0] } else { "" }
  python "$script:ROOT\engine.py" --scene $target
}

function wm { param([string]$Target="") python "$script:ROOT\engine.py" --windowed --scene $Target }
function ws { param([string]$Target="") python "$script:ROOT\engine.py" --silent   --scene $Target }

# snelle aliases w0..w9 (op basis van worlds.json index)
1..10 | ForEach-Object {
  $i = $_ - 1
  Set-Item -Path Function:\("w$i") -Value ([scriptblock]::Create("python `"$script:ROOT\engine.py`" --scene $i"))
}

# dev helpers
function mix { python "$script:ROOT\engine.py" --scene dev_settings }
function bpm {
  param([double]$Value)
  if (-not $Value) { Write-Host "usage: bpm <number>"; return }
  $s = if (Test-Path data\settings.json) { Get-Content data\settings.json -Raw | ConvertFrom-Json } else { New-Object psobject }
  $s | Add-Member -NotePropertyName music_bpm -NotePropertyValue $Value -Force
  $s | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 data\settings.json
  Write-Host "BPM -> $Value"
}
function vol {
  param([double]$Music, [double]$Sfx=$Music)
  if ($null -eq $Music) { Write-Host "usage: vol <music 0..1> [sfx 0..1]"; return }
  $s = (Get-Content data\settings.json -Raw | ConvertFrom-Json)
  $s | Add-Member -NotePropertyName music_volume -NotePropertyValue $Music -Force
  $s | Add-Member -NotePropertyName sfx_volume -NotePropertyValue $Sfx   -Force
  $s | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 data\settings.json
  Write-Host "Volumes -> music=$Music sfx=$Sfx"
}

# world scaffold
function new-world {
  param([Parameter(Mandatory=$true)][string]$Key)
  $path = "scenes\$Key.py"
  if (Test-Path $path) { Write-Warning "$path bestaat al"; return }
  @"
import pygame

class $(($Key -replace '(^|_)(\w)', { $_.Groups[2].Value.ToUpper() }) ):
    def __init__(self, services):
        self.services = services
        self.audio = services.get('audio')
        self.progress = services.get('progress')
        self.settings = services.get('settings', {})
        self.font = pygame.font.SysFont(self.settings.get('font_name') or pygame.font.get_default_font(), 32)
        self.next_scene = None
        self.done = False
        if self.audio: self.audio.play_for('$Key')

    def handle_event(self, e):
        if e.type == pygame.KEYDOWN and e.key in (pygame.K_RETURN, pygame.K_SPACE):
            self.progress.mark_complete('$Key')
            self.next_scene = 'scene_picker'
        elif e.type == pygame.KEYDOWN and e.key == pygame.K_ESCAPE:
            self.next_scene = 'scene_picker'

    def update(self, dt): pass

    def draw(self, screen):
        screen.fill((16,18,26))
        txt = self.font.render('$Key', True, (230,240,255))
        w,h = screen.get_size()
        screen.blit(txt, (w//2 - txt.get_width()//2, h//2 - txt.get_height()//2))
"@ | Set-Content -Encoding utf8 $path

  # wereld registreren in data/worlds.json (achteraan toevoegen)
  $worlds = _read-worlds
  if ($worlds -isnot [System.Array]) { $worlds = @() }
  if ($worlds -notcontains $Key) { $worlds = @($worlds + $Key) }
  $worlds | ConvertTo-Json | Set-Content -Encoding utf8 data\worlds.json

  Write-Host "World scaffolded: $path"
}

# screenshot vanuit CLI (zonder toetsen): rendert 1 frame en schrijft png
function shot {
  param([string]$Target = "")
  python "$script:ROOT\engine.py" --scene $Target --windowed --shotdir screenshots
}
```

**Gebruik (in projectroot):**

```powershell
. .\tools\game-dev.ps1     # 1x per shell

w0                         # start W0 
w 3                        # start W3 via index
w typing_ad                # start per key
wm 0                       # windowed
mix                        # ESC/Mixer scene
bpm 96                     # tempo live voor volgende run
vol 0.5 0.6                # music 50%, sfx 60%
new-world world_w4_city    # scaffold W4 en registreer in worlds.json
shot 0                     # screenshot van W0 naar screenshots\
```

# 3) Must-have commands (écht rammen)

**Run & iterate**

* `w0` / `w1` … `w9` — start een wereld direct
* `w <key|index>` — generiek
* `wm <...>` — windowed (presentatie/recording)
* `ws <...>` — silent (CI of zonder audio device)
* `mix` — meteen de Mixer/ESC-scene

**Project hygiene**

* `bpm <n>` / `vol <m> [s]` — settings zonder file openen
* `new-world <key>` — scene scaffold + worlds.json update
* `shot <scene>` — PNG screenshot wegschrijven (F12 ook in-game)

**Git (dag-ritme)**

* Checkpoint klein & vaak
* Branch per feature: `git switch -c feat/w4-city`
* Rebase light: `git pull --rebase`
* Tag releases: `git tag v0.3.0; git push origin v0.3.0`
* Stash snel: `git stash -k` (houd staged) / `git stash pop`

# 4) (Optioneel) r-alias voor ultiem kort

Wil je 1 letter voor W0 in deze repo?

```powershell
Set-Content -Encoding ascii -NoNewline .\r.bat 'python .\engine.py --scene 0 %*'
Set-Alias r '.\r.bat'
r
```

Rammen = korte loops: `new-world`, `wN`, tweak, F12, commit. Geen muis, nul frictie.

**Copy-paste: commit & push**

```powershell
git add -A
git commit -m "dev: scene runner CLI (--scene), F12 screenshots, tools/game-dev.ps1 with w/wm/ws/w0..w9, bpm/vol, new-world, shot"
git push
```
