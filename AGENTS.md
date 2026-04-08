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
opencode/   -> ~/.config/opencode/ (OpenCode agent wrappers)
plugins/    -> ~/plugins/ (Codex plugin surfaces)
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
- Portable shared agents live in `~/.agents/agents/` at the source level and render into tool-native wrappers.
- Portable shared skills live in `~/.agents/skills/`.
- Tool-native skill links point to the shared skill directory for the migrated portable skills.
- The canonical Codex plugin registry is `agents/.agents/plugins/marketplace.json`; add future local plugins there rather than editing `~/.agents/plugins/marketplace.json` by hand.

## Skills And Private Overlay

- Portable cross-tool agent sources live in `agents/.agents/agents/`.
- Portable cross-tool skills live in `agents/.agents/skills/`.
- Claude-only skills remain in `claude/.claude/skills/`.
- Generated OpenCode agent wrappers live in `opencode/.config/opencode/agents/`.
- Generated Codex plugin agents live in `plugins/plugins/dotfiles-agents/agents/`.
- Private Claude skills and agents live in `~/src/dotfiles-private/claude-private/`.
- Private shared agent and skill sources can live in `~/src/dotfiles-private/agents-private/`.
- Private OpenCode agent wrappers can live in `~/src/dotfiles-private/opencode-private/`.
- The local gitignored `claude-private -> ../dotfiles-private/claude-private` symlink lets `stow` merge the private overlay into `~/.claude/`.
