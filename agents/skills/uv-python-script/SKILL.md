---
name: uv-python-script
description: Create, edit, run, format, and check standalone single-file Python scripts outside a Python project with uv. Use before creating or running PEP 723 or uv run --script scripts; skip third-party scripts that should be followed as-is.
---

# uv Python Scripts

## Scope

- Use for a standalone, session-owned Python file; use `uv-python-project` for files owned by a repository with project configuration, packages, tests, or a lockfile.
- Follow a third-party script's instructions and leave it unchanged unless the task authorizes modifying it.

## Script Shape

- Run standalone scripts with `uv run --script`; add PEP 723 metadata when the script needs dependencies or a specific Python version.

```python
#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
```

- Match `requires-python` to the syntax the script uses.

## Validation

Run this order for an edited script:

1. `uv format --no-project -- path/to/script.py`
2. `uv check --script path/to/script.py`
3. `uv run --script path/to/script.py --help`
4. A dry-run or low-risk command path that exercises the changed behavior.

Report the exact uv commands run and their results.
