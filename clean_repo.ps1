param([switch]$Apply)

$ErrorActionPreference = "Stop"
$root  = $PSScriptRoot
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$trash = Join-Path $root ("_trash\" + $stamp)

# Houden (pas aan naar wens)
$keep = @(
  # dirs
  "core","scenes","data",".git",".github",
  # files
  "engine.py","play.bat","km.bat","bootstrap.ps1","requirements.txt",
  "README.md",".gitignore",".gitattributes","LICENSE",".editorconfig"
)

# verzamel alles in root
$items = Get-ChildItem -Force

# bepaal wat weg mag (alles dat niet in $keep staat), MAAR sla _trash en de cleaner zelf over
$move = @()
foreach ($i in $items) {
  if ($i.Name -eq '_trash') { continue }
  if ($i.Name -eq 'clean_repo.ps1') { continue }
  if ($keep -notcontains $i.Name) { $move += $i }
}

if (-not $Apply) {
  Write-Host "---- DRY RUN ----" -ForegroundColor Yellow
  if ($move.Count -eq 0) { Write-Host "niets te verplaatsen"; exit 0 }
  $move | ForEach-Object { Write-Host ("would move: " + $_.FullName) }
  Write-Host ("Run met -Apply om te verplaatsen naar {0}" -f $trash) -ForegroundColor Yellow
  exit 0
}

New-Item -ItemType Directory -Force -Path $trash | Out-Null
foreach ($m in $move) {
  $dest = Join-Path $trash $m.Name
  Write-Host ("move: " + $m.FullName) -ForegroundColor Cyan
  Move-Item -Force -Path $m.FullName -Destination $dest
}
Write-Host ("[clean] klaar â†’ {0}" -f $trash) -ForegroundColor Green
