# Dotfiles

Stow-managed dotfiles for Eric Ihli. Each top-level directory is a stow package that symlinks into `$HOME`.

## Structure

```
agents/     → ~/.config/AGENTS.md (shared AI agent conventions)
claude/     → ~/.claude/ (Claude Code settings, skills, hooks)
fish/       → ~/.config/fish/ (shell)
git/        → ~/.config/git/ (git config, delta)
zellij/     → ~/.config/zellij/ (terminal multiplexer)
alacritty/  → ~/.config/alacritty/ (terminal)
starship/   → ~/.config/starship.toml (prompt)
nix/        → nix config
tmux/       → ~/.config/tmux/ (legacy multiplexer)
```

## Usage

```bash
./install.sh          # stow all packages + install deps
stow -t ~ <package>   # stow one package
stow -D -t ~ <pkg>    # unstow
```

## Adding Skills

Shared cross-agent skills live at `agents/.agents/skills/<name>/SKILL.md`. The installer fans those out to `~/.claude/skills/`, `~/.codex/skills/`, and `~/.config/opencode/skills/`.

Claude-only skills still live at `claude/.claude/skills/<name>/SKILL.md`.

If a new Claude skill should be invokable without a permission prompt, register it in `claude/.claude/settings.json`.

## Key Files

- `agents/.config/AGENTS.md` — shared conventions (all AI agents read this)
- `claude/.claude/CLAUDE.md` — Claude Code-specific additions
- `claude/.claude/settings.json` — permissions, hooks, plugins
- `install.sh` — bootstrap script (stow + deps)

## Private Overlay

Private stow packages live in `~/src/dotfiles-private/` and are symlinked into this repo when needed. Current overlays:

- `claude-private/` → `~/src/dotfiles-private/claude-private/`
- `git-private/` → `~/src/dotfiles-private/git-private/`
- `opencode-private/` → `~/src/dotfiles-private/opencode-private/`
