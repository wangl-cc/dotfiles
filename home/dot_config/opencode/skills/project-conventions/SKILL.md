---
name: project-conventions
description: Capture or refresh persisted project conventions. Use when the user wants to initialize AGENTS.md, project style, validation commands, or tool preferences so agents stop rediscovering rules each session.
---

# Project Conventions

Use this skill to turn repeated project discovery into durable guidance that
future agents can read directly.

## When to Use This Skill

- The user asks to initialize, capture, refresh, or persist project rules.
- The user says agents keep rediscovering project style or validation commands.
- The user wants an `AGENTS.md`, conventions file, or project profile.
- The user wants common validation commands and tool preferences for a project.

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
   - project-local validation commands agents should prefer for checks, tests,
     builds, documentation, and spelling
   - commit message style and review expectations
4. Prefer project-native commands over ephemeral runners. Use ephemeral runners
   only when the project has no pinned tool:
   - JS/TS CLI tools: `bunx <tool>`
   - Python CLI tools: `uvx <tool>`
   - Other tools: use an existing command on `PATH` or ask before introducing a
     new installer or package-manager path.
5. Ask before writing when a rule is inferred, opinionated, or would change the
   user's workflow.
6. After writing, tell the orchestrator to reuse the persisted guidance and use
   focused local inspection only when the persisted guidance is missing, stale,
   conflicting, or insufficient.

## Validation Commands

This skill records which validation commands are correct for the project. It
does not treat project-local permission as a security boundary. Global opencode
permission controls the user's baseline trust policy; project guidance should
explain what to run, not silently expand what may run.

For unfamiliar or third-party repositories, document commands but do not infer
that they are safe. If the user wants different permission behavior, surface it
as an explicit configuration choice rather than burying it in project
conventions.

### Common commands to record

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

### Commands to label with risk

- Long-running, networked, deployment, migration, publish, install, or external
  service commands.
- Destructive filesystem commands.
- VCS history destruction or force push.
- In-place fix modes unless the user explicitly asks: `--fix`, `--write`,
  `--write-changes`, `-w`, `cargo clippy --fix*`.

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

## Command Risk

- Preferred validation commands: ...
- Risky or long-running commands: ...
- Commands not to run without explicit user intent: ...

## Style and Review

- ...
```
