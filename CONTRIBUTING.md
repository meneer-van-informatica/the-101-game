# Contributing

## New Programmer Workflow
1. Fork en clone.
2. Run lokaal met `.\play.bat`.
3. Branch: `git checkout -b feat/<onderwerp>`.
4. Laat AI een mini-plan schrijven en voer het zelf uit.
5. Test met `.\play.bat`.
6. Commit klein met Conventional Commits:
   - `feat: ...`, `fix: ...`, `docs: ...`, `chore: ...`, `refactor: ...`
7. Push en open een Pull Request.
8. Beschrijf wat en waarom, link issues, voeg korte testnotitie toe.

## Coding standards
- Windows-first: PowerShell en Python.
- Geen muis-stappen; alles via CLI.
- Gebruik `.venv`, geen globale installs.
- Commit geen secrets.

## Setup hints
```powershell
.\play.bat
```
- Autocreates venv, upgrades pip, en installeert `requirements.txt`.
