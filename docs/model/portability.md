# Portability

## Supported Build Environments

The current validated build environments are:

- Windows x64 with Intel `ifx`
- Linux x64 with Intel `ifx`
- Linux x64 with GNU Fortran 13.3

All validated builds use CMake. Build commands are documented in the
[build guide](../getting-started/build.md).

## Runtime Layout

The model uses lowercase runtime directories:

- `input/`
- `output/`
- `hotstart/`

The regression harness stages runtime files into a temporary working directory,
so tests are not tied to the repository root.

## Remaining Portability Constraints

- Direct-access unformatted record lengths are derived with `INQUIRE(IOLENGTH=...)`, allowing the
  Intel and GNU builds to read and write the same established physical record layouts.
- Windows GNU Fortran commands target MSYS2 UCRT64 but remain experimental and unvalidated.
- Other operating systems, architectures, and compiler families remain unvalidated.
