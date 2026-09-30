# Routine-local variable mapping

The legacy `VARS_MAIN` and `VARS_INERC` modules exposed some loop indices,
equation inputs, and calculation temporaries as shared variables. This page
maps selected names to the local arguments and values used by current routines.
For values that remain in shared modules, see the
[shared-variable mapping](shared-variables.md).

## Simulation control

| Legacy identifier | Current local name | Meaning and migration note |
| --- | --- | --- |
| `IT` | `i_step` in `run_timestep_loop` | Timestep-loop index; moved out of shared state |

## Catchment equations

Selected names from the legacy energy-balance equations now appear as local
arguments or temporaries in `calculate_et_demand` and
`calculate_net_radiation`. Their scientific meaning is documented in
[Energy balance and evapotranspiration](../model/energy-balance.md).

| Legacy identifier | Current local name or input | Meaning and units |
| --- | --- | --- |
| `GLAT` | `lat` from <br> `attributes.catchment_lat` | Catchment latitude, degrees; south is negative |
| `SOLX` | `solar` from <br> `forcing.solar_input` | Solar forcing in the configured representation |
| `T2` | `ta` from <br> `forcing.air_temperature` | Current air temperature, °C |
| `T1` | `t_prev` from <br> `forcing.previous_air_temperature` | Previous-step air temperature, °C |
| `URX` | `rh` from <br> `forcing.relative_humidity` | Relative humidity, percent |
| `ALBX` | `alb` from <br> `parameters.albedo` | HRU albedo, dimensionless |
| `RLX` | `r_net` | Net radiation flux, MJ/(m² s) |
| `ED` | `e_d` | Vapor-pressure deficit, kPa |
| `DEL` | `s_e` | Slope of saturation-vapor-pressure curve, kPa/°C |
| `GAMA` | `gamma` | Psychrometric constant, kPa/°C |
| `MSPA` | `rho_a` | Air density, kg/m³ |
| `RUG` | `z0` | Vegetation roughness length, m |
| `RA` | `r_a` | Aerodynamic resistance for vegetation and open water, s/m |
| `RAEP` | `r_aw` | Aerodynamic resistance for vegetation and open water, s/m |
| `WL` | `w_u` | Upper soil-water threshold and wilting storage, mm |
| `WPM` | `w_w` | Upper soil-water threshold and wilting storage, mm |
| `F4` | `f_rs` | Soil-moisture resistance factor, dimensionless |
| `EIX` | `et_int_pot` | Potential interception ET, potential water ET, and actual interception ET, mm/timestep |
| `EIXP` | `et_water_pot` | Potential interception ET, potential water ET, and actual interception ET, mm/timestep |
| `REIX` | `et_int` | Potential interception ET, potential water ET, and actual interception ET, mm/timestep |
| `FDE` | `f_et` | Remaining potential-ET fraction, dimensionless |

## Muskingum-Cunge routing

| Legacy identifier | Current local name | Meaning and units |
| --- | --- | --- |
| `BRX` | `b_river` in `river_muskingum` | River width used by Muskingum-Cunge reach calculations, m |

## Local-inertial routing

### Routing timestep

| Legacy identifier | Current local value | Meaning and migration note |
| --- | --- | --- |
| `dtfloodmax` | `dt_max` | Upper bound for the selected routing timestep, set to the model timestep in seconds |
| `dtflood` | `dt_cfl` in <br> `calculate_inertial_timestep`; <br> `dt_route` in <br> `route_inertial_flow` | Catchment CFL candidate and selected inertial substep, respectively; seconds |
| `dtflood0` | `dt_remaining` | Model-timestep duration used as the routing-loop boundary, seconds |
| `tflood` | `dt_elapsed` | Elapsed routing time within the current model timestep, seconds |
| `hmaxfl` | `h_max` | Current catchment flow depth used by the CFL condition, floored at 0.001 m |

### Flow and continuity

| Legacy identifier | Current local value | Meaning and migration note |
| --- | --- | --- |
| `xMan` | `n_flow` | Upstream catchment Manning roughness used by the inertial equation, s/m¹ᐟ³ |
| `SumQup` | `q_up` | Sum of upstream inertial discharges entering a catchment, m³/s; local scalar |

### Unused legacy auxiliary

| Legacy identifier | Current local value | Meaning and migration note |
| --- | --- | --- |
| `HRX` | — | Declared in the legacy `VARS_INERC` module but never referenced by legacy routines; no current successor |

Other legacy calculation temporaries, including `WX`, `BX`, `SDECL`, `XLADO`,
and loop counters, are local to `catchment`, `river_muskingum`, or
`river_inertial`, or have been removed when unused.
