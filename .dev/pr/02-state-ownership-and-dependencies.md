# Task 2: State ownership and dependency restructuring

## Objective

Give shared catchment data a routing-neutral owner, make inertial and
Muskingum-Cunge routing independent, establish a behavioral reservoir boundary,
and keep whole-model scientific orchestration in the simulation domain.

This task follows the repository-wide naming and formatting work in Task 1 and
must preserve scientific behavior and regression outputs.

## Catchment state

Add `src/catchment/catchment_state.f90`. The module owns data but performs no
scientific orchestration.

Move the following general data into `catchment_state`:

- catchment, subbasin, and HRU counts and identity;
- catchment-to-subbasin and downstream topology;
- catchment ordering and subbasin outlets;
- catchment coordinates and climate-region assignment;
- catchment and drainage areas;
- river length, width, and slope;
- longest-reach length and slope;
- HRU names, percentages, and related general definitions;
- static land and runoff parameters, including `b_arno` and
  `lambda_brooks_corey`;
- soil capacities, conductivities, capillary parameters, and runoff-routing
  coefficients that describe the catchment independently of the selected river
  routing method; and
- `time_of_concentration`.

Move routing-neutral shared values into `catchment_state` using descriptive
names, including:

- `catchment_runoff_current`;
- `catchment_runoff_previous`;
- `river_discharge`;
- `reference_discharge`;
- `river_velocity`; and
- physical results shared across domains, such as flooded area where runoff
  consumes a result produced by routing.

Review each moved value by meaning rather than merely by array dimensions. A
value belongs in `catchment_state` when it describes the physical catchment
regardless of the selected algorithm or is a shared contract between model
processes.

Keep algorithm-specific configuration, derived tables, work arrays, and mutable
state with their specialized owners. Examples include:

- inertial face topology, floodplain interpolation tables, Courant controls,
  and hydraulic work state;
- Muskingum reach discretization, substeps, boundary arrays, component
  fractions, and routing volumes;
- reservoir configuration, operating data, and internal state; and
- evapotranspiration forcing, vegetation data, calculation state, and
  interception state.

If a specialized value is occasionally needed elsewhere, expose it through a
behavioral interface or pass it explicitly. Do not move it into
`catchment_state` solely because a second routine reads it.

## State module APIs and lifecycle

Keep state modules default-private. Mark exported state directly on its
declaration with `public`.

Provide clear allocation and deallocation procedures for the new catchment
state. Update application composition, input readers, hotstart handling, output
handling, and all consumers to use the new owner.

Update `CMakeLists.txt` so module compilation order reflects the new dependency
direction.

Do not require Muskingum state to be allocated or initialized when a simulation
uses only inertial routing. Likewise, inertial state must not be required for a
Muskingum-only simulation except where an independently justified shared output
contract exists in `catchment_state`.

## Simulation orchestration

Keep model-process orchestration in `simulation_runner`. Do not add orchestration
behavior to `catchment_state` and do not create a catchment facade that actually
represents the whole simulation.

The simulation domain remains responsible for coordinating the established
sequence of:

1. time and calendar updates;
2. meteorological forcing;
3. runoff and evapotranspiration;
4. catchment-runoff assembly;
5. reservoir behavior;
6. selection and execution of the configured routing method; and
7. preparation of shared results for output.

Preserve the current numerical ordering. Private helpers within
`simulation_runner` may make the timestep loop readable without moving its
responsibility to another broadly named module.

## Reservoir behavioral boundary

Add a `reservoir_processing` module as the public behavioral interface to
reservoir functionality. `reservoir_state` continues to own reservoir and
prescribed-flow data, while other scientific modules interact through
procedures rather than importing that state directly.

The initial interface must preserve all existing behavior:

- catchments disabled by prescribed-flow substitution remain skipped at the
  same stages;
- prescribed flow continues to replace the routing boundary and affect
  downstream calculations;
- Muskingum boundary interpolation remains numerically unchanged;
- inertial prescribed outflow remains interpolated across routing substeps;
- reservoir downstream overrides remain effective; and
- inertial channel-volume constraints remain active at the same timestep.

The API must provide a stable place for future reservoir storage, inflow,
release, and operating-rule calculations. Do not expose reservoir implementation
arrays merely for the convenience of existing routing code.

Flow substitution remains part of this reservoir-facing behavior for now. Do
not redefine it as an output-only replacement and do not introduce a separate,
very thin flow-substitution domain in this task.

## Dependency rules

Apply these rules to the resulting module graph:

- Specialized processing modules may call another domain's public behavioral
  API.
- A specialized processing module must not import another specialized domain's
  internal state.
- Cross-domain behavior dependencies must remain directional and acyclic.
- Shared physical state and results use `catchment_state`.
- Common utilities remain independent of model state.
- State modules must not depend on behavioral modules.

Remove all existing direct state edges covered by this rule, including:

- `inertial_routing` to `muskingum_state`;
- `muskingum_routing` to `inertial_state`;
- `runoff_processing` to `inertial_state`;
- `runoff_processing` to `reservoir_state`;
- routing modules to `reservoir_state`; and
- `runoff_processing` to `evapotranspiration_state`.

Use the evapotranspiration behavioral API to hide evapotranspiration-owned state.
Use `reservoir_processing` to hide reservoir-owned state. Move genuinely shared
physical values to `catchment_state`.

The accepted behavior-to-behavior relationships include
`runoff_processing` calling `evapotranspiration_processing` and routing calling
`reservoir_processing`, provided these dependencies do not reverse elsewhere.

## Routing independence

Remove every use of a Muskingum-owned variable from inertial routing.

In particular:

- inertial initialization uses `reference_discharge` from `catchment_state`;
- both routing methods publish the current routed result through
  `river_discharge`;
- both methods publish velocity through `river_velocity`; and
- Muskingum-only previous values and routing work arrays remain in
  `muskingum_state`.

Catchment runoff and river discharge must remain distinct concepts. Within
routing kernels, use `r` for catchment runoff entering the river and `q` for
river discharge.

## Documentation

Update at least the following documentation to match the implemented ownership,
lifecycle, public APIs, source tree, and dependency rules:

- `docs/development/architecture.md`;
- `docs/development/language-and-naming.md`;
- `README.md` where it describes source organization or lifecycle;
- `docs/getting-started/build.md` where source/build guidance is affected;
- `docs/getting-started/testing.md` where validation guidance is affected; and
- `docs/model/portability.md` where compiler-sensitive implementation details
  are affected.

Do not claim compiler or platform support beyond the validated baselines in the
repository guidelines.

## Validation throughout the task

Keep the repository buildable and integrated after each coherent portion of
the work.

On the available validated platform and compiler:

1. Configure and build with CMake.
2. Run `regression_magdalena_inertial`.
3. Run `regression_magdalena_muskingum`.
4. Confirm that neither regression baseline requires an update.
5. Audit project-module imports for prohibited direct state dependencies.
6. Verify that both routing selections publish the expected shared catchment
   results.

Do not accept intentional scientific-output changes. Document any unavoidable
floating-point difference before considering the task complete.

## Completion criteria

- `catchment_state` owns all agreed general and shared catchment data.
- Inertial routing no longer depends on Muskingum state.
- Muskingum routing no longer depends on inertial state.
- Specialized processing modules do not import another specialized domain's
  internal state.
- Reservoir and substitution behavior is accessed through
  `reservoir_processing` and remains numerically unchanged.
- `simulation_runner` remains the whole-model scientific orchestrator.
- Allocation, initialization, shutdown, I/O, and output consumers use the new
  ownership boundaries.
- Architecture documentation describes the code that actually exists.
- The project builds successfully.
- Both Magdalena regressions pass against their existing baselines.
