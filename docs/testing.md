# Testing

This branch introduces the first regression case: `magdalena`.

## Layout

- Fixture and manifest: `tests/regression/magdalena/`
- Regression runner: `tests/regression/run_regression.py`
- Regression comparator: `tests/regression/compare_regression.py`

## Canonical Test Command

```powershell
ctest --test-dir build/windows -C Release --output-on-failure -R regression_magdalena
```

## Manual Regression Command

```powershell
python tests/regression/run_regression.py --case-dir tests/regression/magdalena --exe build/windows/Release/mgb_model.exe --work-dir C:\mgbmagtest
```

## Runtime Staging Behavior

For each run, the regression harness:

1. creates a runtime directory
2. copies `tests/regression/magdalena/input` to `<runtime>/input`
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

- `qtudo.mgb`
- `ytudo.mgb`
- `twstudo.mgb`
- `floodtudo.mgb`

Current manifest tolerances:

- `atol = 1.0`
- `rtol = 1e2`
