"""CLI and immutable workflow contracts; companion suites cover IO and sources."""

import contextlib
import hashlib
import io
import json
import operator
import os
import re
import shutil
import subprocess
import sys
import tarfile
import tempfile
import unittest
from pathlib import Path
from typing import Any, cast
from unittest.mock import MagicMock, Mock, patch

import yaml
from githubkit_schemas.latest.models import Release, ReleaseAsset
from pydantic import ValidationError

from portable_pkgs import cli, github, models, operations, storage, tables
from portable_pkgs.requests import AddOptions
from portable_pkgs_support import CONSOLE, fill_schema, run_cli

ROOT = Path(__file__).resolve().parents[2]


class CliParsingTest(unittest.TestCase):
    def command(self, name: str, *args: str) -> Any:
        with patch.object(
            getattr(cli, f"{name.capitalize()}Command"), "cli_cmd", autospec=True
        ) as call:
            result = run_cli([name, *args])
        self.assertEqual(result.exit_code, 0, result.output)
        call.assert_called_once()
        return call.call_args.args[0]

    def test_typed_dispatch(self) -> None:
        for name, args in [
            ("list", []),
            ("search", ["codex"]),
            ("inspect", ["openai/codex"]),
            ("add", ["codex", "--type", "bundle"]),
            ("update", []),
            ("verify", []),
            ("remove", ["codex"]),
        ]:
            with self.subTest(name=name):
                self.command(name, *args)

    def test_explicit_regex_and_command_syntax(self) -> None:
        pattern = r"^foo[0-9]{1,3}\.tar\.gz$"
        for args in [
            ["-T", f'linux="{pattern}"'],
            ["--target-asset", json.dumps({"linux": pattern})],
        ]:
            cmd = self.command(
                "add",
                "pkg",
                "--type",
                "bundle",
                *args,
                "--bin",
                '"true"',
                "--bin",
                '["a,b","host"]',
                "--tag=-preview",
                "--paths",
                '{"true":"bin/true","a,b":"bin/a,b","host":"lib/host"}',
                "--target-paths",
                '{"linux":{"host":"libexec/host"}}',
            )
            self.assertEqual(cmd.target_assets["linux"].pattern, pattern)
            self.assertEqual(cmd.bin_names, ("true", "a,b", "host"))
            self.assertEqual(cmd.target_paths["linux"]["host"], "libexec/host")
            self.assertEqual(cmd.tag, "-preview")
            with self.assertRaises(TypeError):
                cmd.target_paths["linux"]["host"] = "changed"

    def test_invalid_and_removed_options_fail_before_io(self) -> None:
        cases = [
            ["add", "pkg", "--type", "file", "-Tlinux=["],
            ["add", "pkg", "--type", "file", "-Tlinux="],
            ["add", "pkg", "--type", "file", "--path-pattern", "bin/pkg"],
            ["add", "pkg", "--type", "file", "--strip-components", "0"],
            [
                "add",
                "pkg",
                "--type",
                "bundle",
                "--path-pattern",
                "bin/pkg",
                "--paths",
                "pkg=bin/pkg",
            ],
            ["inspect", "demo/pkg", "--path-regex", "foo"],
            ["inspect", "demo/pkg", "--save"],
            ["assets", "demo/pkg"],
            ["search", "pkg", "--limit", "0"],
            ["add", "pkg"],
        ] + [
            ["add", "pkg", "--type", "file", flag]
            for flag in ["--interactive", "--non-interactive", "--target=linux"]
        ]
        with (
            patch.object(github, "GitHubClient") as client,
            patch.object(storage.PackageStore, "load") as load,
        ):
            for args in cases:
                with self.subTest(args=args):
                    result = run_cli(args)
                    self.assertEqual(result.exit_code, 2, result.output)
            client.assert_not_called()
            load.assert_not_called()

    def test_add_request_owns_immutable_collections_and_rejects_unknown_fields(
        self,
    ) -> None:
        bins = ["tool"]
        overrides = {"linux": {"tool": "lib/tool"}}
        raw = {
            "name": "tool",
            "package_type": "archive-files",
            "bin_names": bins,
            "target_assets": {"linux": "tool"},
            "paths": {"tool": "bin/tool"},
            "target_paths": overrides,
        }
        command = cli.AddCommand.model_validate(raw)
        bins.append("other")
        overrides["linux"]["tool"] = "changed"
        self.assertEqual(command.bin_names, ("tool",))
        self.assertEqual(command.target_paths["linux"]["tool"], "lib/tool")
        for mapping in (
            command.target_assets,
            command.paths,
            command.target_paths["linux"],
        ):
            with self.assertRaises(TypeError):
                operator.setitem(cast(Any, mapping), "other", "changed")
        with self.assertRaises(ValidationError):
            cast(Any, command).tag = "changed"
        with self.assertRaises(ValidationError):
            cli.AddCommand.model_validate(raw | {"unexpected_option": True})

    def test_help_environment_and_interrupt(self) -> None:
        with patch.dict(
            os.environ,
            {
                "add": '{"name":"injected","package_type":"file"}',
                "update": '{"tag":"wrong"}',
            },
        ):
            self.assertIsNone(self.command("update", "pkg").tag)
            self.assertEqual(run_cli([]).exit_code, 2)
        for name in ([], ["add"], ["inspect"]):
            result = run_cli([*name, "--help"])
            self.assertEqual(result.exit_code, 0)
            self.assertNotIn("--interactive", result.stdout)
        with patch.object(cli.ListCommand, "cli_cmd", side_effect=KeyboardInterrupt):
            result = run_cli(["list"])
        self.assertEqual(result.exit_code, 1)
        self.assertIn("Aborted", result.stderr)


class WorkflowTest(unittest.TestCase):
    def setUp(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.root = Path(tmp.name)
        self.path = self.root / "source/.chezmoidata/portable-pkgs.yaml"
        self.path.parent.mkdir(parents=True)
        self.path.write_text(
            yaml.safe_dump({"portable_pkgs": {"schema_version": 8, "tools": {}}})
        )
        env = patch.dict(os.environ, {"PORTABLE_PKGS_MANIFEST": str(self.path)})
        env.start()
        self.addCleanup(env.stop)
        self.archive = self.root / "tool.tar.gz"
        with tarfile.open(self.archive, "w:gz") as tar:
            for name in ["bin/tool", "bin/host", "lib/host"]:
                info = tarfile.TarInfo(name)
                info.mode = 0o755
                info.size = 4
                tar.addfile(info, io.BytesIO(b"test"))
        self.sha = hashlib.sha256(self.archive.read_bytes()).hexdigest()
        self.client = MagicMock(spec=github.GitHubClient)
        self.client.__enter__.return_value = self.client
        self.client.fetch_release.return_value = Release.model_validate(
            fill_schema(
                Release,
                tag_name="v1.0.0",
                assets=[
                    fill_schema(
                        ReleaseAsset,
                        name="tool.tar.gz",
                        browser_download_url="https://example.invalid/tool.tar.gz",
                        digest=f"sha256:{self.sha}",
                    )
                ],
            )
        )
        self.client.download_asset.return_value = models.DownloadedAsset(
            path=self.archive, sha256=self.sha
        )
        patcher = patch.object(github, "GitHubClient", return_value=self.client)
        patcher.start()
        self.addCleanup(patcher.stop)

    def tool(self, **changes: Any) -> models.ArchiveFilesSpec:
        tool = models.ArchiveFilesSpec(
            type="archive-files",
            repo="demo/tool",
            tag="v1.0.0",
            bins={"tool": "bin/{bin}"},
            targets={
                target: models.ArchiveTarget(
                    asset_pattern=re.compile(r"^tool\.tar\.gz$"),
                    resolved=models.ResolvedArchive(
                        asset="tool.tar.gz", sha256=self.sha, files={"tool": "bin/tool"}
                    ),
                )
                for target in ["linux", "darwin"]
            },
        )
        return tool.updated(**changes)

    def save(self, tool: models.PackageSpec) -> None:
        storage.PackageStore(self.path).save(
            models.PortableManifest(schema_version=8, tools={"tool": tool})
        )

    def test_network_commands_release_the_owned_client(self) -> None:
        self.save(self.tool())
        self.client.search_repositories.return_value = ()
        for args, expected_code in (
            (["search", "tool"], 0),
            (["inspect", "demo/tool"], 0),
            (["inspect", "demo/tool", "--asset", "missing"], 1),
            (["add", "tool", "--type", "archive-files", "--dry-run"], 0),
            (["update", "tool"], 0),
            (["verify", "tool"], 0),
        ):
            with self.subTest(args=args):
                self.client.reset_mock()
                result = run_cli(args)
                self.assertEqual(result.exit_code, expected_code, result.output)
                self.client.__enter__.assert_called_once_with()
                self.client.__exit__.assert_called_once()

    def test_add_requires_explicit_discovery_without_network(self) -> None:
        for args, message in [
            (["--repo", "demo/tool"], "--target-asset"),
            (["-Tlinux=foo"], "--repo"),
            (["--repo", "demo/tool", "-Tlinux=foo"], "--path-pattern"),
        ]:
            result = run_cli(["add", "tool", "--type", "archive-files", *args])
            self.assertEqual(result.exit_code, 1, result.output)
            self.assertIn(message, result.stderr)
        self.client.fetch_release.assert_not_called()
        self.client.search_repositories.assert_not_called()

    def test_add_reuses_configured_repo_tag_and_rules(self) -> None:
        self.save(self.tool())
        result = run_cli(["add", "tool", "--type", "archive-files", "--format", "json"])
        self.assertEqual(result.exit_code, 0, result.output)
        self.client.fetch_release.assert_called_once_with("demo/tool", "v1.0.0")
        self.client.search_repositories.assert_not_called()
        self.assertEqual(json.loads(result.stdout)["tool"]["repo"], "demo/tool")

    def test_candidate_inheritance_is_pure_and_explicit_paths_take_precedence(
        self,
    ) -> None:
        existing = self.tool()
        before = existing.model_dump()
        for options, expected in [
            ({}, "bin/{bin}"),
            ({"path_pattern": "lib/{bin}"}, "lib/{bin}"),
            ({"paths": {"tool": "custom/tool"}}, "custom/tool"),
        ]:
            with self.subTest(options=options):
                request = AddOptions.model_validate(
                    {"name": "tool", "package_type": "archive-files", **options}
                )
                candidate = request.candidate(existing)
                self.assertIsInstance(candidate, models.ArchiveSpecBase)
                assert isinstance(candidate, models.ArchiveSpecBase)
                self.assertEqual(candidate.bins["tool"], expected)
                self.assertEqual(candidate.repo, existing.repo)
                self.assertEqual(candidate.tag, existing.tag)
        self.assertEqual(existing.model_dump(), before)
        self.assertEqual(self.client.mock_calls, [])

    def test_resolution_is_pure_and_failed_verification_does_not_save(self) -> None:
        original = self.tool()
        self.save(original)
        before = self.path.read_bytes()
        with operations.PackageOperations.open(self.client) as packages:
            resolved = packages.resolve_targets(
                original.updated(tag="v2.0.0"),
                ("linux",),
                self.client.fetch_release.return_value,
            )
        self.assertEqual(original.tag, "v1.0.0")
        self.assertEqual(resolved.tag, "v2.0.0")
        with patch.object(
            operations.PackageOperations,
            "verify_many",
            side_effect=models.PackageError("failed verification"),
        ):
            result = run_cli(
                ["add", "tool", "--type", "archive-files", "--path-pattern", "missing"]
            )
        self.assertEqual(result.exit_code, 1)
        self.assertEqual(self.path.read_bytes(), before)

    def test_shared_changes_refresh_and_verify_retained_targets(self) -> None:
        self.save(self.tool())
        with patch.object(
            operations.PackageOperations, "verify_many", autospec=True
        ) as verify:
            result = run_cli(
                [
                    "add",
                    "tool",
                    "--type",
                    "archive-files",
                    "--repo",
                    "other/tool",
                    "-Tlinux=tool",
                    "--path-pattern",
                    "bin/{bin}",
                ]
            )
        self.assertEqual(result.exit_code, 0, result.output)
        items = verify.call_args.args[1]
        self.assertEqual({item.target_name for item in items}, {"linux", "darwin"})
        self.assertEqual({item.tool.repo for item in items}, {"other/tool"})
        self.client.fetch_release.assert_called_once_with("other/tool", "latest")

    def test_explicit_target_paths_preserve_other_platforms(self) -> None:
        self.save(
            self.tool(
                bins={"tool": "bin/tool", "host": "bin/host"},
                targets={
                    name: models.ArchiveTarget(asset_pattern="tool")
                    for name in ["linux", "darwin"]
                },
            )
        )
        result = run_cli(
            [
                "add",
                "tool",
                "--type",
                "archive-files",
                "--target-paths",
                '{"linux":{"host":"lib/host"}}',
                "--format",
                "json",
            ]
        )
        self.assertEqual(result.exit_code, 0, result.output)
        tool = storage.PackageStore(self.path).load().tools["tool"]
        assert isinstance(tool, models.ArchiveSpecBase)
        resolved = tool.targets["linux"].resolved
        assert resolved is not None
        self.assertEqual(resolved.files["host"], "lib/host")
        self.assertIsNone(tool.targets["darwin"].bins)
        self.assertEqual(tool.bins["host"], "bin/host")

    def test_add_rejects_missing_member_without_opt_in_verification(self) -> None:
        before = self.path.read_bytes()
        result = run_cli(
            [
                "add",
                "tool",
                "--repo",
                "demo/tool",
                "--type",
                "archive-files",
                "-Tlinux=tool",
                "--path-pattern",
                "missing",
            ]
        )
        self.assertEqual(result.exit_code, 1, result.output)
        self.assertIn("member not found", result.stderr)
        self.assertEqual(self.path.read_bytes(), before)

    def test_malformed_api_and_download_failure_leave_manifest_unchanged(self) -> None:
        self.save(self.tool())
        before = self.path.read_bytes()
        self.client.fetch_release.side_effect = models.PackageError(
            "invalid GitHub response"
        )
        result = run_cli(["update", "tool"])
        self.assertEqual(result.exit_code, 1)
        self.assertNotIn("Traceback", result.stderr)
        self.client.fetch_release.side_effect = None
        self.client.download_asset.side_effect = models.PackageError(
            "truncated download"
        )
        result = run_cli(["add", "tool", "--type", "archive-files"])
        self.assertEqual(result.exit_code, 1)
        self.assertEqual(self.path.read_bytes(), before)

    def test_ambiguous_asset_does_not_pick_first_or_save(self) -> None:
        self.save(self.tool())
        before = self.path.read_bytes()
        release = self.client.fetch_release.return_value
        self.client.fetch_release.return_value = release.model_copy(
            update={"assets": (*release.assets, release.assets[0])}
        )
        result = run_cli(["add", "tool", "--type", "archive-files", "-Tlinux=tool"])
        self.assertEqual(result.exit_code, 1)
        self.assertIn("matched 2 assets", result.stderr)
        self.assertEqual(self.path.read_bytes(), before)

    def test_inspect_lists_before_add_and_never_reads_manifest(self) -> None:
        before = self.path.read_bytes()
        with patch.object(
            storage.PackageStore,
            "load",
            side_effect=AssertionError("inspect must not read config"),
        ):
            assets = run_cli(["inspect", "demo/tool"])
            members = run_cli(
                [
                    "inspect",
                    "demo/tool",
                    "--asset",
                    "tool.tar.gz",
                    "--path-regex",
                    "host$",
                    "--format",
                    "json",
                ]
            )
        self.assertEqual(assets.exit_code, 0, assets.output)
        self.assertEqual(members.exit_code, 0, members.output)
        rows = json.loads(members.stdout)
        self.assertEqual({r["path"] for r in rows}, {"bin/host", "lib/host"})
        self.assertTrue(all(r["mode"] == 0o755 and r["kind"] == "file" for r in rows))
        self.assertEqual(self.path.read_bytes(), before)
        self.assertFalse((self.root / "bin").exists())

    def test_verified_dry_run_does_not_save_sources_or_manifest(self) -> None:
        before = self.path.read_bytes()
        result = run_cli(
            [
                "add",
                "tool",
                "--repo",
                "demo/tool",
                "--type",
                "bundle",
                "--bin",
                "tool",
                "--bin",
                "host",
                "-Tlinux=tool",
                "--path-pattern",
                "bin/{bin}",
                "--dry-run",
                "--format",
                "json",
            ]
        )
        self.assertEqual(result.exit_code, 0, result.output)
        self.client.download_asset.assert_called_once()
        self.assertEqual(self.path.read_bytes(), before)
        self.assertFalse((self.root / "source/dot_local").exists())

    def test_update_reports_partial_verification_and_skips_downgrade(self) -> None:
        bundle = models.BundleSpec(
            type="bundle",
            repo="demo/host",
            tag="v1.0.0",
            bins={"host": "bin/host"},
            targets={"linux": models.ArchiveTarget(asset_pattern="tool")},
        )
        manifest = models.PortableManifest(
            schema_version=8, tools={"tool": self.tool(), "host": bundle}
        )
        storage.PackageStore(self.path).save(manifest)
        result = run_cli(["update", "--format", "markdown"])
        self.assertEqual(result.exit_code, 0, result.output)
        self.assertIn("Verification: partial", result.stdout)
        self.save(self.tool(tag="v2.0.0"))
        result = run_cli(["update", "tool", "--format", "markdown"])
        self.assertEqual(result.exit_code, 0, result.output)
        self.assertIn("Verification: not run", result.stdout)
        self.assertIn("is older than configured", result.stderr)
        self.assertIn("- Targets resolved: 0", result.stdout)
        self.assertIn(
            "| tool | v2.0.0 | "
            "[v1.0.0](https://github.com/demo/tool/releases/tag/v1.0.0) |",
            result.stdout,
        )
        self.assertEqual(
            storage.PackageStore(self.path).load().tools["tool"].tag, "v2.0.0"
        )
        result = run_cli(["update", "tool", "--tag", "v1.0.0"])
        self.assertEqual(result.exit_code, 0, result.output)
        self.assertEqual(
            storage.PackageStore(self.path).load().tools["tool"].tag, "v1.0.0"
        )


class WorkspaceTest(unittest.TestCase):
    def test_body_oserror_keeps_its_origin_and_still_cleans_workspace(self) -> None:
        failure = OSError("destination disk is full")
        directory: Path | None = None
        with (
            self.assertRaises(OSError) as caught,
            operations.PackageOperations.open(github.GitHubClient()) as packages,
        ):
            directory = packages.downloads.directory
            self.assertTrue(directory.is_dir())
            raise failure
        self.assertIs(caught.exception, failure)
        assert directory is not None
        self.assertFalse(directory.exists())

    def test_resource_errors_are_attributed_to_creation_or_cleanup(self) -> None:
        failure = OSError("workspace unavailable")
        with (
            patch.object(
                operations.tempfile, "TemporaryDirectory", side_effect=failure
            ),
            self.assertRaises(models.PackageError) as caught,
            operations.PackageOperations.open(github.GitHubClient()),
        ):
            self.fail("must not enter the body")
        self.assertIs(caught.exception.__cause__, failure)
        self.assertIn("create package workspace", str(caught.exception))

        resource = Mock(name="workspace")
        resource.cleanup.side_effect = failure
        resource.name = "/unused/workspace"
        with (
            patch.object(
                operations.tempfile, "TemporaryDirectory", return_value=resource
            ),
            self.assertRaises(models.PackageError) as caught,
            operations.PackageOperations.open(github.GitHubClient()),
        ):
            pass
        resource.cleanup.assert_called_once_with()
        self.assertIs(caught.exception.__cause__, failure)
        self.assertIn("clean package workspace", str(caught.exception))

    def test_cleanup_failure_does_not_replace_the_body_failure(self) -> None:
        failure = models.PackageError("verification failed")
        resource = Mock()
        resource.cleanup.side_effect = OSError("cleanup failed")
        resource.name = "/unused/workspace"
        with (
            patch.object(
                operations.tempfile, "TemporaryDirectory", return_value=resource
            ),
            self.assertRaises(models.PackageError) as caught,
            operations.PackageOperations.open(github.GitHubClient()),
        ):
            raise failure
        self.assertIs(caught.exception, failure)
        self.assertEqual(len(failure.__notes__), 1)
        resource.cleanup.assert_called_once_with()


class ProjectEntryTest(unittest.TestCase):
    def test_console_entry_honors_manifest_override_from_other_directory(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            manifest = root / "manifest.yaml"
            manifest.write_text("portable_pkgs: {schema_version: 8, tools: {}}\n")
            result = subprocess.run(
                [str(CONSOLE), "list", "--format", "json"],
                cwd=root,
                env={**os.environ, "PORTABLE_PKGS_MANIFEST": str(manifest)},
                capture_output=True,
                text=True,
                check=False,
                timeout=15,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(json.loads(result.stdout), [])

    def test_default_manifest_follows_loaded_checkout_and_ignores_cwd(self) -> None:
        self.assertEqual(
            storage.DEFAULT_MANIFEST_PATH,
            ROOT / "home/.chezmoidata/portable-pkgs.yaml",
        )
        with tempfile.TemporaryDirectory() as tmp:
            checkout = Path(tmp).resolve() / "checkout"
            source = checkout / "portable-pkgs/src"
            shutil.copytree(
                ROOT / "portable-pkgs/src/portable_pkgs",
                source / "portable_pkgs",
                ignore=shutil.ignore_patterns("__pycache__"),
            )
            env = {
                key: value
                for key, value in os.environ.items()
                if key != "PORTABLE_PKGS_MANIFEST"
            }
            # Import the relocated checkout through Python's native cwd search,
            # then change cwd before reading the default manifest path.
            result = subprocess.run(
                [
                    sys.executable,
                    "-c",
                    (
                        "from portable_pkgs.storage import manifest_path; "
                        "import os; os.chdir('/'); print(manifest_path())"
                    ),
                ],
                cwd=source,
                env=env,
                capture_output=True,
                text=True,
                check=False,
                timeout=15,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(
                Path(result.stdout.strip()),
                checkout / "home/.chezmoidata/portable-pkgs.yaml",
            )


class OutputTest(unittest.TestCase):
    def test_listing_prints_header_and_cells_literally(self) -> None:
        rows: list[dict[str, object]] = [
            {"name": "中文", "tag": "v1"},
            {"name": "[bold]", "tag": "v2"},
        ]
        output = tables.render_listing(
            rows, [tables.Column("name", "NAME"), tables.Column("tag", "TAG")]
        )
        lines = output.splitlines()
        self.assertEqual(lines[0], "NAME  TAG")
        self.assertIn("中文", lines[1])
        self.assertIn("[bold]", lines[2])
        self.assertNotIn("\x1b", output)

    def test_listing_renders_missing_and_empty_cells_as_dash(self) -> None:
        output = tables.render_listing(
            [{"name": ""}, {"name": None}], [tables.Column("name", "NAME")]
        )
        self.assertEqual(output.splitlines(), ["NAME", "-", "-"])

    def test_json_output_round_trips_exactly(self) -> None:
        rows: list[dict[str, object]] = [{"name": "tool", "tag": None, "bins": []}]
        stream = io.StringIO()
        with contextlib.redirect_stdout(stream):
            tables.print_rows(rows, [tables.Column("name", "NAME")], "json")
        self.assertEqual(json.loads(stream.getvalue()), rows)


class SemanticVersionTest(unittest.TestCase):
    def test_extracts_versions_from_release_tags(self) -> None:
        for tag in ("1.2.3", "v1.2.3", "rust-v1.2.3", "jq-1.2.3"):
            with self.subTest(tag=tag):
                self.assertEqual(str(models.parse_semantic_version(tag)), "1.2.3")
        self.assertTrue(
            models.is_semantic_version_downgrade("rust-v0.153.4", "rust-v0.152.0")
        )

    def test_detects_stable_release_downgrade(self) -> None:
        self.assertTrue(models.is_semantic_version_downgrade("v12.0.0", "v11.25.0"))

    def test_compares_prerelease_precedence(self) -> None:
        is_downgrade = models.is_semantic_version_downgrade

        self.assertTrue(is_downgrade("v1.0.0", "v1.0.0-rc.1"))
        self.assertFalse(is_downgrade("v1.0.0-rc.1", "v1.0.0"))
        self.assertFalse(is_downgrade("v1.0.0+old", "v1.0.0+new"))

    def test_ignores_non_semantic_tags(self) -> None:
        self.assertFalse(models.is_semantic_version_downgrade("nightly", "stable"))
        self.assertFalse(models.is_semantic_version_downgrade("v1.0.0", "v1.0.0-rc.01"))
        self.assertFalse(models.is_semantic_version_downgrade("v2.0.0", "v1٢.0.0"))


if __name__ == "__main__":
    unittest.main()
