# scripts/hue_sync_fix.ps1 — detecteer/stop Hue Entertainment Sync en zet alles groen
param(
  [switch]$TryApi,  # probeer via API stream te stoppen (lukt meestal niet, maar onschadelijk)
  [switch]$Kill,    # kill bekende desktop-processen (Hue Sync/Entertainment apps)
  [switch]$Green    # zet na stop ALLE lampen groen (groups/0)
)
$ErrorActionPreference = 'Stop'
chcp 65001 | Out-Null
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$config = Join-Path $root 'data\hue_config.json'
if (-not (Test-Path $config)) { throw "Geen hue_config.json. Run eerst de pair-scene." }
$cfg = Get-Content $config -Raw | ConvertFrom-Json
$ip=$cfg.ip; $u=$cfg.username
$base = "http://$ip/api/$u"

# 1) Lees groepen en toon actieve entertainment streams
$groups = Invoke-RestMethod -Uri "$base/groups" -TimeoutSec 5
$busy = @()
foreach ($k in $groups.PSObject.Properties.Name) {
  $g = $groups.$k
  if ($g.type -eq 'Entertainment' -and $g.stream -and $g.stream.active) {
    $busy += [pscustomobject]@{
      id = $k; name = $g.name; owner = $g.stream.owner; lights = ($g.lights -join ',')
    }
  }
}
if ($busy.Count -eq 0) {
  Write-Host "[ok] Geen actieve Entertainment-streams gevonden."
} else {
  Write-Host "== Actieve Entertainment groups =="
  $busy | Format-Table -AutoSize
}

# 2) Optioneel: API-probe om stream te stoppen (meestal read-only, maar we proberen)
if ($TryApi -and $busy.Count -gt 0) {
  foreach ($b in $busy) {
    try {
      $body = @{ stream = @{ active = $false } } | ConvertTo-Json -Compress
      $resp = Invoke-RestMethod -Uri "$base/groups/$($b.id)" -Method Put -Body $body -ContentType 'application/json' -TimeoutSec 5
      Write-Host "[probe] groups/$($b.id) -> stream.active=false"; $resp | Out-String | Write-Host
    } catch {
      Write-Host "[probe] API stop niet gelukt: $($_.Exception.Message)"
    }
  }
}

# 3) Optioneel: kill bekende desktop processen die Entertainment aanzetten
if ($Kill) {
  $cands = Get-Process | Where-Object {
    $_.ProcessName -match 'Hue.*Sync|Sync.*Hue|HueDynamic|HueStream|Razer.*Chroma'
  }
  if ($cands) {
    Write-Host "[kill] processen:"; $cands | Select-Object Id,ProcessName | Format-Table -AutoSize
    foreach ($p in $cands) {
      try { Stop-Process -Id $p.Id -Force -ErrorAction Stop; Write-Host "  - killed $($p.ProcessName) ($($p.Id))" }
      catch { Write-Host "  - kon $($p.ProcessName) niet stoppen: $($_.Exception.Message)" }
    }
  } else {
    Write-Host "[kill] geen verdachte processen gevonden."
  }
}

# 4) Refresh groups status na acties
$groups2 = Invoke-RestMethod -Uri "$base/groups" -TimeoutSec 5
$still = @()
foreach ($k in $groups2.PSObject.Properties.Name) {
  $g = $groups2.$k
  if ($g.type -eq 'Entertainment' -and $g.stream -and $g.stream.active) {
    $still += $k
  }
}
if ($still.Count -eq 0) {
  Write-Host "[ok] Entertainment-sync lijkt UIT."
} else {
  Write-Host "[let op] Nog actief bij groups: $($still -join ','). Stop dit in de Hue-app of desktop-app."
}

# 5) Optioneel: zet ALLES groen
if ($Green) {
  $payload = @{ on = $true; bri = 254; hue = 25500; sat = 254 } | ConvertTo-Json -Compress
  Invoke-RestMethod -Uri "$base/groups/0/action" -Method Put -Body $payload -ContentType 'application/json'
  Write-Host "[ok] alles -> GROEN (als Entertainment echt uit is)"
}
