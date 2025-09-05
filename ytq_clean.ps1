param(
    [Parameter(Mandatory=$true)][string]$Url,
    [string]$Langs = 'nl,en',
    [string]$OutPath,
    [switch]$Open,
    [int]$Seed = 0
)

function Get-YouTubeId([string]$u) {
    if ($u -match '^[A-Za-z0-9_-]{11}$') { return $u }
    if ($u -match 'v=([A-Za-z0-9_-]{11})') { return $Matches[1] }
    if ($u -match 'youtu\.be/([A-Za-z0-9_-]{11})') { return $Matches[1] }
    return $u
}

$Langs = $Langs.Trim("'",'"','`')
$vid   = Get-YouTubeId $Url
$date  = Get-Date -Format 'yyyyMMdd'
if (-not $OutPath -or $OutPath.Trim() -eq '') {
    $OutPath = Join-Path $env:USERPROFILE ("Documents\transcript_{0}_{1}.txt" -f $vid, $date)
}

# 1) transcript ophalen (API met CLI-fallback)
$pycode = @'
from youtube_transcript_api import YouTubeTranscriptApi
api   = YouTubeTranscriptApi()
vid   = '{VID}'
langs = '{LANGS}'.split(',')
tx    = api.fetch(vid, languages=langs)
raw   = tx.to_raw_data()
print('\n'.join([t['text'] for t in raw]))
'@
$pycode = $pycode.Replace('{VID}', $vid).Replace('{LANGS}', $Langs)
$tmppy  = Join-Path $env:TEMP ('yt_tr_' + [guid]::NewGuid().ToString() + '.py')

$pycode | Set-Content -Path $tmppy -Encoding utf8
try {
    python $tmppy | Tee-Object -FilePath $OutPath | Out-Null
} finally {
    Remove-Item $tmppy -ErrorAction SilentlyContinue
}

if (-not (Test-Path $OutPath) -or (Get-Item $OutPath).Length -eq 0) {
    try {
        youtube_transcript_api --list-transcripts $vid | Out-Null
        youtube_transcript_api $vid --languages $Langs | Set-Content -Path $OutPath -Encoding utf8
    } catch {
        Write-Error 'Kon transcript niet ophalen (API en CLI faalden).'
        exit 1
    }
}

# 2) zinnen bouwen (unicode-safe) + random selecties
$text = Get-Content $OutPath -Raw -Encoding utf8
$text = [regex]::Replace($text, '\s+', ' ').Trim()
$text = [regex]::Replace($text, '\[(?:music|applause|laughter|inaudible)[^\]]*\]', '', 'IgnoreCase')
$text = [regex]::Replace($text, '\([^)]*\)', '')

$splitPattern = '(?<=\.|\!|\?|…)\s+(?=\p{Lu}|\d|''|“|")'
$sentences = [regex]::Split($text, $splitPattern) | ForEach-Object { $_.Trim() }

$sentences = $sentences | Where-Object {
    $_ -match '^\p{Lu}' -and $_ -match '[\.\!\?…]$' -and $_.Length -ge 40 -and $_.Length -le 220
} | Where-Object {
    $_ -notmatch '\[[^\]]+\]' -and $_ -notmatch '_{2,}'
}

if (-not $sentences -or $sentences.Count -lt 2) {
    $fallback = ($text -split '\. ') | ForEach-Object { ($_ -replace '\s+', ' ').Trim('.') } |
        Where-Object { $_.Length -ge 40 -and $_.Length -le 220 } |
        ForEach-Object { $_ + '.' }
    if ($fallback) { $sentences = $fallback }
}

if (-not $sentences) {
    Write-Error 'No usable sentences extracted.'
    exit 1
}

$rand = if ($Seed -ne 0) { [Random]::new($Seed) } else { [Random]::new() }
$N    = $sentences.Count
$win  = [Math]::Min(10, $N)
$start  = $rand.Next(0, [Math]::Max(1, $N - $win))
$window = $sentences[$start..([Math]::Min($N-1, $start+$win-1))]
$pick   = $sentences[$rand.Next(0, $N)]

'--- willekeurige 10 opeenvolgende zinnen ---'
$window | ForEach-Object { "'$_'" }
'--- losse willekeurige quote ---'
"'$pick'"

$sentOut  = [IO.Path]::ChangeExtension($OutPath,'sentences.txt')
$cleanOut = [IO.Path]::ChangeExtension($OutPath,'clean.txt')
$mdOut    = [IO.Path]::ChangeExtension($OutPath,'clean.md')

$sentences | Set-Content -Path $sentOut -Encoding utf8

# 3) clean NL-verhaal (optionele LanguageTool)
$cleanPy = @'
import sys, re, pathlib
def to_text(sents):
    txt = ' '.join(sents)
    txt = re.sub(r'\s+([,.:;!?…])', r'\1', txt)
    txt = re.sub(r'\s+', ' ', txt).strip()
    return txt
def lt_cleanup(text):
    try:
        import language_tool_python
        tool = language_tool_python.LanguageTool('nl')
        return language_tool_python.utils.correct(text, tool.check(text))
    except Exception:
        return text
if __name__ == "__main__":
    sents = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8", errors="ignore").splitlines()
    body  = to_text([s for s in sents if 40 <= len(s) <= 220 and re.search(r'[.!?…]$', s)])
    body  = lt_cleanup(body)
    pathlib.Path(sys.argv[2]).write_text(body, encoding="utf-8")
'@
$cleanPyPath = Join-Path $env:TEMP ('nl_clean_' + [guid]::NewGuid().ToString() + '.py')
$cleanPy | Set-Content -Path $cleanPyPath -Encoding utf8
try { python $cleanPyPath $sentOut $cleanOut | Out-Null } finally { Remove-Item $cleanPyPath -ErrorAction SilentlyContinue }

# 4) les-md schrijven (quote veilig bouwen)
$md = @'
# Les 0  Esko 101 quote

Quote: {QUOTE}

Waarom:

Vraag voor de klas:
'@
$quote = "'$pick'"
$md = $md.Replace('{QUOTE}', $quote)
$md | Set-Content -Path $mdOut -Encoding utf8

'md geschreven: ' + $mdOut
'clean geschreven: ' + $cleanOut
'zinregels geschreven: ' + $sentOut

if ($Open) { notepad $mdOut }
