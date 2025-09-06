@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\hue_blink_all.ps1" %*
