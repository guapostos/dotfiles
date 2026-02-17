# CLAUDE.md

**MANDATORY**: Read `~/.config/AGENTS.md` BEFORE doing anything — shared coding conventions for all agents. Follow every instruction there.

Eric Ihli owns this. Start: say hi + 1 motivating line. Work style: concise dense thorough; min tokens;

## This file

- ~/.claude/CLAUDE.md — Claude Code-specific additions
- Shared conventions live in `~/.config/AGENTS.md`
- "Make a note" or "Remember to" => edit AGENTS.md (shared) or this file (Claude-specific)

## Doctests

**Every non-trivial function needs doctests.** They serve triple duty:
- Executable documentation (always up-to-date)
- Regression tests (run with pytest --doctest-modules)
- REPL examples (copy-paste to explore)

Priority: pure functions, utilities, core algorithms. Skip: async, I/O-heavy, trivial getters.

## Multi-Agent / Multi-Step Work

- **Max 3-4 specialized agents** - more decreases quality
- **Isolate heavy output**: tests, logs, exploratory work in subagents; keep main thread clean
- **Before multi-step work**: write `working-spec.md` (goal, constraints, acceptance criteria). Reference across steps. Delete when complete.

## Claude Code Patterns

- **MCP minimalism**: prefer CLI tools (`gh`, `curl`, `sqlite3`) over MCPs — less context pollution
- **Screenshot prompting**: for UI work, paste screenshots — images > verbose text descriptions
- **Test in same context**: write tests alongside changes, don't fragment into separate agent calls
- **Interrupt pattern**: escape + "what's the status?" to redirect when agent drifts
