---
name: create-skill
description: Create or revise an agent skill. Use when the user wants to add a new skill, improve an existing skill, define trigger conditions, design SKILL.md structure, or decide whether a skill should include scripts, references, or examples.
---

# Create Skill

Create a focused, maintainable skill.

## Placement

- Put global skills in the environment's global skill directory and project-local skills in the repository-defined location.
- Follow existing layout conventions; use lowercase hyphenated names and `SKILL.md` as the entry point.

## Before Writing

- Define the skill's purpose, trigger, boundaries, expected output, and any required assets from the request and local conventions.
- Keep one skill responsible for one coherent task; split unrelated workflows.
- Add scripts only when automation is more reliable than instructions, references only for occasional detail, and examples only when they improve correctness.

## Frontmatter Rules

Use YAML frontmatter:

```yaml
---
name: skill-name
description: Briefly state what the skill does and when to use it.
---
```

Frontmatter should:

- keep `name` equal to the folder name;
- state both what the skill does and when to use it in a concise, trigger-friendly `description`.

## Review

Confirm the purpose and trigger are explicit, instructions are concise and actionable, the name matches its folder, and extra assets are necessary.
