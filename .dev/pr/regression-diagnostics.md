# Regression diagnostics and local hydrograph reports

## Objective and boundary

Make numerical regression failures explainable at the output, catchment, and timestep level. Produce optional local interactive hydrographs and error tables without making plotting a dependency of CTest or CI. This task changes the comparison and reporting tools; it does not decide whether a changed hydrological trajectory is scientifically correct.

## Repository state and evidence

- `tests/regression/compare_regression.py` reads raw little-endian 32-bit floats, rejects files with non-multiple-of-four lengths and NaNs, and prints value count, maximum absolute and relative error, and one index. That index is updated when either maximum grows, so it does not reliably identify both maxima. Infinities are not explicitly rejected.
- `tests/regression/run_regression.py` stages a case into a temporary runtime directory, executes `mgb_model` with `MGB_NONINTERACTIVE=1`, compares selected outputs, deletes successful temporary runs, and preserves failed runs. A caller can supply `--work-dir` to retain files.
- The inertial manifest compares discharge, level, total water storage, and flooded area. The Muskingum manifest compares discharge, runoff, and total water storage. All entries currently specify `float32`, `atol = 1.0`, and `rtol = 100`. Those values are historical controls, not a justified scientific tolerance policy.
- The Magdalena fixture has 458 catchments and 1,314 daily output records, from 1979-01-01 through 1982-08-06. Each compared output contains 601,812 float32 values. `src/io/output_io.f90` writes one direct-access record per timestep in catchment order; flat zero-based index `i` maps to timestep `i // 458 + 1` and catchment `i % 458 + 1`.
- `.github/workflows/regression-gfortran.yml` currently runs on PR opening and reopening and on manual dispatch, but misses later PR pushes.

## Comparison interface and behavior

1. Keep the manifest as the authority for compared paths, dtype, and tolerances. Allow the same comparison code to compare any two output directories so the [numerical precision task](numerical-precision.md) can report legacy, volatile, and explicit-kind runs pairwise. Add explicit catchment count, simulation start, and timestep seconds to case metadata; reject a file whose value count does not divide into the declared shape or whose record count disagrees with the case period. Keep historical float32 decoding available when a future output format is introduced.
2. Compute measurement data independently of acceptance: dtype, count, p99 absolute error, maximum absolute error and location, p99 relative error, maximum relative error and location, and number of values outside tolerance. Use relative error `abs(actual-expected) / max(abs(expected), abs(actual), 1e-30)`. Define p99 by linear interpolation at sorted zero-based position `0.99 * (n - 1)`. Report both zero-based flat index and one-based timestep/catchment.
3. Reject NaN or infinity in either file with the file name and first location. Reject missing files, unequal lengths, malformed byte lengths, unsupported dtype, and inconsistent shape before computing statistics. Empty files are valid only when the manifest explicitly declares them as empty expected products; they are not silently treated as zero-length time series.
4. Use an elementwise acceptance rule `abs(actual-expected) <= atol + rtol * abs(expected)`. Print configured `atol` and `rtol` beside measurements. Preserve the historical manifest values during the reporting change; replace them with tighter per-output values only after numerical and scientific review. Tests must lock the rule, including near-zero expected values.
5. Add optional `--report-dir PATH` and repeatable `--catchment ID` options to the runner. When requested, produce an HTML report with a per-output statistics table and expected-versus-actual hydrographs plus residual traces. Rank catchments by their maximum absolute error for each output and include the ten worst, then add explicitly requested IDs without duplicates. Report the ranking rule and selected IDs in the page.
6. Generate reports from comparison data before successful temporary work is deleted and also when comparison fails. A model process that exits before producing readable outputs must still yield its ordinary failure message; the report generator must not mask it. Use Plotly through a pinned optional `requirements-report.txt` and embed its JavaScript in the generated HTML so the report works without a network connection. Normal CTest and CI must not install the plotting requirement.
7. Update testing documentation with the percentile, relative-error, pass/fail, data ordering, report command, and the fact that error statistics measure drift rather than establish scientific correctness. Trigger GNU CI on PR `synchronize` as well as `opened` and `reopened`.

## Validation commands

```bash
python3 -m unittest discover -s tests/regression
FC=gfortran cmake -S . -B build/gfortran -DCMAKE_BUILD_TYPE=Release
cmake --build build/gfortran
ctest --test-dir build/gfortran --output-on-failure -R regression_magdalena_
python3 tests/regression/run_regression.py \
  --case-dir tests/regression/magdalena_inertial \
  --exe build/gfortran/mgb_model \
  --work-dir /tmp/mgb-regression-report \
  --report-dir /tmp/mgb-regression-report-html
```

Run the equivalent CTest command with `build/ifx` on Linux and `-C Release` on Windows when those validated environments are available. Generate one report from a deliberately mismatched synthetic output and one from each real routing case. Open the HTML locally and verify dates, units where documented, selected catchments, hover values, and table entries against the console output.

## Focused tests and acceptance gates

- Synthetic arrays cover exact equality, a single outlier, near-zero expected values, values exactly on each tolerance boundary, independent maxima at different indices, and known p99 interpolation.
- File tests cover missing outputs, unequal byte lengths, non-multiple-of-four lengths, NaN, infinity, wrong record shape, and unsupported dtype.
- Report tests cover worst-ten ranking, explicit catchment inclusion, invalid IDs, no duplicate plots, successful-run cleanup, and report generation after a comparison failure.
- The report is optional, locally usable, and absent from normal CTest dependency installation. Both routing regressions still run in CI, and a push to an open PR triggers them.
