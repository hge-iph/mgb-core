# Components and dependencies

MGB is a single Fortran executable organized into simulation, hydrology, I/O,
shared-variable, and common-utility components. This page defines the
responsibility and dependency rules for those components. The
[Architecture overview](architecture.md) introduces the complete system,
while [Execution and data flow](execution-and-data-flow.md) describes their
runtime collaboration.

## Common utilities

Common modules provide focused services that can be reused by the rest of the
model without owning scientific state or model files.

| Module | Responsibility | Public API |
| --- | --- | --- |
| `date_time` | Calendar parsing and formatting, Julian-day conversion, and timestep-count calculations | `format_date_string`, `parse_date_string`, `calculate_integer_julian_day`, `calculate_julian_day`, `convert_julian_day_to_calendar`, `calculate_timestep_count` |
| `interpolation` | Linear interpolation and endpoint extrapolation for tabulated values | `linear_interpolate` |
| `runtime_support` | Legacy runtime support for random-seed initialization and timer updates | `initialize_random_seed`, `update_legacy_timer` |

These modules have default-private visibility and expose only the listed
procedures. They do not import other project modules.

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

Hydrology modules implement terrestrial water balance, reservoir setup, and
the two available river-routing methods. They exchange data through the shared
variable modules and use common utilities where needed.

| Module | Responsibility | Public API |
| --- | --- | --- |
| `catchment` | Evapotranspiration, interception, HRU water balance, catchment aggregation, and terrestrial linear reservoirs | `calculate_catchment_time_of_concentration`, `initialize_catchment`, `update_catchment` |
| `reservoirs` | Initialization required by the existing reservoir and substitution behavior | `initialize_reservoir_state` |
| `river_inertial` | Inertial topology and table preparation, initialization, and local-inertial routing | `prepare_inertial_routing`, `initialize_inertial_routing`, `route_inertial_flow` |
| `river_muskingum` | Muskingum-Cunge parameter preparation, initialization, and network routing | `calculate_muskingum_cunge_parameters`, `initialize_muskingum_cunge_routing`, `route_muskingum_cunge_network` |

The evapotranspiration kernel is private to `catchment`, preserving the legacy
per-HRU calculation order without creating a hidden call between hydrology
modules. Hydrology modules do not import one another; `runner` coordinates
their public entry points.

## I/O

I/O modules own model files and transfer data to or from the five shared
namespaces without changing external formats.

| Module | Responsibility | Public API |
| --- | --- | --- |
| `configuration_io` | Read model configuration, establish dimensions and options, and initialize the simulation calendar | `read_model_configuration` |
| `hotstart_io` | Read and write binary hydrologic/routing state and hotstart schedules | `read_hotstart`, `read_hotstart_schedule`, `write_hotstart` |
| `log_io` | Open and close the model log file | `open_model_log`, `close_model_log` |
| `meteorological_io` | Open, read, and close meteorological forcing streams for the timestep loop | `open_meteorological_inputs`, `read_meteorological_forcing`, `close_meteorological_inputs` |
| `output_io` | Open, write, and close configured model-output streams | `open_model_outputs`, `write_model_outputs`, `close_model_outputs` |
| `static_input_io` | Read fixed, calibrated, catchment, climatology, substitution-flow, floodplain, and reservoir inputs | `read_catchment_inputs`, `read_floodplain_inputs`, `read_reservoir_inputs` |

`configuration_io` and `log_io` are called directly by `main.f90`. The runner
calls static, meteorological, hotstart, and output I/O during preparation and
the timestep sequence. I/O modules do not import hydrology behavior.

## Simulation

The simulation component owns application control and the ordering of all
preparation, runtime, and shutdown operations.

| Unit | Responsibility | Public API |
| --- | --- | --- |
| `runner` | Coordinate static-input loading, scientific preparation, meteorological-input opening, initialization, timestep updates, hotstart handling, output writing, and shutdown | `prepare_simulation`, `run_simulation` |
| `mgb_model` program | Assign runtime directories, open the log, read configuration, allocate and deallocate variables, report configuration and status, handle prompts, measure elapsed time, and call the runner | Program entry point |

`main.f90` owns the visible application lifecycle. It calls `runner` for
hydrology preparation and runtime simulation, while the runner coordinates the
hydrology and I/O public entry points.

## Dependency direction

The tables below show the current direct project-module imports. Each row is
read as **consumer → imported dependency**. Compiler-provided modules such as
`omp_lib` are omitted. Units with no project imports are listed explicitly so
the inventory covers every module and the `mgb_model` program.

### Simulation

| Consumer | Direct project dependencies |
| --- | --- |
| `mgb_model` program | `attributes`, `config`, `configuration_io`, `forcing`, `log_io`, `parameters`, `runner`, `state` |
| `runner` | `attributes`, `catchment`, `config`, `date_time`, `forcing`, `hotstart_io`, `meteorological_io`, `output_io`, `parameters`, `reservoirs`, `river_inertial`, `river_muskingum`, `state`, `static_input_io` |

### Hydrology

| Consumer | Direct project dependencies |
| --- | --- |
| `catchment` | `attributes`, `config`, `date_time`, `forcing`, `parameters`, `state` |
| `reservoirs` | `parameters` |
| `river_inertial` | `attributes`, `config`, `forcing`, `interpolation`, `parameters`, `state` |
| `river_muskingum` | `attributes`, `config`, `forcing`, `parameters`, `state` |

### I/O

| Consumer | Direct project dependencies |
| --- | --- |
| `configuration_io` | `config`, `date_time`, `state` |
| `hotstart_io` | `config`, `date_time`, `forcing`, `parameters`, `state` |
| `log_io` | `config` |
| `meteorological_io` | `config`, `forcing` |
| `output_io` | `config`, `state` |
| `static_input_io` | `attributes`, `config`, `date_time`, `forcing`, `parameters`, `state` |

### Shared variables

| Consumer | Direct project dependencies |
| --- | --- |
| `attributes` | None |
| `config` | None |
| `forcing` | None |
| `parameters` | None |
| `state` | None |

### Common utilities

| Consumer | Direct project dependencies |
| --- | --- |
| `date_time` | None |
| `interpolation` | None |
| `runtime_support` | None |

## Architecture enforcement

Allowed project dependencies are:

| Consumer | May use |
| --- | --- |
| Common | Common utilities only |
| Vars | No project module |
| Hydrology | Vars modules and common utilities |
| I/O | Vars modules and common utilities |
| `runner` | Hydrology, I/O, vars, and common modules |
| `main` | Vars, `configuration_io`, `log_io`, and `runner` |

Every project-module import requires an `only:` list. Common, hydrology, I/O,
and runner modules use default `private` visibility and explicit public APIs.
The vars modules are the sole default-public exception.

Forbidden dependencies include a vars module importing any project module,
one hydrology module importing another, scientific behavior importing I/O, and
I/O importing hydrology behavior. The application is also forbidden from
depending directly on hydrology or on static, meteorological, hotstart, and
output I/O; those dependencies are owned by `runner`. Its direct I/O
dependencies are limited to `configuration_io` and `log_io`.

The policy checker runs from the repository root with:

```bash
python3 scripts/check_fortran_architecture.py
```

The checker enforces approved module names and paths, a single application
program, contained project procedures, `implicit none`, visibility rules,
explicit `only:` imports, the dependency table above, and the prohibition on
named types in vars modules. Focused checker tests are under
`tests/architecture`, and the check is also registered with CTest.
