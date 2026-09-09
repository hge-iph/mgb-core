# Build

This project uses CMake and requires OpenMP. The validated compiler environments are:

- Windows x64 with Intel `ifx`
- Linux x64 with Intel `ifx`
- Linux x64 with GNU Fortran 13.3

Use a separate build directory for each compiler. Select the compiler through the
standard `FC` environment variable before configuring a new build tree.

## Windows with Intel ifx

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

## Linux with Intel ifx

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

## Linux with GNU Fortran

Prerequisites:

- GNU Fortran 13.3
- CMake 3.25 or later
- the GNU OpenMP runtime supplied with gfortran

Run from the repository root:

```bash
FC=gfortran cmake -S . -B build/linux-gfortran -DCMAKE_BUILD_TYPE=Release
cmake --build build/linux-gfortran
ctest --test-dir build/linux-gfortran --output-on-failure
```

## Experimental Windows GNU Fortran

This environment is documented for evaluation but has not been validated. From an
MSYS2 UCRT64 shell, install the UCRT64 GNU Fortran, CMake, and Ninja packages:

```bash
pacman -S --needed mingw-w64-ucrt-x86_64-gcc-fortran \
  mingw-w64-ucrt-x86_64-cmake mingw-w64-ucrt-x86_64-ninja
```

Then configure a compiler-specific build tree:

```bash
FC=gfortran cmake -S . -B build/windows-gfortran -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build build/windows-gfortran
ctest --test-dir build/windows-gfortran --output-on-failure
```

## Optional Diagnostics Build

Use the opt-in diagnostics mode when collecting compiler warning output for cleanup work.

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

For GNU Fortran, use the same `-DENABLE_FORTRAN_DIAGNOSTICS=ON` option with the
GNU configuration command.

## Build Definition

- Canonical build definition: `CMakeLists.txt`
- Compiler-specific flags: `cmake/configure_fortran.cmake`
- Validated compilers: Intel `ifx`, and GNU Fortran 13.3 on Linux
- Required parallel runtime: OpenMP for Fortran

With `BUILD_TESTING` enabled, CTest registers the architecture check and the
inertial and Muskingum-Cunge Magdalena regression cases.
