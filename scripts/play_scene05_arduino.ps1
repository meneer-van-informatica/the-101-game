# scripts\play_scene05_arduino.ps1
param([string]$Port = '')
$ErrorActionPreference='Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $root
if ($env:PYTHONPATH) { $env:PYTHONPATH = "$root;$env:PYTHONPATH" } else { $env:PYTHONPATH = $root }
$py    = Join-Path $root '.venv\Scripts\python.exe'
$scene = Join-Path $root 'scenes\scene05_arduino.py'
$args = @($scene)
if ($Port) { $args += @('-port', $Port) }
elseif ($env:ARDUINO_PORT) { $args += @('-port', $env:ARDUINO_PORT) }
& $py @args
