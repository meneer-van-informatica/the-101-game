# scripts\play_last.ps1
$ErrorActionPreference = 'Stop'

$root  = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$chain = Join-Path $root 'data\scene_chain.txt'
if (-not (Test-Path $chain)) { throw 'data\scene_chain.txt ontbreekt' }

# pak laatste niet-lege regel als string (geen char)
$line = Get-Content -Path $chain -ErrorAction Stop | Where-Object { $_ -and $_.Trim() -ne '' } | Select-Object -Last 1
if (-not $line) { throw 'geen scenes in chain' }
$key = $line.Trim()

& (Join-Path $PSScriptRoot 'play_scene.ps1') -Key $key
