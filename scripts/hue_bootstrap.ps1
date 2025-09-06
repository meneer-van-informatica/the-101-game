# scripts/hue_bootstrap.ps1
param(
  [string]$Ip = ""   # optioneel: brug IP forceren (bijv. 192.168.1.10)
)
$ErrorActionPreference = 'Stop'
chcp 65001 | Out-Null
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $root
$configPath = Join-Path $root 'data\hue_config.json'
if (-not (Test-Path (Split-Path $configPath))) { New-Item -ItemType Directory -Path (Split-Path $configPath) -Force | Out-Null }

if (Test-Path $configPath) {
  Write-Host "[ok] config bestaat al: $configPath"
  Get-Content $configPath -Raw | Write-Host
  return
}

function Discover-HueBridge {
  param([string]$IpOverride = '')
  if ($IpOverride) { return @(@{internalipaddress=$IpOverride}) }
  try {
    $res = Invoke-RestMethod -Uri 'https://discovery.meethue.com' -TimeoutSec 5
    if (-not $res) { return @() }
    return $res
  } catch {
    return @()
  }
}

$bridges = Discover-HueBridge -IpOverride $Ip
if ($bridges.Count -eq 0) { throw "Geen Hue bridge gevonden. Opties: -Ip <bridge_ip> of zorg dat internet/LAN ok is." }
$ip = $bridges[0].internalipaddress
Write-Host "[ok] bridge: $ip"

Write-Host ""
Write-Host ">>> DRUK NU op de ronde link-knop van de Hue Bridge (grote knop)."
Write-Host ">>> Daarna druk je op Enter hier (je hebt ~30s)."
[void][System.Console]::ReadLine()

# Pair: POST naar http://<ip>/api
$body = @{ devicetype = 'the-101-game#powershell' } | ConvertTo-Json -Compress
try {
  $resp = Invoke-RestMethod -Uri ("http://{0}/api" -f $ip) -Method Post -Body $body -ContentType 'application/json' -TimeoutSec 10
} catch {
  throw "Pair request faalde: $($_.Exception.Message)"
}
if (-not $resp) { throw "Lege response van bridge." }

# Response is array met success of error
$username = $null
foreach ($item in $resp) {
  if ($item.success) { $username = $item.success.username }
  elseif ($item.error) { Write-Host ("[bridge] error: {0}" -f ($item.error.description)) -ForegroundColor Yellow }
}
if (-not $username) { throw "Geen username ontvangen. Link button niet (op tijd) ingedrukt?" }

# Test en config opslaan
try {
  $cfg = Invoke-RestMethod -Uri ("http://{0}/api/{1}/config" -f $ip, $username) -TimeoutSec 5
} catch {
  Write-Host "[waarschuwing] kon config niet lezen, ga door."
}

$conf = [ordered]@{
  ip = $ip
  username = $username
  created = (Get-Date).ToString('s')
} | ConvertTo-Json
$conf | Set-Content -Path $configPath -Encoding UTF8
Write-Host "[ok] gepaird. config opgeslagen -> $configPath"
