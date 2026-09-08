# Complete the Documentation, I/O Naming, and Fortran Style Migration

## Summary

Perform a behavior-preserving but intentionally breaking language migration:

- Keep detailed legacy commentary in Markdown rather than restoring source headers.
- Rename runtime inputs, outputs, namelist keys, and fixture labels to descriptive English names.
- Format all Fortran sources consistently in lowercase with pinned automated tooling.
- Preserve hydrological calculations, numerical values, binary layouts, execution order, and executable name.
- Preserve the user’s existing `blocos.hrc` update and use it as the authoritative nine-HRU definition.

## Runtime Interface Changes

- Replace configuration file `infomgb.sim` with `model_config.nml`.
- Rename namelist groups to `model`, `forcing`, `routing`, and `output`.
- Replace abbreviated keys with their corresponding descriptive source names, including:
  - Model: `simulation_start`, `simulation_end`, `timestep_seconds`, hotstart modes, subbasin bounds, entity counts, and reservoir settings.
  - Forcing: `use_temperature_timeseries`, `use_radiation_timeseries`, `use_humidity_timeseries`, `use_wind_timeseries`, `use_pressure_timeseries`, and `monthly_radiation_option`.
  - Routing: `routing_mode`, `thread_count`, `downstream_boundary_slope_m_per_km`, and `courant_alpha`.
  - Output: `write_discharge`, `write_water_surface_elevation`, and equivalent `write_*` keys for every existing output flag.

- Apply these canonical input filenames:
  - `albiaf.fix` → `vegetation_parameters.txt`
  - `blocos.hrc` → `hru_definitions.txt`
  - `climate_regions.fix` → `climate_regions.txt`
  - `mini.gtp` → `catchment_data.txt`
  - `paruso.cal` → `soil_parameters.txt`
  - `chuvabin.pbi` → `precipitation.bin`
  - `medias_cru.bin` → `monthly_climatology.bin`
  - Meteorological series → `air_temperature.bin`, `solar_radiation.bin`, `relative_humidity.bin`, `wind_speed.bin`, and `air_pressure.bin`
  - `cota_area.flp` → `floodplain_stage_area.txt`
  - `face.con` → `floodplain_connections.txt`
  - `qsubst.qsb` → `substitution_flows.txt`
  - `qobs.qob` → `observed_discharge.txt`
  - `hotstartlist.prev` → `hotstart_schedule.txt`
  - Reservoir files → `reservoir_config.txt` and `reservoir_outflow.txt`
  - Hotstarts → `water_balance_state_<date>.bin` and `inertial_state_<date>.bin`
  - Retain already-conforming `flood_stage.bin` and `flood_area.bin`.

- Standardize HRU identifiers in `fixed_hru_parameters.txt` and `calibrated_parameters.txt` as `blc_01` through `blc_09`, matching the updated HRU dictionary and preserving row order and numerical data.

- Rename binary outputs:
  - `qtudo`/`ytudo`/`qceltudo` → `discharge.bin`, `level.bin`, `runoff.bin`
  - `soilwater`/`wsatdegree`/`twstudo`/`handtudo` → `soil_water.bin`, `soil_saturation.bin`, `total_water_storage.bin`, `flooded_level.bin`
  - Evaporation outputs → `evapotranspiration.bin`, `interception_evaporation.bin`, `soil_vegetation_evapotranspiration.bin`, `open_water_evaporation.bin`, `water_hru_evaporation.bin`, and `potential_open_water_evaporation.bin`
  - Storage/flux outputs → descriptive `groundwater_*`, `subsurface_*`, `surface_*`, `interception_storage.bin`, `surface_water.bin`, and `flooded_area.bin`
  - `log_mgb.txt` → `model.log`; stale fixture names such as `ajuste.fob` and `nosolo.txt` become `model_performance.txt` and `soil_diagnostics.txt`.

- Update all readers, writers, messages, regression fixtures, manifest paths, and documentation. Do not provide legacy aliases.

## Documentation and Source Style

- Audit every legacy source file at `main` and add a per-file disposition ledger showing where each unique header item was migrated or why it was rejected as duplicate, stale, disabled code, or inaccurate.
- Expand the documentation with:
  - Model processes and numerical assumptions, including vertical balance, evapotranspiration, radiation, routing, floodplain continuity, and stage-area extrapolation.
  - A complete I/O reference covering filenames, formats, record ordering, precision, units, and configuration keys.
  - All unique valid legacy citations, contributor attribution, and historical notes.
  - A breaking-change migration table for old and new runtime names.
- Keep source comments concise and local; retain only comments needed to understand an immediate assumption or non-obvious operation.
- Fix the currently broken MkDocs navigation and README roadmap link.

- Add a dedicated Fortran style guide and pinned `fprettify==0.3.7` development dependency/configuration:
  - Four-space indentation; no tabs or trailing whitespace.
  - Maximum 100 columns.
  - Lowercase Fortran keywords, intrinsics, identifiers, operators, and logical constants.
  - Do not alter case inside prose comments, user-facing strings, or proper names.
  - Spaces after commas and around assignment, relational, logical, and additive operators; compact multiplication, division, and exponentiation.
  - Consistent `::` declarations, continuation indentation, and block alignment.
- Format every `.f90` file with this configuration. Do not change kinds, interfaces, relational syntax style, calculations, or declaration semantics.
- Add a CI/local formatting check that runs the pinned formatter and fails on any resulting source diff.

## Test Plan

- Run the formatter twice and verify the second run is clean; run `git diff --check`.
- Verify no uppercase Fortran tokens, tabs, trailing whitespace, or lines over 100 columns remain outside documented exclusions.
- Run `python -m mkdocs build --strict`, including link and navigation validation.
- Build with Intel `ifx` on the available supported platform and run `regression_magdalena`.
- Update the regression manifest to the canonical output names and confirm the renamed binary fixtures and produced outputs retain the existing numerical comparison results.
- Verify renamed binary input and expected-output payloads are byte-identical to their pre-migration versions.
- Confirm all text fixture numerical fields and ordering remain unchanged apart from filenames, headers, namelist keys, and `blc_##` labels.

## Assumptions

- This deliberately breaks compatibility with legacy datasets and output consumers.
- Generic `.txt`, `.nml`, `.bin`, and `.log` extensions replace historical format-specific extensions.
- Scientific behavior and binary record layouts remain unchanged.
- The executable remains `mgb_model`, and supported compiler/platform claims remain limited to validated Intel `ifx` Windows and Linux builds.
