# MGB Model

MGB is a legacy Fortran model for large-scale hydrology and hydrodynamics. This
repository is being prepared for maintainable collaborative development while
preserving its scientific behavior, binary layouts, and numerical record data.
The source identifiers use descriptive English names while the runtime input
filenames remain established MGB names.

## Start here

- [Build the model](build.md) on a validated Intel `ifx` environment.
- [Run the Magdalena regression case](testing.md).
- Review the [source architecture and dependency rules](architecture.md).
- Review the [portability constraints](portability.md) before changing source
  code.
- Read the [process and numerical assumptions](model-processes.md) and the
  [complete I/O reference](io-reference.md) before changing a file format.
- Follow the [language and naming guide](language-and-naming.md) when writing
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
