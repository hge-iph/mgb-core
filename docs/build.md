# Build

The bootstrap build in this branch is currently validated for Windows x64 with Intel `ifx` in a oneAPI environment.

## Prerequisites

- Intel oneAPI installed and loaded with (cmd):
  - `call "C:\Program Files (x86)\Intel\oneAPI\setvars.bat"`
- CMake available in that environment
- Visual Studio Build Tools available through the configured oneAPI environment

## Canonical Local Command

Run from the repository root:

```cmd
cmake -S . -B build
cmake --build build --config Release
ctest --test-dir build -C Release --output-on-failure -R regression_magdalena
```

## Current Build Scope

- Canonical build definition: `CMakeLists.txt`
- Current supported backend in this phase: Windows + Intel `ifx`
- Current explicit Intel flags are defined in `cmake/bootstrap_intel_fortran.cmake`
