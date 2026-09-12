"""Shared archive installation policy, independent of tar and ZIP encoding."""

import posixpath
import re
from collections.abc import Sequence
from pathlib import Path

from .archives import open_archive
from .archives.base import Archive, ArchiveMember, InstalledMember, assert_safe_member
from .models import (
    ARCHIVE_RE,
    ArchiveFilesSpec,
    BundleSpec,
    PackageBase,
    PackageError,
    ResolvedArchive,
)


def plan_bundle(
    members: Sequence[ArchiveMember], strip_components: int
) -> tuple[InstalledMember, ...]:
    """Validate the entire installed tree before any member is extracted."""
    entries = []
    seen: dict[str, str] = {}
    links: dict[str, str] = {}
    for member in members:
        assert_safe_member(member.path)
        parts = Path(member.path).parts[strip_components:]
        if not parts:
            if member.kind != "directory":
                raise PackageError(f"strip_components removes file: {member.path}")
            continue
        name = "/".join(parts)
        if member.kind == "hardlink":
            raise PackageError(
                "tar hardlinks are not supported by chezmoi bundle "
                f"installation: {member.path}"
            )
        if member.kind == "other":
            raise PackageError(f"unsupported bundle member: {member.path}")
        if name in seen and (member.kind != "directory" or seen[name] != "directory"):
            raise PackageError(f"duplicate bundle path: {name}")
        seen[name] = member.kind
        if member.link_target is not None:
            links[name] = resolve_bundle_link(name, member.link_target)
        entries.append(InstalledMember(member, name))
    validate_bundle_tree(seen, links)
    return tuple(entries)


def resolve_bundle_link(name: str, link: str) -> str:
    if "\\" in link or "\x00" in link or posixpath.isabs(link):
        raise PackageError(f"unsafe bundle link: {name} -> {link}")
    target = posixpath.normpath(posixpath.join(posixpath.dirname(name), link))
    if target == ".." or target.startswith("../"):
        raise PackageError(f"bundle link escapes installation: {name} -> {link}")
    return target


def validate_bundle_tree(seen: dict[str, str], links: dict[str, str]) -> None:
    for name in seen:
        for parent in Path(name).parents:
            if str(parent) in seen and seen[str(parent)] != "directory":
                raise PackageError(f"bundle member has non-directory parent: {name}")
    for name, target in links.items():
        visited = {name}
        current = target
        while current in links:
            if current in visited:
                raise PackageError(f"cyclic bundle link: {name}")
            visited.add(current)
            current = links[current]


def extract_bundle(archive: Archive, destination: Path, strip_components: int) -> None:
    entries = plan_bundle(archive.members(), strip_components)
    destination.mkdir(parents=True, exist_ok=True)
    archive.extract_tree(entries, destination)
    root = destination.resolve()
    for entry in entries:
        if entry.member.kind != "symlink":
            continue
        try:
            target = (destination / entry.path).resolve(strict=True)
        except (OSError, RuntimeError) as error:
            raise PackageError(f"invalid bundle link: {entry.path}: {error}") from error
        if not target.is_relative_to(root):
            raise PackageError(f"bundle link escapes installation: {entry.path}")


def verify_archive(
    tool: ArchiveFilesSpec | BundleSpec,
    archive_path: Path,
    resolved: ResolvedArchive,
    destination: Path,
) -> None:
    with open_archive(archive_path) as archive:
        bundle = tool if isinstance(tool, BundleSpec) else None
        if bundle is not None:
            extract_bundle(archive, destination, bundle.strip_components)
        for path in resolved.files.values():
            extracted = (
                destination / path
                if bundle is not None
                else archive.extract_member(path, destination)
            )
            if not extracted.is_file():
                raise PackageError(f"archive path is not a file: {path}")
            if bundle is not None and not (extracted.stat().st_mode & 0o111):
                raise PackageError(f"bundle command is not executable: {path}")


def render_path_pattern(
    pattern: str,
    tool: PackageBase,
    target_name: str,
    asset_name: str,
    bin_name: str,
) -> str:
    if not tool.tag:
        raise PackageError(f"{tool.repo} has no resolved tag")
    values = {
        "asset": asset_name,
        "assetStem": ARCHIVE_RE.sub("", asset_name),
        "bin": bin_name,
        "repo": tool.repo,
        "tag": tool.tag,
        "target": target_name,
        "version": tool.tag.removeprefix("v"),
    }

    def replace(match: re.Match[str]) -> str:
        key = match.group(1)
        if key not in values:
            raise PackageError(f"unknown path_pattern variable: {{{key}}}")
        return values[key]

    return re.sub(r"\{([A-Za-z][A-Za-z0-9_]*)\}", replace, pattern)
