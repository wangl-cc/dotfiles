"""Owned chezmoi source lifecycle and isolated installation regressions."""

import functools
import hashlib
import http.server
import io
import json
import os
import platform
import shutil
import subprocess
import tarfile
import tempfile
import threading
import tomllib
import unittest
from pathlib import Path
from typing import Any
from unittest.mock import patch

import yaml
from githubkit_schemas.latest.models import Release, ReleaseAsset

from portable_pkgs import github, models, storage
from portable_pkgs.sources import PackageSources
from portable_pkgs_support import CONSOLE, fill_schema, run_cli

ROOT = Path(__file__).resolve().parents[2]


def manifest_data(tools: dict[str, Any] | None = None) -> dict[str, Any]:
    return {
        "portable_pkgs": {
            "schema_version": 8,
            "install_dir": ".local/bin",
            "tools": tools or {},
        }
    }


def chezmoi_target_paths(source_root: Path, paths: set[Path]) -> dict[Path, str]:
    """Ask chezmoi which target each planned source name maps to.

    Empty stand-ins preserve names and entry types, including sources that do not
    exist yet; no externals, scripts, or real targets are loaded.
    """
    with tempfile.TemporaryDirectory() as tmp:
        source, destination = Path(tmp) / "source", Path(tmp) / "destination"
        ordered = sorted(paths)
        staged = []
        for path in ordered:
            entry = source / path.relative_to(source_root)
            entry.parent.mkdir(parents=True, exist_ok=True)
            if path.is_dir():
                entry.mkdir(exist_ok=True)
            else:
                entry.touch()
            staged.append(str(entry))
        result = subprocess.run(
            [
                "chezmoi",
                f"--source={source}",
                f"--destination={destination}",
                f"--config={os.devnull}",
                "--config-format=toml",
                f"--cache={tmp}/cache",
                f"--persistent-state={tmp}/state",
                "target-path",
                *staged,
            ],
            text=True,
            capture_output=True,
            timeout=30,
            check=False,
        )
        if result.returncode:
            raise AssertionError(f"chezmoi target-path failed: {result.stderr}")
        return {
            path: str(Path(target).relative_to(destination))
            for path, target in zip(ordered, result.stdout.splitlines(), strict=True)
        }


class PackageFixture(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.source = self.base / "source"
        self.manifest = self.source / ".chezmoidata/portable-pkgs.yaml"
        self.manifest.parent.mkdir(parents=True)
        self.manifest.write_text(yaml.safe_dump(manifest_data()))
        machine = "aarch64" if platform.machine() == "arm64" else platform.machine()
        self.target = f"{platform.system().lower()}-{machine}"
        self.archive = self.base / "tool.tar.gz"
        self.make_tar()
        manifest_env = patch.dict(
            os.environ,
            {
                "PORTABLE_PKGS_MANIFEST": str(self.manifest),
                "XDG_CACHE_HOME": str(self.base / "cache"),
            },
        )
        manifest_env.start()
        self.addCleanup(manifest_env.stop)

    def make_tar(
        self, extras: list[tuple[str, bytes | str, int]] | None = None
    ) -> None:
        with tarfile.open(self.archive, "w:gz") as archive:
            for name, data, mode in [
                ("pkg/bin/tool", b"#!/bin/sh\nprintf 'tool-ok\\n'\n", 0o755),
                ("pkg/bin/helper", b"#!/bin/sh\nprintf 'helper-ok\\n'\n", 0o755),
                ("pkg/share/data.txt", b"resource", 0o644),
                *(extras or []),
            ]:
                member = tarfile.TarInfo(name)
                member.mode = mode
                if isinstance(data, str):
                    member.type = tarfile.SYMTYPE
                    member.linkname = data
                    archive.addfile(member)
                else:
                    member.size = len(data)
                    archive.addfile(member, io.BytesIO(data))

    def tool(self, package_type: str = "bundle") -> dict[str, Any]:
        return {
            "type": package_type,
            "repo": "demo/tool",
            "tag": "v1.0.0",
            **(
                {"bin": "tool"}
                if package_type == "file"
                else {
                    "bins": {
                        "tool": "bin/tool"
                        if package_type == "bundle"
                        else "pkg/bin/tool"
                    }
                }
            ),
            **({"strip_components": 1} if package_type == "bundle" else {}),
            "targets": {
                self.target: {
                    "asset_pattern": r"^tool\.tar\.gz$",
                    "resolved": {
                        "asset": self.archive.name,
                        "sha256": hashlib.sha256(self.archive.read_bytes()).hexdigest(),
                        **(
                            {}
                            if package_type == "file"
                            else {
                                "files": {
                                    "tool": "bin/tool"
                                    if package_type == "bundle"
                                    else "pkg/bin/tool"
                                }
                            }
                        ),
                    },
                }
            },
        }

    def save(self, tool: dict[str, Any] | None = None) -> None:
        manifest = models.PortableManifest.model_validate(
            manifest_data({"tool": tool or self.tool()})["portable_pkgs"]
        )
        storage.PackageStore(path=self.manifest).save(manifest)

    def client(self) -> Any:
        archive = self.archive

        class Client:
            def __enter__(self) -> "Client":
                return self

            def __exit__(self, *args: object) -> None:
                pass

            def fetch_release(self, repo: str, tag: str) -> Any:
                return Release.model_validate(
                    fill_schema(
                        Release,
                        tag_name="v1.0.0",
                        assets=[
                            fill_schema(
                                ReleaseAsset,
                                name=archive.name,
                                browser_download_url=(
                                    "https://example.invalid/tool.tar.gz"
                                ),
                                digest="sha256:"
                                + hashlib.sha256(archive.read_bytes()).hexdigest(),
                            )
                        ],
                    )
                )

            def download_asset(self, url: str, destination: Path) -> Any:
                return models.DownloadedAsset(
                    path=archive,
                    sha256=hashlib.sha256(archive.read_bytes()).hexdigest(),
                )

        return Client

    def invoke(self, *args: str) -> Any:
        with patch.object(github, "GitHubClient", self.client()):
            return run_cli(list(args))


class CliBoundaryTest(PackageFixture):
    def process(self, *args: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [str(CONSOLE), *args],
            text=True,
            capture_output=True,
            check=False,
            timeout=15,
        )

    def test_writer_lock_spans_commands_and_releases_on_failure(self) -> None:
        tool = self.tool("archive-files")
        self.save(tool)
        before = self.manifest.read_bytes()
        file = storage.PackageStore(self.manifest)
        with file.lock():
            for args in (
                ("remove", "tool"),
                ("update", "tool"),
                ("add", "tool", "--type", "archive-files", "--repo", "demo/tool"),
            ):
                with self.subTest(args=args):
                    result = self.process(*args)
                    self.assertEqual(result.returncode, 1, result.stderr)
                    self.assertIn("another portable-pkgs command", result.stderr)
            self.assertEqual(self.process("list", "--format", "json").returncode, 0)
        self.assertEqual(self.manifest.read_bytes(), before)
        failed = self.process("remove", "missing")
        self.assertEqual(failed.returncode, 1)
        result = self.process("remove", "tool")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(storage.PackageStore(self.manifest).load().tools, {})

    def test_real_cli_formats_source_conflicts_and_io_errors(self) -> None:
        self.save(self.tool("archive-files"))
        before = self.manifest.read_bytes()
        source = self.source / "dot_local/bin/remove_literal_tool.literal"
        source.parent.mkdir(parents=True)
        source.write_text("handwritten")
        result = self.process("remove", "tool")
        self.assertEqual(result.returncode, 1)
        self.assertIn("not owned or was edited", result.stderr)
        self.assertNotIn("Traceback", result.stderr)
        self.assertEqual(self.manifest.read_bytes(), before)
        with patch.dict(
            os.environ, {"PORTABLE_PKGS_MANIFEST": str(self.base / "missing.yaml")}
        ):
            result = self.process("list")
        self.assertEqual(result.returncode, 1)
        self.assertIn("Error:", result.stderr)
        self.assertNotIn("Traceback", result.stderr)


class SchemaTest(PackageFixture):
    def test_paths_reject_line_breaks_and_nul(self) -> None:
        for character in ("\r", "\n", "\x00"):
            with self.subTest(character=character):
                with self.assertRaises(ValueError):
                    models.FileSpec(
                        type="file", repo="demo/tool", bin="tool" + character
                    )
                with self.assertRaises(ValueError):
                    models.PortableManifest(
                        schema_version=8, install_dir="bin" + character
                    )

    @unittest.skipUnless(
        shutil.which("chezmoi"), "chezmoi is required for source names"
    )
    def test_removal_sources_preserve_literal_filenames(self) -> None:
        sources = PackageSources(self.manifest)
        paths = {
            sources.source_path(f".local/bin/{name}", "remove"): f".local/bin/{name}"
            for name in (
                "tool",
                "[tool]",
                "{{danger}}",
                "space name \t",
                "[ ]",
                "[\t]",
                "*?!#{}",
                "工具",
                ".hidden",
                "dot_foo",
                "literal_foo",
                "foo.tmpl",
                "foo.literal",
            )
        }
        self.assertEqual(chezmoi_target_paths(sources.root, set(paths)), paths)

    @unittest.skipUnless(
        shutil.which("chezmoi"), "chezmoi is required for source names"
    )
    def test_attribute_named_install_dir_components_round_trip(self) -> None:
        sources = PackageSources(self.manifest)
        install_dirs = (
            ".local/private_tools",
            ".x/bin",
            "dot_x/bin",
            "literal_foo/readonly_x",
            "exact_x/remove_x/external_x",
            "plain_dir/bin",
        )
        commands = ("tool", "dot_foo")
        paths = {
            sources.source_path(f"{install_dir}/{command}", kind): (
                f"{install_dir}/{command}"
            )
            for install_dir in install_dirs
            for command in commands
            for kind in ("remove", "symlink")
        }
        self.assertEqual(
            len(paths),
            len(install_dirs) * len(commands) * 2,
            "distinct targets must not share a source path",
        )
        self.assertEqual(chezmoi_target_paths(sources.root, set(paths)), paths)


class LifecycleTest(PackageFixture):
    def test_save_update_and_remove_without_chezmoi(self) -> None:
        with patch.dict(os.environ, {"PATH": ""}):
            self.save()
            updated = self.tool()
            updated["tag"] = "v1.1.0"
            self.save(updated)
            store = storage.PackageStore(self.manifest)
            store.save(store.load().updated(tools={}))
        self.assertEqual(dict(store.load().tools), {})
        self.assertTrue(
            (self.source / "dot_local/bin/remove_literal_tool.literal").is_file()
        )

    def test_generated_source_cannot_escape_its_root(self) -> None:
        outside = self.base / "outside"
        outside.mkdir()
        (self.source / "dot_local").symlink_to(outside, target_is_directory=True)
        before = self.manifest.read_bytes()
        with self.assertRaisesRegex(models.PackageError, "escapes"):
            self.save()
        self.assertEqual(self.manifest.read_bytes(), before)
        self.assertEqual(list(outside.iterdir()), [])

    def add_args(self, package_type: str = "bundle") -> list[str]:
        return [
            "add",
            "tool",
            "--repo",
            "demo/tool",
            "--type",
            package_type,
            "-T" + self.target + r"=^tool\.tar\.gz$",
            "--bin",
            "tool",
            "--path-pattern",
            "bin/{bin}" if package_type == "bundle" else "pkg/bin/{bin}",
            *(["--strip-components", "1"] if package_type == "bundle" else []),
        ]

    def test_failed_manifest_replace_is_retryable_for_add_and_remove(self) -> None:
        replace = Path.replace

        def fail_manifest(path: Path, target: Path) -> Path:
            if target == self.manifest:
                raise OSError("injected manifest replacement failure")
            return replace(path, target)

        link = self.source / "dot_local/bin/symlink_tool.tmpl"
        for operation in (self.add_args(), ["remove", "tool"]):
            with self.subTest(operation=operation[0]):
                before = self.manifest.read_bytes()
                with patch.object(Path, "replace", fail_manifest):
                    result = self.invoke(*operation)
                self.assertNotEqual(result.exit_code, 0)
                self.assertEqual(self.manifest.read_bytes(), before)
                self.assertEqual(link.exists(), operation[0] == "add")
                result = self.invoke(*operation)
                self.assertEqual(result.exit_code, 0, result.output)
        self.assertTrue(
            (self.source / "dot_local/bin/remove_literal_tool.literal").is_file()
        )
        self.assertTrue(
            (
                self.source
                / "dot_local/share/portable-pkgs/remove_literal_tool.literal"
            ).is_file()
        )

    def test_partial_source_write_leaves_original_and_can_retry(self) -> None:
        self.save()
        manifest = storage.PackageStore(path=self.manifest).load()
        manifest = manifest.updated(install_dir=".local/commands")
        before = self.manifest.read_bytes()
        write_text = Path.write_text

        def fail_write(path: Path, content: str) -> int:
            if path.parent.name.startswith(".portable-pkgs-write-"):
                write_text(path, content[:10])
                raise OSError("injected partial write")
            return write_text(path, content)

        with (
            patch.object(Path, "write_text", fail_write),
            self.assertRaisesRegex(models.PackageError, "injected partial write"),
        ):
            storage.PackageStore(path=self.manifest).save(manifest)
        self.assertEqual(self.manifest.read_bytes(), before)
        new_link = self.source / "dot_local/commands/symlink_tool.tmpl"
        self.assertFalse(new_link.exists())
        storage.PackageStore(path=self.manifest).save(manifest)
        self.assertTrue(new_link.exists())
        self.assertFalse((self.source / "dot_local/bin/symlink_tool.tmpl").exists())

    def test_source_transition_failure_is_retryable(self) -> None:
        self.save()
        link = self.source / "dot_local/bin/symlink_tool.tmpl"
        removal = self.source / "dot_local/bin/remove_literal_tool.literal"
        write = storage.atomic_write_text
        for operation, destination in (
            (["remove", "tool"], removal),
            (self.add_args(), link),
        ):
            with self.subTest(operation=operation[0]):
                before = self.manifest.read_bytes()

                def fail_source(
                    path: Path, content: str, target: Path = destination
                ) -> None:
                    if path == target:
                        raise OSError("injected source transition failure")
                    write(path, content)

                with patch.object(storage, "atomic_write_text", fail_source):
                    result = self.invoke(*operation)
                self.assertEqual(result.exit_code, 1, result.output)
                self.assertEqual(self.manifest.read_bytes(), before)
                self.assertFalse(link.exists())
                self.assertFalse(removal.exists())
                result = self.invoke(*operation)
                self.assertEqual(result.exit_code, 0, result.output)
                self.assertTrue(destination.is_file())

    def test_readd_preserves_edited_removal_source(self) -> None:
        self.save()
        self.assertEqual(self.invoke("remove", "tool").exit_code, 0)
        removal = self.source / "dot_local/bin/remove_literal_tool.literal"
        removal.write_text("handwritten")
        before = self.manifest.read_bytes()
        result = self.invoke(*self.add_args())
        self.assertEqual(result.exit_code, 1, result.output)
        self.assertIn("not owned or was edited", result.output)
        self.assertEqual(self.manifest.read_bytes(), before)
        self.assertEqual(removal.read_text(), "handwritten")
        self.assertFalse((self.source / "dot_local/bin/symlink_tool.tmpl").exists())

    def test_add_dry_run_then_remove_and_readd(self) -> None:
        handwritten_removals = self.source / ".chezmoiremove"
        handwritten_removals.write_text("unrelated/file\n")
        before = self.manifest.read_bytes()
        result = self.invoke(*self.add_args(), "--dry-run", "--format", "json")
        self.assertEqual(result.exit_code, 0, result.output)
        dry_tool = json.loads(result.stdout)["tool"]
        self.assertEqual(dry_tool["type"], "bundle")
        self.assertEqual(dry_tool["bins"], {"tool": "bin/{bin}"})
        self.assertEqual(
            dry_tool["targets"][self.target]["resolved"]["files"],
            {"tool": "bin/tool"},
        )
        self.assertEqual(before, self.manifest.read_bytes())
        link = self.source / "dot_local/bin/symlink_tool.tmpl"
        self.assertFalse(link.exists())
        result = self.invoke(*self.add_args())
        self.assertEqual(result.exit_code, 0, result.output)
        self.assertTrue(link.is_file())
        result = self.invoke("remove", "tool")
        self.assertEqual(result.exit_code, 0, result.output)
        self.assertFalse(link.exists())
        removals = [
            self.source / "dot_local/bin/remove_literal_tool.literal",
            self.source / "dot_local/share/portable-pkgs/remove_literal_tool.literal",
        ]
        self.assertTrue(all(path.is_file() for path in removals))
        result = self.invoke(*self.add_args())
        self.assertEqual(result.exit_code, 0, result.output)
        self.assertTrue(all(not path.exists() for path in removals))
        self.assertEqual(handwritten_removals.read_text(), "unrelated/file\n")

    def test_readding_as_archive_files_clears_command_removal(self) -> None:
        self.save()
        self.assertEqual(self.invoke("remove", "tool").exit_code, 0)
        result = self.invoke(*self.add_args("archive-files"))
        self.assertEqual(result.exit_code, 0, result.output)
        self.assertFalse(
            (self.source / "dot_local/bin/remove_literal_tool.literal").exists()
        )
        self.assertTrue(
            (
                self.source
                / "dot_local/share/portable-pkgs/remove_literal_tool.literal"
            ).is_file()
        )

    def test_edited_generated_link_leaves_manifest_unchanged(self) -> None:
        self.save()
        link = self.source / "dot_local/bin/symlink_tool.tmpl"
        link.write_text("edited")
        before = self.manifest.read_bytes()
        result = self.invoke("remove", "tool")
        self.assertNotEqual(result.exit_code, 0)
        self.assertEqual(self.manifest.read_bytes(), before)
        self.assertEqual(link.read_text(), "edited")


@unittest.skipUnless(
    shutil.which("chezmoi"), "chezmoi is required for installation integration"
)
class ChezmoiIntegrationTest(PackageFixture):
    def setUp(self) -> None:
        super().setUp()
        self.templates = self.source / ".chezmoitemplates"
        self.templates.mkdir()
        shutil.copyfile(
            ROOT / "home/.chezmoitemplates/portable-pkgs-link.tmpl",
            self.templates / "portable-pkgs-link.tmpl",
        )
        self.config = self.base / "config.toml"
        self.config.write_text("")
        self.destination = self.base / "home"
        self.destination.mkdir()

    def chezmoi(self, *args: str) -> str:
        result = subprocess.run(
            [
                "chezmoi",
                "--source",
                str(self.source),
                "--destination",
                str(self.destination),
                "--config",
                str(self.config),
                "--cache",
                str(self.base / "cache"),
                "--persistent-state",
                str(self.base / "state.boltdb"),
                "--mode",
                "file",
                "--force",
                *args,
            ],
            text=True,
            capture_output=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        return result.stdout

    @staticmethod
    def external_template() -> str:
        template = (ROOT / "home/.chezmoiexternal.toml.tmpl").read_text()
        return template[template.index("{{/* Portable GitHub release packages.") :]

    def render(self, *args: str) -> str:
        return self.chezmoi(*args, "execute-template", self.external_template())

    def local_external(self, remote: str, local: str) -> None:
        # Keep declarations driven by the manifest, as in the real source tree.
        # Only redirect downloads to the test fixture after rendering.
        template = self.templates / "packages.tmpl"
        template.write_text(self.external_template())
        (self.source / ".chezmoiexternal.toml").write_text(
            "{{ includeTemplate "
            + json.dumps(str(template))
            + " . | replace "
            + json.dumps(remote)
            + " "
            + json.dumps(local)
            + " }}"
        )

    def test_source_prefix_order_and_literal_command_round_trip(self) -> None:
        sibling = self.source / "dot_local/bin/readonly_private_tool"
        sibling.parent.mkdir(parents=True)
        sibling.write_text("handwritten")
        self.save()
        self.chezmoi("apply")
        self.assertEqual(
            (self.destination / ".local/bin/private_tool").read_text(), "handwritten"
        )
        self.assertTrue((self.destination / ".local/bin/tool").is_symlink())
        self.assertEqual(self.invoke("remove", "tool").exit_code, 0)
        self.chezmoi("apply")
        for command in ("dot_foo", "literal_foo", "foo.tmpl"):
            with self.subTest(command=command):
                tool = self.tool()
                tool["bins"] = {command: "bin/tool"}
                tool["targets"][self.target]["resolved"]["files"] = {
                    command: "bin/tool"
                }
                self.save(tool)
                self.chezmoi("apply")
                installed = self.destination / ".local/bin" / command
                self.assertTrue(installed.is_symlink())
                self.assertFalse((self.destination / ".local/bin/.foo").is_symlink())
                self.assertEqual(self.invoke("remove", "tool").exit_code, 0)
                self.chezmoi("apply")
                self.assertFalse(installed.is_symlink())

    def test_rendered_urls_match_tool_on_each_install_branch(self) -> None:
        for kind in ("file", "archive-files", "bundle"):
            tool = self.tool(kind)
            tool["tag"] = "release/v1.0.0#test?+%"
            asset = "tool #?+%雪" + (".tar.gz" if kind != "file" else "")
            target = tool["targets"][self.target]
            target["resolved"]["asset"] = asset
            tool["targets"] = {"darwin-aarch64": target, "linux-x86_64": target}
            self.save(tool)
            expected = models.PACKAGE_ADAPTER.validate_python(tool).download_url(asset)
            for os_name, arch in (("darwin", "arm64"), ("linux", "amd64")):
                with self.subTest(kind=kind, os=os_name):
                    output = self.render(
                        "--override-data",
                        json.dumps({"chezmoi": {"os": os_name, "arch": arch}}),
                    )
                    entries = tomllib.loads(output)
                    self.assertEqual(len(entries), 1)
                    self.assertEqual(next(iter(entries.values()))["url"], expected)

    def test_remove_and_readd_non_bundle_commands_in_real_chezmoi(self) -> None:
        plain = self.base / "plain"
        plain.write_text("#!/bin/sh\necho ok\n")
        for kind, command in (
            ("file", "[tool]"),
            ("archive-files", "tool"),
            ("file", "{{danger}}"),
            ("file", "space name "),
            ("file", "foo.tmpl"),
            ("file", "foo.literal"),
            ("file", ".hidden"),
            ("file", "dot_foo"),
        ):
            with self.subTest(kind=kind, command=command):
                tool = self.tool(kind)
                if kind == "file":
                    tool["bin"] = command
                    tool["targets"][self.target]["resolved"]["asset"] = "plain"
                asset_path = plain if kind == "file" else self.archive
                tool["targets"][self.target]["resolved"]["sha256"] = hashlib.sha256(
                    asset_path.read_bytes()
                ).hexdigest()
                self.save(tool)
                url = models.PACKAGE_ADAPTER.validate_python(tool).download_url(
                    asset_path.name
                )
                self.local_external(url, asset_path.as_uri())
                self.chezmoi("apply")
                target = self.destination / ".local/bin" / command
                neighbor = target.parent / "t"
                neighbor.write_text("unrelated")
                self.assertTrue(target.is_file())
                result = self.invoke("remove", "tool")
                self.assertEqual(result.exit_code, 0, result.output)
                self.chezmoi("apply")
                self.assertFalse(target.exists())
                self.assertEqual(neighbor.read_text(), "unrelated")
                self.save(tool)
                self.chezmoi("apply")
                self.assertTrue(target.is_file())

    def test_render_all_types(self) -> None:
        for kind in ("file", "archive-files", "bundle"):
            with self.subTest(kind=kind):
                tool = self.tool(kind)
                if kind == "file":
                    resolved = tool["targets"][self.target]["resolved"]
                    resolved["asset"] = "tool"
                self.manifest.write_text(yaml.safe_dump(manifest_data({"tool": tool})))
                rendered = tomllib.loads(self.render())
                key = (
                    ".local/share/portable-pkgs/tool"
                    if kind == "bundle"
                    else ".local/bin/tool"
                )
                self.assertEqual(
                    rendered[key]["type"],
                    {
                        "file": "file",
                        "archive-files": "archive-file",
                        "bundle": "archive",
                    }[kind],
                )
                if kind == "bundle":
                    self.assertTrue(rendered[key]["exact"])
                    self.assertNotIn("executable", rendered[key])

    def test_bundle_link_omits_unsupported_target(self) -> None:
        self.save()
        source = self.source / "dot_local/bin/symlink_tool.tmpl"
        self.assertEqual(
            self.chezmoi(
                "--override-data",
                json.dumps(
                    {
                        "chezmoi": {
                            "os": "unsupported",
                            "arch": "unsupported",
                            "targetFile": str(self.destination / ".local/bin/tool"),
                        }
                    }
                ),
                "execute-template",
                "--file",
                str(source),
            ),
            "",
        )

    def test_bundle_defaults_to_zero_stripping(self) -> None:
        tool = self.tool()
        del tool["strip_components"]
        self.save(tool)
        stored = yaml.safe_load(self.manifest.read_text())["portable_pkgs"]["tools"][
            "tool"
        ]
        self.assertEqual(stored["strip_components"], 0)
        rendered = tomllib.loads(self.render())
        self.assertEqual(
            rendered[".local/share/portable-pkgs/tool"]["stripComponents"], 0
        )

    def test_unresolved_bundle_omits_directory_and_command(self) -> None:
        self.save()
        tool = self.tool()
        del tool["targets"][self.target]["resolved"]
        self.manifest.write_text(yaml.safe_dump(manifest_data({"tool": tool})))
        self.assertEqual(tomllib.loads(self.render()), {})
        source = self.source / "dot_local/bin/symlink_tool.tmpl"
        self.assertEqual(
            self.chezmoi(
                "--override-data",
                json.dumps(
                    {
                        "chezmoi": {
                            "targetFile": str(self.destination / ".local/bin/tool")
                        }
                    }
                ),
                "execute-template",
                "--file",
                str(source),
            ),
            "",
        )

    def test_link_reads_command_owner_platform_and_install_dir_from_data(self) -> None:
        tool = self.tool()
        tool["bins"] = dict.fromkeys(("tool", "helper"), "{target}/{bin}")
        target = tool["targets"][self.target]
        tool["targets"] = {
            name: {
                **target,
                "resolved": {
                    **target["resolved"],
                    "files": {command: f"{name}/{command}" for command in tool["bins"]},
                },
            }
            for name in ("darwin-aarch64", "linux-x86_64")
        }
        bare = self.tool("file")
        bare["bin"] = "unrelated"
        bare["targets"][self.target]["resolved"]["asset"] = "unrelated"
        manifest = models.PortableManifest.model_validate(
            manifest_data({"a-bare-file": bare, "suite": tool})["portable_pkgs"]
        )
        manifest = manifest.updated(install_dir="custom/deep/bin")
        storage.PackageStore(path=self.manifest).save(manifest)
        sources = self.source / "custom/deep/bin"
        self.assertEqual(
            (sources / "symlink_tool.tmpl").read_text(),
            (sources / "symlink_helper.tmpl").read_text(),
        )
        for os_name, arch, target in (
            ("darwin", "arm64", "darwin-aarch64"),
            ("linux", "amd64", "linux-x86_64"),
        ):
            for command in tool["bins"]:
                with self.subTest(os=os_name, command=command):
                    destination = self.destination / manifest.install_dir / command
                    rendered = self.chezmoi(
                        "--override-data",
                        json.dumps({"chezmoi": {"os": os_name, "arch": arch}}),
                        "cat",
                        str(destination),
                    ).rstrip("\n")
                    self.assertFalse(Path(rendered).is_absolute())
                    self.assertEqual(
                        (destination.parent / rendered).resolve(),
                        (
                            self.destination
                            / ".local/share/portable-pkgs/suite"
                            / target
                            / command
                        ).resolve(),
                    )

    def test_install_update_remove_bundle_with_native_symlink(self) -> None:
        class QuietHandler(http.server.SimpleHTTPRequestHandler):
            def log_message(self, format: str, *args: Any) -> None:
                pass

        server = http.server.ThreadingHTTPServer(
            ("127.0.0.1", 0), functools.partial(QuietHandler, directory=str(self.base))
        )
        thread = threading.Thread(target=server.serve_forever)
        thread.start()
        try:
            self.make_tar(
                [("pkg/old.txt", b"old", 0o644), ("pkg/bin/link", "tool", 0o777)]
            )
            self.save()
            url = f"http://127.0.0.1:{server.server_port}/tool.tar.gz"

            remote = "https://github.com/demo/tool/releases/download/v1.0.0/tool.tar.gz"
            self.local_external(remote, url)
            self.chezmoi("apply")
            command = self.destination / ".local/bin/tool"
            bundle = self.destination / ".local/share/portable-pkgs/tool"
            self.assertTrue(command.is_symlink())
            self.assertEqual(
                command.readlink().as_posix(),
                "../../.local/share/portable-pkgs/tool/bin/tool",
            )
            self.assertEqual(
                subprocess.check_output([command], text=True).strip(), "tool-ok"
            )
            self.assertEqual((bundle / "share/data.txt").read_text(), "resource")
            self.assertTrue((bundle / "bin/link").is_symlink())
            self.make_tar()
            self.save()
            # Releases have distinct immutable URLs; avoid HTTP Last-Modified
            # timestamps hiding a same-second fixture rewrite.
            url += "?version=2"
            self.local_external(remote, url)
            self.chezmoi("--refresh-externals=always", "apply")
            self.assertFalse((bundle / "old.txt").exists())
            self.assertFalse((bundle / "bin/link").exists())
            result = self.invoke("remove", "tool")
            self.assertEqual(result.exit_code, 0, result.output)
            self.local_external(remote, url)
            self.chezmoi("apply")
            self.assertFalse(command.is_symlink())
            self.assertFalse(bundle.exists())
        finally:
            server.shutdown()
            server.server_close()
            thread.join()


if __name__ == "__main__":
    unittest.main()
