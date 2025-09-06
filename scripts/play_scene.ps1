# scripts\play_scene.ps1
param(
    [Parameter(Mandatory=$true)][string]$Key,
    [int]$Minutes = 5,
    [int]$Bpm = 84,
    [string]$Label = 'D'
)
$ErrorActionPreference = 'Stop'
chcp 65001 | Out-Null
try {
    New-Item -Path 'HKCU:\Console' -Force | Out-Null
    New-ItemProperty -Path 'HKCU:\Console' -Name 'VirtualTerminalLevel' -PropertyType DWord -Value 1 -Force | Out-Null
} catch {}
cmd /c 'mode con: cols=100 lines=32' | Out-Null
$env:PYTHONUTF8 = '1'

$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$py   = Join-Path $root '.venv\Scripts\python.exe'
$scene = Join-Path $root ('scenes\' + $Key + '.py')
if (-not (Test-Path $scene)) { throw 'scene niet gevonden: ' + $scene }

& $py $scene -bpm $Bpm -minutes $Minutes -label $Label
