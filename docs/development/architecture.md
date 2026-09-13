# Architecture

MGB is a single Fortran executable organized around hydrological behavior,
shared model variables, centralized I/O, simulation orchestration, and common
utilities. The organization preserves the legacy model's module-global storage
while making the purpose of each shared variable explicit.

## Source tree

```text
src/
├── application/
│   └── main.f90
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
├── simulation/
│   └── simulation_runner.f90
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
storage-specific initialization procedures remain in the module that owns the
affected variables. Required dimensions are passed as scalar arguments, so
the variable modules do not depend on one another.

### Hydrology

| Module | Responsibility | Public API |
| --- | --- | --- |
| `catchment` | Evapotranspiration, interception, HRU water balance, catchment aggregation, and terrestrial linear reservoirs | `calculate_catchment_time_of_concentration`, `initialize_catchment`, `update_catchment` |
| `river_muskingum` | Muskingum-Cunge parameter preparation, initialization, and network routing | `calculate_muskingum_cunge_parameters`, `initialize_muskingum_cunge_routing`, `route_muskingum_cunge_network` |
| `river_inertial` | Inertial topology/table preparation, initialization, and routing | `prepare_inertial_routing`, `initialize_inertial_routing`, `route_inertial_flow` |
| `reservoirs` | Initialization required by the existing reservoir and substitution behavior | `initialize_reservoir_state` |

The evapotranspiration kernel is private to `catchment`, preserving the legacy
per-HRU calculation order without creating a hidden call between hydrology
modules. Hydrology modules do not import one another; the simulation and
application layers coordinate their public entry points.

### Composition and I/O

`main.f90` owns the visible application lifecycle: read configuration,
allocate and deallocate variables, report the configuration, handle the
interactive prompts, measure elapsed time, and report final status. It calls
`simulation_runner` for hydrology preparation and runtime simulation.

`simulation_runner` owns catchment and static-input loading, routing and
hydrology preparation, meteorological-input opening, and the timestep and
hotstart sequence. It also closes the meteorological and model-output files
after the run. The I/O modules retain ownership of all model files and
serialize variables from the five shared namespaces without changing external
formats. `log_io` owns the model log; `output_io` owns model-output files and
records.

## Dependency direction

```text
application/main
        |
        v
simulation_runner ------> hydrology and centralized runtime I/O
        |
        +-----------------> hydrology behavior ------> vars + common utilities

application/main -------> vars, configuration_io, and log_io
```

Allowed project dependencies are:

| Consumer | May use |
| --- | --- |
| Common utility | Common utilities only |
| Vars module | No project module |
| Hydrology module | Vars modules and common utilities |
| I/O module | Vars modules and common utilities |
| `simulation_runner` | Hydrology, I/O, vars, and common modules |
| `application/main.f90` | Vars, `configuration_io`, `log_io`, and `simulation_runner` |

Every project-module import requires an `only:` list. Behavioral, common, I/O,
and runner modules use default `private` visibility and explicit public APIs.
The vars modules are the sole default-public exception.

Forbidden dependencies include a vars module importing any project module,
one hydrology module importing another, scientific behavior importing I/O, and
I/O importing hydrology behavior. The application is also forbidden from
depending directly on hydrology or runtime-I/O modules; those dependencies are
owned by `simulation_runner`.

## Scientific data flow

Meteorological I/O updates `forcing`. Catchment processing reads forcing,
parameters, configuration, and retained state, then updates catchment state and
diagnostics. The runner invokes the routing implementations in the established
order. River processing consumes catchment-generated flow and updates shared
river state. Output and hotstart I/O serialize selected values without owning
scientific storage.

The direct module-variable exchange is intentional. Narrow `only:` lists show
and constrain each procedure's coupling while avoiding wrapper types or a
whole-model storage object.

## Architecture enforcement

Run the policy checker from the repository root:

```bash
python3 scripts/check_fortran_architecture.py
```

The checker enforces approved module names and paths, a single application
program, contained project procedures, `implicit none`, visibility rules,
explicit `only:` imports, the dependency table above, and the prohibition on
named types in vars modules. Focused checker tests are under
`tests/architecture` and the check is also registered with CTest.
