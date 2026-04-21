# Minimal bash config - fallback when fish unavailable
# Mirror of fish config for consistency across machines

# Exit if non-interactive
[[ $- != *i* ]] && return

# === History ===
HISTCONTROL=ignoreboth
HISTSIZE=50000
HISTFILESIZE=100000
shopt -s histappend

# === XDG ===
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"

# === Environment ===
export EDITOR=vim

# Host-specific shell overrides (not tracked)
[ -f "$HOME/.config/shell/local.sh" ] && . "$HOME/.config/shell/local.sh"

# === Terminal colors ===
# Enable true color support for modern terminals (Claude Code, bat, delta, etc.)
if [[ -z "$COLORTERM" && "$TERM" =~ (256color|alacritty|kitty|tmux|screen) ]]; then
    export COLORTERM=truecolor
fi

# === PATH (platform-aware) ===
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
case "$(uname)" in
    Darwin)
        # Homebrew (Apple Silicon then Intel) + MacPorts
        [ -d /opt/homebrew/bin ] && export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
        [ -d /usr/local/bin ] && export PATH="/usr/local/bin:/usr/local/sbin:$PATH"
        [ -d /opt/local/bin ] && export PATH="/opt/local/bin:/opt/local/sbin:$PATH"
        ;;
esac

# Go binaries
[ -d "$HOME/go/bin" ] && export PATH="$HOME/go/bin:$PATH"

# === Git aliases ===
alias gc='git commit'
alias gp='git push'
alias gpf='git push --force-with-lease'
alias gl='git pull'
alias gd='git diff'
alias gds='git diff --staged'
alias glg='git log --oneline'
alias gco='git checkout'
alias gst='git status'
alias ga='git add'
alias gaa='git add --all'
alias gcm='git commit -m'
alias gsw='git switch'
alias gswc='git switch -c'
alias grb='git rebase'

# === Tools (if available) ===
command -v mise &>/dev/null && eval "$(mise activate bash)"
command -v starship &>/dev/null && eval "$(starship init bash)"
command -v fzf &>/dev/null && eval "$(fzf --bash)"

# === fzf with fd ===
if command -v fd &>/dev/null; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
fi
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'

# === Rust/Cargo ===
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# === zoxide (smart cd) ===
command -v zoxide &>/dev/null && eval "$(zoxide init bash)"

# === bat (better cat) ===
command -v bat &>/dev/null && alias cat='bat'
export ANDROID_HOME="$HOME/Android/Sdk"
export PATH="$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/emulator"
export PATH=$PATH:$HOME/.maestro/bin
