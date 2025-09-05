@echo off
setlocal
pushd "%~dp0"

set "KM_ARGS=%*"
if /I "%~1"=="w0" (
  shift
  set "KM_ARGS=--scene w0 %*"
)

if exist ".venv\Scripts\python.exe" (
  ".venv\Scripts\python.exe" "engine.py" %KM_ARGS%
) else if exist "play.bat" (
  call "play.bat" %KM_ARGS%
) else (
  python "engine.py" %KM_ARGS%
)

popd
endlocal
