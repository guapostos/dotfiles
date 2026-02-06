#!/bin/bash
# Install dotfiles via stow
# Run from the dotfiles directory

set -e
cd "$(dirname "$0")"

# Install stow if missing
if ! command -v stow &> /dev/null; then
    echo "Installing stow..."
    if command -v apt &> /dev/null; then
        sudo apt install -y stow
    elif command -v port &> /dev/null; then
        sudo port install stow
    elif command -v brew &> /dev/null; then
        brew install stow
    else
        echo "Please install stow manually"
        exit 1
    fi
fi

# Stow all packages
for pkg in alacritty claude agents bash fish git nix starship tmux zellij; do
    echo "Stowing $pkg..."
    stow -t ~ "$pkg"
done

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
