"""Render package previews, listings, and release asset views."""

import json
import re
from collections.abc import Sequence

from githubkit_schemas.latest.models import Release, RepoSearchResultItem

from .github import digest_sha256
from .models import (
    ArchiveSpecBase,
    PackageSpec,
    PortableManifest,
    ResolvedArchive,
    is_archive_name,
)
from .tables import (
    AddFormat,
    Column,
    OutputFormat,
    print_rows,
    render_listing,
)

KIB = 1024


def package_preview_rows(name: str, tool: PackageSpec) -> list[dict[str, object]]:
    return [
        {"field": "name", "value": name},
        {"field": "type", "value": tool.type},
        {"field": "repo", "value": tool.repo},
        {"field": "tag", "value": tool.tag},
        {"field": "bins", "value": tool.bin_names()},
        {
            "field": "path_patterns",
            "value": dict(tool.bins) if isinstance(tool, ArchiveSpecBase) else {},
        },
    ]


def target_preview_rows(
    tool: PackageSpec, target_names: list[str]
) -> list[dict[str, object]]:
    rows = []
    for target_name in target_names:
        target = tool.targets[target_name]
        resolved = target.resolved
        row: dict[str, object] = {
            "target": target_name,
            "asset_pattern": target.asset_pattern.pattern,
            "path_pattern": {
                name: tool.path_pattern(name, tool.targets[target_name])
                for name in tool.bins
            }
            if isinstance(tool, ArchiveSpecBase)
            else {},
        }
        if resolved is not None:
            row.update(
                {
                    "type": tool.type,
                    "asset": resolved.asset,
                    "path": dict(resolved.files)
                    if isinstance(resolved, ResolvedArchive)
                    else "-",
                    "sha256": resolved.sha256,
                }
            )
        rows.append(row)
    return rows


def print_add_preview(
    name: str,
    tool: PackageSpec,
    target_names: list[str],
    output_format: AddFormat,
) -> None:
    match output_format:
        case "human":
            print("Package")
            print(
                render_listing(
                    package_preview_rows(name, tool),
                    [
                        Column("field", "FIELD"),
                        Column("value", "VALUE"),
                    ],
                )
            )
            print()
            print("Targets")
            print(
                render_listing(
                    target_preview_rows(tool, target_names),
                    [
                        Column("target", "TARGET"),
                        Column("type", "TYPE"),
                        Column("asset", "ASSET"),
                        Column("path", "PATH"),
                        Column("asset_pattern", "ASSET_PATTERN"),
                        Column("path_pattern", "PATH_PATTERN"),
                        Column("sha256", "SHA256"),
                    ],
                )
            )
        case "json":
            print(
                json.dumps(
                    {
                        "name": name,
                        "tool": tool.model_dump(exclude_none=True, mode="json"),
                        "targets": target_names,
                    },
                    indent=2,
                )
            )


def tool_list_rows(manifest: PortableManifest) -> list[dict[str, object]]:
    return [
        {
            "name": name,
            "type": tool.type,
            "repo": tool.repo,
            "tag": tool.tag,
            "bin": tool.bin_names(),
            "targets": list(tool.targets),
        }
        for name, tool in manifest.tools.items()
    ]


def search_rows(
    repositories: Sequence[RepoSearchResultItem],
) -> list[dict[str, object]]:
    return [
        {
            "index": index,
            "repo": repository.full_name,
            "stars": repository.stargazers_count,
            "description": repository.description or "",
        }
        for index, repository in enumerate(repositories, start=1)
    ]


def print_search_rows(
    repositories: Sequence[RepoSearchResultItem], output_format: OutputFormat
) -> None:
    print_rows(
        search_rows(repositories),
        [
            Column("index", "#"),
            Column("repo", "REPOSITORY"),
            Column("stars", "STARS"),
            Column("description", "DESCRIPTION"),
        ],
        output_format,
    )


def asset_kind(asset_name: str) -> str:
    if is_archive_name(asset_name):
        return "archive"
    if re.search(r"\.(apk|deb|dmg|msi|pkg|rpm)$", asset_name, re.IGNORECASE):
        return "installer"
    return "file"


def format_size(value: object) -> str:
    if not isinstance(value, int):
        return "-"
    amount = float(value)
    for unit in ("B", "KiB", "MiB"):
        if amount < KIB:
            return f"{int(amount)} B" if unit == "B" else f"{amount:.1f} {unit}"
        amount /= KIB
    return f"{amount:.1f} GiB"


def release_asset_rows(release: Release) -> list[dict[str, object]]:
    rows: list[dict[str, object]] = []
    for index, asset in enumerate(release.assets, start=1):
        asset_name = asset.name
        rows.append(
            {
                "index": index,
                "name": asset_name,
                "kind": asset_kind(asset_name),
                "size": format_size(asset.size),
                "sha256": digest_sha256(asset.digest),
            }
        )
    return rows


def release_assets_payload(
    repo: str, release: Release, rows: list[dict[str, object]]
) -> dict[str, object]:
    return {
        "repo": repo,
        "tag": release.tag_name,
        "name": release.name,
        "assets": rows,
    }


def print_release_assets(
    repo: str,
    release: Release,
    output_format: OutputFormat,
) -> None:
    rows = release_asset_rows(release)
    match output_format:
        case "human":
            print(f"{repo} {release.tag_name}")
            print(
                render_listing(
                    rows,
                    [
                        Column("index", "#"),
                        Column("name", "ASSET"),
                        Column("kind", "TYPE"),
                        Column("size", "SIZE"),
                        Column("sha256", "SHA256"),
                    ],
                )
            )
        case "json":
            print(json.dumps(release_assets_payload(repo, release, rows), indent=2))
