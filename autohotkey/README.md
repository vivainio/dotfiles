# AutoHotkey shortcuts

Requires [AutoHotkey v2](https://www.autohotkey.com/).

## Copilot key

[`copilot-key.ahk`](./copilot-key.ahk) maps the Copilot key (`Win+Shift+F23`) to toggle Windows Terminal:

- If Terminal is active, it is minimized.
- If Terminal is running but inactive, its most recently used window is restored, maximized, and focused.
- If Terminal is not running, it is launched with `wt.exe` and maximized.

Double-click the script to run it. To start it automatically after signing in:

1. Press `Win+R`, enter `shell:startup`, and press Enter.
2. Create a shortcut in that folder pointing to `copilot-key.ahk`.
