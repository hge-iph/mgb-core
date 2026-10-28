# Setup and build

MGB uses CMake and requires the Fortran component of OpenMP. The validated
compiler environments are Linux x64 with Intel `ifx`, Windows x64 with Intel
`ifx`, and Linux x64 with GNU Fortran 13.3.

Build trees use the compiler name: `build/ifx` for Intel Fortran and
`build/gfortran` for GNU Fortran. The `FC` environment variable selects the
compiler for a new CMake tree on Unix-like shells. Windows command prompt uses
`set` for the same selection.

This page is the build reference for users and developers. The repository
change workflow and pull-request expectations are maintained in
[CONTRIBUTING.md](https://github.com/HGE-IPH/MGB-model/blob/main/CONTRIBUTING.md).

## Development environment

The repository supports a development container and native environments. Both
use a separate CMake build directory for each compiler.

The recommended development container supplies CMake, Ninja, GNU Fortran,
Intel `ifx`, Python, and the editor extensions used for Fortran development.
Install a container runtime and Visual Studio Code with the Dev Containers
extension, open the repository, and run **Dev Containers: Reopen in Container**
from the command palette.

Install the repository's Python tools inside the container with:

```bash
python3 -m pip install --break-system-packages \
  -r requirements-dev.txt -r requirements-docs.txt
```

The `--break-system-packages` option is appropriate for the disposable
development container. Native environments use their normal Python package
management and provide the compiler, CMake, OpenMP runtime, and
platform-specific tools required by the selected workflow.

## Installed prerequisites

Every workflow assumes that its tools are already installed:

- CMake 3.25 or later;
- an OpenMP runtime with Fortran support;
- Intel oneAPI for the Intel `ifx` workflows;
- GNU Fortran 13.3 for the validated Linux GNU workflow; and
- Visual Studio Build Tools in the configured Intel oneAPI environment on
  Windows.

The Windows GNU workflow has an experimental, unvalidated status. Its
installed prerequisites are an MSYS2 UCRT64 shell, UCRT64 GNU Fortran, CMake,
Ninja, and the matching OpenMP runtime.

## Linux with Intel ifx (validated)

The Linux Intel environment provides Intel oneAPI and CMake. When `ifx` is
unavailable on `PATH`, the oneAPI environment is initialized from the
repository root with:

```bash
source /opt/intel/oneapi/setvars.sh
```

The Linux Intel build commands are:

```bash
FC=ifx cmake -S . -B build/ifx -DCMAKE_BUILD_TYPE=Release
cmake --build build/ifx
ctest --test-dir build/ifx --output-on-failurewho
```

## Windows with Intel ifx (validated)

The Windows Intel environment provides Intel oneAPI, CMake, and Visual Studio
Build Tools. The commands below use a Windows command prompt from the
repository root. When `ifx` is unavailable, the oneAPI environment is
initialized with:

```cmd
call "C:\Program Files (x86)\Intel\oneAPI\setvars.bat"
```

The Windows Intel build commands are:

```cmd
set "FC=ifx"
cmake -S . -B build/ifx
cmake --build build/ifx --config Release
ctest --test-dir build/ifx -C Release --output-on-failure
```

## Linux with GNU Fortran 13.3 (validated)

The Linux GNU environment provides GNU Fortran 13.3, CMake, and the GNU
OpenMP runtime:

```bash
FC=gfortran cmake -S . -B build/gfortran -DCMAKE_BUILD_TYPE=Release
cmake --build build/gfortran
ctest --test-dir build/gfortran --output-on-failure
```

## Windows with GNU Fortran (experimental, unvalidated)

This workflow targets an MSYS2 UCRT64 shell. The shell environment contains
the installed UCRT64 GNU Fortran, CMake, Ninja, and OpenMP prerequisites. The
workflow remains experimental and unvalidated:

```bash
FC=gfortran cmake -S . -B build/gfortran -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build build/gfortran
ctest --test-dir build/gfortran --output-on-failure
```

Optional compiler diagnostics and failure-investigation workflows are in
[Testing and debugging](testing.md).

## Build definition

- The canonical build definition is `CMakeLists.txt`.
- Compiler-specific flags are defined in `cmake/configure_fortran.cmake`.
- The validated compilers are Intel `ifx` and GNU Fortran 13.3 on Linux.
- OpenMP for Fortran is the required parallel runtime.

With `BUILD_TESTING` enabled, CTest registers the architecture check and the
inertial and Muskingum-Cunge Magdalena regression cases.

## Portability status

The validated environments are Windows x64 and Linux x64 with Intel `ifx`,
plus Linux x64 with GNU Fortran 13.3. The Windows GNU workflow remains
experimental and unvalidated. Other operating systems, architectures, and
compiler families are also unvalidated.

Direct-access unformatted record lengths are derived with
`INQUIRE(IOLENGTH=...)`, allowing the validated Intel and GNU builds to retain
the established physical record layouts. Portability changes preserve those
layouts unless an intentional format migration is separately agreed and
documented.
