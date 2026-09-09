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

- [Build](docs/build.md)
- [Testing](docs/testing.md)
- [Architecture](docs/architecture-bootstrap.md)
- [Cleanup roadmap](docs/changes/cleanup/roadmap.md)
- [Processes and I/O](docs/model-processes.md)
- [Runtime migration](docs/migration.md)
- [Portability](docs/portability.md)
- [Language and naming](docs/language-and-naming.md)
- [Fortran style](docs/fortran-style.md)

## Windows

Run from the repository root:

```powershell
call "C:\Program Files (x86)\Intel\oneAPI\setvars.bat"
cmake -S . -B build/windows
cmake --build build/windows --config Release
ctest --test-dir build/windows -C Release --output-on-failure -R regression_magdalena
```

## Linux

Run from the repository root:

```bash
source /opt/intel/oneapi/setvars.sh
FC=ifx cmake -S . -B build/linux -DCMAKE_BUILD_TYPE=Release
cmake --build build/linux
ctest --test-dir build/linux --output-on-failure -R regression_magdalena
```
