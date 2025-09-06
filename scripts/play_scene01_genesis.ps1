# scripts\register_scene.ps1
param(
  [Parameter(Mandatory=$true)][string]$Key,
  [string]$Title = ''
)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $root
chcp 65001 | Out-Null

# chain file
$chainPath = Join-Path $root 'data\scene_chain.txt'
New-Item -ItemType Directory -Path (Join-Path $root 'data') -Force | Out-Null
if (-not (Test-Path $chainPath)) { Set-Content -Path $chainPath -Value '' -Encoding UTF8 }

# append als nog niet aanwezig
$lines = Get-Content $chainPath | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
if ($lines -notcontains $Key) {
  Add-Content -Path $chainPath -Value $Key
}

# stage + commit + push
$sceneRel  = Join-Path 'scenes' ($Key + '.py')
$runnerRel = Join-Path 'scripts' ('play_' + $Key + '.ps1')
$paths = @('data\scene_chain.txt')
if (Test-Path $sceneRel)  { $paths += $sceneRel }
if (Test-Path $runnerRel) { $paths += $runnerRel }

git add -- @paths
$ttl = $Title; if ([string]::IsNullOrWhiteSpace($ttl)) { $ttl = $Key }
git commit -m ('feat(scene): register ' + $Key + ' — ' + $ttl)
git push origin main
Write-Host '[ok] geregistreerd en gepusht'
