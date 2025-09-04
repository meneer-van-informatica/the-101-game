$ErrorActionPreference = 'Stop'

# projectroot
$root = 'E:\the-101-game'
Set-Location $root

# ffmpeg via winget-shims
$links = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Links'
$apps  = Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps'
$env:Path = "$links;$apps;$env:Path"
$ff = (Get-Command 'ffmpeg' -ErrorAction SilentlyContinue).Source
if (-not $ff) {
  $shim = Join-Path $links 'ffmpeg.exe'
  if (Test-Path $shim) { $ff = $shim } else { throw 'ffmpeg niet gevonden. Run: winget install ffmpeg' }
}

function Resolve-First {
  param([string[]]$candidates)
  foreach ($c in $candidates) {
    # relatieve pad?
    $p = Join-Path $root $c
    if (Test-Path $p) { return (Resolve-Path $p).Path }
    # glob search
    $g = Get-ChildItem -Path $root -Recurse -File -Filter (Split-Path $c -Leaf) -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($g) { return $g.FullName }
  }
  return $null
}

function Require-Audio {
  param([string]$label, [string[]]$candidates)
  $found = Resolve-First $candidates
  if ($found) { return $found }
  Write-Host "❌ Niet gevonden: $label" -ForegroundColor Red
  Write-Host 'Geprobeerde patronen:' -ForegroundColor Yellow
  $candidates | ForEach-Object { Write-Host "  - $_" }
  Write-Host 'Beschikbare audio in project:' -ForegroundColor Yellow
  Get-ChildItem -Path $root -Recurse -File -Include '*.mp3','*.wav' -ErrorAction SilentlyContinue | Select-Object -First 25 | ForEach-Object { Write-Host "  - $($_.FullName)" }
  throw "Bestand voor '$label' niet gevonden. Hernoem of verplaats je file naar één van de patronen hierboven."
}

# zoek inputs (valt terug op alternatieve namen)
$menuIn  = Require-Audio 'menu'  @('RAW\menu.mp3','RAW\menu.wav','audio\menu.mp3','assets\RAW\menu.mp3','*menu*.mp3','*menu*.wav')
$beatIn  = Resolve-First @('RAW\beat.wav','audio\beat.wav','assets\RAW\beat.wav','*beat*.wav')
$clickIn = Resolve-First @('RAW\click.wav','audio\click.wav','assets\RAW\click.wav','*click*.wav')

if (-not $beatIn)  { throw 'Bestand niet gevonden: beat.wav (pas de namen aan of zet in RAW\)' }
if (-not $clickIn) { throw 'Bestand niet gevonden: click.wav (pas de namen aan of zet in RAW\)' }

# outputs
$musicDir = Join-Path $root 'data\music'
$sfxDir   = Join-Path $root 'data\sfx'
New-Item -ItemType Directory -Path $musicDir -Force | Out-Null
New-Item -ItemType Directory -Path $sfxDir   -Force | Out-Null
$menuOut  = Join-Path $musicDir 'menu.ogg'
$beatOut  = Join-Path $sfxDir   'beat.wav'
$clickOut = Join-Path $sfxDir   'click.wav'

# run
& $ff -y -i $menuIn  -vn -ar 44100 -ac 2 -c:a libvorbis -q:a 5 -af 'silenceremove=start_periods=1:start_threshold=-50dB:start_silence=0.2:stop_periods=1:stop_threshold=-50dB:stop_silence=0.3' $menuOut
& $ff -y -i $beatIn  -ar 44100 -ac 1 -c:a pcm_s16le $beatOut
& $ff -y -i $clickIn -ar 44100 -ac 1 -c:a pcm_s16le $clickOut

Write-Host '✅ Klaar:' -ForegroundColor Green
Write-Host "  $menuOut"
Write-Host "  $beatOut"
Write-Host "  $clickOut"
