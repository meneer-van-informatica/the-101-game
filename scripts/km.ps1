param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Args)
$ErrorActionPreference = 'Stop'

# projectroot = map boven /scripts
$root = Split-Path -Path $PSScriptRoot -Parent

# venv activeren als aanwezig
$act = Join-Path $root '.venv\Scripts\Activate.ps1'
if (Test-Path $act) { . $act }

# prefer run.ps1, anders direct engine.py
$run = Join-Path $root 'run.ps1'
if (Test-Path $run) { & $run @Args; exit $LASTEXITCODE }

$engine = Join-Path $root 'engine.py'
if (Test-Path $engine) { & python $engine @Args; exit $LASTEXITCODE }

Write-Error 'km: geen run.ps1 of engine.py gevonden in projectroot.'
