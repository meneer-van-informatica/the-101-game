param([string]$Output = 'the-101-game.7z')
Set-Location -Path $PSScriptRoot
if (Get-Command 7z -ErrorAction SilentlyContinue) {
  7z a -t7z -m0=lzma2 -mx=9 -aoa $Output * -r
} else {
  Write-Warning '7-Zip niet gevonden; installeer met: winget install --id 7zip.7zip -e'
}
