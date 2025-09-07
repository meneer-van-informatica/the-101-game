# repo-beginscherm: rood + 'Hallo Mama ❤️'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
$raw = $Host.UI.RawUI
$w = $raw.WindowSize.Width
$h = $raw.WindowSize.Height
$msg1 = 'Hallo Mama ❤️'
$msg2 = 'the-101-game start'
$pad1 = [int][Math]::Max(0, ($w - $msg1.Length) / 2)
$pad2 = [int][Math]::Max(0, ($w - $msg2.Length) / 2)
$esc = [char]27

try {
  Write-Host "$esc[41m$esc[37m" -NoNewline
  for ($i=0; $i -lt $h; $i++) { Write-Host (' ' * $w) }
  $mid = [int]($h/2) - 1
  $raw.CursorPosition = New-Object System.Management.Automation.Host.Coordinates 0 0
  for ($i=0; $i -lt $mid; $i++) { Write-Host '' }
  Write-Host (' ' * $pad1 + $msg1)
  Write-Host (' ' * $pad2 + $msg2)
  Read-Host 'Enter voor doorgaan'
  Write-Host "$esc[0m"
  Clear-Host
} catch {
  $origFg=$raw.ForegroundColor; $origBg=$raw.BackgroundColor
  $raw.BackgroundColor='Red'; $raw.ForegroundColor='White'; Clear-Host
  for ($i=0; $i -lt [int]($h/2 - 1); $i++) { Write-Host '' }
  Write-Host (' ' * $pad1 + $msg1)
  Write-Host (' ' * $pad2 + $msg2)
  Read-Host 'Enter voor doorgaan'
  $raw.BackgroundColor=$origBg; $raw.ForegroundColor=$origFg
  Clear-Host
}
