#!/usr/bin/env python3
"""
Skill Initializer - Creates a new skill from a template.

Usage:
    init_skill.py <skill-name> --path <output-directory>

Examples:
    init_skill.py data-cleaner --path ~/.agents/skills
    init_skill.py my-helper   --path /tmp
"""

import sys
from pathlib import Path


SKILL_TEMPLATE = """---
name: {skill_name}
description: |
  TODO: What this skill does AND when to trigger it. Include concrete user
  phrases, file types, or contexts. Lean slightly assertive — agents often
  under-trigger skills. Example: "Use whenever the user mentions X, Y, or Z,
  even if they do not explicitly ask for a skill."
---

# {skill_title}

## Overview

[TODO: 1-2 sentences explaining what this skill enables.]

## Structure

[TODO: Pick the structure that fits. Common patterns:

1. Workflow-based: sequential process with clear steps.
2. Task-based: a collection of independent operations.
3. Reference: standards, schemas, or specifications.
4. Capabilities: integrated system with multiple features.

Most skills mix patterns. Delete this section when done.]

## [TODO: First main section]

[TODO: Add content here. Write for another AI agent, not a human reader. Explain *why*
things matter so the agent can generalize to edge cases.]

## Resources

[Delete any directories you do not use.]

### scripts/
Executable code run directly by the agent.

### references/
Markdown documentation loaded on demand.

### assets/
Files used *in* the agent's output (templates, images, fonts, boilerplate).
"""

EXAMPLE_SCRIPT = '''#!/usr/bin/env python3
"""Example helper script for {skill_name}. Replace or delete."""


def main() -> None:
    print("Example script for {skill_name}")


if __name__ == "__main__":
    main()
'''

EXAMPLE_REFERENCE = """# Reference Documentation for {skill_title}

Placeholder for detailed reference material. Replace or delete.

Reference docs are ideal for:
- API documentation
- Database schemas
- Detailed workflow guides
- Content too long to live in SKILL.md

Include a table of contents if the file grows beyond ~100 lines.
"""

EXAMPLE_ASSET = """Placeholder asset.

Assets are files used in the agent's output, not loaded into context.
Replace or delete.

Typical assets: .pptx/.docx templates, .png/.svg images, .ttf/.woff2 fonts,
boilerplate code directories, sample data files.
"""


def title_case(skill_name: str) -> str:
    """Convert a hyphen-case skill name to Title Case for display.

    >>> title_case("data-cleaner")
    'Data Cleaner'
    >>> title_case("pdf")
    'Pdf'
    >>> title_case("a-b-c")
    'A B C'
    """
    return " ".join(word.capitalize() for word in skill_name.split("-"))


def init_skill(skill_name: str, path: str) -> Path | None:
    skill_dir = Path(path).resolve() / skill_name

    if skill_dir.exists():
        print(f"Error: skill directory already exists: {skill_dir}")
        return None

    skill_dir.mkdir(parents=True, exist_ok=False)
    print(f"Created {skill_dir}")

    skill_title = title_case(skill_name)
    (skill_dir / "SKILL.md").write_text(
        SKILL_TEMPLATE.format(skill_name=skill_name, skill_title=skill_title)
    )
    print("  SKILL.md")

    scripts_dir = skill_dir / "scripts"
    scripts_dir.mkdir()
    example_script = scripts_dir / "example.py"
    example_script.write_text(EXAMPLE_SCRIPT.format(skill_name=skill_name))
    example_script.chmod(0o755)
    print("  scripts/example.py")

    references_dir = skill_dir / "references"
    references_dir.mkdir()
    (references_dir / "reference.md").write_text(
        EXAMPLE_REFERENCE.format(skill_title=skill_title)
    )
    print("  references/reference.md")

    assets_dir = skill_dir / "assets"
    assets_dir.mkdir()
    (assets_dir / "example.txt").write_text(EXAMPLE_ASSET)
    print("  assets/example.txt")

    print()
    print(f"Skill '{skill_name}' initialized at {skill_dir}")
    print("Next:")
    print("  1. Fill in SKILL.md — especially the description.")
    print("  2. Customize or delete scripts/, references/, assets/.")
    print("  3. Run scripts/quick_validate.py to check the skill structure.")
    return skill_dir


def main() -> None:
    if len(sys.argv) != 4 or sys.argv[2] != "--path":
        print("Usage: init_skill.py <skill-name> --path <output-directory>")
        print()
        print("Skill name: hyphen-case, lowercase letters/digits/hyphens, max 64 chars.")
        sys.exit(1)

    skill_name = sys.argv[1]
    path = sys.argv[3]

    print(f"Initializing skill: {skill_name}")
    print(f"  at: {path}")
    print()

    result = init_skill(skill_name, path)
    sys.exit(0 if result else 1)


if __name__ == "__main__":
    main()
