# Repository Guidelines

## Mission

This repository contains a legacy Fortran hydrological model being prepared for maintainable collaborative development. Modernization should improve structure, portability, documentation, and regression safety without casually changing scientific behavior.

## Current Development Scope

Focus first on infrastructure that makes later refactors safer:

- Preserve and improve the CMake-based build.
- Expand regression coverage before risky restructuring.
- Maintain validated Windows and Linux builds with Intel `ifx`; keep eventual `gfortran` support in view.
- Maintain MkDocs user documentation and in-repo developer documentation.
- Clean unused variables, stale comments, and confusing code incrementally.

Do not claim support for platforms or compilers that have not been validated. The current documented baselines are Windows x64 and Linux x64 with Intel `ifx`; see `docs/build.md` and `docs/portability.md`.

## Change Boundaries

- Keep PRs focused and reviewable. Avoid large mixed changes.
- Do not combine algorithm changes with formatting, cleanup, or module restructuring.
- Preserve input/output file formats and model outputs unless the PR explicitly documents and tests the change.
- Separate IO restructuring from hydrology and routing logic changes.
- Prefer small behavior-preserving steps that can be checked by regression tests.

## Fortran Modernization

- Prefer modules with clear responsibility and explicit interfaces.
- Reduce global-state coupling gradually; avoid broad rewrites just to make code look modern.
- Keep comments useful: explain intent, assumptions, units, file formats, and non-obvious hydrological behavior. Remove comments that merely repeat the code.
- Write new source identifiers, comments, and documentation in English using
  the conventions in `docs/language-and-naming.md`.
- Follow existing naming and layout conventions unless a PR is explicitly improving them in a narrow area.

## Git Contribution Flow

- `main` is the stable branch.
- Use feature branches for development work.
- Pull requests are preferred for all changes, especially source, build, tests, docs structure, and regression data.
- Small documentation or metadata fixes may be committed directly by maintainers.
- PR descriptions should explain behavior impact and list build/test evidence.

## Validation

- For source or build changes, run the CMake build and `regression_magdalena` on the affected supported platform when available.
- For portability work, document the exact OS, compiler, CMake command, and any known failing assumptions.
- For refactors, provide regression evidence showing unchanged outputs or explicitly document output changes.
- For docs-only changes, verify links and keep guidance aligned with `README.md`, `docs/build.md`, `docs/testing.md`, and `docs/portability.md`.

## Documentation

Install, preview, and validate the English MkDocs site from the repository root:

```bash
python -m pip install -r requirements-docs.txt
python -m mkdocs serve
python -m mkdocs build --strict
```

# Build

This project uses CMake with Intel `ifx`. Validated build directories are kept
under `build/` by operating system:

- Windows: `build/windows`
- Linux: `build/linux`

## Windows

Prerequisites:

- Intel oneAPI installed and loaded:
  - `call "C:\Program Files (x86)\Intel\oneAPI\setvars.bat"`
- CMake available in that environment
- Visual Studio Build Tools available through the configured oneAPI environment

Run from the repository root:

```cmd
cmake -S . -B build/windows
cmake --build build/windows --config Release
ctest --test-dir build/windows -C Release --output-on-failure -R regression_magdalena
```

## Linux

Prerequisites:

- Intel oneAPI installed and loaded:
  - `source /opt/intel/oneapi/setvars.sh`
- CMake available in that environment

Run from the repository root:

```bash
source /opt/intel/oneapi/setvars.sh
FC=ifx cmake -S . -B build/linux -DCMAKE_BUILD_TYPE=Release
cmake --build build/linux
ctest --test-dir build/linux --output-on-failure -R regression_magdalena
```

## Build Definition

- Canonical build definition: `CMakeLists.txt`
- Intel Fortran flags: `cmake/bootstrap_intel_fortran.cmake`
- Validated compiler: Intel `ifx`
