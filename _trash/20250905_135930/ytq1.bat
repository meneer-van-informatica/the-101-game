@echo off
setlocal
if "%~1"=="" (
  echo usage: ytq1 VIDEOID_OR_URL [langs] [seed]
  echo   e.g. ytq1 qHvlJp2SGGk ^| ytq1 https://youtu.be/qHvlJp2SGGk
  exit /b 1
)
set URL=%~1
set LANGS=%~2
set SEED=%~3
if "%LANGS%"=="" set LANGS=nl,en
if "%SEED%"=="" set SEED=0
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0ytq_one.ps1" -Url "%URL%" -Langs "%LANGS%" -Seed "%SEED%"