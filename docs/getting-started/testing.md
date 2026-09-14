# Testing

The regression suite covers both routing branches with the Magdalena fixture.
This page explains the test system and how to operate it. The change-specific
checks and pull-request expectations are maintained in
[CONTRIBUTING.md](https://github.com/HGE-IPH/MGB-model/blob/main/CONTRIBUTING.md).

## Layout

- Inertial fixture and manifest: `tests/regression/magdalena_inertial/`
- Muskingum-Cunge manifest and configuration override:
  `tests/regression/magdalena_muskingum/`
- Regression runner: `tests/regression/run_regression.py`
- Regression comparator: `tests/regression/compare_regression.py`

## Windows

```powershell
ctest --test-dir build/windows -C Release --output-on-failure -R regression_magdalena_
```

```powershell
python tests/regression/run_regression.py --case-dir tests/regression/magdalena_inertial --exe build/windows/Release/mgb_model.exe --work-dir C:\mgbmagtest
```

## Linux

Intel build:

```bash
ctest --test-dir build/linux --output-on-failure -R regression_magdalena_
```

GNU Fortran build:

```bash
ctest --test-dir build/linux-gfortran --output-on-failure -R regression_magdalena_
```

```bash
python tests/regression/run_regression.py --case-dir tests/regression/magdalena_inertial --exe build/linux/mgb_model --work-dir /tmp/mgbmagtest
```

## Runtime Staging Behavior

For each run, the regression harness:

1. creates a runtime directory
2. copies the manifest's input directory to `<runtime>/input` and applies any
   case-specific input overrides
3. creates `<runtime>/output`
4. runs the model with `cwd=<runtime>` and `MGB_NONINTERACTIVE=1`
5. compares selected outputs against the case's `expected` directory

## Temp Output Handling

- If `--work-dir` is provided, that directory is recreated and preserved after the run.
- If no `--work-dir` is provided:
  - successful runs clean up the temp directory
  - failed runs preserve the temp directory and print its path

## Compared results and tolerances

Compared outputs:

- `discharge.bin`
- `level.bin`
- `total_water_storage.bin`
- `flooded_area.bin`

Current manifest tolerances:

- `atol = 1.0`
- `rtol = 1e2`

The inertial fixture requests two OpenMP threads so regression builds execute the
existing parallel routing regions rather than only verifying that OpenMP links.

The `magdalena_muskingum` case selects routing mode 0 and compares discharge,
runoff, and total-water-storage records. It exists to execute the
Muskingum-Cunge network path as part of every supported regression run.

## Architecture gate

Run the dependency and explicit-interface policy check without a compiler:

```bash
python scripts/check_fortran_architecture.py
python -m unittest discover -s tests/architecture
```

The [Fortran style guide](../development/fortran-style.md) describes the format
checker and its pinned dependency. Documentation is built with MkDocs in
strict mode. The contribution guide combines these checks into
change-specific validation guidance instead of duplicating that policy here.
