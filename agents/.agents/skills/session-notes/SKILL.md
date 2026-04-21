---
name: session-notes
description: |
  Summarize a work session from git history, diffs, and current state, then append durable notes
  for the next session.
  Use when signing off, ending the day, or when the user wants a concise session summary.
---

# Session Notes

Summarize what actually happened, not what you vaguely remember.

## 1. Gather Session Activity

Collect evidence such as:

- recent commit history
- `git diff --stat` for committed and uncommitted work
- active uncommitted changes
- relevant planning docs that changed

## 2. Summarize By Theme

Group work by theme rather than by commit order:

```markdown
### What Changed
- **<theme>**: <1-line summary> (<files or areas touched>)
- Uncommitted: <what is still in progress>
```

## 3. Extract Findings And Decisions

Identify:

- findings or discoveries
- decisions and tradeoffs
- assumptions not yet verified

## 4. Identify Open Questions

List:

- blockers
- unresolved questions
- known failing checks
- missing external input

## 5. Suggest Next Steps

Propose 2-3 concrete next actions.

Prefer:

- specific files, functions, or commands
- immediate resume actions

Avoid:

- vague continuation language

## 6. Ask For User Notes

Ask whether the user wants to add anything for next time.

## 7. Append To Progress File

Use this file-selection rule:

1. if `agent-progress.txt` exists, append there
2. else if `claude-progress.txt` exists, append there to preserve history
3. else create `agent-progress.txt`

Append:

```markdown
## Session: [YYYY-MM-DD HH:MM]

### What Changed
- <grouped changes>

### Findings
- <what was learned>

### Decisions
- <choices and rationale>

### Open Questions
- <unresolved items>

### Next Steps
1. <specific action>
2. <specific action>

### User Notes
- <anything the user added>
```

## 8. Confirm

Show the summary and state which file was updated.

## Key Principles

- **Read, don't recall.** Use git history and file diffs, not memory.
- **Group by theme.** "3 commits fixing order state machine" not 3 separate bullets.
- **Be specific.** File names, function names, test counts — not vague summaries.
- **Uncommitted work is important.** Flag it prominently so it's not forgotten.
