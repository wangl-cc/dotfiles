---
name: create-skill
description: Create or revise an agent skill. Use when the user wants to add a new skill, improve an existing skill, define trigger conditions, design SKILL.md structure, or decide whether a skill should include scripts, references, or examples.
---

# Create Skill

Create a focused, maintainable skill.

## When to Use This Skill

Use this skill when the user wants to:

- create a new skill
- revise an existing skill
- turn a repeated workflow into a skill
- improve skill triggers or frontmatter
- decide whether a skill needs scripts, examples, or references

## Placement

- Global skills usually live in `~/.agents/skills/<skill-name>/`
- Project-specific skills can live in a repository-defined location
- The main file is `SKILL.md`
- Keep skill names lowercase with hyphens
- Prefer concise skills with one primary job
- If a skill is third-party, preserve license and source attribution separately

Do not assume one fixed layout. Follow the environment or repository conventions when they exist.

## Before Writing

Capture these points first:

1. **Purpose** — what exact task or workflow should this skill handle?
2. **Trigger** — when should the agent use it?
3. **Boundaries** — what should this skill explicitly not try to do?
4. **Output** — does it need a checklist, template, command sequence, or response format?
5. **Assets** — does it actually need `scripts/`, examples, or reference files?

If the user already described the workflow in the conversation, extract the answers from context instead of re-asking everything.

## File Layout

```text
skill-name/
└── SKILL.md
```

Add extra files only when they reduce repetition or improve reliability:

- `scripts/` for deterministic helper scripts
- `reference.md` or similar for longer material the model only needs occasionally
- example files only if they materially improve output quality

Do not add files just because a template allows them.

## Frontmatter Rules

Use YAML frontmatter:

```yaml
---
name: skill-name
description: Briefly state what the skill does and when to use it.
---
```

Frontmatter should:

- keep `name` equal to the folder name
- make `description` trigger-friendly
- describe both **what** the skill does and **when** it should activate

## Writing Rules

Follow these defaults:

1. **One skill, one job** — split unrelated workflows into separate skills.
2. **Short first** — keep `SKILL.md` compact; move detail out only if needed.
3. **Imperative guidance** — tell the agent what to do clearly.
4. **Concrete triggers** — mention user intents, phrases, or situations.
5. **Prefer defaults** — give one recommended path unless real branching is needed.
6. **Avoid filler** — do not explain generic concepts the model already knows.

## Recommended Structure

Use a structure like this when appropriate:

```markdown
---
name: my-skill
description: What it does. Use when the user asks for X, mentions Y, or needs Z.
---

# My Skill

## When to Use This Skill

- trigger one
- trigger two

## Workflow

1. Step one
2. Step two

## Output

Describe the expected final format if needed.
```

Not every skill needs every section, but every skill should make triggering and execution obvious.

## Decision Rules for Extra Files

- Add a script only when code execution is more reliable than prose.
- Add a reference file only when keeping everything in `SKILL.md` would make it bloated.
- Add examples only when they improve correctness, not just because examples are nice.

## Review Checklist

Before finishing, verify:

- the skill has a single clear purpose
- the trigger conditions are explicit
- the file and folder names match
- the workflow is concise and actionable
- optional assets are truly necessary
- the content matches the target environment or repository conventions

## Anti-Patterns

Avoid these:

- vague names like `helper` or `utils`
- broad skills that mix unrelated workflows
- long essays in `SKILL.md`
- duplicate instructions that belong in another skill
- adding scripts, assets, or references without a clear need
