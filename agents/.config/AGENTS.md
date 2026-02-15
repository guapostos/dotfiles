# AGENTS.md

Eric Ihli owns this. Start: say hi + 1 motivating line. Work style: concise dense thorough; min tokens;

## This file

- ~/.config/AGENTS.md (symlinked to ~/.claude/CLAUDE.md)
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

**STOP. DO NOT WRITE CODE YET.**

Misunderstanding requirements wastes hours. Before ANY implementation:

1. **Restate the goal** - summarize what you think user wants in 1-2 sentences
2. **Ask clarifying questions** - if ANY ambiguity exists, ask. Don't assume.
3. **Confirm understanding** - get explicit "yes" before writing code
4. **Describe approach** - outline your plan; let user catch misalignment early

Only proceed when user confirms understanding is correct.

**High-level planning is OK** - sketch out large projects, identify components, discuss architecture. But when implementing: **one specific, well-defined piece at a time**. Confirm each piece before coding it.

Red flags that mean STOP and CLARIFY:
- "I think you want..." (you're guessing)
- Multiple reasonable interpretations exist
- You'd need to make architectural decisions user didn't specify
- The request touches unfamiliar parts of the codebase

Check:
- Have context? (existing code, patterns, constraints)
- User specific enough? If vague, ask.
- Can start with simple testable version?
- Response >50 lines or >3 files? Simplify or break down.

## Coding

- Write tests before implementation
- Tests document context: what was the situation/expectation when added?
- Type checks pass before "done"
- Tests pass before "done"
- No shortcuts to pass types/tests
- Use appropriate lint tools
- Keep files small (optimize for tokens)

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

- Follow `~/.claude/conventions/logging.md` for directory layout and format
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
- E2e to verify; if blocked, say what's missing
- **External APIs: integration test early** - verify real connectivity before extensive mocks

## Planning

- Web search early
- Read external docs early

## Documentation

- Keep notes short; update when behavior/API changes
- Add `read_when` hints on cross-cutting docs
- Follow links until domain makes sense
- **Proactively fix stale docs** after significant work
- **README.md maintenance**: update verification commands, document new modules
- **Diagrams**: use graphviz, not ascii art

## Build / Test

- Before handoff: run full gate (lint, types, tests, docs)
- Use `/review` skill for critical review before complete
- **Handoff summary**: findings, choices made, results (what changed and why)

## Long-Running Sessions

For multi-session/overnight autonomous work:
- **One feature at a time** - complete, test, commit before next
- **Session startup**: `pwd` → read git log/progress → verify baseline → then work
- **Use `/long-session`** to set up progress tracking artifacts
- Update `claude-progress.txt` before session ends

## Git

- Destructive ops forbidden unless explicit
- No repo-wide search & replace; keep edits small
- Avoid manual `git stash`
- Check `git status` and `git diff`; keep commits small
- Prefer `--ff-only` merges (linear history); rebase if needed; project-local CLAUDE.md can override

### Commit messages

- No "Co-authored by ..." AI tagline
- Add context: "what" + "why" (+ "why not X" where appropriate)

## Context Window Management

- Never paste long repetitive tool output - summarize patterns
- Fix auto-fixable issues before asking for help (`--fix` flags)
- Group related errors: "12 type annotation errors" not 12 lines
- Show solutions with problems
- Use incremental checking (changes, not entire codebase)

## Process Management

Use shell job control:
```bash
npm start &          # background
jobs                 # list
kill %1              # kill job 1
jobs -p | xargs kill # cleanup all
```

## Red Flags - Stop and Reassess

- Same error type 3+ times
- Response >50 lines new code
- Changing >3 files at once
- User keeps asking "why isn't this working?"
- Debugging helpers more complex than target code

When triggered: step back, ask what's the smallest useful piece, simplify ruthlessly.

## Critical Thinking

- Fix root cause (not band-aid)
- Unsure: read more code; if still stuck, ask w/ short options
- Conflicts: call out; pick safer path
- Leave breadcrumb notes in thread
