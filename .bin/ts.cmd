@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\scripts\push-ts.ps1" %*
