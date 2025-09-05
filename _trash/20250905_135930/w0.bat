@echo off
setlocal
pushd "%~dp0"
REM Probeer met --scene w0; zo niet, val terug op env-var SCENE=w0
if exist ".venv\Scripts\python.exe" (
  set "SCENE=w0"
  ".venv\Scripts\python.exe" "engine.py" --scene w0 2>nul || ".venv\Scripts\python.exe" "engine.py"
) else (
  set "SCENE=w0"
  python "engine.py" --scene w0 2>nul || python "engine.py"
)
popd
