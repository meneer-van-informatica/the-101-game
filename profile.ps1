$root='E:\the-101-game'
$exe="$root\.venv\Scripts"

function Invoke-SoftClear{Clear-Host;Write-Host '[ok] softclear'}

Set-PSReadLineKeyHandler -Key Enter -ScriptBlock {
  $l=$null;$c=$null
  [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$l,[ref]$c)
  [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0,$l.Length,'Invoke-SoftClear; '+$l)
  [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}

function export{(Get-History|Format-List|Out-String)|Set-Clipboard;Write-Host '[ok] export → clipboard'}

function bleep{
  if(Test-Path '.\bleep'){& .\bleep}
  elseif(Test-Path "$exe\bleep.exe"){& "$exe\bleep.exe"}
  else{[console]::beep(1000,200);Write-Host '[ok] bleep (alert) klaar.'}
}

function blink{1..5|ForEach-Object{.\blink}}

function bloop{bleep;blink;bleep;blink}