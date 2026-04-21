# Repository Guidelines

## Project Structure & Module Organization

This repository contains the MGB hydrology and hydrodynamics model, currently bootstrapped as a legacy Fortran project. Core model sources live in `src/`; mixed-case extensions are intentional (`.f90` and `.F90`) and are listed explicitly in `CMakeLists.txt`. Build helpers are in `cmake/`, especially `cmake/BootstrapIntelFortran.cmake`. Documentation lives in `docs/`, with `docs/build.md`, `docs/testing.md`, `docs/architecture-bootstrap.md`, and `docs/portability.md` as the main references. Regression tests and fixtures live under `tests/regression/`; the current case is `tests/regression/magdalena/`.

## Build, Test, and Development Commands

Run commands from the repository root. The validated bootstrap environment is Windows x64 with Intel oneAPI `ifx`.

```cmd
cmake -S . -B build
```

Configures the CMake build tree.

```cmd
cmake --build build --config Release
```

Builds the `mgb_model` executable.

```cmd
ctest --test-dir build -C Release --output-on-failure -R regression_magdalena
```

Runs the Magdalena regression gate.

```cmd
python tests/regression/run_regression.py --case-dir tests/regression/magdalena --exe build/Release/mgb_model.exe --work-dir C:\mgbmagtest
```

Runs the regression harness manually and preserves the working directory.

## Coding Style & Naming Conventions

Follow the existing Fortran style in nearby files. Keep source filenames and routine names consistent with current legacy naming, including uppercase module-oriented files such as `VARS_MAIN.f90` and flood routines such as `flood_timestep.f90`. Prefer small, localized edits and avoid broad formatting-only churn. Update `CMakeLists.txt` when adding or removing source files because sources are enumerated explicitly.

## Testing Guidelines

Use CTest for the standard regression path. The regression runner stages `Input`, creates `Output`, runs with `MGB_NONINTERACTIVE=1`, and compares selected files against `tests/regression/magdalena/expected`. When changing numerical behavior, update fixtures only with a clear rationale and document tolerance changes in `tests/regression/magdalena/manifest.json`.

## Commit & Pull Request Guidelines

Recent history uses short conventional prefixes such as `docs:`, `feat:`, and `fix:`. Keep subjects imperative and focused on intent. This repository also expects Lore-style commit trailers when useful, for example `Constraint:`, `Rejected:`, `Confidence:`, `Scope-risk:`, `Tested:`, and `Not-tested:`. Pull requests should describe behavioral impact, list verification commands, link related issues, and mention any changed regression fixtures or tolerances.

## Security & Configuration Tips

Do not commit local build outputs, `.omx/` runtime state, generated regression work directories, or machine-specific oneAPI configuration. Keep secrets and local paths out of fixtures and documentation examples unless they are clearly placeholders.
