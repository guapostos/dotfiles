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

Add `claude/.claude/skills/<name>/SKILL.md` with YAML frontmatter (`name`, `description` with triggers). Register in `claude/.claude/settings.json` permissions if needed.

## Key Files

- `agents/.config/AGENTS.md` — shared conventions (all AI agents read this)
- `claude/.claude/CLAUDE.md` — Claude Code-specific additions
- `claude/.claude/settings.json` — permissions, hooks, plugins
- `install.sh` — bootstrap script (stow + deps)

## Private Overlay

`claude-private/` symlinks to `~/src/dotfiles-private/claude-private/` for domain-specific skills not in the public repo. Stow merges it into `~/.claude/`.
