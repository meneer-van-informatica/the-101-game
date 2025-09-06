; space_hue.ahk v2 — Alt+Space blink; Alt+H toggelt game-mode (Space capture)
#NoEnv
#SingleInstance Force
SendMode Input
SetWorkingDir, E:\the-101-game\tools

ps := "powershell -NoProfile -ExecutionPolicy Bypass -File ""E:\the-101-game\scripts\hue_blink.ps1"""
team := ""  ; optioneel: lees uit ENV of hardcode

; Alt+Space = korte flash
!Space::
  cmd := ps " -Pattern x -IntervalMs 280"
  if (team != "")
    cmd := cmd " -Team " team
  Run, %cmd%, , Hide
return

; Alt+H = toggle game-mode: als aan, vangt $Space:: de spatie overal
!h::
  FileCreateDir, E:\the-101-game\tmp
  flag := "E:\the-101-game\tmp\SPACE_ON"
  if (FileExist(flag)) {
    FileDelete, %flag%
    TrayTip, Game mode, Space-capture UIT, 2, 1
  } else {
    FileAppend, on, %flag%
    TrayTip, Game mode, Space-capture AAN, 2, 1
  }
return

; Pure Space in game-mode
$Space::
  if (FileExist("E:\the-101-game\tmp\SPACE_ON")){
    cmd := ps " -Pattern x.x..x -IntervalMs 200"
    if (team != "")
      cmd := cmd " -Team " team
    Run, %cmd%, , Hide
    return
  }
  Send, {Space}
return
