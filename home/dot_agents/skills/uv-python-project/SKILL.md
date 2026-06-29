---
name: uv-python-project
description: Work on Python projects with uv. Use for repositories with pyproject.toml, uv.lock, package directories, dependency groups, .venv environments, uv sync/run/add/remove/lock workflows, or project-level tests and validation.
---

# uv Python Projects

## Scope

Default to uv for project management and command execution.

- Applies to project-owned Python code: `pyproject.toml`, `uv.lock`, `.venv`, package directories, dependency groups, extras, tests, and tools.
- Prefer `uv-python-script` for standalone single-file scripts with PEP 723 inline dependencies.

## Rules

- Prefer `uv run`, `uv sync`, `uv add`, `uv remove`, `uv lock`, `uv format`, and `uv check` over direct system `python3`, `pip`, or ad hoc virtualenv commands.
- Do not run project Python code with system `python3` unless the project explicitly documents that path.
- Do not use `python3 -m py_compile` as the project check.
- Preserve existing project configuration. Do not introduce uv metadata, dependency groups, or lockfile changes unless needed for the task.
- Match the project's declared Python version and write modern Python for that version. Do not downgrade syntax for an unrelated system Python.
- Match `requires-python` and write modern Python for that version, such as `match`, `str | None`, `list[str]`, and `Path`-based filesystem code. Add a focused CLI library such as `click` when it makes parsing clearer than handwritten plumbing.

## Commands

Inspect the project first:

```bash
uv --version
uv tree
```

Install or refresh the environment when needed:

```bash
uv sync
uv sync --all-groups
```

Run project commands through uv:

```bash
uv run python -m pytest
uv run pytest
uv run <tool> <args>
```

Manage dependencies through uv:

```bash
uv add <package>
uv add --dev <package>
uv remove <package>
uv lock
```

Follow existing dependency groups, extras, and lockfile conventions.

## Format and Check

Use uv's project-aware commands when available:

```bash
uv format
uv format --check
uv check
```

If the project already uses specific tools, run them through uv:

```bash
uv run ruff check .
uv run mypy .
uv run basedpyright
uv run pytest
```

Prefer documented validation commands over generic guesses.
Report the exact uv commands run and whether they passed.
