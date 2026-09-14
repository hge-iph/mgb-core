# Architecture

MGB is a single Fortran executable organized around hydrological behavior,
shared model variables, centralized I/O, simulation orchestration, and common
utilities. The organization preserves the legacy model's module-global storage
while making the purpose of each shared variable explicit.

This page describes the implemented system. The rationale for its durable
constraints is recorded in [Design decisions](design-decisions.md), while the
steps and checks for changing it belong in
[CONTRIBUTING.md](https://github.com/HGE-IPH/MGB-model/blob/main/CONTRIBUTING.md).

## Source tree

```text
src/
├── simulation/
│   ├── main.f90
│   └── runner.f90
├── common/
│   ├── date_time.f90
│   ├── interpolation.f90
│   └── runtime_support.f90
├── vars/
│   ├── attributes.f90
│   ├── config.f90
│   ├── forcing.f90
│   ├── parameters.f90
│   └── state.f90
├── hydrology/
│   ├── catchment.f90
│   ├── river_muskingum.f90
│   ├── river_inertial.f90
│   └── reservoirs.f90
└── io/
    ├── configuration_io.f90
    ├── log_io.f90
    ├── static_input_io.f90
    ├── meteorological_io.f90
    ├── hotstart_io.f90
    └── output_io.f90
```

## Responsibilities

### Shared variables

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

### Hydrology

| Module | Responsibility | Public API |
| --- | --- | --- |
| `catchment` | Evapotranspiration, interception, HRU water balance, catchment aggregation, and terrestrial linear reservoirs | `calculate_catchment_time_of_concentration`, `initialize_catchment`, `update_catchment` |
| `river_muskingum` | Muskingum-Cunge parameter preparation, initialization, and network routing | `calculate_muskingum_cunge_parameters`, `initialize_muskingum_cunge_routing`, `route_muskingum_cunge_network` |
| `river_inertial` | Inertial topology/table preparation, initialization, and routing | `prepare_inertial_routing`, `initialize_inertial_routing`, `route_inertial_flow` |
| `reservoirs` | Initialization required by the existing reservoir and substitution behavior | `initialize_reservoir_state` |

The evapotranspiration kernel is private to `catchment`, preserving the legacy
per-HRU calculation order without creating a hidden call between hydrology
modules. Hydrology modules do not import one another; `runner`
coordinates their public entry points.

### Composition and I/O

`main.f90` owns the visible application lifecycle. It assigns the fixed
`./input/`, `./output/`, and `./hotstart/` directories, opens the log, reads
configuration, allocates and deallocates variables, reports the configuration,
handles the interactive prompts, measures elapsed time, and reports final
status. Setting `MGB_NONINTERACTIVE=1` skips both console prompts. The program
calls `runner` for hydrology preparation and runtime simulation.

`runner` owns static-input loading, routing and hydrology
preparation, meteorological-input opening, and the timestep and hotstart
sequence. It also closes the meteorological and model-output files after the
run. The I/O modules retain ownership of the model files and transfer data to
or from the five shared namespaces without changing external formats.
`configuration_io` and `log_io` are called directly by `main.f90`; static,
meteorological, hotstart, and output I/O are called by `runner`.

## Execution lifecycle

The application has three visible phases:

1. **Prepare.** `main.f90` opens the log, reads `config.nml`, allocates the five
   shared variable namespaces, and calls `prepare_simulation`. Static input
   loading initially reads a routing value for each catchment from `mini.gtp`.
   The runner then replaces the entire `routing_method` array with the global
   `routing_mode` from `config.nml`; the current executable therefore runs all
   catchments with one routing method. Catchment time-of-concentration and
   Muskingum-Cunge parameters are calculated for every run. Floodplain input
   and inertial topology/table preparation occur only when the resulting
   routing mode is inertial. Meteorological inputs are then opened.
2. **Run.** `run_simulation` opens outputs. For inertial routing it clears the
   reservoir map and, when reservoir substitution is enabled, reads reservoir
   inputs. Catchment and Muskingum-Cunge state are initialized for every run;
   inertial state is additionally initialized when inertial catchments are
   present. A configured hotstart is read after these initializers. The
   scientific order within the timestep loop is documented under
   [Model processes and numerical assumptions](../model/model-processes.md).
3. **Finish.** Write modes 1 and 3 produce a final hotstart. The runner closes
   model outputs and meteorological inputs, then returns to `main.f90`, which
   deallocates the shared namespaces, reports elapsed time, and closes the log.

Hotstart calls are controlled by their configuration values, not by the
routing mode. A read restores both the water-balance payload and the inertial
payload. Write mode 1 writes only after the loop; mode 2 reads
`hotstart_schedule.txt` and calls the writer at the beginning of every
timestep; mode 3 writes at the beginning of every timestep and again after the
loop. The loaded mode-2 schedule is not currently consulted by the timestep
loop or writer. Each write emits both payloads.

This division keeps process-level concerns in the application, composition in
the runner, scientific calculations in hydrology modules, and file ownership
in I/O modules.

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
| Common utility | Common utilities only |
| Vars module | No project module |
| Hydrology module | Vars modules and common utilities |
| I/O module | Vars modules and common utilities |
| `runner` | Hydrology, I/O, vars, and common modules |
| `simulation/main.f90` | Vars, `configuration_io`, `log_io`, and `runner` |

Every project-module import requires an `only:` list. Behavioral, common, I/O,
and runner modules use default `private` visibility and explicit public APIs.
The vars modules are the sole default-public exception.

Forbidden dependencies include a vars module importing any project module,
one hydrology module importing another, scientific behavior importing I/O, and
I/O importing hydrology behavior. The application is also forbidden from
depending directly on hydrology or on static, meteorological, hotstart, and
output I/O; those dependencies are owned by `runner`. Its direct
I/O dependencies are limited to `configuration_io` and `log_io`.

## State and scientific data flow

The I/O modules populate more than one shared namespace. Configuration I/O
writes configuration values and the initial calendar state. Static input I/O
populates attributes, parameters, climatological and substitution forcing,
and selected configuration values. During reservoir loading it reads the
calendar from `state` to align reservoir observations. Meteorological I/O
refreshes the current forcing arrays. Hotstart I/O restores `state` and the
retained air temperature in `forcing`. Output I/O writes prepared serialization
buffers from `state`; it does not calculate the scientific values in those
buffers.

The direct module-variable exchange is intentional. Narrow `only:` lists show
and constrain each procedure's coupling while avoiding wrapper types or a
whole-model storage object.

The implemented data flow is:

```text
config.nml ----------> configuration_io ------> config
                              |
                              +----------------> state calendar
                                                    |
                                                    +--> reservoir date alignment

static files --------> static_input_io --------> attributes + parameters
                              |                 +-> forcing
                              +------------------> selected config
meteorological files -> meteorological_io -------> forcing
hotstart files ------> hotstart_io --------------> state + forcing air temperature

attributes + config + forcing + parameters + state
                              |
                              v
                    catchment and routing
                              |
                              v
                    evolving state and output buffers
                              |
                              +------> output_io ------> model outputs
                              +------> hotstart_io ----> hotstart files
```

Within a timestep, `catchment` writes the groundwater, subsurface, and surface
flow components. In Muskingum-Cunge mode, the Muskingum routine consumes those
components directly before the runner performs its common lateral-flow sum. In
inertial mode, the runner first stores that sum in `catchment_q_current`, which
the inertial continuity calculation then consumes. Both routing implementations
place routed discharge in `inertial_q`; the runner copies it and other
hydraulic values into the output buffers before calling `output_io`.

`attributes`, `config`, and most of `parameters` are prepared before the time
loop. `forcing` is refreshed as meteorological records are read. `state`
contains evolving values and output buffers carried between calculations and
timesteps. I/O and hydrology procedures mutate the owning namespaces rather
than introducing a second model storage object.

## Architecture enforcement

The policy checker can be run from the repository root:

```bash
python3 scripts/check_fortran_architecture.py
```

The checker enforces approved module names and paths, a single application
program, contained project procedures, `implicit none`, visibility rules,
explicit `only:` imports, the dependency table above, and the prohibition on
named types in vars modules. Focused checker tests are under
`tests/architecture` and the check is also registered with CTest. The
contribution guide defines when contributors should run these checks.
