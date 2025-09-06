@echo off
setlocal
REM altijd naar de repo-root (map van dit bestand)
cd /d %~dp0

REM .\km.bat last  -> speel de laatste scene uit data\scene_chain.txt
if /i "%~1"=="last" (
  powershell -ExecutionPolicy Bypass -File ".\scripts\play_last.ps1"
  goto :eof
)

REM .\km.bat scene <key>  -> speel specifieke scene
if /i "%~1"=="scene" (
  if "%~2"=="" (
    echo usage: km.bat scene ^<key^>
    exit /b 1
  )
  powershell -ExecutionPolicy Bypass -File ".\scripts\play_scene.ps1" -Key %~2
  goto :eof
)

@if /I "%1"=="chain" powershell -ExecutionPolicy Bypass -File ".\scripts\play_chain.ps1"
@if /I "%1"=="chaindev"  powershell -ExecutionPolicy Bypass -File ".\scripts\play_chain.ps1" -Dev -Transcript
@if /I "%1"=="loop"      powershell -ExecutionPolicy Bypass -File ".\scripts\play_chain.ps1" -Dev -Transcript -Loop
@if /I "%1"=="film" powershell -ExecutionPolicy Bypass -File ".\scripts\play_chain.ps1"

echo usage:
echo   .\km.bat last
echo   .\km.bat scene ^<key^>
exit /b 0
