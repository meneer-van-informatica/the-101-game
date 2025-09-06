$root='E:\the-101-game'
$exe="$root\.venv\Scripts"

function Invoke-SoftClear{Clear-Host;Write-Host '[ok] softclear'}
Set-Alias cls Invoke-SoftClear -Force

function bleep{
  Invoke-SoftClear
  if(Test-Path .\bleep){& .\bleep}
  elseif(Test-Path "$exe\bleep.exe"){& "$exe\bleep.exe"}
  else{[console]::beep(1000,200);Write-Host '[ok] bleep (alert) klaar.'}
}

function blink{
  Invoke-SoftClear
  1..5 | ForEach-Object { .\blink }
}

function bloop{
  Invoke-SoftClear
  bleep
  blink
  bleep
  blink
}
