# AGENTS.md

Work style: concise dense thorough; careful; build the right thing and build the thing right; min tokens;

## This file

- ~/.config/AGENTS.md — shared coding conventions for all AI agents
- ~/.config/agentic-best-practices.md — cross-vendor best practices (refresh with `scripts/refresh-best-practices.sh`)
- "Make a note" or "Remember to" => edit this file
- Minimize tokens; optimize for AI agent

## Core Philosophy

**Simple ≠ short/easy**: Simple = untangled (one strand); complex = braided (intertwined concerns); easy = familiar (but often complex). Simplify means decouple/untangle, not inline/shorten/remove.

- **Start simple, always** - smallest testable version first
- **Build up from small** - compose from tiny, tested pieces
- **Functions 3-5 lines** - decompose if larger
- **REPL-driven development** - design for interactive exploration
- **Minimize state** - each piece loadable/testable in isolation
- **Doctests** - inline examples that verify behavior
- **Ask before assuming** - gather context/specificity before implementing
- **Fail fast explicitly** - raise exceptions, not silent failures
- **Fix root cause** - no band-aids

## Before Implementing

- Restate the goal in 1-2 sentences
- Clarify ambiguity before coding; ask, don't assume
- For small clear low-risk changes, proceed after a brief restatement
- Have context: existing code, patterns, constraints
- Start with the smallest testable version
- Response >50 lines or >3 files? Simplify or break down

**Blast radius**: 1-2 files → just do it; 3-5 → plan first; 5+ → `working-spec.md` + subagents/parallel agents when available

**STOP if**: you're guessing intent, multiple interpretations exist, architectural decisions weren't specified, destructive/external side effects are involved, or you're touching unfamiliar code without a clear precedent. High-level planning is fine — but implement one specific piece at a time.

## Coding

- Write tests before implementation
- Tests document context: what was the situation/expectation when added?
- Type checks pass before "done"
- Tests pass before "done"
- No shortcuts to pass types/tests
- Use appropriate lint tools
- Keep files small (optimize for tokens)
- Comment tricky sections to preserve intent across sessions; "why not X" prevents re-trying killed approaches
- Reference sibling projects explicitly for pattern reuse

### Docstrings

Non-trivial functions get detailed "why" docstrings:
- **Purpose**: Why does this exist? What problem does it solve?
- **Context**: Who uses this? When/why created?
- **Behavior**: What decisions and why?
- **Exceptions**: What error conditions cause failure?

Comments should add value beyond what code says:
- ❌ `# Calculate the total` (obvious)
- ✅ `# Use abs() because inputs can be negative (e.g. losses)`

### Error Handling

- Invalid inputs raise exceptions (don't silently omit)
- Error messages: include invalid value + suggest fix
- Let callers handle edge cases (they have context)
- Batch processors catch exceptions at batch level

### Secrets

- .env.enc encrypted age/sops (decrypted to .gitignored .env)
- Only *secrets* in .env; config in config files (.toml, .py, .json, .yaml, whatever...)!

### Logging

- If a project/user logging convention doc exists, follow it for layout and format
- JSON lines format, `runs/{timestamp}_{sha}[_dirty]/` dirs, `latest` symlink
- Output useful to AI agents: clean, structured, min tokens, max info
- Use log levels appropriately
- Use logs to debug
- **Multiprocessing**: stdout prints interleave/corrupt; use `QueueHandler` or file-per-worker

### XDG Directories

Follow XDG Base Directory spec:
- `$XDG_CONFIG_HOME` (~/.config) - config files
- `$XDG_DATA_HOME` (~/.local/share) - persistent data
- `$XDG_CACHE_HOME` (~/.cache) - non-essential cached data
- `$XDG_STATE_HOME` (~/.local/state) - logs, history, recent files

Never pollute $HOME with dotfiles/dotdirs.

## Testing

- Testing pyramid: mostly unit, some integration, few e2e
- **Unit tests must be fast** - no big data, no network, no disk I/O
- Integration/e2e: keep fast as possible; mark with `@pytest.mark.slow`; must be skippable (`pytest -m "not slow"`)
- No big-data test fixtures - use minimal representative samples
- E2e to verify; if blocked, say what's missing
- **External APIs: integration test early** - verify real connectivity before extensive mocks

## Planning

- Web search early
- Read external docs early
- **New projects**: start from shared pre-commit and static-analysis templates if available
- **Large new projects**: write `SPEC.md` as an immutable design contract for LLM agents: locked constraints, killed approaches with evidence, layer gates, decision log

## Documentation

- Keep notes short; update when behavior/API changes
- Add `read_when` hints on cross-cutting docs
- Follow links until domain makes sense
- **Per-project memory**: read `.ai-memory.md` in project root on startup (gitignored, not shared with collaborators). Append stable patterns confirmed across multiple interactions — not session-specific notes. Prune entries that no longer apply. Keep concise (<100 lines). Create if missing on first worthy insight.
- **Proactively fix stale docs** after significant work
- **README.md maintenance**: update verification commands, document new modules
- **Diagrams**: use graphviz, not ascii art

## Build / Test

- Before handoff: run full gate (lint, types, tests, docs)
- Run a critical review pass before complete; use tool support when available
- **Refactoring budget**: ~20% agent time on cleanup — dead code, dedup, `ruff check --fix`
- **Handoff summary**: findings, choices made, results (what changed and why)

## Long-Running Sessions

For multi-session/overnight autonomous work:
- **One feature at a time** - complete, test, commit before next
- **Session startup**: `pwd` → read git log/progress → verify baseline → then work
- Use a lightweight progress artifact for multi-session work

## Git

- Destructive ops forbidden unless explicit
- No repo-wide search & replace; keep edits small
- Avoid manual `git stash`
- Check `git status` and `git diff`; keep commits small
- Prefer `--ff-only` merges (linear history); rebase if needed; project-local CLAUDE.md can override

### Commit messages

- **NEVER** add "Co-authored-by" or any AI attribution tagline to commits
- Add context: "what" + "why" (+ "why not X" where appropriate)

## Context Window Management

- Never paste long repetitive tool output - summarize patterns
- Fix auto-fixable issues before asking for help (`--fix` flags)
- Group related errors: "12 type annotation errors" not 12 lines
- Show solutions with problems
- Use incremental checking (changes, not entire codebase)

## Process Management

- **Python buffering**: Use `python3 -u` for unbuffered stdout in subprocesses/tools
- Use shell job control (`&`, `jobs`, `kill %N`) for background processes

## Red Flags - Stop and Reassess

- Same error type 3+ times
- Response >50 lines new code
- Changing >3 files at once
- User keeps asking "why isn't this working?"
- Debugging helpers more complex than target code

When triggered: step back, ask what's the smallest useful piece, simplify ruthlessly.

## Critical Thinking

- Fix root cause (not band-aid)
- Prefer robustness for external/uncontrolled inputs.
- For stale internal artifacts created by our own code: understand why they exist first. If they are low-value and easily regenerated, prefer deleting or regenerating them over compatibility shims or one-off conditionals.
- Never delete data or artifacts without explicit user approval, even if they look stale, low-value, replaceable, or internally generated.
- **Chesterton's Fence (operational)**: Before proposing to change, remove, bypass, or invert any existing code, config, flag, or convention, first find out *why* it's there. Do this *before* the suggestion leaves your mouth, not after the user pushes back. Minimum steps:
  1. `git log -S "<token>" -- <path>` and/or `git blame` on the line
  2. Read the introducing commit message and diff
  3. Check nearby docs/comments for stated intent
  If the reason is still unclear, ask — don't guess. A suggestion that regresses a prior fix is worse than a question. When you do propose the change, state the original reason and why it no longer applies (or why the tradeoff is now worth it).
- Unsure: read more code; if still stuck, ask w/ short options
- Conflicts: call out; pick safer path
- Leave breadcrumb notes in thread

### Challenge the Approach

User may be stuck in narrow thinking. Distinguish *goal* from *method*:
- "Build a testing framework" → goal is testing, not building frameworks. Suggest existing tools?
- "Grid search for hyperparameters" → goal is optimization. Bayesian search? Optuna?
- "Write a parser for X" → goal is parsing X. Existing library?

**When to suggest alternatives:**
- Existing, mature solution fits the goal
- Proposed approach has known pitfalls you can foresee
- Simpler path achieves same outcome

**Balance:** Don't derail. Brief suggestion + rationale, then defer to user. "Have you considered X because Y? If you prefer the original approach, happy to proceed."
