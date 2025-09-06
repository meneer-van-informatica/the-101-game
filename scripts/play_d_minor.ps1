# scripts\play_d_minor.ps1
$ErrorActionPreference = 'Stop'

# console schoon en unicode aan
chcp 65001 | Out-Null
New-Item -Path 'HKCU:\Console' -Force | Out-Null
New-ItemProperty -Path 'HKCU:\Console' -Name 'VirtualTerminalLevel' -PropertyType DWord -Value 1 -Force | Out-Null
cmd /c 'mode con: cols=100 lines=32' | Out-Null
$env:PYTHONUTF8 = '1'

# paden
$py = Join-Path $PSScriptRoot '..\.venv\Scripts\python.exe'
$scene = Join-Path $PSScriptRoot '..\scenes\d_minor.py'

# run
& $py $scene -bpm 84 -minutes 10 -label 'D'
