# scripts\submodule_discard_and_push.ps1
# doel: submodule 'user-site' schoonmaken, eigen script toevoegen, rebase op origin/main, en pushen
# stil en veilig; alleen korte meldingen

$ErrorActionPreference = 'Stop'

function Write-Step($t) { Write-Host ('[ok] ' + $t) }

# 1) naar projectroot vanuit scripts-map
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $repoRoot
Write-Step 'repo geladen'

# 2) controleer git beschikbaar
git --version | Out-Null

# 3) check branch en schakel naar main indien nodig
$current = (git rev-parse --abbrev-ref HEAD).Trim()
if ($current -ne 'main') {
    git switch main | Out-Null
    Write-Step 'geswitcht naar branch main'
} else {
    Write-Step 'op branch main'
}

# 4) submodule 'user-site' opruimen indien aanwezig
if (Test-Path '.\user-site\.git') {
    Set-Location '.\user-site'
    git reset --hard
    git clean -fdx
    Set-Location $repoRoot
    Write-Step 'submodule user-site opgeschoond'
    # zorg dat submodules overeenkomen met de pointers
    git submodule update --init --recursive
    Write-Step 'submodules gesynchroniseerd'
} else {
    Write-Step 'geen submodule user-site gevonden (skip)'
}

# 5) eigen script toevoegen aan commit
$scriptFull = (Get-Item $MyInvocation.MyCommand.Path).FullName
# bepaal relatief pad t.o.v. repoRoot
$rel = $scriptFull
if ($scriptFull.ToLower().StartsWith($repoRoot.ToLower())) {
    $rel = $scriptFull.Substring($repoRoot.Length).TrimStart('\','/')
}
git add -- $rel

# 6) eventuele andere nieuwe bestanden die vandaag zijn gemaakt kun je optioneel toevoegen
# laat stil; wijzig naar wens: git add scenes\d_minor.py scripts\play_d_minor.ps1

# 7) commit met korte boodschap als er staged changes zijn
$staged = git diff --cached --name-only
if ($staged) {
    git commit -m 'chore(scripts): submodule cleanup helper + push'
    Write-Step 'commit gemaakt'
} else {
    Write-Step 'niets te committen'
}

# 8) haal remote binnen en rebase
git fetch origin
git pull --rebase origin main
Write-Step 'gerebased op origin/main'

# 9) push naar GitHub
git push origin main
Write-Step 'push voltooid'

# 10) klaar
Write-Host 'stilte bewaken: bestanden staan online.'
