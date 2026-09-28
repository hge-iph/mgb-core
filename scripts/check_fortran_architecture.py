#!/usr/bin/env python3
"""Check the repository's deliberately small free-form Fortran architecture.

This is a policy checker, not a general Fortran parser. It supports the source
forms used below ``src``: case-insensitive free-form statements, ``&``
continuations, ordinary modules/programs, contained procedures, visibility
statements, and ``use`` with optional intrinsic qualifiers and renames.
Compiler modules such as ``omp_lib`` and ``ifport`` are ignored because only
imports resolving to project modules are architecture edges.
"""

from __future__ import annotations

import argparse
import re
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]

CLASSIFICATION = {
    "date_time": "common", "interpolation": "common", "runtime_support": "common",
    "attributes": "vars", "config": "vars", "forcing": "vars",
    "parameters": "vars", "state": "vars",
    "catchment": "hydrology", "river_muskingum": "hydrology",
    "river_inertial": "hydrology", "reservoirs": "hydrology",
    "configuration_io": "io", "log_io": "io", "static_input_io": "io",
    "meteorological_io": "io", "reservoir_io": "io", "hotstart_io": "io", "output_io": "io",
    "runner": "runner",
}

APPLICATION_ALLOWED_DEPENDENCIES = {
    "attributes", "config", "forcing", "parameters", "state",
    "configuration_io", "log_io", "runner",
}

EXPECTED_PATHS = {
    "common": "common/", "vars": "vars/", "hydrology": "hydrology/", "io": "io/",
    "runner": "simulation/",
}


@dataclass(frozen=True)
class Statement:
    text: str
    line: int


def statements(text: str) -> list[Statement]:
    result: list[Statement] = []
    current = ""
    start = 0
    for number, raw in enumerate(text.splitlines(), 1):
        code = raw.split("!", 1)[0].strip()
        if not code:
            continue
        if not current:
            start = number
        current = (current + " " + code.lstrip("&").strip()).strip()
        if current.endswith("&"):
            current = current[:-1].rstrip()
        else:
            result.append(Statement(current.lower(), start))
            current = ""
    if current:
        result.append(Statement(current.lower(), start))
    return result


def module_name(items: list[Statement]) -> str | None:
    for item in items:
        match = re.match(r"module\s+(?!procedure\b)([a-z_]\w*)", item.text)
        if match:
            return match.group(1)
    return None


def external_procedures(items: list[Statement]) -> list[Statement]:
    """Return procedure starts that are outside a module or program scope."""
    result: list[Statement] = []
    in_module = False
    in_program = False
    for item in items:
        if re.match(r"module\s+(?!procedure\b)[a-z_]\w*", item.text):
            in_module = True
            continue
        if re.match(r"program\s+[a-z_]\w*", item.text):
            in_program = True
            continue
        if re.match(r"end\s*module\b", item.text):
            in_module = False
            continue
        if re.match(r"end\s*program\b", item.text):
            in_program = False
            continue
        procedure = re.match(
            r"(?:(?:real(?:\([^)]*\)|\*\d+)?|integer|logical|character(?:\([^)]*\))?)\s+)?"
            r"(?:subroutine|function)\s+",
            item.text,
        )
        if procedure and not (in_module or in_program):
            result.append(item)
    return result


def expected_location(name: str, category: str) -> str:
    return EXPECTED_PATHS[category]


def edge_allowed(consumer: str, dependency: str) -> bool:
    if consumer == "application":
        return dependency in APPLICATION_ALLOWED_DEPENDENCIES

    category = CLASSIFICATION[consumer]
    dependency_category = CLASSIFICATION[dependency]
    if category == "common":
        return dependency_category == "common"
    if category == "vars":
        return False
    if category in {"hydrology", "io"}:
        return dependency_category in {"vars", "common"}
    if category == "runner":
        return True
    return False


def check_tree(source_root: Path) -> list[str]:
    files = sorted(source_root.rglob("*.f90"))
    parsed = {path: statements(path.read_text(encoding="utf-8")) for path in files}
    modules = {name: path for path, items in parsed.items() if (name := module_name(items))}
    errors: list[str] = []
    programs: list[tuple[Path, Statement]] = []

    for path, items in parsed.items():
        relative = path.relative_to(source_root).as_posix()
        name = module_name(items)
        program_items = [item for item in items if re.match(r"program\s+\w+", item.text)]
        consumer = name if name else "application" if program_items else None
        programs.extend((path, item) for item in program_items)
        if name:
            if name not in CLASSIFICATION:
                errors.append(f"{relative}:1: unclassified project module '{name}'")
                continue
            prefix = expected_location(name, CLASSIFICATION[name])
            if not relative.startswith(prefix):
                errors.append(f"{relative}:1: module '{name}' must be below src/{prefix}")
            if not any(item.text == "implicit none" for item in items):
                errors.append(f"{relative}:1: module '{name}' requires implicit none")
            if CLASSIFICATION[name] == "vars":
                if any(item.text == "private" for item in items):
                    errors.append(f"{relative}:1: vars module '{name}' requires default public visibility")
                if any(re.match(r"type\s*(?:,.*)?::\s*[a-z_]\w*", item.text) for item in items):
                    errors.append(f"{relative}:1: vars module '{name}' may not define named types")
            else:
                if not any(item.text == "private" for item in items):
                    errors.append(f"{relative}:1: module '{name}' requires default private visibility")
                if not any(re.match(r"public\s*::", item.text) for item in items):
                    errors.append(f"{relative}:1: module '{name}' requires an explicit public API")
        elif not program_items and not external_procedures(items):
            errors.append(f"{relative}:1: source is not an approved project module or program")

        for item in external_procedures(items):
            errors.append(f"{relative}:{item.line}: external project procedure is forbidden")

        for item in items:
            match = re.match(r"use\s*(?:,\s*(intrinsic|non_intrinsic)\s*)?(?:::\s*)?([a-z_]\w*)(.*)", item.text)
            if not match:
                continue
            dependency, suffix = match.group(2), match.group(3)
            if dependency not in modules:
                continue
            if "only:" not in suffix:
                errors.append(f"{relative}:{item.line}: project import '{dependency}' requires an only list")
            if consumer and not edge_allowed(consumer, dependency):
                errors.append(
                    f"{relative}:{item.line}: forbidden dependency {consumer} -> {dependency}"
                )

    if len(programs) != 1:
        errors.append(f"src:1: expected exactly one program, found {len(programs)}")
    elif programs[0][0].relative_to(source_root).as_posix() != "simulation/main.f90":
        path, item = programs[0]
        errors.append(f"{path.relative_to(source_root)}:{item.line}: program must be simulation/main.f90")
    else:
        program_path, _ = programs[0]
        if not any(item.text == "implicit none" for item in parsed[program_path]):
            errors.append("simulation/main.f90:1: program requires implicit none")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--src", type=Path, default=ROOT / "src")
    args = parser.parse_args()
    errors = check_tree(args.src)
    if errors:
        print("\n".join(errors))
        return 1
    print(f"Fortran architecture check passed: {len(list(args.src.rglob('*.f90')))} files")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
