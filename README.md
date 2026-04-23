# MGB-model

Legacy Fortran hydrology and hydrodynamics model under bootstrap for collaborative development.

## Bootstrap Docs

- [Build](docs/build.md)
- [Testing](docs/testing.md)
- [Architecture Bootstrap](docs/architecture-bootstrap.md)
- [Cleanup Roadmap](docs/cleanup-roadmap.md)
- [Portability](docs/portability.md)

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
