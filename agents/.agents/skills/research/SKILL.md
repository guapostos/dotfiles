---
name: research
description: |
  Research-first design workflow for implementation tasks.
  Use when the user wants architecture or implementation guidance grounded in current evidence
  and codebase context before writing code.
---

# Research

Research before implementation. Gather external context, internal codebase context, and likely failure modes before proposing architecture.

## Delegation Model

If your platform supports subagents or parallel work, use 3 research threads by default.
If not, perform the same threads sequentially and keep their outputs logically separate.

## 1. Clarify the Topic

If the topic is underspecified, ask a short clarifying question before starting.

## 2. Run Three Research Threads

### Thread 1: External Research

- gather current best practices
- find authoritative docs, papers, or primary sources
- prefer recent evidence when the topic changes quickly

### Thread 2: Codebase Analysis

- search the repository for existing patterns
- identify reusable code and prior art
- note conventions that the new work must fit

### Thread 3: Pitfalls And Edge Cases

- find common mistakes and failure modes
- identify edge cases
- call out operational or testing traps

Add extra threads only when the problem genuinely needs them.

## 3. Synthesize Findings

Merge the threads into a coherent summary:

- best practices
- relevant existing code
- risks and pitfalls
- tradeoffs surfaced by the research

## 4. Ask Targeted Questions

Ask 2-4 concrete questions only when the research reveals genuine choices the user should make.

## 5. Write A Design Note

Create `design-<topic-slug>.md` in the current working directory:

```markdown
# Design: <Topic>
Date: <timestamp>

## Goal
<1-2 sentence summary>

## Research Findings

### Best Practices
- <key findings>

### Existing Codebase
- <relevant patterns>
- <reusable components>

### Pitfalls To Avoid
- <common mistakes>
- <edge cases>

## Proposed Approach
<recommended architecture>

## Risks
- <risk and mitigation>

## Requirements
- Data: <needed data>
- APIs: <external services>
- Dependencies: <libraries or tools>

## Open Questions
- <remaining decisions>

## Next Steps
1. <first action>
2. <second action>
```

## 6. Confirm

Tell the user where the design note was written and summarize the most important tradeoff.
