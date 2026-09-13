"""Deterministic package resolution and immutable update plans."""

import logging
import tempfile
from collections.abc import Iterator, Sequence
from contextlib import contextmanager
from dataclasses import dataclass
from pathlib import Path

from githubkit_schemas.latest.models import Release, ReleaseAsset

from .github import (
    AssetDownloads,
    GitHubClient,
    default_cache_directory,
    digest_sha256,
)
from .installation import render_path_pattern, verify_archive
from .models import (
    ArchiveSpecBase,
    BundleSpec,
    FileSpec,
    PackageError,
    PackageSpec,
    PortableManifest,
    ResolvedArchive,
    ResolvedFile,
    is_semantic_version_downgrade,
)
from .requests import AddOptions

logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class ToolTarget:
    """One target of one package version, ready to verify or report."""

    tool_name: str
    tool: PackageSpec
    target_name: str


@dataclass(frozen=True)
class SkippedDowngrade:
    """A package left at its configured tag because GitHub's latest is older."""

    tool_name: str
    configured_tag: str | None
    candidate_tag: str


@dataclass(frozen=True)
class PreparedAdd:
    manifest: PortableManifest
    targets: tuple[str, ...]


@dataclass(frozen=True)
class PreparedUpdate:
    manifest: PortableManifest
    updated: tuple[ToolTarget, ...]
    skipped: tuple[SkippedDowngrade, ...]


class PackageOperations:
    def __init__(self, downloads: AssetDownloads) -> None:
        self.downloads = downloads

    @classmethod
    @contextmanager
    def open(cls, github: GitHubClient) -> Iterator["PackageOperations"]:
        with tempfile.TemporaryDirectory(prefix="portable-pkgs-") as workspace:
            yield cls(
                AssetDownloads(
                    github,
                    Path(workspace),
                    cache_directory=default_cache_directory(),
                )
            )

    @staticmethod
    def select(tool: PackageSpec, target_name: str, release: Release) -> ReleaseAsset:
        pattern = tool.targets[target_name].asset_pattern
        matches = [asset for asset in release.assets if pattern.search(asset.name)]
        if len(matches) != 1:
            names = "\n".join(f"  - {asset.name}" for asset in release.assets)
            raise PackageError(
                f"asset_pattern {pattern.pattern!r} matched {len(matches)} "
                f"assets:\n{names}"
            )
        asset = matches[0]
        try:
            tool.check_asset(asset.name)
        except ValueError as error:
            raise PackageError(f"select {tool.repo}/{target_name}: {error}") from error
        return asset

    def resolve(
        self, tool: PackageSpec, target_name: str, asset: ReleaseAsset
    ) -> ResolvedFile | ResolvedArchive:
        """Return resolved metadata without changing the package or target."""
        try:
            sha256 = (
                digest_sha256(asset.digest)
                or self.downloads.download(asset.browser_download_url).sha256
            )
            if isinstance(tool, FileSpec):
                return ResolvedFile(asset=asset.name, sha256=sha256)
            target = tool.targets[target_name]
            return ResolvedArchive(
                asset=asset.name,
                sha256=sha256,
                files={
                    name: render_path_pattern(
                        tool.path_pattern(name, target),
                        tool,
                        target_name,
                        asset.name,
                        name,
                    )
                    for name in tool.bins
                },
            )
        except ValueError as error:
            raise PackageError(f"resolve {tool.repo}/{target_name}: {error}") from error

    def resolve_targets(
        self, tool: PackageSpec, names: Sequence[str], release: Release
    ) -> PackageSpec:
        targets = dict(tool.targets)
        for name in names:
            logger.info("resolve target %s/%s", tool.repo, name)
            resolved = self.resolve(tool, name, self.select(tool, name, release))
            targets[name] = tool.targets[name].updated(resolved=resolved)
        return tool.updated(targets=targets)

    def prepare_add(
        self, manifest: PortableManifest, request: AddOptions
    ) -> PreparedAdd:
        existing = manifest.tools.get(request.name)
        candidate = request.candidate(existing)
        requested_tag = candidate.tag if candidate.tag is not None else "latest"
        logger.info("resolve %s: %s@%s", request.name, candidate.repo, requested_tag)
        release = self.downloads.github.fetch_release(candidate.repo, requested_tag)
        if (
            existing is not None
            and existing.repo == candidate.repo
            and request.tag is None
            and is_semantic_version_downgrade(existing.tag, release.tag_name)
        ):
            raise PackageError(
                f"release {release.tag_name} is older than configured "
                f"{existing.tag}; pass --tag to downgrade explicitly"
            )
        candidate = candidate.updated(tag=release.tag_name)
        selected = request.resolution_targets(existing, candidate)
        candidate = self.resolve_targets(candidate, selected, release)
        return PreparedAdd(manifest.with_package(request.name, candidate), selected)

    def prepare_update(
        self, manifest: PortableManifest, selected_name: str | None, tag: str | None
    ) -> PreparedUpdate:
        replacements = dict(manifest.tools)
        updated: list[ToolTarget] = []
        skipped: list[SkippedDowngrade] = []
        selected = manifest.selected_tools(selected_name)
        for index, (name, tool) in enumerate(selected, 1):
            if not tool.targets:
                raise PackageError(f"{name} has no targets")
            logger.info(
                "resolve [%d/%d] %s: %s@%s",
                index,
                len(selected),
                name,
                tool.repo,
                tag or "latest",
            )
            release = self.downloads.github.fetch_release(tool.repo, tag or "latest")
            if tag is None and is_semantic_version_downgrade(
                tool.tag, release.tag_name
            ):
                skipped.append(SkippedDowngrade(name, tool.tag, release.tag_name))
                continue
            candidate = self.resolve_targets(
                tool.updated(tag=release.tag_name), tuple(tool.targets), release
            )
            replacements[name] = candidate
            updated.extend(
                ToolTarget(name, candidate, target) for target in candidate.targets
            )
        return PreparedUpdate(
            manifest.updated(tools=replacements), tuple(updated), tuple(skipped)
        )

    def verify_target(self, item: ToolTarget) -> None:
        resolved = item.tool.targets[item.target_name].resolved
        if resolved is None:
            raise PackageError(
                f"{item.tool_name}/{item.target_name} is missing resolved metadata"
            )
        try:
            with tempfile.TemporaryDirectory(prefix="portable-pkgs-") as tmp:
                downloaded = self.downloads.download(
                    item.tool.download_url(resolved.asset), resolved.sha256
                )
                if isinstance(item.tool, ArchiveSpecBase) and isinstance(
                    resolved, ResolvedArchive
                ):
                    verify_archive(
                        item.tool, downloaded.path, resolved, Path(tmp) / "extract"
                    )
        except OSError as error:
            raise PackageError(
                f"verify {item.tool_name}/{item.target_name}: {error}"
            ) from error

    def verify_many(self, items: Sequence[ToolTarget]) -> None:
        failures: list[str] = []
        for index, item in enumerate(items, 1):
            logger.info(
                "verify [%d/%d] %s/%s",
                index,
                len(items),
                item.tool_name,
                item.target_name,
            )
            try:
                self.verify_target(item)
            except PackageError as error:
                failures.append(str(error))
        if failures:
            raise PackageError(
                f"verify failed for {len(failures)} target(s):\n" + "\n".join(failures)
            )
        if items:
            logger.info("verification passed: %d targets", len(items))


def verification_required(tool: PackageSpec, *, requested: bool = False) -> bool:
    return requested or isinstance(tool, BundleSpec) or len(tool.bin_names()) > 1
