# scripts\play_d_frame.ps1
Stop = 'Stop'
chcp 65001 | Out-Null
try { New-Item -Path 'HKCU:\Console' -Force | Out-Null; New-ItemProperty -Path 'HKCU:\Console' -Name 'VirtualTerminalLevel' -PropertyType DWord -Value 1 -Force | Out-Null } catch {}
cmd /c 'mode con: cols=100 lines=32' | Out-Null
 = '1'
 = Join-Path E:\the-101-game\scripts '..\.venv\Scripts\python.exe'
 = Join-Path E:\the-101-game\scripts ('..\scenes\d_frame.py')
&   -bpm 84 -minutes 5 -label 'D'
