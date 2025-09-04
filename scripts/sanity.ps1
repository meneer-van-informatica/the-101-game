$ErrorActionPreference = 'Stop'

# projectroot + venv
$root = Split-Path -Path $PSScriptRoot -Parent
$act  = Join-Path $root '.venv\Scripts\Activate.ps1'
if (Test-Path $act) { . $act }

# >>> NIEUW: altijd in projectroot draaien + warnings dempen
Set-Location -Path $root
$env:PYGAME_HIDE_SUPPORT_PROMPT = '1'   # verbergt 'Hello from the pygame community'
$env:PYTHONWARNINGS = 'ignore'          # demp alle Python warnings (sledgehammer)

# python
$py = Get-Command 'python' -ErrorAction Stop

# timestamped shotdir en log
$runId   = Get-Date -Format 'yyyyMMdd_HHmmss'
$shotdir = Join-Path $root ('screenshots\sanity_' + $runId)
New-Item -ItemType Directory -Force -Path $shotdir | Out-Null
$logdir  = Join-Path $root 'logs'
New-Item -ItemType Directory -Force -Path $logdir | Out-Null
$log     = Join-Path $logdir ('sanity_' + $runId + '.log')

function Invoke-Step {
    param(
        [Parameter(Mandatory=$true)][string]   $Label,
        [Parameter(Mandatory=$true)][string[]] $Args
    )
    $exe  = $py.Source
    $file = Join-Path $root 'engine.py'
    Write-Host "[RUN] $Label :: $exe $file $($Args -join ' ')"

    # >>> BELANGRIJK: '-W ignore' voor Python schakelt warnings uit (dus geen stderr-spam)
    & $exe -W ignore $file @Args 2>&1 |
        Tee-Object -FilePath $log -Append | Out-Host

    if ($LASTEXITCODE -ne 0) { throw "step '$Label' exitcode $LASTEXITCODE" }
}

# 1) menu snapshot (één frame)
Invoke-Step 'menu' @('--start','menu','--snapshot','--shotdir', $shotdir)

# 2) w0 snapshot (fast-forward, laatste frame)
Invoke-Step 'w0'   @('--start','w0','--snapshot','--shotdir', $shotdir)

# controle op PNGs
$menuPng = Get-ChildItem -Path $shotdir -Filter 'menu_*.png' -ErrorAction SilentlyContinue
$w0Png   = Get-ChildItem -Path $shotdir -Filter 'w0_*.png'   -ErrorAction SilentlyContinue
if (-not $menuPng) { throw 'menu snapshot ontbreekt' }
if (-not $w0Png)   { throw 'w0 snapshot ontbreekt' }

'OK: snapshots aanwezig' | Tee-Object -FilePath $log -Append | Out-Host
exit 0
