# Runtime name mapping

This page compares the names read or written by the executable at the legacy
baseline [`41146b1`](https://github.com/HGE-IPH/MGB-model/commit/41146b1) with
the current readers and writers. It documents runtime-interface changes
separately from the Fortran source mapping. Old names are not accepted as
aliases where a name changed.

The current file contracts, record layouts, and units are authoritative in
the [I/O reference](../architecture/io-reference.md). Runtime paths are
relative to `input/`, `output/`, and `hotstart/` as described there.

## Configuration file and namelists

The legacy file was `input/infomgb.sim`; the current file is
`input/config.nml`. The four groups and keys changed as follows.

| Legacy namelist group | Current group |
| --- | --- |
| `mgb_config_global` | `model` |
| `mgb_config_forcing` | `forcing` |
| `mgb_config_routing` | `routing` |
| `mgb_config_output` | `output` |

| Legacy key | Current key | Meaning |
| --- | --- | --- |
| `SIM_START_DATE` | `simulation_start` | Start calendar date |
| `SIM_END_DATE` | `simulation_end` | End calendar date |
| `SIM_TIMESTEP` | `model_timestep` | Meteorological timestep in seconds |
| `HOTSTART_READ` | `hotstart_read_mode` | Hotstart read mode |
| `HOTSTART_WRITE` | `hotstart_write_mode` | Hotstart write mode |
| `SUBASIN_START` | `first_subbasin` | First simulated subbasin |
| `SUBASIN_END` | `last_subbasin` | Last simulated subbasin |
| `N_UNIT_CATCHM` | `catchment_count` | Number of catchments |
| `N_HRUS` | `hru_count` | Number of HRUs |
| `N_SUBASINS` | `subbasin_count` | Number of subbasins |
| `N_CLI_REGIONS` | `climate_region_count` | Number of climate regions |
| `OPT_RES_SUB` | `reservoir_substitution_enabled` | Enable reservoir substitution |
| `N_RES_SUB` | `reservoir_count` | Number of reservoir records |
| `TS_TEMP` | `use_temperature_timeseries` | Read temperature time series |
| `TS_RAD` | `use_radiation_timeseries` | Read radiation time series |
| `TS_RH` | `use_humidity_timeseries` | Read humidity time series |
| `TS_WIND` | `use_wind_timeseries` | Read wind time series |
| `TS_PRES` | `use_pressure_timeseries` | Read pressure time series |
| `OPT_MONTH_RAD` | `monthly_radiation_option` | Monthly radiation input representation |
| `OPT_ROUTING` | `routing_mode` | 0 Muskingum-Cunge; 1 local inertial |
| `IN_DOWN_SLOPE` | `downstream_boundary_slope` | Downstream slope in m/km |
| `IN_COURANT_ALPHA` | `courant_alpha` | Inertial stability factor |
| `N_THREADS` | `thread_count` | OpenMP thread count |
| `OUT_FLOW` | `write_discharge` | Write discharge |
| `OUT_WSE` | `write_water_surface_elevation` | Write water-surface elevation |
| `OUT_HAND` | `write_flooded_level` | Write HAND-relative flooded level |
| `OUT_RUNOFF` | `write_runoff` | Write runoff |
| `OUT_SM` | `write_soil_water` | Write soil water |
| `OUT_SSAT` | `write_soil_saturation` | Write soil saturation |
| `OUT_TWS` | `write_total_water_storage` | Write total water storage |
| `OUT_SURFWAT` | `write_surface_water` | Write surface water |
| `OUT_ET` | `write_evapotranspiration` | Write total evapotranspiration |
| `OUT_ETINT` | `write_interception_evaporation` | Write interception evaporation |
| `OUT_ETSOILVEG` | `write_soil_vegetation_evapotranspiration` | Write soil and vegetation evapotranspiration |
| `OUT_ETOPENWAT` | `write_open_water_evaporation` | Write open-water evaporation |
| `OUT_ETURHWAT` | `write_water_hru_evaporation` | Write water-HRU evaporation |
| `OUT_POTETWAT` | `write_potential_open_water_evaporation` | Write potential open-water evaporation |
| `OUT_VBAS` | `write_groundwater_storage` | Write groundwater storage |
| `OUT_VINT` | `write_subsurface_storage` | Write subsurface storage |
| `OUT_VSUP` | `write_surface_storage` | Write surface storage |
| `OUT_VINTERC` | `write_interception_storage` | Write interception storage |
| `OUT_DBAS` | `write_groundwater_flux` | Write groundwater flux |
| `OUT_DINT` | `write_subsurface_flux` | Write subsurface flux |
| `OUT_DSUP` | `write_surface_flux` | Write surface flux |
| `OUT_FLAREA` | `write_flooded_area` | Write flooded area |

`downstream_boundary_slope` is read in m/km, then converted internally to
m/m. The current key names and complete key set are also listed in the
[I/O reference](../architecture/io-reference.md#configuration).

## Static and meteorological input files

| Legacy name at `41146b1` | Current name | Notes |
| --- | --- | --- |
| `albiaf.fix` | `vegetation.par` | Monthly vegetation parameter blocks |
| `climate_regions.fix` | `climate.reg` | Catchment-to-climate-region assignments |
| `paruso.cal` | `soil.par` | Soil and routing calibration parameters |
| `mini.gtp` | `mini.gtp` | Name retained; catchment and network records |
| `cota_area.flp` | `floodplain_stage_area.txt` | Text stage-area relations |
| `face.con` | `floodplain_connections.txt` | Text face connections |
| `qsubst.qsb` | `substitution_flows.txt` | Substitution discharge series |
| `chuvabin.pbi` | `precipitation.bin` | Precipitation records |
| `medias_cru.bin` | `monthly_climatology.bin` | Monthly climatology records |
| `met_temp.pbi` | `air_temperature.bin` | Optional temperature records |
| `met_radiation.pbi` | `solar_radiation.bin` | Optional radiation records |
| `met_relh.pbi` | `relative_humidity.bin` | Optional humidity records |
| `met_wind.pbi` | `wind_speed.bin` | Optional wind records |
| `met_pres.pbi` | `air_pressure.bin` | Optional pressure records |
| `flood_stage.bin` | `flood_stage.bin` | Name retained; binary floodplain stage data |
| `flood_area.bin` | `flood_area.bin` | Name retained; binary floodplain area data |
| `input/sin_minibacias_lago.txt` | `reservoir_config.txt` | Reservoir-to-catchment configuration; the legacy reader hard-coded the `input/` prefix |
| `input/sin_dados_defluencia.txt` | `reservoir_outflow.txt` | Reservoir outflow records; the legacy reader hard-coded the `input/` prefix |
| `hotstartlist.prev` | `hotstart_schedule.txt` | Scheduled hotstart times |

These legacy support files are not opened by the model's Fortran readers.
Their fixture/tool correspondences are:

| Legacy fixture or tool file | Current fixture or tool file | Role |
| --- | --- | --- |
| `blocos.hrc` | `hru.def` | HRU dictionary used to describe the parameter-row labels |
| `qobs.qob` | `observed_discharge.dat` | Observed-flow data for regression or performance tooling |
| `ajuste.fob` | `model_performance.txt` | Performance-metric sidecar |
| `nosolo.txt` | `soil_diagnostics.txt` | Soil-diagnostic sidecar |

These correspondences do not make the files executable inputs or outputs. See
the [I/O reference](../architecture/io-reference.md#input-files).

## Output files

| Legacy output | Current output | Meaning |
| --- | --- | --- |
| `qtudo.mgb` | `discharge.bin` | River discharge |
| `ytudo.mgb` | `level.bin` | Water-surface elevation |
| `qceltudo.mgb` | `runoff.bin` | Catchment runoff |
| `soilwater.mgb` | `soil_water.bin` | Soil water |
| `wsatdegree.mgb` | `soil_saturation.bin` | Soil saturation |
| `twstudo.mgb` | `total_water_storage.bin` | Terrestrial water storage |
| `handtudo.mgb` | `flooded_level.bin` | HAND-relative flooded level |
| `evaptudo.mgb` | `evapotranspiration.bin` | Total evapotranspiration |
| `evapinterc.mgb` | `interception_evaporation.bin` | Interception evaporation |
| `evapsoilplant.mgb` | `soil_vegetation_evapotranspiration.bin` | Soil plus vegetation evapotranspiration |
| `evapopenwater.mgb` | `open_water_evaporation.bin` | Open-water evaporation |
| `evapurhagua.mgb` | `water_hru_evaporation.bin` | Water-HRU evaporation |
| `evappotagua.mgb` | `potential_open_water_evaporation.bin` | Potential open-water evaporation |
| `surfwater.mgb` | `surface_water.bin` | Surface-water output |
| `vbas.mgb` | `groundwater_storage.bin` | Groundwater storage |
| `vint.mgb` | `subsurface_storage.bin` | Subsurface storage |
| `vsup.mgb` | `surface_storage.bin` | Surface storage |
| `vinterc.mgb` | `interception_storage.bin` | Interception storage |
| `dbas.mgb` | `groundwater_flux.bin` | Groundwater flux |
| `dint.mgb` | `subsurface_flux.bin` | Subsurface flux |
| `dsup.mgb` | `surface_flux.bin` | Surface flux |
| `floodtudo.mgb` | `flooded_area.bin` | Flooded area |
| `log_mgb.txt` | `model.log` | Run log |

The executable writes direct-access unformatted binary output records. The
current record ordering, precision, and units are documented in the
[I/O reference](../architecture/io-reference.md#output-files).

Performance and diagnostic sidecars are handled by regression or external
tools; neither is a stream written by the model's Fortran output module.

## Hotstart files

| Legacy name | Current name | Payload |
| --- | --- | --- |
| `statevars_wb_DATE.hot` | `runoff_state_DATE.bin` | Water-balance state vector |
| `statevars_inertial_DATE.hot` | `inertial_state_DATE.bin` | Hydraulic and inertial-routing state vector |

`DATE` is the model timestamp formatted as `YYYYMMDDHH`. The schedule file
name is listed above. File naming does not change the state-vector ordering;
consult the [I/O reference](../architecture/io-reference.md#hotstarts) before
handling records directly.

## HRU labels

The identifiers in historical vegetation and soil parameter rows describe the
dataset's HRU order. The pre-refactor Magdalena fixture used these row labels;
the current nine-row reference fixture uses `blc_01` through `blc_09`.

| Legacy fixture label | Current fixture label | Current `hru.def` description |
| --- | --- | --- |
| `ForShal` | `blc_01` | Forest + Shallow Soil |
| `ForDeep` | `blc_02` | Forest + Deep Soil |
| `AgrShal` | `blc_03` | Agriculture + Shallow Soil |
| `AgrDeep` | `blc_04` | Agriculture + Deep Soil |
| `BareShal` | `blc_05` | Grassland + Shallow Soil |
| `BareDeep` | `blc_06` | Grassland + Deep Soil |
| `Wetland` | `blc_07` | Wetland |
| `SemiPerm` | `blc_08` | Semi-Permeable |
| `Water` | `blc_09` | Water |

This correspondence describes the fixture row order. The `Bare*` to
`Grassland*` label change is not a universal semantic equivalence: verify the
HRU definition and parameter row order for each dataset before relabeling it.
The current fixture's nine-HRU list is authoritative for that fixture.
