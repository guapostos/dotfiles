#!/bin/bash
# Install dotfiles via stow
# Run from the dotfiles directory

set -e
cd "$(dirname "$0")"

# Detect package manager
if command -v port &> /dev/null; then
    PM=port
    PM_INSTALL="sudo port install"
elif command -v apt &> /dev/null; then
    PM=apt
    PM_INSTALL="sudo apt install -y"
elif command -v brew &> /dev/null; then
    PM=brew
    PM_INSTALL="brew install"
else
    echo "No supported package manager found (port, apt, brew)"
    exit 1
fi

# Tools required by dotfiles configs
# Format: "command:apt_pkg:port_pkg:brew_pkg"
# Use - to skip a package manager (tool not available there)
# Use cmd1|cmd2 to check alternate binary names (e.g. Debian's fdfind/batcat)
DEPS=(
    "stow:stow:stow:stow"
    "fish:fish:fish:fish"
    "starship:starship:starship:starship"
    "delta:git-delta:git-delta:git-delta"
    "mise:mise:mise:mise"
    "fzf:fzf:fzf:fzf"
    "fd|fdfind:fd-find:fd:fd"
    "zoxide:zoxide:zoxide:zoxide"
    "bat|batcat:bat:bat:bat"
    "tmux:tmux:tmux:tmux"
    "git-lfs:git-lfs:git-lfs:git-lfs"
    "terminal-notifier:-:terminal-notifier:terminal-notifier"
)

# Check which tools are missing
missing=()
missing_pkgs=()
for dep in "${DEPS[@]}"; do
    IFS=: read -r cmd apt_pkg port_pkg brew_pkg <<< "$dep"
    # Check all alternate names (pipe-separated)
    found=false
    for alt in ${cmd//|/ }; do
        if command -v "$alt" &> /dev/null; then found=true; break; fi
    done
    if ! $found; then
        case $PM in
            apt)  pkg=$apt_pkg ;;
            port) pkg=$port_pkg ;;
            brew) pkg=$brew_pkg ;;
        esac
        if [ "$pkg" != "-" ]; then
            missing+=("$cmd")
            missing_pkgs+=("$pkg")
        fi
    fi
done

# Install missing tools with confirmation
if [ ${#missing[@]} -gt 0 ]; then
    echo "=== Missing tools ==="
    echo ""
    echo "The following tools are required by dotfiles configs but not installed:"
    for i in "${!missing[@]}"; do
        echo "  ${missing[$i]} (${missing_pkgs[$i]})"
    done
    echo ""
    echo "Will run: $PM_INSTALL ${missing_pkgs[*]}"
    echo ""
    read -p "Install? [Y/n]: " -r
    echo ""
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        $PM_INSTALL "${missing_pkgs[@]}"
    else
        echo "Skipping dependency install. Some configs may not work correctly."
    fi
else
    echo "All tool dependencies satisfied."
fi

# Stow all packages
for pkg in alacritty claude agents bash fish git nix starship tmux zellij; do
    echo "Stowing $pkg..."
    stow -t ~ "$pkg"
done

# Stow private overlay (domain-specific skills/agents, not in public repo)
# Uses symlink: claude-private -> ../dotfiles-private/claude-private
# Stow from same dir enables tree folding (merges into shared ~/.claude/)
if [ -L claude-private ] && [ -d claude-private ]; then
    echo "Stowing private overlay..."
    stow -t ~ claude-private
else
    echo "No private overlay found (optional). To add:"
    echo "  git clone <private-repo> ~/src/dotfiles-private"
    echo "  ln -sfn ../dotfiles-private/claude-private ~/src/dotfiles/claude-private"
    echo "  stow -t ~ claude-private"
fi

# Symlink AGENTS.md to CLAUDE.md for Claude Code
if [ -f ~/.config/AGENTS.md ] && [ ! -e ~/.claude/CLAUDE.md ]; then
    mkdir -p ~/.claude
    ln -sf ~/.config/AGENTS.md ~/.claude/CLAUDE.md
    echo "Symlinked AGENTS.md to ~/.claude/CLAUDE.md"
fi

# Register lisa plugin if not already registered
PLUGINS_FILE=~/.claude/plugins/installed_plugins.json
if [ -f "$PLUGINS_FILE" ]; then
    if ! grep -q '"lisa@local"' "$PLUGINS_FILE"; then
        echo "Registering lisa plugin..."
        # Add lisa entry to installed_plugins.json
        jq '.plugins["lisa@local"] = [{
            "scope": "user",
            "installPath": "'"$HOME"'/.claude/plugins/cache/local/lisa/1.0.0",
            "version": "1.0.0",
            "installedAt": "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'",
            "lastUpdated": "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'"
        }]' "$PLUGINS_FILE" > "$PLUGINS_FILE.tmp" && mv "$PLUGINS_FILE.tmp" "$PLUGINS_FILE"
        echo "Lisa plugin registered"
    fi
else
    echo "Warning: $PLUGINS_FILE not found. Run 'claude' once first to initialize."
fi
echo "Done! Symlinks created."
echo ""
echo "=== Manual steps ==="
echo ""
echo "# Claude cross-user notifications (if running claude as another user):"
echo "sudo cp root/etc/tmpfiles.d/claude-notify.conf /etc/tmpfiles.d/"
echo "sudo systemd-tmpfiles --create  # creates /run/claude-notify now"
echo "systemctl --user daemon-reload"
echo "systemctl --user enable --now claude-notify"
echo ""
echo "# Verify service running:"
echo "systemctl --user status claude-notify"
