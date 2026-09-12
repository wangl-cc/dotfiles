"""Transport and archive contracts for portable packages."""

import gzip
import hashlib
import http.server
import io
import stat
import subprocess
import tarfile
import tempfile
import threading
import unittest
import zipfile
from contextlib import nullcontext
from pathlib import Path
from typing import Any
from unittest.mock import patch

import httpx
from githubkit_schemas.latest.models import (
    Release,
    ReleaseAsset,
    RepoSearchResultItem,
)

from portable_pkgs import github, installation, models
from portable_pkgs.archives import open_archive
from portable_pkgs.archives.tar import TarArchive
from portable_pkgs.archives.zip import ZipArchive
from portable_pkgs_support import fill_schema


def api_client(handler: Any) -> github.GitHubClient:
    return github.GitHubClient(api_transport=httpx.MockTransport(handler))


def release_payload(**overrides: Any) -> dict[str, Any]:
    return fill_schema(Release, **overrides)


class GitHubUrlTest(unittest.TestCase):
    def test_download_url_encodes_each_path_segment(self) -> None:
        tag = "release/v1.0.0#test?+%"
        asset = "tool #?+%雪"
        tool = models.FileSpec(type="file", repo="demo/tool", tag=tag, bin="tool")
        self.assertEqual(
            tool.download_url(asset),
            "https://github.com/demo/tool/releases/download/"
            "release%2Fv1.0.0%23test%3F%2B%25/tool%20%23%3F%2B%25%E9%9B%AA",
        )


class GitHubApiTest(unittest.TestCase):
    def test_fetch_release_requests_encoded_paths_and_parses(self) -> None:
        seen: list[httpx.Request] = []

        def handler(request: httpx.Request) -> httpx.Response:
            seen.append(request)
            return httpx.Response(
                200,
                json=release_payload(
                    tag_name="v1.0.0",
                    assets=[
                        fill_schema(
                            ReleaseAsset,
                            name="tool",
                            browser_download_url="https://example.invalid/tool",
                            digest=None,
                        )
                    ],
                ),
            )

        client = api_client(handler)
        release = client.fetch_release("demo/tool", "latest")
        self.assertEqual(seen[-1].url.path, "/repos/demo/tool/releases/latest")
        release = client.fetch_release("demo/tool", "release/v1.0.0#test?+%")
        self.assertEqual(
            seen[-1].url.raw_path,
            b"/repos/demo/tool/releases/tags/release%2Fv1.0.0%23test%3F%2B%25",
        )
        self.assertIsInstance(release, Release)
        self.assertEqual(release.tag_name, "v1.0.0")
        self.assertIsInstance(release.assets[0], ReleaseAsset)
        self.assertEqual(release.assets[0].name, "tool")
        self.assertIsNone(github.digest_sha256(release.assets[0].digest))

    def test_fetch_release_wraps_http_and_schema_errors(self) -> None:
        for response in (
            httpx.Response(503, json={"message": "unavailable"}),
            httpx.Response(200, json={"assets": []}),
        ):
            with self.subTest(status=response.status_code):
                client = api_client(lambda request, response=response: response)
                with self.assertRaisesRegex(models.PackageError, "GitHub API failed"):
                    client.fetch_release("demo/tool", "latest")

    def test_search_repositories_sends_policy_query_and_parses(self) -> None:
        seen: list[httpx.Request] = []

        def handler(request: httpx.Request) -> httpx.Response:
            seen.append(request)
            return httpx.Response(
                200,
                json={
                    "total_count": 1,
                    "incomplete_results": False,
                    "items": [
                        fill_schema(
                            RepoSearchResultItem,
                            name="tool",
                            full_name="demo/tool",
                        )
                    ],
                },
            )

        repositories = api_client(handler).search_repositories("tool", 5)
        params = seen[-1].url.params
        self.assertEqual(params["q"], "tool in:name fork:false archived:false")
        self.assertEqual(params["sort"], "stars")
        self.assertEqual(params["per_page"], "5")
        self.assertIsInstance(repositories, tuple)
        self.assertIsInstance(repositories[0], RepoSearchResultItem)
        self.assertEqual(repositories[0].full_name, "demo/tool")

    def test_search_repositories_wraps_http_errors(self) -> None:
        client = api_client(
            lambda request: httpx.Response(500, json={"message": "broken"})
        )
        with self.assertRaisesRegex(models.PackageError, "GitHub search failed"):
            client.search_repositories("tool", 5)

    def test_transport_errors_are_operational_errors(self) -> None:
        def fail(request: httpx.Request) -> httpx.Response:
            raise httpx.ConnectError("connection refused")

        client = api_client(fail)
        with self.assertRaisesRegex(models.PackageError, "GitHub API failed"):
            client.fetch_release("demo/tool", "latest")

    def test_api_and_download_clients_use_a_finite_timeout(self) -> None:
        client = github.GitHubClient()
        self.assertIs(client.api.config.timeout, github.TIMEOUT)
        self.assertEqual(client.http.timeout, github.TIMEOUT)
        self.assertEqual(github.TIMEOUT.connect, 30.0)


class GitHubClientLifecycleTest(unittest.TestCase):
    def test_context_closes_download_pool_on_success_and_failure(self) -> None:
        for fail in (False, True):
            with self.subTest(fail=fail):
                transport = httpx.MockTransport(lambda request: httpx.Response(200))
                with patch.object(transport, "close", wraps=transport.close) as close:
                    client = github.GitHubClient(token="", download_transport=transport)
                    outcome = (
                        self.assertRaises(models.PackageError)
                        if fail
                        else nullcontext()
                    )
                    with outcome, client as entered:
                        self.assertIs(entered, client)
                        self.assertFalse(client.http.is_closed)
                        if fail:
                            raise models.PackageError("operation failed")
                    self.assertTrue(client.http.is_closed)
                    close.assert_called_once_with()


class DownloadPolicyTest(unittest.TestCase):
    def test_credentials_are_only_added_to_trusted_https_origins(self) -> None:
        client = github.GitHubClient(token="synthetic-test")
        for url, expected in (
            ("https://api.github.com/repos/demo/tool", "Bearer synthetic-test"),
            ("https://github.com/demo/tool", "Bearer synthetic-test"),
            ("http://github.com/demo/tool", None),
            ("https://github.com:444/demo/tool", None),
            ("https://github.com.example.invalid/demo/tool", None),
            ("https://objects.githubusercontent.com/tool", None),
        ):
            with self.subTest(url=url):
                headers = client.download_headers(url)
                self.assertEqual(headers.get("Authorization"), expected)

    def test_unauthenticated_client_sends_no_authorization(self) -> None:
        client = github.GitHubClient(token=None)
        self.assertEqual(client.download_headers("https://github.com/demo/tool"), {})


class DownloadTransportTest(unittest.TestCase):
    def setUp(self) -> None:
        self.requests: list[tuple[str, str | None]] = []
        requests = self.requests

        class Handler(http.server.BaseHTTPRequestHandler):
            def do_GET(self) -> None:
                requests.append((self.path, self.headers.get("Authorization")))
                if self.path == "/redirect":
                    self.send_response(302)
                    self.send_header("Location", f"{other_url}/complete")
                    self.end_headers()
                    return
                if self.path == "/broken-chunk":
                    self.send_response(200)
                    self.send_header("Transfer-Encoding", "chunked")
                    self.end_headers()
                    self.wfile.write(b"5\r\nabc")
                    return
                if self.path in {"/gzip", "/gzip-truncated"}:
                    payload = gzip.compress(b"portable-asset" * 100)
                    self.send_response(200)
                    self.send_header("Content-Encoding", "gzip")
                    self.send_header("Content-Length", str(len(payload)))
                    self.end_headers()
                    if self.path == "/gzip-truncated":
                        payload = payload[:-8]
                    self.wfile.write(payload)
                    return
                if self.path == "/large":
                    payload = b"portable-package\x00" * 100_000
                    self.send_response(200)
                    self.send_header("Content-Length", str(len(payload)))
                    self.end_headers()
                    self.wfile.write(payload)
                    return
                self.send_response(200)
                self.send_header(
                    "Content-Length", "5100" if self.path == "/truncated" else "100"
                )
                self.end_headers()
                self.wfile.write(b"x" * 100)

            def log_message(self, format: str, *args: object) -> None:
                pass

        self.server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), Handler)
        self.other = http.server.ThreadingHTTPServer(("127.0.0.1", 0), Handler)
        other_url = f"http://127.0.0.1:{self.other.server_port}"
        self.threads = [
            threading.Thread(target=server.serve_forever)
            for server in (self.server, self.other)
        ]
        for thread in self.threads:
            thread.start()
        self.url = f"http://127.0.0.1:{self.server.server_port}"
        self.addCleanup(self.stop_servers)
        self.client = github.GitHubClient(token="")
        self.addCleanup(self.client.close)

    def stop_servers(self) -> None:
        for server in (self.server, self.other):
            server.shutdown()
            server.server_close()
        for thread in self.threads:
            thread.join()

    def test_download_rejects_truncation_and_removes_partial_file(self) -> None:
        client = self.client
        with tempfile.TemporaryDirectory() as directory:
            destination = Path(directory)
            for path in ("truncated", "broken-chunk", "gzip-truncated"):
                with (
                    self.subTest(path=path),
                    self.assertRaisesRegex(models.PackageError, "download failed"),
                ):
                    client.download_asset(f"{self.url}/{path}", destination)
                self.assertFalse((destination / path).exists())
            result = client.download_asset(f"{self.url}/complete", destination)
            self.assertEqual(result.path.read_bytes(), b"x" * 100)
            self.assertEqual(result.sha256, hashlib.sha256(b"x" * 100).hexdigest())

    def test_download_streams_and_hashes_the_complete_asset(self) -> None:
        payload = b"portable-package\x00" * 100_000
        with tempfile.TemporaryDirectory() as directory:
            result = self.client.download_asset(f"{self.url}/large", Path(directory))
            self.assertEqual(result.path.read_bytes(), payload)
            self.assertEqual(result.sha256, hashlib.sha256(payload).hexdigest())

    def test_gzip_length_uses_wire_bytes_and_hashes_decoded_asset(self) -> None:
        payload = b"portable-asset" * 100
        with tempfile.TemporaryDirectory() as directory:
            result = self.client.download_asset(f"{self.url}/gzip", Path(directory))
            self.assertEqual(result.path.read_bytes(), payload)
            self.assertEqual(result.sha256, hashlib.sha256(payload).hexdigest())

    def test_authorization_is_stripped_by_real_cross_origin_redirect(self) -> None:
        client = github.GitHubClient(token="synthetic-test")
        with (
            tempfile.TemporaryDirectory() as directory,
            # Force credentials onto an untrusted origin to prove the transport,
            # not the origin policy alone, blocks forwarding.
            patch.object(
                client,
                "download_headers",
                return_value={"Authorization": "Bearer synthetic-test"},
            ),
        ):
            client.download_asset(f"{self.url}/redirect", Path(directory))
        self.assertEqual(
            self.requests,
            [("/redirect", "Bearer synthetic-test"), ("/complete", None)],
        )

    def test_network_failures_are_operational_errors(self) -> None:
        def fail(request: httpx.Request) -> httpx.Response:
            raise httpx.ConnectError("connection refused")

        client = github.GitHubClient(download_transport=httpx.MockTransport(fail))
        with tempfile.TemporaryDirectory() as directory:
            with self.assertRaisesRegex(models.PackageError, "download failed"):
                client.download_asset("https://example.invalid/tool", Path(directory))
            self.assertFalse((Path(directory) / "tool").exists())


class DownloadCacheTest(unittest.TestCase):
    def test_download_reuse_checks_hash_and_keeps_same_names_separate(self) -> None:
        payloads = {"first": b"first", "second": b"second"}
        calls = 0

        def handler(request: httpx.Request) -> httpx.Response:
            nonlocal calls
            calls += 1
            payload = payloads[request.url.path.split("/")[1]]
            return httpx.Response(
                200,
                headers={"Content-Length": str(len(payload))},
                stream=httpx.ByteStream(payload),
            )

        client = github.GitHubClient(download_transport=httpx.MockTransport(handler))
        first_url = "https://example.invalid/first/tool.tar.gz"
        second_url = "https://example.invalid/second/tool.tar.gz"
        with tempfile.TemporaryDirectory() as directory:
            downloads = github.AssetDownloads(client, Path(directory))
            first = downloads.download(first_url)
            with self.assertRaisesRegex(models.PackageError, "sha256 mismatch"):
                downloads.download(first_url, "0" * 64)
            self.assertIs(downloads.download(first_url, first.sha256), first)
            second = downloads.download(
                second_url, hashlib.sha256(b"second").hexdigest()
            )
            self.assertNotEqual(first.path, second.path)
            self.assertEqual(first.path.read_bytes(), b"first")
            self.assertEqual(second.path.read_bytes(), b"second")
            self.assertEqual(calls, 2)


class BundleFixture(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.target = "linux-x86_64"
        self.archive = self.base / "tool.tar.gz"
        self.make_tar()

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

    def tool(self) -> dict[str, Any]:
        return {
            "type": "bundle",
            "repo": "demo/tool",
            "tag": "v1.0.0",
            "bins": {"tool": "bin/tool"},
            "strip_components": 1,
            "targets": {
                self.target: {
                    "asset_pattern": r"^tool\.tar\.gz$",
                    "resolved": {
                        "asset": self.archive.name,
                        "sha256": hashlib.sha256(self.archive.read_bytes()).hexdigest(),
                        "files": {"tool": "bin/tool"},
                    },
                },
            },
        }


class BundleVerificationTest(BundleFixture):
    def test_missing_selected_member_reports_an_operational_error(self) -> None:
        for extension in (".tar.gz", ".zip"):
            with self.subTest(extension=extension):
                archive = self.base / f"empty{extension}"
                if extension == ".zip":
                    with zipfile.ZipFile(archive, "w"):
                        pass
                else:
                    with tarfile.open(archive, "w:gz"):
                        pass
                with (
                    self.assertRaisesRegex(
                        models.PackageError, "archive member not found"
                    ),
                    open_archive(archive) as opened,
                ):
                    opened.extract_member("missing", self.base / "extract")

    def verify(self) -> Path:
        tool = models.BundleSpec.model_validate(self.tool())
        destination = self.base / "extracted"
        resolved = tool.targets[self.target].resolved
        assert resolved is not None
        installation.verify_archive(tool, self.archive, resolved, destination)
        return destination

    def test_preserves_resources_permissions_and_internal_link(self) -> None:
        self.make_tar([("pkg/bin/tool-link", "tool", 0o777)])
        destination = self.verify()
        self.assertEqual((destination / "share/data.txt").read_bytes(), b"resource")
        self.assertTrue((destination / "bin/tool-link").is_symlink())
        self.assertEqual((destination / "share/data.txt").stat().st_mode & 0o111, 0)
        self.assertEqual(
            subprocess.check_output([destination / "bin/tool-link"], text=True).strip(),
            "tool-ok",
        )

    def test_rejects_unsafe_unused_member_and_symlink(self) -> None:
        for entry in [
            ("pkg/../../escape", b"bad", 0o644),
            ("pkg/escape", "../outside", 0o777),
            ("pkg/escape", "/tmp/outside", 0o777),
            ("pkg/bin/tool", b"duplicate", 0o755),
            ("pkg/cycle", "cycle", 0o777),
            ("pkg/missing", "absent", 0o777),
        ]:
            with self.subTest(entry=entry[0:2]):
                self.make_tar([entry])
                with (
                    tempfile.TemporaryDirectory() as directory,
                    self.assertRaises(models.PackageError),
                    open_archive(self.archive) as opened,
                ):
                    installation.extract_bundle(opened, Path(directory), 1)

    def test_rejects_non_executable_entry(self) -> None:
        tool = models.BundleSpec.model_validate(self.tool())
        resolved = tool.targets[self.target].resolved
        assert resolved is not None
        resolved = resolved.updated(files={"tool": "share/data.txt"})
        with self.assertRaisesRegex(models.PackageError, "not executable"):
            installation.verify_archive(
                tool, self.archive, resolved, self.base / "extract"
            )

    def test_zip_permissions_and_links(self) -> None:
        archive_path = self.base / "tool.zip"
        with zipfile.ZipFile(archive_path, "w") as archive:
            for name, mode, data in [
                ("pkg/bin/tool", stat.S_IFREG | 0o755, b"#!/bin/sh\n"),
                ("pkg/link", stat.S_IFLNK | 0o777, b"bin/tool"),
            ]:
                member = zipfile.ZipInfo(name)
                member.create_system = 3
                member.external_attr = mode << 16
                archive.writestr(member, data)
        destination = self.base / "zip"
        with open_archive(archive_path) as opened:
            installation.extract_bundle(opened, destination, 1)
        self.assertTrue((destination / "link").is_symlink())
        self.assertTrue((destination / "bin/tool").stat().st_mode & 0o111)

    def test_rejects_hardlinks_before_extracting_members(self) -> None:
        with tarfile.open(self.archive, "w:gz") as archive:
            for name, target in [
                ("pkg/bin/alias", "pkg/bin/second"),
                ("pkg/bin/second", "pkg/bin/tool"),
            ]:
                member = tarfile.TarInfo(name)
                member.type = tarfile.LNKTYPE
                member.linkname = target
                archive.addfile(member)
            member = tarfile.TarInfo("pkg/bin/tool")
            member.mode = 0o755
            member.size = 4
            archive.addfile(member, io.BytesIO(b"tool"))
        for strip in (0, 1):
            destination = self.base / f"hardlink-{strip}"
            with (
                self.assertRaisesRegex(
                    models.PackageError, "hardlinks are not supported"
                ),
                open_archive(self.archive) as opened,
            ):
                installation.extract_bundle(opened, destination, strip)
            self.assertFalse(destination.exists())


class ArchiveInspectionTest(unittest.TestCase):
    def test_tar_inspection_lists_raw_paths_types_and_links_without_extracting(
        self,
    ) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            path = root / "tool.tar.gz"
            with tarfile.open(path, "w:gz") as archive:
                for name, kind, link, data, mode in (
                    ("pkg", tarfile.DIRTYPE, "", b"", 0o755),
                    ("pkg/tool", tarfile.REGTYPE, "", b"tool", 0o751),
                    ("pkg/link", tarfile.SYMTYPE, "tool", b"", 0o777),
                    ("pkg/hard", tarfile.LNKTYPE, "pkg/tool", b"", 0o644),
                    ("../escape", tarfile.REGTYPE, "", b"x", 0o600),
                    ("pkg/pipe", tarfile.FIFOTYPE, "", b"", 0o640),
                ):
                    member = tarfile.TarInfo(name)
                    member.type, member.linkname, member.mode = kind, link, mode
                    member.size = len(data)
                    archive.addfile(member, io.BytesIO(data))
            with open_archive(path) as archive:
                members = archive.members()
            self.assertIsInstance(members, tuple)
            self.assertEqual(
                [(m.path, m.kind, m.mode, m.link_target, m.size) for m in members],
                [
                    ("pkg", "directory", 0o755, None, 0),
                    ("pkg/tool", "file", 0o751, None, 4),
                    ("pkg/link", "symlink", 0o777, "tool", 0),
                    ("pkg/hard", "hardlink", 0o644, "pkg/tool", 0),
                    ("../escape", "file", 0o600, None, 1),
                    ("pkg/pipe", "other", 0o640, None, 0),
                ],
            )
            self.assertEqual(list(root.iterdir()), [path])

    def test_zip_inspection_lists_permissions_and_symlink_targets_without_extracting(
        self,
    ) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            path = root / "tool.zip"
            with zipfile.ZipFile(path, "w") as archive:
                for name, mode, data in (
                    ("pkg/", stat.S_IFDIR | 0o755, b""),
                    ("pkg/tool", stat.S_IFREG | 0o751, b"tool"),
                    ("pkg/link", stat.S_IFLNK | 0o777, b"tool"),
                    ("../escape", stat.S_IFREG | 0o600, b"x"),
                    ("pkg/pipe", stat.S_IFIFO | 0o640, b""),
                ):
                    member = zipfile.ZipInfo(name)
                    member.create_system = 3
                    member.external_attr = mode << 16
                    archive.writestr(member, data)
            with open_archive(path) as archive:
                members = archive.members()
            self.assertEqual(
                [(m.path, m.kind, m.mode, m.link_target, m.size) for m in members],
                [
                    ("pkg/", "directory", 0o755, None, 0),
                    ("pkg/tool", "file", 0o751, None, 4),
                    ("pkg/link", "symlink", 0o777, "tool", 4),
                    ("../escape", "file", 0o600, None, 1),
                    ("pkg/pipe", "other", 0o640, None, 0),
                ],
            )
            self.assertEqual(list(root.iterdir()), [path])


class ArchiveLifetimeTest(unittest.TestCase):
    def make_archive(self, path: Path) -> None:
        if path.suffix == ".zip":
            with zipfile.ZipFile(path, "w") as archive:
                archive.writestr("one", b"one")
                archive.writestr("two", b"two")
            return
        with tarfile.open(path, "w:gz") as archive:
            for name in ("one", "two"):
                member = tarfile.TarInfo(name)
                member.size = 3
                archive.addfile(member, io.BytesIO(name.encode()))

    def test_factory_closes_both_formats_on_success_and_consumer_failure(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            for extension, backend in ((".tar.gz", TarArchive), (".zip", ZipArchive)):
                path = Path(directory) / f"tool{extension}"
                self.make_archive(path)
                for fail in (False, True):
                    with self.subTest(extension=extension, fail=fail):
                        try:
                            with open_archive(path) as archive:
                                self.assertIsInstance(archive, backend)
                                self.assertEqual(
                                    [member.path for member in archive.members()],
                                    ["one", "two"],
                                )
                                if fail:
                                    raise RuntimeError("consumer failed")
                        except RuntimeError as error:
                            self.assertTrue(fail)
                            self.assertEqual(str(error), "consumer failed")
                        with self.assertRaises((OSError, ValueError)):
                            archive.extract_member(
                                "one", Path(directory) / "after-close"
                            )

    def test_selected_members_share_one_open_archive(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            for extension, library, method in (
                (".tar.gz", tarfile, "open"),
                (".zip", zipfile, "ZipFile"),
            ):
                path = Path(directory) / f"tool{extension}"
                self.make_archive(path)
                tool = models.ArchiveFilesSpec(
                    type="archive-files",
                    repo="demo/tool",
                    bins={"one": "one", "two": "two"},
                )
                resolved = models.ResolvedArchive(
                    asset=path.name, sha256="a" * 64, files={"one": "one", "two": "two"}
                )
                destination = Path(directory) / extension.removeprefix(".")
                with patch.object(
                    library, method, wraps=getattr(library, method)
                ) as opened:
                    installation.verify_archive(tool, path, resolved, destination)
                opened.assert_called_once()
                self.assertEqual((destination / "one").read_bytes(), b"one")
                self.assertEqual((destination / "two").read_bytes(), b"two")

    def test_both_formats_reject_symlink_parent_before_extraction(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for extension in (".tar.gz", ".zip"):
                path = root / f"tree{extension}"
                destination = root / extension.removeprefix(".")
                if extension == ".zip":
                    with zipfile.ZipFile(path, "w") as archive:
                        link = zipfile.ZipInfo("pkg/link")
                        link.external_attr = (stat.S_IFLNK | 0o777) << 16
                        archive.writestr(link, "bin")
                        archive.writestr("pkg/link/child", "payload")
                else:
                    with tarfile.open(path, "w:gz") as archive:
                        link = tarfile.TarInfo("pkg/link")
                        link.type, link.linkname = tarfile.SYMTYPE, "bin"
                        archive.addfile(link)
                        child = tarfile.TarInfo("pkg/link/child")
                        child.size = 7
                        archive.addfile(child, io.BytesIO(b"payload"))
                with (
                    self.subTest(extension=extension),
                    self.assertRaisesRegex(models.PackageError, "non-directory parent"),
                    open_archive(path) as archive,
                ):
                    installation.extract_bundle(archive, destination, 1)
                self.assertFalse(destination.exists())

    def test_corrupt_formats_report_archive_context(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for extension in (".tar.gz", ".zip"):
                path = root / f"bad{extension}"
                path.write_bytes(b"not an archive")
                with (
                    self.assertRaisesRegex(models.PackageError, "archive .*bad"),
                    open_archive(path) as archive,
                ):
                    archive.members()


if __name__ == "__main__":
    unittest.main()
