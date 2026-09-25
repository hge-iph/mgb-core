# Architecture overview

MGB builds one Fortran executable around five source responsibilities:
simulation orchestration, hydrological behavior, runtime I/O, shared model
variables, and common utilities. This organization makes the existing
module-global data exchange visible while keeping scientific calculations,
file ownership, and application control separate.

```text
main program
    |
    v
simulation runner -----> hydrology
    |                       |
    +-----> I/O             |
    |         |             |
    +---------+-------------+
              |
              v
       shared variables <---- common utilities
```

The source preserves established numerical order, data layouts, and model
interfaces. Architecture rules support incremental modernization without
introducing a second state representation or hiding legacy coupling behind a
whole-model object.

## Source organization

```text
src/
├── simulation/   application entry point and simulation runner
├── hydrology/    catchment, routing, and reservoir behavior
├── io/           configuration, input, output, log, and hotstart files
├── vars/         attributes, configuration, forcing, parameters, and state
└── common/       date, interpolation, and runtime utilities
```

Dependencies point from orchestration toward behavior, I/O, shared variables,
and common utilities. Hydrology modules do not call one another, scientific
modules do not own runtime files, and variable modules do not import other
project modules. The runner provides the explicit coordination between these
layers.

## Runtime shape

The executable prepares configuration, storage, static inputs, routing data,
and meteorological streams before entering the timestep loop. Each timestep
updates forcing and catchment hydrology, advances the selected river-routing
method, prepares outputs, and advances the calendar. The runner then closes
runtime streams and returns control to the main program for deallocation and
final reporting.

I/O and hydrology exchange values through five role-based shared namespaces.
Consumers expose that coupling through explicit `only:` import lists, and the
architecture checker enforces the allowed dependency direction.

## Architecture references

- [Components and dependencies](components-and-dependencies.md) defines module
  responsibilities, public APIs, allowed dependencies, and automated policy
  enforcement.
- [Execution and data flow](execution-and-data-flow.md) documents preparation,
  runtime, shutdown, shared-state movement, and scientific handoffs.
- [I/O reference](io-reference.md) defines configuration, input, output, and
  hotstart contracts and their owning modules.
- [Design decisions](design-decisions.md) records the rationale for durable
  boundaries and compatibility constraints.

Contributor workflow and change-validation expectations remain in
[CONTRIBUTING.md](https://github.com/HGE-IPH/MGB-model/blob/main/CONTRIBUTING.md).
