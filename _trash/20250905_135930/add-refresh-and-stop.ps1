# add-refresh-and-stop.ps1 (inline patch)
$ErrorActionPreference = 'Stop'
if (-not (Test-Path .\tools)) { New-Item -ItemType Directory -Force tools | Out-Null }
$TOOLS = ".\tools\game-dev.ps1"
if (-not (Test-Path $TOOLS)) { "" | Set-Content -Encoding utf8 $TOOLS }
$body = Get-Content $TOOLS -Raw

$EnsureRoot = @'
if (-not $script:ROOT) { $script:ROOT = (Get-Location).Path }
$PY = Join-Path $script:ROOT ".venv\Scripts\python.exe"
if (-not (Test-Path $PY)) { $PY = "python" }
'@

$RefreshFn = @'
function refresh {
  [CmdletBinding()] param()
  Write-Host "`n[refresh] repo + runtime status" -ForegroundColor Cyan

  # Git
  $branch = try { git rev-parse --abbrev-ref HEAD 2>$null } catch { "" }
  $last   = try { git log -1 --pretty=format:'%h %ad %s' --date=iso 2>$null } catch { "" }
  $dirty  = if ((git status --porcelain 2>$null)) { "*" } else { "" }
  if ($branch) { Write-Host ("  branch  : {0}{1}" -f $branch, $dirty) }
  if ($last)   { Write-Host ("  last    : {0}" -f $last) }

  # Python / Pygame
  try { & $PY -c "import sys;print('  Python  :',sys.version.split()[0])" } catch { Write-Warning "Python not found." }
  try { & $PY -c "import pygame;print('  Pygame  :',pygame.__version__)" } catch { Write-Warning "Pygame not installed." }

  # Worlds.json quick view
  $w = Join-Path $script:ROOT "data\worlds.json"
  if (Test-Path $w) {
    try {
      $arr = Get-Content $w -Raw | ConvertFrom-Json
      if ($arr) { Write-Host ("  worlds  : {0} -> {1}" -f $arr.Count, ($arr -join ', ')) }
    } catch { }
  }

  Write-Host "  cwd     : $((Get-Location).Path)"
  Write-Host "[ok] refresh done.`n" -ForegroundColor Green
}
'@

$StopFn = @'
function stop {
  [CmdletBinding()] param(
    [switch]$NoPush,      # alleen lokaal
    [switch]$AllowEmpty   # commit ook als er geen wijzigingen zijn
  )
  if (-not (Test-Path ".git")) { Write-Warning "No git repo here."; return }

  $now   = Get-Date
  $stamp = $now.ToString("yyyy-MM-dd HH:mm:ss zzz")
  $tag   = "snap-" + $now.ToString("yyyyMMdd_HHmmss")
  $tz    = try { (Get-TimeZone).Id } catch { "UnknownTZ" }
  $who   = "$env:COMPUTERNAME\$env:USERNAME"
  $msg   = "stop: $stamp [$tz] by $who"

  git add -A | Out-Null
  git diff --cached --quiet; $changed = ($LASTEXITCODE -ne 0)

  if ($changed -or $AllowEmpty) {
    $args = @("commit","-m",$msg)
    if (-not $changed) { $args = @("commit","--allow-empty","-m",$msg) }
    git @args | Out-Null
  } else {
    Write-Host "[stop] no changes; use -AllowEmpty to force." -ForegroundColor Yellow
  }

  # unieke tag (niet crashen als hij al bestaat)
  if (-not (git tag -l $tag)) { git tag -a $tag -m $msg | Out-Null }

  if (-not $NoPush) {
    try {
      git push | Out-Null
      git push origin $tag | Out-Null
      Write-Host "[stop] pushed • tag $tag" -ForegroundColor Green
    } catch {
      Write-Warning "[stop] push failed. Local commit/tag exist. Later: git push; git push origin $tag"
    }
  } else {
    Write-Host "[stop] committed locally • tag $tag (no push)" -ForegroundColor Green
  }
}
'@

# Ensure env helpers
if ($body -notmatch '(?m)^\s*if\s*\(-not\s*\$script:ROOT\)') {
  $body = $EnsureRoot + "`r`n`r`n" + $body
}
# Upsert refresh
if ($body -match '(?s)function\s+refresh\s*\{.*?\}') {
  $body = [regex]::Replace($body, '(?s)function\s+refresh\s*\{.*?\}', [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $RefreshFn })
} else {
  $body = $body.TrimEnd() + "`r`n`r`n" + $RefreshFn
}
# Upsert stop
if ($body -match '(?s)function\s+stop\s*\{.*?\}') {
  $body = [regex]::Replace($body, '(?s)function\s+stop\s*\{.*?\}', [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $StopFn })
} else {
  $body = $body.TrimEnd() + "`r`n`r`n" + $StopFn
}

$body | Set-Content -Encoding utf8 $TOOLS
. .\tools\game-dev.ps1
Write-Host "[ready] Commands: refresh  •  stop  •  stop -AllowEmpty  •  stop -NoPush" -ForegroundColor Cyan
