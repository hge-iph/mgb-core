# MGB-model

Legacy Fortran hydrology and hydrodynamics model under bootstrap for collaborative development.

## Documentation

The documentation is available from the [MkDocs home page](docs/index.md).
Install and preview it locally with:

```bash
python -m pip install -r requirements-docs.txt
python -m mkdocs serve
```

Build the same strict site checked for pull requests with:

```bash
python -m mkdocs build --strict
```

Useful starting points:

- [Build](docs/getting-started/build.md)
- [Testing](docs/getting-started/testing.md)
- [Architecture](docs/development/architecture.md)
- [Processes and I/O](docs/model/model-processes.md)
- [Portability](docs/model/portability.md)
- [Language and naming](docs/development/language-and-naming.md)
- [Fortran style](docs/development/fortran-style.md)

## Windows

Run from the repository root:

```powershell
call "C:\Program Files (x86)\Intel\oneAPI\setvars.bat"
cmake -S . -B build/windows
cmake --build build/windows --config Release
ctest --test-dir build/windows -C Release --output-on-failure
```

## Linux

Run from the repository root with either validated compiler.

Intel `ifx`:

```bash
source /opt/intel/oneapi/setvars.sh
FC=ifx cmake -S . -B build/linux -DCMAKE_BUILD_TYPE=Release
cmake --build build/linux
ctest --test-dir build/linux --output-on-failure
```

GNU Fortran:

```bash
FC=gfortran cmake -S . -B build/linux-gfortran -DCMAKE_BUILD_TYPE=Release
cmake --build build/linux-gfortran
ctest --test-dir build/linux-gfortran --output-on-failure
```

OpenMP is required for every supported build. See the [build guide](docs/getting-started/build.md)
for compiler prerequisites and the experimental Windows GNU Fortran setup.
