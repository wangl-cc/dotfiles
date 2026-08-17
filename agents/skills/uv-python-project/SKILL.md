---
name: uv-python-project
description: Work on Python projects with uv. Use for repositories with pyproject.toml, uv.lock, package directories, dependency groups, .venv environments, uv sync/run/add/remove/lock workflows, or project-level tests and validation.
---

# uv Python Projects

## Scope

- Use for project-owned Python code and configuration, including `pyproject.toml`, `uv.lock`, `.venv`, packages, dependency groups, extras, and tests.
- Use `uv-python-script` instead for a standalone single-file PEP 723 script; follow its publisher's instructions for an external script that must run unchanged.

## Workflow

- Read the project's documented commands and configuration first, then run project code and tools through `uv run`.
- Use `uv sync` only to create or refresh the project environment; use the project's group or extra selection when documented.
- Use `uv add` or `uv remove` only for an intentional dependency change, and use `uv lock` when that change or an explicit resolution refresh requires it.
- Preserve the project's uv configuration, dependency groups, extras, and lockfile conventions; do not introduce uv metadata or change the lockfile without a task need.
- Match `requires-python` and the project's declared Python version; do not reduce supported syntax for an unrelated system interpreter.

## Validation

- Prefer the project's documented formatter, checker, type checker, and test commands; run them with `uv run` where applicable.
- Otherwise use `uv format --check` and `uv check`, then the focused project test command.
- Report the exact uv commands run and their results.
