---
name: project-conventions
description: Capture or refresh persisted project conventions. Use when the user wants to initialize AGENTS.md, project style, validation commands, tool preferences, or permission guidance so agents stop rediscovering rules each session.
---

# Project Conventions

Use this skill to turn repeated project discovery into durable guidance that
future agents can read directly.

## When to Use This Skill

- The user asks to initialize, capture, refresh, or persist project rules.
- The user says agents keep rediscovering project style or validation commands.
- The user wants an `AGENTS.md`, conventions file, or project profile.
- The user wants common validation commands and permission recommendations for a project.

Do not use this skill for ordinary implementation work, one-off lint failures,
or broad codebase exploration unless the goal is to write durable project
guidance.

## Preferred Output Location

Use the narrowest durable file that future agents will actually read:

1. Existing project `AGENTS.md`, if present.
2. New project `AGENTS.md`, for compact repo-wide rules.
3. A referenced file such as `docs/conventions.md` when the content is too long
   for `AGENTS.md`.

Keep global user preferences in global agent instructions, not in a project
file. Keep project-specific conventions in the project.

## Workflow

1. Inspect existing durable guidance before searching elsewhere:
   `AGENTS.md`, `CLAUDE.md`, `README`, `CONTRIBUTING`, `.opencode/`,
   formatter/linter config, package metadata, lockfiles, CI, `Makefile`,
   `justfile`, `Taskfile`, and language-specific config.
2. Separate observed facts from inferred conventions.
3. Capture only stable, reusable rules:
   - project purpose and non-goals
   - source layout and generated-file boundaries
   - dependency manager and toolchain preferences
   - formatting, linting, type-checking, testing, and documentation commands
   - common validation commands for JS/TS, Python, Rust, Markdown, JSONC, and
     spelling when applicable
   - project-local commands the user trusts enough to allow without repeated
     prompts, including tests or build commands that execute project code
   - commit message style and review expectations
4. Prefer project-native commands over ephemeral runners. Use ephemeral runners
   only when the project has no pinned tool:
   - JS/TS CLI tools: `bunx <tool>`
   - Python CLI tools: `uvx <tool>`
   - Tools pinned by aqua: `aqua exec -- <tool>`
5. Ask before writing when a rule is inferred, opinionated, or would change the
   user's workflow.
6. After writing, tell the orchestrator to reuse the persisted guidance and use
   focused local inspection only when the persisted guidance is missing, stale,
   conflicting, or insufficient.

## Trusted Project Permissions

The global allow list should cover broadly safe commands. This skill is for the
project-specific layer: when the user says the project is trusted, write durable
project-local permission rules that allow the commands they expect agents to run
without asking every time.

Do not add these trust rules globally by default. Put them in the project's
opencode config, such as `opencode.jsonc`, `.opencode/opencode.jsonc`, or the
location already used by that project.

### Common trusted-project allow rules

Use the package manager and commands that the project actually uses.

- JS/TS: `bun test*`, `bun run test*`, `bun run lint*`,
  `bun run typecheck*`, `bun run build*`, or the equivalent `npm`/`pnpm`/`yarn`
  scripts when those are the project standard.
- Python: `uv run pytest*`, `uvx pytest*`, `pytest*`, `uv run ruff check*`,
  `uv run mypy*`, `uv run pyright*`.
- Rust: `cargo test*`, `cargo +nightly test*`, `cargo check*`,
  `cargo +nightly check*`, `cargo clippy*`, `cargo +nightly clippy*`,
  `cargo doc*`, `cargo +nightly doc*`.
- Documentation and spelling: project-native docs build commands and `typos*`
  when accepted by the project.

### Still ask or deny by default

- Long-running, networked, deployment, migration, publish, install, or external
  service commands unless the user explicitly includes them in the trust profile.
- Destructive filesystem commands.
- VCS history destruction or force push.
- In-place fix modes unless the user explicitly asks: `--fix`, `--write`,
  `--write-changes`, `-w`, `cargo clippy --fix*`.

### Example project permission block

```jsonc
{
  "permission": {
    "bash": {
      "*": "ask",
      "cargo test*": "allow",
      "cargo +nightly test*": "allow",
      "cargo check*": "allow",
      "cargo +nightly check*": "allow",
      "cargo clippy*": "allow",
      "cargo +nightly clippy*": "allow",
      "cargo doc*": "allow",
      "cargo +nightly doc*": "allow",
      "cargo clippy *--fix*": "ask",
      "cargo +nightly clippy *--fix*": "ask"
    }
  }
}
```

## JSONC Validation

Prefer a tool that matches the real consumer.

- For opencode config, prefer `opencode debug config*` because it exercises the
  actual loader.
- Do not use `python -m json.tool` for JSONC; it rejects comments and trailing
  commas.
- If only syntax checking is needed, use a JSONC-aware parser or a formatter
  that explicitly supports JSONC.

## Output Template

When drafting persisted guidance, keep it compact:

```markdown
# Project Agent Instructions

## Project Context

- ...

## Layout and Boundaries

- ...

## Tooling and Validation

- Format: ...
- Lint: ...
- Type check: ...
- Test: ...
- Docs: ...

## Permissions and Command Risk

- Safe to run without asking: ...
- Ask first: ...
- Never run: ...

## Style and Review

- ...
```
