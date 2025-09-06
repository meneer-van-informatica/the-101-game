# scripts\play_scene00_mama.ps1
$ErrorActionPreference='Stop'
try{
  chcp 65001 | Out-Null
  New-Item -Path 'HKCU:\Console' -Force | Out-Null
  New-ItemProperty -Path 'HKCU:\Console' -Name 'VirtualTerminalLevel' -PropertyType DWord -Value 1 -Force | Out-Null
}catch{}
$env:PYTHONUTF8='1'
$py = Join-Path $PSScriptRoot '..\.venv\Scripts\python.exe'
$scene = Join-Path $PSScriptRoot '..\scenes\scene00_mama.py'
& $py $scene
