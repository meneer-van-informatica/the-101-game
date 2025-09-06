# scripts/film.ps1 — film-runner met pauze, route-keuze en (optionele) scene-timeout
param(
  [switch]$Pause = $true,
  [int]$From = 1,
  [string]$Chain = "",          # "", of "A"/"B"/"C"/"D", of pad naar chain-bestand
  [string]$FromKey = "",        # starten vanaf specifieke scene-naam
  [switch]$StopOnError,         # stop direct bij niet-0 exitcode
  [int]$SceneTimeoutSec = 0     # 0 = geen timeout; anders kill na zoveel seconden
)
$ErrorActionPreference = 'Stop'

# --- repo paths
$root  = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$play  = Join-Path $root 'scripts\play_scene.ps1'

# --- kies chain-bestand
function Resolve-ChainFile([string]$root, [string]$Chain){
  if ([string]::IsNullOrWhiteSpace($Chain)) {
    return (Join-Path $root 'data\scene_chain.txt')
  }
  switch ($Chain.ToUpper()) {
    'A' { return (Join-Path $root 'data\chain_software.txt') }
    'B' { return (Join-Path $root 'data\chain_hardware.txt') }
    'C' { return (Join-Path $root 'data\chain_economie.txt') }
    'D' { return (Join-Path $root 'data\chain_route4.txt') }
    default {
      $p = if ([System.IO.Path]::IsPathRooted($Chain)) { $Chain } else { Join-Path $root $Chain }
      return $p
    }
  }
}
$chain = Resolve-ChainFile $root $Chain

if (-not (Test-Path $chain)) { throw "scene_chain ontbreekt: $chain" }
if (-not (Test-Path $play))  { throw "play_scene.ps1 ontbreekt: $play" }

# --- laad chain
$keys = Get-Content -LiteralPath $chain | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
if ($keys.Count -eq 0) { throw "scene_chain is leeg: $chain" }

# --- zorg dat core.* imports werken voor child-Python
$env:PYTHONPATH = ($root + ($(if ($env:PYTHONPATH) { ";" + $env:PYTHONPATH } else { "" })))
$env:PYTHONUTF8 = '1'
$env:PYTHONIOENCODING = 'utf-8'

# --- helpers
function Wait-Pause {
  param([string]$Msg = "PAUSE - [Enter]/[Space] verder, [s] skip resterende pauzes, [q]/[Esc] stop")
  Write-Host ""
  Write-Host $Msg
  while ($true) {
    $key = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    if ($key.Character -eq 'q' -or $key.VirtualKeyCode -eq 27) { Write-Host "[film] gestopt."; exit 0 }
    if ($key.Character -eq 's' -or $key.Character -eq 'S') { return $false } # pauzes uitschakelen
    if ($key.VirtualKeyCode -eq 13 -or $key.Character -eq ' ') { return $true }
  }
}

function Run-Scene {
  param(
    [string]$Key,
    [int]$TimeoutSec = 0
  )
  $args = @('-NoProfile','-ExecutionPolicy','Bypass','-File',$play,'-Key',$Key)
  $proc = Start-Process -FilePath 'powershell' -ArgumentList $args -PassThru -WindowStyle Normal -WorkingDirectory $root
  if ($TimeoutSec -le 0) {
    $proc.WaitForExit()
    return $proc.ExitCode
  }
  $deadline = (Get-Date).AddSeconds($TimeoutSec)
  while (-not $proc.HasExited) {
    if (Get-Date -gt $deadline) {
      try { $proc.Kill() } catch {}
      Write-Host ("[film] scene '{0}' timeout na {1}s -> gekilled" -f $Key, $TimeoutSec) -ForegroundColor Yellow
      return 408
    }
    Start-Sleep -Milliseconds 100
  }
  return $proc.ExitCode
}

# --- startindex bepalen (via nummer of via FromKey)
$startIndex = [Math]::Max(1, [int]$From)
if ($FromKey) {
  $ix = ($keys | ForEach-Object { $_ }) -as [string[]]
  $pos = [Array]::IndexOf($ix, $FromKey)
  if ($pos -ge 0) { $startIndex = $pos + 1 }
}

# --- loop
for ($i = $startIndex - 1; $i -lt $keys.Count; $i++) {
  $k = $keys[$i]
  Write-Host ""
  Write-Host ("------------------------------------------------------------------------------------------------------")
  Write-Host ([string]::Format("[film] scene {0}/{1}: {2}", $i+1, $keys.Count, $k))
  Write-Host ("------------------------------------------------------------------------------------------------------")

  $t0 = Get-Date
  $code = Run-Scene -Key $k -TimeoutSec $SceneTimeoutSec
  $dt  = [int]((Get-Date) - $t0).TotalMilliseconds

  if ($code -ne 0) {
    Write-Host ("[film] scene '{0}' exitcode {1} ({2} ms)" -f $k, $code, $dt) -ForegroundColor Yellow
    if ($StopOnError) { Write-Host "[film] StopOnError actief -> stop."; exit $code }
  } else {
    Write-Host ("[film] scene '{0}' klaar ({1} ms)" -f $k, $dt)
  }

  if ($Pause) {
    $keep = Wait-Pause
    if ($keep -eq $false) { $Pause = $false; Write-Host "[film] pauzes uitgezet voor resterende scenes." }
  }
}

Write-Host ""
Write-Host "[film] klaar."
