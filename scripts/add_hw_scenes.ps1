# scripts/add_hw_scenes.ps1 — voeg scene06_usb_watch en scene07_usb_power toe na scene05_arduino
$ErrorActionPreference='Stop'
chcp 65001 | Out-Null
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $root
$data = Join-Path $root 'data\scene_chain.txt'
if (-not (Test-Path $data)) { throw "scene_chain ontbreekt: $data" }

# huidige chain
$lines = Get-Content $data | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }

# we willen …, scene05_arduino, scene06_usb_watch, scene07_usb_power, …
$idx = $lines.IndexOf('scene05_arduino')
if ($idx -lt 0) { $idx = $lines.Count-1 }
$target = @()
if ($lines.Count -gt 0 -and $idx -ge 0) { $target += $lines[0..$idx] } else { $target += $lines }
$target += @('scene06_usb_watch','scene07_usb_power')
if ($idx + 1 -le $lines.Count-1) { $target += $lines[($idx+1)..($lines.Count-1)] }
$target = $target | Select-Object -Unique

Set-Content -Path $data -Value ($target -join "`r`n") -Encoding UTF8

git add -- 'scenes/scene06_usb_watch.py' 'scenes/scene07_usb_power.py' 'scripts/usb_try_power_cycle.ps1' 'data/scene_chain.txt'
git commit -m "scenes: 06 USB watch (OUT->IN, strict OK) + 07 USB power (best-effort disable/enable); chain updated"
git push origin main
Write-Host "[ok] scenes 06/07 toegevoegd en gepusht."
