---
name: multi-mind
description: |
  Run a multi-perspective analysis with several specialist subagents or parallel passes,
  then cross-pollinate and synthesize the results.
  Use when the user wants a topic analyzed from distinct expert viewpoints.
---

# Multi-Mind

Execute a multi-specialist analysis that preserves disagreement instead of flattening it.

## Delegation Model

If your platform supports subagents or parallel delegation, use it.
If not, simulate the same structure with clearly separated sequential passes.

Default to 4-6 specialists unless the problem is narrow enough for fewer.

## Phase 1: Specialist Assignment

Choose specialists that cover distinct perspectives. Example roles:

- Technical specialist
- Business or market specialist
- User-experience specialist
- Risk or security specialist
- Historical or trend specialist

Selection criteria:

- materially different expertise
- different methods or evidence sources
- different time horizons
- different risk sensitivities

Each specialist prompt should include:

- the role and lens
- concrete focus areas
- a requirement to gather current evidence when freshness matters
- a requirement to produce findings, not generic commentary

## Phase 2: Independent Analysis

Have each specialist work independently first.

They should:

- gather evidence
- make domain-specific observations
- state assumptions
- flag uncertainty

## Phase 3: Cross-Pollination

After the first round, run a second pass where each specialist:

1. reviews summaries from the other specialists
2. identifies agreements and contradictions
3. challenges weak assumptions from their own perspective
4. extends useful findings rather than repeating them
5. surfaces blind spots

## Phase 4: Synthesis

Synthesize the results without erasing important disagreements.

Your synthesis should include:

- strongest shared conclusions
- highest-value disagreements
- remaining uncertainty
- implications for next actions or decisions

## Output Format

```text
=== MULTI-MIND ANALYSIS: [Topic] ===
Specialists: [List]

--- ROUND 1 ---
Knowledge acquisition
[specialist findings]

Specialist analysis
[specialist viewpoints]

--- ROUND 2 ---
Cross-pollination
[responses to each other]

--- FINAL SYNTHESIS ---
Shared conclusions
[what multiple specialists agree on]

Key disagreements
[important unresolved conflicts]

Remaining uncertainties
[what still needs evidence]

Implications
[what this means for decisions or next steps]
```

## Success Criteria

- each specialist contributes something distinct
- later rounds add new insight rather than rephrasing round 1
- the final synthesis preserves real disagreement
- the result is more useful than a single-agent summary
