# MGB Model

MGB is a legacy Fortran model for large-scale hydrology and hydrodynamics. This
repository is being prepared for maintainable collaborative development while
preserving its scientific behavior, binary layouts, and numerical record data.
The source identifiers use descriptive English names while the runtime input
filenames remain established MGB names.

## Choose a starting point

To build or run MGB:

- [Build the model](getting-started/build.md) in a validated environment.
- Use the [I/O reference](model/io-reference.md) to prepare configuration and
  runtime files.

To understand how the software works:

- Begin with [model concepts and discretization](model/model-concepts.md) for
  the catchment, HRU, subbasin, and river-network hierarchy.
- Use the detailed references for
  [energy and evapotranspiration](model/energy-balance.md),
  [soil and catchment processes](model/soil-and-catchment-processes.md),
  [river routing](model/river-routing.md), and
  [parameters and initial state](model/parameters-and-initial-state.md) when
  interpreting the model equations.
- Start with the [source architecture](development/architecture.md) for module
  responsibilities, dependencies, state organization, and execution flow.
- Read the [process and numerical assumptions](model/model-processes.md) for the
  scientific timestep and routing behavior.
- Consult the [design decisions](development/design-decisions.md) for the
  rationale behind current source boundaries and compatibility constraints.

To make a change to the repository, follow
[CONTRIBUTING.md](https://github.com/HGE-IPH/MGB-model/blob/main/CONTRIBUTING.md).
It contains the development setup, Git workflow, required standards, test and
documentation expectations, and pull-request process. The detailed language,
naming, and Fortran style pages are references for that workflow rather than a
second contribution guide.

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
