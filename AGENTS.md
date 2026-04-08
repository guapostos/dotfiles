# Dotfiles

Stow-managed dotfiles for a remote SSH server. Each top-level directory is a stow package that symlinks into `$HOME`.

## Structure

```text
agents/     -> ~/.config/AGENTS.md (shared global AI-agent conventions)
bash/       -> ~/.bashrc, ~/.zshrc (shell fallbacks)
claude/     -> ~/.claude/ (Claude Code settings, skills, hooks)
fish/       -> ~/.config/fish/ (primary shell)
git/        -> ~/.config/git/ (git config, delta)
nix/        -> ~/.config/nix/ (nix config)
starship/   -> ~/.config/starship.toml (prompt)
tmux/       -> ~/.config/tmux/ (terminal multiplexer)
zellij/     -> ~/.config/zellij/ (terminal multiplexer)
age/        -> ~/.config/age/ (encryption recipients)
scripts/    -> utility scripts
```

## Usage

```bash
./install.sh
stow -t ~ <package>
stow -D -t ~ <package>
```

## AI Config

- Shared global conventions live in `~/.config/AGENTS.md`.
- Claude-specific global additions live in `~/.claude/CLAUDE.md`.
- This repo-level `AGENTS.md` is the shared project instructions file for tools that support `AGENTS.md`.
- `CLAUDE.md` in this repo imports this file so Claude Code reads the same project instructions.

## Skills And Private Overlay

- Public Claude skills live in `claude/.claude/skills/`.
- Private Claude skills and agents live in `~/src/dotfiles-private/claude-private/`.
- The local gitignored `claude-private -> ../dotfiles-private/claude-private` symlink lets `stow` merge the private overlay into `~/.claude/`.
