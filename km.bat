@echo off
setlocal
pushd "%~dp0"

REM Verzamel args
set "KM_ARGS=%*"

REM Speciaal geval: "km w0" wordt "--scene w0"
if /I "%~1"=="w0" (
  shift
  set "KM_ARGS=--scene w0 %*"
)

REM Start via venv-python, anders via play.bat, anders systeem-python
if exist ".venv\Scripts\python.exe" (
  ".venv\Scripts\python.exe" "engine.py" %KM_ARGS%
) else if exist "play.bat" (
  call "play.bat" %KM_ARGS%
) else (
  python "engine.py" %KM_ARGS%
)

popd
endlocal
