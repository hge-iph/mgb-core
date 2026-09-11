# Architecture

MGB is organized as a single Fortran executable composed from domain modules.
The source tree separates application composition, simulation orchestration,
scientific behavior, domain-owned state, and runtime I/O. This gives every
project procedure an explicit interface while preserving the model's numerical
execution order and module-global storage.

This page describes the implemented architecture. It is both a guide to finding
code and a set of dependency and lifecycle constraints for future changes. The
[model processes](../model/model-processes.md) page describes the hydrological
and routing behavior in more detail.

## Source tree

```text
src/
├── application/
│   └── main.f90
├── common/
│   ├── date_time.f90
│   ├── interpolation.f90
│   └── runtime_support.f90
├── simulation/
│   ├── simulation_state.f90
│   └── simulation_runner.f90
├── evapotranspiration/
│   ├── evapotranspiration_state.f90
│   └── evapotranspiration_processing.f90
├── runoff/
│   ├── runoff_state.f90
│   └── runoff_processing.f90
├── reservoirs/
│   └── reservoir_state.f90
├── routing/
│   ├── muskingum/
│   │   ├── muskingum_state.f90
│   │   └── muskingum_routing.f90
│   └── inertial/
│       ├── inertial_state.f90
│       └── inertial_routing.f90
└── io/
    ├── io_state.f90
    ├── output_state.f90
    ├── configuration_io.f90
    ├── static_input_io.f90
    ├── meteorological_io.f90
    ├── hotstart_io.f90
    └── output_io.f90
```

Folders communicate ownership, but dependency classification is per module.
For example, `simulation_state` is a low-level state contract while
`simulation_runner` is a high-level orchestration module even though both are
under `src/simulation/`.

## Architectural vocabulary

The architecture uses the following roles:

- **Application composition** is the `mgb_model` program in `main.f90`. It
  visibly sequences configuration, allocation, static input, preparation,
  simulation, and shutdown.
- **Simulation orchestration** is `simulation_runner`. It coordinates domain
  initialization, the timestep loop, hotstarts, and model-output lifecycle.
- **Scientific facades** are `evapotranspiration_processing`,
  `runoff_processing`, `muskingum_routing`, and `inertial_routing`. Each
  exposes a small domain API and keeps its numerical helpers private.
- **Domain state** is held by the `*_state` modules. State remains beside its
  owning domain instead of being collected in a general state module.
- **Centralized I/O** modules own runtime model files. Scientific modules
  calculate state but do not open, read, write, or close model data files.
- **Common utilities** provide model-independent date, interpolation, and
  runtime helpers.

The model uses cohesive domain modules. This keeps related calculations behind a meaningful public boundary and avoids recreating the former flat call graph inside many nominal modules.

## Module responsibilities and APIs

Every project module has `implicit none`, default `private` visibility, and an
explicit `public` list. Every import of another project module uses an `only`
list. State declarations are public only where existing algorithms exchange
them.

### Common and simulation modules

| Module | Responsibility | Public behavior or lifecycle API |
| --- | --- | --- |
| `date_time` | Parse and format dates, convert Julian dates, and count timesteps | `format_date_string`, `parse_date_string`, `calculate_integer_julian_day`, `calculate_julian_day`, `convert_julian_day_to_calendar`, `calculate_timestep_count` |
| `interpolation` | Generic linear interpolation | `linear_interpolate` |
| `runtime_support` | Retained random-seed and legacy timer helpers | `initialize_random_seed`, `update_legacy_timer` |
| `simulation_state` | Calendar, timestep, run range, and simulation index | Public state declarations; no behavioral API |
| `simulation_runner` | Simulation initialization/finalization and the timestep loop | `run_simulation` |

### Evapotranspiration, runoff, and reservoir modules

| Module | Responsibility | Public behavior or lifecycle API |
| --- | --- | --- |
| `evapotranspiration_state` | Non-precipitation forcing, climatology, vegetation and interception state, and ET/radiation results | `allocate_evapotranspiration_state`, `deallocate_evapotranspiration_state` |
| `evapotranspiration_processing` | Radiation, interception, and evapotranspiration calculations | `calculate_evapotranspiration` |
| `runoff_state` | Catchment/HRU definition, precipitation, soil and linear-reservoir state, and generated flow | `allocate_runoff_state`, `deallocate_runoff_state` |
| `runoff_processing` | Catchment preparation, initialization, and the vertical runoff balance | `calculate_catchment_time_of_concentration`, `initialize_runoff`, `update_runoff` |
| `reservoir_state` | Prescribed gauge flows, reservoir substitution, routing overrides, and associated state | `allocate_reservoir_state`, `initialize_reservoir_state`, `deallocate_reservoir_state` |

### Routing modules

| Module | Responsibility | Public behavior or lifecycle API |
| --- | --- | --- |
| `muskingum_state` | Muskingum-Cunge parameters, boundary arrays, component fractions, and river-route state | `allocate_muskingum_state`, `deallocate_muskingum_state` |
| `muskingum_routing` | Parameter preparation, initial river state, and network routing | `calculate_muskingum_cunge_parameters`, `initialize_muskingum_cunge_routing`, `route_muskingum_cunge_network` |
| `inertial_state` | Routing configuration, floodplain topology and tables, hydraulic state, and OpenMP work state | `allocate_inertial_state`, `deallocate_inertial_state` |
| `inertial_routing` | Inertial topology/table preparation, initialization, and routing | `prepare_inertial_routing`, `initialize_inertial_routing`, `route_inertial_flow` |

### I/O modules

| Module | Responsibility | Public behavior or lifecycle API |
| --- | --- | --- |
| `io_state` | Runtime directories, file-unit constants, and retained format work fields | Public state declarations; no behavioral API |
| `output_state` | Output flags and buffers plus hotstart controls and schedule | `allocate_output_state`, `deallocate_output_state` |
| `configuration_io` | Read `config.nml` and populate owning state modules | `read_model_configuration` |
| `static_input_io` | Read static catchment, parameter, climatology, substitution, reservoir, and floodplain inputs | `read_catchment_inputs`, `read_floodplain_inputs`, `read_reservoir_inputs` |
| `meteorological_io` | Own forcing-file lifecycle and timestep reads | `open_meteorological_inputs`, `read_meteorological_forcing`, `close_meteorological_inputs` |
| `hotstart_io` | Own hotstart vectors, schedules, and files | `read_hotstart`, `read_hotstart_schedule`, `write_hotstart` |
| `output_io` | Own the log and model-output file lifecycles and writes | `open_model_log`, `open_model_outputs`, `write_model_outputs`, `close_model_outputs`, `close_model_log` |

## State ownership

| Owner | State groups |
| --- | --- |
| `simulation_state` | Timestep count/index and duration; calendar fields and Julian day; first and last simulated subbasins |
| `evapotranspiration_state` | Forcing-selection flags; climatology and station coordinates; temperature, humidity, wind, pressure, and radiation; vegetation parameters; interception storage; ET and radiation work/results; open-water evaporation |
| `runoff_state` | Entity counts; catchment/subbasin topology and geometry; HRU identity and percentages; climate-region assignment; precipitation; soil and runoff parameters; soil, surface, subsurface, and groundwater stores and fluxes; capillary and floodplain exchange; terrestrial storage |
| `reservoir_state` | Prescribed-flow series and locations; reservoir configuration, catchment maps, start timesteps, outflows, and downstream overrides |
| `muskingum_state` | Routing inputs and reach counts; celerity and concentration time; boundary and reach flows; component fractions, routing volumes, and velocity |
| `inertial_state` | Routing selection and configuration; upstream and lateral-face topology; source and derived floodplain tables; discharge, stage, depth, volume, and area; interpolation and OpenMP work state |
| `io_state` | Input, output, and hotstart directories; configuration, input, output, log, and hotstart units; retained fixed-format header fields |
| `output_state` | Output-selection flags; single-precision output and diagnostic buffers; hotstart modes and write schedule |

## Dependency direction

```text
application/main
        |
        v
simulation_runner -----> centralized I/O
        |
        +--------------> scientific facades
                               |
                               v
                       domain state + common utilities
```

The allowed project-module dependencies are:

| Consumer | May use |
| --- | --- |
| Common utility | Another explicitly required common utility; never model state |
| State module | Common utilities only, apart from the two fixed-bound exceptions below |
| Scientific facade | State modules and common utilities; `runoff_processing` may also call `evapotranspiration_processing` |
| I/O behavior module | State modules and common utilities |
| `simulation_runner` | I/O APIs, scientific facades, state modules, and common utilities |
| `application/main.f90` | Public orchestration, I/O, lifecycle, and state APIs needed to show the complete application sequence |

The two permitted state-to-state edges are
`reservoir_state -> runoff_state` and `io_state -> runoff_state`. Both
import fixed legacy capacity bounds from `runoff_state`; they are explicit,
narrow exceptions.
When an allocation needs dimensions owned elsewhere, its lifecycle procedure
normally receives scalar dimensions as arguments.

Forbidden dependencies include:

- one scientific facade calling another scientific facade, except for the
  explicit `runoff_processing -> evapotranspiration_processing` edge;
- a state module using a behavioral module;
- a scientific facade using an I/O behavior module;
- an I/O module using a scientific facade;
- a common utility depending on model state; and
- a general state aggregator that re-exports all domain state.

The composition layers call the facades in the required order. The sole nested
scientific call preserves the legacy per-HRU sequence: runoff processing calls
evapotranspiration processing before updating soil water and generated runoff.

## Cross-domain scientific exchanges

The numerical algorithms still require deliberate exchanges across ownership
boundaries. They are exposed by `use, only` lists:

- meteorological I/O updates ET forcing state and precipitation in runoff
  state; inertial continuity also consumes precipitation directly;
- runoff processing reads routing selection and flooded area so inundated area
  can affect the terrestrial water balance;
- runoff processing supplies current soil and precipitation state to ET
  processing, then consumes the adjusted precipitation and ET demand;
- runoff processing produces surface, subsurface, and groundwater flow plus
  floodplain infiltration; ET processing produces interception,
  evapotranspiration, open-water evaporation, and potential ET;
- both routing implementations consume catchment-generated flow;
- Muskingum-Cunge routing consumes open-water evaporation and prescribed-flow
  substitution state;
- inertial routing consumes precipitation, water-balance fluxes, Muskingum
  river state needed by the mixed legacy representation, and reservoir outflow
  substitution state; and
- the runner assembles state from the producing domains into `output_state`,
  after which `output_io` writes the enabled records.

Output and hotstart I/O may read all producing state modules. This broad read
access is intentional serialization behavior.

## Architecture enforcement

Run the repository policy checker from the project root:

```bash
python scripts/check_fortran_architecture.py
```

The checker is deliberately scoped to the free-form Fortran syntax used under
`src/`. It discovers project modules before
classifying imports, so compiler modules such as `omp_lib` are not mistaken for
project dependencies.

It enforces:

- approved paths and classifications for every project module;
- exactly one program, located at `src/application/main.f90`;
- no external project subroutines or functions;
- `implicit none` in every module and the program;
- default `private` and an explicit public API in every module;
- `only` lists on every project-module import;
- the dependency rules and explicit exceptions documented above; and
- rejection of unclassified modules so new code cannot bypass the policy.

When CMake is configured with `BUILD_TESTING`, the same command is registered
with CTest as the `architecture` test. Focused checker tests are in
`tests/architecture/`; see the [testing guide](../getting-started/testing.md)
for the full validation commands.
