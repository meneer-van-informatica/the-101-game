# scripts\submodule_purge_and_push.ps1
# doel: submodule 'user-site' volledig schoonmaken (untracked content weg),
#       script zelf toevoegen aan de repo, rebasen op origin/main, en pushen.
# stijl: stil, korte meldingen, Windows-only, single quotes.

$ErrorActionPreference = 'Stop'

function Step($msg) { Write-Host ('[ok] ' + $msg) }

# 0) naar projectroot t.o.v. scripts-map
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $repoRoot
Step 'repo geladen'

# 1) basisconsole netjes (optioneel)
chcp 65001 | Out-Null

# 2) check git en branch
git --version | Out-Null
$current = (git rev-parse --abbrev-ref HEAD).Trim()
if ($current -ne 'main') { git switch main | Out-Null; Step 'geswitcht naar main' } else { Step 'op branch main' }

# 3) submodule 'user-site' schoonmaken
if (Test-Path '.\user-site\.git') {
    Set-Location '.\user-site'
    # harde reset en alles wat niet getrackt is verwijderen
    git reset --hard
    git clean -fdx
    Step 'user-site: reset + clean uitgevoerd'
    # terug naar root
    Set-Location $repoRoot
    # submodule refs syncen en werkboom exact op pointer zetten
    git submodule sync --recursive
    git submodule update --init --recursive
    Step 'submodules gesynchroniseerd'
} else {
    Step 'geen submodule user-site gevonden (skip)'
}

# 4) eigen script toevoegen aan commit (zodat dit bestand publiek online komt)
$scriptFull = (Get-Item $MyInvocation.MyCommand.Path).FullName
$rel = $scriptFull
if ($scriptFull.ToLower().StartsWith($repoRoot.ToLower())) {
    $rel = $scriptFull.Substring($repoRoot.Length).TrimStart('\','/')
}
git add -- $rel

# 5) korte commit als er staged changes zijn
$staged = git diff --cached --name-only
if ($staged) {
    git commit -m 'chore(git): submodule purge helper; move in stilte'
    Step 'commit gemaakt'
} else {
    Step 'niets te committen'
}

# 6) laatste remote ophalen en rebase (stil, veilig)
git fetch origin
git pull --rebase origin main
Step 'gerebased op origin/main'

# 7) push naar GitHub (publiek)
git push origin main
Step 'push voltooid'

# 8) controle: toon compacte status
git status -s

Write-Host 'stilte: schoon, gesynct, online.'
