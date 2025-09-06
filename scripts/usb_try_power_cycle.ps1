# scripts/usb_try_power_cycle.ps1  (best-effort; Admin vereist)
param(
  [string]$InstanceId = '',
  [switch]$FindArduino,
  [int]$SleepMs = 1500
)
$ErrorActionPreference='Stop'

function Assert-Admin {
  $id = [Security.Principal.WindowsIdentity]::GetCurrent()
  $p = New-Object Security.Principal.WindowsPrincipal($id)
  if (-not $p.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    throw "Run als Administrator. (Rechtsklik PowerShell → 'Run as administrator')"
  }
}

function Find-Arduino {
  $c = Get-PnpDevice -Class Ports -ErrorAction SilentlyContinue
  $hits = @()
  foreach($d in $c){
    if ($d.InstanceId -match 'VID_2341|VID_1A86' -or $d.FriendlyName -match 'Arduino') { $hits += $d }
  }
  if ($hits.Count -gt 0) { return $hits[0].InstanceId }
  return $null
}

function Get-ParentId($id){
  try {
    $p = Get-PnpDeviceProperty -InstanceId $id -KeyName 'DEVPKEY_Device_Parent'
    return $p.Data
  } catch { return $null }
}

Assert-Admin

if ($FindArduino -and -not $InstanceId) { $InstanceId = Find-Arduino }
if (-not $InstanceId) { throw "Geen InstanceId. Gebruik -FindArduino of geef -InstanceId." }

Write-Host "[usb] target: $InstanceId"

try {
  Write-Host "[usb] disable child"
  Disable-PnpDevice -InstanceId $InstanceId -Confirm:$false -ErrorAction Stop
  Start-Sleep -Milliseconds $SleepMs
  Write-Host "[usb] enable child"
  Enable-PnpDevice  -InstanceId $InstanceId -Confirm:$false -ErrorAction Stop
  Write-Host "[usb] cycled (child)."
  exit 0
} catch {
  Write-Host "[usb] child failed: $($_.Exception.Message)"
  $parent = Get-ParentId $InstanceId
  if (-not $parent) { throw "Geen parent gevonden. Stop." }
  Write-Host "[usb] probeer parent: $parent"
  Disable-PnpDevice -InstanceId $parent -Confirm:$false -ErrorAction Stop
  Start-Sleep -Milliseconds $SleepMs
  Enable-PnpDevice  -InstanceId $parent -Confirm:$false -ErrorAction Stop
  Write-Host "[usb] cycled (parent)."
  exit 0
}
