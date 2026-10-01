# Explicit numerical kinds and removal of rounding VOLATILE

## Scope

This task follows [regression diagnostics](regression-diagnostics.md). Use its Magdalena output comparison and reporting code for the measurements below. The source change removes the rounding-related `VOLATILE` declarations and gives every numerical variable an explicit kind from `iso_fortran_env`. Preserve each variable's current storage width: use `real32` and `real64` in place of default `real`, `real(4)`, `real(8)`, and `real*8`, and `int32` for default integers on the validated builds. Update affected constants and procedure interfaces so the code builds without compiler-wide default-kind flags. Preserve input, output, and hotstart record formats.

The current `VOLATILE` sites are in `src/hydrology/catchment.f90` and `src/hydrology/river_inertial.f90`. They are used as a rounding workaround. Remove them; retain a site only if it has an actual asynchronous writer and document that writer. Do not substitute `-fp-model=precise` or another global rounding workaround.

## Three implementations to measure

Use the same Magdalena inputs, output mapping, host, compiler, release flags, and OpenMP thread count for each applicable run:

1. **Legacy:** pin a revision before the source reorganization in `a14415a` and record its commit. Map its output filenames and layout to the current Magdalena products before comparing values.
2. **Current volatile:** pin the unmodified revision immediately before this change and record its commit. This is the existing `VOLATILE` workaround.
3. **Explicit kinds:** the changed revision, with `VOLATILE` removed and `iso_fortran_env` kinds in source.

Build each revision in a separate directory. Run both Magdalena routing cases where the revision supports them. Keep runs and output files separate; do not alter expected fixtures to make comparisons pass.

## Report

After the regression diagnostics task supplies reusable comparison statistics, publish one report with:

- Exact revision, OS, compiler version, CMake command and flags, fixture version, thread count, and timing method for each run.
- Elapsed time per routing case for each implementation, using repeated runs and reporting the median and range.
- For each compared output, pairwise numerical comparisons among legacy, current volatile, and explicit kinds: value count, maximum and p99 absolute and relative differences, number of changed values, and the timestep/catchment of the maximum difference. Include the historical expected output as a reference when available.
- Regression pass/fail for the explicit-kinds build, with any changed trajectory or unsupported legacy comparison stated plainly.

The report measures numerical drift and runtime; it does not assign scientific acceptability to a changed trajectory. Keep a baseline update separate from this source change and require scientific review before accepting it.

## Validation

Build and run both `regression_magdalena_inertial` and `regression_magdalena_muskingum` on available validated Linux `ifx` and GNU Fortran 13.3 environments, following `docs/development/build.md`. Run the source checks in `docs/development/testing.md`. Record Windows `ifx` results only when that environment is run. The change is ready for review when all numerical declarations use explicit standard kinds, rounding-only `VOLATILE` is gone, builds and regressions run, and the three-way report is attached.
