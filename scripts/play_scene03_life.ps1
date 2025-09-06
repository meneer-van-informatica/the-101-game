# scripts\play_scene03_life.ps1
$ErrorActionPreference = 'Stop'
try {
  chcp 65001 | Out-Null
  New-Item -Path 'HKCU:\Console' -Force | Out-Null
  New-ItemProperty -Path 'HKCU:\Console' -Name 'VirtualTerminalLevel' -PropertyType DWord -Value 1 -Force | Out-Null
} catch {}
cmd /c 'mode con: cols=100 lines=36' | Out-Null
$env:PYTHONUTF8 = '1'

$py    = Join-Path $PSScriptRoot '..\.venv\Scripts\python.exe'
$scene = Join-Path $PSScriptRoot '..\scenes\scene03_life.py'
& $py $scene
