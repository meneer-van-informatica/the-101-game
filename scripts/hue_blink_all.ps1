param(
  [double]$Hz = 1.0,          # knips per seconde (toggle-modus)
  [int]$Seconds = 15,         # duur
  [ValidateSet('alert','toggle')]$Mode = 'alert',
  [switch]$Kill,              # probeer entertainment/spotify te killen
  [switch]$Stop               # stop lopende alert (alert=none)
)
$ErrorActionPreference = 'SilentlyContinue'

# config
$cfg  = Get-Content .\data\hue_config.json -Raw | ConvertFrom-Json
$base = 'http://{0}/api/{1}' -f $cfg.ip, $cfg.username

function ApiPut($path, $body) {
  try {
    $json = $body | ConvertTo-Json -Compress
    Invoke-RestMethod -Uri ($base + '/' + $path) -Method Put -Body $json -ContentType 'application/json' -TimeoutSec 3 | Out-Null
  } catch {}
}

if ($Kill) {
  Get-Process | Where-Object { $_.ProcessName -match 'Spotify|Hue.*Sync|HueDynamic|HueStream|Razer|Chroma|iCUE|OpenRGB|SignalRGB' } |
    ForEach-Object { try { Stop-Process -Id $_.Id -Force } catch {} }
}

if ($Stop) {
  ApiPut 'groups/0/action' @{ alert = 'none' }
  Write-Host '[ok] alert gestopt.'
  return
}

# waarschuwing als entertainment nog actief is
try {
  $g = Invoke-RestMethod -Uri ($base + '/groups') -TimeoutSec 3
  $active = @()
  foreach ($p in $g.PSObject.Properties) {
    $v = $p.Value
    if ($v.type -eq 'Entertainment' -and $v.stream -and $v.stream.active) { $active += $p.Name }
  }
  if ($active.Count -gt 0) {
    Write-Host ('[let op] Entertainment actief: ' + ($active -join ', ') + ' - blink kan genegeerd worden.')
  }
} catch {}

if ($Mode -eq 'alert') {
  # langdurig knipperen via alert; daarna uitzetten
  ApiPut 'groups/0/action' @{ on = $true; alert = 'lselect' }
  Start-Sleep -Seconds $Seconds
  ApiPut 'groups/0/action' @{ alert = 'none' }
  Write-Host '[ok] blink (alert) klaar.'
} else {
  # toggle-modus: echt aan/uit flitsen op groep 0
  $dt = [math]::Max(0.05, 1.0 / $Hz / 2.0)
  $deadline = (Get-Date).AddSeconds($Seconds)
  $state = $true
  while (Get-Date -lt $deadline) {
    ApiPut 'groups/0/action' @{ on = $state; bri = 254 }
    Start-Sleep -Seconds $dt
    $state = -not $state
  }
  # eindig met aan
  ApiPut 'groups/0/action' @{ on = $true }
  Write-Host '[ok] blink (toggle) klaar.'
}
