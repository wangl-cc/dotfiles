"""Pydantic Settings CLI: explicit inputs, structured discovery, no prompts."""

import contextlib
from typing import Annotated, Literal

from pydantic import (
    BaseModel,
    ConfigDict,
    Field,
    ValidationError,
    model_validator,
)
from pydantic_settings import (
    BaseSettings,
    CliApp,
    CliPositionalArg,
    CliSubCommand,
    CliToggleFlag,
    PydanticBaseSettingsSource,
    SettingsConfigDict,
    SettingsError,
    get_subcommand,
)

from . import github, reports, tables, views
from .archives import open_archive
from .models import (
    PackageError,
    RegexPattern,
    is_archive_name,
)
from .operations import PackageOperations, ToolTarget, verification_required
from .requests import AddOptions
from .storage import PackageStore, manifest_path


class CommandModel(BaseModel):
    model_config = ConfigDict(extra="forbid")

    def modifies_manifest(self) -> bool:
        """Whether running this command locks and writes the manifest."""
        return False


def needs_manifest_lock(command: object) -> bool:
    """Whether the parsed subcommand must hold the manifest write lock."""
    return isinstance(command, CommandModel) and command.modifies_manifest()


class ListCommand(CommandModel):
    """List configured packages."""

    output_format: tables.OutputFormat = Field("human", alias="format")

    def cli_cmd(self) -> None:
        tables.print_rows(
            views.tool_list_rows(PackageStore(manifest_path()).load()),
            [
                tables.Column("name", "NAME"),
                tables.Column("type", "TYPE"),
                tables.Column("repo", "REPOSITORY"),
                tables.Column("tag", "TAG"),
                tables.Column("bin", "BIN"),
                tables.Column("targets", "TARGETS"),
            ],
            self.output_format,
        )


class SearchCommand(CommandModel):
    """List GitHub repository search results without selecting a repository."""

    query: CliPositionalArg[str]
    limit: Annotated[int, Field(ge=1, le=50)] = 8
    output_format: tables.OutputFormat = Field("human", alias="format")

    def cli_cmd(self) -> None:
        with github.GitHubClient() as client:
            repositories = client.search_repositories(self.query, self.limit)
        views.print_search_rows(repositories, self.output_format)


class InspectCommand(CommandModel):
    """List release assets, or list members of an explicitly named archive asset."""

    repo: CliPositionalArg[str]
    tag: str = "latest"
    asset: str | None = Field(None, description="Exact release asset name to inspect.")
    path_regex: RegexPattern | None = Field(
        None, description="Filter member paths; requires --asset."
    )
    output_format: tables.OutputFormat = Field("human", alias="format")

    @model_validator(mode="after")
    def validate_options(self) -> "InspectCommand":
        if self.path_regex is not None and self.asset is None:
            raise ValueError("--path-regex requires --asset")
        return self

    def cli_cmd(self) -> None:
        repo = github.normalize_repo(self.repo)
        with github.GitHubClient() as client:
            release = client.fetch_release(repo, self.tag)
            if self.asset is None:
                views.print_release_assets(repo, release, self.output_format)
                return
            matches = [asset for asset in release.assets if asset.name == self.asset]
            if len(matches) != 1:
                raise PackageError(
                    f"expected one asset named {self.asset!r}; found {len(matches)}"
                )
            asset = matches[0]
            if not is_archive_name(asset.name):
                raise PackageError(
                    f"asset is not a supported archive: {asset.name}; "
                    "omit --asset to list release files"
                )
            with PackageOperations.open(client) as packages:
                downloaded = packages.downloads.download(
                    asset.browser_download_url, github.digest_sha256(asset.digest)
                )
                with open_archive(downloaded.path) as archive:
                    members = archive.members()
        rows = [
            member.model_dump(mode="json")
            for member in members
            if self.path_regex is None or self.path_regex.search(member.path)
        ]
        tables.print_rows(
            rows,
            [
                tables.Column("path", "PATH"),
                tables.Column("kind", "KIND"),
                tables.Column("mode", "MODE"),
                tables.Column("size", "SIZE"),
                tables.Column("link_target", "LINK TARGET"),
            ],
            self.output_format,
        )


class AddCommand(CommandModel, AddOptions):
    """Resolve explicit asset/path rules; existing rules may be reused."""

    dry_run: CliToggleFlag[bool] = False
    output_format: tables.AddFormat = Field("human", alias="format")

    def modifies_manifest(self) -> bool:
        return not self.dry_run

    def cli_cmd(self) -> None:
        store = PackageStore(manifest_path())
        with (
            github.GitHubClient() as client,
            PackageOperations.open(client) as packages,
        ):
            plan = packages.prepare_add(store.load(), self)
            tool = plan.manifest.tools[self.name]
            packages.verify_many(
                [ToolTarget(self.name, tool, name) for name in plan.targets]
            )
            if self.dry_run:
                views.print_add_preview(
                    self.name, tool, list(plan.targets), self.output_format
                )
                return
            store.save(plan.manifest)
            if self.output_format == "json":
                views.print_add_preview(self.name, tool, list(plan.targets), "json")
            else:
                print(f"added {self.name} for {', '.join(plan.targets)}")


class UpdateCommand(CommandModel):
    """Resolve a newer release using saved rules."""

    name: CliPositionalArg[str | None] = None
    tag: str | None = None
    verify: CliToggleFlag[bool] = False
    output_format: Literal["text", "markdown"] = Field("text", alias="format")

    def modifies_manifest(self) -> bool:
        return True

    def cli_cmd(self) -> None:
        store = PackageStore(manifest_path())
        before = store.load()
        with (
            github.GitHubClient() as client,
            PackageOperations.open(client) as packages,
        ):
            plan = packages.prepare_update(before, self.name, self.tag)
            checks = [
                item
                for item in plan.updated
                if verification_required(item.tool, requested=self.verify)
            ]
            packages.verify_many(checks)
            store.save(plan.manifest)
        for skipped in plan.skipped:
            tables.log(
                f"skip {skipped.tool_name}: GitHub latest {skipped.candidate_tag} "
                f"is older than configured {skipped.configured_tag}; "
                f"use --tag {skipped.candidate_tag} to downgrade explicitly"
            )
        status: reports.VerificationStatus
        if not plan.updated:
            status = "not run"
        elif len(checks) == len(plan.updated):
            status = "passed"
        elif checks:
            status = "partial"
        else:
            status = "not requested"
        selected = dict(before.selected_tools(self.name))
        print(
            reports.UpdateReport(
                before_tools=selected,
                after_tools={name: plan.manifest.tools[name] for name in selected},
                verification_status=status,
                verify_requested=self.verify,
                resolved_target_count=len(plan.updated),
                skipped_downgrades=plan.skipped,
            ).render(self.output_format)
        )


class VerifyCommand(CommandModel):
    """Verify currently pinned assets without updating configuration."""

    name: CliPositionalArg[str | None] = None
    target: str | None = None

    def cli_cmd(self) -> None:
        manifest = PackageStore(manifest_path()).load()
        with (
            github.GitHubClient() as client,
            PackageOperations.open(client) as packages,
        ):
            items = []
            for name, tool in manifest.selected_tools(self.name):
                for target in [self.target] if self.target else tool.targets:
                    if target not in tool.targets:
                        raise PackageError(f"{name} has no target {target}")
                    items.append(ToolTarget(name, tool, target))
            packages.verify_many(items)


class RemoveCommand(CommandModel):
    """Remove configuration and schedule installed paths for removal on apply."""

    name: CliPositionalArg[str]

    def modifies_manifest(self) -> bool:
        return True

    def cli_cmd(self) -> None:
        store = PackageStore(manifest_path())
        store.save(store.load().without_package(self.name))
        print(f"removed {self.name}")


class PortablePkgsCli(BaseSettings):
    """Manage explicit GitHub release packages for chezmoi."""

    model_config = SettingsConfigDict(
        cli_prog_name="portable-pkgs",
        cli_kebab_case=True,
        cli_enforce_required=True,
        cli_hide_none_type=True,
        cli_avoid_json=True,
        case_sensitive=True,
    )
    list: CliSubCommand[ListCommand]
    search: CliSubCommand[SearchCommand]
    inspect: CliSubCommand[InspectCommand]
    add: CliSubCommand[AddCommand]
    update: CliSubCommand[UpdateCommand]
    verify: CliSubCommand[VerifyCommand]
    remove: CliSubCommand[RemoveCommand]

    @classmethod
    def settings_customise_sources(
        cls,
        settings_cls: type[BaseSettings],
        init_settings: PydanticBaseSettingsSource,
        env_settings: PydanticBaseSettingsSource,
        dotenv_settings: PydanticBaseSettingsSource,
        file_secret_settings: PydanticBaseSettingsSource,
    ) -> tuple[PydanticBaseSettingsSource, ...]:
        return (init_settings,)

    def cli_cmd(self) -> None:
        command = get_subcommand(self, is_required=False)
        lock = (
            PackageStore(manifest_path()).lock()
            if needs_manifest_lock(command)
            else contextlib.nullcontext()
        )
        with lock:
            CliApp.run_subcommand(self)


def cli(args: list[str] | None = None) -> None:
    try:
        CliApp.run(PortablePkgsCli, cli_args=args, cli_exit_on_error=False)
    except ValidationError as error:
        for detail in error.errors(include_url=False):
            location = ".".join(str(part) for part in detail["loc"])
            tables.log(f"Error: {location}: {detail['msg']}")
        raise SystemExit(2) from error
    except SettingsError as error:
        tables.log(f"Error: {error}")
        raise SystemExit(2) from error
    except KeyboardInterrupt as error:
        tables.log("Aborted!")
        raise SystemExit(1) from error
    except PackageError as error:
        tables.log(f"Error: {error}")
        raise SystemExit(1) from error
