#!/usr/bin/env python3
"""Check the repository's manual Fortran layout and fprettify compatibility."""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

MAX_LINE_LENGTH = 100


def code_part(line: str) -> str:
    """Return the code before a comment, respecting character literals."""

    quote: str | None = None
    index = 0
    while index < len(line):
        character = line[index]
        if quote:
            if character == quote:
                if index + 1 < len(line) and line[index + 1] == quote:
                    index += 2
                    continue
                quote = None
        elif character in "'\"":
            quote = character
        elif character == "!":
            return line[:index]
        index += 1
    return line


def literal_is_open(line: str) -> bool:
    quote: str | None = None
    index = 0
    while index < len(line):
        character = line[index]
        if quote:
            if character == quote:
                if index + 1 < len(line) and line[index + 1] == quote:
                    index += 2
                    continue
                quote = None
        elif character in "'\"":
            quote = character
        elif character == "!":
            break
        index += 1
    return quote is not None


def check_layout(path: Path) -> list[str]:
    errors: list[str] = []
    lines = path.read_text(encoding="utf-8").splitlines()
    continuation_base: int | None = None

    for line_number, line in enumerate(lines, 1):
        if "\t" in line:
            errors.append(f"{path}:{line_number}: tabs are forbidden")
        if line.rstrip() != line:
            errors.append(f"{path}:{line_number}: trailing whitespace")

        openmp = line.lstrip().lower().startswith("!$omp")
        if len(line) > MAX_LINE_LENGTH and not openmp:
            errors.append(
                f"{path}:{line_number}: line has {len(line)} columns; "
                f"maximum is {MAX_LINE_LENGTH}"
            )

        stripped = line.lstrip(" ")
        if not stripped:
            continue

        indentation = len(line) - len(stripped)
        if indentation % 4:
            errors.append(f"{path}:{line_number}: indentation is not a multiple of four")

        if stripped.startswith("!"):
            if continuation_base is not None and not openmp:
                errors.append(
                    f"{path}:{line_number}: continuation lines must begin with '&'"
                )
            continue

        code = code_part(line).rstrip()
        if code.endswith("&") and literal_is_open(line):
            errors.append(
                f"{path}:{line_number}: character literals must not be split across lines"
            )
        starts_continuation = code.lstrip().startswith("&")
        if continuation_base is not None:
            if not starts_continuation:
                errors.append(f"{path}:{line_number}: continuation lines must begin with '&'")
            elif not (
                indentation == continuation_base + 4
                or (
                    indentation == continuation_base
                    and code.lstrip()[1:].lstrip().startswith(("'", '"'))
                )
            ):
                errors.append(
                    f"{path}:{line_number}: continuation indentation must be four spaces "
                    "beyond the statement (except for long format literals)"
                )
        elif starts_continuation:
            errors.append(f"{path}:{line_number}: unexpected continuation marker")

        if code.endswith("&"):
            if continuation_base is None:
                continuation_base = indentation
        else:
            continuation_base = None

    if continuation_base is not None:
        errors.append(f"{path}:{len(lines)}: unterminated continuation")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path, nargs="?", default=Path("src"))
    args = parser.parse_args()

    source = args.source.resolve()
    with tempfile.TemporaryDirectory(prefix="mgb-format-") as temporary_directory:
        formatted = Path(temporary_directory) / source.name
        shutil.copytree(source, formatted)
        command = [
            "fprettify",
            "--recursive",
            "--config-file",
            str(Path(".fprettify.rc").resolve()),
            str(formatted),
        ]
        completed = subprocess.run(command, text=True, capture_output=True)
        if completed.returncode != 0:
            sys.stderr.write(completed.stdout)
            sys.stderr.write(completed.stderr)
            return completed.returncode

        errors = []
        for path in sorted(source.rglob("*.f90")):
            errors.extend(check_layout(path))

        if errors:
            sys.stderr.write("Fortran formatting is not clean:\n")
            sys.stderr.write("\n".join(errors) + "\n")
            return 1

    print("Fortran formatting is clean and fprettify-compatible.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
