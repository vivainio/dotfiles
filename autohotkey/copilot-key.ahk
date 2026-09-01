#Requires AutoHotkey v2.0
#SingleInstance Force

; Install for automatic startup:
; 1. Press Win+R, enter shell:startup, and press Enter.
; 2. Right-click inside the folder and select New > Shortcut.
; 3. Use this script's full path as the shortcut target.
; 4. Name the shortcut "Copilot key" and finish the wizard.
;
; To stop the script, right-click its AutoHotkey tray icon and select Exit.
;
; The Copilot key is reported by Windows as Win+Shift+F23.
#+F23::ToggleWindowsTerminal()

ToggleWindowsTerminal() {
    terminal := "ahk_exe WindowsTerminal.exe"

    if WinActive(terminal) {
        WinMinimize(terminal)
        return
    }

    if hwnd := WinExist(terminal) {
        if WinGetMinMax(hwnd) = -1
            WinRestore(hwnd)

        WinMaximize(hwnd)
        WinActivate(hwnd)
        return
    }

    try {
        Run("wt.exe")

        if hwnd := WinWait(terminal, , 5) {
            WinMaximize(hwnd)
            WinActivate(hwnd)
        }
    } catch Error as err {
        MsgBox(
            "Could not start Windows Terminal.`n`n" err.Message,
            "Copilot key",
            "Iconx"
        )
    }
}
