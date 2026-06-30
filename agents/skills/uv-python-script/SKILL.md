---
name: uv-python-script
description: Create, edit, run, format, and check standalone single-file Python scripts outside a Python project with uv. Use before creating or running PEP 723 or uv run --script scripts; skip third-party scripts that should be followed as-is.
---

# uv Python Scripts

## Scope

- Applies to single-file Python scripts created, edited, or run in this session.
- Prefer `uv-python-project` when the file is project-owned: a repository with `pyproject.toml`, `.venv`, packages, tests, or lockfiles.
- Prefer third-party instructions when a script is external and should be run as-is.

## Rules

- Run standalone scripts with `uv run --script`, not system `python3`.
- New standalone scripts should use PEP 723 inline metadata when they need dependencies or a specific Python version.
- Do not use `python3 -m py_compile` for validation.

## New Scripts

Example PEP 723 shape for a self-contained script:

```python
#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "click==8.1.8",
# ]
# ///
```

Pin direct dependencies exactly unless a range is intentional. Match `requires-python` to the script syntax and write modern Python for that version, such as `match`, `str | None`, `list[str]`, and `Path`-based filesystem code. Add a focused CLI library such as `click` when it makes parsing clearer than handwritten plumbing.

## Run

```bash
uv run --script path/to/script.py --help
uv run --script path/to/script.py <args>
```

## Format

```bash
uv format --no-project -- path/to/script.py
uv format --check --no-project -- path/to/script.py
```

## Check

```bash
uv check --script path/to/script.py
```

## Validation

For script changes, prefer this sequence:

1. `uv format --no-project -- path/to/script.py`
2. `uv check --script path/to/script.py`
3. `uv run --script path/to/script.py --help`
4. A dry-run or low-risk command path that exercises the changed behavior.

Report which uv commands were run and whether they passed.
