# scripts\run.ps1 — robust runner (venv + src support + fallback main.py)
Set-Location (Get-Location)

if (-not (Test-Path .\.venv\Scripts\python.exe)) { py -3.12 -m venv .venv }
$py = ".\.venv\Scripts\python.exe"

& $py -m pip install --upgrade pip
if (Test-Path .\requirements.txt) { & $py -m pip install -r .\requirements.txt }

if     (Test-Path .\main.py)                       { & $py .\main.py }
elseif (Test-Path .\game.py)                       { & $py .\game.py }
elseif (Test-Path .\app.py)                        { & $py .\app.py }
elseif (Test-Path .\src\the_101_game) {
    # package layout: ensure src on sys.path
    $env:PYTHONPATH = (Resolve-Path .\src)
    & $py -m the_101_game
}
else {
    # create minimal entry and run
    $code = @"
from rich import print

def main() -> None:
    print("[bold]The 101 Game[/bold] zegt: Hallo Mama ❤️")

if __name__ == "__main__":
    main()
"@
    Set-Content -Path .\main.py -Value $code -Encoding utf8
    & $py .\main.py
}
