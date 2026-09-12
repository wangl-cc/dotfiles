"""Shared CLI capture and githubkit schema fixtures for regression tests."""

import contextlib
import datetime
import io
import sys
import types
import typing
from dataclasses import dataclass
from pathlib import Path

from pydantic import BaseModel

from portable_pkgs import cli

CONSOLE = Path(sys.executable).with_name("portable-pkgs")


@dataclass(frozen=True)
class CliResult:
    exit_code: int
    stdout: str
    stderr: str

    @property
    def output(self) -> str:
        return self.stdout + self.stderr


def run_cli(args: list[str]) -> CliResult:
    stdout, stderr = io.StringIO(), io.StringIO()
    exit_code = 0
    with contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
        try:
            cli.cli(args)
        except SystemExit as error:
            if isinstance(error.code, int):
                exit_code = error.code
            elif error.code is not None:
                exit_code = 1
                print(error.code, file=stderr)
    return CliResult(exit_code, stdout.getvalue(), stderr.getvalue())


def fill_schema(model: type[BaseModel], **overrides: object) -> dict[str, object]:
    """Build a minimal valid payload for a githubkit generated schema.

    githubkit models require GitHub's complete field set, so fixtures fill
    every required field recursively and then apply the test's overrides.
    """
    data: dict[str, object] = {}
    for name, field in model.model_fields.items():
        if not field.is_required():
            continue
        annotation = field.annotation
        origin = typing.get_origin(annotation)
        arguments = typing.get_args(annotation)
        if isinstance(annotation, type) and issubclass(annotation, BaseModel):
            data[name] = fill_schema(annotation)
        elif origin is typing.Literal:
            data[name] = arguments[0]
        elif origin in (list, tuple):
            data[name] = []
        elif origin in (types.UnionType, typing.Union):
            first = next(a for a in arguments if a is not type(None))
            if isinstance(first, type) and issubclass(first, BaseModel):
                data[name] = fill_schema(first)
            elif first is datetime.datetime:
                data[name] = "2026-01-01T00:00:00Z"
            elif first is str:
                data[name] = "x"
            else:
                data[name] = 0
        elif annotation is datetime.datetime:
            data[name] = "2026-01-01T00:00:00Z"
        elif annotation is str:
            data[name] = "x"
        elif annotation is bool:
            data[name] = False
        elif annotation in (int, float):
            data[name] = 0
        else:
            data[name] = "x"
    return data | overrides
