# Model overview

MGB is a distributed model for large-scale hydrology and hydrodynamics. It
represents land-surface water and energy balances, runoff generation within
catchments, flow through the river network, and, with local-inertial routing,
river-floodplain storage and exchange. The current executable operates on a
prepared basin discretization and prepared meteorological forcing; it does not
create the drainage network, hydrological response units, or forcing products.

This section documents the scientific behavior of the current Fortran
implementation. It describes implemented equations, parameter roles,
calculation order, initial conditions, and numerical assumptions. The
[Architecture overview](../architecture/architecture.md) separately explains
how those responsibilities are organized in the source.

## Process chain

Each meteorological timestep advances water from atmospheric forcing through
the terrestrial system and into the explicit river network:

```text
meteorological forcing
        |
        v
HRU water and energy balances
        |
        v
surface + subsurface + groundwater generation
        |
        v
catchment linear reservoirs
        |
        v
Muskingum-Cunge or local-inertial river routing
        |
        v
river, floodplain, water-balance, and diagnostic outputs
```

Precipitation and the selected meteorological variables drive an independent
water and energy balance for every active hydrological response unit (HRU) in
a catchment. HRU fluxes are area-weighted into catchment totals. Surface,
subsurface, and groundwater components pass through separate linear reservoirs
before entering the explicitly represented river reach. River flow then moves
through the connected catchment network with one routing method selected for
the entire run.

The order of these calculations is part of the numerical behavior. The exact
timestep sequence and implementation invariants are recorded under
[Model processes and numerical assumptions](model-processes.md).

## Spatial and temporal representation

The model represents a basin with four related classifications:

| Unit | Role |
| --- | --- |
| Catchment | Immediate contributing area and one explicit river segment |
| HRU | Fraction of a catchment with a common land-cover and soil response |
| Subbasin | Group of catchments sharing terrestrial parameter sets and run selection |
| Climate region | Group of catchments sharing monthly vegetation properties |

HRUs are stored as area fractions rather than positioned polygons. Network
connectivity remains defined between catchments, while subbasins regionalize
parameters. One meteorological timestep advances every enabled catchment and
HRU; river routing uses internal substeps within that interval. The detailed
spatial hierarchy and discretization assumptions are described in
[Concepts and discretization](model-concepts.md).

## River-routing choices

The global `routing_mode` selects one method for all catchments in a run:

| Capability | Muskingum-Cunge | Local-inertial |
| --- | --- | --- |
| Main representation | Hydrological wave routing | Reduced Saint-Venant momentum and continuity equations |
| Internal timestep | 24 routing substeps per meteorological timestep | Stability-controlled substeps |
| Reverse and backwater flow | Not represented | Represented by signed discharge and water-surface gradients |
| Dynamic floodplain storage | Not represented | Stage-area-volume tables couple channel and floodplain storage |
| Open-water interaction | Water-HRU evaporation is removed during routing | Precipitation, evaporation, and infiltration act on flooded area |

The [River routing overview](river-routing.md) explains the shared network
context and routing selection. The complete formulations are documented in
[Muskingum-Cunge routing](muskingum-cunge-routing.md) and
[Local-inertial routing](local-inertial-routing.md).

## Runtime boundary

The executable consumes already prepared catchment attributes, HRU fractions,
parameters, climatology, timestep forcing, and optional floodplain, reservoir,
substitution-flow, and hotstart data. GIS delineation, HAND processing,
meteorological interpolation, calibration, and parameter estimation occur
outside this repository's runtime.

The simulation produces catchment-ordered binary streams for configured water
balance, discharge, level, storage, evaporation, flux, and flooded-area
variables. It can also read and write hotstarts. The authoritative filenames,
configuration keys, layouts, precision, and units are listed in the
[I/O reference](../architecture/io-reference.md).

## Detailed model references

- [Concepts and discretization](model-concepts.md) defines the spatial units
  and their relationships.
- [Energy balance and evapotranspiration](energy-balance.md) documents
  radiation, resistances, evaporative demand, and its partitioning.
- [Soil and catchment processes](soil-and-catchment-processes.md) documents
  soil storage, runoff generation, groundwater exchange, aggregation, and
  terrestrial routing.
- [River routing](river-routing.md) introduces the routing alternatives and
  links to each complete method.
- [Parameters and initial state](parameters-and-initial-state.md) records
  parameter indexing, forcing boundaries, and default initialization.
- [Model processes and numerical assumptions](model-processes.md) records
  timestep order and behavior-preserving invariants.
- [Scientific references](references.md) identifies the manuals, methods, and
  publications supporting this documentation.
