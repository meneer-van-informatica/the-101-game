param(
  [int]$Times = 1,
  [int]$IntervalMs = 350,
  [int]$Group = 0,
  [string]$Config = 'E:\the-101-game\data\hue_config.json'
)
$ErrorActionPreference = 'Stop'
if(-not (Test-Path $Config)){ throw 'config ontbreekt: E:\the-101-game\data\hue_config.json' }
$cfg = Get-Content $Config -Raw | ConvertFrom-Json
$ip   = $cfg.bridge_ip
if(-not $ip -and $cfg.ip){ $ip = $cfg.ip }
$user = $cfg.username
if(-not $user -and $cfg.key){ $user = $cfg.key }
if(-not $user -and $cfg.token){ $user = $cfg.token }
if($cfg.group -ne $null){ $Group = [int]$cfg.group }

$uri  = 'http://{0}/api/{1}/groups/{2}/action' -f $ip,$user,$Group
$body = '{ "alert": "select" }'  # 'select' = korte flash; 'lselect' = ~15s

for($i=0; $i -lt $Times; $i++){
  Invoke-RestMethod -Method Put -Uri $uri -Body $body -ContentType 'application/json'
  if($i -lt ($Times-1)){ Start-Sleep -Milliseconds $IntervalMs }
}
