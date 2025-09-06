# scripts\use_mama_title.ps1
# zet 'scene00_mama' als eerste in data\scene_chain.txt, behoudt de rest (uniek), push commit
$ErrorActionPreference='Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $root
$chain = Join-Path $root 'data\scene_chain.txt'
New-Item -ItemType Directory -Path (Join-Path $root 'data') -Force | Out-Null
if (-not (Test-Path $chain)) { Set-Content -Path $chain -Value '' -Encoding UTF8 }

$lines = Get-Content $chain | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
# verwijder oude titel als aanwezig
$lines = $lines | Where-Object { $_ -ne 'scene00_title' -and $_ -ne 'scene00_mama' }
$final = @('scene00_mama')
$final += $lines
$final = $final | Select-Object -Unique
Set-Content -Path $chain -Value ($final -join "`r`n") -Encoding UTF8

git add -- 'scenes/scene00_mama.py' 'scripts/play_scene00_mama.ps1' 'data/scene_chain.txt'
git commit -m 'title: scene00_mama (Hallo Mama) set as first in chain'
git push origin main
Write-Host '[ok] Hallo Mama ingesteld en gepusht.'
