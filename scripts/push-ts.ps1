param([string]$Msg = "chore(ts): update timestamp")
$ErrorActionPreference = "Stop"
$root = Split-Path -Path $PSScriptRoot -Parent
Set-Location $root

# tijd in Europe/Amsterdam
$tz = [System.TimeZoneInfo]::FindSystemTimeZoneById("W. Europe Standard Time")
$nowLocal = [System.TimeZoneInfo]::ConvertTime([datetime]::UtcNow, $tz)
$d = $nowLocal.ToString("yyyy-MM-dd HH:mm:ss 'Europe/Amsterdam'")

New-Item -ItemType Directory -Force -Path .\logs | Out-Null
"d=$d" | Set-Content .\logs\last-run.txt -Encoding UTF8

# git identity (eenmalig per machine)
if (-not (git config user.name))  { git config user.name  "your-name" }
if (-not (git config user.email)) { git config user.email "you@example.com" }

git add .\logs\last-run.txt
git commit -m $Msg 2>$null; if ($LASTEXITCODE -ne 0) { Write-Host "No changes to commit."; exit 0 }
git push
