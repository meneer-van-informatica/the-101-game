# scripts/usb_try_power_cycle_admin.ps1
param(
  [string]$InstanceId = '',
  [switch]$FindArduino,
  [int]$SleepMs = 1500
)
$ErrorActionPreference='Stop'

function Test-IsAdmin {
  $id = [Security.Principal.WindowsIdentity]::GetCurrent()
  $p  = New-Object Security.Principal.WindowsPrincipal($id)
  return $p.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if (-not (Test-IsAdmin)) {
  $argList = @('-NoProfile','-ExecutionPolicy','Bypass','-File',"$PSCommandPath")
  if ($InstanceId) { $argList += @('-InstanceId', $InstanceId) }
  if ($FindArduino) { $argList += '-FindArduino' }
  $argList += @('-SleepMs', $SleepMs)
  Start-Process powershell -Verb RunAs -ArgumentList $argList | Out-Null
  exit
}

& (Join-Path $PSScriptRoot 'usb_try_power_cycle.ps1') @PSBoundParameters
