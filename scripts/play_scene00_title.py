# scripts\play_scene00_title.py (python runner)
$ErrorActionPreference='Stop'
$py = Join-Path $PSScriptRoot '..\.venv\Scripts\python.exe'
& $py (Join-Path $PSScriptRoot '..\scenes\scene00_title.py')
