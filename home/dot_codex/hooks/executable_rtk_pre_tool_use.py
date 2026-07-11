#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Rewrite Codex Bash tool calls through RTK when RTK supports them."""

import json
import subprocess
import sys
from typing import Any

# TODO: Remove this adapter and call `rtk hook codex` directly from hooks.json
# once RTK provides a Codex-compatible PreToolUse protocol handler.


def read_command() -> str | None:
    try:
        payload: Any = json.load(sys.stdin)
    except (json.JSONDecodeError, OSError):
        return None

    if not isinstance(payload, dict) or payload.get("tool_name") != "Bash":
        return None

    tool_input = payload.get("tool_input")
    if not isinstance(tool_input, dict):
        return None

    command = tool_input.get("command")
    return command if isinstance(command, str) else None


def rewrite(command: str) -> str | None:
    try:
        result = subprocess.run(
            ["rtk", "rewrite", command],
            check=False,
            capture_output=True,
            text=True,
        )
    except OSError:
        return None

    rewritten = result.stdout.strip()
    if result.returncode not in {0, 3} or not rewritten or rewritten == command:
        return None
    return rewritten


command = read_command()
if command is not None and (rewritten := rewrite(command)) is not None:
    json.dump(
        {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "allow",
                "permissionDecisionReason": "RTK auto-rewrite",
                "updatedInput": {"command": rewritten},
            }
        },
        sys.stdout,
    )
    sys.stdout.write("\n")
