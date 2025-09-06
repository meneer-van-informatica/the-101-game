; god.ahk — zichtbare blink voor PowerShell (v2) met F11
#Requires AutoHotkey v2.0
#SingleInstance Force

global gBlinkOn := false
global gHwnd := 0
global gOrigTitle := ''

IsPwshWindow() {
    return WinActive("ahk_exe powershell.exe")
        || WinActive("ahk_exe pwsh.exe")
        || (WinActive("ahk_exe WindowsTerminal.exe") && InStr(WinGetTitle("A"), "PowerShell"))
}

MsgBox("god.ahk actief — F11 toggelt blink in PowerShell")

#HotIf IsPwshWindow()
F11::ToggleBlink()
::blink::ToggleBlink()
#HotIf

ToggleBlink() {
    global gBlinkOn, gHwnd, gOrigTitle
    if !IsPwshWindow() {
        ToolTip("Niet in PowerShell-window")
        SetTimer (() => ToolTip()), -800
        return
    }
    if !gBlinkOn {
        gHwnd := WinExist("A")
        gOrigTitle := WinGetTitle(gHwnd)
        gBlinkOn := true
        if WinActive("ahk_exe WindowsTerminal.exe") {
            SetTimer FlashWT, 450
        } else {
            SetTimer BlinkTitle, 450
        }
    } else {
        SetTimer BlinkTitle, 0
        SetTimer FlashWT, 0
        if gOrigTitle && gHwnd
            WinSetTitle(gOrigTitle, "ahk_id " . gHwnd)
        gBlinkOn := false
    }
}

BlinkTitle(*) {
    global gHwnd, gOrigTitle, gBlinkOn
    static flip := false
    if !gBlinkOn || !WinExist("ahk_id " . gHwnd) || !WinActive("ahk_id " . gHwnd) {
        SetTimer BlinkTitle, 0
        if gOrigTitle
            WinSetTitle(gOrigTitle, "ahk_id " . gHwnd)
        gBlinkOn := false
        return
    }
    flip := !flip
    WinSetTitle((flip ? gOrigTitle " [BLINK]" : gOrigTitle), "ahk_id " . gHwnd)
}

FlashWT(*) {
    static FLASHW_STOP := 0, FLASHW_CAPTION := 1, FLASHW_TRAY := 2, FLASHW_TIMERNOFG := 12
    global gHwnd, gBlinkOn
    if !gBlinkOn || !WinExist("ahk_id " . gHwnd) || !WinActive("ahk_id " . gHwnd) {
        FlashWindow(gHwnd, FLASHW_STOP, 0, 0)
        SetTimer FlashWT, 0
        gBlinkOn := false
        return
    }
    FlashWindow(gHwnd, FLASHW_CAPTION | FLASHW_TRAY, 1, 0)
}

FlashWindow(hwnd, flags, count, timeout) {
    buf := Buffer(20, 0)
    NumPut("UInt", 20, buf, 0)
    NumPut("Ptr", hwnd, buf, 4)
    NumPut("UInt", flags, buf, 4 + A_PtrSize)
    NumPut("UInt", count, buf, 8 + A_PtrSize)
    NumPut("UInt", timeout, buf, 12 + A_PtrSize)
    DllCall("user32\FlashWindowEx", "Ptr", buf, "UInt")
}
