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
$text = [regex]::Replace($text, '\[(?:music|applause|laughter|inaudible|muziek|applaus)[^\]]*\]', '', 'IgnoreCase')
$text = [regex]::Replace($text, '\([^)]*\)', '')

# 1) Strenge split: eindigt op . ! ? … en begint met hoofdletter/cijfer/quote
$split = '(?<=\.|\!|\?|\u2026)\s+(?=\p{Lu}|\d|''|“|")'
$sent  = [regex]::Split($text, $split) | ForEach-Object { $_.Trim() } | Where-Object {
  $_ -match '^\p{Lu}' -and $_ -match '[\.\!\?…]$' -and $_.Length -ge 40 -and $_.Length -le 220
} | Where-Object { $_ -notmatch '\[[^\]]+\]' -and $_ -notmatch '_{2,}' }

# 2) Soft split fallback: sta geen hoofdletter-eis toe en accepteer ; :
if (-not $sent -or $sent.Count -lt 1) {
  $soft = [regex]::Split($text, '(?<=[\.\!\?…;:])\s+') | ForEach-Object { $_.Trim() } | Where-Object {
    $_.Length -ge 30 -and $_.Length -le 240
  }
  if ($soft) { $sent = $soft }
}

# 3) Word-chunker fallback: bouw “zinnen” van 14–22 woorden met eindpunt
if (-not $sent -or $sent.Count -lt 1) {
  $tokens = ($text -replace '[^\p{L}\p{N}\-''’.,;:?!… ]', ' ') -split '\s+' | Where-Object { $_ -ne '' }
  $chunk = @()
  $buf = New-Object System.Collections.Generic.List[string]
  $minWords = 14; $maxWords = 22
  foreach ($t in $tokens) {
    $buf.Add($t)
    if ($buf.Count -ge $maxWords -or ($buf.Count -ge $minWords -and $t -match '[\.\!\?…]$')) {
      $s = ($buf -join ' ').Trim()
      if ($s -notmatch '[\.\!\?…]$') { $s += '.' }
      if ($s.Length -ge 40 -and $s.Length -le 240) { $chunk += $s }
      $buf.Clear()
    }
  }
  if ($buf.Count -gt 0) {
    $s = ($buf -join ' ').Trim()
    if ($s.Length -ge 40) {
      if ($s -notmatch '[\.\!\?…]$') { $s += '.' }
      $chunk += $s
    }
  }
  if ($chunk) { $sent = $chunk }
}

# 4) NL-heuristiek om EN weg te duwen (simpel stopwoorden-filter)
function Test-IsDutch([string]$s) {
  $nl = @('de','het','een','en','ik','jij','je','u','hij','zij','wij','jullie','mijn','jouw','zijn','haar','ons','onze',
          'niet','wel','maar','toch','omdat','als','dan','ook','nog','nooit','altijd','weer','voor','achter','tussen',
          'met','zonder','naar','bij','over','onder','tegen','gaat','heb','hebt','heeft','hebben','ben','bent','is','zijn',
          'was','waren','word','wordt','worden','doe','doet','doen','kan','kun','kunnen','moet','moeten','wil','wilt',
          'willen','dit','dat','die','daar','hier','er','waarom','want','dus','eens','gewoon','zoals')
  $en = @('the','and','is','are','to','for','with','of','in','on','this','that','you','your','i','my','we','they','he',
          'she','it','not','do','does','was','were','have','has','had','will','would','should','could','from','at','as','be')
  $words = ($s.ToLower() -replace '[^\p{L}\p{N}\-''’ ]',' ') -split '\s+' | Where-Object { $_ -ne '' }
  if (-not $words) { return $false }
  $nlScore = ($words | Where-Object { $nl -contains $_ }).Count
  # lichte bonus voor NL look
  if ($s -match '(ij|sch|cht|ouw|eau)') { $nlScore += 1 }
  $enScore = ($words | Where-Object { $en -contains $_ }).Count
  $bonus = ([int](($s -match '(ij|sch|cht|ouw|eau)')))
  return ($nlScore + $bonus) -ge ([Math]::Max(1, $enScore))
}
$sentNL = @(); foreach ($s in $sent) { if (Test-IsDutch $s) { $sentNL += $s } }
if ($sentNL.Count -ge 1) { $sent = $sentNL }

if (-not $sent -or $sent.Count -lt 1) { Write-Error 'geen bruikbare zinnen'; exit 1 }

# Random pick (SeedInt al berekend eerder)
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


