# Bootstrap PATH
path=(
    $HOME/.local/bin
    $HOME/bin
    /usr/local/bin
    /usr/local/sbin
    $path
)
typeset -U path  # dedupe

# mise + starship if running zsh interactively
if command -v mise &>/dev/null; then
    eval "$(mise activate zsh)"
fi
if command -v starship &>/dev/null; then
    eval "$(starship init zsh)"
fi
