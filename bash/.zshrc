# Bootstrap PATH
path=(
    $HOME/.local/bin
    $HOME/bin
    $HOME/.cargo/bin        # Prefer rustup-managed Rust toolchain
    /opt/homebrew/bin      # macOS Homebrew (Apple Silicon)
    /opt/homebrew/sbin
    /usr/local/bin         # macOS Homebrew (Intel) / Linux
    /usr/local/sbin
    $path
)
typeset -U path  # dedupe

# Host-specific shell overrides (not tracked)
[ -f "$HOME/.config/shell/local.sh" ] && . "$HOME/.config/shell/local.sh"

# mise + starship if running zsh interactively
if command -v mise &>/dev/null; then
    eval "$(mise activate zsh)"
fi
if command -v starship &>/dev/null; then
    eval "$(starship init zsh)"
fi
export PATH=$PATH:$HOME/.maestro/bin
