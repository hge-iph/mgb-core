# Breaking runtime migration

The cleanup keeps the descriptive source identifiers but restores the
established runtime input filenames. Use the current names exactly; the
executable does not search for aliases. Payloads, numerical fields, row order,
record ordering, and units are unchanged.

## Configuration

| Legacy name | Canonical name |
| --- | --- |
| infomgb.sim and model_config.nml | config.nml |
| model group names and abbreviated groups | model, forcing, routing, output |
| simulation date/timestep and count abbreviations | simulation_start, simulation_end, timestep, first_subbasin, last_subbasin, catchment_count, hru_count, subbasin_count, climate_region_count |
| hotstart flags and reservoir flags | hotstart_read_mode, hotstart_write_mode, reservoir_substitution_enabled, reservoir_count |
| forcing flags | use_temperature_timeseries, use_radiation_timeseries, use_humidity_timeseries, use_wind_timeseries, use_pressure_timeseries, monthly_radiation_option |
| routing flags and parameters | routing_mode, thread_count, downstream_boundary_slope, courant_alpha |
| output flags | write_discharge, write_water_surface_elevation, write_flooded_level, write_runoff, write_soil_water, write_soil_saturation, write_total_water_storage, write_surface_water, write_evapotranspiration, write_interception_evaporation, write_soil_vegetation_evapotranspiration, write_open_water_evaporation, write_water_hru_evaporation, write_potential_open_water_evaporation, write_groundwater_storage, write_subsurface_storage, write_surface_storage, write_interception_storage, write_groundwater_flux, write_subsurface_flux, write_surface_flux, write_flooded_area |

The table groups keys by function because several historical releases used
different abbreviations. The canonical key list in io-reference.md is
authoritative, and physical units are documented in comments rather than
encoded in names.

## Input files

| Previous/legacy name | Current name |
| --- | --- |
| vegetation_parameters.txt | vegetation.par |
| hru_definitions.txt | hru.def |
| climate_regions.txt | climate.reg |
| catchment_data.txt | mini.gtp |
| soil_parameters.txt | soil.par |
| chuvabin.pbi | precipitation.bin |
| medias_cru.bin | monthly_climatology.bin |
| met_temp.pbi | air_temperature.bin |
| met_radiation.pbi | solar_radiation.bin |
| met_relh.pbi | relative_humidity.bin |
| met_wind.pbi | wind_speed.bin |
| met_pres.pbi | air_pressure.bin |
| cota_area.flp | floodplain_stage_area.txt |
| face.con | floodplain_connections.txt |
| qsubst.qsb | substitution_flows.txt |
| observed_discharge.txt | observed_discharge.dat |
| hotstartlist.prev | hotstart_schedule.txt |
| sin_minibacias_lago.txt | reservoir_config.txt |
| sin_dados_defluencia.txt | reservoir_outflow.txt |
| statevars_wb_DATE.hot | water_balance_state_DATE.bin |
| statevars_inertial_DATE.hot | inertial_state_DATE.bin |
| flood_stage.bin | flood_stage.bin |
| flood_area.bin | flood_area.bin |

## Output and fixture files

| Legacy name | Canonical name |
| --- | --- |
| qtudo.mgb | discharge.bin |
| ytudo.mgb | level.bin |
| qceltudo.mgb | runoff.bin |
| soilwater.mgb | soil_water.bin |
| wsatdegree.mgb | soil_saturation.bin |
| twstudo.mgb | total_water_storage.bin |
| handtudo.mgb | flooded_level.bin |
| evaptudo.mgb | evapotranspiration.bin |
| evapinterc.mgb | interception_evaporation.bin |
| evapsoilplant.mgb | soil_vegetation_evapotranspiration.bin |
| evapopenwater.mgb | open_water_evaporation.bin |
| evapurhagua.mgb | water_hru_evaporation.bin |
| evappotagua.mgb | potential_open_water_evaporation.bin |
| surfwater.mgb | surface_water.bin |
| vbas.mgb | groundwater_storage.bin |
| vint.mgb | subsurface_storage.bin |
| vsup.mgb | surface_storage.bin |
| vinterc.mgb | interception_storage.bin |
| dbas.mgb | groundwater_flux.bin |
| dint.mgb | subsurface_flux.bin |
| dsup.mgb | surface_flux.bin |
| floodtudo.mgb | flooded_area.bin |
| log_mgb.txt | model.log |
| ajuste.fob | model_performance.txt |
| nosolo.txt | soil_diagnostics.txt |

## HRU labels

The identifiers in vegetation.par and soil.par are blc_01 through blc_09. They
correspond to the nine rows in hru.def. Only the labels changed; row order and
numerical fields are preserved. The current hru.def contents are authoritative.
