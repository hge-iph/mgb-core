# Model processes and numerical assumptions

This page records the assumptions that must remain visible when the legacy
implementation is changed. It describes the current executable order; it is
not a replacement algorithm specification. For the equations and conceptual
background, start with [Model concepts and discretization](model-concepts.md),
then use the detailed pages for [energy and evapotranspiration](energy-balance.md),
[soil and catchment processes](soil-and-catchment-processes.md),
[river routing](river-routing.md), and
[parameters and initial state](parameters-and-initial-state.md).

## Timestep order

For each meteorological timestep, MGB:

1. optionally writes the configured hotstart state;
2. reads precipitation and the selected meteorological forcing series;
3. calculates evapotranspiration and then updates runoff for every HRU within
   the vertical water-balance loop;
4. routes the river network with Muskingum-Cunge when selected;
5. assembles lateral groundwater, subsurface, and surface inflows;
6. advances local inertial routing, including floodplain continuity;
7. stores one output value per catchment for each enabled output stream; and
8. advances the calendar and Julian date.

The order is part of the numerical behavior. In particular, the `catchment`
module calculates evapotranspiration for each HRU before updating that HRU's
soil storage and generated flow. The current timestep forcing is used by this
vertical balance before lateral inflow is handed to routing.

## Vertical water balance

Each catchment is partitioned into HRUs. HRU percentages are area fractions and
must sum to 100 percent for every catchment. Precipitation is converted into
the catchment/HRU balance, with the flooded area removed from the effective
terrestrial area when inertial flood routing is active.

The soil storage uses the ARNO infiltration relationship. The current
implementation limits infiltration by available storage and precipitation,
produces surface runoff when the soil cannot accept the water, and routes
subsurface and groundwater contributions through linear reservoirs. State
updates include:

- soil water storage;
- interception storage;
- surface, subsurface, and groundwater reservoir storage;
- capillary transfer from groundwater to soil; and
- surface, subsurface, and groundwater fluxes.

The executable uses the groundwater threshold for both groundwater and
subsurface drainage. With inertial routing, the effective floodplain
infiltration rate is `min(Kint, 20 mm/day)`; the `Kinf` field read from
`soil.par` is not the rate ultimately used by this calculation.

Depth variables are generally in millimetres over the catchment or HRU.
Discharge variables are in cubic metres per second. Reservoir volumes used by
the flood solver are cubic metres. Conversions between depth, area, and
discharge are retained in the source and must not be moved across the timestep
boundary without a regression justification.

## Evapotranspiration

The evapotranspiration routine computes evaporative demand from radiation,
temperature, humidity, pressure, wind, vegetation, and surface parameters. It
separates:

- evaporation from canopy interception;
- soil and vegetation evapotranspiration;
- evaporation from open flood waters;
- evaporation from water HRUs; and
- potential open-water evaporation.

Available interception storage limits actual interception evaporation. Soil and
vegetation demand is limited by soil moisture thresholds and available water.
The current unstressed threshold is 80 percent of maximum soil storage.
Open-water demand is applied to the water surface and is also included in the
floodplain continuity adjustment. Reported evapotranspiration outputs are
depths per model timestep unless explicitly identified as potential demand.

## Radiation and meteorological forcing

The forcing reader always reads one precipitation record per model timestep.
Temperature, radiation, humidity, wind, and pressure can independently use
direct-access time series or monthly climatology according to the forcing
flags. Monthly radiation option selects the stored radiation interpretation:
sunshine hours, sunshine percentage, or radiation.

Net radiation combines shortwave and longwave terms using the configured
albedo, day-of-year geometry, humidity, temperature, and pressure. The source
uses its existing constants and precision; this description does not authorize
changing units or replacing the radiation method.

## River routing

Routing mode zero uses Muskingum-Cunge reaches. Catchment parameters determine
reach count, celerity, wave travel time, channel geometry, and routing
coefficients. The implementation preserves the legacy reach subdivision limit
and its upstream/downstream boundary ordering.

Routing mode one uses the local inertial solver. It selects a stable internal
timestep from the current water depth and reach length of every enabled
catchment, together with the configured Courant alpha and gravity. The
downstream boundary slope is supplied in metres per kilometre and converted to
metres per metre by multiplying by 0.001 before it is used. The configured
thread count controls the existing OpenMP parallel regions.

## Floodplain continuity

For an inertial catchment, water volume is advanced from the previous volume by
the internal timestep. The balance includes upstream discharge, local
catchment lateral inflow, outgoing channel discharge, precipitation,
floodplain infiltration, and open-water evaporation. It also contains a term
for pseudo-two-dimensional face/neighbor exchange, but the current runtime
configuration always disables that path, so the term is zero. The continuity
update is repeated until the model timestep is consumed.

Stage, depth, and flooded area are updated after the volume step. Reservoir
outflow substitution, when enabled, is applied at the existing routing point
and retains its interpolation over the internal timestep.

## Stage-area extrapolation

The floodplain tables contain a bottom elevation and elevation/area points.
The runtime builds stage, area, and cumulative volume tables for each
catchment. Between table points, stage and area are linearly interpolated in
volume space.

When volume exceeds the upper table bound, the implementation holds the last
available flooded area constant and increases stage by the excess volume divided
by that area. This is intentional behavior for the available topographic
table, including reservoir-like water bodies. A minimum positive water depth
is retained when a flooded catchment is nearly dry.

## Numerical invariants

The migration preserves:

- source execution order and branching;
- single- versus double-precision declarations;
- direct-access record lengths and record ordering;
- date formatting used in hotstart names;
- HRU and catchment row ordering;
- binary payloads and text numerical fields; and
- the executable name, mgb_model.

The new names are a deliberate interface break. They do not imply conversion
of old datasets or automatic discovery of historical aliases.
