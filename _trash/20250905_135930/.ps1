```powershell
# run.ps1 — one-shot fixer/runner (stopt op error, kopieert error naar klembord, auto-git)
# Doel: snapshot mode + ESC→Mixer in engine.py, 'shot <scene>' (PNG+clipboard) in tools\game-dev.ps1
# Gebruik:  powershell -NoProfile -ExecutionPolicy Bypass -File .\run.ps1 [-NoShot] [-NoGit]
param([switch]$NoShot, [switch]$NoGit)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# ---------- helpers ----------
function Set-ClipboardText {
  param([Parameter(Mandatory=$true)][string]$Text)
  try {
    $escaped = $Text.Replace("`"", "`"`"")
    $cmd = @"
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Clipboard]::SetText("$escaped")
"@
    powershell -NoProfile -STA -Command $cmd | Out-Null
  } catch { }
}
function Fail {
  param([string]$Message, [object]$Exception = $null)
  $details = if ($Exception) { $Message + "`n`n" + ($Exception | Out-String) } else { $Message }
  Write-Host "`n========================= FAILED =========================" -ForegroundColor Red
  Write-Host $details -ForegroundColor Red
  Write-Host "==========================================================" -ForegroundColor Red
  Set-ClipboardText -Text $details
  exit 1
}
function Backup([string]$p){
  if (Test-Path $p) {
    $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    Copy-Item $p "$p.$stamp.bak" -Force | Out-Null
  }
}
function Patch-File {
  param([Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][ScriptBlock]$Transform)
  if (-not (Test-Path $Path)) { Write-Host "[skip] not found: $Path"; return }
  $orig = Get-Content $Path -Raw; if ($null -eq $orig) { $orig = "" }
  $new  = & $Transform $orig;     if ($null -eq $new)  { $new  = $orig }
  if ($new -ne $orig) { Backup $Path; Set-Content -Path $Path -Value $new -Encoding utf8; Write-Host "[ok] patched: $Path" }
  else { Write-Host "[ok] up-to-date: $Path" }
}
function DotSource-Tools { if (Test-Path ".\tools\game-dev.ps1") { . .\tools\game-dev.ps1; return $true } return $false }

# ---------- PATCH: engine.py ----------
try {
  Patch-File ".\engine.py" {
    param($t)

    # A) parse_args: add flags
    if ($t -notmatch "--snapshot") {
      if ($t -notmatch "def\s+parse_args\(\):") { Fail "engine.py: parse_args() not found." }
      $rx = [regex]"(def\s+parse_args\(\):\s*[\s\S]*?)(\r?\n\s*return\s+p\.parse_args\(\))"
      if (-not $rx.IsMatch($t)) { Fail "engine.py: couldn't locate 'return p.parse_args()' inside parse_args()." }
      $t = $rx.Replace($t, {
        param($m)
@"
$($m.Groups[1].Value)
    p.add_argument('--shotdir', type=str, default='screenshots', help='folder for F12/snapshot screenshots')
    p.add_argument('--snapshot', action='store_true', help='render a single frame, save PNG, then exit')
$($m.Groups[2].Value)
"@
      }, 1)
    }

    # B) snapshot block after while self.running:
    if ($t -notmatch "render 1 frame, save, quit") {
      if ($t -notmatch "while\s+self\.running:") { Fail "engine.py: 'while self.running:' not found for snapshot inject." }
      $rxWhile = [regex]"(\s*while\s+self\.running:\s*\r?\n)"
      $t = $rxWhile.Replace($t, {
        param($m)
@"
$($m.Groups[1].Value)            # snapshot mode: render 1 frame, save, quit
            if getattr(self, 'args', None) is None:
                self.args = parse_args()
            if getattr(self.args, 'snapshot', False):
                try:
                    self.scene.update(0.0)
                except Exception:
                    pass
                try:
                    self.scene.draw(self.screen)
                except Exception as ex:
                    self.draw_fallback(ex)
                pygame.display.flip()
                os.makedirs(getattr(self.args,'shotdir','screenshots'), exist_ok=True)
                import time
                path = os.path.join(self.args.shotdir, f"{self.scene_key}_{int(time.time())}.png")
                pygame.image.save(self.screen, path)
                print('[SHOT]', path)
                self.quit()
                continue

"@
      }, 1)
    }

    # C) Global ESC -> Mixer (insert before scene.handle_event)
    if ($t -notmatch "Global:\s*ESC\s*->\s*mixer") {
      if ($t -notmatch "if\s+e\.type\s*==\s*pygame\.KEYDOWN:") { Fail "engine.py: KEYDOWN handler not found for global ESC." }
      $rxKey = [regex]"(if\s+e\.type\s*==\s*pygame\.KEYDOWN:\s*\r?\n)"
      $t = $rxKey.Replace($t, {
        param($m)
@"
$($m.Groups[1].Value)                    # Global: ESC -> mixer (Dev Settings)
                    if e.key == pygame.K_ESCAPE:
                        self.switch_scene('dev_settings')
                        continue

"@
      }, 1)
    }

    return $t
  }
}
catch { Fail "engine.py patch failed." $_ }

# ---------- PATCH: tools\game-dev.ps1 (NO interpolation: single-quoted blocks) ----------
try {
  Patch-File ".\tools\game-dev.ps1" {
    param($t)

    $rootBlock = @'
$script:ROOT = (Get-Location).Path
'@

    $pyBlock = @'
$PY = Join-Path $script:ROOT ".venv\Scripts\python.exe"
if (-not (Test-Path $PY)) { $PY = "python" }
'@

    # A) ensure $script:ROOT
    if ($t -notmatch "(?m)^\s*\$script:ROOT\s*=") {
      $t = $rootBlock + "`r`n" + $t
    }

    # B) ensure $PY detector (append after $script:ROOT if possible)
    if ($t -notmatch "(?m)^\s*\$PY\s*=") {
      if ($t -match "(?m)^\s*\$script:ROOT\s*=.*$") {
        $t = [regex]::Replace($t, "(?m)^\s*\$script:ROOT\s*=.*$", { param($m) $m.Value + "`r`n" + $pyBlock }, 1)
      } else {
        $t = $pyBlock + "`r`n" + $t
      }
    }

$shot = @'
function shot {
  param([string]$Target = "")
  $dir = "screenshots"
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }

  & $PY "$script:ROOT\engine.py" --windowed --scene $Target --snapshot --shotdir $dir | Write-Host

  $last = Get-ChildItem $dir -Filter *.png | Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if (-not $last) { Write-Warning "No PNG found in $dir"; return }

  $clip = @"
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
`$img = [System.Drawing.Image]::FromFile('$($last.FullName)')
[System.Windows.Forms.Clipboard]::SetImage(`$img)
`$img.Dispose()
"@
  powershell -NoProfile -STA -Command $clip | Out-Null
  Write-Host "[SHOT] copied to clipboard:" $last.FullName
}
'@

    # C) ensure/replace shot function
    if ($t -match "(?s)function\s+shot\s*\{.*?\}") {
      $t = [System.Text.RegularExpressions.Regex]::Replace($t, "(?s)function\s+shot\s*\{.*?\}", [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $shot })
    } else {
      $t = $t.TrimEnd() + "`r`n`r`n" + $shot + "`r`n"
    }

    return $t
  }
}
catch { Fail "tools\game-dev.ps1 patch failed." $_ }

# ---------- reload tools + optional shot ----------
try {
  if (DotSource-Tools) { if (-not $NoShot) { shot w0 } }
  else { Write-Warning "tools\game-dev.ps1 not found; skipping reload/shot." }
}
catch { Fail "Post-patch step failed (reload/shot)." $_ }

# ---------- optional Git ----------
if (-not $NoGit) {
  try {
    git add -A
    git commit -m "ops: auto-patch snapshot mode + global ESC→Mixer + shot<scene> (PNG+clipboard)"
    git push
    Write-Host "[git] pushed." -ForegroundColor Green
  } catch { Fail "Git push failed." $_ }
}
```
