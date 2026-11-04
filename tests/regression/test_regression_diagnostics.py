from __future__ import annotations

import array
import contextlib
import io
import json
import sys
import tempfile
import unittest
from datetime import datetime, timedelta
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

from compare_regression import (
    RegressionFailure,
    case_shape,
    compare_files,
    compare_manifest,
    effective_config_path,
    load_manifest,
)
from report_regression import select_catchments, validate_thresholds
from run_regression import run_case


ROOT = Path(__file__).resolve().parents[2]


def write_float32(path: Path, values: list[float]) -> None:
    encoded = array.array("f", values)
    if sys.byteorder != "little":
        encoded.byteswap()
    path.write_bytes(encoded.tobytes())


def shape_for(catchment_count: int = 2, timestep_count: int = 2) -> dict:
    start = datetime(2000, 1, 1)
    return {
        "catchment_count": catchment_count,
        "simulation_start": start,
        "simulation_end": start + timedelta(days=timestep_count - 1),
        "timestep_seconds": 86400,
        "timestep_count": timestep_count,
    }


def config_text(catchment_count: int = 2, timestep_seconds: int = 86400) -> str:
    return f"&model\n catchment_count = {catchment_count}\n model_timestep = {timestep_seconds}.0\n&end\n"


class RegressionDiagnosticsTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.expected = self.root / "expected.bin"
        self.actual = self.root / "actual.bin"

    def tearDown(self) -> None:
        self.temp.cleanup()

    def compare(
        self,
        expected: list[float],
        actual: list[float],
        *,
        atol: float = 1000.0,
        rtol: float = 1000.0,
        record_shape: dict | None = None,
    ):
        write_float32(self.expected, expected)
        write_float32(self.actual, actual)
        return compare_files(
            self.expected,
            self.actual,
            {"dtype": "float32", "atol": atol, "rtol": rtol},
            record_shape or shape_for(),
        )

    def test_equal_values_and_independent_maximum_locations(self) -> None:
        result = self.compare([0.1, 1000.0, 0.1, 1000.0], [0.0, 999.0, 0.1, 1000.0])
        self.assertEqual(result["max_abs_location"]["index"], 1)
        self.assertEqual(result["max_rel_location"]["index"], 0)
        self.assertEqual(result["max_abs_location"]["catchment"], 2)
        self.assertEqual(result["max_abs_location"]["timestep"], 1)
        self.assertEqual(result["outside_tolerance"], 0)

        equal = self.compare([1.0, 2.0, 3.0, 4.0], [1.0, 2.0, 3.0, 4.0])
        self.assertEqual(equal["max_abs"], 0.0)
        self.assertEqual(equal["max_rel"], 0.0)

    def test_p99_uses_linear_interpolation(self) -> None:
        values = list(map(float, range(100)))
        result = self.compare([0.0] * 100, values, record_shape=shape_for(100, 1))
        self.assertAlmostEqual(result["p99_abs"], 98.01, places=5)

    def test_absolute_and_relative_limits_apply_independently(self) -> None:
        one_timestep = shape_for(timestep_count=1)

        abs_boundary = self.compare([100.0, 100.0], [101.0, 100.0], atol=1.0, rtol=0.1, record_shape=one_timestep)
        self.assertTrue(abs_boundary["passed"])

        rel_boundary = self.compare([9.0, 9.0], [10.0, 9.0], atol=2.0, rtol=0.1, record_shape=one_timestep)
        self.assertAlmostEqual(rel_boundary["max_rel"], 0.1, places=6)
        self.assertTrue(rel_boundary["passed"])

        abs_failure = self.compare([100.0, 100.0], [101.5, 100.0], atol=1.0, rtol=0.1, record_shape=one_timestep)
        self.assertEqual(abs_failure["outside_tolerance"], 1)
        self.assertFalse(abs_failure["passed"])

        rel_failure = self.compare([0.25, 0.25], [0.5, 0.25], atol=1.0, rtol=0.1, record_shape=one_timestep)
        self.assertEqual(rel_failure["outside_tolerance"], 1)
        self.assertFalse(rel_failure["passed"])

        near_zero = self.compare([0.0, 0.0], [1.0e-20, 0.0], atol=1.0, rtol=0.1, record_shape=one_timestep)
        self.assertEqual(near_zero["outside_tolerance"], 1)
        self.assertFalse(near_zero["passed"])
        self.assertAlmostEqual(near_zero["max_rel"], 1.0)

    def test_empty_product_requires_manifest_declaration(self) -> None:
        self.expected.write_bytes(b"")
        self.actual.write_bytes(b"")
        with self.assertRaisesRegex(RegressionFailure, "not declared"):
            compare_files(self.expected, self.actual, {"dtype": "float32", "atol": 0, "rtol": 0}, shape_for())
        result = compare_files(
            self.expected,
            self.actual,
            {"dtype": "float32", "atol": 0, "rtol": 0, "empty_expected": True},
            shape_for(),
        )
        self.assertEqual(result["count"], 0)

    def test_file_and_shape_errors(self) -> None:
        self.expected.write_bytes(b"\0\0\0")
        self.actual.write_bytes(b"")
        with self.assertRaisesRegex(RegressionFailure, "Malformed byte length"):
            compare_files(self.expected, self.actual, {"dtype": "float32"}, shape_for())

        write_float32(self.expected, [1.0, 2.0, 3.0, 4.0])
        write_float32(self.actual, [1.0, 2.0])
        with self.assertRaisesRegex(RegressionFailure, "Value count mismatch"):
            compare_files(self.expected, self.actual, {"dtype": "float32"}, shape_for())

        write_float32(self.expected, [1.0, 2.0, 3.0])
        write_float32(self.actual, [1.0, 2.0, 3.0])
        with self.assertRaisesRegex(RegressionFailure, "not divisible"):
            compare_files(self.expected, self.actual, {"dtype": "float32"}, shape_for())

        write_float32(self.expected, [1.0, 2.0])
        write_float32(self.actual, [1.0, 2.0])
        with self.assertRaisesRegex(RegressionFailure, "expected 2, got 1"):
            compare_files(self.expected, self.actual, {"dtype": "float32"}, shape_for())

        with self.assertRaisesRegex(RegressionFailure, "Unsupported dtype"):
            compare_files(self.expected, self.actual, {"dtype": "float64"}, shape_for())

        self.expected.unlink()
        with self.assertRaisesRegex(RegressionFailure, "Missing file"):
            compare_files(self.expected, self.actual, {"dtype": "float32"}, shape_for())

    def test_non_finite_values_name_file_and_location(self) -> None:
        write_float32(self.expected, [1.0, float("nan"), 3.0, 4.0])
        write_float32(self.actual, [1.0, 2.0, 3.0, 4.0])
        with self.assertRaisesRegex(RegressionFailure, r"expected.bin.*index 1.*catchment 2"):
            compare_files(self.expected, self.actual, {"dtype": "float32", "atol": 0, "rtol": 0}, shape_for())

        write_float32(self.expected, [1.0, 2.0, 3.0, 4.0])
        write_float32(self.actual, [1.0, float("inf"), 3.0, 4.0])
        with self.assertRaisesRegex(RegressionFailure, r"Non-finite.*actual.bin"):
            compare_files(self.expected, self.actual, {"dtype": "float32", "atol": 0, "rtol": 0}, shape_for())

    def test_both_fixtures_read_effective_config_shape(self) -> None:
        for case_name in ("magdalena_inertial", "magdalena_muskingum"):
            manifest_path = ROOT / "tests/regression" / case_name / "manifest.json"
            manifest = load_manifest(manifest_path)
            self.assertNotIn("catchment_count", manifest)
            self.assertNotIn("timestep_seconds", manifest)
            config_path = effective_config_path(manifest_path, manifest)
            parsed = case_shape(manifest, config_path)
            self.assertEqual((parsed["catchment_count"], parsed["timestep_seconds"]), (458, 86400))
            self.assertEqual(parsed["timestep_count"], 1314)
        self.assertEqual(config_path, ROOT / "tests/regression/magdalena_muskingum/config.nml")

    def test_case_period_must_align_with_config_step(self) -> None:
        config_path = self.root / "config.nml"
        config_path.write_text(config_text(), encoding="utf-8")
        with self.assertRaisesRegex(RegressionFailure, "align with timestep"):
            case_shape({
                "simulation_start": "2000-01-01T00:00:00",
                "simulation_end": "2000-01-02T01:00:00",
            }, config_path)

    def test_manifest_prints_compact_results_table(self) -> None:
        expected_dir = self.root / "manifest_expected"
        actual_dir = self.root / "manifest_actual"
        input_dir = self.root / "input"
        expected_dir.mkdir()
        actual_dir.mkdir()
        input_dir.mkdir()
        (input_dir / "config.nml").write_text(config_text(), encoding="utf-8")
        write_float32(expected_dir / "output.bin", [1.0, 2.0, 3.0, 4.0])
        write_float32(actual_dir / "output.bin", [1.0, 2.0, 3.0, 4.0])
        manifest = {
            "input_dir": "input",
            "simulation_start": "2000-01-01T00:00:00",
            "simulation_end": "2000-01-02T00:00:00",
            "comparisons": [{"path": "output.bin", "dtype": "float32", "atol": 0.01, "rtol": 1}],
        }
        manifest_path = self.root / "manifest.json"
        manifest_path.write_text(json.dumps(manifest), encoding="utf-8")
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            compare_manifest(manifest_path, expected_dir, actual_dir)
        self.assertIn("Regression comparison results:", output.getvalue())
        self.assertIn("max_abs", output.getvalue())
        self.assertIn("atol/rtol", output.getvalue())
        self.assertIn("PASS", output.getvalue())
        self.assertNotIn("p99_abs", output.getvalue())


class ReportSelectionTests(unittest.TestCase):
    def test_thresholds_select_abs_or_relative_error_at_equality(self) -> None:
        selected = select_catchments(
            [1.0, 1.0, 0.0, 0.0],
            [1.125, -1.0, 0.0, 0.0625],
            4,
            threshold_abs=0.125,
            threshold_rel=1.0,
        )
        self.assertEqual(selected, [2, 1, 4])

    def test_thresholds_are_per_output(self) -> None:
        expected = [1.0, 1.0, 0.0, 0.0]
        changed = [1.125, -1.0, 0.0, 0.0625]
        unchanged = [1.0, 1.0, 0.0, 0.0]
        self.assertEqual(select_catchments(expected, changed, 4, 0.125, 1.0), [2, 1, 4])
        self.assertEqual(select_catchments(expected, unchanged, 4, 0.125, 1.0), [])

    def test_values_below_both_thresholds_are_skipped(self) -> None:
        self.assertEqual(select_catchments([1.0, 0.0], [1.001, 0.0], 2, 0.01, 1.0), [])

    def test_invalid_thresholds_are_rejected(self) -> None:
        with self.assertRaisesRegex(ValueError, "finite and non-negative"):
            validate_thresholds(float("nan"), 1.0)
        with self.assertRaisesRegex(ValueError, "finite and non-negative"):
            validate_thresholds(0.01, -1.0)


class RunnerDiagnosticsTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.case_dir = self.root / "case"
        (self.case_dir / "input").mkdir(parents=True)
        expected_dir = self.case_dir / "expected"
        expected_dir.mkdir()
        write_float32(expected_dir / "output.bin", [1.0, 2.0, 3.0, 4.0])
        (expected_dir / "model.log").write_text("model output", encoding="utf-8")
        (self.case_dir / "input" / "config.nml").write_text(config_text(), encoding="utf-8")
        manifest = {
            "case_name": "tiny",
            "input_dir": "input",
            "expected_dir": "expected",
            "required_outputs": ["model.log"],
            "simulation_start": "2000-01-01T00:00:00",
            "simulation_end": "2000-01-02T00:00:00",
            "comparisons": [{"path": "output.bin", "dtype": "float32", "atol": 0, "rtol": 0}],
        }
        (self.case_dir / "manifest.json").write_text(json.dumps(manifest), encoding="utf-8")

    def tearDown(self) -> None:
        self.temp.cleanup()

    @staticmethod
    def write_model_outputs(cwd: str, values: list[float], returncode: int = 0) -> SimpleNamespace:
        output_dir = Path(cwd) / "output"
        write_float32(output_dir / "output.bin", values)
        (output_dir / "model.log").write_text("model output", encoding="utf-8")
        return SimpleNamespace(returncode=returncode)

    def test_without_results_dir_cleans_temporary_run_and_skips_report(self) -> None:
        temporary_run = tempfile.TemporaryDirectory(dir=self.root)
        with patch("run_regression.tempfile.TemporaryDirectory", return_value=temporary_run), patch(
            "run_regression.subprocess.run",
            side_effect=lambda command, **kwargs: self.write_model_outputs(kwargs["cwd"], [1, 2, 3, 4]),
        ), patch("run_regression.write_report") as report:
            run_case(self.case_dir, self.root / "mgb_model")
        self.assertFalse(Path(temporary_run.name).exists())
        report.assert_not_called()

    def test_results_dir_recreates_run_artifacts_and_preserves_other_files(self) -> None:
        results_dir = self.root / "results"
        for name in ("input", "output"):
            (results_dir / name).mkdir(parents=True)
            (results_dir / name / "stale").write_text("stale", encoding="utf-8")
        (results_dir / "report.html").write_text("stale", encoding="utf-8")
        (results_dir / "notes.txt").write_text("keep", encoding="utf-8")

        def write_report(directory: Path, *args) -> Path:
            path = directory / "report.html"
            path.write_text("report", encoding="utf-8")
            return path

        with patch(
            "run_regression.subprocess.run",
            side_effect=lambda command, **kwargs: self.write_model_outputs(kwargs["cwd"], [1, 2, 3, 4]),
        ), patch("run_regression.write_report", side_effect=write_report):
            run_case(self.case_dir, self.root / "mgb_model", results_dir)
        self.assertTrue((results_dir / "output" / "output.bin").exists())
        self.assertTrue((results_dir / "input" / "config.nml").exists())
        self.assertEqual((results_dir / "report.html").read_text(encoding="utf-8"), "report")
        self.assertEqual((results_dir / "notes.txt").read_text(encoding="utf-8"), "keep")
        self.assertFalse((results_dir / "output" / "stale").exists())

    def test_comparison_failure_still_writes_report(self) -> None:
        results_dir = self.root / "results"

        def write_report(directory: Path, *args) -> Path:
            path = directory / "report.html"
            path.write_text("failure report", encoding="utf-8")
            return path

        with patch(
            "run_regression.subprocess.run",
            side_effect=lambda command, **kwargs: self.write_model_outputs(kwargs["cwd"], [5, 2, 3, 4]),
        ), patch("run_regression.write_report", side_effect=write_report) as report:
            with self.assertRaises(SystemExit):
                run_case(self.case_dir, self.root / "mgb_model", results_dir)
        report.assert_called_once()
        self.assertTrue((results_dir / "report.html").exists())
        self.assertIn("output.bin", report.call_args.args[3])

    def test_model_failure_does_not_attempt_a_report(self) -> None:
        with patch(
            "run_regression.subprocess.run",
            side_effect=lambda command, **kwargs: SimpleNamespace(returncode=4),
        ), patch("run_regression.write_report") as report:
            with self.assertRaises(SystemExit):
                run_case(self.case_dir, self.root / "mgb_model", self.root / "results")
        report.assert_not_called()


if __name__ == "__main__":
    unittest.main()
