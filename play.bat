@echo off
setlocal
pushd "%~dp0"

REM Gebruik venv of bootstrap 'm
if not exist ".venv\Scripts\python.exe" (
  echo [play] geen venv gevonden -> bootstrap...
  powershell -NoProfile -ExecutionPolicy Bypass -File ".\bootstrap.ps1"
)

REM Start engine
if exist ".venv\Scripts\python.exe" (
  ".venv\Scripts\python.exe" "engine.py" %*
) else (
  REM fallback (als bootstrap faalde maar systeem-python bestaat)
  python "engine.py" %*
)

popd
endlocal