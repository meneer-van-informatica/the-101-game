# scripts\play_scene02_afterglow.ps1
$ErrorActionPreference='Stop'
chcp 65001 | Out-Null
try{ New-Item -Path 'HKCU:\Console' -Force | Out-Null; New-ItemProperty -Path 'HKCU:\Console' -Name 'VirtualTerminalLevel' -PropertyType DWord -Value 1 -Force | Out-Null }catch{}
cmd /c 'mode con: cols=100 lines=34' | Out-Null
$env:PYTHONUTF8='1'
$py = Join-Path $PSScriptRoot '..\.venv\Scripts\python.exe'
$scene = Join-Path $PSScriptRoot '..\scenes\scene02_afterglow.py'
& $py $scene
