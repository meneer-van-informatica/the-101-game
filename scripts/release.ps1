Param(
  [Parameter(Mandatory=$true)][string]$Version,   # bv "1.0"
  [string]$Codename = "Bommel",
  [switch]$Pages,                 # ook docs genereren
  [string]$Docs = "docs"
)

$ErrorActionPreference = "Stop"
function Write-Info($m){ Write-Host "› $m" -ForegroundColor Cyan }
function Has-Exe($name){ $null -ne (Get-Command $name -ErrorAction SilentlyContinue) }

# 1) Optional pages build
if ($Pages) {
  if (-not (Test-Path "scripts\gen-pages.ps1")) { throw "scripts\gen-pages.ps1 ontbreekt." }
  Write-Info "Genereer Pages ($Docs)…"
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\gen-pages.ps1 -Docs $Docs -Version $Version -Codename $Codename
}

# 2) Badge in README.md
$readme = "README.md"
if (-not (Test-Path $readme)) { New-Item -ItemType File -Path $readme | Out-Null }
$md = Get-Content $readme -Raw
$start = "<!-- RELEASE BADGE START -->"
$end   = "<!-- RELEASE BADGE END -->"
$badge = "[![Release](https://img.shields.io/badge/release-v$Version%20($Codename)-6cf?style=for-the-badge)](https://meneer-van-informatica.github.io/)"
$block = "$start`r`n$badge`r`n$end"

if ($md -match [regex]::Escape($start) -and $md -match [regex]::Escape($end)) {
  $md = $md -replace "(?s)$([regex]::Escape($start)).*?$([regex]::Escape($end))", [System.Text.RegularExpressions.MatchEvaluator]{ $block }
} else {
  $md = "$block`r`n`r`n$md"
}
$utf8 = New-Object System.Text.UTF8Encoding($false)
[IO.File]::WriteAllText($readme,$md,$utf8)
Write-Info "Badge in README.md gezet."

# 3) Commit, tag, push
$tag = "v$Version"
$relTitle = "$tag - $Codename"
Write-Info "Git commit & tag…"
git add -A
# Alleen committen als er wijzigingen zijn
$dirty = git status --porcelain
if ($dirty) { git commit -m "Release $relTitle" | Out-Null } else { Write-Info "Geen wijzigingen te committen." }
# Tag (overschrijven met -f als tag al bestaat)
git tag -a $tag -m "$relTitle" -f
git push origin HEAD
git push origin --tags -f
Write-Info "Gepusht met tag $tag."

# 4) Optioneel: GitHub Release met gh CLI
if (Has-Exe "gh") {
  Write-Info "Maak GitHub Release (gh)…"
  try {
    gh release delete $tag -y 2>$null | Out-Null
  } catch {}
  gh release create $tag -t "$relTitle" -n "Auto release vanuit scripts\release.ps1" | Out-Null
  Write-Info "GitHub Release klaar."
} else {
  Write-Info "gh CLI niet gevonden — sla GitHub Release stap over."
}

Write-Host "✅ Release $relTitle klaar." -ForegroundColor Green
