---
name: next
description: |
  Resume work on a project by discovering current state, running focused verification,
  cleaning stale planning notes, and proposing the next tasks.
  Use when starting a session, after a long work loop, or when the user asks what to do next.
---

# Next

Resume work from repository reality, not memory.

## 1. Gather Context

Read planning files if they exist:

- `README.md`
- `PLAN.md`
- `SPEC.md`
- `TODO.md`

Also inspect:

- `git status`
- recent commits
- uncommitted changes

## 2. Discover Verification

Find the verification commands from the nearest useful source:

1. `README.md`
2. `pyproject.toml`
3. `Makefile`
4. `package.json`

Run the narrowest meaningful verification first, then broader checks if needed.

Typical checks:

- tests
- types
- lint

## 3. Clean Planning Docs

Auto-fix low-risk drift such as:

- outdated passing-test counts
- duplicated checklist items
- items marked in progress that are clearly complete

Ask the user before making judgment calls about roadmap direction or ambiguous status.

## 4. Summarize Project State

Use a brief summary:

```markdown
## Project State
- Health: [tests/types/lint status]
- Current: [active work or recent completion]
- Cleaned: [doc updates or stale note cleanup]

## Next Options
1. [most logical next task]
2. [alternative path]
3. [another useful option]
```

Wait for the user to choose direction before doing more work, unless they already made the next step explicit.
