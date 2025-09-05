param([switch]$Silent)
Set-Location -Path $PSScriptRoot
if ($Silent) { python engine.py --silent } else { python engine.py }
