# scripts/dr_bibber_act.ps1
param(
  [ValidateSet('probe','cycle')]
  [string]$Action = 'probe',
  [string]$LogPath = '',
  [int]$SleepMs = 1500
)
$ErrorActionPreference = 'Stop'

function Test-IsAdmin {
  $id = [Security.Principal.WindowsIdentity]::GetCurrent()
  $p  = New-Object Security.Principal.WindowsPrincipal($id)
  return $p.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}
function Write-Log([string]$msg) {
  $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
  $line = "[$ts] $msg`r`n"
  if ($LogPath) { [IO.File]::AppendAllText($LogPath,$line,[Text.Encoding]::UTF8) }
  Write-Host $msg
}
# Elevate self if needed
if (-not (Test-IsAdmin)) {
  $args = @('-NoProfile','-ExecutionPolicy','Bypass','-File',"$PSCommandPath",
            '-Action', $Action, '-SleepMs', $SleepMs)
  if ($LogPath) { $args += @('-LogPath', $LogPath) }
  Start-Process powershell -Verb RunAs -ArgumentList $args | Out-Null
  exit
}

function Find-ArduinoInstanceId {
  $cands = Get-PnpDevice -Class Ports -ErrorAction SilentlyContinue
  foreach ($d in $cands) {
    if ($d.InstanceId -match 'VID_2341|VID_1A86' -or $d.FriendlyName -match 'Arduino') { return $d.InstanceId }
  }
  return $null
}
function Get-ParentId($id){
  try { (Get-PnpDeviceProperty -InstanceId $id -KeyName 'DEVPKEY_Device_Parent').Data } catch { $null }
}

# Ensure log dir
if ($LogPath) {
  $dir = Split-Path -Parent $LogPath
  if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
}

Write-Log "=== Dr.Bibber/$Action start ==="
if ($Action -eq 'probe') {
  $ports = Get-PnpDevice -Class Ports -ErrorAction SilentlyContinue
  foreach ($p in $ports) { Write-Log ("port: {0}  status={1}" -f $p.FriendlyName, $p.Status) }
  $id = Find-ArduinoInstanceId
  Write-Log ("arduino.instanceId: {0}" -f ($id ?? '-'))
  Write-Log "probe.done"
} elseif ($Action -eq 'cycle') {
  $id = Find-ArduinoInstanceId
  if (-not $id) { Write-Log "cycle: geen Arduino gevonden"; exit 0 }
  Write-Log ("cycle: target(child) {0}" -f $id)
  try {
    Disable-PnpDevice -InstanceId $id -Confirm:$false -ErrorAction Stop
    Start-Sleep -Milliseconds $SleepMs
    Enable-PnpDevice  -InstanceId $id -Confirm:$false -ErrorAction Stop
    Write-Log "cycle: child OK"
  } catch {
    Write-Log ("cycle: child fail: {0}" -f $_.Exception.Message)
    $parent = Get-ParentId $id
    if ($parent) {
      Write-Log ("cycle: try parent {0}" -f $parent)
      try {
        Disable-PnpDevice -InstanceId $parent -Confirm:$false -ErrorAction Stop
        Start-Sleep -Milliseconds $SleepMs
        Enable-PnpDevice  -InstanceId $parent -Confirm:$false -ErrorAction Stop
        Write-Log "cycle: parent OK"
      } catch {
        Write-Log ("cycle: parent fail: {0}" -f $_.Exception.Message)
      }
    }
  }
}
Write-Log "=== Dr.Bibber/$Action end ==="
