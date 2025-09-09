$domain = 'the101game.io'

Write-Host '== http redirect check =='
try {
  $r = Invoke-WebRequest -Uri ('http://'+$domain+'/') -Method Head -MaximumRedirection 0 -TimeoutSec 10 -UseBasicParsing
} catch {
  $r = $_.Exception.Response
}
if ($r) {
  '{0} -> {1} {2}' -f $r.ResponseUri, [int]$r.StatusCode, $r.StatusDescription
  if ($r.Headers.Location) { '  location: {0}' -f $r.Headers.Location }
}

Write-Host "`n== https sanity =="
$i = Invoke-WebRequest -Uri ('https://'+$domain+'/') -Method Head -TimeoutSec 10 -UseBasicParsing
'{0} -> {1} {2}' -f $i.ResponseUri, [int]$i.StatusCode, $i.StatusDescription

Write-Host "`n== endpoints =="
$urls = @(
  'https://the101game.io/app/',
  'https://the101game.io/101/healthz',
  'https://the101game.io/postmark/inbound'
)
foreach ($u in $urls) {
  try {
    $h = Invoke-WebRequest -Uri $u -Method Head -TimeoutSec 10 -UseBasicParsing
    '{0,-35} -> {1} {2}' -f $u, [int]$h.StatusCode, $h.StatusDescription
  } catch {
    '{0,-35} -> error: {1}' -f $u, $_.Exception.Message
  }
}
Write-Host "`n== klaar =="; Read-Host 'enter om te sluiten'
