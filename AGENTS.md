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

Do not claim support for platforms or compilers that have not been validated. The current documented baselines are Windows x64 and Linux x64 with Intel `ifx`; see `docs/getting-started/build.md` and `docs/model/portability.md`.

## Fortran Modernization

- Prefer modules with clear responsibility and explicit interfaces.
- Reduce global-state coupling gradually; avoid broad rewrites just to make code look modern.
- Keep comments useful: explain intent, assumptions, units, file formats, and non-obvious hydrological behavior. Remove comments that merely repeat the code.
- Write new source identifiers, comments, and documentation in English using
  the conventions in `docs/development/language-and-naming.md`.
- Follow existing naming and layout conventions unless a PR is explicitly improving them in a narrow area.

## Validation

- For source or build changes, run the CMake build and both `regression_magdalena_inertial` and `regression_magdalena_muskingum` on the affected supported platform when available.
- For portability work, document the exact OS, compiler, CMake command, and any known failing assumptions.
- For refactors, provide regression evidence showing unchanged outputs or explicitly document output changes.
- For docs-only changes, verify links and keep guidance aligned with `README.md`, `docs/getting-started/build.md`, `docs/getting-started/testing.md`, and `docs/model/portability.md`.

## Documentation

Install, preview, and validate the English MkDocs site from the repository root:

```bash
python -m pip install -r requirements-docs.txt
python -m mkdocs serve
python -m mkdocs build --strict
```

## Development notes and plans

Use `.dev/pr/` for temporary files specific to the current PR, such as implementation notes, checklists, and draft PR descriptions.

Use `.dev/plans/` for implementation plans, design notes, and tracked changes that may span multiple PRs.

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
ctest --test-dir build/windows -C Release --output-on-failure -R regression_magdalena_
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
ctest --test-dir build/linux --output-on-failure -R regression_magdalena_
```

## Build Definition

- Canonical build definition: `CMakeLists.txt`
- Intel Fortran flags: `cmake/bootstrap_intel_fortran.cmake`
- Validated compiler: Intel `ifx`
