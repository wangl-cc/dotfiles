---
name: uv-python-script
description: Create, edit, run, format, and check a session-owned standalone Python script outside a configured project with uv. Use for PEP 723 or uv run --script workflows; skip project-owned files and third-party scripts that should run unchanged.
---

# uv Python Scripts

## Scope

- Use for a session-owned standalone Python file outside a configured project. Also follow the Python reference for language-level guidance; its uv-managed project subsection does not apply merely because a standalone script uses `uv run --script`.
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

For review or check-only work, do not reformat the file; use `uv format --no-project --check -- path/to/script.py` and `uv check --script path/to/script.py`.

For an authorized edit, run the applicable steps in this order:

1. `uv format --no-project -- path/to/script.py`
2. `uv check --script path/to/script.py`
3. Inspect the script's interface, then use `uv run --script path/to/script.py --help` only when `--help` is supported and side-effect-free.
4. Exercise the changed behavior through a dry-run or another low-risk path when one is available.

Report the exact uv commands run and their results.
