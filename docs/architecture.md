# Architecture

The source tree separates application orchestration, runtime I/O, scientific
behavior, and domain-owned module state. This structure gives every project
procedure an explicit interface while preserving the model's module-global
storage and numerical execution order.

```text
src/
├── application/main.f90
├── common/{date_time,interpolation,runtime_support}.f90
├── simulation/{simulation_state,simulation_runner}.f90
├── catchment/{catchment_state,meteorological_state,water_balance_state,
│             catchment_hydrology}.f90
├── reservoirs/reservoir_state.f90
├── routing/muskingum/{muskingum_state,muskingum_cunge_routing}.f90
├── routing/inertial/{inertial_state,inertial_routing}.f90
└── io/{io_state,output_state,configuration_io,static_input_io,
       meteorological_io,hotstart_io,output_io}.f90
```

## Responsibilities and public APIs

| Module | Responsibility | Public behavior/lifecycle API |
| --- | --- | --- |
| `date_time` | Calendar conversion and timestep counting | Date parse/format, Julian conversion, `calculate_timestep_count` |
| `interpolation` | Generic linear interpolation | `linear_interpolate` |
| `runtime_support` | Legacy runtime helpers | `initialize_random_seed`, `update_legacy_timer` |
| `simulation_state` | Calendar, timestep, and run-range state | State declarations |
| `simulation_runner` | Simulation initialization and timestep loop | `run_simulation` |
| `catchment_state` | Catchment geometry, topology, HRU identity, and counts | State declarations, allocate/deallocate APIs |
| `meteorological_state` | Forcing options, climatology, and current forcing | State declarations, allocate/deallocate APIs |
| `water_balance_state` | Parameters, stores, fluxes, ET, and lateral flow | State declarations, allocate/deallocate APIs |
| `catchment_hydrology` | Parameter preparation and vertical water balance | `calculate_catchment_time_of_concentration`, `initialize_catchment_hydrology`, `update_catchment_hydrology` |
| `reservoir_state` | Prescribed flows and reservoir substitution | State declarations, allocate/initialize/deallocate APIs |
| `muskingum_state` | Muskingum-Cunge parameters and route state | State declarations, allocate/deallocate APIs |
| `muskingum_cunge_routing` | Muskingum-Cunge preparation and routing | Calculate, initialize, and network-route APIs |
| `inertial_state` | Inertial configuration, topology, tables, and hydraulic state | State declarations, allocate/deallocate APIs |
| `inertial_routing` | Inertial preparation and routing | `prepare_inertial_routing`, `initialize_inertial_routing`, `route_inertial_flow` |
| `io_state` | Runtime directories, units, and format work fields | State declarations |
| `output_state` | Output flags, buffers, and hotstart controls | State declarations, allocate/deallocate APIs |
| `configuration_io` | Configuration namelist ownership | `read_model_configuration` |
| `static_input_io` | Static parameter, catchment, floodplain, and reservoir files | Grouped catchment, floodplain, and reservoir read APIs |
| `meteorological_io` | Forcing-file lifecycle and timestep reads | Open, read, and close APIs |
| `hotstart_io` | Hotstart vectors, schedule, and files | Read, schedule-read, and write APIs |
| `output_io` | Log and model-output lifecycle | Log/output open, write, and close APIs |

State declarations are public only where existing algorithms exchange them.
Every module otherwise uses default `private`, and every project-module import
has an `only` list.

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
                       state + common utilities
```

Common modules do not depend on model state. State modules do not depend on
behavioral modules. Scientific facades may use state and common modules but not
another scientific facade or an I/O behavior module. I/O behavior modules may
use state and common modules but not scientific behavior. The runner and
application are the composition layers. The architecture checker enforces
these edges; the two narrow `catchment_state` imports used for fixed legacy
array bounds are explicit exceptions.

Water balance reads inertial routing selection and flooded area, while inertial
continuity consumes precipitation and water-balance fluxes. Both routing
implementations consume catchment-generated flow, Muskingum-Cunge consumes
open-water evaporation, and routing consumes reservoir substitution state.
These exchanges are visible in `use, only` lists rather than hidden in an
aggregating state module.

## Lifecycle

`main` owns startup and shutdown. It reads configuration, allocates state by
domain, reads static inputs, prepares routing, opens forcing inputs, and then
calls `run_simulation`. The runner opens outputs; initializes reservoir,
water-balance, Muskingum-Cunge, and inertial state in the legacy order; applies
hotstarts; runs the timestep loop; writes a final hotstart when configured; and
closes outputs. `main` then closes forcing inputs and deallocates domains in
reverse allocation order.

The timestep loop preserves the established sequence: advance the index,
handle scheduled hotstarts, update the calendar, read forcing, update catchment
hydrology, route Muskingum-Cunge when selected, assemble lateral flow, route
inertial flow, assemble output buffers, write records, and advance Julian time.

State remains module-global in this phase to avoid coupling architectural work
to scientific changes. Derived state types, state-object argument passing,
further reduction of global scratch state, and per-domain CMake targets are
deferred.
