"""Immutable package specifications and their validation boundaries."""

import re
import urllib.parse
from abc import ABC, abstractmethod
from collections.abc import Mapping
from pathlib import Path
from types import MappingProxyType
from typing import Annotated, Generic, Literal, Self, TypeVar

from pydantic import (
    AfterValidator,
    BaseModel,
    ConfigDict,
    Field,
    TypeAdapter,
    WrapSerializer,
    field_validator,
    model_validator,
)
from pydantic_extra_types.semantic_version import SemanticVersion

SCHEMA_VERSION = 8
PackageKind = Literal["file", "archive-files", "bundle"]
BUNDLE_ROOT = ".local/share/portable-pkgs"
GITHUB_SHA256_PREFIX = "sha256:"
TAR_SUFFIXES = (".tar.gz", ".tgz", ".tar.xz", ".txz", ".tar.bz2", ".tbz2")
ZIP_SUFFIXES = (".zip",)


def suffix_pattern(suffixes: tuple[str, ...]) -> re.Pattern[str]:
    return re.compile("(" + "|".join(map(re.escape, suffixes)) + ")$", re.IGNORECASE)


ARCHIVE_RE = suffix_pattern(TAR_SUFFIXES + ZIP_SUFFIXES)
TAR_RE = suffix_pattern(TAR_SUFFIXES)
ZIP_RE = suffix_pattern(ZIP_SUFFIXES)
TAG_PREFIX_RE = re.compile(r"^[^0-9]*")


class PackageError(Exception):
    """An operational failure presented by the CLI without a traceback."""


def parse_semantic_version(tag: str | None) -> SemanticVersion | None:
    if not tag:
        return None
    try:
        return SemanticVersion.parse(TAG_PREFIX_RE.sub("", tag, count=1))
    except ValueError:
        return None


def is_semantic_version_downgrade(
    current_tag: str | None, candidate_tag: str | None
) -> bool:
    current = parse_semantic_version(current_tag)
    candidate = parse_semantic_version(candidate_tag)
    if current is None or candidate is None:
        return False
    return candidate < current


def is_archive_name(name: str) -> bool:
    return bool(ARCHIVE_RE.search(name))


def require_relative_path(path: str, label: str) -> str:
    if not path:
        raise ValueError(f"{label} cannot be empty")
    candidate = Path(path)
    if (
        candidate.is_absolute()
        or ".." in candidate.parts
        or "\\" in path
        or any(char in path for char in "\x00\r\n")
        or not candidate.parts
    ):
        raise ValueError(f"{label} must be a relative path without '..': {path}")
    return path


def require_bin_name(name: str) -> str:
    if not name:
        raise ValueError("bin cannot be empty")
    if any(char in name for char in "/\\\x00\r\n") or name in {".", ".."}:
        raise ValueError(f"bin must be a single command name: {name}")
    return name


# Validated values are shared by configuration and API-boundary models.
CommandName = Annotated[str, AfterValidator(require_bin_name)]
RelativePath = Annotated[
    str, AfterValidator(lambda value: require_relative_path(value, "archive path"))
]
RegexPattern = re.Pattern[str]
NonEmptyString = Annotated[str, Field(min_length=1)]


def require_nonempty_regex(pattern: RegexPattern) -> RegexPattern:
    if not pattern.pattern:
        raise ValueError("asset regex cannot be empty")
    return pattern


AssetPattern = Annotated[RegexPattern, AfterValidator(require_nonempty_regex)]
SHA256 = Annotated[
    str,
    Field(pattern=r"^[0-9a-fA-F]{64}$"),
    AfterValidator(str.lower),
]
BinPattern = Annotated[str, Field(min_length=1)]


KeyT = TypeVar("KeyT")
ValueT = TypeVar("ValueT")


def freeze_mapping(value: Mapping[KeyT, ValueT]) -> Mapping[KeyT, ValueT]:
    # Copy before wrapping so later changes to a caller's dictionary cannot leak in.
    return MappingProxyType(dict(value))


FrozenMap = Annotated[
    Mapping[KeyT, ValueT],
    AfterValidator(freeze_mapping),
    WrapSerializer(lambda value, handler: handler(dict(value))),
]


class FrozenModel(BaseModel):
    """Validated snapshots; updates construct and validate a new snapshot."""

    model_config = ConfigDict(extra="forbid", frozen=True, validate_default=True)

    def updated(self, **changes: object) -> Self:
        values = {name: getattr(self, name) for name in type(self).model_fields}
        return type(self).model_validate(values | changes)


def require_file_asset(asset: str) -> str:
    if is_archive_name(asset):
        raise ValueError(f"type file cannot install asset {asset}")
    return asset


def require_archive_asset(asset: str) -> str:
    if not is_archive_name(asset):
        raise ValueError(f"archive package cannot install asset {asset}")
    return asset


class DownloadedAsset(FrozenModel):
    path: Path
    sha256: SHA256


class ResolvedFile(FrozenModel):
    asset: Annotated[str, AfterValidator(require_file_asset)]
    sha256: SHA256


class ResolvedArchive(FrozenModel):
    asset: Annotated[str, AfterValidator(require_archive_asset)]
    sha256: SHA256
    files: FrozenMap[CommandName, RelativePath] = Field(min_length=1)

    @field_validator("files")
    @classmethod
    def validate_distinct_files(cls, value: Mapping[str, str]) -> Mapping[str, str]:
        if len(set(value.values())) != len(value):
            raise ValueError("archive members must use distinct paths")
        return value


class TargetBase(FrozenModel):
    asset_pattern: AssetPattern


class FileTarget(TargetBase):
    resolved: ResolvedFile | None = None


class ArchiveTarget(TargetBase):
    bins: FrozenMap[CommandName, BinPattern] | None = None
    resolved: ResolvedArchive | None = None


TargetT = TypeVar("TargetT", bound=TargetBase)


class PackageBase(FrozenModel, ABC, Generic[TargetT]):
    repo: str
    tag: str | None = None
    targets: FrozenMap[str, TargetT] = Field(default_factory=dict)

    def download_url(self, asset_name: str) -> str:
        if not self.tag:
            raise PackageError(f"{self.repo} has no resolved tag")
        return (
            f"https://github.com/{self.repo}/releases/download/"
            f"{urllib.parse.quote(self.tag, safe='')}/"
            f"{urllib.parse.quote(asset_name, safe='')}"
        )

    @abstractmethod
    def bin_names(self) -> list[str]:
        raise NotImplementedError

    @abstractmethod
    def check_asset(self, asset: str) -> None:
        """Reject an asset name this package type cannot install."""
        raise NotImplementedError


class FileSpec(PackageBase[FileTarget]):
    type: Literal["file"]
    bin: CommandName

    def bin_names(self) -> list[str]:
        return [self.bin]

    def check_asset(self, asset: str) -> None:
        require_file_asset(asset)


class ArchiveSpecBase(PackageBase[ArchiveTarget]):
    bins: FrozenMap[CommandName, BinPattern] = Field(min_length=1)

    def bin_names(self) -> list[str]:
        return list(self.bins)

    def check_asset(self, asset: str) -> None:
        require_archive_asset(asset)

    def path_pattern(self, bin_name: str, target: ArchiveTarget) -> str:
        return (target.bins or {}).get(bin_name, self.bins[bin_name])

    @model_validator(mode="after")
    def validate_command_references(self) -> "ArchiveSpecBase":
        for target in self.targets.values():
            if not (target.bins or {}).keys() <= self.bins.keys():
                raise ValueError("target bins must refer to declared commands")
            if (
                target.resolved is not None
                and target.resolved.files.keys() != self.bins.keys()
            ):
                raise ValueError("resolved files must match bins")
        return self


class ArchiveFilesSpec(ArchiveSpecBase):
    type: Literal["archive-files"]


class BundleSpec(ArchiveSpecBase):
    type: Literal["bundle"]
    strip_components: int = Field(default=0, ge=0, strict=True)


PackageSpec = Annotated[
    FileSpec | ArchiveFilesSpec | BundleSpec, Field(discriminator="type")
]
PACKAGE_ADAPTER = TypeAdapter(PackageSpec)


class PortableManifest(FrozenModel):
    schema_version: int
    install_dir: RelativePath = ".local/bin"
    tools: FrozenMap[str, PackageSpec] = Field(default_factory=dict)

    @model_validator(mode="after")
    def validate_schema_version(self) -> "PortableManifest":
        if self.schema_version != SCHEMA_VERSION:
            raise ValueError(
                f"schema_version {self.schema_version}; expected {SCHEMA_VERSION}"
            )
        return self

    @model_validator(mode="after")
    def validate_command_ownership(self) -> Self:
        owners: dict[str, str] = {}
        for tool_name, tool in self.tools.items():
            for bin_name in tool.bin_names():
                if owner := owners.get(bin_name):
                    raise ValueError(
                        f"binary destination {bin_name!r} is owned by both "
                        f"{owner} and {tool_name}"
                    )
                owners[bin_name] = tool_name
        return self

    @model_validator(mode="after")
    def validate_bundle_destinations(self) -> Self:
        for tool_name, tool in self.tools.items():
            if tool.type != "bundle":
                continue
            if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._+-]*", tool_name):
                raise ValueError(f"unsafe bundle package name: {tool_name}")
            for bin_name in tool.bin_names():
                if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._+-]*", bin_name):
                    raise ValueError(f"unsafe bundle command name: {bin_name}")
            bundle_dir = Path(BUNDLE_ROOT) / tool_name
            install_dir = Path(self.install_dir)
            if install_dir.is_relative_to(bundle_dir) or bundle_dir.is_relative_to(
                install_dir
            ):
                raise ValueError("bundle directory and install_dir cannot overlap")
        return self

    def selected_tools(self, name: str | None) -> list[tuple[str, PackageSpec]]:
        if name is None:
            return list(self.tools.items())
        tool = self.tools.get(name)
        if tool is None:
            raise PackageError(f"tool not found: {name}")
        return [(name, tool)]

    def with_package(self, name: str, package: PackageSpec) -> "PortableManifest":
        """Validate a candidate package and its destinations before accepting it."""
        return self.updated(tools={**self.tools, name: package})

    def without_package(self, name: str) -> Self:
        if name not in self.tools:
            raise PackageError(f"tool not found: {name}")
        return self.updated(
            tools={key: package for key, package in self.tools.items() if key != name}
        )
