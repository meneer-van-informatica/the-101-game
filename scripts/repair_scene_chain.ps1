# scripts\repair_scene_chain.ps1
# doel: data\scene_chain.txt opschonen → alleen keys waarbij scenes\<key>.py bestaat.
# zet desnoods 'scene01_genesis' als laatste als die bestaat.

$ErrorActionPreference = 'Stop'
try { chcp 65001 | Out-Null } catch {}

# repo root
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $root

# ketting inlezen
$chainPath = Join-Path $root 'data\scene_chain.txt'
if (-not (Test-Path $chainPath)) { throw 'ketting ontbreekt: ' + $chainPath }

$lines = Get-Content -Path $chainPath | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }

# valideren
$valid = @()
$removed = @()
foreach ($k in $lines) {
    $sceneFile = Join-Path $root ('scenes\' + $k + '.py')
    if (Test-Path $sceneFile) { $valid += $k } else { $removed += $k }
}

# als leeg maar Genesis bestaat, zet die erin
if ($valid.Count -eq 0) {
    $gen = Join-Path $root 'scenes\scene01_genesis.py'
    if (Test-Path $gen) { $valid = @('scene01_genesis') }
}

# schrijf terug
Set-Content -Path $chainPath -Value ($valid -join "`r`n") -Encoding UTF8

# tonen wat er gebeurde
if ($removed.Count -gt 0) {
    Write-Host '[ok] verwijderd uit ketting: ' + ($removed -join ', ')
} else {
    Write-Host '[ok] niets verwijderd'
}
if ($valid.Count -gt 0) {
    Write-Host '[ok] laatste scene: ' + $valid[-1]
} else {
    Write-Host '[let op] ketting leeg; maak eerst een scene en registreer die'
}

# commit + push
git add -- 'data\scene_chain.txt'
git commit -m 'fix(chain): purge invalid scene keys; set last valid'
git push origin main
Write-Host '[ok] ketting opgeschoond en gepusht'
