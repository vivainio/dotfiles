# Linux/WSL specific nushell config
# Source this from your config.nu:
# source ~/r/dotfiles/my-linux-config.nu

$env.config.buffer_editor = "code"

# zoxide - smarter cd command
# Install with: curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
# Generate init file with: zoxide init nushell | save -f ~/.cache/zoxide.nu
source ~/.cache/zoxide.nu

# activate virtualenv in current dir (Linux uses bin instead of Scripts)
alias act = overlay use .venv/bin/activate.nu
