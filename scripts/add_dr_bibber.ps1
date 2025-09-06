# scripts/add_dr_bibber.ps1 — voeg scene08_dr_bibber toe na scene07_* in de film
$ErrorActionPreference='Stop'
$root  = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$chain = Join-Path $root 'data\scene_chain.txt'
Set-Location $root
$lines = Get-Content $chain | % { $_.Trim() } | ? { $_ -ne '' }
$idx = ($lines | Select-String -SimpleMatch 'scene07' | Select-Object -Last 1).LineNumber
if (-not $idx) { $idx = $lines.Count }
$idx = [int]$idx - 1
$final = @()
if ($lines.Count -gt 0 -and $idx -ge 0) { $final += $lines[0..$idx] } else { $final += $lines }
$final += 'scene08_dr_bibber'
if ($idx + 1 -le $lines.Count-1) { $final += $lines[($idx+1)..($lines.Count-1)] }
$final = $final | Select-Object -Unique
Set-Content -Path $chain -Value ($final -join "`r`n") -Encoding UTF8

git add -- 'scripts/dr_bibber_act.ps1' 'scenes/scene08_dr_bibber.py' 'data/scene_chain.txt'
git commit -m "scene08: Dr. Bibber (elevated log viewer + actions); chain updated"
git push
Write-Host "[ok] Dr. Bibber toegevoegd en gepusht."
