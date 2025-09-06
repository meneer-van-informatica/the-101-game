param([string]$Message = "savepoint")
$ErrorActionPreference = 'Stop'
chcp 65001 | Out-Null

# naar repo-root
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $root

git add -A | Out-Null
$ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

try {
    git commit -m ("save: {0} - {1}" -f $ts, $Message) | Out-Null
} catch {
    Write-Host '[info] niets te committen (skip)'
}

git push | Out-Null
Write-Host '[ok] save and push klaar.'
