# Structure and Explicit Interfaces Implementation Plan

## Status

This is the implementation plan for the structure-and-interfaces work.

The change is architectural. It is intended to preserve scientific and runtime
behavior while replacing the flat collection of external procedures and the
monolithic shared-state module with cohesive Fortran modules, domain-owned
state, explicit interfaces, and an enforceable dependency direction.

## Decision record

The following decisions are settled:

- Organize procedures into cohesive, deep domain modules rather than creating
  one thin module per existing routine.
- Split global declarations by domain, but retain module-global storage. Do not
  introduce derived state types or pass a model context through procedure
  arguments in this implementation.
- Keep runtime file handling in centralized I/O modules. Scientific domain
  modules must not open, read, write, or close model data files.
- Keep state beside its owning domain instead of creating a generic `state/`
  directory.
- Use `catchment` as the ownership area and `catchment_hydrology` as the
  behavioral facade. Do not create a separate HRU domain in this implementation.
- Keep catchment geometry, HRU definitions and parameterization, meteorological
  state, and water-balance state as distinct modules under `src/catchment/`.
- Treat reservoirs and prescribed/substituted flows as a sibling domain because
  they affect catchment processing and both routing implementations.
- Move allocation, initialization, and deallocation to the domains that own the
  affected state. The application layer preserves the existing lifecycle
  sequence.
- Keep `main.f90` as a broad, readable composition point. Do not reduce it to a
  one-call wrapper.
- Put `run_simulation` and the timestep loop in one ordinary multi-procedure
  module named `simulation_runner`. `run_simulation` is public and the
  timestep-loop procedure is private.
- Consolidate related procedures into ordinary Fortran modules. Do not add
  Fortran submodules in this implementation.
- Allow scientific modules to access another domain's explicitly exported state
  where the existing algorithms exchange data. Do not allow a scientific
  behavioral facade to call another scientific behavioral facade; orchestration
  remains above them.
- Make module visibility and imports explicit with default `private`, explicit
  `public` lists, and `use ..., only: ...` for project modules.
- Add an automated architecture check and run it in CI.

## Current repository state

At the time this plan was written:

- `src/` contains 43 flat `.f90` files and approximately 5,141 lines.
- Only `model_state`, `inertial_state`, `utils_date`, and `utils_time` are
  modules. The remaining project procedures are external program units.
- Most call sites therefore rely on implicit interfaces.
- `model_state.f90` is a 421-line global module containing simulation controls,
  file units, input flags, output flags and buffers, meteorology, catchment and
  HRU data, water-balance state, Muskingum-Cunge state, reservoir state, and
  shared work variables.
- `inertial_state.f90` combines inertial configuration, topology, floodplain
  tables, dynamic state, OpenMP work variables, hotstart controls, and reservoir
  outflow.
- `allocate_model_state` allocates and deallocates state from several unrelated
  domains. `initialize_model_state` initializes water balance, river routing,
  substitution flows, and inertial routing in one procedure.
- `main.f90` is already the visible high-level startup and shutdown sequence and
  should retain that role.
- CMake uses one explicit, flat source list for the `mgb_model` executable.
- The existing Magdalena regression fixture selects inertial routing with one
  OpenMP thread. It does not exercise the Muskingum-Cunge branch, reservoir
  substitution, hotstart reading/writing, or optional meteorological series.
- The current regression manifest compares four enabled binary outputs with
  permissive numerical tolerances. For an architecture-only refactor, a
  same-compiler before/after comparison is also required.

## Scope and behavior contract

### Required changes

- Create the target source hierarchy.
- Replace external project procedures with module procedures and explicit
  interfaces.
- Split `model_state` and `inertial_state` declarations according to the
  ownership rules below.
- Move allocation, initialization, and deallocation into domain lifecycle APIs.
- Consolidate calculation routines behind small public domain APIs.
- Centralize runtime file ownership in I/O modules.
- Update CMake, documentation, and CI for the new structure.
- Add regression coverage for the Muskingum-Cunge route before restructuring
  that route.
- Add and test an automated dependency checker.

### Preserved behavior

The implementation must preserve:

- hydrological and routing equations;
- expression and statement order inside numerical procedures;
- timestep ordering and all branch conditions;
- single- and double-precision declarations;
- array rank, bounds, shape, allocation size, and element ordering;
- module-global `save` semantics;
- OpenMP regions, clauses, and shared/private behavior;
- procedure dummy-argument order, type, kind, and shape for numerical helpers;
- initialization values and their order;
- input and output filenames;
- namelist groups and keys;
- text formats, direct-access record lengths, binary layouts, and record order;
- hotstart vector composition and ordering;
- console and log message ordering where practical;
- the `MGB_NONINTERACTIVE` behavior; and
- the executable target and output name, `mgb_model`.

### Explicit non-goals

This PR must not:

- introduce derived state types;
- pass state objects through the call tree;
- localize global scratch variables merely to improve style;
- change numerical kinds or replace legacy kind syntax as part of the move;
- change algorithms, equations, thresholds, constants, units, or operation
  order;
- redesign runtime formats or add compatibility aliases;
- make hydrological naming changes unrelated to the module move;
- add Fortran submodules;
- claim support for a compiler or platform not already validated;
- split HRU declarations into a separate domain; or
- turn each source folder into a separate CMake library in this implementation.

Compiler errors exposed by explicit interfaces are evidence of a pre-existing
contract problem. They are not permission to alter an algorithm silently. Stop,
record the exact mismatch, and choose a behavior-preserving wrapper or move the
correction to a separately justified change.

## Target source tree

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
├── catchment/
│   ├── catchment_state.f90
│   ├── meteorological_state.f90
│   ├── water_balance_state.f90
│   └── catchment_hydrology.f90
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
In particular, `simulation_state` is a low-level state contract while
`simulation_runner` is high-level simulation orchestration even though they
share a folder. In this plan, the model is the MGB model itself, a simulation
is execution of that model over time, and the application owns startup,
shutdown, and top-level orchestration.

## Module responsibilities and public APIs

Every module must contain `implicit none`, use default `private`, and list its
public entities explicitly. Existing state symbols remain module variables; no
state symbol should be renamed solely because it moves.

### Common modules

| Module | Responsibility | Public API |
| --- | --- | --- |
| `date_time` | Date parsing, formatting, Julian conversion, and timestep count | `format_date_string`, `parse_date_string`, `calculate_integer_julian_day`, `calculate_julian_day`, `convert_julian_day_to_calendar`, `calculate_timestep_count` |
| `interpolation` | Generic linear interpolation | `linear_interpolate` |
| `runtime_support` | Existing random-seed and legacy timer utilities | `initialize_random_seed`, `update_legacy_timer` |

`interpolate_stage_area` is not a generic utility. It becomes a private
procedure of `inertial_routing` because it embeds the floodplain table's
upper-bound extrapolation behavior.

The currently uncalled runtime-support routines remain available as explicit
module procedures. Removing them is a separate code-hygiene decision.

### Simulation modules

| Module | Responsibility | Public API |
| --- | --- | --- |
| `simulation_state` | Shared calendar, timestep, run-range, and simulation-index state | Explicitly listed state declarations; no behavioral facade |
| `simulation_runner` | Simulation initialization/finalization and the timestep loop | `run_simulation` |

`run_timestep_loop` becomes a private procedure inside `simulation_runner`. Its
existing timestep operation order remains unchanged.

### Catchment modules

| Module | Responsibility | Public API |
| --- | --- | --- |
| `catchment_state` | Catchment/subbasin/HRU counts; catchment geometry, topology, HRU composition, and static parameter identity | State declarations, `allocate_catchment_state`, `deallocate_catchment_state` |
| `meteorological_state` | Forcing options, monthly climatology, current forcing arrays, and previous temperature | State declarations, `allocate_meteorological_state`, `deallocate_meteorological_state` |
| `water_balance_state` | Soil/vegetation parameters, dynamic stores and fluxes, ET/radiation work state, catchment-generated flow, and floodplain exchange state | State declarations, `allocate_water_balance_state`, `deallocate_water_balance_state` |
| `catchment_hydrology` | Catchment parameter preparation and vertical water-balance behavior | `calculate_catchment_time_of_concentration`, `initialize_catchment_hydrology`, `update_catchment_hydrology` |

Inside `catchment_hydrology`, the following existing procedures become
private module procedures:

- `calculate_net_radiation`;
- `calculate_evapotranspiration`; and
- `update_soil_water_balance`.

The private numerical procedures retain their current dummy lists and argument
ordering. No conversion to state-object arguments is permitted.

HRU names, HRU percentages, and HRU-indexed parameter tables stay within the
catchment ownership area. This PR does not create `src/hru/`.

### Reservoir state

| Module | Responsibility | Public API |
| --- | --- | --- |
| `reservoir_state` | Gauge substitution, reservoir configuration, outflow series, routing overrides, and associated lifecycle | State declarations, `allocate_reservoir_state`, `initialize_reservoir_state`, `deallocate_reservoir_state` |

This module owns both prescribed gauge flows and reservoir outflow substitution
because both alter the flow handed to routing. Reading their runtime files
remains the responsibility of `static_input_io`.

### Routing modules

| Module | Responsibility | Public API |
| --- | --- | --- |
| `muskingum_state` | Muskingum-Cunge parameters, boundary arrays, network flow state, component fractions, and lifecycle | State declarations, `allocate_muskingum_state`, `deallocate_muskingum_state` |
| `muskingum_routing` | Parameter preparation, initial river state, and network routing | `calculate_muskingum_cunge_parameters`, `initialize_muskingum_cunge_routing`, `route_muskingum_cunge_network` |
| `inertial_state` | Routing selection, inertial configuration, floodplain topology/tables, dynamic hydraulic state, OpenMP work state, and lifecycle | State declarations, `allocate_inertial_state`, `deallocate_inertial_state` |
| `inertial_routing` | Inertial route preparation, initialization, and execution | `prepare_inertial_routing`, `initialize_inertial_routing`, `route_inertial_flow` |

`route_muskingum_cunge` becomes private inside `muskingum_routing`.

The following become private inside `inertial_routing`:

- `build_flood_topology`;
- `build_floodplain_tables`;
- `calculate_inertial_timestep`;
- `calculate_inertial_discharge`;
- `update_inertial_continuity`; and
- `interpolate_stage_area`.

`prepare_inertial_routing` preserves the current ordering of topology building,
table building, and initialization of the reservoir-specific downstream map.
It does not read files; the required floodplain data must already have been
loaded by `static_input_io`.

### I/O modules

| Module | Responsibility | Public API |
| --- | --- | --- |
| `io_state` | Runtime directories, file-unit constants, and retained I/O work state | Explicitly listed state declarations |
| `output_state` | Output-selection flags, output record buffers, and hotstart schedule/control | State declarations, `allocate_output_state`, `deallocate_output_state` |
| `configuration_io` | Parse `config.nml` and populate owning state modules | `read_model_configuration` |
| `static_input_io` | Read static catchment, parameter, climatology, substitution, reservoir, and floodplain inputs | `read_catchment_inputs`, `read_floodplain_inputs`, `read_reservoir_inputs` |
| `meteorological_io` | Own forcing-file lifecycle and per-timestep reads | `open_meteorological_inputs`, `read_meteorological_forcing`, `close_meteorological_inputs` |
| `hotstart_io` | Own hotstart vectors, schedule, and files | `read_hotstart`, `read_hotstart_schedule`, `write_hotstart` |
| `output_io` | Own log and model-output file lifecycles and record writes | `open_model_log`, `open_model_outputs`, `write_model_outputs`, `close_model_outputs`, `close_model_log` |

Individual static-format readers become private procedures of
`static_input_io`. The public operations group them by the points at which the
application can safely call them without changing current ordering:

- `read_catchment_inputs` performs the current fixed-parameter, calibrated-
  parameter, catchment, climatology, and optional gauge-substitution reads;
- `read_floodplain_inputs` performs the currently selected floodplain read; and
- `read_reservoir_inputs` performs the conditional reservoir configuration and
  outflow reads at simulation startup.

The existing text floodplain reader remains a private implementation procedure
and is not activated by this refactor.

The integer action switches currently used by meteorological and output file
managers are hidden behind explicit open/close public procedures. Their bodies
may retain a private action-based helper during the move if that best preserves
the exact file operation order.

Centralized I/O means ownership of runtime model files. Console diagnostics,
application log messages written to the already-open log unit, and interactive
startup reads may remain in `main` or `simulation_runner` to preserve the current
user-visible sequence. Scientific modules must not acquire ownership of a file.

## State ownership ledger

Declarations must move without changes to name, type, kind, rank, bounds,
allocation shape, or initial value. The groups below are authoritative for the
move; ambiguous individual work variables remain with the procedure that uses
them rather than being redesigned.

| Owner | Declaration groups |
| --- | --- |
| `simulation_state` | Timestep count/index, model timestep, calendar fields, Julian day, and first/last simulated subbasin controls |
| `catchment_state` | Capacity limits for catchments/HRUs/subbasins; entity counts; catchment and subbasin indices; catchment/subbasin relationships; drainage network; catchment area and coordinates; reach geometry; HRU names and percentages; climate-region assignment; catchment ordering; catchments per subbasin |
| `meteorological_state` | Forcing-selection flags; monthly radiation option; climate-station coordinates; monthly meteorological arrays; current precipitation, temperature, radiation, humidity, wind, and pressure; previous air temperature |
| `water_balance_state` | Soil and vegetation parameter tables; linear-reservoir coefficients; soil/interception and surface/subsurface/groundwater stores; corresponding fluxes; evapotranspiration, radiation, capillary, delay, and terrestrial-water-storage state; current-procedure work variables; open-water evaporation; potential ET; floodplain infiltration exchanged with inertial routing; catchment-generated lateral flow |
| `reservoir_state` | Substitution count/catchments/series/enabled flags; reservoir count and enable flag; reservoir-to-catchment maps; start timesteps; reservoir outflow; routing downstream overrides |
| `muskingum_state` | Maximum reach capacity; Manning/reference-flow routing inputs; reach counts and timesteps; celerity/concentration time; incoming/outgoing river flow; boundary arrays; component fractions; initial river flow; routed velocity state |
| `inertial_state` | Routing mode selection and count; Courant/thread/boundary settings; inertial Manning values; upstream topology; floodplain source tables and derived tables; inertial discharge; stage, depth, volume, and area state; lateral-face state; interpolation indices; OpenMP work variables; inertial hotstart comparison state |
| `io_state` | Input/output/hotstart directories; configuration, input, output, log, and hotstart unit constants; fixed-format header work fields that remain global |
| `output_state` | Output flags; single-precision record buffers and diagnostic buffers; hotstart read/write modes and schedule |

Specific cross-domain exchanges are expected and must be visible in `use,
only` lists:

- water balance reads inertial routing selection and flooded area;
- water balance writes floodplain infiltration and potential open-water ET;
- inertial continuity consumes water-balance fluxes and meteorological
  precipitation;
- both routing implementations consume catchment-generated flow;
- Muskingum-Cunge consumes open-water evaporation;
- routing consumes reservoir/substitution state; and
- output I/O reads state from all producing domains.

These exchanges do not justify adding a generic coupling-state module in this
implementation.

## Dependency direction

### Allowed layers

```text
application/main
        |
        v
simulation_runner
        |
        +----------> centralized I/O modules
        |
        +----------> scientific domain facades
                             |
                             v
                  state contracts + common utilities
```

### Allowed dependency matrix

| Consumer | May use |
| --- | --- |
| `common/*` | No project modules, or another explicitly allowed common utility |
| `*_state` | Common constants/utilities only; allocation sizes are passed as scalar arguments when the owner does not already hold them |
| `catchment_hydrology` | State modules and common utilities |
| `muskingum_routing` | State modules and common utilities |
| `inertial_routing` | State modules, common utilities, and compiler/OpenMP modules |
| I/O behavior modules | State modules and common utilities; never scientific behavior modules |
| `simulation_runner` | I/O APIs, scientific domain APIs, state modules, and common utilities |
| `application/main.f90` | Public orchestration, I/O, lifecycle, and state APIs required to show the high-level run sequence |

Forbidden edges include:

- one scientific behavioral facade using or calling another scientific
  behavioral facade;
- a state module using a behavioral module;
- a scientific behavioral module using an I/O behavioral module;
- an I/O module using a scientific behavioral module;
- a common module depending on model state; and
- reintroducing a general state aggregator that re-exports all domain state.

The application layer is the only place that sequences catchment behavior,
Muskingum-Cunge routing, inertial routing, hotstarts, and output writing.

## Lifecycle sequence

### Configuration and allocation in `main`

Preserve the current high-level sequence while replacing the monolithic
allocator with owner APIs:

1. Initialize timing, non-interactive mode, and runtime directories.
2. Open the model log through `output_io`.
3. Read configuration through `configuration_io`.
4. Allocate catchment state.
5. Allocate meteorological state.
6. Allocate water-balance state.
7. Allocate reservoir/substitution state.
8. Allocate Muskingum-Cunge state.
9. Allocate inertial state.
10. Allocate output and hotstart-control state.
11. Read catchment/static inputs.
12. Establish the current routing selection exactly as today.
13. Read floodplain inputs when inertial routing is selected.
14. Calculate catchment and Muskingum-Cunge parameters.
15. Prepare inertial topology/tables when selected.
16. Open meteorological inputs.
17. Emit the existing run summary and confirmation prompt.
18. Call `run_simulation`.

Allocation procedures accept required dimensions as scalar arguments if those
dimensions belong to another state module. This keeps state modules from
depending on each other. Every allocation must retain its current dimensions
and bounds.

### Initialization orchestration in `run_simulation`

`run_simulation` is the public simulation orchestrator: it opens simulation
outputs, invokes domain initialization APIs in the required order, enters
`run_timestep_loop`, and performs final simulation output and closure. It does
not replace the assignment sequence from `initialize_model_state` with a new
ordering.

Extract the assignment groups from `initialize_model_state` into the owning
initialization procedures while preserving their original order:

1. Open enabled model outputs.
2. Initialize reservoir maps and read reservoir inputs when enabled.
3. Initialize water-balance stores and generated-flow state.
4. Initialize Muskingum-Cunge river and boundary state, including prescribed
   flow handling.
5. Initialize inertial state when inertial catchments are present.
6. Read hotstart state when configured.
7. Read the hotstart schedule when configured.
8. Enter the timestep loop.
9. Write the final hotstart when configured.
10. Close model outputs.

The extracted assignment sequence must follow the existing statement order in
`initialize_model_state.f90`: water-balance initialization first, river-network
initialization second, and inertial initialization last. This preserved order
is an implementation constraint inside the orchestration above, not a change
to the meaning of `run_simulation`.

### Timestep order

The private `run_timestep_loop` procedure retains this exact order:

1. Advance timestep index.
2. Perform scheduled hotstart output.
3. Convert and report the current date.
4. Preserve previous temperature and read forcing.
5. Update catchment water balance.
6. Route Muskingum-Cunge when selected.
7. Assemble catchment lateral inflow.
8. Route inertial flow when present.
9. Assemble single-precision output records.
10. Write output records.
11. Advance Julian time.

No calculation may move across one of these boundaries.

### Shutdown in `main`

1. Close meteorological inputs.
2. Deallocate output state.
3. Deallocate inertial state.
4. Deallocate Muskingum-Cunge state.
5. Deallocate reservoir state, including conditionally allocated outflow.
6. Deallocate water-balance state.
7. Deallocate meteorological state.
8. Deallocate catchment state.
9. Emit final timing messages.
10. Close the model log and perform the existing interactive exit handling.

Deallocation should be the reverse of allocation and must use `allocated()`
guards for conditionally allocated arrays. Symmetric shutdown fixes only
process-end resource ownership; it must occur after all model outputs are
complete and must not change numerical results.

## Existing-source migration ledger

| Current source | Target module/file | Treatment |
| --- | --- | --- |
| `main.f90` | `application/main.f90` | Retain broad startup/shutdown orchestration; replace unrestricted state imports with explicit APIs/state imports |
| `run_simulation.f90`, `run_model.f90` | `simulation/simulation_runner.f90` | Public `run_simulation`; private `run_timestep_loop` |
| `model_state.f90` | Domain state files | Split declarations mechanically according to the ownership ledger; remove the aggregator |
| `allocate_model_state.f90` | Domain state files | Split allocation/deallocation by owner; replace action switch with explicit lifecycle APIs |
| `initialize_model_state.f90` | Catchment and routing facades | Split initialization in existing statement order |
| `utils_date.f90`, `utils_time.f90` | `common/date_time.f90` | Consolidate existing module procedures and preserve signatures |
| `linear_interpolate.f90` | `common/interpolation.f90` | Convert the external function to a public module procedure |
| `initialize_random_seed.f90`, `update_legacy_timer.f90` | `common/runtime_support.f90` | Convert existing external utilities to public module procedures |
| `calculate_catchment_time_of_concentration.f90` | `catchment/catchment_hydrology.f90` | Public preparation procedure |
| `update_catchment_hydrology.f90` | `catchment/catchment_hydrology.f90` | Public timestep procedure |
| `update_soil_water_balance.f90` | `catchment/catchment_hydrology.f90` | Private numerical helper |
| `calculate_evapotranspiration.f90` | `catchment/catchment_hydrology.f90` | Private numerical helper |
| `calculate_net_radiation.f90` | `catchment/catchment_hydrology.f90` | Private numerical helper |
| `calculate_muskingum_cunge_parameters.f90` | `routing/muskingum/muskingum_routing.f90` | Public preparation procedure |
| `route_muskingum_cunge_network.f90` | `routing/muskingum/muskingum_routing.f90` | Public network procedure |
| `route_muskingum_cunge.f90` | `routing/muskingum/muskingum_routing.f90` | Private reach helper |
| `inertial_state.f90`, `allocate_inertial_state.f90` | `routing/inertial/inertial_state.f90` | Split non-inertial declarations out; add explicit allocation/deallocation APIs |
| `build_flood_topology.f90`, `build_floodplain_tables.f90` | `routing/inertial/inertial_routing.f90` | Private preparation helpers |
| `initialize_inertial_routing.f90` | `routing/inertial/inertial_routing.f90` | Public initialization procedure |
| `route_inertial_flow.f90` | `routing/inertial/inertial_routing.f90` | Public route procedure |
| `calculate_inertial_timestep.f90`, `calculate_inertial_discharge.f90`, `update_inertial_continuity.f90` | `routing/inertial/inertial_routing.f90` | Private numerical helpers |
| `interpolate_stage_area.f90` | `routing/inertial/inertial_routing.f90` | Private floodplain interpolation helper |
| `read_model_configuration.f90` | `io/configuration_io.f90` | Public configuration API |
| `read_fixed_parameters.f90`, `read_calibrated_parameters.f90`, `read_catchment_data.f90`, `read_climatology.f90`, `read_substitution_flows.f90` | `io/static_input_io.f90` | Private format readers behind `read_catchment_inputs` |
| `read_floodplain_binary_data.f90`, `read_floodplain_text_data.f90` | `io/static_input_io.f90` | Private readers behind `read_floodplain_inputs`; do not activate the text path |
| `read_reservoir_data.f90` | `io/static_input_io.f90` | Private reader behind `read_reservoir_inputs` |
| `manage_meteorological_input_files.f90`, `read_meteorological_forcing.f90` | `io/meteorological_io.f90` | Explicit open/read/close public API |
| `read_hotstart.f90`, `write_hotstart.f90` | `io/hotstart_io.f90` | Public hotstart read/write; move schedule file ownership here |
| `write_model_outputs.f90` | `io/output_io.f90` | Explicit log/output open/write/close API |

Use pure file moves before consolidation where practical. Do not mix numerical
edits into consolidation stages.

## CMake changes

- Retain a single `mgb_model` executable target and its existing output name.
- Retain the current Intel compiler gate, release flags, OpenMP/MKL bootstrap,
  module output directory, and regression command.
- Replace `MGB_MODEL_SOURCES` with domain-grouped source variables, for example
  `MGB_COMMON_SOURCES`, `MGB_CATCHMENT_SOURCES`, `MGB_ROUTING_SOURCES`,
  `MGB_IO_SOURCES`, and `MGB_APPLICATION_SOURCES`, then compose the executable
  from them.
- Keep source paths explicit; do not use recursive globbing.
- Let CMake's Fortran dependency scanner determine compilation order rather than
  encoding a hand-maintained pseudo-order in the list.
- Do not create per-domain static/object libraries in this implementation. The existing
  state exchange would make their link graph more complicated than the source
  architecture, while the automated dependency check provides the intended
  boundary enforcement.
- Register the architecture checker as a CTest test when `BUILD_TESTING` and a
  Python interpreter are available.

Nested paths must be validated on both the Windows and Linux CMake generators
used by the project.

## Automated architecture check

Add `scripts/check_fortran_architecture.py`, implemented with the Python
standard library, plus focused parser/checker tests under
`tests/architecture/`.

The checker must:

1. Discover `.f90` files recursively below `src/`.
2. Parse module, program, contained-procedure, visibility, and `use` statements
   case-insensitively, including free-form continuation lines.
3. Build the set of project modules before evaluating imports so external
   compiler modules can be distinguished from project dependencies.
4. Verify every source is in an approved architectural path.
5. Verify there is exactly one program and that it is
   `application/main.f90`.
6. Reject project subroutines/functions that remain external rather than being
   contained in a module.
7. Require `implicit none` in each project module and program.
8. Require default `private` and an explicit public API in every module.
9. Require `only` lists on every project-module import.
10. Evaluate project-module edges against an explicit allowlist implementing
    the dependency matrix in this plan.
11. Reject an unclassified project module so additions cannot bypass the
    architecture accidentally.
12. Print actionable failures containing source path, line, dependency, and the
    violated rule.

Tests must cover at least:

- mixed-case Fortran keywords and names;
- continued `use, only` statements;
- `use, intrinsic` and compiler modules;
- a permitted state dependency;
- a forbidden facade-to-facade dependency;
- an unrestricted project `use`;
- a missing default-private declaration; and
- an external procedure.

Run the script directly in the existing Fortran-format CI workflow so it does
not depend on an Intel compiler runner. Also register it with CTest for local
developer discovery. Update `docs/testing.md` and `docs/fortran-style.md` with
the command:

```bash
python scripts/check_fortran_architecture.py
```

The checker is a policy check for this repository, not a general Fortran
parser. Its supported source syntax and external-module exceptions must be
documented in its module docstring and tests.

## Documentation changes

Add a durable `docs/architecture.md` and include it in `mkdocs.yml`. It must
contain:

- the final source tree;
- a concise responsibility statement for each module;
- the public API table;
- the dependency diagram and allowed-edge rules;
- the reason state remains module-global in this phase;
- the scientific state exchanges between water balance and routing;
- lifecycle ownership and the application sequence; and
- explicit deferred work: derived state types, argument passing, further
  global-state reduction, and CMake component targets.

Also update:

- `README.md` if it describes source layout or developer validation;
- `docs/fortran-style.md` for default-private modules and `use, only`;
- `docs/io-reference.md` with the final module ownership of every runtime file;
- `docs/model-processes.md` only where procedure/module names or ownership have
  changed, without rewriting the documented numerical order;
- `docs/testing.md` for the architecture check and added routing regression;
- `docs/build.md` if the CTest inventory or commands change;
- `.dev/plans/cleanup_roadmap.md` to record that the structure-and-interfaces
  phase was incorporated into the implementation scope.

The existing migration and legacy-header ledgers remain separate concerns and
must stay accurate after file consolidation.

## Regression preparation

### Freeze the pre-refactor baseline

Before moving source:

1. Configure and build the pre-refactor implementation with a validated Intel `ifx`
   environment.
2. Run `regression_magdalena` successfully.
3. Preserve the generated enabled output files outside the build/runtime tree.
4. Record SHA-256 hashes for `discharge.bin`, `level.bin`,
   `total_water_storage.bin`, and `flooded_area.bin`.
5. Record OS, compiler version, CMake version, configure command, build command,
   test command, and thread count in the validation record.

This baseline is in addition to the expected fixtures. It detects
changes hidden by the current regression tolerances.

### Add Muskingum-Cunge coverage first

The consolidation moves all Muskingum-Cunge procedures and must not rely on
compile coverage alone. Before restructuring that module:

1. Add a Magdalena regression variant using the current code and
   `routing_mode = 0`.
2. Keep its remaining input, output selection, and numerical data unchanged
   unless the route requires an explicitly documented fixture adjustment.
3. Capture expected output with the validated pre-refactor Intel `ifx` build.
4. Review record counts, sizes, and finite values before accepting the new
   baseline.
5. Register it as a separate CTest, for example
   `regression_magdalena_muskingum`.
6. Do not update its expected output after structural work begins.

If the existing fixture cannot exercise Muskingum-Cunge without a model or
input reinterpretation, stop and document that limitation rather than inventing
new hydrological data in this implementation.

Reservoir, hotstart, and optional-forcing paths remain coverage gaps unless
valid existing inputs can exercise them without broadening the fixture. Their
module moves still require compile/interface validation and a documented
residual risk.

## Implementation sequence

Each numbered phase should be a reviewable implementation stage. Build and run
the available routing regressions after every phase that changes Fortran source
or CMake.

### Phase 0: Baseline and test coverage

- Complete the pending Linux `ifx` regression evidence.
- Freeze exact before-refactor output hashes.
- Add and validate the Muskingum-Cunge regression variant.
Exit criterion: both routing modes have accepted pre-refactor baselines, or the
plan is paused with an explicit coverage blocker.

### Phase 1: Directory-only source movement

- Create the target directory hierarchy.
- Move files with unambiguous one-to-one owners to their future areas without
  consolidating or editing procedure bodies. Leave cross-domain sources such as
  `model_state.f90`, `allocate_model_state.f90`, and
  `initialize_model_state.f90` in place until the atomic split phases that
  remove them.
- Update only source paths and grouping in CMake.
- Build and run both routing regressions.

Exit criterion: directory moves alone produce no generated-output hash change.

### Phase 2: Common explicit interfaces

- Consolidate date/time utilities into `date_time`.
- Convert linear interpolation to the `interpolation` module.
- Consolidate timer/seed helpers into `runtime_support`.
- Update consumers with `use, only`.
- Remove external function declarations made obsolete by module interfaces.

Exit criterion: all common utilities are module procedures and both routing
regressions remain unchanged.

### Phase 3: State partition and lifecycle allocation

- Create all target state modules.
- Move declarations from `model_state` and `inertial_state` without renaming or
  changing declarations.
- Add default-private and explicit public lists.
- Split allocation/deallocation into owner APIs with unchanged shapes.
- Update every consumer in one atomic state-migration change using explicit
  `use, only` lists.
- Delete `model_state` only after no consumer imports it.
- Do not leave a compatibility aggregator in the final tree.

Exit criterion: the complete executable builds with no unrestricted project
state imports, lifecycle allocation is symmetric, and both routing baselines
are unchanged.

### Phase 4: Catchment module consolidation

- Create `catchment_hydrology`.
- Move the public preparation/update procedures and private soil, ET, and
  radiation helpers under one `contains` section.
- Split the water-balance part of `initialize_model_state` into
  `initialize_catchment_hydrology` without reordering assignments.
- Preserve all numerical helper dummy contracts.

Exit criterion: no external catchment calculation procedure remains and both
routing baselines are unchanged.

### Phase 5: Routing module consolidation

- Create `muskingum_routing`; make the reach solver private.
- Move the river-routing part of initialization into
  `initialize_muskingum_cunge_routing`.
- Create `inertial_routing`; make numerical and topology helpers private.
- Add `prepare_inertial_routing` as the public topology/table operation called
  from main.
- Preserve OpenMP directives and variable data-sharing semantics exactly.
- Remove unused compiler-module imports only when repository/compiler evidence
  proves they are unused.

Exit criterion: all scientific route calls use explicit module interfaces,
forbidden facade-to-facade edges are absent, and both routing baselines are
unchanged.

### Phase 6: Centralized I/O consolidation

- Create `io_state` and `output_state` and move their declarations/lifecycle.
- Consolidate configuration, static input, meteorological, hotstart, and output
  routines according to the migration ledger.
- Replace public integer action switches with explicit open/close APIs while
  retaining private action helpers where useful.
- Move hotstart schedule file ownership out of `simulation_runner`.
- Move log open/close ownership out of main, while retaining application message
  ordering.
- Verify the final I/O ownership map against `docs/io-reference.md`.

Exit criterion: runtime model files are owned by I/O modules, formats and file
operation order remain unchanged, and both routing baselines are unchanged.

### Phase 7: Simulation module and broad main

- Consolidate `run_simulation` and `run_timestep_loop` into `simulation_runner`.
- Keep only `run_simulation` public.
- Update main to show configuration, domain allocation, static loading,
  preparation, simulation, shutdown, and timing explicitly.
- Replace all remaining unrestricted project imports with `use, only`.
- Confirm there is no scientific behavior in main beyond orchestration and the
  existing user interaction/log summary.

Exit criterion: all project procedures except the program are contained module
procedures and the high-level run sequence remains readable in main.

### Phase 8: Enforce and document architecture

- Add the architecture checker and its tests.
- Add the CI and CTest hooks.
- Add `docs/architecture.md` and update related documentation.
- Enable the strict check only after the final module graph satisfies it.
- Update the cleanup roadmap for the combined scope.

Exit criterion: architecture, format, documentation, build, and regression
checks pass from documented commands.

### Phase 9: Final audit

- Compare post-refactor outputs to the frozen same-compiler hashes.
- Confirm expected outputs were not modified after their pre-refactor
  baselines were accepted.
- Audit the final module/use graph with the checker and a manual spot check.
- Inspect the implementation for accidental numerical edits.
- Record Linux and Windows validation evidence.

## Validation matrix

| Check | Required evidence |
| --- | --- |
| Architecture policy | `python scripts/check_fortran_architecture.py` passes |
| Architecture checker tests | Python tests under `tests/architecture/` pass |
| Fortran formatting | Two formatter passes followed by `python scripts/check_fortran_format.py` with no diff |
| Whitespace | No unintended whitespace changes are present |
| Documentation | `python -m mkdocs build --strict` passes |
| Linux build | Documented Linux x64 Intel `ifx` configure and build pass |
| Windows build | Documented Windows x64 Intel `ifx` configure and build pass |
| Inertial regression | `regression_magdalena` passes on available validated environments |
| Muskingum regression | New Muskingum-Cunge regression passes against its pre-refactor baseline |
| Exact behavior check | Enabled binary output SHA-256 values match same-compiler pre-refactor runs |
| Fixture integrity | No expected regression output changes after structural implementation starts |
| I/O compatibility | File names, sizes, record counts, and hotstart vector layouts match the pre-refactor implementation |

The final validation record must list the exact OS, Intel compiler version,
CMake version, configure/build commands, CTest commands, and any path not
exercised.

## Review strategy

Reviewers should evaluate the change in this order:

1. Directory-only moves and source migration ledger.
2. State ownership and declarations, ignoring procedure-body movement.
3. Public APIs, privacy, and dependency edges.
4. Lifecycle allocation/initialization/deallocation ordering.
5. Numerical procedure bodies using whitespace-insensitive comparison where
   useful.
6. I/O open/read/write/close statements and record specifications.
7. CMake and automated policy checks.
8. Regression and exact-output evidence.

Large consolidated files make normal line diffs noisy. During implementation,
produce comparison evidence that extracts each old and new numerical procedure
body after formatting so reviewers can verify that only indentation, module
wrapping, and `use` statements changed.

## Risks and mitigations

### Explicit interfaces expose legacy mismatches

Mitigation: migrate one domain at a time, preserve every dummy declaration, and
treat new compiler diagnostics as investigation points. Do not add implicit
conversion or change kinds to make compilation succeed.

### State moves alter initialization or storage semantics

Mitigation: retain module `save`, move declaration initializers verbatim, keep
allocation shapes exact, and compare initialized arrays indirectly through both
routing regressions and hotstart layout review.

### Consolidation hides numerical changes

Mitigation: move files before combining them, keep numerical-body edits out of
structure stages, compare extracted procedure bodies, and require exact
same-compiler output hashes.

### Cross-domain state creates cycles

Mitigation: state modules must not use behavior modules or each other. Pass
allocation dimensions as scalars. Both behavior modules may import the same
state contract without depending on one another.

### OpenMP behavior changes

Mitigation: do not localize module work variables, reorder loops, or alter
OpenMP clauses. Validate the existing one-thread fixture first and record that
multi-thread equivalence remains untested unless a validated fixture is added.

### Allocation ownership exposes existing leaks

Mitigation: make domain deallocation symmetric with `allocated()` guards and
perform it only after output completion. Keep resource cleanup changes isolated
from numerical changes.

### Centralized I/O accidentally changes record formats

Mitigation: move every `open`, `read`, `write`, `close`, `format`, `recl`,
`access`, and `form` statement verbatim before cleanup. Validate generated file
sizes and hashes.

### Architecture checker accepts or rejects the wrong syntax

Mitigation: keep the supported syntax narrow, add fixtures for every source form
used by the repository, and fail on unclassified modules rather than guessing.

### Combined implementation becomes difficult to review

Mitigation: maintain the phased implementation structure, keep this migration
ledger current, and provide regression evidence at each boundary.

## Stop conditions

Pause implementation and separate or redesign the affected change if:

- any expected output must be altered after structural work starts;
- same-compiler output hashes change without an understood non-scientific
  cause;
- an explicit interface requires a numerical kind, rank, shape, or argument-
  order change;
- a dependency cycle cannot be removed without passing new state objects or
  changing scientific sequencing;
- an I/O move requires a filename, format, record-length, or ordering change;
- OpenMP data-sharing semantics cannot be preserved;
- Muskingum-Cunge cannot be exercised by a valid regression before its module
  is consolidated;
- the Windows or Linux validated build cannot resolve the nested module source
  structure; or
- the implementation begins performing unrelated naming, algorithm, calibration, or
  portability work.

## Definition of done

The structure-and-interfaces work is complete when:

- the target source tree is present and the flat source files are gone;
- `model_state` no longer exists and no replacement all-state aggregator has
  been introduced;
- all project procedures are contained in modules and have explicit interfaces;
- domain helpers are private and only the APIs in this plan are public;
- all project imports use explicit `only` lists;
- state and lifecycle ownership matches this plan;
- main remains a readable high-level composition point;
- runtime file ownership is centralized under `src/io/`;
- the automated dependency check prevents forbidden edges;
- CMake presents sources by domain and builds on validated Windows and Linux
  Intel `ifx` environments;
- inertial and Muskingum-Cunge regressions pass;
- same-compiler generated outputs match their pre-refactor hashes;
- durable architecture and I/O documentation are current;
- the final validation record states that scientific behavior is unchanged and
  includes complete validation evidence.
