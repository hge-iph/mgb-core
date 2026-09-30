# Legacy routines and execution flow

Legacy routine names below refer to procedures present at
[`41146b1`](https://github.com/HGE-IPH/MGB-model/commit/41146b1). Names in the
current implementation column identify matching routines and modules in the
current source tree.
“Absorbed” means the calculation remains inside a larger procedure, often as a
private helper or a procedure-local section.

| Legacy routine | Current implementation | Responsibility and disposition |
| --- | --- | --- |
| `ALLOCA_VARS` | *Routines:*<br>`allocate_attributes`<br>`allocate_config`<br>`allocate_forcing`<br>`allocate_parameters`<br>`allocate_state`<br>matching `deallocate_*` procedures<br><br>*Modules:*<br>`vars/attributes.f90`<br>`vars/config.f90`<br>`vars/forcing.f90`<br>`vars/parameters.f90`<br>`vars/state.f90` | Allocate and release shared namespaces<br><br>Split by data owner |
| `ALLOCA_VARSINERC` | *Routines:*<br>`allocate_attributes`<br>`allocate_config`<br>`allocate_parameters`<br>`allocate_state`<br>matching `deallocate_*` procedures<br><br>*Modules:*<br>`vars/attributes.f90`<br>`vars/config.f90`<br>`vars/parameters.f90`<br>`vars/state.f90` | Allocate and release inertial-routing data<br><br>Split by data owner |
| `CELULA` | *Routines:*<br>`update_catchment`<br><br>*Modules:*<br>`hydrology/catchment.f90` | HRU water balance and catchment aggregation<br><br>Consolidated |
| `CondInic` | *Routines:*<br>`initialize_catchment`<br><br>*Modules:*<br>`hydrology/catchment.f90` | Initialize soil and terrestrial storages<br><br>Renamed and consolidated |
| `EVAPO` | *Routines:*<br>`calculate_et_demand`<br>`calculate_net_radiation`<br><br>*Modules:*<br>`hydrology/catchment.f90` | Energy balance and evapotranspiration<br><br>Absorbed into catchment procedures |
| `FINT` | *Routines:*<br>`linear_interpolate`<br><br>*Modules:*<br>`common/interpolation.f90` | Linear interpolation<br><br>Renamed |
| `flood_continuity` | *Routines:*<br>`update_inertial_continuity`<br><br>*Modules:*<br>`hydrology/river_inertial.f90` | Update inertial water continuity<br><br>Renamed |
| `flood_discharge` | *Routines:*<br>`calculate_inertial_discharge`<br><br>*Modules:*<br>`hydrology/river_inertial.f90` | Calculate inertial discharge<br><br>Renamed |
| `flood_inercial` | *Routines:*<br>`route_inertial_flow`<br><br>*Modules:*<br>`hydrology/river_inertial.f90` | Coordinate a local-inertial routing step<br><br>Renamed and consolidated |
| `flood_ini` | *Routines:*<br>`initialize_inertial_routing`<br>`prepare_inertial_routing`<br><br>*Modules:*<br>`hydrology/river_inertial.f90` | Initialize inertial state and prepare routing inputs<br><br>Split by lifecycle phase |
| `flood_readFP` | *Routines:*<br>`read_floodplain_binary_data`<br><br>*Modules:*<br>`io/static_input_io.f90` | Read binary floodplain tables<br><br>Renamed and moved |
| `flood_READHOT` | *Routines:*<br>`read_hotstart`<br><br>*Modules:*<br>`io/hotstart_io.f90` | Restore model state<br><br>Renamed and moved |
| `flood_TAB` | *Routines:*<br>`build_floodplain_tables`<br><br>*Modules:*<br>`hydrology/river_inertial.f90` | Build stage, area, and volume lookup tables<br><br>Renamed |
| `flood_timestep` | *Routines:*<br>`calculate_inertial_timestep`<br><br>*Modules:*<br>`hydrology/river_inertial.f90` | Select inertial substeps<br><br>Renamed |
| `flood_TOPO` | *Routines:*<br>`build_flood_topology`<br><br>*Modules:*<br>`hydrology/river_inertial.f90` | Build upstream connectivity<br><br>Renamed |
| `flood_WRITEHOT` | *Routines:*<br>`write_hotstart`<br><br>*Modules:*<br>`io/hotstart_io.f90` | Serialize model state<br><br>Renamed and moved |
| `LE_RESERV` | *Routines:*<br>`read_reservoir_data`<br>`initialize_reservoir_state`<br><br>*Modules:*<br>`io/reservoir_io.f90`<br>`hydrology/reservoirs.f90` | Read and initialize reservoir data<br><br>Split between I/O and hydrology |
| `LECELL` | *Routines:*<br>`read_catchment_data`<br><br>*Modules:*<br>`io/static_input_io.f90` | Read catchment network and HRU fractions<br><br>Renamed and moved |
| `LEFLOODPLN` | *Routines:*<br>`read_floodplain_text_data`<br><br>*Modules:*<br>`io/static_input_io.f90` | Read text floodplain geometry and face connections<br><br>Renamed and moved |
| `LESUBST` | *Routines:*<br>`read_substitution_flows`<br><br>*Modules:*<br>`io/reservoir_io.f90` | Read substituted discharge series<br><br>Renamed and moved |
| `LEUSO` | *Routines:*<br>`read_calibrated_parameters`<br><br>*Modules:*<br>`io/static_input_io.f90` | Read soil and routing parameters<br><br>Renamed and moved |
| `LEVAR` | *Routines:*<br>`read_fixed_parameters`<br><br>*Modules:*<br>`io/static_input_io.f90` | Read vegetation parameters and climate-region assignments<br><br>Renamed and moved |
| `MET_INPUT_FILES` | *Routines:*<br>`open_meteorological_inputs`<br>`close_meteorological_inputs`<br>`manage_meteorological_input_files`<br><br>*Modules:*<br>`io/meteorological_io.f90` | Manage meteorological file streams<br><br>Split into focused procedures |
| `MODELO` | *Routines:*<br>`run_timestep_loop`<br><br>*Modules:*<br>`simulation/runner.f90` | Execute timestep operations<br><br>Renamed and reorganized |
| `MUSK` | *Routines:*<br>`route_muskingum_cunge`<br><br>*Modules:*<br>`hydrology/river_muskingum.f90` | Route discharge through one reach<br><br>Renamed |
| `PARCEL` | *Routines:*<br>`calculate_catchment_time_of_concentration`<br>`calculate_muskingum_cunge_parameters`<br><br>*Modules:*<br>`hydrology/catchment.f90`<br>`hydrology/river_muskingum.f90` | Prepare catchment and routing parameters<br><br>Split by responsibility |
| `PARCUNGE` | *Routines:*<br>`calculate_muskingum_cunge_parameters`<br><br>*Modules:*<br>`hydrology/river_muskingum.f90` | Prepare Muskingum-Cunge coefficients<br><br>Renamed |
| `RADIACAO` | *Routines:*<br>`calculate_net_radiation`<br><br>*Modules:*<br>`hydrology/catchment.f90` | Calculate net radiation<br><br>Absorbed into catchment module |
| `READ_CLIM_AVG` | *Routines:*<br>`read_climatology`<br><br>*Modules:*<br>`io/meteorological_io.f90` | Read monthly climatology records<br><br>Renamed and moved |
| `READ_INFOMGB` | *Routines:*<br>`read_model_configuration`<br><br>*Modules:*<br>`io/configuration_io.f90` | Read simulation namelists<br><br>Renamed and moved |
| `READ_MET` | *Routines:*<br>`read_meteorological_forcing`<br><br>*Modules:*<br>`io/meteorological_io.f90` | Read a timestep of forcing<br><br>Renamed and moved |
| `REDE` | *Routines:*<br>`route_muskingum_cunge_network`<br><br>*Modules:*<br>`hydrology/river_muskingum.f90` | Route the catchment network<br><br>Renamed and consolidated |
| `SEMENTE` | *Routines:*<br>`initialize_random_seed`<br><br>*Modules:*<br>`common/runtime_support.f90` | Obtain a seed from the system clock<br><br>Renamed; current application has no call site |
| `SIMULA` | *Routines:*<br>`prepare_simulation`<br>`run_simulation`<br><br>*Modules:*<br>`simulation/runner.f90` | Prepare and run the simulation<br><br>Split by lifecycle phase |
| `SOLO` | *Routines:*<br>`update_soil_water_balance`<br><br>*Modules:*<br>`hydrology/catchment.f90` | Update soil storage and fluxes<br><br>Absorbed into `update_catchment` |
| `STAGEAREA` | *Routines:*<br>`interpolate_stage_area`<br><br>*Modules:*<br>`hydrology/river_inertial.f90` | Interpolate a stage-area relation<br><br>Renamed and moved |
| `TEMPO` | *Routines:*<br>`system_clock` elapsed-time reporting<br><br>*Modules:*<br>`simulation/main.f90` | Report elapsed runtime<br><br>Replaced; old start/stop actions have no separate entry point |
| `date_string` | *Routines:*<br>`format_date_string`<br><br>*Modules:*<br>`common/date_time.f90` | Format a model date<br><br>Renamed |
| `date_parser` | *Routines:*<br>`parse_date_string`<br><br>*Modules:*<br>`common/date_time.f90` | Parse a model date<br><br>Renamed |
| `julday_int` | *Routines:*<br>`calculate_integer_julian_day`<br><br>*Modules:*<br>`common/date_time.f90` | Calculate an integer Julian day<br><br>Renamed |
| `julday_rl` | *Routines:*<br>`calculate_julian_day`<br><br>*Modules:*<br>`common/date_time.f90` | Calculate a real Julian day<br><br>Renamed |
| `caldat_rl` | *Routines:*<br>`convert_julian_day_to_calendar`<br><br>*Modules:*<br>`common/date_time.f90` | Convert Julian day to calendar fields<br><br>Renamed |
| `time_diff` | *Routines:*<br>`calculate_timestep_count`<br><br>*Modules:*<br>`common/date_time.f90` | Calculate a timestep count<br><br>Renamed |
| `WRITE_OUTPUT` | *Routines:*<br>`write_model_outputs`<br>`open_model_outputs`<br>`close_model_outputs`<br><br>*Modules:*<br>`io/output_io.f90` | Write and manage output streams<br><br>Split into focused procedures |
| `OUTPUT_FILES` | *Routines:*<br>`manage_output_files`<br><br>*Modules:*<br>`io/output_io.f90` | Open or close enabled output streams<br><br>Renamed |

## Execution flow

Legacy `1main` read configuration, allocated shared data, read static and
climatological data, prepared routing, and called `SIMULA`. The current
`simulation/main.f90` reads configuration, allocates the five namespaces,
and calls `prepare_simulation` and `run_simulation`.

`SIMULA` initialized the catchment and routing state, handled hotstart
setup, and entered `MODELO`. The current `run_simulation` opens outputs,
initializes catchment and routing state, handles hotstarts, and calls
`run_timestep_loop`.

`MODELO` read forcing, called `CELULA`, routed through `REDE` or
`flood_inercial`, and called `WRITE_OUTPUT`. The current
`run_timestep_loop` reads forcing, calls catchment and selected routing
procedures, fills output buffers, and calls `output_io`.

The current timestep ordering and shared-state handoffs are described in
[Execution and data flow](../architecture/execution-and-data-flow.md). The
scientific order is detailed in
[Model processes and numerical assumptions](../model/model-processes.md).
