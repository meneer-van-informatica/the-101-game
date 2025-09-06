# scripts\submodule_nuke_and_push.ps1
# doel: hardnekkige 'modified: user-site (untracked content)' oplossen
# aanpak: user-site submodule hard clean, geneste rommel weg, foute submodule refs opruimen,
#         alles committen, rebasen en pushen.
# stijl: Windows-only, enkel quotes, rustig en stil.

$ErrorActionPreference = 'Stop'

function step { param($m) Write-Host ('[ok] ' + $m) }
function warn { param($m) Write-Host ('[let op] ' + $m) }
function gitx { param([Parameter(ValueFromRemainingArguments=$true)][string[]]$Args)
  & git @Args
  if ($LASTEXITCODE -ne 0) { throw ('git faalde: ' + ($Args -join ' ')) }
}

# 0) repo root bepalen en daarheen
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $repoRoot
step 'repo geladen'

# 1) unicode console en branch check
chcp 65001 | Out-Null
$current = (& git rev-parse --abbrev-ref HEAD).Trim()
if ($current -ne 'main') { gitx switch main; step 'geswitcht naar main' } else { step 'op branch main' }

# 2) user-site submodule hard schoon
if ( (Test-Path '.\user-site\.git') -or (Test-Path '.\user-site') ) {
    if (Test-Path '.\user-site\.git') {
        gitx -C user-site reset --hard
        gitx -C user-site clean -ffdx
        step 'user-site: reset + clean'
    } else {
        warn 'user-site map bestaat maar .git ontbreekt; verwijder en re-init'
        Remove-Item -Recurse -Force '.\user-site'
        gitx submodule update --init user-site
    }

    # specifiek: per ongeluk geneste kloon weghalen
    if (Test-Path '.\user-site\user-site') {
        warn 'verwijder geneste map user-site\user-site'
        Remove-Item -Recurse -Force '.\user-site\user-site'
    }

    # nog resterende untracked items tonen en extra clean forceren
    $left = & git -C user-site ls-files --others --exclude-standard
    if ($left) {
        warn 'ongetrackte rest in user-site:'
        $left | ForEach-Object { Write-Host ('  - ' + $_) }
        gitx -C user-site clean -ffdx
    }
} else {
    step 'geen submodule user-site gevonden (skip)'
}

# 3) foute submodule refs opruimen (bekende boosdoener)
try { git config -f .git/config --remove-section 'submodule.tmp_101_mirror/the-101-game-clean' | Out-Null } catch {}
if (Test-Path '.\tmp_101_mirror\the-101-game-clean') {
    try { git rm -f --cached '.\tmp_101_mirror\the-101-game-clean' | Out-Null } catch {}
    Remove-Item -Recurse -Force '.\tmp_101_mirror\the-101-game-clean'
    step 'verkeerde submodule map verwijderd'
}

# 4) submodules syncen en exact zetten op pointer van parent
try { gitx submodule sync --recursive } catch {}
# alleen zeker bestaande submodule(s) updaten om .gitmodules-fouten te vermijden
if (Test-Path '.\user-site\.git') { try { gitx submodule update --init user-site } catch { warn 'submodule update gaf melding, ga door' } }

# 5) parent repo: stage alle eigen wijzigingen (scripts e.d.), submodulepointer indien aangepast
git add -A | Out-Null

# 6) commit als er staged is
$staged = (& git diff --cached --name-only)
if ($staged) {
    gitx commit -m 'chore(git): submodule nuke/normalize; cleanup scripts; stilte'
    step 'commit gemaakt'
} else {
    step 'niets te committen'
}

# 7) rebase op origin/main en push
gitx fetch origin
gitx pull --rebase origin main
step 'gerebased op origin/main'
gitx push origin main
step 'push voltooid'

# 8) eindstatus
Write-Host '--- submodule status ---'
& git -C user-site status --porcelain
Write-Host '--- parent status ---'
& git status -s
Write-Host 'stilte: schoon, gesynct, online.'
