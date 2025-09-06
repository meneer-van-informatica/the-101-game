param(
  [string]$Team,
  [string]$Pattern = 'x',         # bv: 'x.x..x' of 'SOS'
  [switch]$Long,                  # lange flash (lselect)
  [int]$IntervalMs = 300,
  [int]$DebounceMs = 200,
  [int]$Times = 1,                # gebruikt als Pattern = 'x'
  [int]$Group = 0,
  [int]$Bri = 200,                # 1..254
  [string]$Color = '',            # 'red','blue','green','white','yellow','purple','cyan','orange'
  [string]$Config = 'E:\the-101-game\data\hue_config.json',
  [string]$Teams = 'E:\the-101-game\data\hue_teams.psd1'
)
$ErrorActionPreference = 'Stop'

function Get-HueXY([string]$name){
  switch ($name.ToLower()){
    'red'    { return @(0.675,0.322) }
    'green'  { return @(0.409,0.518) }
    'blue'   { return @(0.167,0.04) }
    'white'  { return @(0.3227,0.329) }
    'yellow' { return @(0.443,0.517) }
    'purple' { return @(0.272,0.109) }
    'cyan'   { return @(0.17,0.34) }
    'orange' { return @(0.556,0.408) }
    default  { return $null }
  }
}

if(-not (Test-Path $Config)){ throw 'config ontbreekt: E:\the-101-game\data\hue_config.json' }
$cfg = Get-Content $Config -Raw | ConvertFrom-Json
$ip = $cfg.bridge_ip; if(-not $ip -and $cfg.ip){ $ip = $cfg.ip }
$user = $cfg.username; if(-not $user){ $user = $cfg.key ?? $cfg.token }

# Team-overlay
if($Team){
  if(Test-Path $Teams){
    $t = Import-PowerShellDataFile -Path $Teams
    if($t.ContainsKey($Team)){
      if($t[$Team].ContainsKey('group')){ $Group = [int]$t[$Team].group }
      if($t[$Team].ContainsKey('color') -and -not $Color){ $Color = [string]$t[$Team].color }
      if($t[$Team].ContainsKey('bri')){ $Bri = [int]$t[$Team].bri }
    }
  }
}

$uri = 'http://{0}/api/{1}/groups/{2}/action' -f $ip,$user,$Group
$alert = $Long.IsPresent ? 'lselect' : 'select'
$xy = $Color ? (Get-HueXY $Color) : $null

function Invoke-Hue([string]$json){
  $tries = 0
  do {
    try {
      return Invoke-RestMethod -Method Put -Uri $using:uri -Body $json -ContentType 'application/json' -TimeoutSec 3
    } catch {
      $tries++
      Start-Sleep -Milliseconds 150
      if($tries -ge 3){ throw }
    }
  } while ($true)
}

# Debounce
$lockDir = 'E:\the-101-game\tmp'
$lock = Join-Path $lockDir 'hue_blink.lock'
if(-not (Test-Path $lockDir)){ New-Item -ItemType Directory -Path $lockDir | Out-Null }
$now = [int64](Get-Date -UFormat %s%3) # ms
if(Test-Path $lock){
  $last = [int64](Get-Content $lock -Raw)
  if(($now - $last) -lt $DebounceMs){ return } # te snel; skip
}
Set-Content -Path $lock -Value $now -Encoding Ascii

# Basis: kleur zetten (optioneel), dan alert
function FlashOnce {
  if($xy){
    $set = @{
      on  = $true
      bri = [int]$Bri
      xy  = @([double]$xy[0],[double]$xy[1])
    } | ConvertTo-Json -Compress
    Invoke-Hue $set | Out-Null
    Start-Sleep -Milliseconds 40
  }
  $flash = @{ alert = $alert } | ConvertTo-Json -Compress
  Invoke-Hue $flash | Out-Null
}

# Patroon bouwen
function Expand-Pattern([string]$p){
  if($p -match '^(?i)SOS$'){ return @('x','.','x','.','x','..','x','..','x','..','x','.','x','.','x') }
  return $p.ToCharArray() | ForEach-Object { $_.ToString() }
}

$seq = @()
if($Pattern -eq 'x' -and $Times -gt 1){
  1..$Times | ForEach-Object { $seq += 'x'; if($_ -lt $Times){ $seq += '.' } }
} else {
  $seq = Expand-Pattern $Pattern
}

foreach($step in $seq){
  if($step -eq 'x'){ FlashOnce }
  Start-Sleep -Milliseconds $IntervalMs
}
