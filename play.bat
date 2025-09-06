@echo off
REM play.bat — start de Film (Film x Game) vanaf de ketting
REM Gebruik:
REM   play.bat                -> film met pauze, standaard chain (data\scene_chain.txt)
REM   play.bat C              -> film met pauze, route C (data\chain_economie.txt)
REM   play.bat C sceneC1_hue_pair  -> route C en starten vanaf specifieke scene

setlocal
cd /d "%~dp0"

REM venv activeren als die bestaat
if exist ".venv\Scripts\activate.bat" call ".venv\Scripts\activate.bat"

REM Python-ansi/utf8 ok
set "PYTHONUTF8=1"
set "PYTHONIOENCODING=utf-8"

REM optionele args doorgeven aan film.ps1
set "ARGS="
if not "%~1"=="" set "ARGS=%ARGS% -Chain %~1"
if not "%~2"=="" set "ARGS=%ARGS% -FromKey %~2"

powershell -NoProfile -ExecutionPolicy Bypass -File ".\scripts\film.ps1" %ARGS% -Pause
exit /b %ERRORLEVEL%
