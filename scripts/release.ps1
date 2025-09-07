param([string]$Version = 'v0.1.0', [switch]$Prerelease)

Set-Location (git rev-parse --show-toplevel).Trim()
$zip = ".\dist\the-101-game-$Version-win64.zip"

Remove-Item -Recurse -Force .\dist -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path .\dist | Out-Null

$include = @('README.md','LICENSE','requirements.txt','scripts\w0.ps1','main.py','game.py','app.py','src','assets','data') | Where-Object { Test-Path $_ }
Compress-Archive -Path $include -DestinationPath $zip -Force

git add -A
git commit -m "release: $Version" 2>$null
git tag -a $Version -m "The 101 Game $Version"
git push
git push origin $Version

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { winget install --id GitHub.cli -e --source winget }
gh auth status 2>$null | Out-Null; if ($LASTEXITCODE -ne 0) { gh auth login --web }

$notes = "# The 101 Game $Version`n`n- Zero-friction Windows start`n- Auto venv + requirements`n- 'scripts\\w0.ps1' quickstart"
$nf = ".\dist\RELEASE_NOTES_$Version.md"; $notes | Set-Content -Path $nf -Encoding utf8

$flags = @(); if ($Prerelease) { $flags += '--prerelease' }
gh release create $Version $zip --title "The 101 Game $Version" --notes-file $nf @flags
