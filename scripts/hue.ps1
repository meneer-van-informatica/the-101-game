param(
  [switch]$Red,
  [switch]$Green,
  [switch]$Orange,
  [switch]$Off,
  [int]$Hue,
  [int]$Bri = 254,
  [int]$Sat = 254
)

$cfgPath = Join-Path $PSScriptRoot 'hue.config.json'
if (-not (Test-Path $cfgPath)) {
  Write-Host "HUE: ontbrekende config $cfgPath" -ForegroundColor Yellow
  Write-Host '{ "bridge":"192.168.1.10", "token":"YOUR-HUE-TOKEN", "group":0 }' -ForegroundColor DarkGray
  exit 1
}
$cfg = Get-Content $cfgPath -Raw | ConvertFrom-Json
$bridge = $cfg.bridge; $token = $cfg.token; $group = $cfg.group
$base = "http://$bridge/api/$token/groups/$group/action"

function Set-HueAll([hashtable]$State) {
  try {
    $json = $State | ConvertTo-Json -Compress
    Invoke-WebRequest -Uri $base -Method Put -Body $json -ContentType 'application/json' -UseBasicParsing | Out-Null
    $true
  } catch {
    Write-Host "HUE: request faalde: $($_.Exception.Message)" -ForegroundColor Yellow
    $false
  }
}

if ($Off) { if (Set-HueAll @{on=$false}) { Write-Host 'HUE: alles is nu uit.' -ForegroundColor Yellow }; exit }

# presets
if ($Red)    { $Hue = 0 }
if ($Green)  { $Hue = 25500 }
if ($Orange) { $Hue = 6000 }   # warm oranje

if ($PSBoundParameters.ContainsKey('Hue')) {
  if (Set-HueAll @{ on=$true; bri=$Bri; sat=$Sat; hue=$Hue }) {
    $name = if     ($Red)    {'ROOD'}
            elseif ($Green)  {'GROEN'}
            elseif ($Orange) {'ORANJE'}
            else { "HUE=$Hue" }
    Write-Host "HUE: alles staat nu op $name." -ForegroundColor Yellow
  }
  exit
}

Write-Host @"
Gebruik:
  powershell -File .\scripts\hue.ps1 -Red
  powershell -File .\scripts\hue.ps1 -Green
  powershell -File .\scripts\hue.ps1 -Orange
  powershell -File .\scripts\hue.ps1 -Off
  # of vrij:
  powershell -File .\scripts\hue.ps1 -Hue 25500 -Bri 200 -Sat 254
"@
