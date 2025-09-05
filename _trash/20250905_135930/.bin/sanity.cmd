@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\scripts\sanity.ps1" %*
