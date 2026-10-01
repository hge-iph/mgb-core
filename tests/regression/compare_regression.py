from __future__ import annotations

import argparse
import array
import json
import math
import re
import sys
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any


DTYPES = {"float32": ("f", 4)}


class RegressionFailure(RuntimeError):
    def __init__(self, message: str, *, results: dict[str, dict[str, Any]] | None = None,
                 errors: list[str] | None = None):
        super().__init__(message)
        self.results = results or {}
        self.errors = errors or [message]


def load_manifest(manifest_path: Path) -> dict[str, Any]:
    with manifest_path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def effective_config_path(manifest_path: Path, manifest: dict[str, Any]) -> Path:
    case_dir = manifest_path.parent
    config_path = case_dir / manifest.get("input_dir", "input") / "config.nml"
    for relative_path in manifest.get("input_overrides", []):
        override = case_dir / relative_path
        if override.name.lower() == "config.nml":
            config_path = override
    return config_path


def read_case_config(config_path: Path) -> tuple[int, int]:
    try:
        lines = config_path.read_text(encoding="utf-8").splitlines()
    except OSError as exc:
        raise RegressionFailure(f"Could not read case config {config_path}: {exc}") from exc

    values: dict[str, str] = {}
    for line in lines:
        code = line.partition("!")[0]
        match = re.match(r"\s*(catchment_count|model_timestep)\s*=\s*([^,\s/]+)", code, re.IGNORECASE)
        if match:
            values[match.group(1).lower()] = match.group(2)
    try:
        catchment_value = float(values["catchment_count"])
        timestep_value = float(values["model_timestep"])
    except (KeyError, ValueError) as exc:
        raise RegressionFailure(
            f"Case config {config_path} must define numeric catchment_count and model_timestep"
        ) from exc

    if (
        not math.isfinite(catchment_value)
        or catchment_value < 1
        or not catchment_value.is_integer()
    ):
        raise RegressionFailure(f"catchment_count in {config_path} must be a positive integer")
    if not math.isfinite(timestep_value) or timestep_value < 1 or not timestep_value.is_integer():
        raise RegressionFailure(f"model_timestep in {config_path} must be a positive whole number of seconds")
    return int(catchment_value), int(timestep_value)


def case_shape(manifest: dict[str, Any], config_path: Path) -> dict[str, Any]:
    try:
        start = datetime.fromisoformat(manifest["simulation_start"])
        end = datetime.fromisoformat(manifest["simulation_end"])
    except (KeyError, TypeError, ValueError) as exc:
        raise RegressionFailure(f"Invalid regression case metadata: {exc}") from exc

    catchment_count, timestep_seconds = read_case_config(config_path)
    if start.tzinfo != end.tzinfo:
        raise RegressionFailure("simulation_start and simulation_end must use the same timezone")

    duration = (end - start).total_seconds()
    if duration < 0 or duration % timestep_seconds != 0:
        raise RegressionFailure("Simulation period must be non-negative and align with timestep_seconds")

    return {
        "catchment_count": catchment_count,
        "simulation_start": start,
        "simulation_end": end,
        "timestep_seconds": timestep_seconds,
        "timestep_count": int(duration // timestep_seconds) + 1,
    }


def format_location(index: int, shape: dict[str, Any]) -> dict[str, Any]:
    timestep = index // shape["catchment_count"] + 1
    catchment = index % shape["catchment_count"] + 1
    timestamp = shape["simulation_start"] + timedelta(
        seconds=(timestep - 1) * shape["timestep_seconds"]
    )
    return {
        "index": index,
        "timestep": timestep,
        "date": timestamp.isoformat(sep=" "),
        "catchment": catchment,
    }


def read_values(path: Path, dtype: str) -> array.array:
    if dtype not in DTYPES:
        raise RegressionFailure(f"Unsupported dtype in manifest: {dtype}")

    typecode, itemsize = DTYPES[dtype]
    try:
        data = path.read_bytes()
    except FileNotFoundError as exc:
        raise RegressionFailure(f"Missing file: {path}") from exc
    except OSError as exc:
        raise RegressionFailure(f"Could not read {path}: {exc}") from exc

    if len(data) % itemsize:
        raise RegressionFailure(
            f"Malformed byte length in {path}: {len(data)} bytes is not divisible by {itemsize}"
        )

    values = array.array(typecode)
    values.frombytes(data)
    if sys.byteorder != "little":
        values.byteswap()
    return values


def linear_percentile(values: list[float], fraction: float) -> float:
    ordered = sorted(values)
    position = fraction * (len(ordered) - 1)
    lower = int(position)
    upper = min(lower + 1, len(ordered) - 1)
    weight = position - lower
    return ordered[lower] + (ordered[upper] - ordered[lower]) * weight


def _check_shape(path: Path, values: array.array, shape: dict[str, Any], empty_expected: bool) -> None:
    count = len(values)
    if count == 0:
        if empty_expected:
            return
        raise RegressionFailure(f"Empty file is not declared as an empty expected product: {path}")
    if empty_expected:
        raise RegressionFailure(f"Manifest declares {path.name} empty but it contains {count} values")

    catchment_count = shape["catchment_count"]
    if count % catchment_count:
        raise RegressionFailure(
            f"Wrong record shape in {path}: {count} values is not divisible by {catchment_count} catchments"
        )
    records = count // catchment_count
    if records != shape["timestep_count"]:
        raise RegressionFailure(
            f"Wrong record count in {path}: expected {shape['timestep_count']}, got {records}"
        )


def compare_files(
    expected_path: Path,
    actual_path: Path,
    entry: dict[str, Any],
    shape: dict[str, Any],
) -> dict[str, Any]:
    dtype = entry.get("dtype")
    if dtype not in DTYPES:
        raise RegressionFailure(f"Unsupported dtype in manifest: {dtype}")

    expected_values = read_values(expected_path, dtype)
    actual_values = read_values(actual_path, dtype)
    if len(expected_values) != len(actual_values):
        raise RegressionFailure(
            f"Value count mismatch for {expected_path.name}: expected {len(expected_values)}, "
            f"got {len(actual_values)}"
        )

    empty_expected = entry.get("empty_expected") is True
    _check_shape(expected_path, expected_values, shape, empty_expected)
    _check_shape(actual_path, actual_values, shape, empty_expected)

    try:
        atol = float(entry["atol"])
        rtol = float(entry["rtol"])
    except (KeyError, TypeError, ValueError) as exc:
        raise RegressionFailure(f"Invalid tolerances for {expected_path.name}: {exc}") from exc
    if not math.isfinite(atol) or not math.isfinite(rtol) or atol < 0 or rtol < 0:
        raise RegressionFailure(f"Tolerances for {expected_path.name} must be finite and non-negative")

    count = len(expected_values)
    result: dict[str, Any] = {
        "dtype": dtype,
        "count": count,
        "atol": atol,
        "rtol": rtol,
        "unit": entry.get("unit", ""),
        "expected_values": expected_values,
        "actual_values": actual_values,
        "catchment_count": shape["catchment_count"],
        "timestep_count": shape["timestep_count"],
        "empty_expected": empty_expected,
    }
    if count == 0:
        result.update({
            "p99_abs": 0.0,
            "max_abs": 0.0,
            "max_abs_location": None,
            "p99_rel": 0.0,
            "max_rel": 0.0,
            "max_rel_location": None,
            "outside_tolerance": 0,
            "passed": True,
        })
        return result

    for path, values in ((expected_path, expected_values), (actual_path, actual_values)):
        for index, value in enumerate(values):
            if not math.isfinite(value):
                location = format_location(index, shape)
                raise RegressionFailure(
                    f"Non-finite value in {path} at flat index {index} "
                    f"(timestep {location['timestep']}, date {location['date']}, "
                    f"catchment {location['catchment']})"
                )

    absolute_errors: list[float] = []
    relative_errors: list[float] = []
    max_abs = max_rel = 0.0
    max_abs_index = max_rel_index = 0
    outside_tolerance = 0
    for index, (expected_value, actual_value) in enumerate(zip(expected_values, actual_values)):
        abs_error = abs(actual_value - expected_value)
        rel_error = abs_error / max(abs(expected_value), abs(actual_value), 1.0e-30)
        absolute_errors.append(abs_error)
        relative_errors.append(rel_error)
        if abs_error > max_abs:
            max_abs, max_abs_index = abs_error, index
        if rel_error > max_rel:
            max_rel, max_rel_index = rel_error, index
        if abs_error > atol or rel_error > rtol:
            outside_tolerance += 1

    result.update({
        "p99_abs": linear_percentile(absolute_errors, 0.99),
        "max_abs": max_abs,
        "max_abs_location": format_location(max_abs_index, shape),
        "p99_rel": linear_percentile(relative_errors, 0.99),
        "max_rel": max_rel,
        "max_rel_location": format_location(max_rel_index, shape),
        "outside_tolerance": outside_tolerance,
        "passed": outside_tolerance == 0,
    })
    return result


def _format_location(location: dict[str, Any] | None) -> str:
    if location is None:
        return "n/a"
    return (
        f"index={location['index']} timestep={location['timestep']} "
        f"date={location['date']} catchment={location['catchment']}"
    )


def _print_result(path: str, result: dict[str, Any]) -> None:
    if result["count"] == 0:
        print(f"{path}: dtype={result['dtype']} count=0 empty expected product PASS")
        return
    print(
        f"{path}: dtype={result['dtype']} count={result['count']} "
        f"p99_abs={result['p99_abs']:.8e} max_abs={result['max_abs']:.8e} "
        f"max_abs_at=({_format_location(result['max_abs_location'])}) "
        f"p99_rel={result['p99_rel']:.8e} max_rel={result['max_rel']:.8e} "
        f"max_rel_at=({_format_location(result['max_rel_location'])}) "
        f"atol={result['atol']:.8e} rtol={result['rtol']:.8e} "
        f"outside_tolerance={result['outside_tolerance']} "
        f"{'PASS' if result['passed'] else 'FAIL'}"
    )


def compare_manifest(
    manifest_path: Path,
    expected_dir: Path,
    actual_dir: Path,
    config_path: Path | None = None,
) -> dict[str, dict[str, Any]]:
    manifest = load_manifest(manifest_path)
    shape = case_shape(manifest, config_path or effective_config_path(manifest_path, manifest))
    results: dict[str, dict[str, Any]] = {}
    errors: list[str] = []

    for relative_path in manifest.get("required_outputs", []):
        required_path = actual_dir / relative_path
        if not required_path.is_file():
            errors.append(f"Required output is missing: {required_path}")

    for entry in manifest.get("comparisons", []):
        relative_path = entry["path"]
        try:
            result = compare_files(expected_dir / relative_path, actual_dir / relative_path, entry, shape)
        except RegressionFailure as exc:
            errors.append(str(exc))
            continue

        results[relative_path] = result
        if not result["passed"]:
            errors.append(
                f"Tolerance exceeded for {relative_path}: {result['outside_tolerance']} values exceeded "
                "atol or rtol"
            )

    _print_results(results)
    if errors:
        raise RegressionFailure("\n".join(errors), results=results, errors=errors)
    return results


def _print_results(results: dict[str, dict[str, Any]]) -> None:
    print("Regression comparison results:")
    print(f"{'output':<30} {'max_abs':>12} {'max_rel':>12} {'outside':>8} {'atol/rtol':>19} result")
    for path, result in results.items():
        tolerance = f"{result['atol']:.3g}/{result['rtol']:.3g}"
        print(
            f"{path:<30} {result['max_abs']:>12.4e} {result['max_rel']:>12.4e} "
            f"{result['outside_tolerance']:>8} {tolerance:>19} "
            f"{'PASS' if result['passed'] else 'FAIL'}"
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
