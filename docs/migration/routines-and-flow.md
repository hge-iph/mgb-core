# Legacy routines and execution flow

Legacy routine names below refer to procedures present at
[`41146b1`](https://github.com/HGE-IPH/MGB-model/commit/41146b1). Names in the
current column are procedures in the current source tree. “Absorbed” means the
calculation remains inside a larger procedure, often as a private helper or a
procedure-local section.

| Legacy routine | Current routine | Current module and source | Responsibility | Disposition |
| --- | --- | --- | --- | --- |
| `ALLOCA_VARS` | `allocate_attributes`, `allocate_config`, `allocate_forcing`, `allocate_parameters`, `allocate_state` and matching `deallocate_*` procedures | `vars/{attributes,config,forcing,parameters,state}.f90`; orchestration in `simulation/main.f90` | Allocate and release shared namespaces | Split by data owner |
| `ALLOCA_VARSINERC` | `allocate_attributes`, `allocate_config`, `allocate_parameters`, `allocate_state` and matching `deallocate_*` procedures | `vars/{attributes,config,parameters,state}.f90`; orchestration in `simulation/main.f90` | Allocate and release inertial-routing data | Split by data owner |
| `CELULA` | `update_catchment` | `hydrology/catchment.f90` | HRU water balance and catchment aggregation | Consolidated |
| `CondInic` | `initialize_catchment` | `hydrology/catchment.f90` | Initialize soil and terrestrial storages | Renamed and consolidated |
| `EVAPO` | `calculate_et_demand`; `calculate_net_radiation` | `hydrology/catchment.f90` | Energy balance and evapotranspiration | Absorbed into catchment procedures |
| `FINT` | `linear_interpolate` | `common/interpolation.f90` | Linear interpolation | Renamed |
| `flood_continuity` | `update_inertial_continuity` | `hydrology/river_inertial.f90` | Update inertial water continuity | Renamed |
| `flood_discharge` | `calculate_inertial_discharge` | `hydrology/river_inertial.f90` | Calculate inertial discharge | Renamed |
| `flood_inercial` | `route_inertial_flow` | `hydrology/river_inertial.f90` | Coordinate a local-inertial routing step | Renamed and consolidated |
| `flood_ini` | `initialize_inertial_routing`; `prepare_inertial_routing` | `hydrology/river_inertial.f90` | Initialize inertial state and prepare routing inputs | Split by lifecycle phase |
| `flood_readFP` | `read_floodplain_binary_data` | `io/static_input_io.f90` | Read binary floodplain tables | Renamed and moved |
| `flood_READHOT` | `read_hotstart` | `io/hotstart_io.f90` | Restore model state | Renamed and moved |
| `flood_TAB` | `build_floodplain_tables` | `hydrology/river_inertial.f90` | Build stage, area, and volume lookup tables | Renamed |
| `flood_timestep` | `calculate_inertial_timestep` | `hydrology/river_inertial.f90` | Select inertial substeps | Renamed |
| `flood_TOPO` | `build_flood_topology` | `hydrology/river_inertial.f90` | Build upstream connectivity | Renamed |
| `flood_WRITEHOT` | `write_hotstart` | `io/hotstart_io.f90` | Serialize model state | Renamed and moved |
| `LE_RESERV` | `read_reservoir_data`; `initialize_reservoir_state` | `io/reservoir_io.f90`, `hydrology/reservoirs.f90` | Read and initialize reservoir data | Split between I/O and hydrology |
| `LECELL` | `read_catchment_data` | `io/static_input_io.f90` | Read catchment network and HRU fractions | Renamed and moved |
| `LEFLOODPLN` | `read_floodplain_text_data` | `io/static_input_io.f90` | Read text floodplain geometry and face connections | Renamed and moved |
| `LESUBST` | `read_substitution_flows` | `io/reservoir_io.f90` | Read substituted discharge series | Renamed and moved |
| `LEUSO` | `read_calibrated_parameters` | `io/static_input_io.f90` | Read soil and routing parameters | Renamed and moved |
| `LEVAR` | `read_fixed_parameters` | `io/static_input_io.f90` | Read vegetation parameters and climate-region assignments | Renamed and moved |
| `MET_INPUT_FILES` | `open_meteorological_inputs`, `close_meteorological_inputs`, `manage_meteorological_input_files` | `io/meteorological_io.f90` | Manage meteorological file streams | Split into focused procedures |
| `MODELO` | `run_timestep_loop` | `simulation/runner.f90` | Execute timestep operations | Renamed and reorganized |
| `MUSK` | `route_muskingum_cunge` | `hydrology/river_muskingum.f90` | Route discharge through one reach | Renamed |
| `PARCEL` | `calculate_catchment_time_of_concentration`; `calculate_muskingum_cunge_parameters` | `hydrology/catchment.f90`, `hydrology/river_muskingum.f90` | Prepare catchment and routing parameters | Split by responsibility |
| `PARCUNGE` | `calculate_muskingum_cunge_parameters` | `hydrology/river_muskingum.f90` | Prepare Muskingum-Cunge coefficients | Renamed |
| `RADIACAO` | `calculate_net_radiation` | `hydrology/catchment.f90` | Calculate net radiation | Absorbed into catchment module |
| `READ_CLIM_AVG` | `read_climatology` | `io/meteorological_io.f90` | Read monthly climatology records | Renamed and moved |
| `READ_INFOMGB` | `read_model_configuration` | `io/configuration_io.f90` | Read simulation namelists | Renamed and moved |
| `READ_MET` | `read_meteorological_forcing` | `io/meteorological_io.f90` | Read a timestep of forcing | Renamed and moved |
| `REDE` | `route_muskingum_cunge_network` | `hydrology/river_muskingum.f90` | Route the catchment network | Renamed and consolidated |
| `SEMENTE` | `initialize_random_seed` | `common/runtime_support.f90` | Obtain a seed from the system clock | Renamed; current application has no call site |
| `SIMULA` | `prepare_simulation`, `run_simulation` | `simulation/runner.f90` | Prepare and run the simulation | Split by lifecycle phase |
| `SOLO` | `update_soil_water_balance` | `hydrology/catchment.f90` | Update soil storage and fluxes | Absorbed into `update_catchment` |
| `STAGEAREA` | `interpolate_stage_area` | `hydrology/river_inertial.f90` | Interpolate a stage-area relation | Renamed and moved |
| `TEMPO` | `system_clock` elapsed-time reporting in `simulation/main.f90` | `simulation/main.f90` | Report elapsed runtime | Replaced; old start/stop actions have no separate entry point |
| `date_string` | `format_date_string` | `common/date_time.f90` | Format a model date | Renamed |
| `date_parser` | `parse_date_string` | `common/date_time.f90` | Parse a model date | Renamed |
| `julday_int` | `calculate_integer_julian_day` | `common/date_time.f90` | Calculate an integer Julian day | Renamed |
| `julday_rl` | `calculate_julian_day` | `common/date_time.f90` | Calculate a real Julian day | Renamed |
| `caldat_rl` | `convert_julian_day_to_calendar` | `common/date_time.f90` | Convert Julian day to calendar fields | Renamed |
| `time_diff` | `calculate_timestep_count` | `common/date_time.f90` | Calculate a timestep count | Renamed |
| `WRITE_OUTPUT` | `write_model_outputs`, `open_model_outputs`, `close_model_outputs` | `io/output_io.f90` | Write and manage output streams | Split into focused procedures |
| `OUTPUT_FILES` | `manage_output_files` | `io/output_io.f90` | Open or close enabled output streams | Renamed |

## Execution flow

| Legacy flow | Current flow |
| --- | --- |
| `1main` read configuration, allocated shared data, read static and climatological data, prepared routing, then called `SIMULA`. | `simulation/main.f90` reads configuration, allocates the five namespaces, and calls `prepare_simulation` and `run_simulation`. |
| `SIMULA` initialized the catchment and routing state, handled hotstart setup, then entered `MODELO`. | `run_simulation` opens outputs, initializes catchment and routing state, handles hotstarts, and calls `run_timestep_loop`. |
| `MODELO` read forcing, called `CELULA`, routed through `REDE` or `flood_inercial`, then called `WRITE_OUTPUT`. | `run_timestep_loop` reads forcing, calls catchment and selected routing procedures, fills output buffers, then calls `output_io`. |

The current timestep ordering and shared-state handoffs are described in
[Execution and data flow](../architecture/execution-and-data-flow.md). The
scientific order is detailed in
[Model processes and numerical assumptions](../model/model-processes.md).
