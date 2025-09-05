@echo off
setlocal
pushd "%~dp0"
set SCENE=%1
if "%SCENE%"=="" set SCENE=w0
REM Gebruik bestaande scripts:
if exist ".\scripts\shot.ps1" (
  powershell -NoProfile -ExecutionPolicy Bypass -File ".\scripts\shot.ps1" "%SCENE%"
) else if exist ".\.bin\shot.cmd" (
  ".\.bin\shot.cmd" "%SCENE%"
) else (
  echo [shot] geen shot script gevonden
)
popd
