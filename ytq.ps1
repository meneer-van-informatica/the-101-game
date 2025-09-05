param(
    [Parameter(Mandatory=$true)][string]$Url,
    [string]$Langs = 'nl,en',
    [string]$OutPath
)

function Get-YouTubeId([string]$u) {
    if ($u -match '^[A-Za-z0-9_-]{11}$') { return $u }
    if ($u -match 'v=([A-Za-z0-9_-]{11})') { return $Matches[1] }
    if ($u -match 'youtu\.be/([A-Za-z0-9_-]{11})') { return $Matches[1] }
    return $u
}

# strip eventueel meegekomen aanhalingstekens uit -Langs
$Langs = $Langs.Trim("'",'"','`')

$vid = Get-YouTubeId $Url
if (-not $OutPath) {
    $date = Get-Date -Format 'yyyyMMdd'
    $OutPath = Join-Path $env:USERPROFILE "Documents\transcript_${vid}_${date}.txt"
}

$pycode = @'
from youtube_transcript_api import YouTubeTranscriptApi
api = YouTubeTranscriptApi()
vid = '{VID}'
langs = '{LANGS}'.split(',')
tx = api.fetch(vid, languages=langs)
raw = tx.to_raw_data()
print('\n'.join([t['text'] for t in raw]))
'@
$pycode = $pycode.Replace('{VID}', $vid).Replace('{LANGS}', $Langs)

$tmppy = Join-Path $env:TEMP ('yt_tr_' + [guid]::NewGuid().ToString() + '.py')
$pycode | Set-Content -Path $tmppy -Encoding utf8

try {
    python $tmppy | Tee-Object -FilePath $OutPath | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Error 'Python transcript step failed.'
        exit 1
    }
}
finally {
    Remove-Item $tmppy -ErrorAction SilentlyContinue
}

if (-not (Test-Path $OutPath)) {
    Write-Error 'Transcript file not created.'
    exit 1
}

$doc = Get-Content $OutPath -ErrorAction Stop
$k = $doc | Where-Object { $_ -match '\S' -and $_.Length -ge 25 -and $_.Length -le 120 }

'--- top 10 zinnen ---'
$top = $k | Select-Object -First 10
$top | ForEach-Object { "'$_'" }

$pick = $k | Sort-Object Length -Descending | Select-Object -First 1
'--- aanbevolen ---'
"'$pick'"

$md = @'
# Les 0  Esko 101 quote

Quote: {QUOTE}

Waarom:

Vraag voor de klas:
'@
$md = $md.Replace('{QUOTE}', "'" + $pick + "'")
$mdOut = [IO.Path]::ChangeExtension($OutPath,'md')
$md | Set-Content -Path $mdOut -Encoding utf8
'md geschreven: ' + $mdOut
