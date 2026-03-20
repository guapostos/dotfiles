#!/usr/bin/env bash
# Refresh agentic-best-practices.md with current vendor documentation.
# Uses Claude Code in non-interactive mode: researcher → reviewer.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="$REPO_ROOT/agents/.config/agentic-best-practices.md"

echo "=== Step 1: Researching current best practices ==="
claude -p "$(cat <<'PROMPT'
Search the web for the latest AI agentic coding best practices from:
1. Anthropic (Claude Code, CLAUDE.md guidance)
2. OpenAI (Codex, AGENTS.md guidance)
3. Google (Gemini CLI, GEMINI.md guidance)

Then update the file agents/.config/agentic-best-practices.md with a concise,
vendor-neutral summary. Rules:
- Under 60 lines of content (not counting the sources section)
- Organize by topic, not by vendor
- Only include practices applicable across all three tools
- Be concrete and actionable, not vague
- Include a Sources section at the bottom with URLs
- Update the "Last updated" date to today
- Keep the existing file structure/format as a guide
PROMPT
)"

echo ""
echo "=== Step 2: Reviewing the update ==="
claude -p "$(cat <<'PROMPT'
Review the file agents/.config/agentic-best-practices.md that was just updated.
Check for:
1. Accuracy — no hallucinated practices or broken URLs
2. Conciseness — under 60 lines of content? Cut fluff if over
3. Vendor-neutrality — no Claude/Codex/Gemini-specific features
4. Actionability — every bullet should be concrete, not vague
5. No conflicts with agents/.config/AGENTS.md (don't duplicate what's there)

Fix any issues directly in the file. If it looks good, leave it as-is.
PROMPT
)"

echo ""
echo "=== Done ==="
echo "Review changes with: git diff $TARGET"
