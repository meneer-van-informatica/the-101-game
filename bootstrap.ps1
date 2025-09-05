param([switch]$Force)
$ErrorActionPreference = "Stop"

# 1) Python check
$py = Get-Command python -ErrorAction SilentlyContinue
if (-not $py) {
  Write-Host "[bootstrap] Python niet gevonden. Installeer Python 3.11+." -ForegroundColor Red
  exit 1
}

# 2) venv
$venvPy = Join-Path $PSScriptRoot ".venv\Scripts\python.exe"
if ($Force -or -not (Test-Path $venvPy)) {
  Write-Host "[bootstrap] (her)maak .venv…" -ForegroundColor Cyan
  python -m venv ".venv"
}

# 3) pip updaten + deps
& $venvPy -m pip install --upgrade pip
if (Test-Path (Join-Path $PSScriptRoot "requirements.txt")) {
  Write-Host "[bootstrap] pip install -r requirements.txt" -ForegroundColor Cyan
  & $venvPy -m pip install -r (Join-Path $PSScriptRoot "requirements.txt")
}

Write-Host "[bootstrap] ok" -ForegroundColor Green
