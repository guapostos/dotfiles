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
opencode/   -> ~/.config/opencode/ (OpenCode generated agent wrappers)
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

## Scope

This repo holds tool configuration and domain-neutral AI infrastructure — shells, terminal, git, nix, general workflow skills (checkpoint, next, research, session-notes, skill-creator, multi-mind) and generic engineering agents (debug, reviewer-*, code-simplifier, verify-app, logalyzer).

Work/domain-specific material (private project-specific skills, local overlays, secrets) lives in a peer repo at `~/src/dotfiles-private` with its own `install.sh`. Run both installers if you want the full environment.

## AI Config

- Shared global conventions live in `~/.config/AGENTS.md`.
- Claude-specific global additions live in `~/.claude/CLAUDE.md`.
- This repo-level `AGENTS.md` is the shared project instructions file for tools that support `AGENTS.md`.
- `CLAUDE.md` in this repo imports this file so Claude Code reads the same project instructions.
- Portable shared agents live in `~/.agents/agents/` and render into tool-native wrappers.
- Portable shared skills live in `~/.agents/skills/`.
- The canonical Codex plugin registry is `agents/.agents/plugins/marketplace.json`.

## Canonical Sources

- Edit canonical sources, not generated wrappers.
- Portable agents: `agents/.agents/agents/`
- Portable skills: `agents/.agents/skills/`
- Claude-only skills: `claude/.claude/skills/`
- Do not hand-edit generated wrappers under `opencode/.config/opencode/agents/` or `plugins/plugins/dotfiles-agents/agents/`; they are rendered by `scripts/render-agent-surfaces.py` and refreshed by `./install.sh`.

## Skill Install Pipeline

- `install.sh` stows `agents` with `--no-folding` so `~/.agents/` stays a real dir (prevents stray writes from leaking into this repo — see commit `ab70eca`), then refolds each `~/.agents/skills/<name>/` into a directory symlink so `SKILL.md` is a real file at the end of the chain (required by Codex's skill loader).
- Each skill under `~/.agents/skills/` is then linked into `~/.claude/skills/`, `~/.codex/skills/`, and `~/.config/opencode/skills/`.
