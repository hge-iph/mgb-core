from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

from compare_regression import RegressionFailure, case_shape, compare_manifest, load_manifest
from report_regression import ReportFailure, validate_thresholds, write_report


class RunFailure(RuntimeError):
    pass


def prepare_results_dir(results_dir: Path | None) -> tuple[Path, tempfile.TemporaryDirectory[str] | None]:
    if results_dir is None:
        temp_dir = tempfile.TemporaryDirectory(prefix="mgb-regression-")
        return Path(temp_dir.name), temp_dir

    results_dir.mkdir(parents=True, exist_ok=True)
    for name in ("input", "output", "report.html"):
        generated = results_dir / name
        if generated.is_symlink() or generated.is_file():
            generated.unlink()
        elif generated.is_dir():
            shutil.rmtree(generated)
    return results_dir, None


def stage_case(case_dir: Path, manifest: dict, results_dir: Path) -> Path:
    input_dir = case_dir / manifest["input_dir"]
    output_dir = results_dir / "output"
    shutil.copytree(input_dir, results_dir / "input")
    for relative_path in manifest.get("input_overrides", []):
        source = case_dir / relative_path
        shutil.copy2(source, results_dir / "input" / source.name)
    output_dir.mkdir(parents=True, exist_ok=True)
    return output_dir


def run_case(
    case_dir: Path,
    exe_path: Path,
    results_dir: Path | None = None,
    threshold_abs: float = 1.0e-2,
    threshold_rel: float = 1.0e-3,
) -> None:
    validate_thresholds(threshold_abs, threshold_rel)
    manifest_path = case_dir / "manifest.json"
    manifest = load_manifest(manifest_path)
    case_root = case_dir.resolve()
    if results_dir is not None:
        result_root = results_dir.resolve()
        if result_root == case_root or result_root in case_root.parents:
            raise ValueError("results-dir must be outside the case directory and its parents")
    runtime_root, temp_dir = prepare_results_dir(results_dir)
    keep_temp_dir = False

    try:
        output_dir = stage_case(case_dir, manifest, runtime_root)
        config_path = runtime_root / "input" / "config.nml"
        shape = case_shape(manifest, config_path)

        env = os.environ.copy()
        env["MGB_NONINTERACTIVE"] = "1"
        try:
            completed = subprocess.run(
                [str(exe_path.resolve())],
                cwd=runtime_root,
                env=env,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
            )
        except OSError as exc:
            raise RunFailure(f"Could not start model: {exc}") from exc
        if completed.returncode != 0:
            model_output = getattr(completed, "stdout", "")
            if model_output:
                print(model_output, file=sys.stderr, end="")
            raise RunFailure(f"Model exited with code {completed.returncode}")

        try:
            results = compare_manifest(
                manifest_path, case_dir / manifest["expected_dir"], output_dir, config_path
            )
        except RegressionFailure as exc:
            if results_dir is not None:
                try:
                    report_path = write_report(
                        results_dir, manifest, shape, exc.results, exc.errors, threshold_abs, threshold_rel
                    )
                    print(f"Regression report written to: {report_path}")
                except Exception as report_exc:
                    print(f"Could not write regression report: {report_exc}", file=sys.stderr)
            raise

        if results_dir is not None:
            try:
                report_path = write_report(
                    results_dir, manifest, shape, results, [], threshold_abs, threshold_rel
                )
            except Exception as exc:
                raise ReportFailure(f"Could not write regression report: {exc}") from exc
            print(f"Regression report written to: {report_path}")
    except (RunFailure, RegressionFailure, ReportFailure, OSError, ValueError) as exc:
        keep_temp_dir = results_dir is None
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
    parser.add_argument("--results-dir", type=Path)
    parser.add_argument("--threshold-abs", type=float, default=0.1)
    parser.add_argument("--threshold-rel", type=float, default=0.01)
    args = parser.parse_args()

    try:
        run_case(
            args.case_dir.resolve(),
            args.exe.resolve(),
            args.results_dir.resolve() if args.results_dir else None,
            args.threshold_abs,
            args.threshold_rel,
        )
    except ValueError as exc:
        parser.error(str(exc))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
