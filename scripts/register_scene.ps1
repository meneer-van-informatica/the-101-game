# scripts\register_scene.ps1
param(
  [Parameter(Mandatory=$true)][string]$Key,
  [string]$Title = ''
)
$ErrorActionPreference = 'Stop'

# repo root
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $root
try { chcp 65001 | Out-Null } catch {}

# zorg voor data-map en chain file
New-Item -ItemType Directory -Path (Join-Path $root 'data') -Force | Out-Null
$chainPath = Join-Path $root 'data\scene_chain.txt'
if (-not (Test-Path $chainPath)) {
  Set-Content -Path $chainPath -Value '' -Encoding UTF8
}

# laatste, unieke toevoeging
$lines = @()
if (Test-Path $chainPath) {
  $lines = Get-Content $chainPath | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
}
if ($lines -notcontains $Key) {
  Add-Content -Path $chainPath -Value $Key
}

# paden die we willen pushen
$paths = @('data\scene_chain.txt')
$sceneRel  = Join-Path 'scenes' ($Key + '.py')
$runnerRel = Join-Path 'scripts' ('play_' + $Key + '.ps1')
if (Test-Path $sceneRel)  { $paths += $sceneRel }
if (Test-Path $runnerRel) { $paths += $runnerRel }

# commit en push
git add -- @paths
$ttl = $Title; if ([string]::IsNullOrWhiteSpace($ttl)) { $ttl = $Key }
git commit -m ('feat(scene): register ' + $Key + ' — ' + $ttl)
git push origin main
Write-Host '[ok] geregistreerd en gepusht'
