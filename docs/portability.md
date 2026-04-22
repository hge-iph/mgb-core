# Portability

Linux support remains a project requirement. This branch prepares an
experimental Intel `ifx` Linux build path, but it is not a validated supported
baseline until the Linux build and regression case have been run successfully.

## Current Position

- validated build path in this phase: Windows x64 + Intel `ifx`
- experimental build path: Linux + Intel `ifx`
- canonical build definition: CMake
- regression harness is designed so the runtime layout is explicit and not tied to the repository root

## Known Portability Constraints

- Intel-specific build assumptions remain in the current codebase
- direct-access unformatted binary I/O will need careful validation across toolchains
- `gfortran` support remains out of scope for this bootstrap step
