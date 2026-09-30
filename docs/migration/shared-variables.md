# Shared variables and terminology

The legacy model placed configuration, parameters, forcing, geometry, routing
state, and scratch values in the public `VARS_MAIN` and `VARS_INERC` modules.
The current implementation assigns long-lived values to five modules. This
page maps the legacy identifiers most useful when reading scientific notes,
input preparation code, and routing equations. A legacy module name is not a
current Fortran alias.

Current owners are `config`, `attributes`, `parameters`, `forcing`, and
`state`, all under `src/vars/`. The
[components reference](../architecture/components-and-dependencies.md#shared-variables)
describes their current responsibilities. Current process equations and units
are documented in [model processes](../model/model-processes.md),
[parameters and initial state](../model/parameters-and-initial-state.md), and
[the I/O reference](../architecture/io-reference.md).

## Index and unit conventions

- A catchment vector has one element per catchment. Current terminology uses
  *catchment* for the historical *minibacia*.
- Catchment-by-HRU arrays use `(catchment, HRU)` in `attributes` and `state`.
  Soil parameters use `(subbasin, HRU)`; vegetation parameters use
  `(HRU, month, climate region)`.
- Floodplain tables use `(point, catchment)`. Routing boundary arrays use
  `(catchment, internal routing substep)`.
- Depth and water-balance flux values are generally millimetres over one
  model timestep; river discharge is m³/s; storage volumes are m³. The table
  states different units where applicable. “Input units” means the units
  supplied by the dataset and documented in the current model references.

## Configuration and dimensions

| Legacy identifier | Current identifier | Owner | Meaning, dimensions, and migration note |
| --- | --- | --- | --- |
| `INPUT_DIRECTORY` | `input_directory` | `config` | Input directory prefix |
| `OUTPUT_DIRECTORY` | `output_directory` | `config` | Output directory prefix |
| `INPUT_DIRECTORY_HOTSTART` | `hotstart_input_directory` | `config` | Hotstart directory prefix |
| `NUP` | `max_hru_count` | `config` | Maximum HRU capacity; value 12 retained |
| `NBP` | `max_subbasin_count` | `config` | Maximum subbasin capacity; value 505 retained |
| `NUMUSK` | `max_muskingum_reach_count` | `config` | Maximum Muskingum reach subdivisions; value 150 retained |
| `NC` | `catchment_count` | `config` | Number of catchments |
| `NU` | `hru_count` | `config` | Number of HRUs |
| `NT` | `timestep_count` | `config` | Number of meteorological timesteps |
| `NCLI` | — | — | Legacy temporary alias set equal to `NC`; current code sizes climate station coordinates by catchment and has no separate station count |
| `NREG` | `climate_region_count` | `config` | Number of climate regions |
| `NB` | `subbasin_count` | `config` | Number of subbasins |
| `NUMSUBST` | `substitution_count` | `config` | Number of substituted catchment flow series |
| `nSIN` | `reservoir_count` | `config` | Number of reservoir records |
| `DTP` | `model_timestep` | `config` | Meteorological timestep, seconds |
| `IT` | `i_step` | `simulation/runner.f90` local | Timestep-loop index; moved out of shared state |
| `SUBini`, `SUBfim` | `first_subbasin`, `last_subbasin` | `config` | Inclusive simulated subbasin limits |
| `alpha` | `courant_alpha` | `config` | Local-inertial Courant stability factor, dimensionless |
| `g` | `gravity` | `config` | Gravitational acceleration, 9.81 m/s² |
| `thread_count` | `thread_count` | `config` | OpenMP thread count |
| `flag_opt_rout`, `hdFLAG0` | `routing_mode` | `config` | Global routing selection: 0 Muskingum-Cunge, 1 local inertial |
| `HDFLAG(:)` | `routing_method(:)` | `config` | Per-catchment routing flag read from `mini.gtp`; the runner currently replaces the array with the global `routing_mode` |
| `flag_pseudo_two_d` | `pseudo_2d_enabled` | `config` | Pseudo-2D option; current configuration reader sets it to 0 |
| `bflow_overland` | `overland_flow_width` | `config` | Overland connection width; current reader initializes it to 10.0 m |
| `xMan_overland`, `xMan` | `overland_manning_n` | `config` | Overland Manning roughness; current reader initializes it to 0.1 |
| `WSslope` | `downstream_water_surface_slope` | `config` | Downstream boundary slope; input is m/km and current code stores the converted m/m value |
| `flag_RES_SUB` | `reservoir_substitution_enabled` | `config` | Reservoir substitution switch |
| `CLI_INDEX` | `monthly_radiation_option` | `config` | Monthly radiation representation selector |
| `flag_ReadHot`, `flag_WriteHot` | `hotstart_read_mode`, `hotstart_write_mode` | `config` | Hotstart read and write modes |
| `ISUBST(:)` | `substitution_catchment(:)` | `parameters` | Catchment indices associated with substitution records |
| `WriteHotFile(:)` | `hotstart_write_schedule(:)` | `config` | Scheduled write steps |
| `FIL*` file-unit constants | `io_unit_*` constants | `config` | Unit numbers are named by file purpose; exact pairs appear in the file-unit mapping below |

Legacy forcing and output flag variables are represented directly by current
`config` fields. Their corresponding namelist key changes are in the
[configuration table](runtime-names.md#configuration-file-and-namelists).

| Legacy variable | Current `config` variable |
| --- | --- |
| `flag_IN_TEMP`, `flag_IN_RAD`, `flag_IN_RH`, `flag_IN_WIND`, `flag_IN_PRES` | `use_temperature_timeseries`, `use_radiation_timeseries`, `use_humidity_timeseries`, `use_wind_timeseries`, `use_pressure_timeseries` in the same order |
| `flag_OUT_FLOW`, `flag_OUT_WSE`, `flag_OUT_HAND`, `flag_OUT_RUNOFF`, `flag_OUT_SM`, `flag_OUT_SSATD`, `flag_OUT_TWS`, `flag_OUT_SURFWAT` | `write_discharge`, `write_water_surface_elevation`, `write_flooded_level`, `write_runoff`, `write_soil_water`, `write_soil_saturation`, `write_total_water_storage`, `write_surface_water` in the same order |
| `flag_OUT_ET`, `flag_OUT_ETINT`, `flag_OUT_ETSOILVEG`, `flag_OUT_ETOPENWAT`, `flag_OUT_ETURHWAT`, `flag_OUT_POTETWAT` | `write_evapotranspiration`, `write_interception_evaporation`, `write_soil_vegetation_evapotranspiration`, `write_open_water_evaporation`, `write_water_hru_evaporation`, `write_potential_open_water_evaporation` in the same order |
| `flag_OUT_VBAS`, `flag_OUT_VINT`, `flag_OUT_VSUP`, `flag_OUT_VINTERC` | `write_groundwater_storage`, `write_subsurface_storage`, `write_surface_storage`, `write_interception_storage` in the same order |
| `flag_OUT_DBAS`, `flag_OUT_DINT`, `flag_OUT_DSUP`, `flag_OUT_FLAREA` | `write_groundwater_flux`, `write_subsurface_flux`, `write_surface_flux`, `write_flooded_area` in the same order |

## Catchment attributes

The old input-reader names below are stored in `attributes` unless noted.
Catchment geometry values retain the units and conversions described in
[geometry-derived river parameters](../model/parameters-and-initial-state.md#geometry-derived-river-parameters).

| Legacy identifier | Current identifier | Owner | Meaning, dimensions, units |
| --- | --- | --- | --- |
| `IBAC(:)` | `catchment_subbasin(:)` | `attributes` | Subbasin index for each catchment; catchment vector |
| `CELJUS(:)` | `downstream_catchment(:)` | `attributes` | Downstream catchment index; catchment vector |
| `OD(:)` | `catchment_order(:)` | `attributes` | Catchment traversal/order code from `mini.gtp`; catchment vector |
| `ACEL(:)` | `catchment_area(:)` | `attributes` | Local catchment area, km² |
| `ACUR(:)` | `drainage_area(:)` | `attributes` | Upstream drainage area, km² |
| `SRIO(:)` | `river_length(:)` | `attributes` | Main river length, km; current reader enforces a 2.5 km minimum |
| `DECL(:)` | `river_slope(:)` | `attributes` | Main river slope; input m/km converted to m/m during loading |
| `LCEL(:)` | `longest_reach_length(:)` | `attributes` | Longest internal reach length, km; minimum 0.001 km |
| `HCEL(:)` | `longest_reach_slope(:)` | `attributes` | Longest internal reach slope; supplied geometry units |
| `BRIO(:)`, `RUGMAN(:)`, `nMan(:)` | `river_width(:)`, `n_manning(:)` | `attributes` | Channel width, m, and Manning roughness; the legacy `RUGMAN`/`nMan` values now share one owner |
| `X(:)`, `Y(:)` | `catchment_lon(:)`, `catchment_lat(:)` | `attributes` | Catchment centroid coordinates in the input coordinate convention |
| `REGCLI(:)` | `climate_region(:)` | `attributes` | Climate-region index; catchment vector |
| `PUSO(:,:)` | `hru_percentage(:,:)` | `attributes` | HRU area share, percent; `(catchment, HRU)` |
| `IEXUT(:)` | `subbasin_outlet_catchment(:)` | `parameters` | Outlet catchment index for each subbasin |
| `HRIO(:)` | `bankfull_depth(:)` | `attributes` | Bankfull channel depth, m |
| `NPFL(:)` | `floodplain_point_count(:)` | `attributes` | Number of floodplain stage-area points; catchment vector |
| `ZFUNDOFL(:)` | `floodplain_bottom_elevation(:)` | `attributes` | Floodplain bottom elevation, m |
| `ZFL(:,:)` | `floodplain_elevation(:,:)` | `attributes` | Floodplain point elevations, m; `(point, catchment)` |
| `AFL(:,:)` | `floodplain_area(:,:)` | `attributes` | Floodplain area, km²; `(point, catchment)` |
| `nFACE` | `face_count` | `config` | Number of pseudo-2D face connections |
| `nFACECAT1(:)`, `nFACECAT2(:)` | `face_catchment_1(:)`, `face_catchment_2(:)` | `attributes` | Catchment indices at each face endpoint |
| `nFACEY1(:)`, `nFACEY2(:)` | `first_face_elevation(:)`, `second_face_elevation(:)` | `attributes` | Face endpoint elevations, m |
| `nFACEDX(:)` | `face_distance(:)` | `attributes` | Distance between face endpoints, m |

`BRX`, `HRX`, and similar one-value auxiliaries are now procedure-local when
needed; they do not have shared module replacements.

## Parameters

| Legacy identifier | Current identifier | Owner | Meaning, dimensions, units |
| --- | --- | --- | --- |
| `AUSO(:)` | `hru_name(:)` | `parameters` | HRU row identifiers; one character label per HRU |
| `ALB(:,:,:)` | `albedo(:,:,:)` | `parameters` | Albedo; `(HRU, month, climate region)`, dimensionless |
| `RIAF(:,:,:)` | `leaf_area_index(:,:,:)` | `parameters` | Leaf-area index; `(HRU, month, climate region)`, dimensionless |
| `Z(:,:,:)` | `vegetation_height(:,:,:)` | `parameters` | Vegetation height; `(HRU, month, climate region)`, m |
| `RS(:,:,:)` | `surface_resistance(:,:,:)` | `parameters` | Minimum surface resistance; `(HRU, month, climate region)`, s/m; current reader retains the legacy ×1.5 adjustment |
| `WM(:,:)` | `max_soil_water_storage(:,:)` | `parameters` | Maximum soil-water storage; `(subbasin, HRU)`, mm |
| `B(:,:)` | `b_arno(:,:)` | `parameters` | ARNO shape parameter; `(subbasin, HRU)`, dimensionless |
| `KBAS(:,:)` | `groundwater_conductivity(:,:)` | `parameters` | Groundwater conductivity; `(subbasin, HRU)`, mm/day |
| `KINS(:,:)` | `subsurface_conductivity(:,:)` | `parameters` | Subsurface conductivity; `(subbasin, HRU)`, mm/day |
| `PLAM(:,:)` | `lambda_brooks_corey(:,:)` | `parameters` | Brooks-Corey index; `(subbasin, HRU)`, dimensionless |
| `CAP(:,:)` | `max_capillary_flux(:,:)` | `parameters` | Maximum capillary flux; `(subbasin, HRU)`, mm/day |
| `WC(:,:)` | `capillary_threshold_fraction(:,:)` | `parameters` | Moisture-threshold fraction; `(subbasin, HRU)`, dimensionless |
| `KINF(:,:)` | `floodplain_infiltration_rate(:,:)` | `parameters` | Legacy floodplain infiltration field; `(subbasin, HRU)`, mm/day; inertial calculations apply the current documented cap/replacement rule |
| `CS(:)` | `surface_routing_coefficient(:)` | `parameters` | Surface-reservoir delay multiplier; subbasin vector, dimensionless |
| `CI(:)` | `subsurface_routing_coefficient(:)` | `parameters` | Subsurface-reservoir delay multiplier; subbasin vector, dimensionless |
| `CB(:)` | `groundwater_routing_coefficient(:)` | `parameters` | Groundwater delay; subbasin vector, hours |
| `QESP(:)` | `specific_baseflow(:)` | `parameters` | Specific baseflow; subbasin vector, m³/s/km² |
| `NSUBT(:)` | `muskingum_reach_count(:)` | `parameters` | Number of Muskingum reach subdivisions; catchment vector |
| `DT(:)` | `muskingum_timestep(:)` | `parameters` | Internal Muskingum routing timestep, seconds |
| `CEL(:)` | `wave_celerity(:)` | `parameters` | Muskingum-Cunge wave celerity, m/s |
| `TIND(:)` | `time_of_concentration(:)` | `parameters` | Catchment time of concentration, seconds |
| `QREF(:)` | `reference_q(:)` | `parameters` | Reference discharge used to initialize routing, m³/s |
| `KCB(:)` | `catchments_per_subbasin(:)` | `parameters` | Catchment count by subbasin |
| `MINIMONT(:,:)` | `upstream_topology(:,:)` | `parameters` | Upstream catchment indices; `(catchment, topology slot)`, with slot 1 storing the count |
| `ZTAB(:,:)` | `stage_table(:,:)` | `parameters` | Stage lookup values, m; `(point, catchment)` |
| `VTAB(:,:)` | `volume_table(:,:)` | `parameters` | Volume lookup values, m³; `(point, catchment)` |
| `ATAB(:,:)` | `area_table(:,:)` | `parameters` | Area lookup values, km²; `(point, catchment)` |
| `Ind_Reserv(:)` | `reservoir_index_by_catchment(:)` | `parameters` | Reservoir index associated with a catchment |
| `CELJUS2(:)` | `routing_downstream_catchment(:)` | `parameters` | Downstream routing index used by reservoir/routing support |
| `iTini_Reserv(:)` | `reservoir_start_timestep(:)` | `parameters` | First simulation timestep for a reservoir series |

## Forcing and external series

| Legacy identifier | Current identifier | Owner | Meaning, dimensions, units |
| --- | --- | --- | --- |
| `P(:)` | `precipitation(:)` | `forcing` | Catchment precipitation for the current timestep, mm |
| `TA(:)`, `TAMM(:,:)` | `air_temperature(:)`, `monthly_air_temperature(:,:)` | `forcing` | Current and monthly air temperature, °C; monthly array `(catchment, month)` |
| `UR(:)`, `URMM(:,:)` | `relative_humidity(:)`, `monthly_relative_humidity(:,:)` | `forcing` | Current and monthly relative humidity, percent; monthly `(catchment, month)` |
| `VV(:)`, `VVMM(:,:)` | `wind_speed(:)`, `monthly_wind_speed(:,:)` | `forcing` | Current and monthly wind speed, m/s; monthly `(catchment, month)` |
| `SOL(:)`, `SOLMM(:,:)` | `solar_input(:)`, `monthly_solar_input(:,:)` | `forcing` | Current and monthly solar input or configured sunshine representation |
| `PA(:)`, `PAMM(:,:)` | `air_pressure(:)`, `monthly_air_pressure(:,:)` | `forcing` | Current and monthly atmospheric pressure, kPa; monthly `(catchment, month)` |
| `XYC(:,:)` | `climate_station_coordinates(:,:)` | `forcing` | Climate coordinates; `(catchment, coordinate)` |
| `TONTEM(:)` | `previous_air_temperature(:)` | `forcing` | Retained prior air temperature, °C |
| `QLIDO(:,:)` | `substituted_q(:,:)` | `forcing` | Substituted discharge; `(substitution series, timestep)`, m³/s |
| `Qdefl(:,:)` | `reservoir_outflow(:,:)` | `forcing` | Reservoir outflow series; `(timestep, reservoir)`, m³/s |

## Water-balance state and output buffers

| Legacy identifier | Current identifier | Owner | Meaning, dimensions, units |
| --- | --- | --- | --- |
| `iday`, `imonth`, `iyear`, `ihour`, `iminute` | `day`, `month`, `year`, `hour`, `minute` | `state` | Current calendar fields |
| `doy` | `day_of_year` | `state` | Day of year |
| `jday` | `julian_day` | `state` | Current Julian date |
| `W(:,:)` | `soil_water_storage(:,:)` | `state` | Soil-water storage; `(catchment, HRU)`, mm |
| `SI(:,:)` | `interception_storage(:,:)` | `state` | Intercepted water storage; `(catchment, HRU)`, mm |
| `ET(:,:)` | `evapotranspiration(:,:)` | `state` | HRU evapotranspiration; `(catchment, HRU)`, mm/timestep |
| `CAF(:,:)` | `capillary_flux(:,:)` | `state` | Upward capillary flux; `(catchment, HRU)`, mm/timestep |
| `QBAS(:)`, `QINT(:)`, `QSUP(:)` | `groundwater_q(:)`, `subsurface_q(:)`, `surface_q(:)` | `state` | Catchment runoff components, m³/s |
| `VBAS(:)`, `VINT(:)`, `VSUP(:)` | `groundwater_storage(:)`, `subsurface_storage(:)`, `surface_storage(:)` | `state` | Terrestrial linear-reservoir stores, m³ |
| `EVQ(:)` | `open_water_evaporation_q(:)` | `state` | Open-water evaporation discharge, m³/s |
| `DINFILT(:)` | `floodplain_infiltration(:)` | `state` | Floodplain-to-soil infiltration depth, mm/timestep |
| `TWS(:)` | `grace_total_water_storage(:)` | `state` | Legacy GRACE comparison storage; current declaration remains allocated and initialized, with no active calculation call site |
| `TWS2(:)` | `total_water_storage(:)` | `state` | Legacy catchment terrestrial-storage accumulator; current total terrestrial storage, mm |
| `QM1(:)`, `QM2(:)` | `incoming_q_previous(:)`, `incoming_q_current(:)` | `state` | Upstream/incoming routed discharge at previous and current routing timestep, m³/s |
| `QJ1(:)`, `QJ2(:)` | `outgoing_q_previous(:)`, `outgoing_q_current(:)` | `state` | Downstream/outgoing routed discharge at previous and current routing timestep, m³/s |
| `QCEL1(:)`, `QCEL2(:)` | `catchment_q_previous(:)`, `catchment_q_current(:)` | `state` | Local catchment-generated discharge at previous and current timestep, m³/s |
| `PMB1(:)`, `PMI1(:)`, `PMS1(:)` | `incoming_groundwater_fraction_previous(:)`, `incoming_subsurface_fraction_previous(:)`, `incoming_surface_fraction_previous(:)` | `state` | Previous incoming flow fractions by source; dimensionless |
| `PMB2(:)`, `PMI2(:)`, `PMS2(:)` | `incoming_groundwater_fraction_current(:)`, `incoming_subsurface_fraction_current(:)`, `incoming_surface_fraction_current(:)` | `state` | Current incoming flow fractions by source; dimensionless |
| `PJB1(:)`, `PJI1(:)`, `PJS1(:)` | `outgoing_groundwater_fraction_previous(:)`, `outgoing_subsurface_fraction_previous(:)`, `outgoing_surface_fraction_previous(:)` | `state` | Previous outgoing flow fractions by source; dimensionless |
| `PJB2(:)`, `PJI2(:)`, `PJS2(:)` | `outgoing_groundwater_fraction_current(:)`, `outgoing_subsurface_fraction_current(:)`, `outgoing_surface_fraction_current(:)` | `state` | Current outgoing flow fractions by source; dimensionless |
| `VRB(:)`, `VRI(:)`, `VRS(:)` | `groundwater_routing_volume(:)`, `subsurface_routing_volume(:)`, `surface_routing_volume(:)` | `state` | Source-attributed Muskingum routing storage, m³ |
| `QCONTORM(:,:)`, `QCONTORJ(:,:)` | `incoming_q_boundary(:,:)`, `outgoing_q_boundary(:,:)` | `state` | Intra-timestep routing boundary hydrographs; `(catchment, internal substep)`, m³/s |
| `QRIOINI(:,:)` | `initial_river_q(:,:)` | `state` | Initial river discharge per Muskingum reach; `(catchment, reach)`, m³/s |
| `vflow(:)` | `flow_velocity(:)` | `state` | Derived river flow velocity, m/s |
| `QTUDO(:)` | `q_river_output(:)` | `state` | Discharge output buffer, m³/s per catchment |
| `YTUDO(:)` | `water_surface_elevation_output(:)` | `state` | Water-surface elevation output buffer, m |
| `TWSTUDO(:)` | `total_water_storage_output(:)` | `state` | Total water storage output buffer, mm |
| `ALAGTUDO(:)` | `flooded_area_output(:)` | `state` | Flooded area output buffer, km² |
| `HANDTUDO(:)` | `hand_output(:)` | `state` | HAND-relative flooded-level output buffer, m |
| `QITUDO(:)` | `incremental_q_output(:)` | `state` | Incremental discharge output buffer, m³/s |
| `EVAPTUDO(:)` | `et_output(:)` | `state` | Total evapotranspiration output buffer, mm |
| `QBASTUDO(:)` | `groundwater_q_output(:)` | `state` | Groundwater-flow output buffer, m³/s |
| `WSATDEGREE(:)` | `soil_saturation_output(:)` | `state` | Soil saturation output buffer, dimensionless |
| `ETINTERC(:)`, `ETSOILPLANT(:)`, `ETOPENWAT(:)`, `EVAPURHAGUA(:)` | `interception_et_output(:)`, `soil_vegetation_et_output(:)`, `open_water_et_output(:)`, `water_hru_et_output(:)` | `state` | Component evapotranspiration output buffers, mm |
| `POTETWAT(:)` | `potential_open_water_et_output(:)` | `state` | Potential open-water ET output buffer, mm |
| `SOILWATER(:)`, `CAPWATER(:)`, `VINTERC(:)` | `soil_water_output(:)`, `capillary_water_output(:)`, `interception_storage_output(:)` | `state` | Soil, capillary, and interception output buffers, mm |
| `VBASMMDIA(:)`, `VINTMMDIA(:)`, `VSUPMMDIA(:)` | `groundwater_storage_depth_output(:)`, `subsurface_storage_depth_output(:)`, `surface_storage_depth_output(:)` | `state` | Storage-depth output buffers, mm |
| `DBASMMDIA(:)`, `DINTMMDIA(:)`, `DSUPMMDIA(:)` | `groundwater_runoff_depth_output(:)`, `subsurface_runoff_depth_output(:)`, `surface_runoff_depth_output(:)` | `state` | Runoff-depth output buffers, mm/timestep |
| `SURFWAT(:)`, `QCELTUDO(:)` | `surface_water_output(:)`, `catchment_q_output(:)` | `state` | Surface-water depth and catchment discharge output buffers |

## Inertial-routing state

| Legacy identifier | Current identifier | Owner | Meaning, dimensions, units |
| --- | --- | --- | --- |
| `Q2fl(:)` | `inertial_q(:)` | `state` | Inertial river discharge, m³/s |
| `Qmont(:)` | `upstream_q(:)` | `state` | Upstream discharge scratch retained in the namespace; current declarations allocate three entries and have no active call sites |
| `Vol1(:)`, `Vol2(:)` | `previous_water_volume(:)`, `current_water_volume(:)` | `state` | Previous and current channel/floodplain volume, m³ |
| `Area2(:)` | `current_flooded_area(:)` | `state` | Current flooded area, km² |
| `Hfl(:)` | `water_depth(:)` | `state` | Water depth above the channel/floodplain datum, m |
| `Yfl(:)` | `water_surface_elevation(:)` | `state` | Water-surface elevation, m |
| `Q2face(:)` | `face_q(:)` | `state` | Discharge at pseudo-2D faces, m³/s |
| `Q2viz(:)` | `neighbor_q(:)` | `state` | Net neighboring-face discharge by catchment, m³/s |
| `jtab(:)` | `stage_table_index(:)` | `state` | Current stage-volume lookup index |
| `SumQup` | — | — | Replaced by local topology-based upstream discharge sums; no shared scalar successor |
| `dtfloodmax`, `dtflood`, `dtflood0`, `tflood`, `hmaxfl`, `HRX` | procedure-local values in `river_inertial` | `hydrology/river_inertial.f90` | Routing timestep/depth scratch values; no shared module replacement |

## Legacy scratch names and file units

The old shared modules also exposed many calculation temporaries (`WX`, `BX`,
`SDECL`, `GAMA`, `RA`, `XLADO`, and loop counters) because earlier routines
shared their storage through global state. Those values are now local to
`catchment`, `river_muskingum`, or `river_inertial`, or have been removed when
unused. The scientific meaning of the energy-balance terms is documented in
[Energy balance and evapotranspiration](../model/energy-balance.md).

Selected names from the legacy energy-balance equations now appear as local
arguments or temporaries in `calculate_et_demand` and
`calculate_net_radiation`:

| Legacy identifier | Current local name or input | Meaning and units |
| --- | --- | --- |
| `GLAT` | `lat` from `attributes.catchment_lat` | Catchment latitude, degrees; south is negative |
| `SOLX` | `solar` from `forcing.solar_input` | Solar forcing in the configured representation |
| `T2` | `ta` from `forcing.air_temperature` | Current air temperature, °C |
| `T1` | `t_prev` from `forcing.previous_air_temperature` | Previous-step air temperature, °C |
| `URX` | `rh` from `forcing.relative_humidity` | Relative humidity, percent |
| `ALBX` | `alb` from `parameters.albedo` | HRU albedo, dimensionless |
| `RLX` | `r_net` | Net radiation flux, MJ/(m² s) |
| `ED` | `e_d` | Vapor-pressure deficit, kPa |
| `DEL` | `s_e` | Slope of saturation-vapor-pressure curve, kPa/°C |
| `GAMA` | `gamma` | Psychrometric constant, kPa/°C |
| `MSPA` | `rho_a` | Air density, kg/m³ |
| `RUG` | `z0` | Vegetation roughness length, m |
| `RA`, `RAEP` | `r_a`, `r_aw` | Aerodynamic resistance for vegetation and open water, s/m |
| `WL`, `WPM` | `w_u`, `w_w` | Upper soil-water threshold and wilting storage, mm |
| `F4` | `f_rs` | Soil-moisture resistance factor, dimensionless |
| `EIX`, `EIXP`, `REIX` | `et_int_pot`, `et_water_pot`, `et_int` | Potential interception ET, potential water ET, and actual interception ET, mm/timestep |
| `FDE` | `f_et` | Remaining potential-ET fraction, dimensionless |

The legacy `FIL*` constants became purpose-named `io_unit_*` constants in
`config`. File names and their current owners are listed on the
[runtime name mapping](runtime-names.md); file-unit numbers are implementation
details and do not define a runtime file contract.

| Legacy constants | Current `config` constants |
| --- | --- |
| `FILFIX`, `FILVAR`, `FILUSO`, `FILHIG`, `FILCLIREG`, `FILSUBS` | `io_unit_config`, `io_unit_fixed_parameter`, `io_unit_calibrated_parameter`, `io_unit_catchment_data`, `io_unit_climate_region`, `io_unit_substitution_flow` in the same order |
| `FILSTAGE`, `FILAREA`, `FILCLIMATEbin`, `FILHOTSTART_WB`, `FILHOTSTART_Inert`, `FILLOG` | `io_unit_flood_stage`, `io_unit_flood_area`, `io_unit_climatology`, `io_unit_water_balance_hotstart`, `io_unit_inertial_hotstart`, `io_unit_log` in the same order |
| `FILCOTAREA`, `FILFACE`, `FILHOTLIST` | `io_unit_stage_area`, `io_unit_face_connection`, `io_unit_hotstart_list` in the same order |
| `FILPLU`, `FILTEMP`, `FILRAD`, `FILRELH`, `FILWIND`, `FILPRES` | `io_unit_precipitation`, `io_unit_temperature`, `io_unit_radiation`, `io_unit_relative_humidity`, `io_unit_wind`, `io_unit_pressure` in the same order |
| `FIL_FLOW`, `FIL_ET`, `FIL_WSE`, `FIL_HAND`, `FIL_TWS`, `FIL_FLOOD`, `FIL_SSATD` | `io_unit_discharge_output`, `io_unit_et_output`, `io_unit_water_surface_elevation_output`, `io_unit_hand_output`, `io_unit_total_water_storage_output`, `io_unit_flooded_area_output`, `io_unit_soil_saturation_output` in the same order |
| `FIL_ETINT`, `FIL_ETSOILVEG`, `FIL_ETOPENW`, `FIL_SOILWATER`, `FIL_VBAS`, `FIL_VINT`, `FIL_VSUP`, `FIL_VINTERC` | `io_unit_interception_et_output`, `io_unit_soil_vegetation_et_output`, `io_unit_open_water_et_output`, `io_unit_soil_water_output`, `io_unit_groundwater_storage_output`, `io_unit_subsurface_storage_output`, `io_unit_surface_storage_output`, `io_unit_interception_storage_output` in the same order |
| `FIL_DBAS`, `FIL_DINT`, `FIL_DSUP`, `FIL_SURFWAT`, `FIL_RUNOFF`, `FIL_ETURHWAT`, `FIL_POTETWAT` | `io_unit_groundwater_flux_output`, `io_unit_subsurface_flux_output`, `io_unit_surface_flux_output`, `io_unit_surface_water_output`, `io_unit_runoff_output`, `io_unit_water_hru_et_output`, `io_unit_potential_open_water_et_output` in the same order |

## Terminology

| Historical term | Current term | Usage |
| --- | --- | --- |
| URH | HRU | Historical abbreviation for *unidade de resposta hidrológica*; current English term is hydrological response unit. |
| minibacia | catchment | Local contributing area associated with one explicit river segment. |
| montante | upstream | Direction toward the headwaters. |
| jusante | downstream | Direction toward the outlet. |
| cota | stage or elevation | Water-surface or floodplain elevation, depending on context. |
| cota-área-volume | stage-area-volume | Floodplain lookup relation used by local-inertial routing. |
| vazão | discharge or flow | Volumetric flow rate; identify the variable context and units. |
| solo | soil | Soil storage and flux domain in catchment water balance. |

The current model's spatial units and storage concepts are introduced in
[Model concepts](../model/model-concepts.md).
