@echo off
cd /d %~dp0
powershell -ExecutionPolicy Bypass -File ".\scripts\play_chain.ps1" %*
