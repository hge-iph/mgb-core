# Repository Guidelines

## Mission

This repository contains a legacy Fortran hydrological model being prepared for maintainable collaborative development. Modernization should improve structure, portability, documentation, and regression safety without casually changing scientific behavior.

## Current Development Scope

Focus first on infrastructure that makes later refactors safer:

- Preserve and improve the CMake-based build.
- Expand regression coverage before risky restructuring.
- Maintain validated Windows and Linux builds with Intel `ifx` and the validated Linux GNU Fortran build.
- Maintain MkDocs user documentation and in-repo developer documentation.
- Clean unused variables, stale comments, and confusing code incrementally.

Do not claim support for platforms or compilers that have not been validated. The current documented baselines are Windows x64 and Linux x64 with Intel `ifx`, plus Linux x64 with GNU Fortran 13.3; see `docs/development/build.md`.

## Fortran Modernization

- Prefer modules with clear responsibility and explicit interfaces.
- Reduce global-state coupling gradually; avoid broad rewrites just to make code look modern.
- Keep comments useful: explain intent, assumptions, units, file formats, and non-obvious hydrological behavior. Remove comments that merely repeat the code.
- Write new source identifiers, comments, and documentation in English using
  the conventions in `docs/development/coding-conventions.md`.
- Follow existing naming and layout conventions unless a PR is explicitly improving them in a narrow area.

## Validation

- For source or build changes, run the CMake build and both `regression_magdalena_inertial` and `regression_magdalena_muskingum` on the affected supported platform when available.
- For portability work, document the exact OS, compiler, CMake command, and any known failing assumptions.
- For refactors, provide regression evidence showing unchanged outputs or explicitly document output changes.
- For docs-only changes, verify links and keep guidance aligned with `README.md`, `docs/development/build.md`, and `docs/development/testing.md`.

## Documentation

Documentation tables use at most three columns. Drop or merge columns when
the same information can be expressed together. A table is not a good form of
presentation when its content does not fit clearly into three columns; use
prose, lists, or another presentation instead.

Legacy migration mappings list one variable per row, use the section title for
the namespace, and keep identifiers and paths intact without mid-word wrapping.

Install, preview, and validate the English MkDocs site from the repository root:

```bash
python -m pip install -r requirements-docs.txt
python -m mkdocs serve
python -m mkdocs build --strict
```

### Documentation voice

Documentation describes the model, its rationale, and its conventions directly.
Prose uses declarative sentences, active voice, concrete technical terms, and
affirmative explanations of implemented behavior. Command blocks remain
reference commands; surrounding prose describes what each command represents.

Headings and lists in `docs/` state facts, responsibilities, or behavior.
Development standards are declarative reference pages, while `CONTRIBUTING.md`
contains contributor instructions and workflow steps.

Ordinary explanations use affirmative wording and avoid rhetorical negative or
contrast framing. Necessary negation remains when it records a limitation,
unsupported environment, compatibility rule, or scientific meaning.

## Development notes and plans

Use `.dev/pr/` for temporary files specific to the current PR, such as implementation notes, checklists, and draft PR descriptions.

Use `.dev/plans/` for implementation plans, design notes, and tracked changes that may span multiple PRs.

# Build

This project uses CMake with OpenMP. Validated build directories are kept under
`build/` by compiler:

- Linux Intel: `build/ifx`
- Linux GNU: `build/gfortran`

## Windows

Prerequisites:

- Intel oneAPI installed
- CMake available in that environment
- Visual Studio Build Tools available through the configured oneAPI environment

When `ifx` is unavailable, initialize oneAPI from the repository root:

```cmd
call "C:\Program Files (x86)\Intel\oneAPI\setvars.bat"
```

Build from the repository root:

```cmd
set "FC=ifx"
cmake -S . -B build/ifx
cmake --build build/ifx --config Release
ctest --test-dir build/ifx -C Release --output-on-failure -R regression_magdalena_
```

## Linux

Prerequisites:

- Intel oneAPI installed
- CMake available in that environment

When `ifx` is unavailable, initialize oneAPI from the repository root:

```bash
source /opt/intel/oneapi/setvars.sh
```

Build from the repository root:

```bash
FC=ifx cmake -S . -B build/ifx -DCMAKE_BUILD_TYPE=Release
cmake --build build/ifx
ctest --test-dir build/ifx --output-on-failure -R regression_magdalena_
```

For GNU Fortran 13.3 on Linux:

```bash
FC=gfortran cmake -S . -B build/gfortran -DCMAKE_BUILD_TYPE=Release
cmake --build build/gfortran
ctest --test-dir build/gfortran --output-on-failure -R regression_magdalena_
```

## Build Definition

- Canonical build definition: `CMakeLists.txt`
- Compiler-specific flags: `cmake/configure_fortran.cmake`
- Validated compilers: Intel `ifx`, and GNU Fortran 13.3 on Linux
