#!/bin/bash
# Install dotfiles via stow
# Run from the dotfiles directory

set -e
cd "$(dirname "$0")"

# Regenerate tool-specific AGENTS.md / CLAUDE.md surfaces from shared source.
if [ -f scripts/render-agent-surfaces.py ]; then
    python3 scripts/render-agent-surfaces.py
fi

# ---- helper functions ----

link_shared_doc() {
    local target="$1"
    local source="$2"

    mkdir -p "$(dirname "$target")"

    if [ -e "$target" ] && [ ! -L "$target" ]; then
        echo "Skipping $target (exists and is not a symlink)"
        return
    fi

    if [ -L "$target" ] && [ "$(readlink -f -- "$target" 2>/dev/null)" = "$(readlink -f -- "$source" 2>/dev/null)" ]; then
        return
    fi

    ln -sfn "$source" "$target"
    echo "Linked $target -> $source"
}

link_shared_dir() {
    local target="$1"
    local source="$2"

    mkdir -p "$(dirname "$target")"

    if [ -L "$target" ]; then
        # If the existing symlink already resolves to the same final target,
        # leave it alone. This preserves stow-owned chains (e.g. private
        # overlay pointing through the shared tree) and keeps install.sh
        # idempotent.
        existing="$(readlink -f -- "$target" 2>/dev/null || true)"
        desired="$(readlink -f -- "$source" 2>/dev/null || true)"
        if [ -n "$desired" ] && [ "$existing" = "$desired" ]; then
            return
        fi
        ln -sfn "$source" "$target"
        echo "Linked $target -> $source"
        return
    fi

    if [ ! -e "$target" ]; then
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

link_compat_file() {
    local legacy_target="$1"
    local source="$2"
    local legacy_norm
    local source_norm

    mkdir -p "$(dirname "$legacy_target")"

    if [ -L "$legacy_target" ] || [ ! -e "$legacy_target" ]; then
        ln -sfn "$source" "$legacy_target"
        echo "Linked $legacy_target -> $source"
        return
    fi

    if cmp -s "$legacy_target" "$source"; then
        rm -f "$legacy_target"
        ln -sfn "$source" "$legacy_target"
        echo "Replaced identical legacy file $legacy_target -> $source"
        return
    fi

    legacy_norm="$(mktemp)"
    source_norm="$(mktemp)"
    if jq -S . "$legacy_target" >"$legacy_norm" 2>/dev/null && jq -S . "$source" >"$source_norm" 2>/dev/null; then
        if cmp -s "$legacy_norm" "$source_norm"; then
            rm -f "$legacy_norm" "$source_norm"
            rm -f "$legacy_target"
            ln -sfn "$source" "$legacy_target"
            echo "Replaced equivalent legacy JSON $legacy_target -> $source"
            return
        fi
    fi
    rm -f "$legacy_norm" "$source_norm"

    echo "Skipping $legacy_target (legacy file differs from managed config)"
}

# ---- package manager / dep install ----

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

missing=()
missing_pkgs=()
manual=()
for dep in "${DEPS[@]}"; do
    IFS=: read -r cmd apt_pkg port_pkg brew_pkg pacman_pkg <<< "$dep"
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

# ---- shared-skill discovery (for stow --ignore filtering) ----

shared_skill_names=()
shared_skill_ignore_args=()

has_shared_skill() {
    local candidate="$1"
    local name
    for name in "${shared_skill_names[@]}"; do
        [ "$name" = "$candidate" ] && return 0
    done
    return 1
}

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

# ---- stow public packages ----

# Clear refolded skill leaves before re-stowing shared skill packages. The
# post-stow refold step below replaces stow's per-file symlinks with direct
# directory symlinks, which stow treats as foreign on a subsequent run.
# Removing those leaves first keeps both public and private skill overlays
# idempotent.
clear_refolded_skill_leaves() {
    local source_root leaf target

    [ -d "$HOME/.agents/skills" ] || return

    for source_root in "$@"; do
        source_root="$(readlink -f -- "$source_root" 2>/dev/null || true)"
        [ -n "$source_root" ] || continue

        for leaf in "$HOME/.agents/skills"/*; do
            [ -L "$leaf" ] || continue
            target="$(readlink -f -- "$leaf" 2>/dev/null || true)"
            case "$target" in
                "$source_root"/*) rm -f "$leaf" ;;
            esac
        done
    done
}

clear_refolded_skill_leaves "${shared_skill_roots[@]}"

for pkg in age agents alacritty bash claude desktop fish git localbin nix opencode plugins starship tmux zellij; do
    [ -d "$pkg" ] || continue
    build_shared_skill_ignore_args "$pkg"
    if [ ${#shared_skill_ignore_args[@]} -gt 0 ]; then
        echo "Stowing $pkg (shared skills filtered)..."
    else
        echo "Stowing $pkg..."
    fi
    stow --no-folding "${shared_skill_ignore_args[@]}" -t ~ "$pkg"

    if [ "$pkg" = "opencode" ]; then
        OPENCODE_CONFIG="$HOME/.config/opencode/opencode.json"
        if [ -f "$OPENCODE_CONFIG" ]; then
            # Keep the legacy install tree compatible while making the XDG path
            # the canonical source of truth.
            link_compat_file "$HOME/.opencode/opencode.json" "$OPENCODE_CONFIG"
        fi
    fi
done

# ---- stow private overlays ----
# Symlink shims in this repo point at ../dotfiles-private/* so stow sees all
# overlapping packages from a single stow dir. Lets shared targets like
# ~/.claude/ and ~/.agents/ get split safely between public and private.
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
        stow --no-folding "${shared_skill_ignore_args[@]}" -t ~ "$overlay"
        stowed_private=true
    fi
done

if ! $stowed_private; then
    echo "No private overlays found (optional). To add:"
    echo "  git clone <private-repo> ~/src/dotfiles-private"
    for overlay in "${private_overlays[@]}"; do
        echo "  ln -sfn ../dotfiles-private/$overlay ~/src/dotfiles/$overlay"
    done
fi

# ---- shared skills: refold + fan out to each tool ----

SHARED_SKILLS_ROOT="$HOME/.agents/skills"

# Refold public-repo skills at the leaf level. We stow `agents` with
# --no-folding to keep ~/.agents/ itself a real directory (so stray writes
# don't leak into the repo). But that leaves each ~/.agents/skills/<name>/ as
# a real dir with symlinked leaves, which means SKILL.md ends up a symlink.
# Codex's skill loader is supposed to follow symlinked SKILL.md files, but in
# practice skills discovered that way don't show up in `/skills`. Collapsing
# each skill subdir into a single directory symlink gives every consumer
# (Codex, Claude Code, OpenCode) a real SKILL.md at the far end of the chain.
#
# Safe because LLM tooling treats skill dirs as read-only; nothing writes
# cache/state next to SKILL.md.
refold_public_skills() {
    local source_root="$1"
    [ -d "$source_root" ] || return
    [ -d "$SHARED_SKILLS_ROOT" ] || return

    for src in "$source_root"/*/; do
        [ -d "$src" ] || continue
        name="$(basename "$src")"
        leaf="$SHARED_SKILLS_ROOT/$name"
        src_canon="$(readlink -f -- "$src")"

        if [ -L "$leaf" ]; then
            if [ "$(readlink -f -- "$leaf")" = "$src_canon" ]; then
                continue
            fi
            rm -f "$leaf"
        elif [ -d "$leaf" ]; then
            rm -rf "$leaf"
        fi

        ln -sfn "$src_canon" "$leaf"
        echo "Refolded $leaf -> $src_canon"
    done
}

refold_public_skills "$(pwd)/agents/.agents/skills"
refold_public_skills "$(pwd)/agents-private/.agents/skills"

if [ -d "$SHARED_SKILLS_ROOT" ]; then
    for skill_dir in "$SHARED_SKILLS_ROOT"/*; do
        [ -d "$skill_dir" ] || continue
        skill="$(basename "$skill_dir")"
        link_shared_dir "$HOME/.claude/skills/$skill" "$skill_dir"
        link_shared_dir "$HOME/.codex/skills/$skill" "$skill_dir"
        link_shared_dir "$HOME/.config/opencode/skills/$skill" "$skill_dir"
    done
fi

# ---- shared AGENTS.md surfaces ----

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

# ---- lisa plugin registration ----

PLUGINS_FILE=~/.claude/plugins/installed_plugins.json
if [ -f "$PLUGINS_FILE" ]; then
    if ! grep -q '"lisa@local"' "$PLUGINS_FILE"; then
        echo "Registering lisa plugin..."
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
