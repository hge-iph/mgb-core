# Parameters and initial state

MGB combines parameters that describe HRU vegetation, soil-water response,
catchment geometry, terrestrial routing, and river routing. This page explains
their role in the equations and records the initial conditions used by the
current executable. File layouts and ordering requirements remain documented
in the [I/O reference](io-reference.md).

Parameter values must be selected for the basin and input data being modeled.
The current executable does not enforce parameter validity limits, and some
regression datasets intentionally use values outside typical calibration
ranges.

## Parameter indexing

Parameters are associated with different spatial classifications:

| Classification | Examples | Consequence |
| --- | --- | --- |
| HRU, month, and climate region | Albedo, leaf-area index, vegetation height, surface resistance | Represents seasonal vegetation behavior |
| Subbasin and HRU | Maximum soil storage, ARNO shape, conductivities, capillary parameters | Regionalizes land-surface behavior |
| Subbasin | Surface, subsurface, and groundwater delay coefficients; initial specific baseflow | Regionalizes catchment response time and initial groundwater state |
| Catchment | Area, drainage area, channel geometry, roughness, topology | Controls aggregation and river routing |

The same HRU can therefore have different soil parameters in different
subbasins while retaining vegetation seasonality selected by its climate
region.

## Vegetation and surface parameters

`vegetation.par` supplies 12 monthly values for each HRU and climate region:

| Parameter | Units | Role |
| --- | --- | --- |
| Albedo $\alpha$ | Dimensionless | Fraction of incoming shortwave radiation reflected by the surface |
| Leaf-area index $LAI$ | Dimensionless | Controls maximum interception storage |
| Vegetation height $z_v$ | m | Controls roughness and aerodynamic resistance |
| Minimum surface resistance $r_{s,\min}$ | $\mathrm{s\,m^{-1}}$ | Controls unstressed soil and vegetation evapotranspiration |

The executable multiplies all surface-resistance values by 1.5 when it reads
the file. Soil moisture then increases the effective resistance below
$0.8W_m$, as detailed in
[Energy balance and evapotranspiration](energy-balance.md).

These properties are usually estimated from vegetation information rather
than adjusted solely to fit discharge, but the executable does not enforce a
distinction between fixed and calibrated values.

## Soil and generated-flow parameters

Each HRU row in each `soil.par` subbasin block contains:

| Input field | Source meaning | Units | Effect in the current model |
| --- | --- | --- | --- |
| `Wm` | Maximum soil-water storage $W_m$ | mm | Sets the available soil store and scales moisture thresholds |
| `b` | ARNO shape $b$ | Dimensionless | Controls the growth of saturated area and surface runoff |
| `Kbas` | Groundwater conductivity $K_{bas}$ | mm/day | Controls slow percolation from soil to groundwater storage |
| `Kint` | Subsurface conductivity $K_{int}$ | mm/day | Controls intermediate drainage and the effective floodplain infiltration rate |
| `XL` | Brooks-Corey index $\lambda$ | Dimensionless | Controls the nonlinearity of subsurface drainage |
| `CAP` | Maximum capillary flux | mm/day | Controls possible return from groundwater to dry soil |
| `Wc` | Moisture-threshold fraction $w_c$ | Dimensionless | Defines groundwater, subsurface, and capillary activation storage |
| `Kinf` | Legacy floodplain infiltration field | mm/day | Read into memory but replaced by $\min(K_{int},20)$ during inertial calculations |

Increasing $W_m$ increases the amount of water that can remain available for
evapotranspiration and generally delays saturation. Increasing $b$ increases
the represented saturated fraction at intermediate storage, making surface
runoff more responsive to smaller rainfall events. Increasing $K_{int}$ or
$K_{bas}$ increases the corresponding soil drainage rate, subject to storage
and timestep limits.

The executable caps `Wc` at 0.1 before applying it. `CAP=0` disables capillary
return. The precise flux equations and their limiting order are documented in
[Soil and catchment processes](soil-and-catchment-processes.md).

## Catchment delay and initial-baseflow parameters

After the HRU rows, each subbasin block supplies:

| Input field | Units | Role |
| --- | --- | --- |
| `CS` | Dimensionless | Multiplier of catchment time of concentration for the surface reservoir |
| `CI` | Dimensionless | Multiplier of catchment time of concentration for the subsurface reservoir |
| `CB` | hours | Groundwater-reservoir delay |
| `QB_M3/SKM2` | $\mathrm{m^3\,s^{-1}\,km^{-2}}$ | Specific baseflow used to initialize groundwater storage |

Larger delay coefficients retain generated water in their linear reservoirs
for longer and smooth the contribution to the main river. `CB` is converted
from hours to seconds.

Parameter estimation is external to the current executable and produces the
parameter set supplied in `soil.par`.

## Geometry-derived river parameters

`mini.gtp` supplies catchment area and drainage area, river length and slope,
longest internal reach length and slope, downstream connectivity, river width,
bankfull depth, Manning roughness, and HRU percentages.

During input preparation:

- main river lengths are limited to at least 2.5 km;
- longest internal reaches are limited to at least 0.001 km;
- main river slopes are converted from metres per kilometre to metres per
  metre; and
- reference discharge is derived as $Q_0=0.333A_d^{0.7}$.

Catchment time of concentration, Muskingum-Cunge celerity and subdivision, and
local-inertial initial depth are derived from these prepared values. See
[River routing](river-routing.md).

## Meteorological boundary conditions

Every timestep requires one precipitation record containing a value for each
catchment. Air temperature, solar forcing, relative humidity, wind speed, and
air pressure are independently selected from either a timestep series or the
monthly value for the current calendar month.

The present executable consumes already prepared catchment-ordered binary
arrays. Station interpolation, remote-sensing sampling, and GIS preparation
are preprocessing steps that happen before these files are provided and are not
runtime capabilities of this repository.

Solar climatology can represent sunshine hours, sunshine percentage, or
radiation according to `monthly_radiation_option`. A direct solar-radiation
series bypasses that climatological conversion. Exact filenames and units are
listed in the [I/O reference](io-reference.md).

The local-inertial downstream boundary is controlled by
`downstream_boundary_slope`, except for its fixed-level and reservoir-dam
special cases. Those conditions are detailed in [River routing](river-routing.md).

## Default initial state

When no hotstart replaces the initialized state, the land-surface variables
are set as follows for catchment $i$, HRU $j$, and its subbasin $s$:

$$
W_{i,j}^{0}=0.15W_{m,s,j},
$$

$$
S_{i,j}^{0}=0,
\qquad
V_{sup,i}^{0}=0,
\qquad
V_{int,i}^{0}=0.
$$

Here $S$ is interception storage and $V_{sup}$ and $V_{int}$ are the surface
and subsurface linear-reservoir volumes. The current source initializes soil
storage to 15% of maximum storage.

For specific baseflow $q_{b,s}$, catchment area $A_i$, and groundwater delay
$C_{B,s}$ in hours,

$$
Q_{bas,i}^{0}=q_{b,s}A_i,
$$

$$
V_{bas,i}^{0}=Q_{bas,i}^{0}(3600C_{B,s}).
$$

The retained air temperature is initialized to $20\,^{\circ}\mathrm{C}$ so
the first ground-heat calculation has a preceding value.

Muskingum-Cunge routing is then initialized from the surface, subsurface, and
groundwater discharges accumulated through the network. Local-inertial routing
instead initializes river discharge to $Q_0$ and derives depth and volume from
channel geometry. It also initializes flooded area to the greater of the
stage-area interpolation and the full catchment area. Consequently, the first
terrestrial balance normally sees the entire catchment as flooded; the first
inertial continuity update replaces this with interpolated area capped at the
catchment area. Thus the present river state does not begin completely dry.

If `hotstart_read_mode` requests a restart, the model first performs these
default initializers and then restores the saved water-balance and inertial
payloads. The restored values are the effective starting state.
