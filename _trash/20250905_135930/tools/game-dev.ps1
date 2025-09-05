if (-not $script:ROOT) { $script:ROOT = (Get-Location).Path }
$PY = Join-Path $script:ROOT ".venv\Scripts\python.exe"
if (-not (Test-Path $PY)) { $PY = "python" }

 # tools\game-dev.ps1 â€” scene runner + helpers (robust, PS 5.1)
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
function shot {
  param([string]$Target = "")
  $dir = "screenshots"
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }

  # --- resolve scene argument (km/ui â†’ scene_picker, wN/index â†’ worlds.json key) ---
  $sceneArg = ($Target | ForEach-Object { $_.Trim().ToLower() })
  if ([string]::IsNullOrWhiteSpace($sceneArg)) { $sceneArg = "scene_picker" }
  if ($sceneArg -in @('km','ui')) { $sceneArg = 'scene_picker' }

  if ($sceneArg -match '^w(\d+)$' -or $sceneArg -match '^\d+$') {
    try {
      $idx = if ($sceneArg -match '^w(\d+)$') { [int]$Matches[1] } else { [int]$sceneArg }
      $worldsPath = Join-Path $script:ROOT "data\worlds.json"
      if (Test-Path $worldsPath) {
        $worlds = Get-Content $worldsPath -Raw | ConvertFrom-Json
        if ($worlds -and $idx -ge 0 -and $idx -lt $worlds.Count) {
          $sceneArg = [string]$worlds[$idx]
        }
      }
    } catch { }
  }

  # 1) render 1 frame â†’ PNG
  & $PY "$script:ROOT\engine.py" --windowed --scene $sceneArg --snapshot --shotdir $dir | Write-Host

  # 2) pak laatste PNG (even wachten tot file vrij is)
  $png = $null
  for ($i=0; $i -lt 25; $i++) {
    $png = Get-ChildItem $dir -Filter *.png | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($png -and (Test-Path $png.FullName)) {
      try { $fs = [IO.File]::Open($png.FullName, 'Open', 'Read', 'Read'); $fs.Close(); break } catch { }
    }
    Start-Sleep -Milliseconds 80
  }
  if (-not $png) { Write-Warning "No PNG found in $dir"; return }

  # 3) PNG â†’ clipboard (STA) â€” gebruik ScriptBlock + -ArgumentList (gÃ©Ã©n -Args)
  $clip = {
    param([string]$PngPath)
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    try {
      $img = [System.Drawing.Image]::FromFile($PngPath)
      [System.Windows.Forms.Clipboard]::Clear()
      [System.Windows.Forms.Clipboard]::SetImage($img)
      $img.Dispose()
      if (-not [System.Windows.Forms.Clipboard]::ContainsImage()) {
        throw [System.Exception]::new('Clipboard does not contain image after SetImage().')
      }
      'OK'
    } catch {
      'ERR: ' + $_.Exception.Message
    }
  }
  $res = powershell -NoProfile -STA -Command $clip -ArgumentList $png.FullName
  if ($res -eq 'OK') {
    Write-Host "[SHOT] copied to clipboard: $($png.FullName)"
  } else {
    Write-Warning "Clipboard copy failed: $res  (PNG: $($png.FullName))"
  }
}

param([string]$PngPath)
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
try {
    $img = [System.Drawing.Image]::FromFile($PngPath)
    [System.Windows.Forms.Clipboard]::Clear()
    [System.Windows.Forms.Clipboard]::SetImage($img)
    $img.Dispose()
    if (-not [System.Windows.Forms.Clipboard]::ContainsImage()) {
        throw [System.Exception]::new('Clipboard does not contain image after SetImage().')
    }
    'OK'
} catch {
    'ERR: ' + $_.Exception.Message
}
'@
  $res = powershell -NoProfile -STA -Command $clipScript -Args $png.FullName
  if ($res -eq 'OK') {
    Write-Host "[SHOT] copied to clipboard: $($png.FullName)"
  } else {
    Write-Warning "Clipboard copy failed: $res  (PNG: $($png.FullName))"
  }
}


param([string]$PngPath)
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
try {
    $img = [System.Drawing.Image]::FromFile($PngPath)
    [System.Windows.Forms.Clipboard]::Clear()
    [System.Windows.Forms.Clipboard]::SetImage($img)
    $img.Dispose()
    if (-not [System.Windows.Forms.Clipboard]::ContainsImage()) {
        throw [System.Exception]::new('Clipboard does not contain image after SetImage().')
    }
    'OK'
} catch {
    'ERR: ' + $_.Exception.Message
}
'@
  $res = powershell -NoProfile -STA -Command $clipScript -Args $png.FullName
  if ($res -eq 'OK') {
    Write-Host "[SHOT] copied to clipboard: $($png.FullName)"
  } else {
    Write-Warning "Clipboard copy failed: $res  (PNG: $($png.FullName))"
  }
}


param([string]$PngPath)
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
try {
    $img = [System.Drawing.Image]::FromFile($PngPath)
    [System.Windows.Forms.Clipboard]::Clear()
    [System.Windows.Forms.Clipboard]::SetImage($img)
    $img.Dispose()
    if (-not [System.Windows.Forms.Clipboard]::ContainsImage()) {
        throw [System.Exception]::new('Clipboard does not contain image after SetImage().')
    }
    'OK'
} catch {
    'ERR: ' + $_.Exception.Message
}
'@
  $res = powershell -NoProfile -STA -Command $clipScript -Args $png.FullName
  if ($res -eq 'OK') {
    Write-Host "[SHOT] copied to clipboard: $($png.FullName)"
  } else {
    Write-Warning "Clipboard copy failed: $res  (PNG: $($png.FullName))"
  }
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
try {
    \$img = [System.Drawing.Image]::FromFile('$($png.FullName)')
    [System.Windows.Forms.Clipboard]::Clear()
    [System.Windows.Forms.Clipboard]::SetImage(\$img)
    \$img.Dispose()
    if (-not [System.Windows.Forms.Clipboard]::ContainsImage()) {
        throw [System.Exception]::new('Clipboard does not contain image after SetImage().')
    }
    Write-Output 'OK'
} catch {
    Write-Output ('ERR: ' + \$_.Exception.Message)
}
"@
  $res = powershell -NoProfile -STA -Command $clipScript
  if ($res -is [System.Array]) { $res = $res -join "`n" }
  if ($res -match '^OK') {
    Write-Host "[SHOT] copied to clipboard: $($png.FullName)"
  } else {
    Write-Warning "Clipboard copy failed. ($res)  PNG at: $($png.FullName)"
  }
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


function _find-vs {
  $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
  if (Test-Path $vswhere) {
    try {
      $path = & $vswhere -latest -products * -property productPath 2>$null
      if ($path -and (Test-Path $path)) { return $path }
    } catch { }
  }
  $dev = Get-Command devenv.exe -ErrorAction SilentlyContinue
  if ($dev) { return $dev.Source }
  return $null
}

function Resolve-RepoFile {
  param([string]$Token)
  if (-not $Token -or $Token -eq '.') { return (Join-Path $script:ROOT 'engine.py') }

  # 1) Direct pad?
  $cand = Resolve-Path -LiteralPath $Token -ErrorAction SilentlyContinue | ForEach-Object { $_.Path } | Select-Object -First 1
  if ($cand) { return $cand }

  # 2) Zonder extensie? Probeer .py / .ps1 in repo-root
  foreach ($n in @($Token, "$Token.py", "$Token.ps1")) {
    $p = Join-Path $script:ROOT $n
    if (Test-Path $p) { return (Resolve-Path $p).Path }
  }

  # 3) Aliassen (korte namen)
  $alias = @{
    'eng'   = 'engine.py'
    'engine'= 'engine.py'
    'audio' = 'core\audio.py'
    'ui'    = 'core\ui.py'
    'picker'= 'scenes\scene_picker.py'
    'km'    = 'scenes\scene_picker.py'
    'w0'    = 'scenes\level_story_one.py'
    'w1'    = 'scenes\typing_ad.py'
  }
  $key = $Token.ToLower()
  if ($alias.ContainsKey($key)) {
    $ap = Join-Path $script:ROOT $alias[$key]
    if (Test-Path $ap) { return (Resolve-Path $ap).Path }
  }

  # 4) Fuzzy: zoek bestanden die de token bevatten
  $hit = Get-ChildItem -Recurse -File -Include *.py,*.ps1 -Path $script:ROOT | Where-Object {
    $_.Name -like "*$Token*" -or $_.FullName -like "*$Token*"
  } | Sort-Object `
      @{Expression={ $_.Name -ieq 'engine.py' }; Descending=$true}, `
      @{Expression={ $_.Name.StartsWith($Token, 'CurrentCultureIgnoreCase') }; Descending=$true}, `
      Name | Select-Object -First 1
  if ($hit) { return $hit.FullName }

  return $null
}

function vs {
  param([Parameter(ValueFromRemainingArguments=$true)][string[]]$Args)
  $tok = if ($Args.Count) { $Args[0] } else { 'eng' }  # default naar engine.py
  $target = Resolve-RepoFile $tok
  if (-not $target) { Write-Warning "Bestand niet gevonden voor '$tok'."; return }

  $devenv = _find-vs
  if ($devenv) { & $devenv /Edit "$target" | Out-Null; return }
  if (Get-Command devenv.exe -ErrorAction SilentlyContinue) { devenv "$target" | Out-Null; return }
  if (Get-Command code -ErrorAction SilentlyContinue) { code -g "$target":1 | Out-Null; return }
  Write-Warning "Geen Visual Studio of VS Code gevonden."
}

# Sneltoets: altijd engine.py
function vse { vs eng }

function rsnap {
  param([string]$Scene = "w0")
  $py = Join-Path $script:ROOT ".venv\Scripts\python.exe"
  if (-not (Test-Path $py)) { $py = "python" }
  if (-not (Test-Path "screenshots")) { New-Item -ItemType Directory -Force -Path "screenshots" | Out-Null }
  & $py "$script:ROOT\engine.py" --windowed --scene $Scene --snapshot --shotdir "screenshots"
}

function refresh {
  [CmdletBinding()] param()
  Write-Host "`n[refresh] repo + runtime status" -ForegroundColor Cyan

  # Git
  $branch = try { git rev-parse --abbrev-ref HEAD 2>$null } catch { "" }
  $last   = try { git log -1 --pretty=format:'%h %ad %s' --date=iso 2>$null } catch { "" }
  $dirty  = if ((git status --porcelain 2>$null)) { "*" } else { "" }
  if ($branch) { Write-Host ("  branch  : {0}{1}" -f $branch, $dirty) }
  if ($last)   { Write-Host ("  last    : {0}" -f $last) }

  # Python / Pygame
  try { & $PY -c "import sys;print('  Python  :',sys.version.split()[0])" } catch { Write-Warning "Python not found." }
  try { & $PY -c "import pygame;print('  Pygame  :',pygame.__version__)" } catch { Write-Warning "Pygame not installed." }

  # Worlds.json quick view
  $w = Join-Path $script:ROOT "data\worlds.json"
  if (Test-Path $w) {
    try {
      $arr = Get-Content $w -Raw | ConvertFrom-Json
      if ($arr) { Write-Host ("  worlds  : {0} -> {1}" -f $arr.Count, ($arr -join ', ')) }
    } catch { }
  }

  Write-Host "  cwd     : $((Get-Location).Path)"
  Write-Host "[ok] refresh done.`n" -ForegroundColor Green
}

function stop {
  [CmdletBinding()] param(
    [switch]$NoPush,      # alleen lokaal
    [switch]$AllowEmpty   # commit ook als er geen wijzigingen zijn
  )
  if (-not (Test-Path ".git")) { Write-Warning "No git repo here."; return }

  $now   = Get-Date
  $stamp = $now.ToString("yyyy-MM-dd HH:mm:ss zzz")
  $tag   = "snap-" + $now.ToString("yyyyMMdd_HHmmss")
  $tz    = try { (Get-TimeZone).Id } catch { "UnknownTZ" }
  $who   = "$env:COMPUTERNAME\$env:USERNAME"
  $msg   = "stop: $stamp [$tz] by $who"

  git add -A | Out-Null
  git diff --cached --quiet; $changed = ($LASTEXITCODE -ne 0)

  if ($changed -or $AllowEmpty) {
    $args = @("commit","-m",$msg)
    if (-not $changed) { $args = @("commit","--allow-empty","-m",$msg) }
    git @args | Out-Null
  } else {
    Write-Host "[stop] no changes; use -AllowEmpty to force." -ForegroundColor Yellow
  }

  # unieke tag (niet crashen als hij al bestaat)
  if (-not (git tag -l $tag)) { git tag -a $tag -m $msg | Out-Null }

  if (-not $NoPush) {
    try {
      git push | Out-Null
      git push origin $tag | Out-Null
      Write-Host "[stop] pushed â€¢ tag $tag" -ForegroundColor Green
    } catch {
      Write-Warning "[stop] push failed. Local commit/tag exist. Later: git push; git push origin $tag"
    }
  } else {
    Write-Host "[stop] committed locally â€¢ tag $tag (no push)" -ForegroundColor Green
  }
}

function esc {
  [CmdletBinding()]
  param(
    [switch]$Run   # use -Run to launch the scene instead of opening the file
  )
  if (-not $script:ROOT) { $script:ROOT = (Get-Location).Path }
  $path = Join-Path $script:ROOT 'scenes\dev_settings.py'
  if ($Run) {
    $py = Join-Path $script:ROOT '.venv\Scripts\python.exe'
    if (-not (Test-Path $py)) { $py = 'python' }
    & $py "$script:ROOT\engine.py" --windowed --scene dev_settings
    return
  }
  if (Get-Command vs -ErrorAction SilentlyContinue) {
    vs $path       # opens in Visual Studio (your 'vs' auto-creates if missing)
  } elseif (Get-Command code -ErrorAction SilentlyContinue) {
    code -g "$path":1
  } else {
    Write-Host $path
    Start-Process $path
  }
}
