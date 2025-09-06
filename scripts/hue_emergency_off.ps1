# scripts/hue_emergency_off.ps1 — breek Spotify/Sync, alles UIT
$ErrorActionPreference = 'SilentlyContinue'
$cfg  = Get-Content .\data\hue_config.json -Raw | ConvertFrom-Json
$base = "http://$($cfg.ip)/api/$($cfg.username)"

Write-Host "[kill] Spotify/Hue Sync/lighting apps…"
Get-Process | Where-Object {
  $_.ProcessName -match 'Spotify|Philips.*Hue.*Sync|HueSync|HueDynamic|HueStream|Razer|Chroma|iCUE|OpenRGB|SignalRGB|Corsair'
} | ForEach-Object {
  try { Stop-Process -Id $_.Id -Force; Write-Host "  - killed $($_.ProcessName) ($($_.Id))" } catch {}
}

# Probeer Entertainment stream te stoppen (meestal read-only, maar schaadt niet)
try {
  $body = @{ stream = @{ active = $false } } | ConvertTo-Json -Compress
  Invoke-RestMethod -Uri "$base/groups/0" -Method Put -Body $body -ContentType 'application/json' | Out-Null
} catch {}

# Alles UIT via groups/0 (meerdere keren, om eventuele reststream te overrulen)
$off = @{ on = $false } | ConvertTo-Json -Compress
for ($i=0; $i -lt 15; $i++) {
  try { Invoke-RestMethod -Uri "$base/groups/0/action" -Method Put -Body $off -ContentType 'application/json' -TimeoutSec 2 | Out-Null } catch {}
  Start-Sleep -Milliseconds 200
}

# Fall-back: per lamp uit
try {
  $lights = Invoke-RestMethod -Uri "$base/lights" -TimeoutSec 3
  foreach ($id in $lights.PSObject.Properties.Name) {
    try { Invoke-RestMethod -Uri "$base/lights/$id/state" -Method Put -Body $off -ContentType 'application/json' -TimeoutSec 2 | Out-Null } catch {}
  }
} catch {}

Write-Host "[ok] nood-actie verstuurd: alles UIT."
