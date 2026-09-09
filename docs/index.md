# MGB Model

MGB is a legacy Fortran model for large-scale hydrology and hydrodynamics. This
repository is being prepared for maintainable collaborative development while
preserving its scientific behavior, binary layouts, and numerical record data.
The source identifiers use descriptive English names while the runtime input
filenames remain established MGB names.

## Start here

- [Build the model](getting-started/build.md) on a validated Intel `ifx` environment.
- [Run the Magdalena regression case](getting-started/testing.md).
- Review the [source architecture and dependency rules](development/architecture.md).
- Review the [portability constraints](model/portability.md) before changing source
  code.
- Read the [process and numerical assumptions](model/model-processes.md) and the
  [complete I/O reference](model/io-reference.md) before changing a file format.
- Follow the [language and naming guide](development/language-and-naming.md) when writing
  code or documentation.

## Documentation locally

Install the documentation dependencies and start the development server:

```bash
python -m pip install -r requirements-docs.txt
python -m mkdocs serve
```

Build the same strict site used by pull-request validation with:

```bash
python -m mkdocs build --strict
```

The generated site is written to `site/` and is not committed.
