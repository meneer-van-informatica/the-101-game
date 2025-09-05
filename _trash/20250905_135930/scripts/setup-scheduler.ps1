$ErrorActionPreference = 'Stop'
$root     = Split-Path -Path $PSScriptRoot -Parent
$taskName = 'the-101-game_sanity'

$ps     = (Get-Command 'powershell').Source
$script = Join-Path $root 'scripts\sanity.ps1'

# Actie met expliciete werkmap (belangrijk!)
$action = New-ScheduledTaskAction -Execute $ps `
          -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$script`"" `
          -WorkingDirectory $root

# Triggers: dagelijks 09:00 + elk uur 10–18
$triggerDaily  = New-ScheduledTaskTrigger -Daily -At 09:00
$triggerHourly = New-ScheduledTaskTrigger -Once -At (Get-Date -Hour 10 -Minute 0 -Second 0)
$triggerHourly.Repetition.Interval = (New-TimeSpan -Hours 1)
$triggerHourly.Repetition.Duration = (New-TimeSpan -Hours 8)

# Principal
$user = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$principal = New-ScheduledTaskPrincipal -UserId $user -LogonType Interactive

# (Her)registreren
try { Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue } catch {}
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $triggerDaily,$triggerHourly -Principal $principal

Write-Host "OK: taak '$taskName' geregistreerd. Start nu met:"
Write-Host "Start-ScheduledTask -TaskName '$taskName'"
