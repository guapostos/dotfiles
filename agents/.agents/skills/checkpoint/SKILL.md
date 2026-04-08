---
name: checkpoint
description: |
  Save or restore a compact working-state snapshot for later resumption.
  Use when the user wants to save progress, resume a prior thread, list checkpoints,
  or preserve context before risky work or a long pause.
---

# Checkpoint

Capture and restore working state without depending on conversation history.

## Storage

Use:

```bash
CHECKPOINT_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/agents/checkpoints"
```

Create the directory if needed.

## Save

When saving a checkpoint:

1. Choose a short kebab-case name if the user did not provide one.
2. Create a file named `<name>-<YYYYMMDD-HHMM>.md` in `CHECKPOINT_DIR`.
3. Write:

```markdown
# Checkpoint: <name>
Date: <timestamp>
CWD: <pwd>

## Goal
<1-2 sentence summary>

## Current State
- <what is working or verified>
- <files changed>
- Diff stat: <git diff --stat summary>
- Last known green commit: <sha or "unknown">

## Key Decisions
- <decision and rationale>

## Gotchas
- <pitfalls, failed approaches, or caveats>

## Next Steps
- <specific resume actions>
```

4. Confirm the saved path.

## Load

When loading a checkpoint:

1. Search `CHECKPOINT_DIR` for matching files.
2. If no query is provided, use the most recent checkpoint.
3. If multiple matches are plausible, show the shortlist and ask which one to load.
4. Read the selected file.
5. Summarize the goal, current state, and next steps before resuming work.

## List

When the user asks to list checkpoints, show the newest entries first with:

- timestamp
- checkpoint name
- path

## Suggestions

Suggest checkpointing when:

- context is getting noisy
- the task is about to branch in multiple directions
- risky edits are about to start
- the user is signing off and may resume later
