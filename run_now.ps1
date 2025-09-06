# run_now.ps1  start game idempotent, zonder gedoe
$ErrorActionPreference = 'Stop'
Set-Location 'E:\the-101-game'
if (-not (Test-Path '.\.venv\Scripts\python.exe')) { py -3.11 -m venv '.\.venv' }
. '.\.venv\Scripts\Activate.ps1'
python -m pip install --upgrade pip setuptools wheel > $null
if (Test-Path '.\requirements.txt') { pip install -r '.\requirements.txt' } else { pip install pygame-ce }
# optioneel: scene via arg, anders menu
param([string]$Scene='')
$args = @()
if ($Scene) { $args += @('--scene', $Scene) }
python '.\engine.py' @args
