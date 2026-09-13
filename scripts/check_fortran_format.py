#!/usr/bin/env python3
"""Check the repository's manual Fortran layout and fprettify compatibility."""

from __future__ import annotations

import argparse
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

MAX_LINE_LENGTH = 132


def split_top_level(text: str) -> list[str]:
    """Split a comma-separated Fortran list without splitting array shapes."""

    parts: list[str] = []
    start = 0
    depth = 0
    quote: str | None = None
    index = 0
    while index < len(text):
        character = text[index]
        if quote:
            if character == quote:
                if index + 1 < len(text) and text[index + 1] == quote:
                    index += 2
                    continue
                quote = None
        elif character in "'\"":
            quote = character
        elif character == "(":
            depth += 1
        elif character == ")":
            depth -= 1
        elif character == "," and depth == 0:
            parts.append(text[start:index].strip())
            start = index + 1
        index += 1
    parts.append(text[start:].strip())
    return [part for part in parts if part]


def logical_statements(lines: list[str]) -> list[tuple[int, list[str], str]]:
    """Return source line, physical code lines, and joined logical statement."""

    statements: list[tuple[int, list[str], str]] = []
    physical: list[str] = []
    start = 0
    for line_number, line in enumerate(lines, 1):
        code = code_part(line).strip()
        if not code:
            continue
        if not physical:
            start = line_number
        physical.append(code)
        continued = code.endswith("&")
        if continued:
            continue
        joined = " ".join(
            item.rstrip("&").strip().lstrip("&").strip() for item in physical
        )
        statements.append((start, physical, joined))
        physical = []
    return statements


def has_assignment(statement: str) -> bool:
    """Return whether a logical statement is an assignment equation."""

    prefix = statement.lstrip().lower()
    if prefix.startswith(
        (
            "call ",
            "use ",
            "allocate ",
            "deallocate ",
            "if ",
            "elseif ",
            "open ",
            "read ",
            "write ",
            "inquire ",
            "namelist ",
        )
    ):
        return False
    return re.search(r"(?<![<>=/])=(?!=|>)", code_part(statement)) is not None


def check_structural_layout(
    path: Path,
    lines: list[str],
    project_procedures: set[str],
) -> list[str]:
    """Check repository-specific one-item-per-line layout rules."""

    errors: list[str] = []
    declaration = re.compile(
        r"^(?:integer|real|logical|complex|character|type\s*\([^)]*\))\b",
        re.IGNORECASE,
    )
    procedure = re.compile(
        r"^(?:(?:integer|real|logical|complex|character)(?:\s*\([^)]*\)|\*\d+)?\s+)?"
        r"(?:subroutine|function)\s+([a-z_]\w*)",
        re.IGNORECASE,
    )
    call = re.compile(r"^call\s+([a-z_]\w*)", re.IGNORECASE)

    for line_number, physical, statement in logical_statements(lines):
        lowered = statement.lower()
        if "::" in statement and declaration.match(statement):
            entities = split_top_level(statement.split("::", 1)[1])
            if len(entities) > 1:
                errors.append(f"{path}:{line_number}: declare one variable per line")

        for keyword in ("allocate", "deallocate"):
            if lowered.startswith(f"{keyword} "):
                inner = statement[statement.find("(") + 1:statement.rfind(")")]
                if len(split_top_level(inner)) > 1:
                    errors.append(f"{path}:{line_number}: {keyword} one target per statement")

        if lowered.startswith("use ") and "only:" in lowered:
            imported = split_top_level(statement[lowered.index("only:") + len("only:"):])
            if len(imported) > 1:
                first = physical[0].lower()
                continuations = physical[1:]
                if not first.rstrip().endswith("only: &") or len(continuations) != len(imported):
                    errors.append(f"{path}:{line_number}: put one imported name on each line")

        procedure_match = procedure.match(statement)
        if procedure_match and "(" in statement:
            inner = statement[statement.find("(") + 1:statement.rfind(")")]
            arguments = split_top_level(inner)
            if arguments and len(physical) != len(arguments) + 1:
                errors.append(f"{path}:{line_number}: put one dummy argument on each line")

        call_match = call.match(statement)
        if call_match and call_match.group(1).lower() in project_procedures and "(" in statement:
            inner = statement[statement.find("(") + 1:statement.rfind(")")]
            arguments = split_top_level(inner)
            if arguments and len(physical) != len(arguments) + 1:
                errors.append(f"{path}:{line_number}: put one actual argument on each line")

        if len(physical) > 1 and has_assignment(statement):
            errors.append(f"{path}:{line_number}: equations must occupy one physical line")
    return errors


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

        if len(line) > MAX_LINE_LENGTH:
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
            if continuation_base is not None and not line.lstrip().lower().startswith("!$omp"):
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

        paths = sorted(source.rglob("*.f90"))
        project_procedures: set[str] = set()
        procedure_pattern = re.compile(
            r"^(?:(?:integer|real|logical|complex|character)(?:\s*\([^)]*\)|\*\d+)?\s+)?"
            r"(?:subroutine|function)\s+([a-z_]\w*)",
            re.IGNORECASE,
        )
        for path in paths:
            lines = path.read_text(encoding="utf-8").splitlines()
            for _, _, statement in logical_statements(lines):
                if match := procedure_pattern.match(statement):
                    project_procedures.add(match.group(1).lower())

        errors = []
        for path in paths:
            lines = path.read_text(encoding="utf-8").splitlines()
            errors.extend(check_layout(path))
            errors.extend(check_structural_layout(path, lines, project_procedures))

        if errors:
            sys.stderr.write("Fortran formatting is not clean:\n")
            sys.stderr.write("\n".join(errors) + "\n")
            return 1

    print("Fortran formatting is clean and fprettify-compatible.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
