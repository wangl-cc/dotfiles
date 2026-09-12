"""GitHub API boundary via githubkit; verified asset downloads over httpx."""

import hashlib
import os
import urllib.parse
from contextlib import AbstractContextManager
from pathlib import Path
from types import TracebackType

import httpx
from githubkit import (
    BaseAuthStrategy,
    GitHub,
    TokenAuthStrategy,
    UnauthAuthStrategy,
)
from githubkit.exception import GitHubException
from githubkit_schemas.latest.models import Release, RepoSearchResultItem
from pydantic import TypeAdapter

from .models import GITHUB_SHA256_PREFIX, SHA256, DownloadedAsset, PackageError

TIMEOUT = httpx.Timeout(30.0)
# Downloads authenticate only to GitHub's own HTTPS origins. httpx strips the
# Authorization header when a redirect leaves the origin, so release-asset
# redirects to the CDN never receive credentials.
DOWNLOAD_ORIGINS = {"api.github.com", "github.com"}


class GitHubClient(AbstractContextManager["GitHubClient"]):
    """One GitHub API client plus one streaming client for asset downloads."""

    def __init__(
        self,
        token: str | None = None,
        *,
        base_url: str | None = None,
        api_transport: httpx.BaseTransport | None = None,
        download_transport: httpx.BaseTransport | None = None,
    ) -> None:
        if token is None:
            token = os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN")
        self.token = token
        auth: BaseAuthStrategy = (
            TokenAuthStrategy(token) if token else UnauthAuthStrategy()
        )
        # githubkit defaults cover rate-limit and server-error retries.
        self.api = GitHub(
            auth,
            user_agent="portable-pkgs",
            timeout=TIMEOUT,
            base_url=base_url,
            transport=api_transport,
        )
        self.http = httpx.Client(
            timeout=TIMEOUT,
            follow_redirects=True,
            headers={"User-Agent": "portable-pkgs"},
            transport=download_transport,
        )

    def close(self) -> None:
        # githubkit closes each API request's client itself; we own this pool.
        self.http.close()

    def __exit__(
        self,
        exc_type: type[BaseException] | None,
        exc_value: BaseException | None,
        traceback: TracebackType | None,
    ) -> None:
        self.close()

    def fetch_release(self, repo: str, tag: str) -> Release:
        owner, name = repo.split("/")
        try:
            response = (
                self.api.rest.repos.get_latest_release(owner, name)
                if tag == "latest"
                # githubkit passes path parameters through unquoted.
                else self.api.rest.repos.get_release_by_tag(
                    owner, name, urllib.parse.quote(tag, safe="")
                )
            )
            return response.parsed_data
        except (GitHubException, ValueError) as error:
            raise PackageError(
                f"GitHub API failed for {repo}@{tag}: {error}"
            ) from error

    def search_repositories(
        self, query: str, limit: int
    ) -> tuple[RepoSearchResultItem, ...]:
        try:
            return tuple(
                self.api.rest.search.repos(
                    q=f"{query} in:name fork:false archived:false",
                    sort="stars",
                    order="desc",
                    per_page=limit,
                ).parsed_data.items
            )
        except (GitHubException, ValueError) as error:
            raise PackageError(
                f"GitHub search failed for {query!r}: {error}"
            ) from error

    def download_headers(self, url: str) -> dict[str, str]:
        origin = urllib.parse.urlsplit(url)
        if (
            self.token
            and origin.scheme == "https"
            and origin.hostname in DOWNLOAD_ORIGINS
            and origin.port in {None, 443}
        ):
            return {"Authorization": f"Bearer {self.token}"}
        return {}

    def download_asset(self, url: str, directory: Path) -> DownloadedAsset:
        filename = Path(urllib.parse.urlparse(url).path).name
        output = directory / filename
        received = 0
        try:
            with (
                self.http.stream(
                    "GET", url, headers=self.download_headers(url)
                ) as response,
                output.open("wb") as stream,
            ):
                response.raise_for_status()
                for chunk in response.iter_bytes():
                    stream.write(chunk)
                # Content-Length describes the encoded HTTP body. iter_bytes()
                # decodes content encodings before writing the asset to disk.
                received = response.num_bytes_downloaded
                length = response.headers.get("Content-Length")
            if length is not None and (
                not length.isascii()
                or not length.isdecimal()
                or received != int(length)
            ):
                raise PackageError(
                    f"download failed for {url}: expected Content-Length {length}, "
                    f"received {received} bytes"
                )
        except httpx.HTTPError as error:
            output.unlink(missing_ok=True)
            raise PackageError(f"download failed for {url}: {error}") from error
        except BaseException:
            output.unlink(missing_ok=True)
            raise
        with output.open("rb") as stream:
            sha256 = hashlib.file_digest(stream, "sha256").hexdigest()
        return DownloadedAsset(path=output, sha256=sha256)


class AssetDownloads:
    """Reuse assets within the caller's temporary directory, checking each request."""

    def __init__(self, github: GitHubClient, directory: Path) -> None:
        self.github = github
        self.directory = directory
        self.assets: dict[str, DownloadedAsset] = {}

    def download(self, url: str, expected_sha256: str | None = None) -> DownloadedAsset:
        try:
            if url not in self.assets:
                destination = self.directory / str(len(self.assets))
                destination.mkdir(exist_ok=True)
                self.assets[url] = self.github.download_asset(url, destination)
            downloaded = self.assets[url]
            if expected_sha256 is not None and downloaded.sha256 != expected_sha256:
                raise PackageError(
                    f"sha256 mismatch for {url}: "
                    f"expected {expected_sha256}, got {downloaded.sha256}"
                )
            return downloaded
        except OSError as error:
            raise PackageError(f"asset download {url}: {error}") from error


def digest_sha256(digest: str | None) -> str | None:
    if digest and digest.startswith(GITHUB_SHA256_PREFIX):
        return TypeAdapter(SHA256).validate_python(digest[len(GITHUB_SHA256_PREFIX) :])
    return None


def normalize_repo(repo: str) -> str:
    value = repo.strip().removeprefix("https://github.com/")
    value = value.removesuffix(".git").strip("/")
    if value.count("/") != 1 or not all(value.split("/")):
        raise PackageError("expected GitHub repository as OWNER/REPO")
    return value
