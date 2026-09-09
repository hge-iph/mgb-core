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
ctest --test-dir build/windows -C Release --output-on-failure
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
ctest --test-dir build/linux --output-on-failure
```

## Optional Diagnostics Build

Use the opt-in diagnostics mode when collecting Intel Fortran warning output for
cleanup work.

### Linux

```bash
source /opt/intel/oneapi/setvars.sh
FC=ifx cmake -S . -B build/linux-diagnostics -DCMAKE_BUILD_TYPE=Release -DENABLE_FORTRAN_DIAGNOSTICS=ON
cmake --build build/linux-diagnostics
```

### Windows

```cmd
call "C:\Program Files (x86)\Intel\oneAPI\setvars.bat"
cmake -S . -B build/windows-diagnostics -DENABLE_FORTRAN_DIAGNOSTICS=ON
cmake --build build/windows-diagnostics --config Release
```

## Build Definition

- Canonical build definition: `CMakeLists.txt`
- Intel Fortran flags: `cmake/bootstrap_intel_fortran.cmake`
- Validated compiler: Intel `ifx`

With `BUILD_TESTING` enabled, CTest registers the architecture check and the
inertial and Muskingum-Cunge Magdalena regression cases.
