# scripts/find_arduino.ps1
param(
  [int]$Baud = 115200,
  [switch]$OpenTest,
  [switch]$SetEnv
)
$ErrorActionPreference = 'Stop'

$raw = Get-CimInstance Win32_PnPEntity | Where-Object { $_.Name -match '\(COM\d+\)' }

$items = foreach ($r in $raw) {
  if ($r.Name -match '\((COM\d+)\)') {
    $com = $Matches[1]
    $name = $r.Name
    $id   = $r.PNPDeviceID
    $score = 0

    # Positieve signalen (UNO/klonen)
    if ($id -match 'VID_2341') { $score += 200 }  # Arduino (genuine)
    if ($id -match 'PID_0043') { $score += 120 }  # Uno
    if ($id -match 'VID_1A86') { $score += 120 }  # CH340 (klonen)
    if ($id -match 'VID_10C4') { $score += 100 }  # CP210x
    if ($id -match 'VID_0403') { $score += 100 }  # FTDI
    if ($name -match 'Arduino') { $score += 100 }
    if ($name -match 'USB.*(Serial|Seri[eë]el)') { $score += 60 }

    # Negatief: Bluetooth / generiek
    if ($id -match '^BTHENUM') { $score -= 200 }
    if ($name -match 'Bluetooth') { $score -= 150 }

    [pscustomobject]@{
      COM=$com; Name=$name; Score=$score; PNPID=$id
    }
  }
}

if (-not $items -or $items.Count -eq 0) {
  $coms = [System.IO.Ports.SerialPort]::GetPortNames() | Sort-Object
  $items = $coms | ForEach-Object { [pscustomobject]@{ COM=$_; Name="(no name) ($_)" ; Score=0; PNPID='' } }
}

$items = $items | Sort-Object -Property @{e='Score';Descending=$true}, @{e='COM';Descending=$false}
Write-Host "== Mogelijke COM-poorten ==" 
$items | Format-Table -AutoSize

if (-not $items -or $items.Count -eq 0) { Write-Host "[let op] Geen seriële poorten gevonden."; exit 1 }

$best = $items | Select-Object -First 1
Write-Host ("`n=> Suggestie: {0}  ({1})" -f $best.COM, $best.Name)

if ($SetEnv) {
  $env:ARDUINO_PORT = $best.COM
  Write-Host "Set: `$env:ARDUINO_PORT = $($best.COM)"
}

if ($OpenTest) {
  try {
    $sp = New-Object System.IO.Ports.SerialPort $best.COM, $Baud, 'None', 8, 'One'
    $sp.ReadTimeout  = 600
    $sp.WriteTimeout = 600
    $sp.DtrEnable    = $true   # help UNO reset/ready worden
    $sp.Open()
    Start-Sleep -Milliseconds 500
    $sp.DiscardInBuffer()
    $sp.Write("H`n")
    Start-Sleep -Milliseconds 500
    $resp = ""
    try { $resp = $sp.ReadExisting() } catch {}
    $sp.Close()
    if ($resp -match 'OK') { Write-Host "[ok] Handshake OK op $($best.COM)" }
    else { Write-Host "[info] Open gelukt op $($best.COM), geen 'OK' (sketch nog niet geüpload of board niet klaar)" }
  } catch {
    Write-Host "[fout] Kon $($best.COM) niet openen: $($_.Exception.Message)"
  }
}
