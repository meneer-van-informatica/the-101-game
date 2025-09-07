# scripts\monnie.ps1 — Monnie Takkies (ABN helper, ASCII-safe, PS 5.1)
param(
  [ValidateSet('show','add','open','trend','hue')]
  [string]$cmd = 'show',
  [string]$amount,
  [int]$days = 30,
  [decimal]$ok = 100.00
)

$ErrorActionPreference = 'Stop'
$dir  = Join-Path $env:USERPROFILE 'Documents\Monnie'
$file = Join-Path $dir 'abn.csv'
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
if (-not (Test-Path $file)) { 'timestamp,amount' | Set-Content -Path $file -Encoding utf8 }

function Parse-Amount([string]$txt) {
  if (-not $txt) { throw 'Geen bedrag opgegeven.' }
  $t = $txt.Trim() -replace '\s',''
  $t = $t -replace ',','.'
  [decimal]::Parse($t, [System.Globalization.CultureInfo]::InvariantCulture)
}

function Load-Data {
  (Get-Content $file | Select-Object -Skip 1) | ForEach-Object {
    if ($_ -match '^([^,]+),(.+)$') {
      [pscustomobject]@{
        ts = [datetime]$Matches[1]
        amount = [decimal]::Parse($Matches[2], [System.Globalization.CultureInfo]::InvariantCulture)
      }
    }
  }
}

function Format-EUR([decimal]$v) {
  $nl = New-Object System.Globalization.CultureInfo('nl-NL')
  'EUR ' + $v.ToString('N2', $nl)  # ASCII-safe: geen euroteken
}

switch ($cmd) {

  'open' {
    Start-Process 'https://www.abnamro.nl/mijn-abnamro/authenticatie/inloggen/'
    break
  }

  'add' {
    if (-not $amount) { $amount = Read-Host 'Nieuw saldo (bijv 1234,56 of 1234.56)' }
    $val = Parse-Amount $amount
    $line = '{0},{1}' -f (Get-Date).ToString('yyyy-MM-dd HH:mm:ss'), $val.ToString([System.Globalization.CultureInfo]::InvariantCulture)
    Add-Content -Path $file -Value $line -Encoding utf8
    Write-Host ('OK: saldo opgeslagen: {0}' -f (Format-EUR $val)) -ForegroundColor Green
    break
  }

  'show' {
    $rows = Load-Data
    if (-not $rows) { Write-Host 'Nog geen data. Run: abn add 123,45' -ForegroundColor Yellow; break }
    $last = $rows | Select-Object -Last 1
    $ago  = New-TimeSpan -Start $last.ts -End (Get-Date)
    $agoTxt = '{0:hh\:mm\:ss}' -f $ago
    Write-Host ("Saldo: {0}  (laatste update {1:g} - {2} geleden)" -f (Format-EUR $last.amount), $last.ts, $agoTxt) -ForegroundColor Cyan
    break
  }

  'trend' {
    $rows = Load-Data
    if (-not $rows) { Write-Host 'Nog geen data. Run eerst: abn add ...' -ForegroundColor Yellow; break }
    $from = (Get-Date).AddDays(-$days)
    $slice = $rows | Where-Object { $_.ts -ge $from }
    if (-not $slice) { Write-Host ("Geen data laatste {0} dagen." -f $days) -ForegroundColor Yellow; break }
    $min = ($slice | Measure-Object amount -Minimum).Minimum
    $max = ($slice | Measure-Object amount -Maximum).Maximum
    $range = [math]::Max(1.0, [double]($max - $min))
    foreach ($r in $slice) {
      $level = [int]([math]::Round((([double]$r.amount - [double]$min) / $range) * 30))
      $bar = ('#' * $level)
      Write-Host ('{0:MM-dd} {1,12} | {2}' -f $r.ts, (Format-EUR $r.amount), $bar)
    }
    break
  }

  'hue' {
    $rows = Load-Data
    $lastAmt = if ($rows) { $rows[-1].amount } else { 0 }
    $hue = Join-Path (Get-Location) 'scripts\hue.ps1'
    if (-not (Test-Path $hue)) { Write-Host 'scripts\hue.ps1 ontbreekt' -ForegroundColor Yellow; break }
    if ($lastAmt -ge $ok) {
      powershell -File $hue -Green
      Write-Host ("HUE: GROEN (saldo {0} >= drempel {1})" -f (Format-EUR $lastAmt), (Format-EUR $ok)) -ForegroundColor Green
    } else {
      powershell -File $hue -Red
      Write-Host ("HUE: ROOD (saldo {0} < drempel {1})" -f (Format-EUR $lastAmt), (Format-EUR $ok)) -ForegroundColor Red
    }
    break
  }
}
