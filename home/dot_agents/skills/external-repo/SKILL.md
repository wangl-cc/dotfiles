---
name: external-repo
description: Inspect an external repository locally. Use when official docs or lightweight web review are not enough and you need code-level investigation of a library or open-source repo.
---

# External Repo Inspect

## When to Use This Skill

- The user needs code-level investigation of an external repository.
- Official docs, web search, or lightweight remote browsing are not enough.
- Understanding behavior requires reading actual source structure, symbols, or implementation details.
- A large repository should be inspected locally for better search and navigation.

Do not use this skill for routine API lookup or when official docs already answer the question.

## Workflow

1. Confirm that local project files and lightweight external sources are insufficient.
2. Check whether a corresponding local clone already exists in the current workspace or a suitable nearby scratch location.
3. Confirm that the current workspace is the right place for a temporary `.scratch/` research clone.
4. If no suitable local clone exists, clone the external repository into the current workspace's `.scratch/` directory.
5. Prefer a shallow clone unless deeper history is clearly needed.
6. Inspect the cloned repository locally using normal read/search tools.
7. Report findings with clear separation between:
   - local project observations
   - external repository observations
   - official docs or web sources

## Boundaries

- Use `.scratch/` only as a temporary research workspace, not as part of the real project.
- Do not modify the user's main project to integrate the external repository unless explicitly asked.
- Do not treat the cloned repository as part of the user's project or mix it into normal project changes.
- Do not assume the external repository is authoritative for the user's exact installed version without noting version uncertainty.
- Do not clone large repositories by default; clone only when code-level inspection is genuinely needed.

## Output

Return a concise summary with:

- what repository was inspected
- where it was cloned locally
- what was found
- any version or confidence caveats
