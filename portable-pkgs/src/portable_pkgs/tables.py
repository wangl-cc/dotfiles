"""Shared output toolkit: plain human listing and JSON formats.

The human listing is not a stable contract; only JSON output is.
"""

import json
import sys
from collections.abc import Sequence
from dataclasses import dataclass
from typing import Literal

OutputFormat = Literal["human", "json"]
AddFormat = Literal["human", "json"]


@dataclass(frozen=True)
class Column:
    key: str
    header: str


def cell_text(value: object) -> str:
    if value is None:
        return "-"
    if isinstance(value, list):
        return ", ".join(str(item) for item in value) or "-"
    text = str(value)
    return text if text else "-"


def render_listing(rows: list[dict[str, object]], columns: Sequence[Column]) -> str:
    lines = ["  ".join(column.header for column in columns)]
    for row in rows:
        lines.append("  ".join(cell_text(row.get(column.key)) for column in columns))
    return "\n".join(lines)


def print_rows(
    rows: list[dict[str, object]],
    columns: Sequence[Column],
    output_format: OutputFormat,
) -> None:
    match output_format:
        case "human":
            print(render_listing(rows, columns))
        case "json":
            print(json.dumps(rows, indent=2))


def log(message: str) -> None:
    print(message, file=sys.stderr)
