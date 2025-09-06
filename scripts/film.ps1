# scripts/film.ps1 — film-runner met pauze tussen scenes (ASCII only)
param(
  [switch]$Pause = $true,
  [int]$From = 1
)
$ErrorActionPreference = 'Stop'

$root  = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$chain = Join-Path $root 'data\scene_chain.txt'
$play  = Join-Path $root 'scripts\play_scene.ps1'

if (-not (Test-Path $chain)) { throw "scene_chain ontbreekt: $chain" }
if (-not (Test-Path $play))  { throw "play_scene.ps1 ontbreekt: $play" }

# laad chain
$keys = Get-Content $chain | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
if ($keys.Count -eq 0) { throw "scene_chain is leeg." }

# zorg dat core.* imports werken
if ($env:PYTHONPATH) {
  $env:PYTHONPATH = "$root;$env:PYTHONPATH"
} else {
  $env:PYTHONPATH = $root
}

function Wait-Pause {
  param(
    [string]$Msg = "PAUSE - druk [Enter] of [Space] om verder te gaan, [q] of [Esc] om te stoppen..."
  )
  Write-Host ""
  Write-Host $Msg
  while ($true) {
    $key = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    if ($key.Character -eq 'q' -or $key.VirtualKeyCode -eq 27) {
      Write-Host "[film] gestopt."
      exit 0
    }
    if ($key.VirtualKeyCode -eq 13 -or $key.Character -eq ' ') {
      break
    }
  }
}

$startIndex = [Math]::Max(1, [int]$From)
for ($i = $startIndex - 1; $i -lt $keys.Count; $i++) {
  $k = $keys[$i]

  Write-Host ""
  Write-Host ("------------------------------------------------------------------------------------------------------")
  Write-Host ([string]::Format("[film] scene {0}/{1}: {2}", $i+1, $keys.Count, $k))
  Write-Host ("------------------------------------------------------------------------------------------------------")

  & powershell -NoProfile -ExecutionPolicy Bypass -File $play -Key $k
  $exit = $LASTEXITCODE

  if ($exit -ne 0) {
    Write-Host ("[film] scene '{0}' gaf exitcode {1} (ga door)" -f $k, $exit) -ForegroundColor Yellow
  }

  if ($Pause) { Wait-Pause }
}

Write-Host ""
Write-Host "[film] klaar."
