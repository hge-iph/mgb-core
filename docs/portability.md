# Portability

Linux support remains a project requirement, but it is not implemented in this bootstrap completion phase.

## Current Position

- validated build path in this phase: Windows x64 + Intel `ifx`
- canonical build definition: CMake
- regression harness is designed so the runtime layout is explicit and not tied to the repository root

## Known Portability Constraints

- Intel-specific build/runtime assumptions remain in the current codebase
- the main driver still uses Windows-style relative paths by default
- direct-access unformatted binary I/O will need careful validation across toolchains
- filename case mismatches may matter outside Windows

## Deferred Work

- Linux CI lane
- alternative compiler support such as `gfortran`
- portability shims or compiler-compatibility cleanup beyond the current bootstrap seam
