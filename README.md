# MGB-model

Legacy Fortran hydrology and hydrodynamics model under bootstrap for collaborative development.

## Bootstrap Docs

- [Build](docs/build.md)
- [Testing](docs/testing.md)
- [Architecture Bootstrap](docs/architecture-bootstrap.md)
- [Portability](docs/portability.md)

## Canonical Local Flow

Run from the repository root:

```powershell
cmake -S . -B build/windows
cmake --build build/windows --config Release
ctest --test-dir build/windows -C Release --output-on-failure -R regression_magdalena
```
