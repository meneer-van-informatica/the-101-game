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

function film {
  $root='E:\the-101-game'
  Start-Process 'powershell.exe' -ArgumentList @('-NoProfile','-NoLogo','-ExecutionPolicy','Bypass','-Command',"& '.\blink'") -WorkingDirectory $root
  Start-Process 'powershell.exe' -ArgumentList @('-NoProfile','-NoLogo','-ExecutionPolicy','Bypass','-Command',"& '.\bleep'") -WorkingDirectory $root
}

function blink_shell {
  $root='E:\the-101-game'
  $venv=Join-Path $root '.venv\Scripts'
  $tmp=Join-Path $env:TEMP 'blink_hue_elev.ps1'
  $lines=@()
  $lines+="Set-Location '$root'"
  if($env:HUE_BRIDGE){$lines+="$([char]36)env:HUE_BRIDGE='$($env:HUE_BRIDGE)'"}
  if($env:HUE_TOKEN){$lines+="$([char]36)env:HUE_TOKEN='$($env:HUE_TOKEN)'"}
  if($env:HUE_LIGHTS){$lines+="$([char]36)env:HUE_LIGHTS='$($env:HUE_LIGHTS)'"}
  $lines+='for($i=0;$i -lt 6;$i++){'
  $lines+="  & '$venv\lamp-on.exe'"
  $lines+="  & '$venv\bleep.exe'"
  $lines+='  Start-Sleep -Milliseconds 250'
  $lines+="  & '$venv\lamp-off.exe'"
  $lines+="  & '$venv\bloop.exe'"
  $lines+='  Start-Sleep -Milliseconds 250'
  $lines+='}'
  $lines+="Read-Host 'press Enter to close'"
  Set-Content -Path $tmp -Value $lines -Encoding UTF8
  Start-Process 'powershell.exe' -Verb RunAs -ArgumentList @('-NoProfile','-NoExit','-ExecutionPolicy','Bypass','-File',$tmp) -WorkingDirectory $root
}

function p { notepad 'E:\the-101-game\profile.ps1' }

function f {
  $root='E:\the-101-game'
  $blink=Join-Path $root 'blink'
  if(-not(Test-Path $blink)){$blink=Join-Path $root '.venv\Scripts\blink.exe'}
  $bleep=Join-Path $root 'bleep'
  if(-not(Test-Path $bleep)){$bleep=Join-Path $root '.venv\Scripts\bleep.exe'}
  Start-Process 'powershell.exe' -WorkingDirectory $root -WindowStyle Minimized -ArgumentList @('-NoProfile','-NoLogo','-ExecutionPolicy','Bypass','-Command',"& '$blink'")
  Start-Process 'powershell.exe' -WorkingDirectory $root -WindowStyle Minimized -ArgumentList @('-NoProfile','-NoLogo','-ExecutionPolicy','Bypass','-Command',"& '$bleep'")
}
