# Execution and data flow

The simulation layer coordinates preparation, timestep execution, and
shutdown. Hydrology and I/O exchange values through the five shared variable
namespaces described under
[Components and dependencies](components-and-dependencies.md).

## Execution lifecycle

The application has three visible phases:

1. **Prepare.** `main.f90` opens the log, reads `config.nml`, allocates the five
   shared variable namespaces, and calls `prepare_simulation`. Static input
   loading initially reads a routing value for each catchment from `mini.gtp`.
   The runner then replaces the entire `routing_method` array with the global
   `routing_mode`; the current executable therefore runs all catchments with
   one routing method. Catchment time-of-concentration and Muskingum-Cunge
   parameters are calculated for every run. Floodplain input and inertial
   topology/table preparation occur only in inertial mode. Meteorological
   inputs are then opened.
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

## Shared-state flow

The I/O modules populate more than one shared namespace. Configuration I/O
writes configuration values and the initial calendar state. Static input I/O
populates attributes, parameters, climatological and substitution forcing, and
selected configuration values. During reservoir loading it reads the calendar
from `state` to align reservoir observations. Meteorological I/O refreshes the
current forcing arrays. Hotstart I/O restores `state` and the retained air
temperature in `forcing`. Output I/O writes prepared serialization buffers
from `state`; it does not calculate the scientific values in those buffers.

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

The direct module-variable exchange is intentional. Narrow `only:` lists show
and constrain each procedure's coupling while avoiding wrapper types or a
whole-model storage object.

## Scientific handoffs

Within a timestep, `catchment` writes the groundwater, subsurface, and surface
flow components. In Muskingum-Cunge mode, the routing routine consumes those
components directly before the runner performs its common lateral-flow sum. In
inertial mode, the runner first stores that sum in `catchment_q_current`, which
the inertial continuity calculation then consumes. Both implementations place
routed discharge in `inertial_q`; the runner copies it and other hydraulic
values into output buffers before calling `output_io`.

`attributes`, `config`, and most of `parameters` are prepared before the time
loop. `forcing` is refreshed as meteorological records are read. `state`
contains evolving values and output buffers carried between calculations and
timesteps. I/O and hydrology procedures mutate the owning namespaces rather
than introducing a second model storage object.
