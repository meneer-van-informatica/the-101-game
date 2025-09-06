param(
  [double]$Hz = 1.0,          # knips per seconde (toggle-modus)
  [int]$Seconds = 15,         # duur
  [ValidateSet('alert','toggle')]$Mode = 'alert',
  [switch]$Kill,              # probeer entertainment/spotify te killen
  [switch]$Stop,              # stop lopende alert (alert=none)
  [switch]$Beat               # speel Tik–Tok op de beat
)
$ErrorActionPreference = 'SilentlyContinue'

# config
$cfg  = Get-Content .\data\hue_config.json -Raw | ConvertFrom-Json
$base = 'http://{0}/api/{1}' -f $cfg.ip, $cfg.username

function ApiPut($path, $body) {
  try {
    $json = $body | ConvertTo-Json -Compress
    Invoke-RestMethod -Uri ($base + '/' + $path) -Method Put -Body $json -ContentType 'application/json' -TimeoutSec 3 | Out-Null
  } catch {}
}

# --- AUDIO: maak een korte WAV in-memory en speel die af via SoundPlayer (betrouwbaarder dan Console.Beep) ---
Add-Type -AssemblyName System.Windows.Forms | Out-Null
Add-Type -AssemblyName System.Media | Out-Null
function Play-Tone([double]$freq, [int]$ms, [double]$vol = 0.25) {
  try {
    $rate = 44100
    $samples = [int]([math]::Round($rate * ($ms/1000.0)))
    $amp = [int](32767 * [math]::Min([math]::Max($vol,0),1))
    $msStream = New-Object System.IO.MemoryStream
    $bw = New-Object System.IO.BinaryWriter($msStream)

    # WAV header (PCM, mono, 16-bit)
    $dataBytes = $samples * 2
    $bw.Write([byte[]][char[]]"RIFF")
    $bw.Write([int](36 + $dataBytes))
    $bw.Write([byte[]][char[]]"WAVEfmt ")
    $bw.Write([int]16)               # PCM header size
    $bw.Write([short]1)              # PCM format
    $bw.Write([short]1)              # mono
    $bw.Write([int]$rate)
    $bw.Write([int]($rate * 2))      # byte rate (sampleRate * blockAlign)
    $bw.Write([short]2)              # block align (channels * bytesPerSample)
    $bw.Write([short]16)             # bits per sample
    $bw.Write([byte[]][char[]]"data")
    $bw.Write([int]$dataBytes)

    for ($i=0; $i -lt $samples; $i++) {
      $t = 2.0 * [math]::PI * $freq * ($i / $rate)
      $s = [int]([math]::Sin($t) * $amp)
      $bw.Write([short]$s)
    }
    $bw.Flush(); $msStream.Position = 0
    $player = New-Object System.Media.SoundPlayer
    $player.Stream = $msStream
    $player.PlaySync()
    $player.Dispose(); $bw.Dispose(); $msStream.Dispose()
  } catch {}
}

function Beep-TikTok([int]$i) {
  if (-not $Beat) { return }
  $accent = ($i % 4 -eq 0)
  if ($accent) {
    Play-Tone 1300 60 0.3
  } else {
    if ($i % 2 -eq 0) { Play-Tone 1000 40 0.25 } else { Play-Tone 800 40 0.25 }
  }
}

if ($Kill) {
  Get-Process | Where-Object { $_.ProcessName -match 'Spotify|Hue.*Sync|HueDynamic|HueStream|Razer|Chroma|iCUE|OpenRGB|SignalRGB' } |
    ForEach-Object { try { Stop-Process -Id $_.Id -Force } catch {} }
}

if ($Stop) {
  ApiPut 'groups/0/action' @{ alert = 'none' }
  Write-Host '[ok] alert gestopt.'
  return
}

# waarschuwing als entertainment nog actief is (alleen melding)
try {
  $g = Invoke-RestMethod -Uri ($base + '/groups') -TimeoutSec 3
  $active = @()
  foreach ($p in $g.PSObject.Properties) {
    $v = $p.Value
    if ($v.type -eq 'Entertainment' -and $v.stream -and $v.stream.active) { $active += $p.Name }
  }
  if ($active.Count -gt 0) {
    Write-Host ('[let op] Entertainment actief: ' + ($active -join ', ') + ' - blink kan genegeerd worden.')
  }
} catch {}

if ($Mode -eq 'alert') {
  ApiPut 'groups/0/action' @{ on = $true; alert = 'lselect' }
  $deadline = (Get-Date).AddSeconds($Seconds)
  $i = 0
  while (Get-Date -lt $deadline) {
    $i++
    Beep-TikTok $i
    Start-Sleep -Seconds (1.0 / [Math]::Max(0.5,$Hz))
  }
  ApiPut 'groups/0/action' @{ alert = 'none' }
  Write-Host '[ok] blink (alert) klaar.'
} else {
  $dt = [math]::Max(0.05, 1.0 / $Hz / 2.0)
  $deadline = (Get-Date).AddSeconds($Seconds)
  $state = $true
  $i = 0
  while (Get-Date -lt $deadline) {
    $i++
    ApiPut 'groups/0/action' @{ on = $state; bri = 254 }
    Beep-TikTok $i
    Start-Sleep -Seconds $dt
    $state = -not $state
  }
  ApiPut 'groups/0/action' @{ on = $true }
  Write-Host '[ok] blink (toggle) klaar.'
}
