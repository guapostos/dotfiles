#!/usr/bin/env python3

from __future__ import annotations

import json
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parent.parent
PRIVATE_ROOT = REPO_ROOT.parent / "dotfiles-private"


def load_text(path: Path) -> str:
    return path.read_text(encoding="utf-8").rstrip() + "\n"


def write_if_changed(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists() and path.read_text(encoding="utf-8") == content:
        return
    path.write_text(content, encoding="utf-8")


def prune_files(directory: Path, suffix: str, keep: set[str]) -> None:
    if not directory.is_dir():
        return

    for path in directory.glob(f"*{suffix}"):
        if path.name not in keep:
            path.unlink()


def yaml_scalar(value: Any) -> str:
    return json.dumps(value, ensure_ascii=False)


def yaml_lines(value: Any, indent: int = 0) -> list[str]:
    prefix = "  " * indent

    if isinstance(value, dict):
        lines: list[str] = []
        for key, nested in value.items():
            if nested is None:
                continue
            if isinstance(nested, (dict, list)):
                if not nested:
                    continue
                lines.append(f"{prefix}{key}:")
                lines.extend(yaml_lines(nested, indent + 1))
            else:
                lines.append(f"{prefix}{key}: {yaml_scalar(nested)}")
        return lines

    if isinstance(value, list):
        lines = []
        for nested in value:
            if isinstance(nested, (dict, list)):
                lines.append(f"{prefix}-")
                lines.extend(yaml_lines(nested, indent + 1))
            else:
                lines.append(f"{prefix}- {yaml_scalar(nested)}")
        return lines

    return [f"{prefix}{yaml_scalar(value)}"]


def frontmatter(entries: list[tuple[str, Any]]) -> str:
    body: list[str] = ["---"]
    for key, value in entries:
        if value is None:
            continue
        if isinstance(value, (dict, list)):
            if not value:
                continue
            body.append(f"{key}:")
            body.extend(yaml_lines(value, 1))
        else:
            body.append(f"{key}: {yaml_scalar(value)}")
    body.append("---")
    return "\n".join(body)


def load_agents(root: Path) -> list[dict[str, Any]]:
    if not root.is_dir():
        return []

    agents: list[dict[str, Any]] = []
    for metadata_path in sorted(root.glob("*/agent.json")):
        agent_dir = metadata_path.parent
        metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
        metadata["slug"] = agent_dir.name
        metadata.setdefault("name", agent_dir.name)
        metadata["prompt"] = load_text(agent_dir / "PROMPT.md")
        agents.append(metadata)
    return agents


def render_claude(agent: dict[str, Any]) -> str:
    claude = agent.get("claude", {})
    header = frontmatter(
        [
            ("name", agent["name"]),
            ("description", agent["description"]),
            ("model", claude.get("model")),
        ]
    )
    return f"{header}\n\n{agent['prompt']}"


def render_opencode(agent: dict[str, Any]) -> str:
    opencode = agent.get("opencode", {})
    header = frontmatter(
        [
            ("description", agent["description"]),
            ("mode", opencode.get("mode", "subagent")),
            ("model", opencode.get("model")),
            ("temperature", opencode.get("temperature")),
            ("steps", opencode.get("steps")),
            ("hidden", opencode.get("hidden")),
            ("permission", opencode.get("permission")),
        ]
    )
    return f"{header}\n\n{agent['prompt']}"


def render_codex(agent: dict[str, Any]) -> str:
    header = frontmatter(
        [
            ("name", agent["name"]),
            ("description", agent["description"]),
        ]
    )
    return f"{header}\n\n{agent['prompt']}"


def render_public_agents(agents: list[dict[str, Any]]) -> None:
    outputs = {
        "claude": REPO_ROOT / "claude/.claude/agents",
        "opencode": REPO_ROOT / "opencode/.config/opencode/agents",
        "codex": REPO_ROOT / "plugins/plugins/dotfiles-agents/agents",
    }

    keep = {
        "claude": {f"{agent['slug']}.md" for agent in agents},
        "opencode": {f"{agent['slug']}.md" for agent in agents},
        "codex": {
            f"{agent['slug']}.md"
            for agent in agents
            if agent.get("codex", {}).get("enabled", True)
        },
    }

    prune_files(outputs["claude"], ".md", keep["claude"])
    prune_files(outputs["opencode"], ".md", keep["opencode"])
    prune_files(outputs["codex"], ".md", keep["codex"])

    for agent in agents:
        slug = agent["slug"]
        write_if_changed(outputs["claude"] / f"{slug}.md", render_claude(agent))
        write_if_changed(outputs["opencode"] / f"{slug}.md", render_opencode(agent))
        if agent.get("codex", {}).get("enabled", True):
            write_if_changed(outputs["codex"] / f"{slug}.md", render_codex(agent))


def render_private_agents(agents: list[dict[str, Any]]) -> None:
    if not agents:
        return

    outputs = {
        "claude": PRIVATE_ROOT / "claude-private/.claude/agents",
        "opencode": PRIVATE_ROOT / "opencode-private/.config/opencode/agents",
    }

    keep = {f"{agent['slug']}.md" for agent in agents}
    prune_files(outputs["claude"], ".md", keep)
    prune_files(outputs["opencode"], ".md", keep)

    for agent in agents:
        slug = agent["slug"]
        write_if_changed(outputs["claude"] / f"{slug}.md", render_claude(agent))
        write_if_changed(outputs["opencode"] / f"{slug}.md", render_opencode(agent))


def main() -> None:
    public_agents = load_agents(REPO_ROOT / "agents/.agents/agents")
    private_agents = load_agents(PRIVATE_ROOT / "agents-private/.agents/agents")

    render_public_agents(public_agents)
    render_private_agents(private_agents)


if __name__ == "__main__":
    main()
