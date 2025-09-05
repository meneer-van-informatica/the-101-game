param(
  [Parameter(Mandatory=$true)][string]$Url,
  [string]$Langs = 'nl,en',
  [string]$Seed = '0',           # <- string, we parsen zelf veilig
  [string]$OutDir = "$env:USERPROFILE\Documents\ytq",
  [switch]$Polish
)

# seed veilig parsen: alles wat niet int is → 0
[int]$SeedInt = 0
[void][int]::TryParse(($Seed -as [string]), [ref]$SeedInt)


function Get-YouTubeId([string]$u) {
  if ($u -match '^[A-Za-z0-9_-]{11}$') { return $u }
  if ($u -match 'v=([A-Za-z0-9_-]{11})') { return $Matches[1] }
  if ($u -match 'youtu\.be/([A-Za-z0-9_-]{11})') { return $Matches[1] }
  return $u
}

$Langs = $Langs.Trim("'",'"','`')
$vid   = Get-YouTubeId $Url
$date  = Get-Date -Format 'yyyyMMdd_HHmmss'
if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir | Out-Null }

# venv-tools zonder activatie
$venvPy  = Join-Path $PSScriptRoot ".venv\Scripts\python.exe"
$venvCli = Join-Path $PSScriptRoot ".venv\Scripts\youtube_transcript_api.exe"
$pyexe = "python"; if (Test-Path $venvPy)  { $pyexe = $venvPy }
$cli   = "youtube_transcript_api"; if (Test-Path $venvCli) { $cli = $venvCli }

# Transcript (API → CLI fallback)
$py = @'
from youtube_transcript_api import YouTubeTranscriptApi
api   = YouTubeTranscriptApi()
vid   = '{VID}'
langs = '{LANGS}'.split(',')
tx    = api.fetch(vid, languages=langs)
raw   = tx.to_raw_data()
print('\n'.join([t['text'] for t in raw]))
'@.Replace('{VID}',$vid).Replace('{LANGS}',$Langs)

$tmppy = Join-Path $env:TEMP ('yt_tr_' + [guid]::NewGuid().ToString() + '.py')
$txt   = Join-Path $env:TEMP ('yt_tr_' + [guid]::NewGuid().ToString() + '.txt')
$py    | Set-Content -Path $tmppy -Encoding utf8
try {
  & $pyexe $tmppy | Set-Content -Path $txt -Encoding utf8
  if ($LASTEXITCODE -ne 0 -or -not (Test-Path $txt) -or (Get-Item $txt).Length -eq 0) {
    & $cli $vid --languages $Langs | Set-Content -Path $txt -Encoding utf8
  }
} finally { Remove-Item $tmppy -ErrorAction SilentlyContinue }

if (-not (Test-Path $txt) -or (Get-Item $txt).Length -eq 0) { Write-Error 'geen transcript gevonden'; exit 1 }

# Clean → zinnen
$text = Get-Content $txt -Raw -Encoding utf8
$text = [regex]::Replace($text, '\s+', ' ').Trim()
$text = [regex]::Replace($text, '\[(?:music|applause|laughter|inaudible)[^\]]*\]', '', 'IgnoreCase')
$text = [regex]::Replace($text, '\([^)]*\)', '')

# Unicode-veilig split: ., !, ?, … (U+2026) → spatie + hoofdletter/cijfer/quote
$split = '(?<=\.|\!|\?|\u2026)\s+(?=\p{Lu}|\d|''|“|")'
$sent  = [regex]::Split($text, $split) | ForEach-Object { $_.Trim() } | Where-Object {
  $_ -match '^\p{Lu}' -and $_ -match '[\.\!\?…]$' -and $_.Length -ge 40 -and $_.Length -le 220
} | Where-Object { $_ -notmatch '\[[^\]]+\]' -and $_ -notmatch '_{2,}' }

if (-not $sent -or $sent.Count -lt 1) {
  $fallback = ($text -split '\. ') | ForEach-Object { ($_ -replace '\s+', ' ').Trim('.') } |
    Where-Object { $_.Length -ge 40 -and $_.Length -le 220 } |
    ForEach-Object { $_ + '.' }
  if ($fallback) { $sent = $fallback }
}
if (-not $sent) { Write-Error 'geen bruikbare zinnen'; exit 1 }

# Random pick (gebruik SeedInt)
if ($SeedInt -ne 0) { $rand = New-Object System.Random($SeedInt) } else { $rand = New-Object System.Random }
$pick  = $sent[$rand.Next(0,$sent.Count)]

# Optionele NL-polish (stil; werkt alleen als Java+LT aanwezig)
function Fix-NL([string]$s) {
  if (-not $Polish) { return $s }
  $javaOk = $false
  try {
    $j = Get-Command java -ErrorAction SilentlyContinue
    if ($j) { $javaOk = $true }
    if (-not $javaOk) {
      $cand = @(
        Get-ChildItem "$env:ProgramFiles\Eclipse Adoptium\*\bin\java.exe" -ErrorAction SilentlyContinue
        Get-ChildItem "$env:LOCALAPPDATA\Programs\Eclipse Adoptium\*\bin\java.exe" -ErrorAction SilentlyContinue
      ) | Select-Object -First 1
      if ($cand) { $env:PATH = "$env:PATH;$(Split-Path $cand.FullName)"; $javaOk = $true }
    }
  } catch { $javaOk = $false }
  if (-not $javaOk) { return $s }

  $pyfix = @'
import sys
text = sys.stdin.read().strip()
try:
    import language_tool_python
    tool = language_tool_python.LanguageTool('nl')
    from language_tool_python import utils
    print(utils.correct(text, tool.check(text)))
except Exception:
    print(text)
'@
  try {
    $tmp = Join-Path $env:TEMP ('lt_' + [guid]::NewGuid().ToString() + '.py')
    $pyfix | Set-Content -Path $tmp -Encoding utf8
    $fixed = $s | & $pyexe $tmp 2>$null
    Remove-Item $tmp -ErrorAction SilentlyContinue
    if ($fixed -and $fixed.Trim().Length -gt 0) { return $fixed.Trim() } else { return $s }
  } catch { return $s }
}

# Post-format
$quote = Fix-NL $pick
if ($quote.Length -ge 1) { $quote = $quote.Substring(0,1).ToUpper() + $quote.Substring(1) }
if ($quote -notmatch '[\.\!\?…]$') { $quote += '.' }

# Output – PS5.1-safe, zonder rare quotes
$mdPath = Join-Path $OutDir ("quote_" + $vid + "_" + $date + ".md")
if (Test-Path $mdPath) { Remove-Item $mdPath -ErrorAction SilentlyContinue }
Add-Content -Path $mdPath -Value "# Les 0  Esko 101 quote" -Encoding utf8
Add-Content -Path $mdPath -Value "" -Encoding utf8
Add-Content -Path $mdPath -Value ("Quote: `'$quote`'") -Encoding utf8
Add-Content -Path $mdPath -Value "" -Encoding utf8
Add-Content -Path $mdPath -Value "Waarom:" -Encoding utf8
Add-Content -Path $mdPath -Value "" -Encoding utf8
Add-Content -Path $mdPath -Value "Vraag voor de klas:" -Encoding utf8

Remove-Item $txt -ErrorAction SilentlyContinue

Write-Output ("`'$quote`'")
Write-Output ("md geschreven: " + $mdPath)

