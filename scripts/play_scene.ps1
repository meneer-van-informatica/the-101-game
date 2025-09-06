# scripts\play_scene.ps1
param(
    [Parameter(Mandatory=$true)][string]$Key,
    [int]$Minutes = 5,
    [int]$Bpm = 84,
    [string]$Label = 'D',
    [switch]$Dev,             # i.p.v. -Debug (gereserveerd)
    [switch]$NoTranscript
)
$ErrorActionPreference = 'Stop'
chcp 65001 | Out-Null
try {
    New-Item -Path 'HKCU:\Console' -Force | Out-Null
    New-ItemProperty -Path 'HKCU:\Console' -Name 'VirtualTerminalLevel' -PropertyType DWord -Value 1 -Force | Out-Null
} catch {}
$env:PYTHONUTF8 = '1'

# projectroot + PYTHONPATH
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $root
if ($env:PYTHONPATH) { $env:PYTHONPATH = "$root;$env:PYTHONPATH" } else { $env:PYTHONPATH = $root }

# consolebuffer groot voor scrollback
try {
    $raw = $Host.UI.RawUI
    $buf = $raw.BufferSize
    $win = $raw.WindowSize
    $buf.Width  = [Math]::Max($buf.Width, 140)
    $buf.Height = if ($Dev) { 10000 } else { [Math]::Max($buf.Height, 3000) }
    $raw.BufferSize = $buf
    $win.Width  = [Math]::Min($buf.Width, 120)
    $win.Height = if ($win.Height -lt 40) { 40 } else { $win.Height }
    $raw.WindowSize = $win
} catch {}

# Transcript + DEV flag
if ($Dev) { $env:GAME_DEV = '1' } else { Remove-Item Env:\GAME_DEV -ErrorAction SilentlyContinue }
if ($Dev -and -not $NoTranscript) {
    $logDir = Join-Path $root 'data\logs'
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $transcriptPath = Join-Path $logDir ("run_"+$Key+"_"+$stamp+".log")
    try { Start-Transcript -Path $transcriptPath -Append | Out-Null } catch {}
}

# Run
$py    = Join-Path $root '.venv\Scripts\python.exe'
$scene = Join-Path $root ('scenes\' + $Key + '.py')
if (-not (Test-Path $scene)) { throw 'scene niet gevonden: ' + $scene }
& $py $scene -bpm $Bpm -minutes $Minutes -label $Label

if ($Dev -and -not $NoTranscript) {
    try { Stop-Transcript | Out-Null } catch {}
    Write-Host "[log] transcript: $transcriptPath"
}
