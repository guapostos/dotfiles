---
name: "prompt-search"
description: "Search your local AI coding assistant prompt history across Claude Code, Codex, Gemini CLI, and OpenCode. Use when you need to find a previous chat, recover an old prompt, or identify which session contained a topic."
disable-model-invocation: true
---

# Prompt Search

Search prompt history across the locally installed coding agents.

## When To Use It

- Find a previous conversation by keyword
- Recover the session ID for an old task
- Check which tool you used for a topic
- List recent sessions when you do not remember the search term

## Workflow

1. If the user gave search terms, run:

```bash
python3 ~/.agents/skills/prompt-search/scripts/search_prompt_history.py "$@"
```

2. If the user did not give terms, show recent sessions instead:

```bash
python3 ~/.agents/skills/prompt-search/scripts/search_prompt_history.py recent
```

3. Summarize the strongest matches for the user.

4. If the user wants to reopen one:
- Claude Code: `claude --resume SESSION_ID`
- Codex: `codex --resume SESSION_ID`
- OpenCode: `opencode --resume SESSION_ID` if supported by the installed version
- Gemini CLI: reopen the same project directory; Gemini restores the local project chat history

## Notes

- The script auto-detects whichever of Claude Code, Codex, Gemini CLI, and OpenCode are present on disk.
- Search is case-insensitive.
- The script searches local history stores only. It does not call remote APIs.
- Codex history on this machine lives under `~/.codex/`, not `~/.openai/codex/`.
