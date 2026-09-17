# Muskingum-Cunge routing

Muskingum-Cunge is the hydrological routing option used when `routing_mode=0`.
It propagates terrestrial inflow through a sequence of river subreaches. The
[River routing overview](river-routing.md) describes the common network context
and reference discharge used by both routing methods.

For one routing reach, downstream discharge at routing substep $n+1$ is

$$
Q_{out}^{n+1}=C_1Q_{in}^{n}+C_2Q_{in}^{n+1}+C_3Q_{out}^{n}.
$$

For reach travel time $K$, weighting parameter $X$, and routing timestep
$\Delta t_r$, the coefficients are

$$
C_1=\frac{2KX+\Delta t_r}{2K(1-X)+\Delta t_r},
$$

$$
C_2=\frac{\Delta t_r-2KX}{2K(1-X)+\Delta t_r},
$$

$$
C_3=\frac{2K(1-X)-\Delta t_r}{2K(1-X)+\Delta t_r}.
$$

The upstream boundary is interpolated between the preceding and current
catchment inflows over the substeps. Open-water evaporation associated with a
water HRU is removed there, and each calculated discharge is limited to be
nonnegative.

## Celerity and reach parameters

For channel slope $S_0$ in metres per metre, Manning roughness $n$, width $B$
in metres, and reference discharge $Q_0$, the current kinematic celerity is

$$
c_0=\frac{1.67S_0^{0.3}}{n^{0.6}}
\left(\frac{Q_0}{B}\right)^{0.4}.
$$

Each meteorological timestep is divided into 24 Muskingum routing substeps:

$$
\Delta t_r=\frac{\Delta t_{model}}{24}.
$$

This gives hourly routing for a daily model timestep. The implemented rule
always divides by 24; it does not use a fixed one-hour interval for other model
timestep lengths.

The target subreach length is

$$
\Delta x_{ideal}=\frac{c_0\Delta t_r}{2}
\left[1+\sqrt{1+\frac{1.5(Q_0/B)}{c_0^2S_0\Delta t_r}}\right].
$$

For total catchment river length $L$, the number of subreaches is the nearest
integer to $L/\Delta x_{ideal}$, with a minimum of one. The actual length is
$\Delta x=L/N$, subject to the compiled maximum reach count. This nearest-
integer rule and the compiled maximum reach count are applied by the
executable.

The initial reach parameters are

$$
K=\frac{\Delta x}{c_0},
\qquad
X=\frac{1}{2}\left(1-\frac{Q_0}{BS_0c_0\Delta x}\right).
$$

The executable enforces $0.2\leq X\leq0.5$. When $X<0.2$, it sets $X=0.2$
and replaces the travel time with

$$
K=\frac{\Delta t_r}{3.125X^{1.25}}.
$$

When $X\geq0.5$, it sets $X=0.5$ and $K=\Delta t_r$. Catchments whose network
order does not exceed one are not subdivided and pass their accumulated flow
directly downstream.

## Initial state

Muskingum-Cunge reach states are initialized from the terrestrial baseflow
propagated through the network. A requested hotstart is loaded after this
initializer and replaces the routing state.
