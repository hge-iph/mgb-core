# River routing overview

After the three terrestrial linear reservoirs produce lateral inflow, MGB
routes water along the explicit river network. The global `routing_mode` in
`config.nml` currently replaces the per-catchment routing values read from
`mini.gtp`, so one run uses either Muskingum-Cunge everywhere or local-inertial
routing everywhere.

Muskingum-Cunge is a hydrological approximation for downstream propagation.
The local-inertial solver retains pressure, gravity, friction, and local
acceleration from the Saint-Venant equations and can represent floodplain
storage and backwater flow. The formulations follow Fread (1993), Bates et al.
(2010), Fan et al. (2014), and related MGB work listed in
[References](references.md).

## Routing methods

| Behavior | Muskingum-Cunge | Local-inertial |
| --- | --- | --- |
| Configuration | `routing_mode=0` | `routing_mode=1` |
| Representation | Hydrological reach routing | Local-inertial momentum and continuity |
| Internal timestep | 24 equal substeps | Stability-controlled substeps |
| Discharge direction | Nonnegative downstream flow | Signed flow from water-surface gradients |
| Floodplain | No dynamic floodplain storage | Stage-area-volume storage with surface fluxes |
| Default initialization | Terrestrial baseflow propagated through the network | Reference discharge and geometry-derived depth and volume |

The complete numerical formulations and method-specific implementation
details are documented separately:

- [Muskingum-Cunge routing](muskingum-cunge-routing.md) describes reach
  subdivision, celerity, coefficients, substeps, and initialization.
- [Local-inertial routing](local-inertial-routing.md) describes the staggered
  solver, stability condition, floodplain continuity, stage-area-volume
  tables, initialization, and downstream boundaries.

## Common reference discharge

A reference discharge is derived from upstream drainage area $A_d$ in square
kilometres:

$$
Q_0=0.333A_d^{0.7},
$$

where $Q_0$ is in cubic metres per second. This value is calculated while
`mini.gtp` is read; it is not itself an input column. Muskingum-Cunge uses
$Q_0$ to derive celerity and reach parameters, while local-inertial routing
also uses it to initialize discharge, depth, and volume. Muskingum-Cunge state
itself is initialized from the terrestrial flows.

## Connection to the model timestep

The catchment balance generates surface, subsurface, and groundwater
components. In Muskingum-Cunge mode, routing consumes those components before
the runner performs its common lateral-flow sum. In local-inertial mode, the
runner first stores that sum as catchment lateral inflow, which the inertial
continuity calculation consumes.

Both routing methods place routed discharge in the shared river state used by
the output preparation. Their location in the complete calculation sequence is
documented under
[Model processes and numerical assumptions](model-processes.md).
