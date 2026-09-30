# MGB Model

MGB is a distributed large-scale hydrological and hydrodynamic model. This
site documents the current Fortran implementation, its scientific formulation,
software structure, runtime interfaces, and collaborative development workflow
while preserving established numerical behavior and file formats.

## Documentation map

### Model

Start with the [Model overview](model/overview.md) for the model's purpose,
process chain, spatial and temporal representation, routing choices, runtime
boundary, and paths into the scientific reference.

- [Concepts and discretization](model/model-concepts.md) defines catchments,
  HRUs, subbasins, climate regions, and the spatial hierarchy.
- [Energy balance and evapotranspiration](model/energy-balance.md) and
  [soil and catchment processes](model/soil-and-catchment-processes.md)
  document terrestrial behavior.
- The [river-routing overview](model/river-routing.md) compares the routing
  choices and links to the separate
  [Muskingum-Cunge](model/muskingum-cunge-routing.md) and
  [local-inertial](model/local-inertial-routing.md) formulations.
- [Parameters and initial state](model/parameters-and-initial-state.md),
  [model processes and numerical assumptions](model/model-processes.md), and
  [scientific references](model/references.md) complete the scientific
  reference.

### Architecture

The [Architecture overview](architecture/architecture.md) introduces the
source layers and runtime shape.
[Components and dependencies](architecture/components-and-dependencies.md)
defines module responsibilities, APIs, dependency rules, and enforcement.
[Execution and data flow](architecture/execution-and-data-flow.md) documents
the application lifecycle, shared state, and scientific handoffs. The
[I/O reference](architecture/io-reference.md) records runtime contracts, while
[Design decisions](architecture/design-decisions.md) explains the rationale
for durable boundaries.

### Development

The four development guides cover:

- [Setup and build](development/build.md), including the development
  container, native prerequisites, validated compiler workflows, and
  portability status;
- [Testing and debugging](development/testing.md), including regression,
  policy, and documentation checks plus failure investigation;
- [Automation and documentation](development/continuous-integration.md),
  including CI workflows, MkDocs commands, and documentation boundaries; and
- [Coding conventions](development/coding-conventions.md), including language,
  naming, comments, Fortran style, and policy checks.

Contributor workflow, branch conventions, review expectations, and pull-request
checklists are maintained in
[CONTRIBUTING.md](https://github.com/HGE-IPH/MGB-model/blob/main/CONTRIBUTING.md).

### Legacy migration

The [Legacy migration reference](migration/overview.md) maps the source tree
at commit `41146b1` to the current implementation. It includes mappings for
[source files and modules](migration/source-files.md),
[routines and execution flow](migration/routines-and-flow.md),
[shared variables and terminology](migration/shared-variables.md), and
[runtime names](migration/runtime-names.md).
