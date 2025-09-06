# scripts/add_usb_sim_chain.ps1 — voeg scene06_usb_sim en scene07_power_sim toe (na scene05_arduino of aan het einde)
$ErrorActionPreference='Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $root
$data = Join-Path $root 'data\scene_chain.txt'
if (-not (Test-Path $data)) { throw "scene_chain ontbreekt: $data" }

$lines = Get-Content $data | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
$idx = $lines.IndexOf('scene05_arduino'); if ($idx -lt 0) { $idx = $lines.Count-1 }

$final = @()
if ($lines.Count -gt 0 -and $idx -ge 0) { $final += $lines[0..$idx] } else { $final += $lines }
$final += @('scene06_usb_sim','scene07_power_sim')
if ($idx + 1 -le $lines.Count-1) { $final += $lines[($idx+1)..($lines.Count-1)] }
$final = $final | Select-Object -Unique

Set-Content -Path $data -Value ($final -join "`r`n") -Encoding UTF8

git add -- 'scenes/scene06_usb_sim.py' 'scenes/scene07_power_sim.py' 'data/scene_chain.txt'
git commit -m "sim: scene06 USB OUT->IN + scene07 3.3V ON/OFF (film-friendly); chain updated"
git push origin main
Write-Host "[ok] sim-scenes toegevoegd en gepusht."