"""Validated add inputs and pure configuration inheritance, before release I/O."""

from collections.abc import Sequence
from typing import Annotated, Self

from pydantic import AfterValidator, AliasChoices, ConfigDict, Field, model_validator
from pydantic_settings import CliPositionalArg

from .github import normalize_repo
from .models import (
    PACKAGE_ADAPTER,
    ArchiveSpecBase,
    ArchiveTarget,
    AssetPattern,
    BinPattern,
    BundleSpec,
    CommandName,
    FileTarget,
    FrozenMap,
    FrozenModel,
    NonEmptyString,
    PackageError,
    PackageKind,
    PackageSpec,
)


class AddOptions(FrozenModel):
    """One input schema shared by CLI parsing and package preparation.

    Sequence and Mapping retain native CLI collection parsing; validation stores
    tuples and immutable mappings, so no second request model is needed.
    """

    model_config = ConfigDict(validate_by_name=True)

    name: CliPositionalArg[CommandName]
    package_type: PackageKind = Field(alias="type")
    repo: str | None = None
    tag: str | None = None
    target_assets: FrozenMap[NonEmptyString, AssetPattern] = Field(
        default_factory=dict,
        validation_alias=AliasChoices("T", "target-asset"),
        description="TARGET=REGEX or JSON; required for a new package.",
    )
    bin_names: Annotated[Sequence[CommandName], AfterValidator(tuple)] = Field(
        default=(),
        alias="bin",
        description="Declared command; repeat for multiple commands.",
    )
    path_pattern: BinPattern | None = None
    paths: FrozenMap[CommandName, BinPattern] = Field(default_factory=dict)
    target_paths: FrozenMap[NonEmptyString, FrozenMap[CommandName, BinPattern]] = Field(
        default_factory=dict
    )
    strip_components: Annotated[int | None, Field(ge=0)] = None

    @model_validator(mode="after")
    def validate_options(self) -> Self:
        if self.package_type != "bundle" and self.strip_components is not None:
            raise ValueError("--strip-components requires --type bundle")
        if self.package_type == "file" and (
            self.path_pattern is not None or self.paths or self.target_paths
        ):
            raise ValueError("file packages cannot use archive path options")
        if self.path_pattern is not None and self.paths:
            raise ValueError("--path-pattern and --paths cannot be combined")
        return self

    def commands_for(self, existing: PackageSpec | None) -> tuple[str, ...]:
        if self.bin_names:
            commands = tuple(dict.fromkeys(self.bin_names))
        elif existing is not None:
            commands = tuple(existing.bin_names())
        else:
            commands = (self.name,)
        if existing is not None and set(commands) != set(existing.bin_names()):
            raise PackageError(
                "cannot change binaries for existing package; remove and re-add it"
            )
        return commands

    def paths_for(
        self, existing: PackageSpec | None, commands: tuple[str, ...]
    ) -> dict[str, str]:
        if self.paths:
            paths = dict(self.paths)
        elif self.path_pattern is not None:
            paths = dict.fromkeys(commands, self.path_pattern)
        elif isinstance(existing, ArchiveSpecBase):
            paths = dict(existing.bins)
        else:
            paths = {}
        if set(paths) != set(commands):
            raise PackageError(
                "archive packages require --path-pattern or --paths "
                "covering every declared command"
            )
        if (
            isinstance(existing, ArchiveSpecBase)
            and len(commands) > 1
            and paths != existing.bins
        ):
            raise PackageError(
                "cannot change shared path patterns for existing "
                "multi-command package; remove and re-add it"
            )
        return paths

    def targets_for(
        self, existing: PackageSpec | None
    ) -> dict[str, FileTarget | ArchiveTarget]:
        targets: dict[str, FileTarget | ArchiveTarget] = (
            dict(existing.targets) if existing else {}
        )
        for name, pattern in self.target_assets.items():
            if name in targets:
                targets[name] = targets[name].updated(
                    asset_pattern=pattern, resolved=None
                )
            elif self.package_type == "file":
                targets[name] = FileTarget(asset_pattern=pattern)
            else:
                targets[name] = ArchiveTarget(asset_pattern=pattern)
        if not targets:
            raise PackageError(
                "new packages require --target-asset; "
                "use inspect to list release assets"
            )
        for name, overrides in self.target_paths.items():
            if name not in targets:
                raise PackageError(f"path override refers to unknown target: {name}")
            targets[name] = targets[name].updated(bins=overrides or None, resolved=None)
        return targets

    def repo_for(self, existing: PackageSpec | None) -> str:
        if self.repo is not None:
            return normalize_repo(self.repo)
        if existing is not None:
            return existing.repo
        raise PackageError(
            "new packages require --repo; use search or inspect "
            "to discover a repository"
        )

    def command_paths(
        self, existing: PackageSpec | None, commands: tuple[str, ...]
    ) -> dict[str, object]:
        if self.package_type == "file":
            if len(commands) != 1:
                raise PackageError("file packages require exactly one --bin")
            return {"bin": commands[0]}
        return {"bins": self.paths_for(existing, commands)}

    def stripping_for(self, existing: PackageSpec | None) -> int:
        if self.strip_components is not None:
            stripping = self.strip_components
        elif isinstance(existing, BundleSpec):
            stripping = existing.strip_components
        else:
            stripping = 0
        if isinstance(existing, BundleSpec) and stripping != existing.strip_components:
            raise PackageError("cannot change package stripping; remove and re-add it")
        return stripping

    def candidate(self, existing: PackageSpec | None) -> PackageSpec:
        """Apply explicit options and inheritance without network or manifest writes."""
        repo = self.repo_for(existing)
        if existing is not None and existing.type != self.package_type:
            raise PackageError("cannot change package type; remove and re-add it")
        commands = self.commands_for(existing)
        data: dict[str, object] = {
            "type": self.package_type,
            "repo": repo,
            "targets": self.targets_for(existing),
            **self.command_paths(existing, commands),
        }
        if self.package_type == "bundle":
            data["strip_components"] = self.stripping_for(existing)
        if self.tag is not None:
            data["tag"] = self.tag
        elif existing is not None and repo == existing.repo:
            data["tag"] = existing.tag or None
        return PACKAGE_ADAPTER.validate_python(data)

    def resolution_targets(
        self, existing: PackageSpec | None, candidate: PackageSpec
    ) -> tuple[str, ...]:
        """Shared release or path changes invalidate every target's resolution.

        Candidate construction already forbids changing type, commands, or stripping.
        Otherwise only explicitly edited targets need resolving.
        """
        if existing is None:
            return tuple(candidate.targets)
        if candidate.repo != existing.repo or candidate.tag != existing.tag:
            return tuple(candidate.targets)
        if (
            isinstance(candidate, ArchiveSpecBase)
            and isinstance(existing, ArchiveSpecBase)
            and candidate.bins != existing.bins
        ):
            return tuple(candidate.targets)
        return tuple(dict.fromkeys((*self.target_assets, *self.target_paths))) or tuple(
            candidate.targets
        )
