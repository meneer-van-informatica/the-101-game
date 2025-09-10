# Server- en bestandspaden
$serverIP = "82.165.231.86"
$serverUser = "root"
$localFileEn = "E:\the-101-game\web\en\index-en.html"
$localFileNl = "E:\the-101-game\web\nl\index-nl.html"
$remotePath = "/root/the-101-game/web"
$gitBranch = "main"
$projectPath = "E:\the-101-game"
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$commitMessage = "Deploy update: $timestamp"

# SSH en SCP opties
$sshOptions = "-o StrictHostKeyChecking=no"
$scpOptions = "-o StrictHostKeyChecking=no"

# Functie om commando's uit te voeren
function Execute-Command {
    param (
        [string]$command,
        [string]$errorMessage
    )
    & $command
    if ($LASTEXITCODE -ne 0) {
        Write-Error $errorMessage
        exit 1
    }
}

# Stap 1: Ga naar de projectmap
cd $projectPath
Execute-Command "cd $projectPath" "Fout bij het navigeren naar de projectmap: $projectPath"

# Stap 2: Voeg bestanden toe aan Git
Execute-Command "git add ." "Fout bij het toevoegen van bestanden aan Git."

# Stap 3: Commit de wijzigingen met tijdstempel
Execute-Command "git commit -m '$commitMessage'" "Fout bij het committen van wijzigingen."

# Stap 4: Push naar de remote repository (GitHub)
Execute-Command "git push origin $gitBranch" "Fout bij het pushen naar de remote repository."

# Stap 5: Gebruik SCP om bestanden naar de server te sturen
Execute-Command "scp $scpOptions '$localFileEn' '$serverUser@$serverIP:${remotePath}/en/index-en.html'" "Fout bij het kopiëren van het Engelse bestand naar de server."
Execute-Command "scp $scpOptions '$localFileNl' '$serverUser@$serverIP:${remotePath}/nl/index-nl.html'" "Fout bij het kopiëren van het Nederlandse bestand naar de server."

# Stap 6: Verifieer of de bestanden correct zijn gekopieerd
Execute-Command "ssh $sshOptions $serverUser@$serverIP 'ls ${remotePath}/en'" "Fout bij het verifiëren van het Engelse bestand."
Execute-Command "ssh $sshOptions $serverUser@$serverIP 'ls ${remotePath}/nl'" "Fout bij het verifiëren van het Nederlandse bestand."

# Stap 7: Herstart Nginx op de server
Execute-Command "ssh $sshOptions $serverUser@$serverIP 'sudo systemctl restart nginx'" "Fout bij het herstarten van Nginx."

Write-Host "Deploy en Nginx herstart voltooid."
