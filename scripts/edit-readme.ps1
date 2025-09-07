param(
  [string]$File = 'README.md',
  [string]$Message = "docs: README update ($(Get-Date -Format 'yyyy-MM-dd HH:mm'))"
)

# fail fast als we niet in een git repo zitten
& git rev-parse --is-inside-work-tree 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
  Write-Host 'hier is geen git repo. run in je projectmap.' -ForegroundColor Yellow
  exit 1
}

# exFAT/veiligheidsfix (no harm on NTFS)
$top = (& git rev-parse --show-toplevel).Trim()
& git config --global --add safe.directory $top 2>$null | Out-Null

# open README in Notepad en wacht tot je klaar bent
if (-not (Test-Path $File)) { New-Item -ItemType File -Path $File | Out-Null }
Start-Process -FilePath notepad -ArgumentList $File -Wait

# check of README echt gewijzigd is
& git diff --quiet -- $File
$changed = ($LASTEXITCODE -ne 0)

if (-not $changed) {
  Write-Host 'geen veranderingen in README. nothing to commit.' -ForegroundColor Yellow
  exit 0
}

# add → commit → push
& git add -- $File
if ($LASTEXITCODE -ne 0) { Write-Host 'git add faalde.' -ForegroundColor Red; exit 1 }

& git commit -m $Message
if ($LASTEXITCODE -ne 0) { Write-Host 'git commit faalde.' -ForegroundColor Red; exit 1 }

& git push
if ($LASTEXITCODE -ne 0) { Write-Host 'git push faalde.' -ForegroundColor Red; exit 1 }

Write-Host 'README online gezet. klaar.' -ForegroundColor Green
