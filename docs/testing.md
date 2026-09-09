# Testing

The regression suite covers both routing branches with the Magdalena fixture.

## Layout

- Fixture and manifest: `tests/regression/magdalena/`
- Muskingum-Cunge manifest and configuration override:
  `tests/regression/magdalena_muskingum/`
- Regression runner: `tests/regression/run_regression.py`
- Regression comparator: `tests/regression/compare_regression.py`

## Windows

```powershell
ctest --test-dir build/windows -C Release --output-on-failure -R regression_magdalena
```

```powershell
python tests/regression/run_regression.py --case-dir tests/regression/magdalena --exe build/windows/Release/mgb_model.exe --work-dir C:\mgbmagtest
```

## Linux

```bash
ctest --test-dir build/linux --output-on-failure -R regression_magdalena
```

```bash
python tests/regression/run_regression.py --case-dir tests/regression/magdalena --exe build/linux/mgb_model --work-dir /tmp/mgbmagtest
```

## Runtime Staging Behavior

For each run, the regression harness:

1. creates a runtime directory
2. copies the manifest's input directory to `<runtime>/input` and applies any
   case-specific input overrides
3. creates `<runtime>/output`
4. runs the model with `cwd=<runtime>` and `MGB_NONINTERACTIVE=1`
5. compares selected outputs against `tests/regression/magdalena/expected`

## Temp Output Handling

- If `--work-dir` is provided, that directory is recreated and preserved after the run.
- If no `--work-dir` is provided:
  - successful runs clean up the temp directory
  - failed runs preserve the temp directory and print its path

## Current Regression Gate

Compared outputs:

- `discharge.bin`
- `level.bin`
- `total_water_storage.bin`
- `flooded_area.bin`

Current manifest tolerances:

- `atol = 1.0`
- `rtol = 1e2`

The `magdalena_muskingum` case selects routing mode 0 and compares runoff and
total-water-storage records. It exists to execute the Muskingum-Cunge network
path as part of every supported regression run.

## Architecture gate

Run the dependency and explicit-interface policy check without a compiler:

```bash
python scripts/check_fortran_architecture.py
python -m unittest discover -s tests/architecture
```

## Formatting and documentation gates

The development dependency pins `fprettify==0.3.7`. Run the formatter
twice and require the second run to produce no source diff:

~~~bash
python -m pip install -r requirements-dev.txt
fprettify --recursive --config-file .fprettify.rc src
fprettify --recursive --config-file .fprettify.rc src
python scripts/check_fortran_format.py
python scripts/check_fortran_architecture.py
git diff --check
python -m mkdocs build --strict
~~~
