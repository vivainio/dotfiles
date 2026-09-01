# Herdr config

This configuration mirrors the key choices in `~/dotfiles/tmux.conf`:

- `Ctrl+Space` is the prefix.
- `Alt+Left` / `Alt+Right` switch tabs (tmux windows).
- `Alt+Up` / `Alt+Down` switch workspaces (tmux sessions).
- `prefix + k`, `prefix + K`, and `prefix + x` close a tab, workspace,
  and pane.
- `prefix + Ctrl+G`, `prefix + Ctrl+L`, `prefix + Ctrl+N`, and
  `prefix + m` open the same popups as tmux.
- Catppuccin and Nushell remain the defaults.

On Linux, install it with:

```sh
mkdir -p ~/.config/herdr
ln -s ~/dotfiles/herdr/config.toml ~/.config/herdr/config.toml
herdr server reload-config
```

On Windows, Herdr reads `%APPDATA%\herdr\config.toml`:

```powershell
New-Item -ItemType Directory -Force "$env:APPDATA\herdr"
New-Item -ItemType SymbolicLink -Force `
  -Path "$env:APPDATA\herdr\config.toml" `
  -Target "$HOME\dotfiles\herdr\config.toml"
herdr server reload-config
```

Running `python install.py` selects the correct target automatically.
