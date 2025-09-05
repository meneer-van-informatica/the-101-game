@echo off
setlocal
if "%~1"=="" (
  echo usage: ytq VIDEOID_OR_URL [langs]
  echo   e.g. ytq qHvlJp2SGGk ^| ytq https://youtu.be/qHvlJp2SGGk
  exit /b 1
)
set URL=%~1
set LANGS=%~2
if "%LANGS%"=="" set LANGS=nl,en
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0ytq.ps1" -Url "%URL%" -Langs %LANGS%
