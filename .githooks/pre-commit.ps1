$patterns = @('\b(\+31|0031)\s?6[-\s]?\d{8}\b','\b0?6[-\s]?\d{8}\b')
$hits = Get-ChildItem -Recurse -File |
  Where-Object { -not $_.FullName.Contains('\.git\') } |
  Select-String -Pattern $patterns -AllMatches -SimpleMatch:$false
if ($hits) {
  Write-Host 'commit blocked: phone-like number found'
  $hits | ForEach-Object { Write-Host ('  ' + $_.Path + ':' + $_.LineNumber + ' -> ' + $_.Line.Trim()) }
  exit 1
}
