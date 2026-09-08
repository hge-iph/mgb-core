# Cleanup and Documentation Language

## Overview

The `cleanup/docs-language` branch introduces MkDocs documentation and applies
a behavior-preserving English naming pass to the legacy Fortran source. The
change is intentionally limited to documentation, comments, encoding, source
filenames, and identifiers. Hydrological equations, operation order, constants,
input/output formats, and runtime messages are unchanged.

## Documentation changes

- MkDocs is the documentation generator, using its built-in theme and search.
- Pull requests validate the site with `mkdocs build --strict`.
- Project history, contributors, references, licensing, language guidance, and
  terminology are now maintained outside source headers.
- Fortran sources use UTF-8 and concise SPDX/purpose headers.

## Source migration ledger

This is the complete filename and program-unit migration ledger. A row with an
unchanged filename records a symbol-only rename.

| Legacy file | Legacy program unit | New file | New program unit |
| --- | --- | --- | --- |
| `1main.f90` | `MGB_Inercial` | `main.f90` | `mgb_model` |
| `vars_main.f90` | `VARS_MAIN` | `model_state.f90` | `model_state` |
| `vars_inerc.f90` | `VARS_INERC` | `inertial_state.f90` | `inertial_state` |
| `alloca_vars.f90` | `ALLOCA_VARS` | `allocate_model_state.f90` | `allocate_model_state` |
| `alloca_varsinerc.f90` | `ALLOCA_VARSINERC` | `allocate_inertial_state.f90` | `allocate_inertial_state` |
| `celula.f90` | `CELULA` | `update_catchment_water_balance.f90` | `update_catchment_water_balance` |
| `solo.f90` | `SOLO` | `update_soil_water_balance.f90` | `update_soil_water_balance` |
| `evapo.f90` | `EVAPO` | `calculate_evapotranspiration.f90` | `calculate_evapotranspiration` |
| `radiacao.f90` | `RADIACAO` | `calculate_net_radiation.f90` | `calculate_net_radiation` |
| `condinic.f90` | `CONDINIC` | `initialize_model_state.f90` | `initialize_model_state` |
| `simula.f90` | `SIMULA` | `run_simulation.f90` | `run_simulation` |
| `modelo.f90` | `MODELO` | `run_model.f90` | `run_model` |
| `rede.f90` | `REDE` | `route_muskingum_cunge_network.f90` | `route_muskingum_cunge_network` |
| `musk.f90` | `MUSK` | `route_muskingum_cunge.f90` | `route_muskingum_cunge` |
| `parcel.f90` | `PARCEL` | `calculate_catchment_parameters.f90` | `calculate_catchment_parameters` |
| `parcunge.f90` | `PARCUNGE` | `calculate_muskingum_cunge_parameters.f90` | `calculate_muskingum_cunge_parameters` |
| `lecell.f90` | `LECELL` | `read_catchment_data.f90` | `read_catchment_data` |
| `leuso.f90` | `LEUSO` | `read_calibrated_parameters.f90` | `read_calibrated_parameters` |
| `levar.f90` | `LEVAR` | `read_fixed_parameters.f90` | `read_fixed_parameters` |
| `lesubst.f90` | `LESUBST` | `read_substitution_flows.f90` | `read_substitution_flows` |
| `le_reserv.f90` | `LE_RESERV` | `read_reservoir_data.f90` | `read_reservoir_data` |
| `flood_readfp.f90` | `flood_readFP` | `read_floodplain_binary_data.f90` | `read_floodplain_binary_data` |
| `lefloodpln.f90` | `LEFLOODPLN` | `read_floodplain_text_data.f90` | `read_floodplain_text_data` |
| `read_infomgb.f90` | `READ_INFOMGB` | `read_model_configuration.f90` | `read_model_configuration` |
| `read_clim_avg.f90` | `READ_CLIM_AVG` | `read_climatology.f90` | `read_climatology` |
| `read_met.f90` | `READ_MET` | `read_meteorological_forcing.f90` | `read_meteorological_forcing` |
| `met_input_files.f90` | `MET_INPUT_FILES` | `manage_meteorological_input_files.f90` | `manage_meteorological_input_files` |
| `write_output.f90` | `WRITE_OUTPUT` | `write_model_outputs.f90` | `write_model_outputs` |
| `write_output.f90` | `OUTPUT_FILES` | `write_model_outputs.f90` | `manage_output_files` |
| `flood_topo.f90` | `flood_TOPO` | `build_flood_topology.f90` | `build_flood_topology` |
| `flood_tab.f90` | `flood_TAB` | `build_floodplain_tables.f90` | `build_floodplain_tables` |
| `flood_timestep.f90` | `flood_timestep` | `calculate_inertial_timestep.f90` | `calculate_inertial_timestep` |
| `flood_discharge.f90` | `flood_discharge` | `calculate_inertial_discharge.f90` | `calculate_inertial_discharge` |
| `flood_continuity.f90` | `flood_continuity` | `update_inertial_continuity.f90` | `update_inertial_continuity` |
| `flood_inercial.f90` | `flood_inercial` | `route_inertial_flow.f90` | `route_inertial_flow` |
| `flood_ini.f90` | `flood_ini` | `initialize_inertial_routing.f90` | `initialize_inertial_routing` |
| `flood_readhot.f90` | `flood_READHOT` | `read_hotstart.f90` | `read_hotstart` |
| `flood_writehot.f90` | `flood_WRITEHOT` | `write_hotstart.f90` | `write_hotstart` |
| `stagearea.f90` | `STAGEAREA` | `interpolate_stage_area.f90` | `interpolate_stage_area` |
| `fint.f90` | `FINT` | `linear_interpolate.f90` | `linear_interpolate` |
| `semente.f90` | `SEMENTE` | `initialize_random_seed.f90` | `initialize_random_seed` |
| `tempo.f90` | `TEMPO` | `update_legacy_timer.f90` | `update_legacy_timer` |
| `utils_date.f90` | `date_string` | `utils_date.f90` | `format_date_string` |
| `utils_date.f90` | `date_parser` | `utils_date.f90` | `parse_date_string` |
| `utils_time.f90` | `julday_int` | `utils_time.f90` | `calculate_integer_julian_day` |
| `utils_time.f90` | `julday_rl` | `utils_time.f90` | `calculate_julian_day` |
| `utils_time.f90` | `caldat_rl` | `utils_time.f90` | `convert_julian_day_to_calendar` |
| `utils_time.f90` | `time_diff` | `utils_time.f90` | `calculate_timestep_count` |

### Shared-state symbol ledger

The renamed module state is source-visible, so its migration is recorded here
as well. Conventional scientific components such as `q`, `v`, `et`, `dt`,
`hru`, `x`, and `y` remain within descriptive names.

| Legacy symbols | New symbols |
| --- | --- |
| `NUP`, `NBP`, `NUMUSK` | `max_hru_count`, `max_subbasin_count`, `max_muskingum_reach_count` |
| `NC`, `NU`, `NCLI`, `NREG`, `NB`, `NT` | `catchment_count`, `hru_count`, `climate_cell_count`, `climate_region_count`, `subbasin_count`, `timestep_count` |
| `NUMSUBST`, `ISUBST`, `nSIN` | `substitution_count`, `substitution_catchment`, `reservoir_count` |
| `IT`, `IC`, `IU`, `IB` | `timestep_index`, `catchment_index`, `hru_index`, `subbasin_index` |
| `INPUT_DIRECTORY_HOTSTART` | `hotstart_input_directory` |
| `FILFIX`, `FILVAR`, `FILUSO`, `FILHIG`, `FILCLIREG`, `FILSUBS` | `config_unit`, `fixed_parameter_unit`, `calibrated_parameter_unit`, `catchment_data_unit`, `climate_region_unit`, `substitution_flow_unit` |
| `FILSTAGE`, `FILAREA`, `FILCLIMATEbin`, `FILHOTSTART_WB`, `FILHOTSTART_Inert` | `flood_stage_unit`, `flood_area_unit`, `climatology_unit`, `water_balance_hotstart_unit`, `inertial_hotstart_unit` |
| `FILLOG`, `FILCOTAREA`, `FILFACE`, `FILHOTLIST` | `log_unit`, `stage_area_unit`, `face_connection_unit`, `hotstart_list_unit` |
| `FILPLU`, `FILTEMP`, `FILRAD`, `FILRELH`, `FILWIND`, `FILPRES` | `precipitation_unit`, `temperature_unit`, `radiation_unit`, `relative_humidity_unit`, `wind_unit`, `pressure_unit` |
| `FIL_FLOW`, `FIL_ET`, `FIL_WSE`, `FIL_HAND`, `FIL_TWS`, `FIL_FLOOD` | `discharge_output_unit`, `et_output_unit`, `water_surface_elevation_output_unit`, `hand_output_unit`, `total_water_storage_output_unit`, `flooded_area_output_unit` |
| `FIL_SSATD`, `FIL_ETINT`, `FIL_ETSOILVEG`, `FIL_ETOPENW`, `FIL_SOILWATER` | `soil_saturation_output_unit`, `interception_et_output_unit`, `soil_vegetation_et_output_unit`, `open_water_et_output_unit`, `soil_water_output_unit` |
| `FIL_VBAS`, `FIL_VINT`, `FIL_VSUP`, `FIL_VINTERC` | `groundwater_storage_output_unit`, `subsurface_storage_output_unit`, `surface_storage_output_unit`, `interception_storage_output_unit` |
| `FIL_DBAS`, `FIL_DINT`, `FIL_DSUP`, `FIL_SURFWAT`, `FIL_RUNOFF` | `groundwater_flux_output_unit`, `subsurface_flux_output_unit`, `surface_flux_output_unit`, `surface_water_output_unit`, `runoff_output_unit` |
| `FIL_ETURHWAT`, `FIL_POTETWAT` | `water_hru_et_output_unit`, `potential_open_water_et_output_unit` |
| `flag_IN_TEMP`, `flag_IN_RAD`, `flag_IN_RH`, `flag_IN_WIND`, `flag_IN_PRES` | `use_temperature_timeseries`, `use_radiation_timeseries`, `use_humidity_timeseries`, `use_wind_timeseries`, `use_pressure_timeseries` |
| `flag_OUT_FLOW`, `flag_OUT_SM`, `flag_OUT_WSE`, `flag_OUT_HAND` | `write_discharge_output`, `write_soil_moisture_output`, `write_water_surface_elevation_output`, `write_hand_output` |
| `flag_OUT_TWS`, `flag_OUT_RUNOFF`, `flag_OUT_SURFWAT`, `flag_OUT_SSATD` | `write_total_water_storage_output`, `write_runoff_output`, `write_surface_water_output`, `write_soil_saturation_output` |
| `flag_OUT_ET`, `flag_OUT_ETINT`, `flag_OUT_ETSOILVEG`, `flag_OUT_ETOPENWAT` | `write_et_output`, `write_interception_et_output`, `write_soil_vegetation_et_output`, `write_open_water_et_output` |
| `flag_OUT_ETURHWAT`, `flag_OUT_POTETWAT` | `write_water_hru_et_output`, `write_potential_open_water_et_output` |
| `flag_OUT_VBAS`, `flag_OUT_VINT`, `flag_OUT_VSUP`, `flag_OUT_VINTERC` | `write_groundwater_storage_output`, `write_subsurface_storage_output`, `write_surface_storage_output`, `write_interception_storage_output` |
| `flag_OUT_FLAREA`, `flag_OUT_DBAS`, `flag_OUT_DINT`, `flag_OUT_DSUP` | `write_flooded_area_output`, `write_groundwater_flux_output`, `write_subsurface_flux_output`, `write_surface_flux_output` |
| `QTUDO`, `YTUDO`, `TWSTUDO`, `ALAGTUDO`, `HANDTUDO` | `q_river_output`, `water_surface_elevation_output`, `total_water_storage_output`, `flooded_area_output`, `hand_output` |
| `QLIDO`, `KCB` | `substituted_q`, `catchments_per_subbasin` |
| `iday`, `imonth`, `iyear`, `ihour`, `iminute`, `doy`, `jday` | `day`, `month`, `year`, `hour`, `minute`, `day_of_year`, `julian_day` |
| `QESP`, `ALB`, `RIAF`, `Z`, `RS` | `specific_baseflow`, `albedo`, `leaf_area_index`, `vegetation_height`, `surface_resistance` |
| `NSUBT`, `DT`, `CEL`, `TIND` | `muskingum_reach_count`, `muskingum_timestep`, `wave_celerity`, `concentration_time` |
| `WM`, `B`, `KINS`, `KBAS`, `PLAM`, `CAP`, `WC`, `KINF` | `max_soil_water_storage`, `arno_b`, `subsurface_conductivity`, `groundwater_conductivity`, `brooks_corey_lambda`, `max_capillary_flux`, `capillary_threshold_fraction`, `floodplain_infiltration_rate` |
| `CI`, `CB`, `CS`, `AUSO` | `subsurface_routing_coefficient`, `groundwater_routing_coefficient`, `surface_routing_coefficient`, `hru_name` |
| `IEXUT`, `BRIO`, `BRX`, `IBAC`, `CELJUS` | `subbasin_outlet_catchment`, `river_width`, `current_river_width`, `catchment_subbasin`, `downstream_catchment` |
| `HCEL`, `LCEL`, `X`, `Y`, `REGCLI` | `longest_reach_slope`, `longest_reach_length`, `catchment_x`, `catchment_y`, `climate_region` |
| `ACEL`, `ACUR`, `SRIO`, `DECL`, `PUSO`, `QREF`, `QRX` | `catchment_area`, `drainage_area`, `river_length`, `river_slope`, `hru_percentage`, `reference_q`, `current_reference_q` |
| `TAMM`, `URMM`, `VVMM`, `PAMM`, `SOLMM`, `XYC` | `monthly_air_temperature`, `monthly_relative_humidity`, `monthly_wind_speed`, `monthly_air_pressure`, `monthly_solar_input`, `climate_station_coordinates` |
| `CABE`, `SI`, `XLADO`, `DH`, `ARX` | `header_fields`, `interception_storage`, `current_reach_length`, `elevation_difference`, `current_area` |
| `QM1`, `QJ1`, `QM2`, `QJ2`, `QCEL1`, `QCEL2` | `incoming_q_previous`, `outgoing_q_previous`, `incoming_q_current`, `outgoing_q_current`, `catchment_q_previous`, `catchment_q_current` |
| `PMB2`, `PMI2`, `PMS2`, `PJB2`, `PJI2`, `PJS2` | current incoming/outgoing groundwater, subsurface, and surface flow fractions |
| `PMB1`, `PMI1`, `PMS1`, `PJB1`, `PJI1`, `PJS1` | previous incoming/outgoing groundwater, subsurface, and surface flow fractions |
| `VRB`, `VRI`, `VRS` | `groundwater_routing_volume`, `subsurface_routing_volume`, `surface_routing_volume` |
| `ET`, `CAF`, `W`, `QBAS`, `QINT`, `QSUP`, `VBAS`, `VINT`, `VSUP` | `evapotranspiration`, `capillary_flux`, `soil_water_storage`, `groundwater_q`, `subsurface_q`, `surface_q`, `groundwater_storage`, `subsurface_storage`, `surface_storage` |
| `TONTEM`, `P`, `TA`, `UR`, `VV`, `SOL`, `PA`, `DTP` | `previous_air_temperature`, `precipitation`, `air_temperature`, `relative_humidity`, `wind_speed`, `solar_input`, `air_pressure`, `model_timestep_seconds` |
| `GLAT`, `SOLX`, `T1`, `ALBX`, `RLX`, `RDIA`, `URX` | `latitude_degrees`, `current_solar_input`, `previous_temperature`, `current_albedo`, `net_radiation`, `day_of_year_real`, `current_relative_humidity` |
| `MESP`, `STEBOL`, `CLATE`, `SDECL`, `SANG`, `HIM`, `DR` | `water_density`, `stefan_boltzmann_constant`, `latent_heat_vaporization`, `solar_declination`, `sunset_hour_angle`, `max_sunshine_hours`, `earth_sun_distance_factor` |
| `GS`, `STO`, `SSUP`, `SN`, `ED`, `ES`, `SLONG` | `ground_heat_flux`, `top_atmosphere_radiation`, `incoming_shortwave_radiation`, `net_shortwave_radiation`, `actual_vapor_pressure`, `saturation_vapor_pressure`, `longwave_radiation` |
| `CLI_INDEX`, `flag_RES_SUB`, `flag_opt_rout`, `flag_pseudo_two_d` | `monthly_radiation_option`, `reservoir_substitution_enabled`, `inertial_routing_enabled`, `pseudo_two_d_enabled` |
| `WX`, `WMX`, `PAX`, `TAX`, `VVX` | `current_soil_water_storage`, `current_max_soil_water_storage`, `current_air_pressure`, `current_air_temperature`, `current_wind_speed` |
| `BX`, `KIX`, `KBX`, `RIAFX`, `ZX` | `current_arno_b`, `current_subsurface_conductivity`, `current_groundwater_conductivity`, `current_leaf_area_index`, `current_vegetation_height` |
| `EX`, `PX`, `SIX`, `VVX2`, `KINFX` | `soil_vegetation_et`, `current_precipitation`, `current_interception_storage`, `wind_speed_2m`, `current_floodplain_infiltration_rate` |
| `XL`, `T2`, `RSX`, `CAPX`, `ETX`, `WCX` | `current_brooks_corey_lambda`, `current_temperature`, `current_surface_resistance`, `current_capillary_flux`, `current_total_et`, `current_capillary_threshold_fraction` |
| `VBX`, `VIX`, `VSX`, `PPU`, `WXB`, `DCAP` | `remaining_groundwater_storage`, `remaining_subsurface_storage`, `remaining_surface_storage`, `hru_area_fraction`, `catchment_soil_water_sum`, `catchment_capillary_q` |
| `D`, `DEL`, `GAMA`, `MSPA`, `RUG` | `vapor_pressure_deficit`, `saturation_vapor_pressure_slope`, `psychrometric_constant`, `air_density`, `surface_roughness` |
| `SF`, `SIL`, `EIX`, `EIXP`, `EVQ`, `REIX`, `FDE` | `available_interception_storage`, `max_interception_storage`, `potential_interception_et`, `potential_open_water_et_current`, `open_water_evaporation_q`, `actual_interception_et`, `remaining_et_demand_fraction` |
| `CSPA`, `RA`, `RAEP`, `WL`, `WPM`, `F4` | `wet_air_specific_heat`, `aerodynamic_resistance`, `open_water_aerodynamic_resistance`, `soil_moisture_unlimited_et_threshold`, `wilting_point`, `surface_resistance_factor` |
| `QCONTORM`, `QCONTORJ`, `QRIOINI`, `OD`, `sbtFLAG` | `incoming_q_boundary`, `outgoing_q_boundary`, `initial_river_q`, `catchment_order`, `substitution_enabled` |
| `E0agua`, `E0TOPO`, `E0SUP`, `QITUDO`, `EVAPTUDO`, `QBASTUDO`, `WSATDEGREE` | `potential_open_water_et`, `potential_top_radiation_et`, `potential_surface_radiation_et`, `incremental_q_output`, `et_output`, `groundwater_q_output`, `soil_saturation_output` |
| `ETINTERC`, `ETSOILPLANT`, `ETOPENWAT`, `EVAPURHAGUA`, `POTETWAT` | `interception_et_output`, `soil_vegetation_et_output`, `open_water_et_output`, `water_hru_et_output`, `potential_open_water_et_output` |
| `SOILWATER`, `CAPWATER`, `VINTERC`, `SURFWAT`, `QCELTUDO`, `TWS2` | `soil_water_output`, `capillary_water_output`, `interception_storage_output`, `surface_water_output`, `catchment_q_output`, `total_water_storage` |
| `VSUPMMDIA`, `VINTMMDIA`, `VBASMMDIA` | `surface_storage_depth_output`, `subsurface_storage_depth_output`, `groundwater_storage_depth_output` |
| `DSUPMMDIA`, `DINTMMDIA`, `DBASMMDIA` | `surface_runoff_depth_output`, `subsurface_runoff_depth_output`, `groundwater_runoff_depth_output` |
| `vflow`, `WriteHotFile`, `SUBini`, `SUBfim` | `flow_velocity`, `hotstart_write_schedule`, `first_subbasin`, `last_subbasin` |
| `Ind_Reserv`, `CELJUS2`, `iTini_Reserv`, `RUGMAN` | `reservoir_index_by_catchment`, `routing_downstream_catchment`, `reservoir_start_timestep`, `manning_n` |
| `ACELX`, `WMMINI`, `TKB`, `TKI`, `TKS` | `current_catchment_area`, `minimum_soil_storage`, `groundwater_delay`, `subsurface_delay`, `surface_delay` |
| `alpha`, `g`, `nMan`, `HDFLAG`, `hdFLAG0`, `MINIMONT` | `courant_alpha`, `gravity`, `inertial_manning_n`, `routing_method`, `inertial_catchment_count`, `upstream_topology` |
| `NPFL`, `ZFUNDOFL`, `ZFL`, `AFL`, `HRIO`, `HRX` | `floodplain_point_count`, `floodplain_bottom_elevation`, `floodplain_elevation`, `floodplain_area`, `bankfull_depth`, `current_bankfull_depth` |
| `ZTAB`, `VTAB`, `ATAB` | `stage_table`, `volume_table`, `area_table` |
| `dtfloodmax`, `dtflood`, `dtflood0`, `tflood`, `hmaxfl` | `max_inertial_timestep`, `inertial_timestep`, `remaining_model_timestep`, `inertial_elapsed_time`, `max_water_depth` |
| `Q2fl`, `Qmont`, `Vol2`, `Vol1`, `SumQup`, `Area2`, `Hfl`, `Yfl` | `inertial_q`, `upstream_q`, `current_water_volume`, `previous_water_volume`, `sum_upstream_q`, `current_flooded_area`, `water_depth`, `water_surface_elevation` |
| `Sflow`, `hflow`, `dxflow`, `bflow`, `xMan`, `bflow_overland`, `xMan_overland` | `flow_slope`, `flow_depth`, `flow_length`, `flow_width`, `flow_manning_n`, `overland_flow_width`, `overland_manning_n` |
| `WSslope`, `iCJus`, `Nentradas`, `y2_fl` | `downstream_water_surface_slope`, `downstream_catchment_index`, `upstream_count`, `updated_water_surface_elevation` |
| `nFACE`, `iFACE`, `KCAT`, `KCAT2` | `face_count`, `face_index`, `first_face_catchment_index`, `second_face_catchment_index` |
| `nFACECAT1`, `nFACECAT2`, `Q2face`, `nFACEY1`, `nFACEY2`, `nFACEDX`, `Q2viz` | `face_catchment_1`, `face_catchment_2`, `face_q`, `first_face_elevation`, `second_face_elevation`, `face_distance`, `neighbor_q` |
| `jtab`, `DINFILT`, `DINFILTX`, `areajtab`, `yjtab` | `stage_table_index`, `floodplain_infiltration`, `current_floodplain_infiltration`, `interpolated_area`, `interpolated_stage` |
| `TWS`, `flag_WriteHot`, `flag_ReadHot`, `Qdefl` | `grace_total_water_storage`, `write_hotstart_mode`, `read_hotstart_mode`, `reservoir_outflow` |
| `volume_temp` | removed; it was an unused OpenMP private-list residue |

Routine arguments and locals use the same convention; they are not linkable
interfaces in this executable-only repository. Examples include `DSUP` to
`surface_runoff_depth`, `DINT` to `subsurface_runoff_depth`, `DBAS` to
`groundwater_runoff_depth`, `JUS` to `downstream_index`, and `TK` to
`routing_delay_seconds`.

## Compatibility

The executable remains `mgb_model`. Namelist keys in `infomgb.sim`, literal
runtime filenames, directory names, record lengths, formats, binary layouts,
and output/log text are unchanged. External source code that imported the old
modules or called the old routine symbols must use the mapping above.

## Validation

Validation completed on Linux x64:

- Documentation: Python 3.13, MkDocs 1.6.1; dependency installation and
  `python -m mkdocs build --strict` passed. Pull requests run the same build
  under Python 3.12.
- Model: Intel `ifx` 2025.3.3 and CMake 4.4.3; the temporary-directory CMake
  build completed successfully after loading the Intel compiler and MKL 2025.3
  environments.
- Regression: `regression_magdalena` passed against the committed fixtures.
- Baseline: `qtudo.mgb`, `ytudo.mgb`, `twstudo.mgb`, and `floodtudo.mgb` are
  byte-identical to outputs generated from clean `main` at `41146b1`.
- Hygiene: every `.f90` source decodes as UTF-8, the retired program-unit names
  have no code references, `git diff --check` passes, and no regression fixture
  or runtime input-format file changed.
