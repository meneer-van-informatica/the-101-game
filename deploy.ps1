# Definieer server- en bestandspaden
$serverIP = "82.165.231.86"
$serverUser = "root"
$localFileEn = "E:\the-101-game\web\en\index-en.html"
$localFileNl = "E:\the-101-game\web\nl\index-nl.html"
$remotePath = "/root/the-101-game/web"

# Stap 1: Ga naar de projectmap
cd E:\the-101-game

# Stap 2: Voeg bestanden toe aan Git
git add .

# Stap 3: Commit de wijzigingen met tijdstempel
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
git commit -m "Deploy update: $timestamp"

# Stap 4: Push naar de remote repository (GitHub)
git push origin main

# Stap 5: Gebruik SCP om bestanden naar de server te sturen
scp "E:\the-101-game\web\en\index-en.html" "root@82.165.231.86:/root/the-101-game/web/en/index-en.html"
scp "E:\the-101-game\web\nl\index-nl.html" "root@82.165.231.86:/root/the-101-game/web/nl/index-nl.html"

# Stap 6: Verifieer of de bestanden correct zijn gekopieerd
ssh root@82.165.231.86 "ls /root/the-101-game/web/en"
ssh root@82.165.231.86 "ls /root/the-101-game/web/nl"

Write-Host "Deploy completed successfully."
