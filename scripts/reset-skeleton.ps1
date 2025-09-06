param([switch]$DryRun)

$repo = 'E:\the-101-game'
$trash = Join-Path $repo ("_trash\{0:yyyyMMdd}_repo_sweep" -f (Get-Date))
$keep = @(
  '.git', '.gitignore', '.gitattributes', '.editorconfig',
  'README.md', 'pyproject.toml', 'requirements.txt',
  'scripts', 'scripts\reset-skeleton.ps1', 'scripts\dev.ps1',
  'src', 'src\the_101_game', 'src\the_101_game\__init__.py', 'src\the_101_game\main.py',
  'tests', 'tests\test_smoke.py',
  'data', 'data\.gitkeep', 'data\logs', 'data\logs\.gitkeep'
) | ForEach-Object { (Join-Path $repo $_) }

# maak trash-map
if (-not (Test-Path $trash)) { New-Item -ItemType Directory -Path $trash | Out-Null }

# bepaal wat weg moet
$all = Get-ChildItem -Force -LiteralPath $repo
$moveList = @()
foreach ($item in $all) {
  if ($keep -contains $item.FullName) { continue }
  if ($item.Name -eq '.' -or $item.Name -eq '..') { continue }
  if ($item.Name -eq '_trash') { continue }
  $moveList += $item
}

Write-Host ('[plan] {0} item(s) naar {1}' -f $moveList.Count, $trash) -ForegroundColor Cyan
$moveList | ForEach-Object { Write-Host " - $($_.FullName)" }

if ($DryRun) { return }

# verplaats rommel veilig
foreach ($m in $moveList) {
  $dest = Join-Path $trash $m.Name
  Move-Item -LiteralPath $m.FullName -Destination $dest -Force
}

# skelet aanleggen
$paths = @(
  'src\the_101_game', 'tests', 'data\logs'
) | ForEach-Object { Join-Path $repo $_ }
foreach ($p in $paths) { if (-not (Test-Path $p)) { New-Item -ItemType Directory -Path $p | Out-Null } }

# ankers
$gitkeeps = @('data\.gitkeep','data\logs\.gitkeep') | ForEach-Object { Join-Path $repo $_ }
foreach ($g in $gitkeeps) { if (-not (Test-Path $g)) { New-Item -ItemType File -Path $g | Out-Null } }

# minimale bestanden als ze ontbreken
$req = Join-Path $repo 'requirements.txt'
if (-not (Test-Path $req)) { Set-Content -Path $req -Value "rich`npytest`nruff" -NoNewline }

$pyproj = Join-Path $repo 'pyproject.toml'
if (-not (Test-Path $pyproj)) {
  Set-Content -Path $pyproj -Value @"
[tool.ruff]
target-version = 'py312'
line-length = 100
fix = true

[tool.pytest.ini_options]
addopts = '-q'
testpaths = ['tests']
"@
}

$main = Join-Path $repo 'src\the_101_game\main.py'
if (-not (Test-Path $main)) {
  Set-Content -Path $main -Value "from rich import print`n`nif __name__ == '__main__':`n    print('[bold]the-101-game[/bold] zegt: hallo, wereld')" -NoNewline
}

$init = Join-Path $repo 'src\the_101_game\__init__.py'
if (-not (Test-Path $init)) { New-Item -ItemType File -Path $init | Out-Null }

$test = Join-Path $repo 'tests\test_smoke.py'
if (-not (Test-Path $test)) { Set-Content -Path $test -Value "def test_smoke():`n    assert True" -NoNewline }
