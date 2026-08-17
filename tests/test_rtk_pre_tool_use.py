#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Fixture tests for the cross-harness RTK PreToolUse adapter."""

import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path
from typing import Any

HOOK = Path(__file__).parents[1] / "home/dot_local/bin/rtk-pre-tool-use"
RTK_STUB = """#!/bin/sh
case "$2" in
  "allow me")
    printf '%s\\n' 'rtk git status'
    exit 0
    ;;
  "ask me")
    printf '%s\\n' 'rtk git push'
    exit 3
    ;;
  "deny me")
    printf '%s\\n' 'rtk echo must-not-run'
    exit 2
    ;;
  *)
    exit 1
    ;;
esac
"""


class RtkPreToolUseTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temp_dir = tempfile.TemporaryDirectory()
        stub = Path(self.temp_dir.name) / "rtk"
        stub.write_text(RTK_STUB)
        stub.chmod(0o755)
        self.env = os.environ.copy()
        self.env["PATH"] = f"{self.temp_dir.name}:{self.env['PATH']}"

    def tearDown(self) -> None:
        self.temp_dir.cleanup()

    def run_hook(
        self, harness: str, payload: dict[str, Any] | str
    ) -> subprocess.CompletedProcess[str]:
        raw = payload if isinstance(payload, str) else json.dumps(payload)
        return subprocess.run(
            [str(HOOK), harness],
            input=raw,
            capture_output=True,
            text=True,
            check=False,
            env=self.env,
        )

    def test_antigravity_preserves_rtk_allow(self) -> None:
        proc = self.run_hook(
            "antigravity", {"toolCall": {"args": {"CommandLine": "allow me"}}}
        )

        self.assertEqual(proc.returncode, 0, proc.stderr)
        self.assertEqual(
            json.loads(proc.stdout),
            {
                "decision": "allow",
                "overwrite": {"CommandLine": "rtk git status"},
            },
        )

    def test_antigravity_preserves_rtk_ask(self) -> None:
        proc = self.run_hook(
            "antigravity", {"toolCall": {"args": {"CommandLine": "ask me"}}}
        )

        self.assertEqual(proc.returncode, 0, proc.stderr)
        self.assertEqual(
            json.loads(proc.stdout),
            {
                "decision": "ask",
                "overwrite": {"CommandLine": "rtk git push"},
            },
        )

    def test_antigravity_defers_without_a_usable_rewrite(self) -> None:
        payloads: list[dict[str, Any] | str] = [
            {"toolCall": {"args": {"CommandLine": "no rewrite"}}},
            {"toolCall": {"args": {"CommandLine": "deny me"}}},
            {"toolCall": {"args": {"CommandLine": "rtk git status"}}},
            "not json",
        ]

        for payload in payloads:
            with self.subTest(payload=payload):
                proc = self.run_hook("antigravity", payload)
                self.assertEqual(proc.returncode, 0, proc.stderr)
                self.assertEqual(json.loads(proc.stdout), {"decision": "ask"})

    def test_codex_rewrites_only_rtk_allow(self) -> None:
        allow = self.run_hook(
            "codex",
            {"tool_name": "Bash", "tool_input": {"command": "allow me"}},
        )
        ask = self.run_hook(
            "codex",
            {"tool_name": "Bash", "tool_input": {"command": "ask me"}},
        )
        deny = self.run_hook(
            "codex",
            {"tool_name": "Bash", "tool_input": {"command": "deny me"}},
        )

        self.assertEqual(allow.returncode, 0, allow.stderr)
        self.assertEqual(
            json.loads(allow.stdout),
            {
                "hookSpecificOutput": {
                    "hookEventName": "PreToolUse",
                    "permissionDecision": "allow",
                    "permissionDecisionReason": "RTK allowlisted rewrite",
                    "updatedInput": {"command": "rtk git status"},
                }
            },
        )
        self.assertEqual(ask.returncode, 0, ask.stderr)
        self.assertEqual(ask.stdout, "")
        self.assertEqual(deny.returncode, 0, deny.stderr)
        self.assertEqual(deny.stdout, "")


if __name__ == "__main__":
    unittest.main()
