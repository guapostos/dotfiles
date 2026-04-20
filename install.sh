#!/bin/bash
# Install dotfiles via stow
# Run from the dotfiles directory

set -e
cd "$(dirname "$0")"

# Detect package manager
if command -v port &> /dev/null; then
    PM=port
    PM_INSTALL="sudo port install"
elif command -v pacman &> /dev/null; then
    PM=pacman
    PM_INSTALL="sudo pacman -S --needed"
elif command -v apt &> /dev/null; then
    PM=apt
    PM_INSTALL="sudo apt install -y"
elif command -v brew &> /dev/null; then
    PM=brew
    PM_INSTALL="brew install"
else
    echo "No supported package manager found (port, pacman, apt, brew)"
    exit 1
fi

# Tools required by dotfiles configs
# Format: "command:apt_pkg:port_pkg:brew_pkg:pacman_pkg"
# Use - to skip a package manager (tool not available there)
# Use cmd1|cmd2 to check alternate binary names (e.g. Debian's fdfind/batcat)
DEPS=(
    "stow:stow:stow:stow:stow"
    "fish:fish:fish:fish:fish"
    "starship:-:starship:starship:starship"
    "delta:-:git-delta:git-delta:git-delta"
    "mise:-:mise:mise:mise"
    "fzf:fzf:fzf:fzf:fzf"
    "fd|fdfind:fd-find:fd:fd:fd"
    "zoxide:zoxide:zoxide:zoxide:zoxide"
    "bat|batcat:bat:bat:bat:bat"
    "tmux:tmux:tmux:tmux:tmux"
    "git-lfs:git-lfs:git-lfs:git-lfs:git-lfs"
    "jq:jq:jq:jq:jq"
    "terminal-notifier:-:terminal-notifier:terminal-notifier:-"
    "usage:-:-:usage:usage"
)

# Check which tools are missing
missing=()
missing_pkgs=()
manual=()
for dep in "${DEPS[@]}"; do
    IFS=: read -r cmd apt_pkg port_pkg brew_pkg pacman_pkg <<< "$dep"
    # Check all alternate names (pipe-separated)
    found=false
    for alt in ${cmd//|/ }; do
        if command -v "$alt" &> /dev/null; then found=true; break; fi
    done
    if ! $found; then
        case $PM in
            apt)    pkg=$apt_pkg ;;
            port)   pkg=$port_pkg ;;
            brew)   pkg=$brew_pkg ;;
            pacman) pkg=$pacman_pkg ;;
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

shared_skill_names=()
shared_skill_ignore_args=()

collect_shared_skills() {
    local root src name

    for root in "$@"; do
        [ -d "$root" ] || continue

        for src in "$root"/*; do
            [ -e "$src" ] || continue
            [ -d "$src" ] || [ -L "$src" ] || continue
            name="$(basename "$src")"
            if ! has_shared_skill "$name"; then
                shared_skill_names+=("$name")
            fi
        done
    done
}

has_shared_skill() {
    local candidate="$1"
    local name

    for name in "${shared_skill_names[@]}"; do
        if [ "$name" = "$candidate" ]; then
            return 0
        fi
    done

    return 1
}

regex_escape() {
    printf '%s' "$1" | sed -e 's/[][(){}.^$+*?|\\]/\\&/g'
}

build_shared_skill_ignore_args() {
    local pkg="$1"
    local pkg_source skill_root entry name escaped_root
    local shared_names=()
    local entries=()

    shared_skill_ignore_args=()
    pkg_source="$(readlink -f -- "$pkg" 2>/dev/null || true)"
    if [ -z "$pkg_source" ] || [ ! -d "$pkg_source" ]; then
        return
    fi

    for skill_root in ".claude/skills" ".codex/skills" ".config/opencode/skills"; do
        [ -d "$pkg_source/$skill_root" ] || continue

        entries=()
        shared_names=()
        while IFS= read -r -d '' entry; do
            entries+=("$entry")
            name="$(basename "$entry")"
            if { [ -d "$entry" ] || [ -L "$entry" ]; } && has_shared_skill "$name"; then
                shared_names+=("$name")
            fi
        done < <(find "$pkg_source/$skill_root" -mindepth 1 -maxdepth 1 -print0 2>/dev/null)

        [ ${#shared_names[@]} -gt 0 ] || continue

        escaped_root="$(regex_escape "$skill_root")"
        if [ ${#shared_names[@]} -eq ${#entries[@]} ]; then
            shared_skill_ignore_args+=("--ignore=$escaped_root")
            continue
        fi

        for name in "${shared_names[@]}"; do
            shared_skill_ignore_args+=("--ignore=$escaped_root/$(regex_escape "$name")")
        done
    done
}

shared_skill_roots=("$(pwd)/agents/.agents/skills" "$(pwd)/agents-private/.agents/skills")
collect_shared_skills "${shared_skill_roots[@]}"

# Stow all packages
for pkg in alacritty claude agents bash fish git localbin nix opencode starship tmux zellij; do
    build_shared_skill_ignore_args "$pkg"
    if [ ${#shared_skill_ignore_args[@]} -gt 0 ]; then
        echo "Stowing $pkg (shared skills filtered)..."
    else
        echo "Stowing $pkg..."
    fi
    stow "${shared_skill_ignore_args[@]}" -t ~ "$pkg"
done

# Stow private overlays (personal configs not kept in the public repo).
# These are symlink shims in this repo pointing at ../dotfiles-private/* so
# Stow can see all overlapping packages from a single stow dir and split
# shared targets like ~/.claude/ and ~/.agents/ safely.
private_overlays=(agents-private claude-private gemini-private git-private opencode-private)
stowed_private=false
for overlay in "${private_overlays[@]}"; do
    if [ -L "$overlay" ] && [ -d "$overlay" ]; then
        build_shared_skill_ignore_args "$overlay"
        if [ ${#shared_skill_ignore_args[@]} -gt 0 ]; then
            echo "Stowing $overlay (shared skills filtered)..."
        else
            echo "Stowing $overlay..."
        fi
        stow "${shared_skill_ignore_args[@]}" -t ~ "$overlay"
        stowed_private=true
    fi
done

if ! $stowed_private; then
    echo "No private overlays found (optional). To add:"
    echo "  git clone <private-repo> ~/src/dotfiles-private"
    echo "  ln -sfn ../dotfiles-private/agents-private ~/src/dotfiles/agents-private"
    echo "  ln -sfn ../dotfiles-private/claude-private ~/src/dotfiles/claude-private"
    echo "  ln -sfn ../dotfiles-private/gemini-private ~/src/dotfiles/gemini-private"
    echo "  ln -sfn ../dotfiles-private/git-private ~/src/dotfiles/git-private"
    echo "  ln -sfn ../dotfiles-private/opencode-private ~/src/dotfiles/opencode-private"
    echo "  stow -t ~ agents-private"
    echo "  stow -t ~ claude-private"
    echo "  stow -t ~ gemini-private"
    echo "  stow -t ~ git-private"
    echo "  stow -t ~ opencode-private"
fi

link_tool_skill() {
    local target="$1"
    local source="$2"
    local existing_link

    mkdir -p "$(dirname "$target")"

    if [ -L "$target" ]; then
        existing_link="$(readlink -- "$target" 2>/dev/null || true)"
        if [ -n "$existing_link" ] && [ "$existing_link" = "$source" ]; then
            return
        fi
    fi

    if [ -e "$target" ] && [ ! -L "$target" ]; then
        echo "Skipping $target (exists and is not a symlink)"
        return
    fi

    ln -sfn "$source" "$target"
    echo "Linked $target -> $source"
}

refold_shared_skill_root() {
    local source_root="$1"
    local leaf name src_canon current_canon

    [ -d "$source_root" ] || return
    mkdir -p "$HOME/.agents/skills"

    for src in "$source_root"/*/; do
        [ -d "$src" ] || continue
        name="$(basename "$src")"
        leaf="$HOME/.agents/skills/$name"
        src_canon="$(readlink -f -- "$src")"
        current_canon="$(readlink -f -- "$leaf" 2>/dev/null || true)"

        if [ -n "$current_canon" ] && [ "$current_canon" = "$src_canon" ]; then
            link_tool_skill "$HOME/.claude/skills/$name" "$leaf"
            link_tool_skill "$HOME/.codex/skills/$name" "$leaf"
            link_tool_skill "$HOME/.config/opencode/skills/$name" "$leaf"
            continue
        fi

        if [ -L "$leaf" ]; then
            rm -f "$leaf"
        elif [ -d "$leaf" ]; then
            rm -rf "$leaf"
        fi

        ln -sfn "$src_canon" "$leaf"
        echo "Refolded $leaf -> $src_canon"

        link_tool_skill "$HOME/.claude/skills/$name" "$leaf"
        link_tool_skill "$HOME/.codex/skills/$name" "$leaf"
        link_tool_skill "$HOME/.config/opencode/skills/$name" "$leaf"
    done
}

refold_shared_skill_root "$(pwd)/agents/.agents/skills"
refold_shared_skill_root "$(pwd)/agents-private/.agents/skills"

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
