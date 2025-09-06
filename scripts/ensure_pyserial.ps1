# scripts/ensure_pyserial.ps1
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

# venv python/pip
$py  = Join-Path $root '.venv\Scripts\python.exe'
$pip = Join-Path $root '.venv\Scripts\pip.exe'

if (-not (Test-Path $py))  { throw "Python in venv niet gevonden: $py" }
# pip via exe als die er is, anders via -m
if (Test-Path $pip) {
  & $pip install --upgrade pip
  & $pip install --upgrade pyserial
} else {
  & $py -m pip install --upgrade pip
  & $py -m pip install --upgrade pyserial
}
Write-Host "[ok] pyserial geïnstalleerd/actueel"
