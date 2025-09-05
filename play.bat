@echo off
setlocal enableextensions

if not exist .venv (
  py -3 -m venv .venv
)

call .venv\Scripts\activate.bat
python -m pip install --upgrade pip >nul
if exist requirements.txt (
  pip install -r requirements.txt
)

for %%F in (game.py app.py main.py) do (
  if exist %%F (
    python %%F
    goto end
  )
)

echo No entry point found. Add game.py or app.py or main.py.
:end
