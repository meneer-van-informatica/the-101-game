param(
  [switch]$Red,
  [switch]$Off
)

# zachte clear
function softclean { Clear-Host }

# configpad
$cfgDir  = Join-Path $env:USERPROFILE 'Documents\Hue'
$cfgFile = Join-Path $cfgDir 'config.json'
if (-not (Test-Path $cfgDir)) { New-Item -ItemType Directory -Path $cfgDir | Out-Null }

# hulpfuncties
function Get-HueConfig {
  if (Test-Path $cfgFile) { try { Get-Content $cfgFile | ConvertFrom-Json } catch { $null } } else { $null }
}
function Save-HueConfig($obj) { $obj | ConvertTo-Json | Set-Content -Path $cfgFile -Encoding utf8 }

function Discover-BridgeIp {
  try {
    $resp = Invoke-RestMethod -Uri 'https://discovery.meethue.com/' -TimeoutSec 5
    if ($resp -and $resp.Count -gt 0) { return $resp[0].internalipaddress }
  } catch {}
  return $null
}

function Ensure-BridgeAndUser {
  $cfg = Get-HueConfig
  if (-not $cfg) { $cfg = [pscustomobject]@{ ip = $null; user = $null } }

  if (-not $cfg.ip) {
    $ip = Discover-BridgeIp
    if (-not $ip) {
      softclean
      $ip = Read-Host 'Voer het IP van je Hue Bridge in (bijv. 192.168.1.10)'
    }
    $cfg.ip = $ip
    Save-HueConfig $cfg
  }

  if (-not $cfg.user) {
    softclean
    Write-Host 'Druk binnen 30s op de link-knop op je Hue Bridge...' -ForegroundColor Yellow
    $body = @{ devicetype = 'the-101-game#hue' } | ConvertTo-Json
    $deadline = (Get-Date).AddSeconds(30)
    while ((Get-Date) -lt $deadline -and -not $cfg.user) {
      try {
        $resp = Invoke-RestMethod -Method Post -Uri ('http://{0}/api' -f $cfg.ip) -Body $body
        if ($resp -and $resp[0].success.username) {
          $cfg.user = $resp[0].success.username
          Save-HueConfig $cfg
          break
        }
      } catch {}
      Start-Sleep -Milliseconds 1500
    }
    if (-not $cfg.user) {
      throw 'Kon geen user aanmaken. Druk op de link-knop en run dit script opnieuw.'
    }
  }

  return $cfg
}

function Hue-All($cfg, $state) {
  $uri = 'http://{0}/api/{1}/groups/0/action' -f $cfg.ip, $cfg.user
  Invoke-RestMethod -Method Put -Uri $uri -Body ($state | ConvertTo-Json) | Out-Null
}

# main
softclean
$cfg = Ensure-BridgeAndUser

if ($Red) {
  $state = @{
    on  = $true
    bri = 254
    sat = 254
    hue = 0       # 0 of 65535 is rood
  }
  Hue-All $cfg $state
  Write-Host 'HUE: alles staat nu op ROOD.' -ForegroundColor Red
  exit 0
}

if ($Off) {
  Hue-All $cfg @{ on = $false }
  Write-Host 'HUE: alles is nu uit.' -ForegroundColor DarkGray
  exit 0
}

Write-Host 'Gebruik:' -ForegroundColor Cyan
Write-Host '  powershell -File .\scripts\hue.ps1 -Red    # alles rood'
Write-Host '  powershell -File .\scripts\hue.ps1 -Off    # alles uit'
