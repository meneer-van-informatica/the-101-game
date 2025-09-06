# scripts\reset_chain_bitworld.ps1
# zet scene_chain.txt exact op de bit-wereld (5 scenes) met afterglow centraal
$ErrorActionPreference='Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $root
$wanted = @('scene00_title','scene01_genesis','scene02_afterglow','scene03_life','scene04_choice')
# filter: neem alleen bestaande .py op, waarschuw voor missende
$final = @()
foreach($k in $wanted){
  if (Test-Path (Join-Path $root ("scenes\"+$k+".py"))) { $final += $k }
  else { Write-Host "[let op] ontbreekt: $k.py  (maak 'm of pas lijst aan)"; }
}
if ($final.Count -eq 0) { throw 'geen scenes gevonden' }
New-Item -ItemType Directory -Path (Join-Path $root 'data') -Force | Out-Null
$chain = Join-Path $root 'data\scene_chain.txt'
Set-Content -Path $chain -Value ($final -join "`r`n") -Encoding UTF8
git add -- 'data\scene_chain.txt'
git commit -m ('film: reset chain to bit-world order [' + ($final -join ', ') + ']')
git push origin main
Write-Host "[ok] chain reset -> " ($final -join ' | ')
