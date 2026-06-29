---
name: external-repo
description: External repository research workflow. Use when local code, official docs, release notes, or web pages are insufficient and a task requires temporarily cloning or inspecting a third-party repository as read-only reference material.
---

# External Repository Research

Use this skill when local code plus lightweight external sources are not enough,
and answering the user requires inspecting a third-party repository.

## Workflow

1. Prefer lightweight sources first: local code, official docs, release notes,
   and web pages.
2. Clone an external repository only when those sources are insufficient, or
   when the exact implementation in that repository matters.
3. Reuse an existing checkout under `/tmp/external-repo-research/` when
   available; otherwise clone into `/tmp/external-repo-research/<repo-name>/`.
4. Treat `/tmp/external-repo-research/` as temporary read-only reference
   material:
   - do not edit external repository files
   - do not mix external paths into project-local findings unless explicitly
     relevant
   - do not commit, install dependencies, or run heavyweight setup unless the
     user specifically asks and the benefit is clear
5. Keep external findings separate from local observations.

## Output

When external repository material is used, report:

- repository URL and checkout path
- relevant files, symbols, or line numbers from the external repository
- how the external finding relates to the user's project or question
- remaining unknowns, especially when the checkout may not match the user's
  installed version

## Boundaries

- This skill is for research, not implementation.
- Do not recommend designs or fixes unless the user explicitly asked for a
  research-backed recommendation.
- Do not present external repository behavior as local project behavior.
