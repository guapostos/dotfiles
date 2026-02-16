---
name: session-notes
description: |
  Auto-generate session summary: what changed, findings, open questions, next steps.
  Richer than /signoff — reads git history and conversation context automatically.
  Usage: /session-notes
---

# Session Notes: Auto-Generated Session Summary

Generate a detailed session summary by analyzing what actually happened, not what you remember happened.

## Process

### 1. Gather Session Activity

Run in parallel:
- `git log --oneline --since="8 hours ago"` (or since last session-notes entry)
- `git diff --stat HEAD~N` where N = commits this session
- `git diff` for any uncommitted work
- `git stash list` for stashed work
- Check for modified planning docs (NORTH_STAR.md, ROADMAP.md, PROMPT.md, TODO.md, PLAN.md)

### 2. Summarize Changes

Group commits by theme, not chronologically:
```
### What Changed
- **<theme>**: <1-line summary> (<files touched>)
- **<theme>**: <1-line summary> (<files touched>)
- Uncommitted: <what's in progress>
```

### 3. Extract Findings & Decisions

From conversation context, identify:
- **Findings**: things learned or discovered (bugs found, performance measured, API behavior observed)
- **Decisions made**: architectural choices, tradeoffs taken, approaches chosen/rejected with rationale
- **Assumptions**: anything assumed but not yet verified

### 4. Identify Open Questions & Blockers

- Questions raised but not answered
- Things that need external input (API access, data, user decision)
- Failing tests or known issues not yet fixed

### 5. Suggest Next Steps

Based on the session's trajectory, suggest 2-3 concrete next actions. Be specific:
- Not "continue working on X"
- Yes "implement the retry logic in `order_manager.py`, then run the integration test against paper trading endpoint"

### 6. Write to File

Append to `claude-progress.txt` (create if missing):

```
## Session: [YYYY-MM-DD HH:MM] (auto-generated)

### What Changed
- <grouped changes>

### Findings
- <what was learned>

### Decisions
- <choices made and why>

### Open Questions
- <unresolved items>

### Next Steps
1. <specific action>
2. <specific action>
```

### 7. Confirm

Output the summary to the user and note: "Session notes appended to `claude-progress.txt`."

## Key Principles

- **Read, don't recall.** Use git history and file diffs, not memory.
- **Group by theme.** "3 commits fixing order state machine" not 3 separate bullet points.
- **Be specific.** File names, function names, test counts — not vague summaries.
- **Uncommitted work is important.** Flag it prominently so it's not forgotten.
