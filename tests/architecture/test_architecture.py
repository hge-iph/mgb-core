from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path


sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "scripts"))
from check_fortran_architecture import check_tree  # noqa: E402


class ArchitectureCheckerTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.src = Path(self.temporary_directory.name) / "src"
        self.write("application/main.f90", "program mgb_model\nimplicit none\nend program\n")

    def tearDown(self) -> None:
        self.temporary_directory.cleanup()

    def write(self, relative: str, text: str) -> None:
        path = self.src / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")

    @staticmethod
    def module(name: str, body: str = "") -> str:
        return f"module {name}\nimplicit none\nprivate\npublic :: value\ninteger :: value\n{body}\nend module\n"

    def test_mixed_case_keywords_and_names(self) -> None:
        self.write("common/date_time.f90", self.module("DaTe_TiMe").replace("module", "MoDuLe"))
        self.assertEqual([], check_tree(self.src))

    def test_continued_use_only_is_accepted(self) -> None:
        self.write("catchment/catchment_state.f90", self.module("catchment_state"))
        body = "use catchment_state, only: &\n  value\n"
        self.write("io/configuration_io.f90", self.module("configuration_io", body))
        self.assertEqual([], check_tree(self.src))

    def test_intrinsic_and_compiler_modules_are_external(self) -> None:
        body = "use, intrinsic :: iso_fortran_env, only: real64\nuse omp_lib\n"
        self.write("routing/inertial/inertial_state.f90", self.module("inertial_state", body))
        self.assertEqual([], check_tree(self.src))

    def test_permitted_state_dependency(self) -> None:
        self.write("catchment/catchment_state.f90", self.module("catchment_state"))
        body = "use catchment_state, only: value\n"
        self.write("reservoirs/reservoir_state.f90", self.module("reservoir_state", body))
        self.assertEqual([], check_tree(self.src))

    def test_forbidden_facade_dependency(self) -> None:
        self.write("catchment/catchment_hydrology.f90", self.module("catchment_hydrology"))
        body = "use catchment_hydrology, only: value\n"
        self.write("routing/inertial/inertial_routing.f90", self.module("inertial_routing", body))
        self.assertTrue(any("forbidden dependency" in error for error in check_tree(self.src)))

    def test_unrestricted_project_use(self) -> None:
        self.write("catchment/catchment_state.f90", self.module("catchment_state"))
        self.write("io/configuration_io.f90", self.module("configuration_io", "use catchment_state\n"))
        self.assertTrue(any("requires an only list" in error for error in check_tree(self.src)))

    def test_missing_default_private(self) -> None:
        text = self.module("date_time").replace("private\n", "")
        self.write("common/date_time.f90", text)
        self.assertTrue(any("default private" in error for error in check_tree(self.src)))

    def test_external_procedure(self) -> None:
        self.write("common/orphan.f90", "subroutine orphan\nimplicit none\nend subroutine\n")
        self.assertTrue(any("external project procedure" in error for error in check_tree(self.src)))

    def test_external_procedure_after_module(self) -> None:
        text = self.module("date_time") + "subroutine orphan\nimplicit none\nend subroutine\n"
        self.write("common/date_time.f90", text)
        self.assertTrue(any("external project procedure" in error for error in check_tree(self.src)))


if __name__ == "__main__":
    unittest.main()
