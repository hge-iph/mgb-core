# Components and dependencies

MGB is a single Fortran executable organized into simulation, hydrology, I/O,
shared-variable, and common-utility layers. This page defines the responsibility
and dependency rules for those components. The [Architecture overview](architecture.md)
introduces the complete system, while [Execution and data flow](execution-and-data-flow.md)
describes their runtime collaboration.

## Shared variables

The five modules under `src/vars` contain flat module variables. They do not
define derived types or additional storage aggregates.

| Module | Responsibility |
| --- | --- |
| `attributes` | Fixed catchment geometry, classifications, connectivity, HRU composition, channel roughness, and raw floodplain geometry |
| `config` | Dimensions, fixed capacities, simulation and routing options, output and hotstart options, paths, file units, and schedules |
| `forcing` | Current and historical meteorology, climatology, prescribed-flow series, and reservoir outflow forcing |
| `parameters` | Scientific coefficients, derived river parameters, prepared routing tables and topology, and reservoir mappings |
| `state` | Calendar state, evolving terrestrial and river values, routing work arrays, diagnostics, and output serialization buffers |

These modules are default-public by design. Access is controlled at every
consumer with an explicit `use ..., only:` list. Allocation, deallocation, and
storage management remain in the module that owns the affected variables.
Required dimensions are passed as scalar arguments, so the variable modules
do not depend on one another. Scientific initialization is separate from
storage management: hydrology procedures populate initial model state, and I/O
procedures can load or restore values in these namespaces.

## Hydrology

| Module | Responsibility | Public API |
| --- | --- | --- |
| `catchment` | Evapotranspiration, interception, HRU water balance, catchment aggregation, and terrestrial linear reservoirs | `calculate_catchment_time_of_concentration`, `initialize_catchment`, `update_catchment` |
| `river_muskingum` | Muskingum-Cunge parameter preparation, initialization, and network routing | `calculate_muskingum_cunge_parameters`, `initialize_muskingum_cunge_routing`, `route_muskingum_cunge_network` |
| `river_inertial` | Inertial topology/table preparation, initialization, and routing | `prepare_inertial_routing`, `initialize_inertial_routing`, `route_inertial_flow` |
| `reservoirs` | Initialization required by the existing reservoir and substitution behavior | `initialize_reservoir_state` |

The evapotranspiration kernel is private to `catchment`, preserving the legacy
per-HRU calculation order without creating a hidden call between hydrology
modules. Hydrology modules do not import one another; `runner` coordinates
their public entry points.

## Simulation and I/O

`main.f90` owns the visible application lifecycle. It assigns the fixed runtime
directories, opens the log, reads configuration, allocates and deallocates
variables, reports the configuration, handles interactive prompts, measures
elapsed time, and reports final status. The program calls `runner` for
hydrology preparation and runtime simulation.

`runner` owns static-input loading, scientific preparation, meteorological-input
opening, and the timestep and hotstart sequence. It closes meteorological and
model-output files after the run. The I/O modules own model files and transfer
data to or from the five shared namespaces without changing external formats.
`configuration_io` and `log_io` are called directly by `main.f90`; the runner
calls static, meteorological, hotstart, and output I/O.

## Dependency direction

```text
simulation/main -----> vars + configuration_io + log_io
        |
        v
runner ----> hydrology + static/meteorological/hotstart/output I/O
        |                                  |
        +----------------> vars + common <-+
```

Allowed project dependencies are:

| Consumer | May use |
| --- | --- |
| Common | Common utilities only |
| Vars | No project module |
| Hydrology | Vars modules and common utilities |
| I/O | Vars modules and common utilities |
| `runner` | Hydrology, I/O, vars, and common modules |
| `main` | Vars, `configuration_io`, `log_io`, and `runner` |

Every project-module import requires an `only:` list. Behavioral, common, I/O,
and runner modules use default `private` visibility and explicit public APIs.
The vars modules are the sole default-public exception.

Forbidden dependencies include a vars module importing any project module,
one hydrology module importing another, scientific behavior importing I/O, and
I/O importing hydrology behavior. The application is also forbidden from
depending directly on hydrology or on static, meteorological, hotstart, and
output I/O; those dependencies are owned by `runner`. Its direct I/O
dependencies are limited to `configuration_io` and `log_io`.

## Architecture enforcement

The policy checker runs from the repository root with:

```bash
python3 scripts/check_fortran_architecture.py
```

The checker enforces approved module names and paths, a single application
program, contained project procedures, `implicit none`, visibility rules,
explicit `only:` imports, the dependency table above, and the prohibition on
named types in vars modules. Focused checker tests are under
`tests/architecture`, and the check is also registered with CTest.
