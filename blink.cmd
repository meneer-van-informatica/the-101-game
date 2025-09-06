@echo off
setlocal
set "ARGS=%*"
echo %ARGS% | findstr /I "\-Beat" >nul || set "ARGS=-Beat %ARGS%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\hue_blink_all.ps1" %ARGS%