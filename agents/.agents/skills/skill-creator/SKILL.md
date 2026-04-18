---
name: skill-creator
description: |
  Create, edit, and iterate on skills. Use whenever the user wants to scaffold a new
  skill, improve an existing one, tune a skill's triggering description, or plan bundled
  resources (scripts, references, assets). Trigger on phrases like "make a skill",
  "turn this into a skill", "update this skill", "my skill isn't triggering", or any
  request that produces a reusable workflow another AI agent should follow.
---

# Skill Creator

Guidance for creating skills that any compatible AI agent (Claude Code, Codex, OpenCode,
Claude.ai, etc.) can load and run. A skill is a self-contained package — a SKILL.md plus
optional bundled resources — that transforms a general-purpose agent into a specialized
one by injecting procedural knowledge, domain context, and reusable code.

## When the user asks for a skill

Figure out where the user is in the lifecycle and jump in there:

- No draft yet: capture intent, plan resources, initialize, then write SKILL.md.
- Has a draft: focus on editing, tightening, and (if useful) testing.
- Updating an existing skill: preserve the original name and directory. Copy to a
  writable location before editing if the installed path is read-only.
- Wants to fix triggering: focus on the description (see "Description Optimization").

Stay flexible. If the user says "just vibe with me", skip the formal process.

## Core Principles

### Concise Is Key

The context window is shared by system prompt, conversation, other skills' metadata, and
the actual user request. Only add context the agent does not already have. Challenge each
sentence: "Does this paragraph justify its token cost?" Prefer concise examples over
verbose explanations.

### Explain the Why, Not Heavy-Handed MUSTs

Modern LLMs have good theory of mind. When you explain *why* something matters, the agent
can generalize to edge cases. Rigid ALWAYS/NEVER instructions are a yellow flag; reframe
and explain the reasoning instead. Reserve imperative MUSTs for genuinely fragile steps
where deviation causes real harm.

### Set Appropriate Degrees of Freedom

Match specificity to the task's fragility:

- **High freedom (prose instructions)**: multiple valid approaches, context-dependent
  decisions, heuristic choices.
- **Medium freedom (pseudocode, parameterized scripts)**: a preferred pattern exists,
  some variation is acceptable.
- **Low freedom (specific scripts, few parameters)**: fragile operations where
  consistency is critical.

Think of the agent exploring a path: narrow bridges need guardrails; open fields don't.

### Principle of Lack of Surprise

Skills must not contain malware, exploit code, credential theft, or content that could
compromise system security. Nothing in a skill should surprise the user relative to its
stated purpose. Decline requests to create misleading skills or skills designed to
facilitate unauthorized access or data exfiltration.

## Anatomy of a Skill

```
skill-name/
├── SKILL.md                    (required)
│   ├── YAML frontmatter        (name, description — required)
│   └── Markdown body           (instructions)
└── Optional bundled resources:
    ├── scripts/                executable code (Python, bash, etc.)
    ├── references/             documentation loaded on demand
    └── assets/                 files used in the agent's output
```

### SKILL.md

- **Frontmatter**: `name` and `description` only. These are the *sole* fields the agent
  sees when deciding whether to trigger the skill.
- **Body**: markdown. Loaded only *after* the skill triggers — putting "when to use this
  skill" in the body does nothing.

### scripts/

Executable code for tasks that are deterministic, repetitive, or otherwise benefit from
not rewriting the same code each invocation.

- Token efficient: the agent can execute scripts without reading them into context.
- Still readable: the agent can open them when patching or adjusting for environment.
- Test scripts before shipping — a broken script wastes every future invocation.

### references/

Markdown documentation the agent loads on demand.

- Keep SKILL.md lean; move detailed schemas, API docs, and long examples here.
- Reference each file from SKILL.md with a clear hint about when to read it.
- For files >100 lines, include a table of contents at the top.
- Avoid duplication: information lives in SKILL.md *or* in a reference, never both.

### assets/

Files the agent uses *in its output* (templates, boilerplate, images, fonts). Not loaded
into context, just copied or opened from scripts.

### What Not to Include

Skip README.md, INSTALLATION_GUIDE.md, CHANGELOG.md, and other auxiliary docs. A skill is
for an agent to do a job — not for humans to learn how it was built.

## Progressive Disclosure

Three tiers of loading:

1. **Metadata** (name + description): always in context (~100 words).
2. **SKILL.md body**: loaded when the skill triggers. Target <500 lines.
3. **Bundled resources**: loaded as needed; scripts can execute without loading.

### Pattern 1: High-level guide with references

```markdown
## Advanced features
- **Form filling**: see [references/forms.md]
- **API reference**: see [references/api.md]
- **Examples**: see [references/examples.md]
```

### Pattern 2: Domain organization

When a skill spans multiple domains or frameworks, split by variant so the agent reads
only the relevant file:

```
cloud-deploy/
├── SKILL.md          (workflow + provider selection)
└── references/
    ├── aws.md
    ├── gcp.md
    └── azure.md
```

### Pattern 3: Conditional details

Link to deep-dives only when specific features are invoked:

```markdown
For simple edits, modify the XML directly.

**For tracked changes**: see [references/redlining.md]
**For OOXML internals**: see [references/ooxml.md]
```

Keep references one level deep from SKILL.md — avoid nested chains.

## Skill Creation Process

### 1. Capture Intent

Extract answers from the conversation first; ask only what you cannot infer.

1. What should this skill enable the agent to do?
2. When should it trigger? (what user phrases or contexts)
3. What is the expected output format?
4. Are there verifiable outputs (file transforms, data extraction, deterministic code
   generation) that would benefit from test cases? Subjective outputs (style, art) often
   do not — let the user decide.

Wait to write the skill until you have concrete examples in hand. A vague skill becomes
a vague skill.

### 2. Plan Reusable Contents

For each concrete example, ask:

- What would the agent do from scratch?
- Which scripts, references, or assets would save work if bundled?

Example analysis for a `pdf-editor` skill:

- "Rotate this PDF" is rewritten often → bundle `scripts/rotate_pdf.py`.
- "Fill this form" needs schema discovery → bundle `references/form-fields.md`.
- "Brand this PDF" reuses templates → bundle `assets/cover-template.pdf`.

### 3. Initialize

If starting fresh, use `scripts/init_skill.py`:

```bash
scripts/init_skill.py <skill-name> --path <output-directory>
```

This creates the directory, a SKILL.md template, and example `scripts/`, `references/`,
`assets/` folders. Delete what you don't need — not every skill uses all three.

Skip this step if the skill already exists.

### 4. Edit

Write for another AI agent, not a human reader. Include procedural knowledge, domain
details, and gotchas that are non-obvious.

#### Frontmatter

```yaml
---
name: skill-name                # hyphen-case, matches directory
description: |                  # primary triggering mechanism
  What the skill does AND when to use it. Include concrete trigger phrases
  and contexts. Many agents under-trigger skills — lean slightly assertive:
  "Use whenever the user mentions X, Y, or Z, even if they don't explicitly
  ask for a 'skill'."
---
```

Keep descriptions specific and context-rich. Bad: `"Format this data"`. Good: `"Clean
and normalize messy spreadsheet data — column headers with typos, inconsistent date
formats, mixed types. Use when a user pastes tabular data or references an .xlsx/.csv
file that needs cleanup before analysis."`

#### Body

- Use imperative or infinitive form ("Extract the fields", "Run the script").
- Reference bundled resources explicitly with a hint about when to read them.
- Test every bundled script by running it.
- Delete placeholder files from init.

### 5. Package (optional)

For distribution as a single file:

```bash
scripts/package_skill.py <path/to/skill-folder>
```

Produces a `.skill` file (a zip with a `.skill` extension). The script validates
frontmatter, naming, and structure before packaging. Not every tool consumes `.skill`
files — many just read directories directly — so this step is optional.

### 6. Iterate

After real use, notice struggles or inefficiencies. The iteration loop is where skills
get good:

- **Generalize from feedback**: a skill should work across many prompts, not just the
  three test cases under your nose. Fix the pattern, not the instance. Fiddly,
  overfit edits are a warning sign.
- **Keep the prompt lean**: remove instructions that aren't pulling their weight. If the
  agent is wasting time on unproductive steps, cut the instructions that cause them.
- **Explain the why**: if you find yourself writing ALWAYS or NEVER in caps, reframe and
  explain the reasoning. The agent handles edge cases better when it understands
  motivation.
- **Bundle repeated work**: if multiple runs independently wrote similar helper scripts
  or took the same multi-step approach, that's a signal to bundle a script. Write it
  once; save every future invocation from reinventing it.

## Writing Patterns

### Strict output format

```markdown
## Report structure
ALWAYS use this exact template:

# [Title]
## Executive summary
## Key findings
## Recommendations
```

### Flexible output format

```markdown
## Report structure
A sensible default — adapt as needed:

# [Title]
## Summary
## Findings
## Recommendations
```

### Input/output examples

```markdown
## Commit message format

**Example 1:**
Input: Added user authentication with JWT tokens
Output: feat(auth): implement JWT-based authentication

**Example 2:**
Input: Fixed a bug where dates displayed wrong in reports
Output: fix(reports): correct timezone handling in date formatting
```

Examples communicate style faster than prose descriptions.

### Sequential workflow

```markdown
Filling a PDF form:

1. Analyze the form (run analyze_form.py)
2. Create field mapping (edit fields.json)
3. Validate mapping (run validate_fields.py)
4. Fill the form (run fill_form.py)
5. Verify output (run verify_output.py)
```

### Conditional workflow

```markdown
1. Determine the modification type:
   **Creating new content?** → follow "Creation workflow"
   **Editing existing content?** → follow "Editing workflow"
```

See `references/workflows.md` and `references/output-patterns.md` for more.

## Description Optimization

The description field decides whether the skill triggers at all. After the skill works
well, tune the description:

1. Write 16–20 realistic user queries: roughly half should trigger the skill, half
   should not.
2. Make the should-trigger queries cover different phrasings — formal, casual,
   implicit, and cases where the user doesn't name the skill or file type.
3. Make the should-not-trigger queries near-misses — queries sharing keywords but
   needing something else. "Write a fibonacci function" is a bad negative test for a
   PDF skill; it's too easy to reject.
4. Manually evaluate the current description against the queries, or use a tool-specific
   loop (e.g., Claude Code's `claude -p` CLI) if available.
5. Revise the description based on failures. Iterate.

Note: simple one-step queries ("read this file") may not trigger any skill because the
agent handles them directly. Test queries should be substantive enough that the agent
would genuinely benefit from the skill's guidance.

## Tool-Specific Notes

This skill ships as a portable directory symlinked into each tool's skill root:

- **Claude Code**: `~/.claude/skills/<name>/` — triggered by description match.
- **Codex**: `~/.codex/skills/<name>/` — same SKILL.md format.
- **OpenCode**: `~/.config/opencode/skills/<name>/` — same.

Differences to keep in mind when writing skills:

- Subagent availability varies. Don't hard-code "spawn a subagent" as a required step;
  phrase it as "delegate to a subagent if available, otherwise run inline".
- Display/browser availability varies. Don't assume the agent can `open` HTML in a
  browser; offer a file-based fallback ("write `report.html`, tell the user the path").
- CLI tools vary. Anything like `claude -p` is Claude-Code-specific. Gate tool-specific
  instructions behind "if your environment provides X".

When in doubt, write the skill in terms of *capabilities* ("if you can run scripts in
parallel, do so"), not *specific tools*.

## Reference Files

- `references/workflows.md` — sequential and conditional workflow patterns
- `references/output-patterns.md` — template, example, and formatting patterns
