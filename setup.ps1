# 15 kukels

$ErrorActionPreference = 'Stop'

# 1. Verwijder ongewenste bestanden en mappen
$foldersToRemove = @(
    '_trash', 'node_modules', 'dist', 'temp', 'logs', 'typing', 'scenes', 'frames', 'w0l1', 'w1l1', 'js', 'css', 'the-101-game.tmp', '__pycache__'
)
foreach ($folder in $foldersToRemove) {
    $path = Join-Path -Path $PWD -ChildPath $folder
    if (Test-Path -Path $path) {
        Remove-Item -Path $path -Recurse -Force
        Write-Host "Verwijderd: $folder" -ForegroundColor Green
    }
}

# 2. Maak mappen aan voor de landingspagina's
$landingPages = @(
    @{ Path = 'web/en'; File = 'index-en.html'; Language = 'English' },
    @{ Path = 'web/nl'; File = 'index-nl.html'; Language = 'Nederlands' }
)
foreach ($page in $landingPages) {
    $dirPath = Join-Path -Path $PWD -ChildPath $page.Path
    if (-not (Test-Path -Path $dirPath)) {
        New-Item -ItemType Directory -Path $dirPath -Force
        Write-Host "Gemaakt: $dirPath" -ForegroundColor Green
    }

    $filePath = Join-Path -Path $dirPath -ChildPath $page.File
    $htmlContent = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>The 101 Game - $($page.Language)</title>
    <link rel="stylesheet" href="/css/styles.css">
</head>
<body>
    <header>
        <h1>The 101 Game</h1>
        <p>Welcome to the $($page.Language) version of The 101 Game.</p>
        <button id="languageSelect" class="btn" onclick="toggleLanguage()">Nederlands</button>
    </header>
    <main>
        <section>
            <h2>About</h2>
            <p>Experience the thrill of The 101 Game in your preferred language.</p>
        </section>
    </main>
    <footer>
        <p>&copy; 2025 The 101 Game</p>
    </footer>
    <script>
        function toggleLanguage() {
            const currentUrl = window.location.href;
            if (currentUrl.includes('the101game.io')) {
                window.location.href = currentUrl.replace('the101game.io', 'the101game.nl');
            } else {
                window.location.href = currentUrl.replace('the101game.nl', 'the101game.io');
            }
        }
    </script>
</body>
</html>
"@
    Set-Content -Path $filePath -Value $htmlContent
    Write-Host "Bestand geschreven: $filePath" -ForegroundColor Green
}

# 3. Voeg wijzigingen toe aan Git
git add -A
git commit -m "v2: Added landing pages for English and Dutch domains"
git tag -a "v2" -m "Version 2: Added landing pages for English and Dutch domains"

# 4. Push wijzigingen naar de remote repository
git push origin main
git push origin --tags

Write-Host "Opruimen en versiebeheer voltooid. Landingspagina's zijn toegevoegd en versie 2 is gepusht." -ForegroundColor Green
