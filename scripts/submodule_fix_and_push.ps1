# scripts\submodule_fix_and_push.ps1
# doel: hardnekkige melding 'modified: user-site (untracked content)' oplossen
# plus kapotte submodule entry 'tmp_101_mirror/the-101-game-clean' uit .gitmodules verwijderen
# daarna rebasen op origin/main en pushen
# stijl: Windows-only, enkel quotes, stil en netjes

$ErrorActionPreference = 'Stop'

function step($m) { Write-Host ('[ok] ' + $m) }
function gitx { param([Parameter(ValueFromRemainingArguments=$true)][string[]]$Args) & git @Args; if ($LASTEXITCODE -ne 0) { throw ('git failed: ' + ($Args -join ' ')) } }

# 0) naar projectroot
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $repoRoot
step 'repo geladen'

# 1) basisconsole unicode
chcp 65001 | Out-Null

# 2) branch controleren
gitx rev-parse --abbrev-ref HEAD
$current = (& git rev-parse --abbrev-ref HEAD).Trim()
if ($current -ne 'main') { gitx switch main; step 'geswitcht naar main' } else { step 'op branch main' }

# 3) user-site submodule hard schoon
if (Test-Path '.\user-site\.git') {
    gitx -C user-site reset --hard
    gitx -C user-site clean -fdx
    # toon nog resterende untracked, puur informatief
    $left = & git -C user-site ls-files --others --exclude-standard
    if ($left) { Write-Host '[let op] ongetrackte rest in user-site:'; $left | ForEach-Object { Write-Host ('  - ' + $_) } } else { step 'user-site clean' }
} else {
    step 'geen submodule user-site gevonden (skip)'
}

# 4) kapotte submodule entry fixen (.gitmodules)
$gm = Join-Path $repoRoot '.gitmodules'
$removed = $false
if (Test-Path $gm) {
    $text = Get-Content $gm -Raw
    # verwijder blokken die de path 'tmp_101_mirror/the-101-game-clean' bevatten of die geen url hebben
    $patternBadPath = '(?ms)^\[submodule\s+''?[^''"]+''?\]\s*[^[]*?path\s*=\s*tmp_101_mirror/the-101-game-clean\s*[^[]*?(?=^\[submodule|\z)'
    $patternNoUrl   = '(?ms)^\[submodule\s+''?[^''"]+''?\]\s*(?:(?!^\[submodule).)*?path\s*=.*\r?\n(?:(?!^\[submodule).)*?(?=^\[submodule|\z)'
    # eerst specifiek pad
    $fixed = [regex]::Replace($text, $patternBadPath, '')
    if ($fixed -ne $text) { $removed = $true; $text = $fixed }
    # daarna defensief blokken zonder 'url =' wegvangen
    $blocks = ($text -split '(\r?\n)(?=\[submodule)')
    $rebuilt = New-Object System.Text.StringBuilder
    foreach ($b in $blocks) {
        if ($b -match '^\[submodule' -and ($b -notmatch '^\s*url\s*=')) {
            $pathLine = ($b -split "`n" | Where-Object { $_ -match '^\s*path\s*=' }) -join ''
            if ($pathLine) {
                $p = ($pathLine -replace '^\s*path\s*=\s*','').Trim()
                if ($p) { $removed = $true }
            }
            continue
        }
        [void]$rebuilt.Append($b)
    }
    $newText = $rebuilt.ToString()
    if ($removed) {
        Copy-Item $gm ($gm + '.bak') -Force
        Set-Content -Path $gm -Value $newText -Encoding UTF8
        step '.gitmodules opgeschoond'
        # deinit en verwijder map als die nog bestaat
        try { git submodule deinit -f tmp_101_mirror/the-101-game-clean | Out-Null } catch {}
        if (Test-Path '.\tmp_101_mirror\the-101-game-clean') {
            try { git rm -f --cached '.\tmp_101_mirror\the-101-game-clean' } catch {}
            Remove-Item -Recurse -Force '.\tmp_101_mirror\the-101-game-clean'
        }
        gitx add .gitmodules
    } else {
        step 'geen kapotte .gitmodules entries gevonden'
    }
} else {
    step '.gitmodules ontbreekt (skip)'
}

# 5) submodules syncen op basis van bijgewerkte .gitmodules
try { gitx submodule sync --recursive } catch {}
try { gitx submodule update --init --recursive } catch { Write-Host '[waarschuwing] submodule update gaf melding, ga door'; }

# 6) commit als er staged is
$staged = & git diff --cached --name-only
if ($staged) { gitx commit -m 'fix(submodules): purge user-site, remove broken submodule entry'; step 'commit gemaakt' } else { step 'niets te committen' }

# 7) rebase en push
gitx fetch origin
gitx pull --rebase origin main
step 'gerebased op origin/main'
gitx push origin main
step 'push voltooid'

# 8) eindstatus
& git status -s
Write-Host 'stilte: schoon, gesynct, online.'
