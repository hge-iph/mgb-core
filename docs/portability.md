# Portability

## Supported Build Environments

The current validated build environments are:

- Windows x64 with Intel `ifx`
- Linux x64 with Intel `ifx`

Both builds use CMake. Build commands are documented in `docs/build.md`.

## Runtime Layout

The model uses lowercase runtime directories:

- `input/`
- `output/`
- `hotstart/`

The regression harness stages runtime files into a temporary working directory,
so tests are not tied to the repository root.

## Remaining Portability Constraints

- Direct-access unformatted binary I/O must be revalidated before changing compiler families.
- `gfortran` support remains a future target and is not currently validated.
