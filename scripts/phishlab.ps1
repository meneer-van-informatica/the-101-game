# ========== Helpers ==========
function Show-QRJson {
  param([Parameter(Mandatory)][string]$Json)
  try {
    $obj = $Json | ConvertFrom-Json
    Write-Host "QRProcessType : $($obj.QRProcessType)" -ForegroundColor Cyan
    $det = $obj.QRProcessDetails
    if ($det) {
      Write-Host "challenge     : $($det.challenge)"
      Write-Host "handle        : $($det.challengeHandle)"
    }
    Write-Host "(Let op: dit is tijdelijk en hoort bij je browsersessie.)" -ForegroundColor DarkGray
  } catch {
    Write-Host "Geen geldige JSON." -ForegroundColor Yellow
  }
}

function Get-TlsInfo {
  param([Parameter(Mandatory)][string]$HostName, [int]$Port = 443)
  $tcp = New-Object Net.Sockets.TcpClient
  $tcp.Connect($HostName, $Port)
  $ssl = New-Object Net.Security.SslStream($tcp.GetStream(), $false, ({ $true }))
  $ssl.AuthenticateAsClient($HostName)
  $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 $ssl.RemoteCertificate
  [pscustomobject]@{
    Subject = $cert.Subject
    Issuer  = $cert.Issuer
    NotBefore = $cert.NotBefore
    NotAfter  = $cert.NotAfter
    SANs   = ($cert.Extensions | Where-Object { $_.Oid.FriendlyName -eq 'Subject Alternative Name' } | ForEach-Object { $_.Format($false) })
    Protocol = $ssl.SslProtocol
    Cipher   = $ssl.NegotiatedCipherSuite
  }
}

function Test-PhishUrl {
  param([Parameter(Mandatory)][string]$Url)

  # Parse en normaliseer host (punycode)
  $u = [Uri]$Url
  $host = $u.Host
  $idn = New-Object System.Globalization.IdnMapping
  $asciiHost = $idn.GetAscii($host)

  # simpele domeincheck: exact eindigend op abnamro.nl of subdomein daarvan
  $isAbn = $asciiHost -match '(^|\.)abnamro\.nl$'

  # HEAD-request voor headers (zonder content)
  try {
    $resp = Invoke-WebRequest -Uri $Url -Method Head -UseBasicParsing -TimeoutSec 10
    $hdr = $resp.Headers
  } catch {
    $hdr = @{}
  }

  # TLS-info
  try { $tls = Get-TlsInfo -HostName $asciiHost } catch { $tls = $null }

  # Scores (heel simpel; didactisch)
  $score = 0
  if ($isAbn) { $score += 2 } else { $score -= 1 }
  if ($hdr.'Strict-Transport-Security') { $score += 1 }
  if ($hdr.'Content-Security-Policy')   { $score += 1 }
  if ($hdr.'X-Content-Type-Options' -eq 'nosniff') { $score += 1 }

  [pscustomobject]@{
    Url        = $Url
    Host       = $asciiHost
    LooksLikeAbnDomain = $isAbn
    StatusCode = ($resp.StatusCode     | Out-String).Trim()
    Server     = ($hdr.Server          | Out-String).Trim()
    HSTS       = ($hdr.'Strict-Transport-Security' | Out-String).Trim()
    CSP        = ($hdr.'Content-Security-Policy'   | Out-String).Trim()
    XCTO       = ($hdr.'X-Content-Type-Options'    | Out-String).Trim()
    TLS        = $tls
    ScoreHint  = $score
  }
}

# Optioneel: HUE integratie (groen bij 'vertrouwd', rood bij 'sus')
function Invoke-HueColor {
  param([ValidateSet('Red','Green')][string]$Color = 'Green')
  $s = Join-Path (Get-Location) 'scripts\hue.ps1'
  if (-not (Test-Path $s)) { return }
  if ($Color -eq 'Green') { powershell -File $s -Green } else { powershell -File $s -Red }
}

# ========== Demo-workflow ==========
function phishlab {
  param([Parameter(Mandatory)][string]$Url,
        [string]$QrJson = $null)

  Write-Host "Analyseren: $Url" -ForegroundColor Cyan
  $r = Test-PhishUrl -Url $Url
  $r

  if ($QrJson) {
    Write-Host "`nQR JSON:" -ForegroundColor Cyan
    Show-QRJson -Json $QrJson
  }

  # Hue: simpel drempeltje
  if ($r.LooksLikeAbnDomain -and $r.HSTS -and $r.CSP) {
    Invoke-HueColor -Color Green
    Write-Host "Hue → GROEN (basisheaders OK, domein lijkt echt)" -ForegroundColor Green
  } else {
    Invoke-HueColor -Color Red
    Write-Host "Hue → ROOD (verdacht of onvoldoende beveiligingsheaders)" -ForegroundColor Red
  }
}
