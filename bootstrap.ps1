param(
  [string]$Repo = "https://github.com/<jouw-naam>/the-101-game.git",
  [string]$Path = "$env:USERPROFILE\dev\the-101-game"
)


$ErrorActionPreference = "Stop"

function Ensure-Command($name, $wingetId) {
  if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
      Write-Warning "winget ontbreekt; installeer handmatig $name"
      return
    }
    Write-Host "Installing $wingetId ..."
    winget install --id $wingetId -e --accept-package-agreements --accept-source-agreements | Out-Null
  }
}

function To-PascalCase { param([string]$s)
  return ($s -split '_') | Where-Object { $_ -ne '' } | ForEach-Object {
    if ($_.Length -le 1) { $_.ToUpper() } else { $_.Substring(0,1).ToUpper() + $_.Substring(1).ToLower() }
  } | ForEach-Object { $_ } -join ''
}
# Gebruik:
# $KeyPascal = To-PascalCase $Key
# "$KeyPascal:"

function shot { param([string]$Target = '')
  if ([string]::IsNullOrWhiteSpace($Target)) { $Target = 'screen' }
  Write-Host 'shot:' $Target
}


# 1) Tools (Git, Python 3.11, VS Code, FFmpeg, 7-Zip)
Ensure-Command git.exe           "Git.Git"
Ensure-Command py.exe            "Python.Python.3.11"
Ensure-Command code.exe          "Microsoft.VisualStudioCode"
Ensure-Command ffmpeg.exe        "Gyan.FFmpeg"
Ensure-Command 7z.exe            "7zip.7zip"

# 2) Clone of update
if (-not (Test-Path $Path)) { New-Item -ItemType Directory -Force -Path $Path | Out-Null }
Set-Location $Path

if (-not (Test-Path (Join-Path $Path ".git"))) {
  if ($Repo -and $Repo -ne "-") {
    git clone $Repo . 
  } else {
    Write-Host "Repo is lokaal; oversla clonen."
  }
} else {
  try { git pull --rebase } catch { Write-Warning "Git pull faalde; ga verder." }
}

# 3) Virtuele omgeving + pygame
if (-not (Test-Path ".venv")) { py -m venv .venv }
$py = ".\.venv\Scripts\python.exe"
& $py -m pip install --upgrade pip
& $py -m pip install pygame

# 4) tools\game-dev.ps1 neerzetten
if (-not (Test-Path ".\tools")) { New-Item -ItemType Directory -Force -Path .\tools | Out-Null }

@"
# tools\game-dev.ps1 — scene runner & helpers
`$script:ROOT = (Get-Location).Path

function w { param([Parameter(ValueFromRemainingArguments=`$true)][string[]]`$Args)
  `$t = if (`$Args.Count) { `$Args[0] } else { "" }
  python "`$script:ROOT\engine.py" --scene `$t
}
function wm { param([string]`$t="") python "`$script:ROOT\engine.py" --windowed --scene `$t }
function ws { param([string]`$t="") python "`$script:ROOT\engine.py" --silent   --scene `$t }

1..10 | % { `$i = `$_ - 1; Set-Item -Path Function:\("w`$i") -Value ([scriptblock]::Create("python `"`$script:ROOT\engine.py`" --scene `$i")) }

function mix { python "`$script:ROOT\engine.py" --scene dev_settings }

function bpm { param([double]`$Value)
  if (-not `$Value) { Write-Host "usage: bpm <number>"; return }
  `$s = if (Test-Path data\settings.json) { Get-Content data\settings.json -Raw | ConvertFrom-Json } else { New-Object psobject }
  `$s | Add-Member -NotePropertyName music_bpm -NotePropertyValue `$Value -Force
  `$s | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 data\settings.json
  Write-Host "BPM -> `$Value"
}
function vol { param([double]`$Music, [double]`$Sfx=`$Music)
  if (`$null -eq `$Music) { Write-Host "usage: vol <music 0..1> [sfx 0..1]"; return }
  `$s = if (Test-Path data\settings.json) { Get-Content data\settings.json -Raw | ConvertFrom-Json } else { New-Object psobject }
  `$s | Add-Member -NotePropertyName music_volume -NotePropertyValue `$Music -Force
  `$s | Add-Member -NotePropertyName sfx_volume   -NotePropertyValue `$Sfx   -Force
  `$s | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 data\settings.json
  Write-Host "Volumes -> music=`$Music sfx=`$Sfx"
}

function _read-worlds {
  if (Test-Path "`$script:ROOT\data\worlds.json") {
    try { (Get-Content "`$script:ROOT\data\worlds.json" -Raw | ConvertFrom-Json) } catch { @() }
  } else { @() }
}

function new-world { param([Parameter(Mandatory=`$true)][string]`$Key)
  `$path = "scenes\`$Key.py"
  if (Test-Path `$path) { Write-Warning "`$path bestaat al"; return }
  @"
import pygame

class $(($Key -replace '(^|_)(\w)', { `$_.Groups[2].Value.ToUpper() })):
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
"@ | Set-Content -Encoding utf8 `$path

  `$worlds = _read-worlds
  if (`$worlds -isnot [System.Array]) { `$worlds = @() }
  if (`$worlds -notcontains `$Key) { `$worlds = @(`$worlds + `$Key) }
  `$worlds | ConvertTo-Json | Set-Content -Encoding utf8 data\worlds.json
  Write-Host "World scaffolded: `$path"
}

function shot { param([string]`$Target = "")
  python "`$script:ROOT\engine.py" --scene `$Target --windowed --shotdir screenshots
}
"@ | Set-Content -Encoding utf8 .\tools\game-dev.ps1

# 5) VS Code tasks (Ctrl+Shift+B) en extensie-aanbevelingen
if (-not (Test-Path ".vscode")) { New-Item -ItemType Directory -Force -Path .\.vscode | Out-Null }

@"
{
  "version": "2.0.0",
  "tasks": [
    { "label": "Run W0",           "type": "shell", "command": "powershell -NoProfile -ExecutionPolicy Bypass -Command \". .\\tools\\game-dev.ps1; w 0\"" },
    { "label": "Run W1",           "type": "shell", "command": "powershell -NoProfile -ExecutionPolicy Bypass -Command \". .\\tools\\game-dev.ps1; w 1\"" },
    { "label": "Run Mixer (ESC)",  "type": "shell", "command": "powershell -NoProfile -ExecutionPolicy Bypass -Command \". .\\tools\\game-dev.ps1; mix\"" },
    { "label": "Run Scene (prompt)","type": "shell", "command": "powershell -NoProfile -ExecutionPolicy Bypass -Command \"\$s = Read-Host 'scene key or index'; . .\\tools\\game-dev.ps1; w \$s\"" },
    { "label": "Windowed W0",      "type": "shell", "command": "powershell -NoProfile -ExecutionPolicy Bypass -Command \". .\\tools\\game-dev.ps1; wm 0\"" },
    { "label": "Screenshot W0",    "type": "shell", "command": "powershell -NoProfile -ExecutionPolicy Bypass -Command \". .\\tools\\game-dev.ps1; shot 0\"" }
  ]
}
"@ | Set-Content -Encoding utf8 .\.vscode\tasks.json

@"
{
  "recommendations": [
    "ms-python.python",
    "ms-python.vscode-pylance",
    "github.copilot"
  ]
}
"@ | Set-Content -Encoding utf8 .\.vscode\extensions.json

# 6) Workspace openen
code .
Write-Host "Bootstrap done. In VS Code: Ctrl+Shift+B -> kies een task (Run W0 / Mixer / etc.)"
