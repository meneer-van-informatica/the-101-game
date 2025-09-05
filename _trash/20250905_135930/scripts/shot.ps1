param([string]$Tag = "frame_square")
$ErrorActionPreference = "Stop"
$root = Split-Path -Path $PSScriptRoot -Parent
Set-Location -Path $root
$act = Join-Path $root ".venv\Scripts\Activate.ps1"
if (Test-Path $act) { . $act }
$env:PYGAME_HIDE_SUPPORT_PROMPT = "1"
$env:PYTHONWARNINGS = "ignore"
$py = Get-Command "python" -ErrorAction Stop
& $py.Source -W ignore (Join-Path $root "engine.py") --scene $Tag --snapshot
