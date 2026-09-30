# Shared-variable mapping

The legacy model placed configuration, parameters, forcing, geometry, routing
state, and scratch values in the public `VARS_MAIN` and `VARS_INERC` modules.
This page maps selected legacy shared identifiers to the five current variable
modules and records listed names without a current successor. The
[routine-local mapping](routine-locals.md) covers former globals used as
equation inputs and calculation temporaries. A legacy module name is not a
current Fortran alias.

The five current namespaces are `config`, `attributes`, `parameters`,
`forcing`, and `state`, all under `src/vars/`. The
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

The [terminology glossary](overview.md#terminology) defines historical terms.

## Config

### Dimensions and options

| Legacy identifier | Current identifier | Meaning, dimensions, and migration note |
| --- | --- | --- |
| `INPUT_DIRECTORY` | `input_directory` | Input directory prefix |
| `OUTPUT_DIRECTORY` | `output_directory` | Output directory prefix |
| `INPUT_DIRECTORY_HOTSTART` | `hotstart_input_directory` | Hotstart directory prefix |
| `NUP` | `max_hru_count` | Maximum HRU capacity; value 12 retained |
| `NBP` | `max_subbasin_count` | Maximum subbasin capacity; value 505 retained |
| `NUMUSK` | `max_muskingum_reach_count` | Maximum Muskingum reach subdivisions; value 150 retained |
| `NC` | `catchment_count` | Number of catchments |
| `NU` | `hru_count` | Number of HRUs |
| `NT` | `timestep_count` | Number of meteorological timesteps |
| `NCLI` | — | Legacy temporary alias set equal to `NC`; current code sizes climate station coordinates by catchment and has no separate station count |
| `NREG` | `climate_region_count` | Number of climate regions |
| `NB` | `subbasin_count` | Number of subbasins |
| `NUMSUBST` | `substitution_count` | Number of substituted catchment flow series |
| `nSIN` | `reservoir_count` | Number of reservoir records |
| `DTP` | `model_timestep` | Meteorological timestep, seconds |
| `SUBini` | `first_subbasin` | Inclusive simulated subbasin limits |
| `SUBfim` | `last_subbasin` | Inclusive simulated subbasin limits |
| `alpha` | `courant_alpha` | Local-inertial Courant stability factor, dimensionless |
| `g` | `gravity` | Gravitational acceleration, 9.81 m/s² |
| `thread_count` | `thread_count` | OpenMP thread count |
| `flag_opt_rout` | `routing_mode` | Global routing selection: 0 Muskingum-Cunge, 1 local inertial |
| `hdFLAG0` | `routing_mode` | Global routing selection: 0 Muskingum-Cunge, 1 local inertial |
| `HDFLAG(:)` | `routing_method(:)` | Per-catchment routing flag read from `mini.gtp`; the runner currently replaces the array with the global `routing_mode` |
| `flag_pseudo_two_d` | `pseudo_2d_enabled` | Pseudo-2D option; current configuration reader sets it to 0 |
| `bflow_overland` | `overland_flow_width` | Overland connection width; current reader initializes it to 10.0 m |
| `xMan_overland` | `overland_manning_n` | Overland Manning roughness; current reader initializes it to 0.1 |
| `WSslope` | `downstream_water_surface_slope` | Downstream boundary slope; input is m/km and current code stores the converted m/m value |
| `flag_RES_SUB` | `reservoir_substitution_enabled` | Reservoir substitution switch |
| `CLI_INDEX` | `monthly_radiation_option` | Monthly radiation representation selector |
| `flag_ReadHot` | `hotstart_read_mode` | Hotstart read mode |
| `flag_WriteHot` | `hotstart_write_mode` | Hotstart write mode |
| `WriteHotFile(:)` | `hotstart_write_schedule(:)` | Scheduled write steps |
| `FIL*` | `io_unit_*` constants | Unit numbers are named by file purpose; exact pairs appear in the file-unit mapping below |
| `nFACE` | `face_count` | Number of pseudo-2D face connections |

### Forcing and output switches

Legacy forcing and output flag variables are represented directly by current
`config` fields. Their corresponding namelist key changes are in the
[configuration table](runtime-names.md#configuration-file-and-namelists).

| Legacy variable | Current `config` variable |
| --- | --- |
| `flag_IN_TEMP` | `use_temperature_timeseries` |
| `flag_IN_RAD` | `use_radiation_timeseries` |
| `flag_IN_RH` | `use_humidity_timeseries` |
| `flag_IN_WIND` | `use_wind_timeseries` |
| `flag_IN_PRES` | `use_pressure_timeseries` |
| `flag_OUT_FLOW` | `write_discharge` |
| `flag_OUT_WSE` | `write_water_surface_elevation` |
| `flag_OUT_HAND` | `write_flooded_level` |
| `flag_OUT_RUNOFF` | `write_runoff` |
| `flag_OUT_SM` | `write_soil_water` |
| `flag_OUT_SSATD` | `write_soil_saturation` |
| `flag_OUT_TWS` | `write_total_water_storage` |
| `flag_OUT_SURFWAT` | `write_surface_water` |
| `flag_OUT_ET` | `write_evapotranspiration` |
| `flag_OUT_ETINT` | `write_interception_evaporation` |
| `flag_OUT_ETSOILVEG` | `write_soil_vegetation_evapotranspiration` |
| `flag_OUT_ETOPENWAT` | `write_open_water_evaporation` |
| `flag_OUT_ETURHWAT` | `write_water_hru_evaporation` |
| `flag_OUT_POTETWAT` | `write_potential_open_water_evaporation` |
| `flag_OUT_VBAS` | `write_groundwater_storage` |
| `flag_OUT_VINT` | `write_subsurface_storage` |
| `flag_OUT_VSUP` | `write_surface_storage` |
| `flag_OUT_VINTERC` | `write_interception_storage` |
| `flag_OUT_DBAS` | `write_groundwater_flux` |
| `flag_OUT_DINT` | `write_subsurface_flux` |
| `flag_OUT_DSUP` | `write_surface_flux` |
| `flag_OUT_FLAREA` | `write_flooded_area` |

### File units

The legacy `FIL*` constants became purpose-named `io_unit_*` constants in
`config`. File names and their current mappings are listed on the
[runtime name mapping](runtime-names.md); file-unit numbers are implementation
details and do not define a runtime file contract.

| Legacy constants | Current `config` constants |
| --- | --- |
| `FILFIX` | `io_unit_config` |
| `FILVAR` | `io_unit_fixed_parameter` |
| `FILUSO` | `io_unit_calibrated_parameter` |
| `FILHIG` | `io_unit_catchment_data` |
| `FILCLIREG` | `io_unit_climate_region` |
| `FILSUBS` | `io_unit_substitution_flow` |
| `FILSTAGE` | `io_unit_flood_stage` |
| `FILAREA` | `io_unit_flood_area` |
| `FILCLIMATEbin` | `io_unit_climatology` |
| `FILHOTSTART_WB` | `io_unit_water_balance_hotstart` |
| `FILHOTSTART_Inert` | `io_unit_inertial_hotstart` |
| `FILLOG` | `io_unit_log` |
| `FILCOTAREA` | `io_unit_stage_area` |
| `FILFACE` | `io_unit_face_connection` |
| `FILHOTLIST` | `io_unit_hotstart_list` |
| `FILPLU` | `io_unit_precipitation` |
| `FILTEMP` | `io_unit_temperature` |
| `FILRAD` | `io_unit_radiation` |
| `FILRELH` | `io_unit_relative_humidity` |
| `FILWIND` | `io_unit_wind` |
| `FILPRES` | `io_unit_pressure` |
| `FIL_FLOW` | `io_unit_discharge_output` |
| `FIL_ET` | `io_unit_et_output` |
| `FIL_WSE` | `io_unit_water_surface_elevation_output` |
| `FIL_HAND` | `io_unit_hand_output` |
| `FIL_TWS` | `io_unit_total_water_storage_output` |
| `FIL_FLOOD` | `io_unit_flooded_area_output` |
| `FIL_SSATD` | `io_unit_soil_saturation_output` |
| `FIL_ETINT` | `io_unit_interception_et_output` |
| `FIL_ETSOILVEG` | `io_unit_soil_vegetation_et_output` |
| `FIL_ETOPENW` | `io_unit_open_water_et_output` |
| `FIL_SOILWATER` | `io_unit_soil_water_output` |
| `FIL_VBAS` | `io_unit_groundwater_storage_output` |
| `FIL_VINT` | `io_unit_subsurface_storage_output` |
| `FIL_VSUP` | `io_unit_surface_storage_output` |
| `FIL_VINTERC` | `io_unit_interception_storage_output` |
| `FIL_DBAS` | `io_unit_groundwater_flux_output` |
| `FIL_DINT` | `io_unit_subsurface_flux_output` |
| `FIL_DSUP` | `io_unit_surface_flux_output` |
| `FIL_SURFWAT` | `io_unit_surface_water_output` |
| `FIL_RUNOFF` | `io_unit_runoff_output` |
| `FIL_ETURHWAT` | `io_unit_water_hru_et_output` |
| `FIL_POTETWAT` | `io_unit_potential_open_water_et_output` |

## Attributes

The old input-reader names below are stored in `attributes` unless noted.
Catchment geometry values retain the units and conversions described in
[geometry-derived river parameters](../model/parameters-and-initial-state.md#geometry-derived-river-parameters).

| Legacy identifier | Current identifier | Meaning, dimensions, and units |
| --- | --- | --- |
| `IBAC(:)` | `catchment_subbasin(:)` | Subbasin index for each catchment; catchment vector |
| `CELJUS(:)` | `downstream_catchment(:)` | Downstream catchment index; catchment vector |
| `OD(:)` | `catchment_order(:)` | Catchment traversal/order code from `mini.gtp`; catchment vector |
| `ACEL(:)` | `catchment_area(:)` | Local catchment area, km² |
| `ACUR(:)` | `drainage_area(:)` | Upstream drainage area, km² |
| `SRIO(:)` | `river_length(:)` | Main river length, km; current reader enforces a 2.5 km minimum |
| `DECL(:)` | `river_slope(:)` | Main river slope; input m/km converted to m/m during loading |
| `LCEL(:)` | `longest_reach_length(:)` | Longest internal reach length, km; minimum 0.001 km |
| `HCEL(:)` | `longest_reach_slope(:)` | Longest internal reach slope; supplied geometry units |
| `BRIO(:)` | `river_width(:)` | Channel width, m |
| `RUGMAN(:)` | `n_manning(:)` | Manning roughness, s/m¹ᐟ³; catchment vector |
| `nMan(:)` | `n_manning(:)` | Manning roughness, s/m¹ᐟ³; catchment vector |
| `X(:)` | `catchment_lon(:)` | Catchment centroid coordinates in the input coordinate convention |
| `Y(:)` | `catchment_lat(:)` | Catchment centroid coordinates in the input coordinate convention |
| `REGCLI(:)` | `climate_region(:)` | Climate-region index; catchment vector |
| `PUSO(:,:)` | `hru_percentage(:,:)` | HRU area share, percent; `(catchment, HRU)` |
| `HRIO(:)` | `bankfull_depth(:)` | Bankfull channel depth, m |
| `NPFL(:)` | `floodplain_point_count(:)` | Number of floodplain stage-area points; catchment vector |
| `ZFUNDOFL(:)` | `floodplain_bottom_elevation(:)` | Floodplain bottom elevation, m |
| `ZFL(:,:)` | `floodplain_elevation(:,:)` | Floodplain point elevations, m; `(point, catchment)` |
| `AFL(:,:)` | `floodplain_area(:,:)` | Floodplain area, km²; `(point, catchment)` |
| `nFACECAT1(:)` | `face_catchment_1(:)` | Catchment indices at each face endpoint |
| `nFACECAT2(:)` | `face_catchment_2(:)` | Catchment indices at each face endpoint |
| `nFACEY1(:)` | `first_face_elevation(:)` | Face endpoint elevations, m |
| `nFACEY2(:)` | `second_face_elevation(:)` | Face endpoint elevations, m |
| `nFACEDX(:)` | `face_distance(:)` | Distance between face endpoints, m |

Former shared auxiliaries such as `BRX` and `HRX` are covered in the
[routine-local mapping](routine-locals.md).

## Parameters

| Legacy identifier | Current identifier | Meaning, dimensions, and units |
| --- | --- | --- |
| `AUSO(:)` | `hru_name(:)` | HRU row identifiers; one character label per HRU |
| `ALB(:,:,:)` | `albedo(:,:,:)` | Albedo; `(HRU, month, climate region)`, dimensionless |
| `RIAF(:,:,:)` | `leaf_area_index(:,:,:)` | Leaf-area index; `(HRU, month, climate region)`, dimensionless |
| `Z(:,:,:)` | `vegetation_height(:,:,:)` | Vegetation height; `(HRU, month, climate region)`, m |
| `RS(:,:,:)` | `surface_resistance(:,:,:)` | Minimum surface resistance; `(HRU, month, climate region)`, s/m; current reader retains the legacy ×1.5 adjustment |
| `WM(:,:)` | `max_soil_water_storage(:,:)` | Maximum soil-water storage; `(subbasin, HRU)`, mm |
| `B(:,:)` | `b_arno(:,:)` | ARNO shape parameter; `(subbasin, HRU)`, dimensionless |
| `KBAS(:,:)` | `groundwater_conductivity(:,:)` | Groundwater conductivity; `(subbasin, HRU)`, mm/day |
| `KINS(:,:)` | `subsurface_conductivity(:,:)` | Subsurface conductivity; `(subbasin, HRU)`, mm/day |
| `PLAM(:,:)` | `lambda_brooks_corey(:,:)` | Brooks-Corey index; `(subbasin, HRU)`, dimensionless |
| `CAP(:,:)` | `max_capillary_flux(:,:)` | Maximum capillary flux; `(subbasin, HRU)`, mm/day |
| `WC(:,:)` | `capillary_threshold_fraction(:,:)` | Moisture-threshold fraction; `(subbasin, HRU)`, dimensionless |
| `KINF(:,:)` | `floodplain_infiltration_rate(:,:)` | Legacy floodplain infiltration field; `(subbasin, HRU)`, mm/day; inertial calculations apply the current documented cap/replacement rule |
| `CS(:)` | `surface_routing_coefficient(:)` | Surface-reservoir delay multiplier; subbasin vector, dimensionless |
| `CI(:)` | `subsurface_routing_coefficient(:)` | Subsurface-reservoir delay multiplier; subbasin vector, dimensionless |
| `CB(:)` | `groundwater_routing_coefficient(:)` | Groundwater delay; subbasin vector, hours |
| `QESP(:)` | `specific_baseflow(:)` | Specific baseflow; subbasin vector, m³/s/km² |
| `NSUBT(:)` | `muskingum_reach_count(:)` | Number of Muskingum reach subdivisions; catchment vector |
| `DT(:)` | `muskingum_timestep(:)` | Internal Muskingum routing timestep, seconds |
| `CEL(:)` | `wave_celerity(:)` | Muskingum-Cunge wave celerity, m/s |
| `TIND(:)` | `time_of_concentration(:)` | Catchment time of concentration, seconds |
| `QREF(:)` | `reference_q(:)` | Reference discharge used to initialize routing, m³/s |
| `KCB(:)` | `catchments_per_subbasin(:)` | Catchment count by subbasin |
| `MINIMONT(:,:)` | `upstream_topology(:,:)` | Upstream catchment indices; `(catchment, topology slot)`, with slot 1 storing the count |
| `ZTAB(:,:)` | `stage_table(:,:)` | Stage lookup values, m; `(point, catchment)` |
| `VTAB(:,:)` | `volume_table(:,:)` | Volume lookup values, m³; `(point, catchment)` |
| `ATAB(:,:)` | `area_table(:,:)` | Area lookup values, km²; `(point, catchment)` |
| `Ind_Reserv(:)` | `reservoir_index_by_catchment(:)` | Reservoir index associated with a catchment |
| `CELJUS2(:)` | `routing_downstream_catchment(:)` | Downstream routing index used by reservoir/routing support |
| `iTini_Reserv(:)` | `reservoir_start_timestep(:)` | First simulation timestep for a reservoir series |
| `ISUBST(:)` | `substitution_catchment(:)` | Catchment indices associated with substitution records |
| `IEXUT(:)` | `subbasin_outlet_catchment(:)` | Outlet catchment index for each subbasin |

## Forcing

| Legacy identifier | Current identifier | Meaning, dimensions, and units |
| --- | --- | --- |
| `P(:)` | `precipitation(:)` | Catchment precipitation for the current timestep, mm |
| `TA(:)` | `air_temperature(:)` | Current and monthly air temperature, °C; monthly array `(catchment, month)` |
| `TAMM(:,:)` | `monthly_air_temperature(:,:)` | Current and monthly air temperature, °C; monthly array `(catchment, month)` |
| `UR(:)` | `relative_humidity(:)` | Current and monthly relative humidity, percent; monthly `(catchment, month)` |
| `URMM(:,:)` | `monthly_relative_humidity(:,:)` | Current and monthly relative humidity, percent; monthly `(catchment, month)` |
| `VV(:)` | `wind_speed(:)` | Current and monthly wind speed, m/s; monthly `(catchment, month)` |
| `VVMM(:,:)` | `monthly_wind_speed(:,:)` | Current and monthly wind speed, m/s; monthly `(catchment, month)` |
| `SOL(:)` | `solar_input(:)` | Current and monthly solar input or configured sunshine representation |
| `SOLMM(:,:)` | `monthly_solar_input(:,:)` | Current and monthly solar input or configured sunshine representation |
| `PA(:)` | `air_pressure(:)` | Current and monthly atmospheric pressure, kPa; monthly `(catchment, month)` |
| `PAMM(:,:)` | `monthly_air_pressure(:,:)` | Current and monthly atmospheric pressure, kPa; monthly `(catchment, month)` |
| `XYC(:,:)` | `climate_station_coordinates(:,:)` | Climate coordinates; `(catchment, coordinate)` |
| `TONTEM(:)` | `previous_air_temperature(:)` | Retained prior air temperature, °C |
| `QLIDO(:,:)` | `substituted_q(:,:)` | Substituted discharge; `(substitution series, timestep)`, m³/s |
| `Qdefl(:,:)` | `reservoir_outflow(:,:)` | Reservoir outflow series; `(timestep, reservoir)`, m³/s |

## State

### Calendar and water balance

| Legacy identifier | Current identifier | Meaning, dimensions, and units |
| --- | --- | --- |
| `iday` | `day` | Current calendar fields |
| `imonth` | `month` | Current calendar fields |
| `iyear` | `year` | Current calendar fields |
| `ihour` | `hour` | Current calendar fields |
| `iminute` | `minute` | Current calendar fields |
| `doy` | `day_of_year` | Day of year |
| `jday` | `julian_day` | Current Julian date |
| `W(:,:)` | `soil_water_storage(:,:)` | Soil-water storage; `(catchment, HRU)`, mm |
| `SI(:,:)` | `interception_storage(:,:)` | Intercepted water storage; `(catchment, HRU)`, mm |
| `ET(:,:)` | `evapotranspiration(:,:)` | HRU evapotranspiration; `(catchment, HRU)`, mm/timestep |
| `CAF(:,:)` | `capillary_flux(:,:)` | Upward capillary flux; `(catchment, HRU)`, mm/timestep |
| `QBAS(:)` | `groundwater_q(:)` | Catchment runoff components, m³/s |
| `QINT(:)` | `subsurface_q(:)` | Catchment runoff components, m³/s |
| `QSUP(:)` | `surface_q(:)` | Catchment runoff components, m³/s |
| `VBAS(:)` | `groundwater_storage(:)` | Terrestrial linear-reservoir stores, m³ |
| `VINT(:)` | `subsurface_storage(:)` | Terrestrial linear-reservoir stores, m³ |
| `VSUP(:)` | `surface_storage(:)` | Terrestrial linear-reservoir stores, m³ |
| `EVQ(:)` | `open_water_evaporation_q(:)` | Open-water evaporation discharge, m³/s |
| `DINFILT(:)` | `floodplain_infiltration(:)` | Floodplain-to-soil infiltration depth, mm/timestep |
| `TWS(:)` | `grace_total_water_storage(:)` | Legacy GRACE comparison storage; current declaration remains allocated and initialized, with no active calculation call site |
| `TWS2(:)` | `total_water_storage(:)` | Legacy catchment terrestrial-storage accumulator; current total terrestrial storage, mm |

### Muskingum-Cunge routing state

| Legacy identifier | Current identifier | Meaning, dimensions, and units |
| --- | --- | --- |
| `QM1(:)` | `incoming_q_previous(:)` | Upstream/incoming routed discharge at previous and current routing timestep, m³/s |
| `QM2(:)` | `incoming_q_current(:)` | Upstream/incoming routed discharge at previous and current routing timestep, m³/s |
| `QJ1(:)` | `outgoing_q_previous(:)` | Downstream/outgoing routed discharge at previous and current routing timestep, m³/s |
| `QJ2(:)` | `outgoing_q_current(:)` | Downstream/outgoing routed discharge at previous and current routing timestep, m³/s |
| `QCEL1(:)` | `catchment_q_previous(:)` | Local catchment-generated discharge at previous and current timestep, m³/s |
| `QCEL2(:)` | `catchment_q_current(:)` | Local catchment-generated discharge at previous and current timestep, m³/s |
| `PMB1(:)` | `incoming_groundwater_fraction_previous(:)` | Previous incoming flow fractions by source; dimensionless |
| `PMI1(:)` | `incoming_subsurface_fraction_previous(:)` | Previous incoming flow fractions by source; dimensionless |
| `PMS1(:)` | `incoming_surface_fraction_previous(:)` | Previous incoming flow fractions by source; dimensionless |
| `PMB2(:)` | `incoming_groundwater_fraction_current(:)` | Current incoming flow fractions by source; dimensionless |
| `PMI2(:)` | `incoming_subsurface_fraction_current(:)` | Current incoming flow fractions by source; dimensionless |
| `PMS2(:)` | `incoming_surface_fraction_current(:)` | Current incoming flow fractions by source; dimensionless |
| `PJB1(:)` | `outgoing_groundwater_fraction_previous(:)` | Previous outgoing flow fractions by source; dimensionless |
| `PJI1(:)` | `outgoing_subsurface_fraction_previous(:)` | Previous outgoing flow fractions by source; dimensionless |
| `PJS1(:)` | `outgoing_surface_fraction_previous(:)` | Previous outgoing flow fractions by source; dimensionless |
| `PJB2(:)` | `outgoing_groundwater_fraction_current(:)` | Current outgoing flow fractions by source; dimensionless |
| `PJI2(:)` | `outgoing_subsurface_fraction_current(:)` | Current outgoing flow fractions by source; dimensionless |
| `PJS2(:)` | `outgoing_surface_fraction_current(:)` | Current outgoing flow fractions by source; dimensionless |
| `VRB(:)` | `groundwater_routing_volume(:)` | Source-attributed Muskingum routing storage, m³ |
| `VRI(:)` | `subsurface_routing_volume(:)` | Source-attributed Muskingum routing storage, m³ |
| `VRS(:)` | `surface_routing_volume(:)` | Source-attributed Muskingum routing storage, m³ |
| `QCONTORM(:,:)` | `incoming_q_boundary(:,:)` | Intra-timestep routing boundary hydrographs; `(catchment, internal substep)`, m³/s |
| `QCONTORJ(:,:)` | `outgoing_q_boundary(:,:)` | Intra-timestep routing boundary hydrographs; `(catchment, internal substep)`, m³/s |
| `QRIOINI(:,:)` | `initial_river_q(:,:)` | Initial river discharge per Muskingum reach; `(catchment, reach)`, m³/s |
| `vflow(:)` | `flow_velocity(:)` | Derived river flow velocity, m/s |

### Output buffers

| Legacy identifier | Current identifier | Meaning, dimensions, and units |
| --- | --- | --- |
| `QTUDO(:)` | `q_river_output(:)` | Discharge output buffer, m³/s per catchment |
| `YTUDO(:)` | `water_surface_elevation_output(:)` | Water-surface elevation output buffer, m |
| `TWSTUDO(:)` | `total_water_storage_output(:)` | Total water storage output buffer, mm |
| `ALAGTUDO(:)` | `flooded_area_output(:)` | Flooded area output buffer, km² |
| `HANDTUDO(:)` | `hand_output(:)` | HAND-relative flooded-level output buffer, m |
| `QITUDO(:)` | `incremental_q_output(:)` | Incremental discharge output buffer, m³/s |
| `EVAPTUDO(:)` | `et_output(:)` | Total evapotranspiration output buffer, mm |
| `QBASTUDO(:)` | `groundwater_q_output(:)` | Groundwater-flow output buffer, m³/s |
| `WSATDEGREE(:)` | `soil_saturation_output(:)` | Soil saturation output buffer, dimensionless |
| `ETINTERC(:)` | `interception_et_output(:)` | Component evapotranspiration output buffers, mm |
| `ETSOILPLANT(:)` | `soil_vegetation_et_output(:)` | Component evapotranspiration output buffers, mm |
| `ETOPENWAT(:)` | `open_water_et_output(:)` | Component evapotranspiration output buffers, mm |
| `EVAPURHAGUA(:)` | `water_hru_et_output(:)` | Component evapotranspiration output buffers, mm |
| `POTETWAT(:)` | `potential_open_water_et_output(:)` | Potential open-water ET output buffer, mm |
| `SOILWATER(:)` | `soil_water_output(:)` | Soil, capillary, and interception output buffers, mm |
| `CAPWATER(:)` | `capillary_water_output(:)` | Soil, capillary, and interception output buffers, mm |
| `VINTERC(:)` | `interception_storage_output(:)` | Soil, capillary, and interception output buffers, mm |
| `VBASMMDIA(:)` | `groundwater_storage_depth_output(:)` | Storage-depth output buffers, mm |
| `VINTMMDIA(:)` | `subsurface_storage_depth_output(:)` | Storage-depth output buffers, mm |
| `VSUPMMDIA(:)` | `surface_storage_depth_output(:)` | Storage-depth output buffers, mm |
| `DBASMMDIA(:)` | `groundwater_runoff_depth_output(:)` | Runoff-depth output buffers, mm/timestep |
| `DINTMMDIA(:)` | `subsurface_runoff_depth_output(:)` | Runoff-depth output buffers, mm/timestep |
| `DSUPMMDIA(:)` | `surface_runoff_depth_output(:)` | Runoff-depth output buffers, mm/timestep |
| `SURFWAT(:)` | `surface_water_output(:)` | Surface-water depth and catchment discharge output buffers |
| `QCELTUDO(:)` | `catchment_q_output(:)` | Surface-water depth and catchment discharge output buffers |

### Local-inertial routing state

| Legacy identifier | Current identifier | Meaning, dimensions, and units |
| --- | --- | --- |
| `Q2fl(:)` | `inertial_q(:)` | Inertial river discharge, m³/s |
| `Qmont(:)` | `upstream_q(:)` | Upstream discharge scratch retained in the namespace; current declarations allocate three entries and have no active call sites |
| `Vol1(:)` | `previous_water_volume(:)` | Previous and current channel/floodplain volume, m³ |
| `Vol2(:)` | `current_water_volume(:)` | Previous and current channel/floodplain volume, m³ |
| `Area2(:)` | `current_flooded_area(:)` | Current flooded area, km² |
| `Hfl(:)` | `water_depth(:)` | Water depth above the channel/floodplain datum, m |
| `Yfl(:)` | `water_surface_elevation(:)` | Water-surface elevation, m |
| `Q2face(:)` | `face_q(:)` | Discharge at pseudo-2D faces, m³/s |
| `Q2viz(:)` | `neighbor_q(:)` | Net neighboring-face discharge by catchment, m³/s |
| `jtab(:)` | `stage_table_index(:)` | Current stage-volume lookup index |
