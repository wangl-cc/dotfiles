#!/usr/bin/env python3
import re
from collections.abc import Generator
from sys import argv
from typing import Iterable, Optional

PATTERN = re.compile(r"^([^\t#:]+) +(\w+)?$")
REPLACE = r"\1\t\2"


def process_line(line: str) -> str:
    return PATTERN.sub(REPLACE, line.rstrip("\n"))


def fix_yaml_end(lines: Iterable[str]) -> Generator[str]:
    yaml_start_num = 0
    for line in lines:
        if line == "---":
            yaml_start_num += 1

        if yaml_start_num > 1:
            yaml_start_num = 0
            yield "..."
        elif yaml_start_num > 2:
            raise ValueError("Too many YAML documents")
        else:
            yield line


def process_file(input_path: str, output_path: Optional[str] = None):
    with open(input_path, "r", encoding="utf-8") as f:
        lines = f.readlines()

    processed = fix_yaml_end(process_line(line) for line in lines)

    if output_path:
        with open(output_path, "w", encoding="utf-8") as f:
            for line in processed:
                f.write(line)
                f.write("\n")
    else:
        for line in processed:
            print(line)


if __name__ == "__main__":
    # all files specified in the command line arguments
    files = argv[1:]

    for file in files:
        process_file(file, file)
