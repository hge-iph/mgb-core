from __future__ import annotations

import argparse
import array
import json
import math
import sys
from pathlib import Path
from typing import Any


FLOAT32_SIZE = 4


class RegressionFailure(RuntimeError):
    pass


def load_manifest(manifest_path: Path) -> dict[str, Any]:
    with manifest_path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def read_float32_file(path: Path) -> array.array:
    data = path.read_bytes()
    if len(data) % FLOAT32_SIZE != 0:
        raise RegressionFailure(f"{path} size {len(data)} is not divisible by {FLOAT32_SIZE} bytes")

    values = array.array("f")
    values.frombytes(data)
    if sys.byteorder != "little":
        values.byteswap()
    return values


def compare_float32_files(expected_path: Path, actual_path: Path, atol: float, rtol: float) -> dict[str, float]:
    if not expected_path.exists():
        raise RegressionFailure(f"Missing expected file: {expected_path}")
    if not actual_path.exists():
        raise RegressionFailure(f"Missing actual file: {actual_path}")

    expected_size = expected_path.stat().st_size
    actual_size = actual_path.stat().st_size
    if expected_size != actual_size:
        raise RegressionFailure(
            f"Size mismatch for {expected_path.name}: expected {expected_size} bytes, got {actual_size} bytes"
        )

    expected_values = read_float32_file(expected_path)
    actual_values = read_float32_file(actual_path)
    if len(expected_values) != len(actual_values):
        raise RegressionFailure(
            f"Value count mismatch for {expected_path.name}: expected {len(expected_values)}, got {len(actual_values)}"
        )

    max_abs = 0.0
    max_rel = 0.0
    max_index = -1
    for index, (expected_value, actual_value) in enumerate(zip(expected_values, actual_values)):
        if math.isnan(expected_value) or math.isnan(actual_value):
            raise RegressionFailure(f"NaN encountered in {expected_path.name} at index {index}")

        abs_error = abs(actual_value - expected_value)
        rel_error = abs_error / max(abs(expected_value), abs(actual_value), 1.0e-30)
        if abs_error > max_abs or rel_error > max_rel:
            max_abs = max(max_abs, abs_error)
            max_rel = max(max_rel, rel_error)
            max_index = index

    if max_abs > atol or max_rel > rtol:
        raise RegressionFailure(
            f"Tolerance exceeded for {expected_path.name}: max_abs={max_abs:.8e}, max_rel={max_rel:.8e}, index={max_index}"
        )

    return {
        "count": float(len(expected_values)),
        "max_abs": max_abs,
        "max_rel": max_rel,
        "max_index": float(max_index),
    }


def compare_manifest(manifest_path: Path, expected_dir: Path, actual_dir: Path) -> None:
    manifest = load_manifest(manifest_path)
    required_outputs = manifest.get("required_outputs", [])
    for relative_path in required_outputs:
        required_path = actual_dir / relative_path
        if not required_path.exists():
            raise RegressionFailure(f"Required output is missing: {required_path}")

    for entry in manifest.get("comparisons", []):
        if entry.get("dtype") != "float32":
            raise RegressionFailure(f"Unsupported dtype in manifest: {entry.get('dtype')}")

        relative_path = entry["path"]
        result = compare_float32_files(
            expected_dir / relative_path,
            actual_dir / relative_path,
            float(entry["atol"]),
            float(entry["rtol"]),
        )
        print(
            f"{relative_path}: count={int(result['count'])} max_abs={result['max_abs']:.8e} "
            f"max_rel={result['max_rel']:.8e} index={int(result['max_index'])}"
        )


def main() -> int:
    parser = argparse.ArgumentParser(description="Compare regression outputs against a manifest.")
    parser.add_argument("--manifest", required=True, type=Path)
    parser.add_argument("--expected-dir", required=True, type=Path)
    parser.add_argument("--actual-dir", required=True, type=Path)
    args = parser.parse_args()

    try:
        compare_manifest(args.manifest.resolve(), args.expected_dir.resolve(), args.actual_dir.resolve())
    except RegressionFailure as exc:
        print(str(exc), file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())

