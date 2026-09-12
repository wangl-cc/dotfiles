"""Render update reports as plain text or pull-request markdown."""

import urllib.parse
from collections.abc import Mapping
from dataclasses import dataclass
from typing import Literal

from .models import PackageSpec
from .operations import SkippedDowngrade

VerificationStatus = Literal["passed", "partial", "not requested", "not run"]
ReportFormat = Literal["text", "markdown"]

CHANGES_TABLE_HEADER = (
    "| Package | Repository | Previous tag | Updated tag | Changed targets |"
)


@dataclass(frozen=True)
class ChangedTool:
    """One package whose pinned release or target rules changed."""

    tool_name: str
    before: PackageSpec
    after: PackageSpec
    changed_targets: list[str]


def markdown_cell(value: str | None) -> str:
    text = "-" if value is None else value
    return text.replace("|", "\\|").replace("\n", " ")


def markdown_release_link(repo: str, tag: str | None) -> str:
    if tag is None:
        return "-"
    label = markdown_cell(tag).replace("[", "\\[").replace("]", "\\]")
    repo_path = urllib.parse.quote(repo, safe="/")
    tag_path = urllib.parse.quote(tag, safe="")
    return f"[{label}](https://github.com/{repo_path}/releases/tag/{tag_path})"


def comparable_tool(tool: PackageSpec) -> dict[str, object]:
    return tool.model_dump(exclude_none=True)


@dataclass(frozen=True)
class UpdateReport:
    """One update run's facts, rendered as plain text or a pull-request body."""

    before_tools: Mapping[str, PackageSpec]
    after_tools: Mapping[str, PackageSpec]
    verification_status: VerificationStatus
    verify_requested: bool
    resolved_target_count: int
    skipped_downgrades: tuple[SkippedDowngrade, ...]

    def render(self, output_format: ReportFormat) -> str:
        changed_rows = changed_update_rows(self.before_tools, self.after_tools)
        if output_format == "text":
            return render_text_update_report(self, changed_rows)
        return render_markdown_update_report(self, changed_rows)


def changed_update_rows(
    before_tools: Mapping[str, PackageSpec],
    after_tools: Mapping[str, PackageSpec],
) -> list[ChangedTool]:
    rows = []
    for tool_name, after in after_tools.items():
        before = before_tools[tool_name]
        if comparable_tool(before) == comparable_tool(after):
            continue
        rows.append(
            ChangedTool(tool_name, before, after, changed_target_names(before, after))
        )
    return rows


def changed_target_names(before: PackageSpec, after: PackageSpec) -> list[str]:
    names = sorted(set(before.targets) | set(after.targets))
    changed = []
    for name in names:
        before_target = before.targets.get(name)
        after_target = after.targets.get(name)
        before_data = (
            before_target.model_dump(exclude_none=True) if before_target else None
        )
        after_data = (
            after_target.model_dump(exclude_none=True) if after_target else None
        )
        if before_data != after_data:
            changed.append(name)
    return changed


def render_text_update_report(
    report: UpdateReport,
    changed_rows: list[ChangedTool],
) -> str:
    verification = {
        "passed": "verified",
        "partial": "partially verified",
        "not requested": "not verified",
        "not run": "verification not run",
    }[report.verification_status]
    if not changed_rows:
        return (
            f"no portable package changes "
            f"(checked {count_label(len(report.after_tools), 'package')}, "
            f"{count_label(report.resolved_target_count, 'target')}; "
            f"{verification})"
        )
    return "\n".join(
        f"{row.tool_name}: {markdown_cell(row.before.tag)} -> "
        f"{markdown_cell(row.after.tag)}"
        f"{format_text_targets(row.changed_targets)}"
        for row in changed_rows
    )


def format_text_targets(targets: list[str]) -> str:
    if not targets:
        return ""
    return f" ({', '.join(targets)})"


def count_label(count: int, singular: str) -> str:
    suffix = "" if count == 1 else "s"
    return f"{count} {singular}{suffix}"


def render_markdown_update_report(
    report: UpdateReport,
    changed_rows: list[ChangedTool],
) -> str:
    lines = [
        "## Portable package updates",
        "",
        "Automated weekly update of portable GitHub release binaries.",
        "",
        "### Summary",
        "",
        f"- Packages checked: {len(report.after_tools)}",
        f"- Targets resolved: {report.resolved_target_count}",
        f"- Verification: {report.verification_status}",
        "",
        "### Changes",
        "",
    ]

    if changed_rows:
        lines.extend([CHANGES_TABLE_HEADER, "| --- | --- | --- | --- | --- |"])
        for row in changed_rows:
            lines.append(
                "| "
                + " | ".join(
                    [
                        markdown_cell(row.tool_name),
                        markdown_cell(row.after.repo),
                        markdown_cell(row.before.tag),
                        markdown_release_link(row.after.repo, row.after.tag),
                        markdown_cell(", ".join(row.changed_targets) or "-"),
                    ]
                )
                + " |"
            )
    else:
        lines.append("- No portable package changes were found.")

    if report.skipped_downgrades:
        lines.extend(
            [
                "",
                "### Skipped downgrades",
                "",
                "| Package | Configured tag | GitHub latest |",
                "| --- | --- | --- |",
            ]
        )
        for skipped in report.skipped_downgrades:
            lines.append(
                "| "
                + " | ".join(
                    [
                        markdown_cell(skipped.tool_name),
                        markdown_cell(skipped.configured_tag),
                        markdown_release_link(
                            report.after_tools[skipped.tool_name].repo,
                            skipped.candidate_tag,
                        ),
                    ]
                )
                + " |"
            )

    command = "uv run --locked --project portable-pkgs portable-pkgs update"
    if report.verify_requested:
        command += " --verify"
    command += " --format markdown"
    lines.extend(
        [
            "",
            "### Validation",
            "",
            f"- `{command}`",
            "- `git diff --check`",
            "",
        ]
    )
    return "\n".join(lines)
