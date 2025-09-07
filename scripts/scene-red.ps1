# scene: off -> film -> red -> pause
$root = (Get-Location)
$hue  = Join-Path $root 'scripts\hue.ps1'
if (Test-Path $hue) { powershell -File $hue -Off }

# gebruik je profiel 'film' als die er is, anders val terug op repo-variant
if (Get-Command film -ErrorAction SilentlyContinue) {
  film
} elseif (Test-Path (Join-Path $root 'scripts\film.ps1')) {
  powershell -File (Join-Path $root 'scripts\film.ps1')
}

if (Test-Path $hue) { powershell -File $hue -Red }

Read-Host 'Enter om door te gaan' | Out-Null
