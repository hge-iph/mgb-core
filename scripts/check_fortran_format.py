#!/usr/bin/env python3
"""Check that pinned fprettify produces no source changes."""

from __future__ import annotations

import argparse
import difflib
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


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

        differences = []
        for original_path in sorted(source.rglob("*.f90")):
            formatted_path = formatted / original_path.relative_to(source)
            original_lines = original_path.read_text(encoding="utf-8").splitlines(keepends=True)
            formatted_lines = formatted_path.read_text(encoding="utf-8").splitlines(keepends=True)
            if original_lines != formatted_lines:
                differences.extend(
                    difflib.unified_diff(
                        original_lines,
                        formatted_lines,
                        fromfile=str(original_path),
                        tofile=str(original_path),
                    )
                )

        if differences:
            sys.stderr.write("Fortran formatting is not clean; run fprettify with .fprettify.rc.\n")
            sys.stderr.writelines(differences)
            return 1

    print("Fortran formatting is clean.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
