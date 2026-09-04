#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "click>=8.1,<9",
#   "pydantic>=2,<3",
#   "pyyaml>=6,<7",
# ]
# ///
"""Regression tests for the portable package helper."""

import importlib.machinery
import importlib.util
import shutil
import sys
import tempfile
import unittest
from pathlib import Path
from typing import Any

import yaml
from click.testing import CliRunner

sys.dont_write_bytecode = True
ROOT = Path(__file__).parents[1]
SCRIPT = ROOT / "home/dot_local/bin/portable-pkgs"
SOURCE_MANIFEST = ROOT / "home/.chezmoidata/portable-pkgs.yaml"
LOADER = importlib.machinery.SourceFileLoader("portable_pkgs_test", str(SCRIPT))
SPEC = importlib.util.spec_from_loader(LOADER.name, LOADER)
if SPEC is None:
    raise RuntimeError(f"cannot load {SCRIPT}")
MODULE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = MODULE
LOADER.exec_module(MODULE)


class FakeGitHubClient:
    def fetch_release(self, repo: str, tag: str) -> dict[str, Any]:
        return {
            "tag_name": "v11.25.0",
            "assets": [
                {
                    "name": "pnpm-darwin-arm64.tar.gz",
                    "digest": f"sha256:{'a' * 64}",
                },
                {
                    "name": "pnpm-linux-x64-musl.tar.gz",
                    "digest": f"sha256:{'b' * 64}",
                },
            ],
        }


class SemanticVersionTest(unittest.TestCase):
    def test_detects_stable_release_downgrade(self) -> None:
        self.assertTrue(MODULE.is_semantic_version_downgrade("v12.0.0", "v11.25.0"))

    def test_compares_prerelease_precedence(self) -> None:
        is_downgrade = MODULE.is_semantic_version_downgrade

        self.assertTrue(is_downgrade("v1.0.0", "v1.0.0-rc.1"))
        self.assertFalse(is_downgrade("v1.0.0-rc.1", "v1.0.0"))
        self.assertFalse(is_downgrade("v1.0.0+old", "v1.0.0+new"))

    def test_ignores_non_semantic_tags(self) -> None:
        self.assertFalse(MODULE.is_semantic_version_downgrade("nightly", "stable"))
        self.assertFalse(MODULE.is_semantic_version_downgrade("v1.0.0", "v1.0.0-rc.01"))
        self.assertFalse(MODULE.is_semantic_version_downgrade("v2.0.0", "v1٢.0.0"))


class UpdateDowngradeTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temp_dir = tempfile.TemporaryDirectory()
        self.manifest = Path(self.temp_dir.name) / "portable-pkgs.yaml"
        shutil.copyfile(SOURCE_MANIFEST, self.manifest)
        self.original_manifest_path = MODULE.MANIFEST_PATH
        self.original_github_client = MODULE.GitHubClient
        MODULE.MANIFEST_PATH = self.manifest
        MODULE.GitHubClient = FakeGitHubClient

    def tearDown(self) -> None:
        MODULE.MANIFEST_PATH = self.original_manifest_path
        MODULE.GitHubClient = self.original_github_client
        self.temp_dir.cleanup()

    def pnpm_tag(self) -> str:
        data = yaml.safe_load(self.manifest.read_text())
        return data["portable_pkgs"]["tools"]["pnpm"]["tag"]

    def test_implicit_latest_skips_downgrade(self) -> None:
        result = CliRunner().invoke(
            MODULE.cli, ["update", "pnpm", "--verify", "--format", "markdown"]
        )

        self.assertEqual(result.exit_code, 0, result.output)
        self.assertEqual(self.pnpm_tag(), "v12.0.0")
        self.assertIn("GitHub latest v11.25.0 is older", result.output)
        self.assertIn("- Targets resolved: 0", result.output)
        self.assertIn("- Verification: not run", result.output)
        self.assertIn(
            "| pnpm | v12.0.0 | "
            "[v11.25.0](https://github.com/pnpm/pnpm/releases/tag/v11.25.0) |",
            result.output,
        )

    def test_explicit_tag_allows_downgrade(self) -> None:
        result = CliRunner().invoke(
            MODULE.cli,
            ["update", "pnpm", "--tag", "v11.25.0", "--format", "markdown"],
        )

        self.assertEqual(result.exit_code, 0, result.output)
        self.assertEqual(self.pnpm_tag(), "v11.25.0")
        self.assertIn(
            "[v11.25.0](https://github.com/pnpm/pnpm/releases/tag/v11.25.0)",
            result.output,
        )


if __name__ == "__main__":
    unittest.main()
