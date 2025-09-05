@echo off
setlocal
pushd "%~dp0"
if exist ".venv\Scripts\python.exe" (
  ".venv\Scripts\python.exe" "engine.py"
) else (
  python "engine.py"
)
popd
