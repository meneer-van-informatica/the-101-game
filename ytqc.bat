@echo off
setlocal
if "%~1"=="" (
  echo usage: ytqc VIDEOID_OR_URL [langs]
  echo   e.g. ytqc qHvlJp2SGGk  ^|  ytqc https://youtu.be/qHvlJp2SGGk
  exit /b 1
)
set URL=%~1
set LANGS=%~2
if "%LANGS%"=="" set LANGS=nl,en
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0ytq_clean.ps1" -Url "%URL%" -Langs %LANGS% -Open
