#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "typer>=0.16,<1",
#   "unidiff>=0.7,<0.8",
# ]
# ///
"""Run cargo llvm-cov and emit compact agent-readable coverage reports."""

from __future__ import annotations

import json
import re
import shlex
import subprocess
import tempfile
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any, NoReturn

import typer
from unidiff import PatchSet
from unidiff.errors import UnidiffParseError


DEFAULT_TIMEOUT_SECONDS = 300
DEFAULT_MAX_OUTPUT_BYTES = 80_000
DEFAULT_MAX_ITEMS = 200
DEFAULT_TOOLCHAIN = "nightly"
PACKAGE_RE = re.compile(r"^[A-Za-z0-9_.-]+$")

app = typer.Typer(
    add_completion=False,
    no_args_is_help=True,
    help="Agent-oriented wrapper for cargo llvm-cov coverage reports.",
)


@dataclass(frozen=True)
class CommandResult:
    command: tuple[str, ...]
    cwd: str
    exit_code: int
    timed_out: bool
    elapsed_seconds: float
    max_output_bytes: int
    stdout: str
    stderr: str

    @property
    def succeeded(self) -> bool:
        return self.exit_code == 0 and not self.timed_out

    def first_output_line(self) -> str:
        output = self.stdout.strip() or self.stderr.strip()
        return output.splitlines()[0] if output else "no output"

    def diagnostic_lines(self, stage: str) -> list[str]:
        lines = [
            f"stage: {stage}",
            f"command: {shlex.join(self.command)}",
            f"cwd: {self.cwd}",
            f"exit_code: {self.exit_code}",
        ]
        if self.timed_out:
            lines.append("timed_out: true")
        details = self.stderr.strip() or self.stdout.strip()
        if details:
            details, _ = truncate_text(details, min(self.max_output_bytes, 40_000))
            lines.extend(["details:", *[f"  {line}" for line in details.splitlines()]])
        return lines


@dataclass(frozen=True)
class CommandOptions:
    cwd: Path
    timeout_seconds: int
    max_output_bytes: int

    def run(self, command: list[str]) -> CommandResult:
        started = time.monotonic()
        try:
            completed = subprocess.run(
                command,
                cwd=self.cwd,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                timeout=self.timeout_seconds,
                check=False,
            )
            timed_out = False
            exit_code = completed.returncode
            stdout = completed.stdout
            stderr = completed.stderr
        except subprocess.TimeoutExpired as exc:
            timed_out = True
            exit_code = 124
            stdout = exc.stdout or ""
            stderr = exc.stderr or ""
            if isinstance(stdout, bytes):
                stdout = stdout.decode("utf-8", errors="replace")
            if isinstance(stderr, bytes):
                stderr = stderr.decode("utf-8", errors="replace")
            stderr = (
                f"{stderr}\n[timed out after {self.timeout_seconds} seconds]".strip()
            )
        except FileNotFoundError as exc:
            timed_out = False
            exit_code = 127
            stdout = ""
            stderr = str(exc)

        return CommandResult(
            command=tuple(command),
            cwd=str(self.cwd),
            exit_code=exit_code,
            timed_out=timed_out,
            elapsed_seconds=round(time.monotonic() - started, 3),
            max_output_bytes=self.max_output_bytes,
            stdout=stdout,
            stderr=stderr,
        )


@dataclass(frozen=True)
class CargoScope:
    toolchain: str | None
    package: str | None
    workspace: bool
    manifest_path: str | None
    all_features: bool
    no_default_features: bool
    features: tuple[str, ...]

    def cargo_command(self, extra: list[str]) -> list[str]:
        command = ["cargo"]
        if self.toolchain:
            command.append(f"+{self.toolchain}")
        command.extend(extra)
        return command

    def command(self, extra: list[str]) -> list[str]:
        command = self.cargo_command(["llvm-cov"])

        if self.package:
            command.extend(["-p", self.package])
        elif self.workspace:
            command.append("--workspace")

        if self.manifest_path:
            command.extend(["--manifest-path", self.manifest_path])
        if self.all_features:
            command.append("--all-features")
        if self.no_default_features:
            command.append("--no-default-features")
        for feature_set in self.features:
            command.extend(["--features", feature_set])

        command.extend(extra)
        return command

    def label(self) -> str:
        if self.package:
            target = f"package={self.package}"
        elif self.workspace:
            target = "workspace"
        else:
            target = "current-package"

        modifiers = [f"toolchain={self.toolchain or 'default'}"]
        if self.all_features:
            modifiers.append("all-features")
        if self.no_default_features:
            modifiers.append("no-default-features")
        modifiers.extend(f"features={features}" for features in self.features)
        return ", ".join([target, *modifiers])


@dataclass(frozen=True)
class CoverageMetric:
    covered: int
    missed: int
    total: int
    percent: float | None

    @classmethod
    def from_json(cls, metric: dict[str, Any]) -> CoverageMetric:
        total = int(metric.get("count", 0))
        covered = int(metric.get("covered", 0))
        missed = int(metric.get("notcovered", total - covered))
        percent = metric.get("percent")
        return cls(
            covered=covered,
            missed=missed,
            total=total,
            percent=float(percent) if isinstance(percent, (int, float)) else None,
        )

    def text(self) -> str:
        percent = (
            "n/a" if self.total == 0 or self.percent is None else f"{self.percent:.2f}%"
        )
        return f"{percent} ({self.covered}/{self.total})"


@dataclass(frozen=True)
class CoverageTotals:
    branches: CoverageMetric
    functions: CoverageMetric
    lines: CoverageMetric
    regions: CoverageMetric

    @classmethod
    def from_report(cls, report: dict[str, Any]) -> CoverageTotals:
        data = report.get("data") or []
        totals = data[0].get("totals", {}) if data else {}
        return cls(
            branches=CoverageMetric.from_json(totals.get("branches", {})),
            functions=CoverageMetric.from_json(totals.get("functions", {})),
            lines=CoverageMetric.from_json(totals.get("lines", {})),
            regions=CoverageMetric.from_json(totals.get("regions", {})),
        )

    def text_lines(self) -> list[str]:
        return [
            f"lines: {self.lines.text()}",
            f"functions: {self.functions.text()}",
            f"regions: {self.regions.text()}",
            f"branches: {self.branches.text()}",
        ]


@dataclass(frozen=True)
class UncoveredLine:
    file: str
    line: int

    def location(self) -> str:
        return f"{self.file}:{self.line}"


@dataclass(frozen=True)
class UncoveredFunction:
    file: str
    line: int
    name: str

    def description(self) -> str:
        return f"{self.file}:{self.line} {self.name}".rstrip()


@dataclass(frozen=True)
class CoverageReport:
    totals: CoverageTotals
    uncovered_lines: tuple[UncoveredLine, ...]
    uncovered_functions: tuple[UncoveredFunction, ...]

    @classmethod
    def from_json(cls, report: dict[str, Any], cwd: Path) -> CoverageReport:
        data = report.get("data") or []
        coverage = data[0] if data else {}
        uncovered_lines: list[UncoveredLine] = []
        uncovered_functions: list[UncoveredFunction] = []

        for file_report in coverage.get("files", []):
            file_name = normalize_path(file_report.get("filename", ""), cwd)
            line_hits = line_hits_from_segments(file_report.get("segments", []))
            uncovered_lines.extend(
                UncoveredLine(file=file_name, line=line)
                for line, hits in sorted(line_hits.items())
                if hits and max(hits) == 0
            )

        for function in coverage.get("functions", []):
            if function.get("count") != 0:
                continue
            filenames = function.get("filenames") or []
            regions = function.get("regions") or []
            line = regions[0][0] if regions and regions[0] else 0
            uncovered_functions.append(
                UncoveredFunction(
                    file=normalize_path(filenames[0], cwd) if filenames else "",
                    line=line,
                    name=function.get("name", ""),
                )
            )

        return cls(
            totals=CoverageTotals.from_report(report),
            uncovered_lines=tuple(uncovered_lines),
            uncovered_functions=tuple(uncovered_functions),
        )

    def filtered(self, paths: set[str], active: bool) -> CoverageReport:
        if not active:
            return self

        def keep(file_name: str) -> bool:
            return file_name in paths or any(
                file_name.endswith(f"/{path}") for path in paths
            )

        return CoverageReport(
            totals=self.totals,
            uncovered_lines=tuple(
                item for item in self.uncovered_lines if keep(item.file)
            ),
            uncovered_functions=tuple(
                item for item in self.uncovered_functions if keep(item.file)
            ),
        )


@dataclass(frozen=True)
class ChangedLines:
    by_file: dict[str, frozenset[int]]

    @classmethod
    def from_diff(cls, diff_text: str) -> ChangedLines:
        changed: dict[str, set[int]] = {}
        patch = PatchSet(diff_text.splitlines(keepends=True))

        for patched_file in patch:
            path = normalize_diff_path(patched_file.path)
            if not path or path == "/dev/null":
                continue
            for hunk in patched_file:
                for line in hunk:
                    if line.is_added and line.target_line_no is not None:
                        changed.setdefault(path, set()).add(line.target_line_no)

        return cls(
            by_file={path: frozenset(lines) for path, lines in sorted(changed.items())}
        )

    @property
    def count(self) -> int:
        return sum(len(lines) for lines in self.by_file.values())

    def contains(self, file_name: str, line: int) -> bool:
        return any(
            (file_name == path or file_name.endswith(f"/{path}")) and line in lines
            for path, lines in self.by_file.items()
        )


@dataclass(frozen=True)
class DiffCoverage:
    changed_lines: ChangedLines
    uncovered_lines: tuple[UncoveredLine, ...]
    zero_hit_function_records: tuple[UncoveredFunction, ...]

    @classmethod
    def from_report(cls, report: CoverageReport, changed: ChangedLines) -> DiffCoverage:
        return cls(
            changed_lines=changed,
            uncovered_lines=tuple(
                item
                for item in report.uncovered_lines
                if changed.contains(item.file, item.line)
            ),
            zero_hit_function_records=tuple(
                item
                for item in report.uncovered_functions
                if changed.contains(item.file, item.line)
            ),
        )

    @property
    def has_uncovered_changed_lines(self) -> bool:
        return bool(self.uncovered_lines)


def truncate_text(text: str, max_bytes: int) -> tuple[str, bool]:
    data = text.encode("utf-8", errors="replace")
    if len(data) <= max_bytes:
        return text, False
    truncated = data[:max_bytes].decode("utf-8", errors="replace")
    return f"{truncated}\n\n[truncated to {max_bytes} bytes]", True


def resolve_cwd(value: str) -> Path:
    path = Path(value).expanduser().resolve()
    if not path.is_dir():
        raise typer.BadParameter(f"cwd is not a directory: {value}")
    return path


def build_command_options(
    cwd: str,
    timeout_seconds: int,
    max_output_bytes: int,
) -> CommandOptions:
    return CommandOptions(
        cwd=resolve_cwd(cwd),
        timeout_seconds=timeout_seconds,
        max_output_bytes=max_output_bytes,
    )


def build_scope(
    toolchain: str | None,
    package: str | None,
    workspace: bool,
    manifest_path: str | None,
    all_features: bool,
    no_default_features: bool,
    features: list[str] | None,
) -> CargoScope:
    if package and workspace:
        raise typer.BadParameter("use either --package/-p or --workspace, not both")
    if package and not PACKAGE_RE.fullmatch(package):
        raise typer.BadParameter(f"invalid Cargo package name: {package!r}")
    return CargoScope(
        toolchain=toolchain,
        package=package,
        workspace=workspace,
        manifest_path=manifest_path,
        all_features=all_features,
        no_default_features=no_default_features,
        features=tuple(features or []),
    )


def normalize_path(path: str, cwd: Path) -> str:
    candidate = Path(path)
    if not candidate.is_absolute():
        return candidate.as_posix()
    try:
        return candidate.resolve().relative_to(cwd).as_posix()
    except ValueError:
        return candidate.as_posix()


def normalize_diff_path(path: str) -> str:
    if path.startswith("a/") or path.startswith("b/"):
        return path[2:]
    return path


def line_hits_from_segments(segments: list[list[Any]]) -> dict[int, list[int]]:
    line_hits: dict[int, list[int]] = {}
    for segment in segments:
        if len(segment) < 4 or not segment[3]:
            continue
        line = segment[0]
        hits = segment[2]
        if isinstance(line, int) and isinstance(hits, int):
            line_hits.setdefault(line, []).append(hits)
    return line_hits


def read_coverage_report(
    path: Path, cwd: Path
) -> tuple[CoverageReport | None, str | None]:
    try:
        raw = json.loads(path.read_text(encoding="utf-8"))
        if not isinstance(raw, dict):
            return None, f"expected JSON object, got {type(raw).__name__}"
        return CoverageReport.from_json(raw, cwd), None
    except (OSError, json.JSONDecodeError, TypeError, ValueError) as exc:
        return None, str(exc)


def get_changed_files(
    options: CommandOptions,
    base: str,
) -> tuple[set[str], CommandResult]:
    result = options.run(["git", "diff", "--name-only", "--relative", base, "--"])
    files = {line.strip() for line in result.stdout.splitlines() if line.strip()}
    return files, result


def get_changed_diff(options: CommandOptions, base: str) -> CommandResult:
    return options.run(["git", "diff", "--unified=0", "--relative", base, "--"])


def make_json_path(prefix: str) -> Path:
    tmp_root = Path(tempfile.gettempdir()) / "agent-cargo-llvm-cov"
    tmp_root.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(
        prefix=prefix,
        suffix=".json",
        dir=tmp_root,
        delete=False,
    ) as tmp_file:
        return Path(tmp_file.name)


def emit(lines: list[str], exit_code: int = 0) -> NoReturn:
    typer.echo("\n".join(lines).rstrip())
    raise typer.Exit(exit_code)


def emit_command_error(label: str, stage: str, result: CommandResult) -> NoReturn:
    emit([f"{label}: error", *result.diagnostic_lines(stage)], result.exit_code or 1)


def emit_parse_error(label: str, stage: str, error: str) -> NoReturn:
    emit([f"{label}: error", f"stage: {stage}", f"error: {error}"], 1)


def append_locations(
    lines: list[str],
    title: str,
    locations: tuple[str, ...],
    max_items: int,
) -> None:
    if not locations:
        return
    lines.extend(["", f"{title}:"])
    lines.extend(f"  {location}" for location in locations[:max_items])
    if len(locations) > max_items:
        lines.append(f"  ... {len(locations) - max_items} more")


def append_kept_json(lines: list[str], output_path: Path, keep_json: bool) -> None:
    if keep_json:
        lines.append(f"json_report: {output_path}")


@app.command()
def check(
    cwd: str = typer.Option(".", help="Repository or crate directory."),
    toolchain: str | None = typer.Option(
        DEFAULT_TOOLCHAIN,
        help="Rust toolchain for coverage commands. Defaults to nightly.",
    ),
    timeout_seconds: int = typer.Option(
        DEFAULT_TIMEOUT_SECONDS,
        min=1,
        help="Command timeout.",
    ),
    max_output_bytes: int = typer.Option(
        DEFAULT_MAX_OUTPUT_BYTES,
        min=1,
        help="Maximum failure output bytes to keep.",
    ),
) -> None:
    """Check cargo llvm-cov availability."""
    options = build_command_options(cwd, timeout_seconds, max_output_bytes)
    scope = build_scope(toolchain, None, False, None, False, False, [])
    cargo_version = options.run(scope.cargo_command(["--version"]))
    llvm_cov_version = options.run(scope.command(["--version"]))
    succeeded = cargo_version.succeeded and llvm_cov_version.succeeded
    lines = [
        f"coverage_check: {'pass' if succeeded else 'error'}",
        f"toolchain: {scope.toolchain or 'default'}",
        f"cargo: {cargo_version.first_output_line()}",
        f"cargo_llvm_cov: {llvm_cov_version.first_output_line()}",
    ]
    if not cargo_version.succeeded:
        lines.extend(cargo_version.diagnostic_lines("cargo"))
    if not llvm_cov_version.succeeded:
        lines.extend(llvm_cov_version.diagnostic_lines("cargo_llvm_cov"))
    emit(lines, 0 if succeeded else 1)


@app.command()
def summary(
    cwd: str = typer.Option(".", help="Repository or crate directory."),
    toolchain: str | None = typer.Option(
        DEFAULT_TOOLCHAIN,
        help="Rust toolchain for coverage commands. Defaults to nightly.",
    ),
    package: str | None = typer.Option(None, "-p", "--package"),
    workspace: bool = typer.Option(False, "--workspace"),
    manifest_path: str | None = typer.Option(None, "--manifest-path"),
    all_features: bool = typer.Option(False, "--all-features"),
    no_default_features: bool = typer.Option(False, "--no-default-features"),
    features: list[str] | None = typer.Option(None, "--features"),
    timeout_seconds: int = typer.Option(
        DEFAULT_TIMEOUT_SECONDS,
        min=1,
        help="Command timeout.",
    ),
    max_output_bytes: int = typer.Option(
        DEFAULT_MAX_OUTPUT_BYTES,
        min=1,
        help="Maximum failure output bytes to keep.",
    ),
    keep_json: bool = typer.Option(
        False,
        "--keep-json",
        help="Keep the internal llvm-cov JSON report.",
    ),
) -> None:
    """Run coverage and summarize totals."""
    options = build_command_options(cwd, timeout_seconds, max_output_bytes)
    scope = build_scope(
        toolchain,
        package,
        workspace,
        manifest_path,
        all_features,
        no_default_features,
        features,
    )
    output_path = make_json_path("coverage-summary-")

    try:
        result = options.run(
            scope.command(
                ["--json", "--summary-only", "--output-path", str(output_path)]
            )
        )
        if not result.succeeded:
            emit_command_error("coverage_summary", "cargo_llvm_cov", result)
        report, parse_error = read_coverage_report(output_path, options.cwd)
        if parse_error or report is None:
            emit_parse_error(
                "coverage_summary", "coverage_json", parse_error or "empty report"
            )

        lines = ["coverage_summary: pass", f"scope: {scope.label()}"]
        lines.extend(report.totals.text_lines())
        append_kept_json(lines, output_path, keep_json)
        emit(lines)
    finally:
        if not keep_json:
            output_path.unlink(missing_ok=True)


@app.command()
def uncovered(
    cwd: str = typer.Option(".", help="Repository or crate directory."),
    toolchain: str | None = typer.Option(
        DEFAULT_TOOLCHAIN,
        help="Rust toolchain for coverage commands. Defaults to nightly.",
    ),
    package: str | None = typer.Option(None, "-p", "--package"),
    workspace: bool = typer.Option(False, "--workspace"),
    manifest_path: str | None = typer.Option(None, "--manifest-path"),
    all_features: bool = typer.Option(False, "--all-features"),
    no_default_features: bool = typer.Option(False, "--no-default-features"),
    features: list[str] | None = typer.Option(None, "--features"),
    path: list[str] | None = typer.Option(
        None, "--path", help="Filter parsed output to a file."
    ),
    changed_only: bool = typer.Option(
        False,
        "--changed-only",
        help="Filter parsed output to files changed from --base.",
    ),
    base: str = typer.Option(
        "HEAD", "--base", help="Git diff base for --changed-only."
    ),
    max_items: int = typer.Option(
        DEFAULT_MAX_ITEMS,
        "--max-items",
        min=1,
        help="Maximum locations to list per section.",
    ),
    verbose: bool = typer.Option(
        False,
        "--verbose",
        help="List zero-hit function records in addition to uncovered lines.",
    ),
    timeout_seconds: int = typer.Option(
        DEFAULT_TIMEOUT_SECONDS,
        min=1,
        help="Command timeout.",
    ),
    max_output_bytes: int = typer.Option(
        DEFAULT_MAX_OUTPUT_BYTES,
        min=1,
        help="Maximum failure output bytes to keep.",
    ),
    keep_json: bool = typer.Option(
        False,
        "--keep-json",
        help="Keep the internal llvm-cov JSON report.",
    ),
) -> None:
    """Report uncovered lines and optional zero-hit function records."""
    options = build_command_options(cwd, timeout_seconds, max_output_bytes)
    scope = build_scope(
        toolchain,
        package,
        workspace,
        manifest_path,
        all_features,
        no_default_features,
        features,
    )
    output_path = make_json_path("coverage-")

    try:
        result = options.run(
            scope.command(["--json", "--output-path", str(output_path)])
        )
        if not result.succeeded:
            emit_command_error("coverage_uncovered", "cargo_llvm_cov", result)
        report, parse_error = read_coverage_report(output_path, options.cwd)
        if parse_error or report is None:
            emit_parse_error(
                "coverage_uncovered", "coverage_json", parse_error or "empty report"
            )

        filter_paths = {normalize_path(item, options.cwd) for item in path or []}
        filter_active = bool(path) or changed_only
        if changed_only:
            changed_files, changed_result = get_changed_files(options, base)
            if not changed_result.succeeded:
                emit_command_error("coverage_uncovered", "git_diff", changed_result)
            filter_paths.update(changed_files)
        report = report.filtered(filter_paths, filter_active)

        lines = [
            "coverage_uncovered: pass",
            f"scope: {scope.label()}",
            f"uncovered_lines: {len(report.uncovered_lines)}",
            f"zero_hit_function_records: {len(report.uncovered_functions)} (diagnostic only)",
        ]
        if changed_only:
            lines.insert(2, f"base: {base}")
        append_locations(
            lines,
            "uncovered_line_locations",
            tuple(item.location() for item in report.uncovered_lines),
            max_items,
        )
        if verbose:
            append_locations(
                lines,
                "zero_hit_function_records",
                tuple(item.description() for item in report.uncovered_functions),
                max_items,
            )
        append_kept_json(lines, output_path, keep_json)
        emit(lines)
    finally:
        if not keep_json:
            output_path.unlink(missing_ok=True)


@app.command("diff-uncovered")
def diff_uncovered_command(
    cwd: str = typer.Option(".", help="Repository or crate directory."),
    toolchain: str | None = typer.Option(
        DEFAULT_TOOLCHAIN,
        help="Rust toolchain for coverage commands. Defaults to nightly.",
    ),
    package: str | None = typer.Option(None, "-p", "--package"),
    workspace: bool = typer.Option(False, "--workspace"),
    manifest_path: str | None = typer.Option(None, "--manifest-path"),
    all_features: bool = typer.Option(False, "--all-features"),
    no_default_features: bool = typer.Option(False, "--no-default-features"),
    features: list[str] | None = typer.Option(None, "--features"),
    base: str = typer.Option("HEAD", "--base", help="Git diff base."),
    max_items: int = typer.Option(
        DEFAULT_MAX_ITEMS,
        "--max-items",
        min=1,
        help="Maximum locations to list per section.",
    ),
    verbose: bool = typer.Option(
        False,
        "--verbose",
        help="List zero-hit changed function records and command timings.",
    ),
    fail_on_diff_uncovered: bool = typer.Option(
        False,
        "--fail-on-diff-uncovered",
        help="Exit non-zero when changed uncovered lines are found.",
    ),
    timeout_seconds: int = typer.Option(
        DEFAULT_TIMEOUT_SECONDS,
        min=1,
        help="Command timeout.",
    ),
    max_output_bytes: int = typer.Option(
        DEFAULT_MAX_OUTPUT_BYTES,
        min=1,
        help="Maximum failure output bytes to keep.",
    ),
    keep_json: bool = typer.Option(
        False,
        "--keep-json",
        help="Keep the internal llvm-cov JSON report.",
    ),
) -> None:
    """Report uncovered executable lines that intersect changed diff hunks."""
    options = build_command_options(cwd, timeout_seconds, max_output_bytes)
    scope = build_scope(
        toolchain,
        package,
        workspace,
        manifest_path,
        all_features,
        no_default_features,
        features,
    )
    output_path = make_json_path("coverage-")

    try:
        coverage_result = options.run(
            scope.command(["--json", "--output-path", str(output_path)])
        )
        if not coverage_result.succeeded:
            emit_command_error("diff_coverage", "cargo_llvm_cov", coverage_result)

        diff_result = get_changed_diff(options, base)
        if not diff_result.succeeded:
            emit_command_error("diff_coverage", "git_diff", diff_result)

        report, parse_error = read_coverage_report(output_path, options.cwd)
        if parse_error or report is None:
            emit_parse_error(
                "diff_coverage", "coverage_json", parse_error or "empty report"
            )
        try:
            changed = ChangedLines.from_diff(diff_result.stdout)
        except UnidiffParseError as exc:
            emit_parse_error("diff_coverage", "git_diff_parse", str(exc))

        coverage = DiffCoverage.from_report(report, changed)
        should_fail = fail_on_diff_uncovered and coverage.has_uncovered_changed_lines
        if should_fail:
            status = "fail"
        elif coverage.has_uncovered_changed_lines:
            status = "findings"
        else:
            status = "pass"

        lines = [
            f"diff_coverage: {status}",
            f"scope: {scope.label()}",
            f"base: {base}",
            f"changed_source_lines: {coverage.changed_lines.count}",
            f"uncovered_changed_lines: {len(coverage.uncovered_lines)}",
            (
                "zero_hit_changed_function_records: "
                f"{len(coverage.zero_hit_function_records)} (diagnostic only)"
            ),
            f"line_coverage: {report.totals.lines.text()}",
        ]
        append_locations(
            lines,
            "uncovered_changed_line_locations",
            tuple(item.location() for item in coverage.uncovered_lines),
            max_items,
        )
        if verbose:
            lines.extend(
                [
                    f"cargo_elapsed_seconds: {coverage_result.elapsed_seconds}",
                    f"git_diff_elapsed_seconds: {diff_result.elapsed_seconds}",
                ]
            )
            append_locations(
                lines,
                "zero_hit_changed_function_records",
                tuple(
                    item.description() for item in coverage.zero_hit_function_records
                ),
                max_items,
            )
        append_kept_json(lines, output_path, keep_json)
        emit(lines, 1 if should_fail else 0)
    finally:
        if not keep_json:
            output_path.unlink(missing_ok=True)


if __name__ == "__main__":
    app()
