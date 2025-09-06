function ToggleBlink {
  param([int]$Count=6,[int]$Ms=300)
  for($i=0;$i -lt $Count;$i++){
    lamp-on
    bleep
    Start-Sleep -Milliseconds $Ms
    lamp-off
    bloop
    Start-Sleep -Milliseconds $Ms
  }
}
Set-Alias Toggle-Blink ToggleBlink -Force
