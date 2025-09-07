# auto-commit & push op elke wijziging van README.md
$repo = (git rev-parse --show-toplevel).Trim()
Set-Location $repo
git config --global --add safe.directory $repo | Out-Null

$fsw = New-Object IO.FileSystemWatcher -Property @{
  Path = $repo; Filter = 'README.md'; IncludeSubdirectories = $false; EnableRaisingEvents = $true
}

$last = Get-Date 0
$action = {
  $now = Get-Date
  if (($now - $script:last).TotalSeconds -lt 1) { return } # debounce
  $script:last = $now
  & git add -- README.md
  & git commit -m "docs: README autosave ($($now.ToString('yyyy-MM-dd HH:mm:ss')))" 2>$null
  if ($LASTEXITCODE -eq 0) { & git push }
}

Register-ObjectEvent $fsw Changed -Action $action | Out-Null
Register-ObjectEvent $fsw Created -Action $action | Out-Null
Register-ObjectEvent $fsw Renamed -Action $action | Out-Null

Write-Host 'watcher actief. Ctrl+C om te stoppen.' -ForegroundColor Green
while ($true) { Start-Sleep -Seconds 1 }
