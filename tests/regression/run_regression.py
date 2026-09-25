from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

from compare_regression import compare_manifest, load_manifest, RegressionFailure


class RunFailure(RuntimeError):
    pass


def prepare_work_dir(case_dir: Path, work_dir: Path | None) -> tuple[Path, tempfile.TemporaryDirectory[str] | None]:
    if work_dir is not None:
        if work_dir.exists():
            shutil.rmtree(work_dir)
        work_dir.mkdir(parents=True, exist_ok=True)
        return work_dir, None

    temp_dir = tempfile.TemporaryDirectory(prefix="mgb-regression-")
    return Path(temp_dir.name), temp_dir


def stage_case(case_dir: Path, manifest: dict, work_dir: Path) -> tuple[Path, Path]:
    input_dir = case_dir / manifest["input_dir"]
    output_dir = work_dir / "output"
    shutil.copytree(input_dir, work_dir / "input")
    for relative_path in manifest.get("input_overrides", []):
        source = case_dir / relative_path
        shutil.copy2(source, work_dir / "input" / source.name)
    output_dir.mkdir(parents=True, exist_ok=True)
    return input_dir, output_dir


def run_case(case_dir: Path, exe_path: Path, work_dir: Path | None) -> None:
    manifest_path = case_dir / "manifest.json"
    manifest = load_manifest(manifest_path)
    runtime_root, temp_dir = prepare_work_dir(case_dir, work_dir)
    keep_temp_dir = False
    try:
        _, output_dir = stage_case(case_dir, manifest, runtime_root)

        env = os.environ.copy()
        env["MGB_NONINTERACTIVE"] = "1"
        completed = subprocess.run([str(exe_path.resolve())], cwd=runtime_root, env=env)
        if completed.returncode != 0:
            raise RunFailure(f"Model exited with code {completed.returncode}")

        compare_manifest(manifest_path, case_dir / manifest["expected_dir"], output_dir)
    except (RunFailure, RegressionFailure) as exc:
        keep_temp_dir = work_dir is None
        print(str(exc), file=sys.stderr)
        if keep_temp_dir:
            print(f"Temporary work directory preserved at: {runtime_root}", file=sys.stderr)
        raise SystemExit(1) from exc
    finally:
        if temp_dir is not None and not keep_temp_dir:
            temp_dir.cleanup()


def main() -> int:
    parser = argparse.ArgumentParser(description="Run an MGB regression case and compare selected outputs.")
    parser.add_argument("--case-dir", required=True, type=Path)
    parser.add_argument("--exe", required=True, type=Path)
    parser.add_argument("--work-dir", type=Path)
    args = parser.parse_args()

    run_case(args.case_dir.resolve(), args.exe.resolve(), args.work_dir.resolve() if args.work_dir else None)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
