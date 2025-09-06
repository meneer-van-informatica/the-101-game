$root='E:\the-101-game'
$exe="$root\.venv\Scripts"

Remove-Item alias:blink,alias:bleep,alias:bloop,function:blink,function:bleep,function:bloop,function:Invoke-SoftClear,alias:cls -ErrorAction SilentlyContinue

function Invoke-Chain{param([string]$name) if(Test-Path ".\$name"){& ".\$name" @args;return} if(Test-Path "$exe\$name.exe"){& "$exe\$name.exe" @args;return} Write-Host "[err] $name niet gevonden"}

function export{(Get-History|Format-List|Out-String)|Set-Clipboard;Write-Host '[ok] export → clipboard'}

function blink{1..5 | ForEach-Object { .\blink }}
function bleep{Invoke-Chain 'bleep'}
function bloop{Invoke-Chain 'bloop'}

function Invoke-SoftClear{Clear-Host;Write-Host '[ok] softclear'}
Set-Alias cls Invoke-SoftClear -Force
# let 'sc' met rust (AllScope in Windows PowerShell)
