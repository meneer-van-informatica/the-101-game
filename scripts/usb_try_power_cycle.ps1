# scripts/usb_try_power_cycle.ps1
param(
  [string]$InstanceId = '',
  [switch]$FindArduino,   # auto-vind Arduino (VID_2341/PID_0043) of CH340 (VID_1A86)
  [int]$SleepMs = 1500    # wachttijd tussen disable/enable
)
$ErrorActionPreference='Stop'

function Find-ArduinoInstanceId {
  $cands = Get-PnpDevice -Class Ports -Status OK -ErrorAction SilentlyContinue
  $hits = @()
  foreach ($d in $cands) {
    $id = $d.InstanceId
    if ($id -match 'VID_2341' -or $id -match 'VID_1A86' -or $d.FriendlyName -match 'Arduino') {
      $hits += $d
    }
  }
  if ($hits.Count -gt 0) { return $hits[0].InstanceId }
  return $null
}

if ($FindArduino -and [string]::IsNullOrWhiteSpace($InstanceId)) {
  $InstanceId = Find-ArduinoInstanceId
}
if (-not $InstanceId) { throw "Geen InstanceId. Gebruik -FindArduino of geef -InstanceId op." }

Write-Host "[usb] disable $InstanceId"
Disable-PnpDevice -InstanceId $InstanceId -Confirm:$false -ErrorAction Stop
Start-Sleep -Milliseconds $SleepMs
Write-Host "[usb] enable $InstanceId"
Enable-PnpDevice -InstanceId $InstanceId -Confirm:$false -ErrorAction Stop
Write-Host "[usb] cycled."
