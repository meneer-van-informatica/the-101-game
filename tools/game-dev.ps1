# tools\game-dev.ps1 — scene runner + helpers (robust, PS 5.1)
# Detecteer lokale venv Python, anders val terug op systeem 'python'
$script:ROOT = (Get-Location).Path
$PY = Join-Path $script:ROOT ".venv\Scripts\python.exe"
if (-not (Test-Path $PY)) { $PY = "python" }

function w  { param([Parameter(ValueFromRemainingArguments=$true)][string[]]$Args)
  $t = if ($Args.Count) { $Args[0] } else { "" }
  & $PY "$script:ROOT\engine.py" --scene $t
}
function wm { param([string]$t="") & $PY "$script:ROOT\engine.py" --windowed --scene $t }
function ws { param([string]$t="") & $PY "$script:ROOT\engine.py" --silent   --scene $t }
function mix { & $PY "$script:ROOT\engine.py" --scene dev_settings }

function bpm {
  param([double]$Value)
  if (-not $Value) { Write-Host "usage: bpm <number>"; return }
  $s = if (Test-Path data\settings.json) { Get-Content data\settings.json -Raw | ConvertFrom-Json } else { New-Object psobject }
  $s | Add-Member -NotePropertyName music_bpm  -NotePropertyValue $Value -Force
  $s | Add-Member -NotePropertyName fullscreen -NotePropertyValue $true  -Force
  $s | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 data\settings.json
  Write-Host "BPM -> $Value"
}

function vol {
  param([double]$Music, [double]$Sfx=$Music)
  if ($null -eq $Music) { Write-Host "usage: vol <music 0..1> [sfx 0..1]"; return }
  $s = if (Test-Path data\settings.json) { Get-Content data\settings.json -Raw | ConvertFrom-Json } else { New-Object psobject }
  $s | Add-Member -NotePropertyName music_volume -NotePropertyValue $Music -Force
  $s | Add-Member -NotePropertyName sfx_volume   -NotePropertyValue $Sfx   -Force
  $s | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 data\settings.json
  Write-Host "Volumes -> music=$Music sfx=$Sfx"
}

function new-world {
  param([Parameter(Mandatory=$true)][string]$Key)
  $path = "scenes\$Key.py"
  if (Test-Path $path) { Write-Warning "$path bestaat al"; return }
@"
import pygame
class $(($Key -split '_' | ForEach-Object { if($_){ $_.Substring(0,1).ToUpper()+$_.Substring(1).ToLower() } }) -join ''):
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
            self.progress.mark_complete('$Key'); self.next_scene = 'scene_picker'
        elif e.type == pygame.KEYDOWN and e.key == pygame.K_ESCAPE:
            self.next_scene = 'scene_picker'
    def update(self, dt): pass
    def draw(self, screen):
        screen.fill((16,18,26))
        txt = self.font.render('$Key', True, (230,240,255))
        w,h = screen.get_size()
        screen.blit(txt, (w//2 - txt.get_width()//2, h//2 - txt.get_height()//2))
"@ | Set-Content -Encoding utf8 $path

  $worlds = @()
  if (Test-Path data\worlds.json) { try { $worlds = Get-Content data\worlds.json -Raw | ConvertFrom-Json } catch { $worlds=@() } }
  if ($worlds -isnot [array]) { $worlds = @() }
  if ($worlds -notcontains $Key) { $worlds = @($worlds + $Key) }
  $worlds | ConvertTo-Json | Set-Content -Encoding utf8 data\worlds.json
  Write-Host "World scaffolded: $path"
}

function shot { param([string]$Target = "")
  & $PY "$script:ROOT\engine.py" --scene $Target --windowed --shotdir screenshots
}

function Register-WorldShortcuts {
  # km = KeuzeMenu (scene_picker)
  New-Item -Path Function:\global:km -Value ([ScriptBlock]::Create("& `"$PY`" `"$script:ROOT\engine.py`" --scene scene_picker")) -Force | Out-Null

  # w0 = W0 (The Dog + film)
  New-Item -Path Function:\global:w0 -Value ([ScriptBlock]::Create("& `"$PY`" `"$script:ROOT\engine.py`" --scene level_story_one")) -Force | Out-Null

  # w1 = W1 (Type Tempo)
  New-Item -Path Function:\global:w1 -Value ([ScriptBlock]::Create("& `"$PY`" `"$script:ROOT\engine.py`" --scene typing_ad")) -Force | Out-Null

  # optionele generieke sneltoetsen: w2..w9 via worlds.json index 1..8
  for ($i = 2; $i -le 9; $i++) {
    $idx = $i - 1
    $name = "w$($i)"
    $cmd  = "& `"$PY`" `"$script:ROOT\engine.py`" --scene $idx"
    New-Item -Path ("Function:\global:{0}" -f $name) -Value ([ScriptBlock]::Create($cmd)) -Force | Out-Null
  }
}
Register-WorldShortcuts

Write-Host "[tools] loaded. Commands: km (menu), w0 (dog+film), w1 (type tempo), w2..w9 (world indices), w <key|index>, wm/ws, mix, bpm, vol, new-world, shot"

function _find-vs {
  # Zoek Visual Studio via vswhere (shipt met VS/Build Tools)
  $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
  if (Test-Path $vswhere) {
    try {
      $path = & $vswhere -latest -products * -property productPath 2>$null
      if ($path -and (Test-Path $path)) { return $path }  # volledige pad naar devenv.exe
    } catch { }
  }
  # Anders: als devenv in PATH staat
  $dev = Get-Command devenv.exe -ErrorAction SilentlyContinue
  if ($dev) { return $dev.Source }
  return $null
}

function vs {
  param([Parameter(ValueFromRemainingArguments=$true)][string[]]$Args)
  # Standaard: engine.py openen
  $target = if ($Args.Count) { $Args[0] } else { ".\engine.py" }
  $target = Resolve-Path -LiteralPath $target -ErrorAction SilentlyContinue | ForEach-Object { $_.Path } | Select-Object -First 1
  if (-not $target) { Write-Warning "Bestand niet gevonden."; return }

  $devenv = _find-vs
  if ($devenv) {
    # /Edit opent file zonder project-dialoog; 'Open Folder' kan met /Command maar /Edit is snappy
    & $devenv /Edit "$target" | Out-Null
    return
  }

  # Fallbacks: probeer Visual Studio via start, anders VS Code
  if (Get-Command devenv.exe -ErrorAction SilentlyContinue) {
    devenv "$target" | Out-Null; return
  }
  if (Get-Command code -ErrorAction SilentlyContinue) {
    code -g "$target":1 | Out-Null; return
  }
  Write-Warning "Geen Visual Studio of VS Code gevonden. Installeer VS (Community/Build Tools) of VS Code."
}

# Sneltoets: open altijd engine.py in VS
function vse { vs ".\engine.py" }
