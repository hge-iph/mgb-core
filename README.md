# MGB-model

Legacy Fortran hydrology and hydrodynamics model under bootstrap for collaborative development.

## Start here

- To build and run the model, start with the [build guide](docs/getting-started/build.md)
  and [I/O reference](docs/model/io-reference.md).
- To understand the source, start with the [documentation home](docs/index.md),
  [architecture](docs/development/architecture.md), and
  [model processes](docs/model/model-processes.md).
- To make a repository change, follow [CONTRIBUTING.md](CONTRIBUTING.md).

## Documentation

The MkDocs site contains the software architecture, model behavior, interfaces,
scientific references, and durable design decisions. Preview it locally with:

```bash
python -m pip install -r requirements-docs.txt
python -m mkdocs serve
```

Build the same strict site checked for pull requests with:

```bash
python -m mkdocs build --strict
```

OpenMP is required for every supported build. The build and portability pages
contain the current validated environments; this README intentionally does not
duplicate those commands or support claims.
