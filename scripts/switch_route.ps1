# scripts/switch_route.ps1
param(
  [ValidateSet('A','B','C','D')] [string]$Route = 'A',
  [switch]$Push
)
$ErrorActionPreference='Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$data = Join-Path $root 'data'
$chain = Join-Path $data 'scene_chain.txt'

$map = @{
  'A' = Join-Path $data 'chain_software.txt'
  'B' = Join-Path $data 'chain_hardware.txt'
  'C' = Join-Path $data 'chain_economie.txt'
  'D' = Join-Path $data 'chain_route4.txt'
}

if (-not (Test-Path $map[$Route])) { throw "Template ontbreekt: $($map[$Route])" }

Copy-Item -Force -Path $map[$Route] -Destination $chain

git add -- $chain
git commit -m ("route: set chain -> {0}" -f $Route) | Out-Null
if ($Push) { git push | Out-Null }

Write-Host ("[ok] route {0} actief (data\scene_chain.txt)" -f $Route)
