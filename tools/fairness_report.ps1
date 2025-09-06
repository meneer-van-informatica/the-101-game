param(
  [Parameter(Mandatory=$true)][string]$Csv,   # bv: E:\the-101-game\data\results.csv
  [string]$Out = 'E:\the-101-game\reports\fairness_report.md'
)
$ErrorActionPreference = 'Stop'
Import-Module Microsoft.PowerShell.Utility | Out-Null
New-Item -ItemType Directory -Path (Split-Path $Out -Parent) -Force | Out-Null
$data = Import-Csv $Csv
if(-not ($data | Get-Member -Name 'race' -MemberType NoteProperty)){ throw 'kolom race ontbreekt; gebruik codes zoals black, white, mixed, other, unknown, prefer_not' }
$groups = $data | Group-Object race
$lines = @()
$lines += '# Fairness Report'
$lines += ''
$lines += '*purpose* bias_audit'
$lines += ''
$lines += '| group | n | wpm_avg | wpm_sd | err_avg |'
$lines += '|-------|---:|-------:|------:|-------:|'
foreach($g in $groups){
  $n = $g.Count
  $wpm = ($g.Group | Measure-Object -Property wpm -Average -StandardDeviation)
  $err = ($g.Group | Measure-Object -Property errors_pct -Average)
  $lines += '| {0} | {1} | {2:n2} | {3:n2} | {4:n2} |' -f $g.Name, $n, $wpm.Average, $wpm.StandardDeviation, $err.Average
}
$lines += ''
$lines += '> labels dienen mensen, niet andersom'
Set-Content -Path $Out -Value $lines -Encoding UTF8
Write-Host 'OK:' $Out
