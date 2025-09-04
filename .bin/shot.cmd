@echo off
powershell -NoProfile -ExecutionPolicy Bypass -Command "Set-Location '%~dp0..'; .\scripts\shot.ps1 %*"
