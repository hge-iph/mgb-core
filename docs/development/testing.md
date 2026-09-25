# Testing and debugging

The regression suite covers both routing branches with the Magdalena fixture.
This page describes the test system and its reference commands. Change-specific
checks and pull-request expectations are maintained in
[CONTRIBUTING.md](https://github.com/HGE-IPH/MGB-model/blob/main/CONTRIBUTING.md).

## Test layout

- The inertial fixture and manifest are in
  `tests/regression/magdalena_inertial/`.
- The Muskingum-Cunge manifest and configuration override are in
  `tests/regression/magdalena_muskingum/`.
- The regression runner is `tests/regression/run_regression.py`.
- The regression comparator is `tests/regression/compare_regression.py`.

## Windows x64 with Intel ifx (validated)

The validated Windows Intel build uses `build/ifx` and the multi-configuration
executable under `build/ifx/Release`:

```powershell
ctest --test-dir build/ifx -C Release --output-on-failure -R regression_magdalena_
```

```powershell
python tests/regression/run_regression.py --case-dir tests/regression/magdalena_inertial --exe build/ifx/Release/mgb_model.exe --work-dir C:\mgbmagtest
```

## Linux x64 with Intel ifx (validated)

The validated Linux Intel build uses `build/ifx`:

```bash
ctest --test-dir build/ifx --output-on-failure -R regression_magdalena_
python tests/regression/run_regression.py --case-dir tests/regression/magdalena_inertial --exe build/ifx/mgb_model --work-dir /tmp/mgbmagtest
```

## Linux x64 with GNU Fortran 13.3 (validated)

The validated Linux GNU build uses `build/gfortran`:

```bash
ctest --test-dir build/gfortran --output-on-failure -R regression_magdalena_
python tests/regression/run_regression.py --case-dir tests/regression/magdalena_inertial --exe build/gfortran/mgb_model --work-dir /tmp/mgbmagtest
```

## Windows x64 with GNU Fortran (experimental, unvalidated)

The experimental MSYS2 UCRT64 workflow uses the single-configuration
executable in `build/gfortran`:

```bash
ctest --test-dir build/gfortran --output-on-failure -R regression_magdalena_
python tests/regression/run_regression.py --case-dir tests/regression/magdalena_inertial --exe build/gfortran/mgb_model.exe --work-dir /tmp/mgbmagtest
```

## Runtime staging behavior

For each run, the regression harness performs this sequence:

1. The harness creates a runtime directory.
2. It copies the manifest input directory to `<runtime>/input` and applies any
   case-specific input overrides.
3. It creates `<runtime>/output`.
4. It runs the model with `cwd=<runtime>` and `MGB_NONINTERACTIVE=1`.
5. It compares selected outputs with the case's `expected` directory.

## Temporary output handling

The failure-investigation section below describes how `--work-dir` preserves
staged inputs and outputs for inspection. Without that option, successful runs
clean up their temporary directory while failed runs preserve it and print its
path.

## Output comparisons and tolerances

The compared outputs are:

- `discharge.bin`
- `level.bin`
- `total_water_storage.bin`
- `flooded_area.bin`

The current manifest tolerances are `atol = 1.0` and `rtol = 1e2`.

The inertial fixture requests two OpenMP threads, so regression builds execute
the existing parallel routing regions and verify the linked OpenMP runtime.
The `magdalena_muskingum` case selects routing mode 0 and compares discharge,
runoff, and total-water-storage records. It executes the Muskingum-Cunge
network path in every supported regression run.

## Source and architecture checks

The formatting checker, architecture policy checker, and focused architecture
tests run without a compiler:

```bash
python3 scripts/check_fortran_format.py
python3 scripts/check_fortran_architecture.py
python3 -m unittest discover -s tests/architecture
```

## Documentation checks

MkDocs builds the documentation in strict mode:

```bash
python3 -m mkdocs build --strict
```

The [Coding conventions](coding-conventions.md) guide describes the formatter
and its pinned dependency. The contribution guide combines these checks with
change-specific validation guidance.

## Compiler diagnostics

`ENABLE_FORTRAN_DIAGNOSTICS=ON` enables compiler warning output for cleanup
work. Apply the option to the compiler-named build tree being diagnosed.
Initialize oneAPI first when `ifx` is unavailable.

Linux Intel:

```bash
FC=ifx cmake -S . -B build/ifx -DCMAKE_BUILD_TYPE=Release -DENABLE_FORTRAN_DIAGNOSTICS=ON
cmake --build build/ifx
```

Windows Intel command prompt:

```cmd
set "FC=ifx"
cmake -S . -B build/ifx -DENABLE_FORTRAN_DIAGNOSTICS=ON
cmake --build build/ifx --config Release
```

GNU Fortran uses the same option with the `build/gfortran` configuration
command.

## Investigating regression failures

Pass `--work-dir` to the regression runner when staged inputs and outputs need
inspection. The supplied directory is recreated and preserved after the run.
Without that option, successful runs remove their temporary directory while
failed runs preserve it and print its path.

The regression harness uses `MGB_NONINTERACTIVE=1`, so console prompts do not
interrupt diagnostic runs. Inspect `model.log` and the preserved `output/`
directory in the runtime working directory. The
[Execution and data flow](../architecture/execution-and-data-flow.md) and
[I/O reference](../architecture/io-reference.md) identify the owners and
formats of runtime streams.
