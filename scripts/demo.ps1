Param(
  [int]$Bpm = 90,          # tempo
  [int]$FadeMs = 300,
  [switch]$Transcript
)

if ($Transcript) { if (Get-Command export-on -ea 0) { export-on } }

function CallIf($n,$args){ if (Get-Command $n -ea 0) { & $n @args } }
function KeyPressed([ref]$k){
  if ([Console]::KeyAvailable) {
    $kk = [Console]::ReadKey($true)
    $k.Value = $kk
    return $true
  }
  return $false
}

$beatMs = [int](60000 / [Math]::Max(1,$Bpm))
$colors = @("red","green","blue","orange")
$notes  = @("bleep","bloop","tik","tok")

CallIf "on" @()

Write-Host "🎬 Demo loopt (BPM=$Bpm). Druk Q of Esc om te stoppen."
while ($true) {
  # stop check
  $key = $null
  if (KeyPressed([ref]$key)) {
    if ($key.Key -eq "Escape" -or ($key.KeyChar -as [int]) -eq 113) { break } # 113 = 'q'
  }

  # kleur + note
  $c = Get-Random $colors
  $n = Get-Random $notes
  CallIf $c @()
  Start-Sleep -Milliseconds $FadeMs
  CallIf $n @()
  Start-Sleep -Milliseconds $beatMs
}

CallIf "off" @()
if ($Transcript) { if (Get-Command export-off -ea 0) { export-off } }
Write-Host "🛑 Demo gestopt."
