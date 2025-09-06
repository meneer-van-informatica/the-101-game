# scripts/chain_skip_05.ps1 — verwijder scene05_arduino uit de ketting
$ErrorActionPreference='Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$chain = Join-Path $root 'data\scene_chain.txt'
$lines = Get-Content $chain | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' -and $_ -ne 'scene05_arduino' }
Set-Content -Path $chain -Value ($lines -join "`r`n") -Encoding UTF8
git add -- 'data/scene_chain.txt'
git commit -m "chain: skip scene05_arduino (fast path to 06/07)"
git push
Write-Host "[ok] scene05_arduino geskipt."
