# I/O reference

All paths below are relative to the runtime input or output directory selected
by the executable. The model uses direct-access unformatted records for the
binary files. Record lengths are derived with `INQUIRE(IOLENGTH=...)` so Intel
and GNU compilers retain the established physical record layouts.

Runtime file ownership is centralized: `configuration_io` owns `config.nml`,
`static_input_io` owns static parameter, catchment, climatology, substitution,
reservoir, and floodplain inputs, `meteorological_io` owns forcing streams,
`hotstart_io` owns hotstart files and schedules, and `output_io` owns the log
and model output streams. Scientific modules do not open or close model files.

## Configuration

The only configuration file is config.nml. It contains four namelist
groups.

### model

| Key | Meaning and units |
| --- | --- |
| simulation_start, simulation_end | Calendar strings: YYYY-MM-DD HH:mm |
| timestep | Meteorological timestep in seconds |
| hotstart_read_mode, hotstart_write_mode | Hotstart mode flags |
| first_subbasin, last_subbasin | Inclusive simulated subbasin bounds |
| catchment_count, hru_count, subbasin_count | Entity counts |
| climate_region_count | Number of climate regions |
| reservoir_substitution_enabled | Enables reservoir substitution |
| reservoir_count | Number of reservoir records |

### forcing

| Key | Meaning and units |
| --- | --- |
| use_temperature_timeseries | Use air_temperature.bin instead of monthly means |
| use_radiation_timeseries | Use solar_radiation.bin instead of monthly means |
| use_humidity_timeseries | Use relative_humidity.bin instead of monthly means |
| use_wind_timeseries | Use wind_speed.bin instead of monthly means |
| use_pressure_timeseries | Use air_pressure.bin instead of monthly means |
| monthly_radiation_option | 0 sunshine hours, 1 sunshine percent, 2 radiation |

### routing

| Key | Meaning and units |
| --- | --- |
| routing_mode | 0 Muskingum-Cunge, 1 local inertial |
| thread_count | OpenMP thread count |
| downstream_boundary_slope | Downstream slope in m/km |
| courant_alpha | CFL stability factor |

### output

Every output flag is an integer: 1 writes the stream and 0 disables it.

write_discharge, write_water_surface_elevation, write_flooded_level,
write_runoff, write_soil_water, write_soil_saturation,
write_total_water_storage, write_surface_water, write_evapotranspiration,
write_interception_evaporation, write_soil_vegetation_evapotranspiration,
write_open_water_evaporation, write_water_hru_evaporation,
write_potential_open_water_evaporation, write_groundwater_storage,
write_subsurface_storage, write_surface_storage, write_interception_storage,
write_groundwater_flux, write_subsurface_flux, write_surface_flux, and
write_flooded_area are the complete output key set.

## Input files

### Static text inputs

| File | Format and ordering |
| --- | --- |
| vegetation.par | Four parameter blocks. Each HRU row has a 10-character identifier, 12 monthly values with F5.2 precision, 12 monthly names/labels, and four fixed fields. |
| hru.def | The authoritative HRU dictionary. The current fixture has nine rows in order: blc_01 through blc_09. Comment lines begin with two slashes. |
| climate.reg | Header followed by one two-integer climate-region record per catchment. |
| mini.gtp | Header followed by catchment records in input order. The fixed legacy fields are catchment sequence/id, area and drainage geometry, network/subbasin fields, routing parameters, and six geometry/parameter values, followed by the HRU percentages. |
| soil.par | HRU calibration rows use A10 identifiers and the existing fixed F8.3, F8.1, and F8.6 numeric fields, followed by subbasin routing parameter rows. |
| floodplain_stage_area.txt | Text stage-area records: catchment index, bottom/elevation value, stage/elevation, and area. |
| floodplain_connections.txt | Face connection records used by the pseudo-2D path. The current text reader retains the historical connection layout and the active binary floodplain path remains unchanged. |
| substitution_flows.txt | Header fields followed by date/time and reservoir substitution flow records. |
| observed_discharge.dat | Observed discharge fixture used by regression and performance tooling. |
| hotstart_schedule.txt | Hotstart timestep schedule read as integer records. |
| reservoir_config.txt | Reservoir-to-catchment and lake configuration records when reservoir substitution is enabled. |
| reservoir_outflow.txt | Time-indexed reservoir outflow records when reservoir substitution is enabled. |

Numeric text fields and row ordering are preserved. The descriptive HRU labels
blc_01 through blc_09 replace the old labels without changing any numeric row
data.

### Binary forcing inputs

precipitation.bin and the optional meteorological series are direct-access,
unformatted records. Each record contains catchment_count single-precision
values in catchment index order:

- precipitation.bin: precipitation depth for the timestep, normally mm;
- air_temperature.bin: air temperature, degrees Celsius;
- solar_radiation.bin: radiation or the configured sunshine representation;
- relative_humidity.bin: relative humidity, percent;
- wind_speed.bin: wind speed at the forcing height, m/s; and
- air_pressure.bin: atmospheric pressure, kPa.

monthly_climatology.bin stores the monthly climatology in the legacy record
order: 12 temperature values, 12 relative-humidity values, 12 radiation
values, 12 wind values, and 12 pressure values for each climate cell. The
existing precision and direct-access record length are authoritative.

flood_stage.bin and flood_area.bin retain their existing names and binary
layouts. Stage data use the bottom-elevation records expected by the flood
table builder; area data provide the fixed floodplain point records. Do not
reinterpret their byte order or precision from the filename extension.

## Hotstarts

Hotstarts are named water_balance_state_DATE.bin and
inertial_state_DATE.bin, where DATE is the existing YYYYMMDDHH date string.
The water-balance file stores the legacy state vector in its existing order:
HRU soil/interception state, catchment reservoir state, routing state, and
other water-balance values. The inertial file stores nine double-precision
values per catchment in the existing order: inertial discharge, water depth,
water-surface elevation, previous volume, current volume, flooded area, stage
table index, face discharge, and neighbor discharge.

hotstart_schedule.txt selects write times. Record lengths are calculated from
the actual single- or double-precision vectors, preserving compatibility between
the validated Intel and Linux GNU builds.

## Output files

Each enabled output is a direct-access unformatted stream. Record number is
the model timestep. Each record contains catchment_count single-precision
values in catchment index order, with no header. The values and units are:

| File | Value |
| --- | --- |
| discharge.bin | River discharge, m3/s |
| level.bin | Water-surface elevation, m |
| flooded_level.bin | HAND-relative flooded level, m |
| runoff.bin | Total catchment runoff, mm |
| soil_water.bin | Soil water, mm |
| soil_saturation.bin | Soil saturation degree |
| total_water_storage.bin | Terrestrial water storage, mm |
| surface_water.bin | Surface-water volume/depth output, mm |
| evapotranspiration.bin | Total evapotranspiration, mm |
| interception_evaporation.bin | Interception evaporation, mm |
| soil_vegetation_evapotranspiration.bin | Soil plus vegetation ET, mm |
| open_water_evaporation.bin | Dynamic open-water evaporation, mm |
| water_hru_evaporation.bin | Water-HRU evaporation, mm |
| potential_open_water_evaporation.bin | Potential open-water evaporation, mm |
| groundwater_storage.bin | Groundwater storage depth, mm |
| subsurface_storage.bin | Subsurface storage depth, mm |
| surface_storage.bin | Surface storage depth, mm |
| interception_storage.bin | Interception storage, mm |
| groundwater_flux.bin | Groundwater flux depth, mm |
| subsurface_flux.bin | Subsurface flux depth, mm |
| surface_flux.bin | Surface flux depth, mm |
| flooded_area.bin | Flooded area, square kilometres |

The model also writes model.log. Regression fixtures may contain
model_performance.txt and soil_diagnostics.txt; these are descriptive fixture
names and do not change the underlying text fields.

## Precision and compatibility

The .bin extension describes a binary payload, not a newly defined encoding.
The source open statements and `INQUIRE(IOLENGTH=...)` results define the record
lengths, precision, access mode, and ordering. Compiler portability does not
convert payloads, rescale numerical fields, add headers, or provide legacy aliases.
