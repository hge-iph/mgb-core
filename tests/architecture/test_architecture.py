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
    def behavior_module(name: str, body: str = "") -> str:
        return f"module {name}\nimplicit none\nprivate\npublic :: value\ninteger :: value\n{body}\nend module\n"

    @staticmethod
    def vars_module(name: str, body: str = "integer :: value") -> str:
        return f"module {name}\nimplicit none\nsave\n{body}\nend module\n"

    def test_mixed_case_keywords_and_names(self) -> None:
        module = self.behavior_module("DaTe_TiMe").replace("module", "MoDuLe")
        self.write("common/date_time.f90", module)
        self.assertEqual([], check_tree(self.src))

    def test_all_vars_modules_are_accepted(self) -> None:
        for name in ("attributes", "config", "forcing", "parameters", "state"):
            self.write(f"vars/{name}.f90", self.vars_module(name))
        self.assertEqual([], check_tree(self.src))

    def test_all_hydrology_modules_are_accepted(self) -> None:
        for name in ("catchment", "river_muskingum", "river_inertial", "reservoirs"):
            self.write(f"hydrology/{name}.f90", self.behavior_module(name))
        self.assertEqual([], check_tree(self.src))

    def test_continued_use_only_is_accepted(self) -> None:
        self.write("vars/state.f90", self.vars_module("state"))
        body = "use state, only: &\n  value\n"
        self.write("io/configuration_io.f90", self.behavior_module("configuration_io", body))
        self.assertEqual([], check_tree(self.src))

    def test_intrinsic_and_compiler_modules_are_external(self) -> None:
        body = "use, intrinsic :: iso_fortran_env, only: real64\nuse omp_lib\n"
        self.write("hydrology/river_inertial.f90", self.behavior_module("river_inertial", body))
        self.assertEqual([], check_tree(self.src))

    def test_hydrology_may_use_vars(self) -> None:
        self.write("vars/parameters.f90", self.vars_module("parameters"))
        body = "use parameters, only: value\n"
        self.write("hydrology/catchment.f90", self.behavior_module("catchment", body))
        self.assertEqual([], check_tree(self.src))

    def test_hydrology_may_not_call_another_hydrology_module(self) -> None:
        self.write("hydrology/catchment.f90", self.behavior_module("catchment"))
        body = "use catchment, only: value\n"
        self.write("hydrology/river_inertial.f90", self.behavior_module("river_inertial", body))
        self.assertTrue(any("forbidden dependency" in error for error in check_tree(self.src)))

    def test_application_approved_dependencies_are_accepted(self) -> None:
        for name in ("attributes", "config", "forcing", "parameters", "state"):
            self.write(f"vars/{name}.f90", self.vars_module(name))
        self.write("io/configuration_io.f90", self.behavior_module("configuration_io"))
        self.write("io/log_io.f90", self.behavior_module("log_io"))
        self.write("simulation/simulation_runner.f90", self.behavior_module("simulation_runner"))
        self.write(
            "application/main.f90",
            "program mgb_model\n"
            "use attributes, only: value\n"
            "use config, only: value\n"
            "use forcing, only: value\n"
            "use parameters, only: value\n"
            "use state, only: value\n"
            "use configuration_io, only: value\n"
            "use log_io, only: value\n"
            "use simulation_runner, only: value\n"
            "implicit none\n"
            "end program\n",
        )
        self.assertEqual([], check_tree(self.src))

    def test_application_may_not_depend_on_hydrology(self) -> None:
        self.write("hydrology/catchment.f90", self.behavior_module("catchment"))
        self.write(
            "application/main.f90",
            "program mgb_model\n"
            "use catchment, only: value\n"
            "implicit none\n"
            "end program\n",
        )
        self.assertTrue(any("forbidden dependency application -> catchment" in error
                            for error in check_tree(self.src)))

    def test_application_may_not_depend_on_runtime_io(self) -> None:
        self.write("io/meteorological_io.f90", self.behavior_module("meteorological_io"))
        self.write(
            "application/main.f90",
            "program mgb_model\n"
            "use meteorological_io, only: value\n"
            "implicit none\n"
            "end program\n",
        )
        self.assertTrue(any("forbidden dependency application -> meteorological_io" in error
                            for error in check_tree(self.src)))

    def test_vars_may_not_depend_on_project_modules(self) -> None:
        self.write("common/date_time.f90", self.behavior_module("date_time"))
        body = "use date_time, only: value\ninteger :: stored_value"
        self.write("vars/state.f90", self.vars_module("state", body))
        self.assertTrue(any("forbidden dependency" in error for error in check_tree(self.src)))

    def test_unrestricted_project_use_is_rejected(self) -> None:
        self.write("vars/state.f90", self.vars_module("state"))
        body = self.behavior_module("configuration_io", "use state\n")
        self.write("io/configuration_io.f90", body)
        self.assertTrue(any("requires an only list" in error for error in check_tree(self.src)))

    def test_vars_module_must_be_default_public(self) -> None:
        self.write("vars/state.f90", self.vars_module("state", "private\ninteger :: value"))
        self.assertTrue(any("default public" in error for error in check_tree(self.src)))

    def test_vars_module_may_not_define_named_type(self) -> None:
        body = "type :: model_state\ninteger :: value\nend type model_state"
        self.write("vars/state.f90", self.vars_module("state", body))
        self.assertTrue(any("named types" in error for error in check_tree(self.src)))

    def test_behavior_module_requires_default_private(self) -> None:
        text = self.behavior_module("catchment").replace("private\n", "")
        self.write("hydrology/catchment.f90", text)
        self.assertTrue(any("default private" in error for error in check_tree(self.src)))

    def test_external_procedure(self) -> None:
        self.write("common/orphan.f90", "subroutine orphan\nimplicit none\nend subroutine\n")
        self.assertTrue(any("external project procedure" in error for error in check_tree(self.src)))


if __name__ == "__main__":
    unittest.main()
