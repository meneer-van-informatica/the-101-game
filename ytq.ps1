$doc = Get-Content $OutPath -ErrorAction Stop

# 1) Maak één tekst en normaliseer spaties
$text = ($doc -join ' ').Trim()
$text = [regex]::Replace($text, '\s+', ' ')

# 2) Verwijder ruis (tussen [] of ())
$text = [regex]::Replace($text, '\[(?:music|applause|laughter|inaudible)[^\]]*\]', '', 'IgnoreCase')
$text = [regex]::Replace($text, '\([^)]*\)', '')

# 3) Splits in zinnen op . ! ? … gevolgd door spatie + hoofdletter/quote/cijfer
$splitPattern = '(?<=[\.\!\?…])\s+(?=[A-ZÀ-ÖØ-Þ0-9''”“""])'
$sentences = [regex]::Split($text, $splitPattern) |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ -match '\S' -and $_.Length -ge 25 -and $_.Length -le 220 }

# 4) Val terug op regels als zinnen leeg zijn
if (-not $sentences -or $sentences.Count -lt 2) {
    $sentences = $doc | ForEach-Object { $_.Trim() } |
        Where-Object { $_ -match '\S' -and $_.Length -ge 25 -and $_.Length -le 220 }
}

# 5) Random keuzes
$rand = New-Object System.Random
$N = $sentences.Count
$win = [Math]::Min(10, $N)
$start = $rand.Next(0, [Math]::Max(1, $N - $win))
$window = $sentences[$start..([Math]::Min($N-1, $start+$win-1))]
$pick = $sentences[$rand.Next(0, $N)]

# 6) Print output
'--- willekeurige 10 opeenvolgende zinnen ---'
$window | ForEach-Object { "'$_'" }
'--- losse willekeurige quote ---'
"'$pick'"

# 7) Schrijf ook een .sentences.txt bestand
$sentOut = [IO.Path]::ChangeExtension($OutPath,'sentences.txt')
$sentences | Set-Content -Path $sentOut -Encoding utf8

# 8) Maak de .md met de losse quote
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
'zinregels geschreven: ' + $sentOut
