Add-Type -AssemblyName System.Media
# 800 Hz, 120 ms
$rate=44100;$ms=120;$freq=800
$s=[int]($rate*$ms/1000.0);$amp=20000
$msm=New-Object IO.MemoryStream;$bw=New-Object IO.BinaryWriter($msm)
$bw.Write([byte[]][char[]]"RIFF");$bw.Write([int](36+$s*2));$bw.Write([byte[]][char[]]"WAVEfmt ")
$bw.Write(16);$bw.Write([int16]1);$bw.Write([int16]1);$bw.Write($rate);$bw.Write($rate*2);$bw.Write([int16]2);$bw.Write([int16]16)
$bw.Write([byte[]][char[]]"data");$bw.Write($s*2)
for($i=0;$i -lt $s;$i++){ $t=2*[math]::PI*$freq*($i/$rate);$bw.Write([int16]([math]::Sin($t)*$amp)) }
$bw.Flush();$msm.Position=0;$p=New-Object System.Media.SoundPlayer;$p.Stream=$msm;$p.PlaySync();$p.Dispose();$bw.Dispose();$msm.Dispose()
