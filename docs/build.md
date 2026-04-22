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

## Experimental Linux Command

Linux support is prepared for Intel `ifx`, but remains experimental until the
build and regression case are validated on Linux.

Load oneAPI first:

```bash
source /opt/intel/oneapi/setvars.sh
```

Then run from the repository root:

```bash
FC=ifx cmake -S . -B build-linux -DCMAKE_BUILD_TYPE=Release
cmake --build build-linux
ctest --test-dir build-linux --output-on-failure -R regression_magdalena
```

## Current Build Scope

- Canonical build definition: `CMakeLists.txt`
- Current validated backend in this phase: Windows + Intel `ifx`
- Experimental Linux backend: Intel `ifx`
- Current explicit Intel flags are defined in `cmake/bootstrap_intel_fortran.cmake`
