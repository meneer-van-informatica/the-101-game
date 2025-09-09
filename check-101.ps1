Write-Host '== https sanity =='
try {
  $r = Invoke-WebRequest -UseBasicParsing -Method Head -Uri 'https://the101game.io/'
  "-> {0} {1}`n" -f [int]$r.StatusCode, $r.StatusDescription
} catch { "-> error: $($_.Exception.Message)`n" }

Write-Host '== endpoints =='
# app
'https://the101game.io/app/' | %{
  try { $r = Invoke-WebRequest -UseBasicParsing -Method Head -Uri $_
        '{0,-32} -> {1} {2}' -f $_, [int]$r.StatusCode, $r.StatusDescription
  } catch { '{0,-32} -> error: {1}' -f $_, $_.Exception.Message }
}

# healthz (verwacht 200)
'https://the101game.io/healthz','https://the101game.io/101/healthz' | %{
  try { $r = Invoke-WebRequest -UseBasicParsing -Method Head -Uri $_
        '{0,-32} -> {1} {2}' -f $_, [int]$r.StatusCode, $r.StatusDescription
  } catch { '{0,-32} -> error: {1}' -f $_, $_.Exception.Message }
}

# inbound (GET=405 is OK; endpoint is POST-only)
'https://the101game.io/postmark/inbound' | %{
  try {
    $r = Invoke-WebRequest -UseBasicParsing -Method Head -Uri $_
    '{0,-32} -> {1} {2}' -f $_, [int]$r.StatusCode, $r.StatusDescription
  } catch {
    $resp = $_.Exception.Response
    if ($resp -and $resp.StatusCode.value__ -eq 405) {
      '{0,-32} -> 405 Method Not Allowed (OK: POST-only)' -f $_
    } else {
      '{0,-32} -> error: {1}' -f $_, $_.Exception.Message
    }
  }
}

Write-Host "`n== klaar =="
Read-Host 'enter om te sluiten'
