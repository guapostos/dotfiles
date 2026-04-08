#!/bin/bash
# Install dotfiles via stow
# Run from the dotfiles directory

set -e
cd "$(dirname "$0")"

link_shared_doc() {
    local target="$1"
    local source="$2"

    mkdir -p "$(dirname "$target")"

    if [ -e "$target" ] && [ ! -L "$target" ]; then
        echo "Skipping $target (exists and is not a symlink)"
        return
    fi

    ln -sfn "$source" "$target"
    echo "Linked $target -> $source"
}

link_shared_dir() {
    local target="$1"
    local source="$2"

    mkdir -p "$(dirname "$target")"

    if [ -L "$target" ] || [ ! -e "$target" ]; then
        ln -sfn "$source" "$target"
        echo "Linked $target -> $source"
        return
    fi

    if [ -d "$target" ]; then
        if find "$target" -mindepth 1 ! \( -type d -o -type l \) -print -quit | grep -q .; then
            echo "Skipping $target (directory contains non-symlink files)"
            return
        fi

        rm -rf "$target"
        ln -sfn "$source" "$target"
        echo "Replaced $target -> $source"
        return
    fi

    echo "Skipping $target (exists and is not a symlink or directory)"
}

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
    "starship:-:starship:starship"
    "delta:-:git-delta:git-delta"
    "mise:-:mise:mise"
    "fzf:fzf:fzf:fzf"
    "fd|fdfind:fd-find:fd:fd"
    "zoxide:zoxide:zoxide:zoxide"
    "bat|batcat:bat:bat:bat"
    "tmux:tmux:tmux:tmux"
    "git-lfs:git-lfs:git-lfs:git-lfs"
    "jq:jq:jq:jq"
)

# Check which tools are missing
missing=()
missing_pkgs=()
manual=()
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
            missing+=("${cmd%%|*}")
            missing_pkgs+=("$pkg")
        else
            manual+=("${cmd%%|*}")
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

# Print manual install instructions for tools not in package manager
if [ ${#manual[@]} -gt 0 ]; then
    echo ""
    echo "=== Manual installs needed ==="
    echo ""
    echo "These tools aren't in $PM repos. Install manually:"
    for tool in "${manual[@]}"; do
        case $tool in
            starship)  echo "  starship:  curl -sS https://starship.rs/install.sh | sh" ;;
            delta)     echo "  delta:     https://github.com/dandavison/delta/releases" ;;
            mise)      echo "  mise:      curl https://mise.run | sh" ;;
            usage)     echo "  usage:     brew install usage  OR  cargo install usage-cli" ;;
            *)         echo "  $tool:     (no install instructions available)" ;;
        esac
    done
    echo ""
fi

# Stow all packages
for pkg in age agents bash claude fish git nix starship tmux zellij; do
    echo "Stowing $pkg..."
    stow --no-folding -t ~ "$pkg"
done

# Stow private overlay (domain-specific skills/agents, not in public repo)
# Uses symlink: claude-private -> ../dotfiles-private/claude-private
# Stow from same dir enables tree folding (merges into shared ~/.claude/)
if [ ! -e claude-private ] && [ -d ../dotfiles-private/claude-private ]; then
    ln -sfn ../dotfiles-private/claude-private claude-private
    echo "Linked local private overlay symlink"
fi

if [ -L claude-private ] && [ -d claude-private ]; then
    echo "Stowing private overlay..."
    stow -t ~ claude-private
else
    echo "No private overlay found (optional). To add:"
    echo "  git clone <private-repo> ~/src/dotfiles-private"
    echo "  ln -sfn ../dotfiles-private/claude-private ~/src/dotfiles/claude-private"
    echo "  stow -t ~ claude-private"
fi

# Link shared AGENTS.md into tools that natively read AGENTS.md
SHARED_AGENTS="$HOME/.config/AGENTS.md"
if [ -f "$SHARED_AGENTS" ]; then
    link_shared_doc "$HOME/.codex/AGENTS.md" "$SHARED_AGENTS"
    link_shared_doc "$HOME/.config/opencode/AGENTS.md" "$SHARED_AGENTS"

    # Claude Code still needs CLAUDE.md. Fall back to shared AGENTS.md only if
    # no Claude-specific global file exists yet.
    if [ ! -e "$HOME/.claude/CLAUDE.md" ]; then
        mkdir -p "$HOME/.claude"
        ln -sfn "$SHARED_AGENTS" "$HOME/.claude/CLAUDE.md"
        echo "Linked $HOME/.claude/CLAUDE.md -> $SHARED_AGENTS"
    fi
fi

SHARED_SKILLS_ROOT="$HOME/.agents/skills"
SHARED_SKILLS=(
    "checkpoint"
    "multi-mind"
    "next"
    "research"
    "session-notes"
)

for skill in "${SHARED_SKILLS[@]}"; do
    if [ -d "$SHARED_SKILLS_ROOT/$skill" ]; then
        link_shared_dir "$HOME/.claude/skills/$skill" "$SHARED_SKILLS_ROOT/$skill"
        link_shared_dir "$HOME/.codex/skills/$skill" "$SHARED_SKILLS_ROOT/$skill"
        link_shared_dir "$HOME/.config/opencode/skills/$skill" "$SHARED_SKILLS_ROOT/$skill"
    fi
done

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
