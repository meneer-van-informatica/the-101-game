; space_hue.ahk — Alt+Space triggert Hue flash via PowerShell
#NoEnv
#SingleInstance Force
SendMode Input
SetWorkingDir, E:\the-101-game\tools

; Pad naar jouw script
ps := "powershell -NoProfile -ExecutionPolicy Bypass -File ""E:\the-101-game\scripts\hue_blink.ps1"" -Times 1"

; Alt+Spatie = flash 1x
!Space::
  Run, %ps%, , Hide
return

; Optioneel: pure Space laten flashen (interfereert met typen!)
; Verwijder de eerste ';' van de volgende regel als je dit écht wilt.
; $Space::
;   Run, %ps%, , Hide
; return
