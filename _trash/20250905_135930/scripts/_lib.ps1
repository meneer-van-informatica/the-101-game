$ErrorActionPreference = 'Stop'

# projectroot afleiden
$root = Split-Path -Path $PSScriptRoot -Parent
if (-not $root) { $root = (Get-Location).Path }

# venv activeren als aanwezig
$act = Join-Path $root '.venv\Scripts\Activate.ps1'
if (Test-Path $act) { . $act }

# shell detecteren zonder ternary
$shell = 'powershell'
if (Get-Command 'pwsh' -ErrorAction SilentlyContinue) { $shell = 'pwsh' }

# python zoeken
$py = Get-Command 'python' -ErrorAction Stop

function Invoke-Start {
    param([Parameter(Mandatory=$true)][string]$StartArg)

    $engine = Join-Path $root 'engine.py'
    if (-not (Test-Path $engine)) {
        throw "engine.py niet gevonden in $root"
    }

    $cmd  = "$($py.Source) $engine --start $StartArg"
    $args = @('-NoExit','-ExecutionPolicy','Bypass','-Command', $cmd)
    Start-Process -FilePath $shell -ArgumentList $args -WorkingDirectory $root | Out-Null
}
