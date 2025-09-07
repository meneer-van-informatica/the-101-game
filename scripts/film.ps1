# repo-beginscherm: rood met 'Hallo Mama ❤️'
function softclean { Clear-Host }
softclean

$raw = $host.UI.RawUI
$origFg = $raw.ForegroundColor
$origBg = $raw.BackgroundColor
$raw.BackgroundColor = 'Red'
$raw.ForegroundColor = 'White'
Clear-Host

$w = $raw.WindowSize.Width
$h = $raw.WindowSize.Height
$msg1 = 'Hallo Mama ❤️'
$msg2 = 'the-101-game start'
$pad1 = [int][Math]::Max(0, ($w - $msg1.Length) / 2)
$pad2 = [int][Math]::Max(0, ($w - $msg2.Length) / 2)
for ($i = 0; $i -lt [int]($h/2 - 1); $i++) { Write-Host '' }
Write-Host (' ' * $pad1 + $msg1)
Write-Host (' ' * $pad2 + $msg2)
Read-Host 'Enter voor doorgaan'

$raw.BackgroundColor = $origBg
$raw.ForegroundColor = $origFg
Clear-Host
