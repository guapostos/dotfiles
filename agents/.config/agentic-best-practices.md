# Agentic Coding Best Practices

Cross-vendor best practices synthesized from Anthropic, OpenAI, and Google documentation.
Last updated: 2026-03-09. Refresh with `scripts/refresh-best-practices.sh`.

## Instruction Files

- **Under 200 lines** — bloated files degrade adherence; split with imports if needed
- **Only include what the agent can't infer** from reading the code itself
- **Be concrete and verifiable** — "use 2-space indentation for TS" not "format properly"
- **Specify build/test/lint commands** — highest-leverage thing you can include
- **State tool preferences explicitly** — e.g., "use `gh` not raw API calls"
- **Use layered hierarchy** — global (user prefs) → project root (team standards) → subdirectory (component rules)
- **Version control** instruction files; review after agent failures; prune regularly
- **Use emphasis sparingly** — "IMPORTANT", "MUST" only for rules that keep getting violated

## Workflow

- **Separate exploration from implementation** — read/plan first, then implement
- **Trivial tasks**: just do it. **Multi-file changes**: plan first. **5+ files**: working spec
- **Provide verification criteria** — tests, expected output, screenshots. Without these, you are the only feedback loop
- **Test-driven**: write tests first, implement until they pass
- **One feature at a time** — complete, test, commit before starting next

## Context Management

- **Clear context between unrelated tasks** — saturation is the #1 failure mode
- **Delegate investigation to subagents** — keep main context clean
- **Never paste long repetitive output** — summarize patterns instead
- **Scope investigations narrowly** — unscoped "investigate" fills context with noise

## Hooks Over Instructions

- Instructions are advisory; hooks are deterministic
- **Must-run actions** (formatting, linting, security) → use hooks, not text instructions
- Reserve instructions for judgment calls and preferences

## Common Pitfalls

| Pitfall | Fix |
|---------|-----|
| Kitchen sink session (unrelated tasks accumulate) | Clear context between tasks |
| Over-specified instructions (agent ignores half) | If agent does it correctly without the instruction, delete it |
| Correct-and-repeat loop (same fix 3+ times) | Stop, clear context, write better prompt |
| Trust-then-verify gap (plausible but wrong) | Always provide verification (tests, scripts) |
| Conflicting instructions across layers | Audit periodically |
| Redundant instructions (stating language defaults) | Only include deviations |

## Sources

- [Anthropic: Claude Code Best Practices](https://code.claude.com/docs/en/best-practices)
- [Anthropic: CLAUDE.md / Memory Guide](https://code.claude.com/docs/en/memory)
- [OpenAI: Codex AGENTS.md Guide](https://developers.openai.com/codex/guides/agents-md/)
- [OpenAI: Codex Prompting Guide](https://developers.openai.com/cookbook/examples/gpt-5/codex_prompting_guide/)
- [Google: Gemini CLI GEMINI.md](https://google-gemini.github.io/gemini-cli/docs/cli/gemini-md.html)
