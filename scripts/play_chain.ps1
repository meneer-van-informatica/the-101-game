# scripts\play_chain.ps1
param(
  [string]$From = '',
  [int]$DelayMs = 200,
  [switch]$Dev,           # frames blijven staan; transcript op film-niveau
  [switch]$Transcript,
  [switch]$Loop           # herhaal de hele film tot je stopt
)
$ErrorActionPreference = 'Stop'

# grote scrollback
try{
  $raw=$Host.UI.RawUI; $buf=$raw.BufferSize; $win=$raw.WindowSize
  $buf.Width=[Math]::Max($buf.Width,160); $buf.Height=20000; $raw.BufferSize=$buf
  $win.Width=[Math]::Min($buf.Width,140); $win.Height=[Math]::Max($win.Height,50); $raw.WindowSize=$win
}catch{}

$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$chainPath = Join-Path $root 'data\scene_chain.txt'
if (-not (Test-Path $chainPath)) { throw 'data\scene_chain.txt ontbreekt' }
$keys = Get-Content $chainPath | % { $_.Trim() } | ? { $_ -ne '' }
$valid = @(); foreach($k in $keys){ if (Test-Path (Join-Path $root ("scenes\"+$k+".py"))) { $valid+=$k } }
if ($valid.Count -eq 0){ throw 'geen geldige scenes' }
$start = 0; if ($From){ $i=$valid.IndexOf($From); if ($i -ge 0){ $start=$i } }

# transcript (1 per film-run)
if ($Transcript){
  $logDir = Join-Path $root 'data\logs'; New-Item -ItemType Directory -Path $logDir -Force | Out-Null
  $stamp  = Get-Date -Format 'yyyyMMdd_HHmmss'
  $global:FilmTranscript = Join-Path $logDir ("film_"+$stamp+".log")
  try{ Start-Transcript -Path $global:FilmTranscript -Append | Out-Null }catch{}
}

# stopknop helper
function Stop-Requested {
  try{
    if ([console]::KeyAvailable){
      $k=[console]::ReadKey($true)
      if ($k.Key -in 'Q','Escape','X'){ return $true }
    }
  }catch{}
  return $false
}

do {
  for($n=$start; $n -lt $valid.Count; $n++){
    $k=$valid[$n]
    Write-Host ('-'*120)
    Write-Host ("[film] scene "+($n+1)+"/"+$valid.Count+": "+$k)
    Write-Host ('-'*120)
    $args=@('-File',(Join-Path $PSScriptRoot 'play_scene.ps1'),'-Key',$k)
    if ($Dev){ $args += '-Dev'; $args += '-NoTranscript' }
    powershell -ExecutionPolicy Bypass @args
    Start-Sleep -Milliseconds $DelayMs
    if (Stop-Requested){ $Loop=$false; break }
  }
} while ($Loop)

if ($Transcript){
  try{ Stop-Transcript | Out-Null }catch{}
  Write-Host "[log] film transcript: $global:FilmTranscript"
}
Write-Host "[ok] chain klaar."
