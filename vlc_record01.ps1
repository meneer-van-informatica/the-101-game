$vlc = 'C:\Program Files\VideoLAN\VLC\vlc.exe'
$out = 'C:\Capture\screen.mp4'
New-Item -ItemType Directory -Path 'C:\Capture' -Force | Out-Null
Start-Process $vlc `
  '-I','dummy','screen://',':screen-fps=30',':screen-caching=100',
  '--sout=#transcode{vcodec=h264,acodec=none}:std{access=file,mux=mp4,dst=C:\Capture\screen.mp4}',
  '--run-time=30','vlc://quit' -Wait
Write-Host 'Klaar → C:\Capture\screen.mp4'
