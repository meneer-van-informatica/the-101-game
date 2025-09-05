$repo   = Split-Path -Parent $MyInvocation.MyCommand.Path
$py     = Join-Path $repo ".venv\Scripts\python.exe"
$engine = Join-Path $repo "engine.py"
Set-Location $repo
if (Test-Path $py) { & $py $engine } else { python $engine }
