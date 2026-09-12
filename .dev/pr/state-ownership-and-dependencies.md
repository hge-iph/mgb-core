# Typed model storage and explicit domain coupling

## Objective

Replace module-global allocated model data with named, lifecycle-specific
derived types, while preserving the existing scientific calculations and
runtime interfaces exactly.

The resulting architecture must make state ownership and cross-domain exchange
explicit without giving scientific code a lookup path through the whole model.
It must also provide stable boundaries where reservoirs, irrigation, and other
human-intervention modules can be added later. Those future processes are not
implemented in this task.

This is an organizational refactor. It must not redefine hydrological or
hydraulic behavior, repair unvalidated mixed-routing behavior, change equation
order, or intentionally change any output.

This task follows Task 1's numerical naming and formatting work. Do not combine
the two tasks in one uncontrolled repository-wide rewrite.

## Agreed architecture decisions

The implementation must follow these decisions:

- Retain `catchment` as the canonical English source term for an MGB
  mini-catchment. Do not rename source identifiers to `mini`.
- Use a composition-only `model_storage_t` root object.
- Scientific domains must never import `model_storage` or receive the complete
  root object as an argument.
- Pass narrow named types to scientific procedures with explicit `intent`.
- Keep derived types data-oriented, with directly accessible components.
  Dependency rules and narrow arguments provide encapsulation; do not create a
  large getter/setter API.
- Preserve the existing structure-of-arrays layout. Do not replace it with an
  array of per-catchment objects.
- Keep the HRU water balance, evapotranspiration, HRU aggregation, depth-to-flow
  conversion, and surface/subsurface/groundwater linear reservoirs in one
  `catchment` scientific domain. There is no separate top-level `land` domain.
- Keep river routing as one domain with per-catchment routing selection.
  Muskingum-Cunge and inertial routing remain separate implementations behind
  the river boundary.
- Preserve `routing_method(:)` as a per-catchment property. Do not collapse it
  to a model-wide scalar, even though the validated fixtures currently select
  one method for the full model.
- Preserve existing mixed-routing execution as-is. Characterize it before
  moving shared arrays, but do not claim to correct or newly validate the
  science of heterogeneous routing in this task.
- Keep all immutable data read from a `mini.gtp` record together in one shared
  `catchment_attributes_t`. Catchment and river procedures may receive that
  object read-only.
- Treat general prescribed-flow substitution as river boundary forcing, not as
  a reservoir structure.
- Represent the existing reservoir feature under `structures/reservoir`. Its
  current outflow series is forcing; this task does not add simulated reservoir
  storage or operating rules.
- Scientific forcing is read-only to scientific procedures. A transformed
  value such as post-interception precipitation is a result or exchanged flux,
  not a mutation of the raw forcing.
- Diagnostics are distinct from scientific state.
- Persistent scratch workspace is distinct from both scientific state and
  immutable prepared data.
- Coupling types contain values only. They must not contain pointers or
  references to complete domain objects.
- The simulation runner coordinates domains and transfers. A coupling module
  must not become a service locator or a second whole-model orchestrator.

## Architectural vocabulary

Classify allocated data by lifecycle and purpose:

| Category | Meaning |
| --- | --- |
| Attributes | Fixed discretization facts: identity, geometry, topology, membership, and fractions. Input normalization during preparation is allowed; timestep science then reads them only. |
| Parameters | Fixed coefficients used by scientific equations or algorithm configuration. |
| Forcing | Externally prescribed, time-varying input. Scientific domains read forcing but do not overwrite it. |
| State | Values that must be carried forward to advance a later timestep or routing substep. |
| Prepared data | Values and lookup tables derived once from attributes or parameters and reused by the simulation. |
| Fluxes | Values transferred across scientific-domain boundaries during a timestep. |
| Diagnostics | Values calculated for reporting or serialization that are not required to advance the science. |
| Workspace | Mutable temporary storage used to execute an algorithm but not part of its scientific history or public exchange. |

Not every domain needs every category. In particular, the current reservoir
feature has attributes and forcing but no independently simulated scientific
state.

When a value is difficult to classify, use these tests in order:

1. If a later timestep or substep needs the value, it is state.
2. If another domain consumes the value, it is a directional flux or feedback.
3. If it is immutable after preparation, it is an attribute, parameter, or
   prepared value according to how it was obtained.
4. If output consumes it but science does not, it is a diagnostic.
5. Otherwise, if an algorithm only needs it temporarily, it is workspace and
   should be local when practical.

Do not place a value in state merely because the current implementation stores
it in a module variable.

## Target domains and storage shape

The composition layer owns a root object with domain-specific components. The
names below are the target vocabulary; small adjustments are acceptable during
implementation when required by Fortran name resolution, but the ownership and
dependency direction are not optional.

```text
model_storage_t
├── dimensions                 model_dimensions_t
├── simulation
│   ├── configuration          simulation_configuration_t
│   └── state                  simulation_state_t
├── catchment_attributes       catchment_attributes_t
├── catchment
│   ├── parameters             catchment_parameters_t
│   ├── forcing                catchment_forcing_t
│   ├── state                  catchment_state_t
│   ├── prepared               catchment_prepared_t
│   ├── diagnostics            catchment_diagnostics_t
│   └── workspace              catchment_workspace_t, only if persistent storage is needed
├── river
│   ├── parameters             river_parameters_t
│   ├── prepared               river_prepared_t
│   ├── state                  river_state_t
│   ├── diagnostics            river_diagnostics_t
│   ├── boundary_forcing       prescribed_flow_forcing_t
│   ├── muskingum              method-specific types
│   └── inertial               method-specific types
├── structures
│   └── reservoirs
│       ├── attributes         reservoir_attributes_t
│       ├── forcing            reservoir_forcing_t
│       └── prepared           reservoir_prepared_t, if needed
├── coupling                   directional exchange records
└── runtime I/O                paths, options, schedules, and serialization buffers
```

The root type may aggregate these objects for construction, teardown, and
orchestration. It must not be used as a scientific procedure argument.

Domain aggregates may exist for composition convenience, but scientific calls
must pass the lifecycle components separately when their `intent` differs. For
example, do not pass a mutable `catchment_data_t` when the procedure should see
parameters and forcing as read-only while modifying state and diagnostics.

## Composition-only root and lookup direction

In the diagrams below, `A -> B` means that A imports or depends on B.

The allowed high-level direction is:

```text
application/main
        |
        v
simulation runner and model lifecycle
        |
        +----------> model storage and all owned type definitions
        +----------> centralized I/O APIs
        +----------> catchment processing
        +----------> river facade
        +----------> structures processing, when behavior exists
                           |
                           v
                  narrow coupling contracts
```

The type and behavior dependency direction is:

```text
common utilities and numeric constants
        |
        +----> coupling contract types
        +----> catchment type definitions
        +----> river type definitions
        +----> structure type definitions

catchment processing --> catchment types + catchment attributes + coupling contracts + common
river facade         --> river types + method implementations + coupling contracts + common
method implementation--> its own types + shared river types + coupling contracts + common
structure processing --> its own types + coupling contracts + common

model storage        --> all type definitions, but no scientific behavior
runner/lifecycle     --> model storage + I/O + scientific behavior
```

Explicitly forbid:

```text
catchment processing  -X-> model_storage
river processing      -X-> model_storage
structure processing  -X-> model_storage
catchment processing  -X-> river state or method state
river processing      -X-> catchment parameters or state
Muskingum-Cunge       -X-> inertial state
inertial routing      -X-> Muskingum-Cunge state
coupling contracts    -X-> any scientific domain type
domain type modules   -X-> processing or I/O modules
```

Passing the root to a domain would allow paths such as
`model%river%state` from catchment code and would recreate global lookup under
a new name. The architecture checker must reject that dependency even if the
Fortran compiler could resolve it.

## Shared catchment attributes

`catchment_attributes_t` is the immutable shared description populated from
`mini.gtp` and its existing preparation rules. Keep the record cohesive rather
than splitting its fields according to which scientific routine happens to
read them today.

It includes the current equivalents of:

- catchment, subbasin, and HRU identity and counts needed by the record;
- catchment coordinates and area;
- drainage area;
- catchment-to-subbasin membership;
- climate-region assignment;
- HRU names and percentages;
- downstream catchment and routing order;
- subbasin outlets and catchment counts;
- river and longest-reach geometry;
- routing-method selection per catchment; and
- the channel or hydraulic descriptors currently carried in `mini.gtp`.

The exact existing precision and extents must remain unchanged. Existing input
preparation such as HRU redistribution, slope/length limits, enabled-subbasin
outlet adjustment, and per-catchment routing flags must occur in the same order
before the attributes become read-only for timestep processing.

Catchment and river APIs may both accept `catchment_attributes_t` with
`intent(in)`. This shared immutable dependency does not authorize access to
another domain's parameters, state, diagnostics, or workspace.

## Catchment domain

The catchment domain replaces the current architectural split between runoff
and evapotranspiration modules. It owns the complete terrestrial calculation
from meteorological forcing through per-catchment lateral runoff.

### Catchment parameters

`catchment_parameters_t` owns the current scientific inputs associated with:

- maximum soil-water storage and ARNO shape;
- subsurface and groundwater conductivity;
- Brooks-Corey pore-size index;
- maximum capillary transfer and its activation threshold;
- floodplain infiltration rate;
- surface, subsurface, and groundwater linear-reservoir coefficients;
- specific baseflow initialization;
- monthly vegetation albedo, leaf-area index, height, and surface resistance;
  and
- other fixed terrestrial equation coefficients that are currently allocated
  as model data.

Retain subbasin/HRU indexing, precision, and input ordering.

### Catchment forcing

`catchment_forcing_t` owns the externally supplied meteorological values used
for the current calculation:

- precipitation;
- current and previous air temperature;
- relative humidity;
- wind speed;
- solar input; and
- air pressure.

The forcing subsystem may also own its selection flags, station coordinates,
and monthly climatology needed to construct current forcing. These source data
must remain distinguishable from scientific catchment parameters.

Move advancement of forcing history, including the previous-temperature copy,
to forcing preparation immediately before the existing meteorological read.
Catchment science receives the completed forcing read-only. This movement must
retain the present assignment and calculation order.

Do not write post-interception precipitation back into forcing. Publish the
same calculated value through the catchment-to-river exchange at the point
where the current code writes it back.

### Catchment state

`catchment_state_t` owns values required by later timesteps:

- soil-water storage by catchment and HRU;
- interception storage by catchment and HRU; and
- surface, subsurface, and groundwater linear-reservoir storage by catchment.

Review hotstart payloads as the authoritative minimum state inventory. A value
must not be removed from state merely because a current equation can recompute
an approximation of it.

### Catchment prepared data

`catchment_prepared_t` owns immutable values derived before initialization and
reused by catchment equations. In particular, move time of concentration out
of Muskingum-owned state: it is derived from shared catchment geometry and is
used by catchment linear reservoirs regardless of river-routing method.

### Catchment-to-river exchange

Use one method-neutral output contract for values the river consumes. Its
fields must retain distinct physical meanings and units, including:

- surface lateral discharge;
- subsurface lateral discharge;
- groundwater lateral discharge;
- total lateral discharge where the existing order requires it;
- post-interception/effective precipitation used by floodplain continuity;
- floodplain infiltration used by floodplain continuity; and
- potential or actual open-water evaporation in the exact representation
  required at the boundary.

The implementation must resolve the existing misleading
`open_water_evaporation_q` name. It currently represents different units in
different routing branches. Use separate fields or an explicit adapter so no
field changes physical quantity according to `routing_method`. Preserve the
legacy equations and conversions; this is a representation cleanup, not a new
evaporation formulation.

Catchment processing must not import `routing_method` or any river state.
Differences required by existing routing behavior must be expressed in the
input feedback or in composition/river adapters without exposing the selected
solver to catchment kernels.

### River-to-catchment feedback

The feedback contract initially contains the flooded area needed by the
terrestrial balance. It represents the river state available at the start of
the catchment calculation, which under the preserved timestep order is the
result retained from the preceding river update.

Do not pass `river_state_t` to catchment processing. Copy or assemble the
narrow feedback in the runner without changing precision.

### Catchment diagnostics and workspace

`catchment_diagnostics_t` owns timestep results used for reporting but not for
advancing state, including the current equivalents of:

- total terrestrial water storage;
- mean soil water and soil saturation;
- interception, soil/vegetation, water-HRU, open-water, and total ET outputs;
- interception and linear-reservoir storage depths;
- surface, subsurface, and groundwater runoff depths;
- capillary-transfer reporting; and
- potential radiation or evaporation indicators not consumed as river fluxes.

Keep equation accumulators local. Introduce `catchment_workspace_t` only for
scratch arrays that would otherwise be repeatedly allocated or must persist for
performance. Workspace is not serialized or exposed outside catchment
processing.

## River domain

The river domain owns shared river results and coordinates the existing
Muskingum-Cunge and inertial implementations. Preserve per-catchment routing
selection and all current call order.

### Shared river data

`river_parameters_t`, `river_prepared_t`, `river_state_t`, and
`river_diagnostics_t` contain only method-neutral values. Candidate shared
ownership includes:

- reference discharge as prepared data;
- the active routing topology after existing boundary and reservoir overrides;
- routed river discharge published by either method;
- river velocity where it is a shared result;
- flooded area, water depth, and water-surface elevation when exposed as
  physical river results; and
- reporting values consumed by output independently of implementation.

Do not move a value to shared river state solely because one implementation
currently reads the other implementation's array. First determine whether the
value is a physical river result, method state, prepared data, or workspace.

### Routing facade and per-catchment selection

Introduce a river facade that is the only module outside method implementation
folders allowed to know both routing implementations. The runner calls this
facade; it does not select and call method internals itself.

The facade must retain the existing ordering and per-catchment masks. Do not
introduce polymorphic dispatch, a new numerical scheduler, compact index maps,
or selective array extents in this task. Full catchment-indexed arrays may be
retained for both method implementations when that most directly preserves
legacy behavior.

The current code contains implicit handoffs:

- Muskingum skips catchments marked for inertial routing;
- Muskingum publishes values through arrays subsequently used by inertial
  routing;
- inertial loops and upstream sums do not consistently express the routing
  mask at every point; and
- both implementations update nominally shared discharge and velocity values.

Capture this behavior with a characterization test or documented executable
trace before replacing these arrays. Preserve the observed behavior. Do not
interpret this task as authorization to correct mixed routing or claim it as a
new validated mode.

### Muskingum-Cunge ownership

Classify the existing Muskingum data as follows, subject to the hotstart and
equation audit:

- parameters/prepared: reach count, routing timestep, wave celerity, and
  derived coefficients that remain valid across model timesteps;
- state: current and previous incoming/outgoing discharge, reach discharge
  profile, routed component volumes, and component fractions carried between
  timesteps; and
- workspace: boundary interpolation arrays and temporary reach/substep storage
  that is reset during routing.

Muskingum-Cunge code consumes shared attributes, catchment-to-river fluxes,
river boundary forcing, and its own data. It must not import inertial types.

### Inertial ownership

Classify the existing inertial data as follows, subject to the hotstart and
equation audit:

- parameters: Courant control, gravity, Manning values, downstream boundary
  slope, thread count, and pseudo-2D controls;
- attributes/prepared: source floodplain data, face connections, upstream
  topology, and stage/area/volume lookup tables;
- state: channel/face discharge, current and previous volume, water depth,
  water-surface elevation, flooded area, and any lookup index or neighbor value
  required by hotstart continuation; and
- workspace: substep-only neighbor sums and other temporary OpenMP work not
  required by hotstart or the next timestep.

The existing hotstart includes `stage_table_index`, `face_q`, and `neighbor_q`;
therefore retain them as state until a separate, regression-protected change
proves that any one is reconstructible without changing restart behavior.

Inertial code consumes shared attributes, catchment-to-river fluxes, structure
exchange data, and its own types. It must not import Muskingum types.

## River boundary forcing

Move general prescribed discharge substitution out of reservoir ownership.
Use `prescribed_flow_forcing_t` or an equivalently explicit river-owned type for:

- substitution count;
- substitution catchment mapping;
- the prescribed discharge time series;
- availability/sentinel values; and
- the existing catchment-disable mask or the source information from which the
  runner constructs that narrow control.

The catchment domain currently skips calculation for substituted catchments.
Preserve that behavior by passing a narrow read-only calculation mask or
boundary-control contract. Do not give catchment processing access to all river
forcing.

Both routing implementations must preserve their present substitution timing,
search/order behavior, interpolation, sentinel handling, and downstream
replacement behavior.

## Structures domain and reservoirs

Create a structures boundary that can host future reservoirs, irrigation,
withdrawals, diversions, and related interventions without making those
modules owners of catchment or river state.

For this task, only reorganize the behavior that already exists:

- `reservoir_attributes_t` owns reservoir identity, reservoir-to-catchment
  mapping, dam/lake membership, and the configuration flags currently read
  from `reservoir_config.txt`;
- `reservoir_forcing_t` owns prescribed reservoir outflow, availability, and
  start-timestep information from `reservoir_outflow.txt`; and
- any derived reservoir control needed by routing is published through a
  narrow structures-to-river contract.

The reservoir input currently modifies active downstream topology and
floodplain lookup tables. Preserve these transformations and their order during
river preparation. Express the input as a narrow structure configuration or
preparation contract rather than allowing reservoir code to look up the whole
river object.

Do not add speculative reservoir storage, rule curves, irrigation demand,
callbacks, or a generic structure base class. The extension point is the
directional contract and the structures package boundary. Future behavior can
add purpose-specific contracts once its timestep requirements are known.

## Coupling contracts

Place directionally named, data-only exchange types in a low-level coupling
module or small set of coupling modules. Initial contracts are expected to
cover:

```text
river_to_catchment_feedback_t
    flooded area available before catchment processing

catchment_to_river_flux_t
    lateral runoff components and floodplain vertical-balance terms

structure_to_river_control_t
    prescribed release and existing topology/floodplain controls needed by routing

river_boundary_control_t
    narrow substitution mask or values needed outside river forcing ownership
```

Use purpose-specific fields with documented units. Do not create a generic
`flux(:)` array whose meaning depends on the producer, consumer, or routing
method.

Coupling modules may depend on common numeric kinds and constants only. They
must not import catchment, river, structures, I/O, model storage, or simulation
behavior.

The root may contain an aggregate of the coupling records for lifecycle
convenience. A domain receives only the specific record it consumes or
produces.

## Scientific procedure interfaces

Use explicit dataflow in public APIs. The intended catchment form is:

```fortran
subroutine update_catchments( &
    simulation, &
    attributes, &
    parameters, &
    prepared, &
    forcing, &
    river_feedback, &
    calculation_control, &
    state, &
    river_flux, &
    diagnostics, &
    workspace)
```

Apply these intent rules:

- configuration, attributes, parameters, prepared data, forcing, feedback, and
  controls are `intent(in)`;
- scientific state is `intent(inout)`;
- newly produced fluxes and diagnostics are `intent(out)` when fully assigned,
  otherwise `intent(inout)` only when the preserved accumulation order requires
  an existing value; and
- workspace is `intent(inout)` and remains an implementation concern.

The river facade follows the same pattern with shared river data,
method-specific state/workspace, catchment fluxes, boundary forcing, structure
controls, and river diagnostics.

Prefer whole named objects over long lists of unrelated module variables, but
do not combine arguments merely to shorten a call. The argument boundary must
make read and write authority visible.

Private equation kernels may continue to use compact scalar dummy arguments as
specified by Task 1. Do not force a large derived object into a small numerical
kernel when explicit scalars make the equation and evaluation order clearer.

## Allocation and lifecycle

Use a staged lifecycle because dimensions are learned before most static model
data and some optional inputs are learned later:

1. Create an unallocated `model_storage_t` in application composition.
2. Read configuration into scalar configuration and dimension types.
3. Validate dimensions before allocation.
4. Allocate shared catchment attributes and each domain's parameters, forcing,
   state, diagnostics, coupling records, and required workspace using explicit
   dimensions.
5. Read and normalize `mini.gtp`, HRU, parameter, climatology, and prescribed
   boundary inputs in their existing order.
6. Allocate/read optional reservoir and floodplain data at the same points as
   today.
7. Build catchment and river prepared data.
8. Initialize forcing history and scientific state.
9. Open runtime forcing and output files.
10. Run the timestep loop.
11. Close files and release owned storage in reverse lifecycle order.

Provide free allocation procedures with explicit arguments, for example
`allocate_catchment_state(state, dimensions)`. Do not let allocation routines
read dimensions from module globals.

A composition-level `allocate_model_storage` may call the category-specific
allocators. Domain allocators remain responsible for their own array extents
and initialization. Keep explicit deallocation during this migration even
though allocatable derived-type components are finalized automatically; the
explicit lifecycle makes failure paths and ownership auditable on all validated
compilers.

Preserve all current allocation extents, lower bounds, fixed capacities,
precisions, and sentinel initialization unless a separately justified bug fix
is approved. Do not compact arrays to only the catchments using a routing
method in this task.

## Simulation order

Preserve the existing externally observable and numerical order. The typed
dataflow should expose, not reorder, the current sequence:

1. perform scheduled hotstart output;
2. advance forcing history;
3. read current meteorological forcing;
4. assemble river-to-catchment feedback from the retained river state;
5. update catchment evapotranspiration, HRU water balance, aggregation, and
   linear reservoirs;
6. publish the catchment-to-river exchange;
7. execute the existing Muskingum/inertial routing sequence and per-catchment
   branches through the river facade;
8. retain river state for the following timestep;
9. assemble diagnostics into output serialization buffers;
10. write enabled outputs; and
11. advance calendar state.

Where this conceptual list is less precise than the current executable—for
example the exact point where lateral discharge is assembled—retain the source
execution order and document it in the implementation notes. Do not move an
assignment across a routing call merely to make the conceptual sequence look
cleaner.

## I/O and serialization boundaries

Keep runtime file ownership centralized in `src/io`. I/O modules may depend on
multiple data-type modules because they are composition-layer serializers, but
they must accept the required objects explicitly rather than updating
module-global arrays.

Split current `output_state` responsibilities into:

- output configuration flags;
- hotstart configuration and schedule;
- domain diagnostics owned by catchment or river; and
- I/O-owned single-precision serialization buffers, where a buffer is still
  required by the existing direct-access write.

Scientific processing must not import output I/O state. The runner or a
dedicated output-assembly procedure copies domain state, fluxes, and diagnostics
to the existing output buffers at the same timestep point and with the same
precision conversion as today.

Hotstart I/O is a broad serializer by design. It may read and update the
required catchment, forcing-history, river-common, Muskingum, and inertial state
objects through explicit arguments. Preserve exactly:

- filenames and date formatting;
- record lengths;
- variable ordering;
- single- and double-precision payloads;
- reach-dependent vector lengths;
- sentinel handling; and
- the timestep at which reads and writes occur.

Use the current hotstart read/write loops as the compatibility specification.
Do not reorganize the binary payload to mirror the new derived types.

## Proposed source organization

The implementation may converge on the following structure:

```text
src/
├── application/
│   └── main.f90
├── common/
│   └── existing model-independent utilities
├── coupling/
│   └── coupling_types.f90
├── simulation/
│   ├── simulation_types.f90
│   ├── model_storage.f90
│   ├── model_lifecycle.f90
│   └── simulation_runner.f90
├── catchment/
│   ├── catchment_types.f90
│   └── catchment_processing.f90
├── river/
│   ├── river_types.f90
│   ├── river_routing.f90
│   ├── prescribed_flow_types.f90
│   ├── muskingum/
│   │   ├── muskingum_types.f90
│   │   └── muskingum_routing.f90
│   └── inertial/
│       ├── inertial_types.f90
│       └── inertial_routing.f90
├── structures/
│   └── reservoir/
│       └── reservoir_types.f90
└── io/
    └── centralized configuration, static-input, forcing, hotstart, and output modules
```

Avoid one source file per small type when the types share the same owner and
dependency level. The goal is explicit ownership with a navigable source tree,
not maximal file count.

Do not retain parallel legacy `*_state` modules after their data has moved.
Temporary adapters are allowed only during a buildable migration step and must
be removed before completion.

## Implementation sequence

Keep the model buildable and regression-tested after each coherent stage.

### 1. Baseline and characterization

- Record the available OS, compiler version, CMake command, and baseline test
  results.
- Run both Magdalena regressions against the current executable.
- Inventory every allocated module variable and classify it using the agreed
  categories.
- Record each hotstart field and output field with owner, precision, units, and
  serialization order.
- Add focused characterization for the existing routing handoff and
  per-catchment `routing_method` branches. If a practical mixed-routing fixture
  can be made from existing data, capture current output without calling that
  behavior scientifically validated. Otherwise document the uncovered branch
  and add structural tests that ensure the per-catchment property is retained.

### 2. Low-level type and contract modules

- Add simulation/dimension types, shared catchment attributes, catchment types,
  shared river types, method-specific types, reservoir types, prescribed-flow
  forcing, diagnostics, and coupling contracts.
- Add allocation/deallocation procedures that use explicit dimensions.
- Initially populate the types through narrowly scoped migration adapters if
  necessary, while keeping one authoritative copy of each value.
- Add unit tests for allocation shapes, independent instances, and clean
  deallocation where practical.

### 3. Composition root and configuration lifecycle

- Add `model_storage_t` and composition-level lifecycle procedures.
- Change configuration I/O to populate configuration/dimension objects rather
  than state-module globals.
- Update `main.f90` to construct the root and call composition APIs.
- Keep the root out of all scientific and low-level I/O procedure signatures.
- Confirm that two separately allocated storage objects do not alias, even
  though the executable continues to run one model instance.

### 4. Catchment migration

- Merge evapotranspiration and runoff ownership into the catchment package
  without merging or reordering the numerical kernels themselves.
- Move `mini.gtp` data to shared catchment attributes.
- Move terrestrial parameters, forcing, state, prepared values, diagnostics,
  and workspace into their named types.
- Move time of concentration to catchment prepared data.
- Replace direct river, reservoir, and output-state imports with narrow
  feedback, control, flux, and diagnostic arguments.
- Make scientific forcing read-only and publish effective precipitation through
  the exchange contract.
- Verify both routing regressions before continuing.

### 5. Shared river state and routing implementations

- Establish method-neutral river prepared data, state, and diagnostics.
- Move Muskingum data into parameter/prepared/state/workspace types.
- Move inertial data into parameter/prepared/state/workspace types.
- Introduce the river facade while preserving the current method call order and
  per-catchment branches.
- Replace Muskingum-to-inertial and inertial-to-Muskingum array imports with
  shared river values or facade-controlled handoffs.
- Preserve full array extents and current OpenMP loop behavior.
- Re-run the routing characterization and both regressions.

### 6. Boundary forcing and structures

- Extract prescribed-flow substitution from reservoir ownership into river
  boundary forcing.
- Pass the catchment-disable behavior through a narrow control.
- Move reservoir mapping/configuration to reservoir attributes and prescribed
  outflow to reservoir forcing.
- Express the existing reservoir topology, floodplain-table, and outflow effects
  through narrow preparation/runtime contracts.
- Preserve every existing sentinel, interpolation, start-timestep, and
  downstream override behavior.
- Do not add new reservoir or irrigation calculations.

### 7. Diagnostics, output, and hotstart

- Stop scientific modules from importing `output_state`.
- Populate domain diagnostics at the exact points where current output arrays
  are assigned.
- Add output assembly that performs existing single-precision conversions.
- Change output and hotstart I/O to explicit typed arguments.
- Byte-compare hotstart and binary output payloads where deterministic.
- Verify that restarting from existing hotstarts and newly written hotstarts
  preserves current results.

### 8. Remove legacy globals and enforce the architecture

- Remove migrated module-global allocatable arrays and obsolete allocation
  procedures.
- Remove temporary compatibility adapters and duplicate data copies.
- Update CMake source groups and compilation dependencies.
- Extend `scripts/check_fortran_architecture.py` and its focused tests with the
  new categories and forbidden lookup edges.
- Audit all project `use` statements and all public APIs.
- Update architecture, model-process, I/O, testing, build, naming, and
  portability documentation where affected.

## Architecture checks

Extend the checker beyond a flat state/facade distinction. It must classify at
least:

- common utilities;
- coupling contracts;
- domain type modules;
- domain processing modules;
- river method implementations;
- centralized I/O;
- model storage/lifecycle;
- simulation orchestration; and
- application composition.

Add checker tests proving that it rejects:

- a scientific module importing `model_storage`;
- catchment processing importing river or structure state;
- river processing importing catchment state;
- one river implementation importing the other's types;
- a coupling module importing any domain module;
- a domain type module importing behavior or I/O; and
- an I/O or domain procedure that uses project modules without an `only` list.

Also test the intentional allowances:

- the root imports all data-type modules;
- the runner imports the root, I/O APIs, and scientific facades;
- the river facade imports both routing implementations;
- catchment and river processing both import shared immutable catchment
  attributes; and
- hotstart/output serializers import the several type definitions they
  serialize.

## Validation gates

For every stage that changes source or build definitions, run on the available
validated Linux GNU Fortran platform:

```bash
FC=gfortran cmake -S . -B build/linux-gfortran -DCMAKE_BUILD_TYPE=Release
cmake --build build/linux-gfortran
ctest --test-dir build/linux-gfortran --output-on-failure -R architecture
ctest --test-dir build/linux-gfortran --output-on-failure -R regression_magdalena_
```

Also run focused Python tests when the architecture checker or regression
harness changes.

Before completion, validate the applicable documented Intel `ifx` build when
that compiler is available. Record exact OS, compiler, and command evidence.
Do not claim validation on an unavailable platform or compiler.

Required numerical evidence:

- both existing Magdalena regressions pass without baseline updates;
- deterministic binary outputs remain byte-identical;
- hotstart field order, precision, and restart behavior remain unchanged;
- per-catchment routing selection remains represented and exercised to the
  extent supported by characterization; and
- no intentional floating-point or scientific-output change is accepted.

If a compiler produces unavoidable nondeterministic or floating-point
differences, stop and document the exact field, magnitude, platform, compiler,
and reason before proceeding. Do not silently refresh expected results.

## Documentation updates

Update at least:

- `docs/development/architecture.md` for source ownership, lookup direction,
  coupling contracts, and lifecycle;
- `docs/development/language-and-naming.md` for named type and lifecycle-category
  conventions;
- `docs/development/fortran-style.md` for derived-type component and explicit
  argument layout where necessary;
- `docs/model/model-processes.md` for the unchanged but newly explicit
  catchment/river dataflow;
- `docs/model/io-reference.md` for unchanged serialization mapped to new owners;
- `docs/getting-started/testing.md` for architecture and characterization tests;
- `docs/getting-started/build.md` if source grouping or compiler guidance is
  affected;
- `docs/model/portability.md` for any derived-type or compiler-sensitive notes;
  and
- `README.md` if its source-tree or application-lifecycle description changes.

Documentation must distinguish implemented behavior from future extension
points. Do not document reservoirs, irrigation, or mixed routing as newly
supported scientific capabilities.

Run:

```bash
python -m mkdocs build --strict
```

## Non-goals

This task does not:

- change scientific equations, constants, evaluation order, or precision;
- change model timestep or routing-substep scheduling;
- correct or redefine mixed Muskingum/inertial behavior;
- change input filenames, namelist keys, text layouts, binary layouts, output
  names, or hotstart formats;
- add reservoir storage, release rules, irrigation, allocation, diversion, or
  return-flow science;
- introduce a plugin system, generic process registry, event bus, dependency
  injection framework, or service locator;
- introduce polymorphic routing dispatch or a generic abstract structure base
  class;
- compact state according to routing masks;
- convert structure-of-arrays data into arrays of objects;
- hide numerical arrays behind getters and setters; or
- claim new compiler or platform support.

## Risks and mitigations

### Root object becomes renamed global state

Mitigation: only lifecycle, runner, and application composition may import the
root. Enforce this in the architecture checker. Pass selected components to all
other procedures.

### A type becomes another broad state bag

Mitigation: classify fields by lifecycle, keep state domain-specific, and use
directional contracts. Review every public procedure's argument list and
`intent`.

### Moving arrays changes numerical order

Mitigation: move ownership before simplifying calculations. Retain loop,
assignment, call, conversion, and OpenMP ordering. Run both regressions after
each domain migration.

### Forcing cleanup changes precipitation behavior

Mitigation: assign the post-interception value to the new exchange field at the
exact legacy statement point. Keep raw forcing unchanged and update the river
consumer in the same coherent change.

### Shared routing handoffs are accidentally reinterpreted

Mitigation: characterize existing per-catchment branches and shared array
updates first. Introduce method-neutral river fields without changing the
facade schedule.

### Hotstart compatibility is broken by better ownership

Mitigation: treat the current serialization loop as the external contract.
Derived-type component order must never determine file order.

### Future structures are over-designed

Mitigation: add only the current reservoir attributes/forcing and narrow
contracts required to reproduce existing behavior. Defer dynamic operating
interfaces until a concrete module supplies their requirements.

## Completion criteria

- All run-dependent allocated scientific data is owned by a component of one
  `model_storage_t` instance; scientific arrays are no longer module globals.
- No scientific procedure imports or receives the complete root.
- Catchment owns evapotranspiration, HRU water balance, aggregation, and the
  three linear reservoirs.
- There is no top-level land domain.
- `mini.gtp` data is held together in shared read-only
  `catchment_attributes_t` storage.
- Parameters, forcing, state, prepared data, diagnostics, fluxes, and persistent
  workspace are distinguishable by named types and procedure intent.
- Scientific forcing is not overwritten by catchment processing.
- Catchment and river exchange data only through narrow contracts.
- Per-catchment routing selection is retained.
- Muskingum-Cunge and inertial implementations no longer import each other's
  internal state.
- General flow substitution is river boundary forcing, separate from reservoir
  structures.
- Existing reservoir configuration and prescribed outflow are represented
  under structures without adding new reservoir behavior.
- Scientific modules no longer write directly to output I/O state.
- Hotstart and output formats remain compatible.
- The architecture checker enforces the new lookup direction.
- The CMake build succeeds on the available validated platform.
- Both Magdalena regressions pass without baseline changes.
- Strict MkDocs validation passes.
- Documentation describes the implemented architecture and clearly labels
  future extension points.
