#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "typer>=0.16,<1",
#   "unidiff>=0.7,<0.8",
# ]
# ///
"""Run cargo llvm-cov through stable JSON summary and coverage commands."""

import json
import re
import subprocess
import tempfile
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import typer
from unidiff import PatchSet
from unidiff.errors import UnidiffParseError


DEFAULT_TIMEOUT_SECONDS = 300
DEFAULT_MAX_OUTPUT_BYTES = 80_000
DEFAULT_MAX_ITEMS = 200
PACKAGE_RE = re.compile(r"^[A-Za-z0-9_.-]+$")

app = typer.Typer(
    add_completion=False,
    no_args_is_help=True,
    help="Stable wrapper for cargo llvm-cov JSON summary and coverage.",
)


@dataclass(frozen=True)
class CommandOptions:
    cwd: Path
    timeout_seconds: int
    max_output_bytes: int


@dataclass(frozen=True)
class CargoScope:
    toolchain: str | None
    package: str | None
    workspace: bool
    manifest_path: str | None
    all_features: bool
    no_default_features: bool
    features: list[str]


@dataclass(frozen=True)
class CommandResult:
    command: list[str]
    cwd: str
    exit_code: int
    timed_out: bool
    elapsed_seconds: float
    max_output_bytes: int
    stdout: str
    stderr: str


def truncate_text(text: str, max_bytes: int) -> tuple[str, bool]:
    data = text.encode("utf-8", errors="replace")
    if len(data) <= max_bytes:
        return text, False
    truncated = data[:max_bytes].decode("utf-8", errors="replace")
    return f"{truncated}\n\n[truncated to {max_bytes} bytes]", True


def run_command(
    command: list[str],
    options: CommandOptions,
) -> CommandResult:
    started = time.monotonic()
    try:
        completed = subprocess.run(
            command,
            cwd=options.cwd,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=options.timeout_seconds,
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
        stderr = f"{stderr}\n[timed out after {options.timeout_seconds} seconds]".strip()
    except FileNotFoundError as exc:
        timed_out = False
        exit_code = 127
        stdout = ""
        stderr = str(exc)

    elapsed = time.monotonic() - started
    return CommandResult(
        command=command,
        cwd=str(options.cwd),
        exit_code=exit_code,
        timed_out=timed_out,
        elapsed_seconds=round(elapsed, 3),
        max_output_bytes=options.max_output_bytes,
        stdout=stdout,
        stderr=stderr,
    )


def result_to_dict(result: CommandResult) -> dict[str, Any]:
    stdout, stdout_truncated = truncate_text(result.stdout, result.max_output_bytes)
    stderr, stderr_truncated = truncate_text(
        result.stderr, min(result.max_output_bytes, 40_000)
    )
    return {
        "command": result.command,
        "cwd": result.cwd,
        "exit_code": result.exit_code,
        "timed_out": result.timed_out,
        "elapsed_seconds": result.elapsed_seconds,
        "truncated": stdout_truncated or stderr_truncated,
        "stdout": stdout,
        "stderr": stderr,
    }


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
        features=features or [],
    )


def cargo_command(scope: CargoScope, extra: list[str]) -> list[str]:
    command = ["cargo"]
    if scope.toolchain:
        command.append(f"+{scope.toolchain}")
    command.append("llvm-cov")

    if scope.package:
        command.extend(["-p", scope.package])
    elif scope.workspace:
        command.append("--workspace")

    if scope.manifest_path:
        command.extend(["--manifest-path", scope.manifest_path])
    if scope.all_features:
        command.append("--all-features")
    if scope.no_default_features:
        command.append("--no-default-features")
    for feature_set in scope.features:
        command.extend(["--features", feature_set])

    command.extend(extra)
    return command


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


def metric_summary(metric: dict[str, Any]) -> dict[str, Any]:
    total = int(metric.get("count", 0))
    covered = int(metric.get("covered", 0))
    missed = int(metric.get("notcovered", total - covered))
    percent = metric.get("percent")
    return {
        "covered": covered,
        "missed": missed,
        "total": total,
        "percent": float(percent) if isinstance(percent, (int, float)) else None,
    }


def json_totals(report: dict[str, Any]) -> dict[str, Any]:
    data = report.get("data") or []
    totals = data[0].get("totals", {}) if data else {}
    return {
        "branches": metric_summary(totals.get("branches", {})),
        "functions": metric_summary(totals.get("functions", {})),
        "lines": metric_summary(totals.get("lines", {})),
        "regions": metric_summary(totals.get("regions", {})),
    }


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


def parse_json_report(report: dict[str, Any], cwd: Path) -> dict[str, Any]:
    data = report.get("data") or []
    if not data:
        return {
            "totals": json_totals(report),
            "uncovered_lines": [],
            "uncovered_functions": [],
            "truncated_items": False,
        }

    coverage = data[0]
    uncovered_lines: list[dict[str, Any]] = []
    uncovered_functions: list[dict[str, Any]] = []

    for file_report in coverage.get("files", []):
        file_name = normalize_path(file_report.get("filename", ""), cwd)
        line_hits = line_hits_from_segments(file_report.get("segments", []))
        for line, hits in sorted(line_hits.items()):
            if hits and max(hits) == 0:
                uncovered_lines.append({"file": file_name, "line": line, "hits": 0})

    for function in coverage.get("functions", []):
        if function.get("count") != 0:
            continue
        filenames = function.get("filenames") or []
        regions = function.get("regions") or []
        line = regions[0][0] if regions and regions[0] else 0
        uncovered_functions.append(
            {
                "file": normalize_path(filenames[0], cwd) if filenames else "",
                "line": line,
                "name": function.get("name", ""),
                "hits": 0,
            }
        )

    return {
        "totals": json_totals(report),
        "uncovered_lines": uncovered_lines,
        "uncovered_functions": uncovered_functions,
        "truncated_items": False,
    }


def limit_parsed(parsed: dict[str, Any], max_items: int) -> dict[str, Any]:
    uncovered_lines = parsed["uncovered_lines"]
    uncovered_functions = parsed["uncovered_functions"]
    return {
        **parsed,
        "uncovered_lines": uncovered_lines[:max_items],
        "uncovered_functions": uncovered_functions[:max_items],
        "truncated_items": (
            len(uncovered_lines) > max_items or len(uncovered_functions) > max_items
        ),
    }


def read_json_report(path: Path) -> tuple[dict[str, Any] | None, str | None]:
    try:
        report = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        return None, str(exc)
    if not isinstance(report, dict):
        return None, f"expected JSON object, got {type(report).__name__}"
    return report, None


def get_changed_files(
    options: CommandOptions,
    base: str,
) -> tuple[set[str], dict[str, Any]]:
    result = run_command(
        ["git", "diff", "--name-only", "--relative", base, "--"],
        options,
    )
    files = {
        line.strip()
        for line in result.stdout.splitlines()
        if line.strip() and not line.startswith("[")
    }
    return files, result_to_dict(result)


def get_changed_diff(options: CommandOptions, base: str) -> CommandResult:
    return run_command(
        ["git", "diff", "--unified=0", "--relative", base, "--"],
        options,
    )


def parse_changed_lines(diff_text: str) -> dict[str, list[int]]:
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

    return {path: sorted(lines) for path, lines in sorted(changed.items())}


def changed_line_set(changed: dict[str, list[int]]) -> dict[str, set[int]]:
    return {path: set(lines) for path, lines in changed.items()}


def item_matches_changed_line(
    item: dict[str, Any],
    changed: dict[str, set[int]],
) -> bool:
    file_name = item.get("file", "")
    line = item.get("line")
    if not isinstance(line, int):
        return False
    for path, lines in changed.items():
        if file_name == path or file_name.endswith(f"/{path}"):
            return line in lines
    return False


def diff_uncovered(
    parsed: dict[str, Any],
    changed: dict[str, list[int]],
) -> dict[str, Any]:
    changed_sets = changed_line_set(changed)
    uncovered_lines = [
        item
        for item in parsed["uncovered_lines"]
        if item_matches_changed_line(item, changed_sets)
    ]
    uncovered_functions = [
        item
        for item in parsed["uncovered_functions"]
        if item_matches_changed_line(item, changed_sets)
    ]
    return {
        "changed_lines": changed,
        "uncovered_lines": uncovered_lines,
        "uncovered_functions": uncovered_functions,
        "matched": bool(uncovered_lines or uncovered_functions),
    }


def filter_parsed(
    parsed: dict[str, Any],
    paths: set[str],
) -> dict[str, Any]:
    if not paths:
        return {
            **parsed,
            "filter": {
                "paths": [],
                "matched": False,
                "totals_scope": "full_json_report",
            },
        }

    def keep(item: dict[str, Any]) -> bool:
        file_name = item.get("file", "")
        return file_name in paths or any(
            file_name.endswith(f"/{path}") for path in paths
        )

    uncovered_lines = [item for item in parsed["uncovered_lines"] if keep(item)]
    uncovered_functions = [
        item for item in parsed["uncovered_functions"] if keep(item)
    ]
    return {
        **parsed,
        "uncovered_lines": uncovered_lines,
        "uncovered_functions": uncovered_functions,
        "filter": {
            "paths": sorted(paths),
            "matched": bool(uncovered_lines or uncovered_functions),
            "totals_scope": "full_json_report",
        },
    }


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


def emit(payload: dict[str, Any], exit_code: int = 0) -> None:
    typer.echo(json.dumps(payload, indent=2, sort_keys=True))
    raise typer.Exit(exit_code)


@app.command()
def check(
    cwd: str = typer.Option(".", help="Repository or crate directory."),
    toolchain: str | None = typer.Option(
        None,
        help="Optional Rust toolchain, for example 'nightly' for cargo +nightly.",
    ),
    timeout_seconds: int = typer.Option(
        DEFAULT_TIMEOUT_SECONDS,
        min=1,
        help="Command timeout.",
    ),
    max_output_bytes: int = typer.Option(
        DEFAULT_MAX_OUTPUT_BYTES,
        min=1,
        help="Maximum stdout/stderr bytes to keep.",
    ),
) -> None:
    """Check cargo llvm-cov availability."""
    options = build_command_options(cwd, timeout_seconds, max_output_bytes)
    scope = build_scope(toolchain, None, False, None, False, False, [])
    cargo_version = run_command(["cargo", "--version"], options)
    llvm_cov_version = run_command(cargo_command(scope, ["--version"]), options)
    exit_code = (
        0
        if cargo_version.exit_code == 0 and llvm_cov_version.exit_code == 0
        else 1
    )
    emit(
        {
            "cargo": result_to_dict(cargo_version),
            "cargo_llvm_cov": result_to_dict(llvm_cov_version),
            "ok": exit_code == 0,
            "script_exit_code": exit_code,
        },
        exit_code,
    )


@app.command()
def summary(
    cwd: str = typer.Option(".", help="Repository or crate directory."),
    toolchain: str | None = typer.Option(
        None,
        help="Optional Rust toolchain, for example 'nightly' for cargo +nightly.",
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
        help="Maximum stdout/stderr bytes to keep.",
    ),
    keep_json: bool = typer.Option(
        False,
        "--keep-json",
        help="Keep the generated JSON report instead of deleting it.",
    ),
) -> None:
    """Run JSON summary coverage."""
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
        result = run_command(
            cargo_command(
                scope, ["--json", "--summary-only", "--output-path", str(output_path)]
            ),
            options,
        )
        payload = result_to_dict(result)
        payload["json_path"] = str(output_path)
        payload["json_path_retained"] = keep_json
        exit_code = result.exit_code
        payload["parsed_summary"] = None
        if result.exit_code == 0 and not result.timed_out:
            report, parse_error = read_json_report(output_path)
            if parse_error:
                payload["parse_error"] = parse_error
                exit_code = 1
            elif report is not None:
                payload["parsed_summary"] = json_totals(report)
        payload["script_exit_code"] = exit_code
        emit(payload, exit_code)
    finally:
        if not keep_json:
            output_path.unlink(missing_ok=True)


@app.command()
def uncovered(
    cwd: str = typer.Option(".", help="Repository or crate directory."),
    toolchain: str | None = typer.Option(
        None,
        help="Optional Rust toolchain, for example 'nightly' for cargo +nightly.",
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
    base: str = typer.Option("HEAD", "--base", help="Git diff base for --changed-only."),
    max_items: int = typer.Option(
        DEFAULT_MAX_ITEMS,
        "--max-items",
        min=1,
        help="Maximum uncovered lines/functions to return.",
    ),
    timeout_seconds: int = typer.Option(
        DEFAULT_TIMEOUT_SECONDS,
        min=1,
        help="Command timeout.",
    ),
    max_output_bytes: int = typer.Option(
        DEFAULT_MAX_OUTPUT_BYTES,
        min=1,
        help="Maximum stdout/stderr bytes to keep.",
    ),
    keep_json: bool = typer.Option(
        False,
        "--keep-json",
        help="Keep the generated JSON report instead of deleting it.",
    ),
) -> None:
    """Run JSON coverage and parse uncovered lines/functions."""
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
        result = run_command(
            cargo_command(scope, ["--json", "--output-path", str(output_path)]),
            options,
        )
        parsed = None
        filters: list[dict[str, Any]] = []
        filter_exit_code = 0
        if result.exit_code == 0 and not result.timed_out:
            report, parse_error = read_json_report(output_path)
            if parse_error:
                filter_exit_code = 1
            elif report is not None:
                parsed = parse_json_report(report, options.cwd)
                filter_paths = {
                    normalize_path(item, options.cwd) for item in path or []
                }
                if changed_only:
                    changed_files, changed_result = get_changed_files(options, base)
                    filters.append({"changed_files_result": changed_result})
                    if (
                        changed_result["exit_code"] == 0
                        and not changed_result["timed_out"]
                    ):
                        filter_paths.update(changed_files)
                    else:
                        filter_exit_code = changed_result["exit_code"] or 1
                if filter_paths:
                    parsed = filter_parsed(parsed, filter_paths)
                parsed = limit_parsed(parsed, max_items)

        payload = {
            **result_to_dict(result),
            "json_path": str(output_path),
            "json_path_retained": keep_json,
            "parsed": parsed,
        }
        if result.exit_code == 0 and not result.timed_out and parsed is None:
            payload["parse_error"] = parse_error
        if filters:
            payload["filters"] = filters
        if filter_exit_code:
            payload["filter_failed"] = True
        payload["script_exit_code"] = filter_exit_code or result.exit_code
        emit(payload, filter_exit_code or result.exit_code)
    finally:
        if not keep_json:
            output_path.unlink(missing_ok=True)


@app.command("diff-uncovered")
def diff_uncovered_command(
    cwd: str = typer.Option(".", help="Repository or crate directory."),
    toolchain: str | None = typer.Option(
        None,
        help="Optional Rust toolchain, for example 'nightly' for cargo +nightly.",
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
        help="Maximum raw uncovered lines/functions to keep.",
    ),
    include_raw: bool = typer.Option(
        False,
        "--include-raw",
        help="Always include raw uncovered lines/functions.",
    ),
    fail_on_diff_uncovered: bool = typer.Option(
        False,
        "--fail-on-diff-uncovered",
        help="Exit non-zero when changed uncovered lines or functions are found.",
    ),
    timeout_seconds: int = typer.Option(
        DEFAULT_TIMEOUT_SECONDS,
        min=1,
        help="Command timeout.",
    ),
    max_output_bytes: int = typer.Option(
        DEFAULT_MAX_OUTPUT_BYTES,
        min=1,
        help="Maximum stdout/stderr bytes to keep.",
    ),
    keep_json: bool = typer.Option(
        False,
        "--keep-json",
        help="Keep the generated JSON report instead of deleting it.",
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
        coverage_result = run_command(
            cargo_command(scope, ["--json", "--output-path", str(output_path)]),
            options,
        )
        diff_result = get_changed_diff(options, base)
        parsed = None
        diff_coverage = None
        diff_parse_error = None
        raw_fallback = None
        exit_code = coverage_result.exit_code

        if diff_result.exit_code != 0 or diff_result.timed_out:
            exit_code = diff_result.exit_code or 1

        if coverage_result.exit_code == 0 and not coverage_result.timed_out:
            report, parse_error = read_json_report(output_path)
            if parse_error:
                exit_code = 1
            elif report is not None:
                parsed = parse_json_report(report, options.cwd)
                if diff_result.exit_code == 0 and not diff_result.timed_out:
                    try:
                        changed = parse_changed_lines(diff_result.stdout)
                    except UnidiffParseError as exc:
                        diff_parse_error = str(exc)
                        exit_code = 1
                    else:
                        diff_coverage = diff_uncovered(parsed, changed)
                        if include_raw or not diff_coverage["matched"]:
                            raw_parsed = limit_parsed(parsed, max_items)
                            raw_fallback = {
                                "reason": "requested"
                                if include_raw
                                else "no_changed_uncovered_lines",
                                "uncovered_lines": raw_parsed["uncovered_lines"],
                                "uncovered_functions": raw_parsed["uncovered_functions"],
                                "truncated_items": raw_parsed["truncated_items"],
                            }
                        if fail_on_diff_uncovered and diff_coverage["matched"]:
                            exit_code = 1

        payload = {
            **result_to_dict(coverage_result),
            "base": base,
            "diff": result_to_dict(diff_result),
            "json_path": str(output_path),
            "json_path_retained": keep_json,
            "parsed_totals": parsed["totals"] if parsed else None,
            "diff_uncovered": diff_coverage,
            "raw_uncovered": raw_fallback,
            "fail_on_diff_uncovered": fail_on_diff_uncovered,
            "failed_on_diff_uncovered": bool(
                fail_on_diff_uncovered
                and diff_coverage is not None
                and diff_coverage["matched"]
            ),
        }
        if diff_parse_error:
            payload["diff_parse_error"] = diff_parse_error
        if (
            coverage_result.exit_code == 0
            and not coverage_result.timed_out
            and parsed is None
        ):
            payload["parse_error"] = parse_error
        if diff_result.exit_code != 0 or diff_result.timed_out:
            payload["diff_failed"] = True
        payload["script_exit_code"] = exit_code
        emit(payload, exit_code)
    finally:
        if not keep_json:
            output_path.unlink(missing_ok=True)


if __name__ == "__main__":
    app()
