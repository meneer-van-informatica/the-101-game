# stop.ps1 — muziek uit (Spotify/VLC/lighting apps) + Hue lampen OFF
$ErrorActionPreference = 'SilentlyContinue'
chcp 65001 | Out-Null

Write-Host "[kill] muziek/lighting processen stoppen..."
Get-Process | Where-Object {
  $_.ProcessName -match 'Spotify|vlc|Philips.*Hue.*Sync|HueSync|HueDynamic|HueStream|Razer|Chroma|iCUE|OpenRGB|SignalRGB'
} | ForEach-Object {
  try { Stop-Process -Id $_.Id -Force; Write-Host ("  - killed {0} ({1})" -f $_.ProcessName,$_.Id) } catch {}
}

# Hue OFF (groep 0, herhaal + per-lamp fallback)
try {
  $cfg = Get-Content .\data\hue_config.json -Raw | ConvertFrom-Json
  $base = "http://{0}/api/{1}" -f $cfg.ip, $cfg.username

  # entertainment stream poging uit (schadeloos als het niet mag)
  try {
    $probe = @{ stream = @{ active = $false } } | ConvertTo-Json -Compress
    Invoke-RestMethod -Uri ($base + "/groups/0") -Method Put -Body $probe -ContentType 'application/json' -TimeoutSec 2 | Out-Null
  } catch {}

  $off = @{ on = $false } | ConvertTo-Json -Compress
  for ($i=0; $i -lt 10; $i++) {
    try { Invoke-RestMethod -Uri ($base + "/groups/0/action") -Method Put -Body $off -ContentType 'application/json' -TimeoutSec 2 | Out-Null } catch {}
    Start-Sleep -Milliseconds 200
  }

  try {
    $lights = Invoke-RestMethod -Uri ($base + "/lights") -TimeoutSec 3
    foreach ($id in $lights.PSObject.Properties.Name) {
      try { Invoke-RestMethod -Uri ($base + "/lights/$id/state") -Method Put -Body $off -ContentType 'application/json' -TimeoutSec 2 | Out-Null } catch {}
    }
  } catch {}
  Write-Host "[ok] Hue -> OFF verstuurd."
} catch {
  Write-Host "[info] geen hue_config.json gevonden; alleen apps gestopt."
}
