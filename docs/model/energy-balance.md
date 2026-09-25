# Energy balance and evapotranspiration

MGB calculates radiation and evaporative demand separately for every active
HRU in every catchment. The same meteorological forcing is used by all HRUs in
a catchment, while monthly vegetation parameters vary by HRU and climate
region. The equations below describe the current `catchment` implementation;
their scientific background follows Shuttleworth (1993) and Wigmosta et al.
(1994), as cited in [References](references.md).

Unless stated otherwise, radiation is in $\mathrm{MJ\,m^{-2}\,day^{-1}}$,
water depths are in millimetres per model timestep, temperature is in degrees
Celsius, vapor pressure is in kilopascals, and resistance is in
$\mathrm{s\,m^{-1}}$.

## Vapor pressure and latent heat

For air temperature $T$, relative humidity $RH$, and air pressure $P_a$, the
latent heat of vaporization and the saturation and actual vapor pressures are

$$
\lambda = 2.501 - 0.002361T,
$$

$$
e_s = 0.6108\exp\left(\frac{17.27T}{237.3+T}\right),
\qquad
e_a = e_s\frac{RH}{100}.
$$

Here $\lambda$ is in $\mathrm{MJ\,kg^{-1}}$. The vapor-pressure deficit used
by Penman-Monteith is $e_d=e_s-e_a$. The slope of the saturation-vapor-pressure
curve, psychrometric constant, and air density are

$$
\Delta = \frac{4098e_s}{(237.3+T)^2},
\qquad
\gamma = \frac{0.0016286P_a}{\lambda},
\qquad
\rho_a = \frac{3.486P_a}{275+T}.
$$

$\Delta$ and $\gamma$ are in $\mathrm{kPa\,^{\circ}C^{-1}}$, while
$\rho_a$ is in $\mathrm{kg\,m^{-3}}$.

## Solar geometry

The calculation uses the integer day of year $d$ and catchment latitude
$\varphi$. Latitude is stored in degrees; the trigonometric operations shown
with $\varphi$ therefore use degrees, while solar declination and sunset angle
are in radians.

Solar declination $\delta$, sunset hour angle $\omega_s$, maximum sunshine
duration $N$, and the dimensionless Earth-Sun distance factor $d_r$ are

$$
\delta = 0.4093\sin\left(\frac{2\pi d}{365}-1.405\right),
$$

$$
\omega_s = \arccos\left[-\tan(\varphi)\tan(\delta)\right],
\qquad
N = \frac{24\omega_s}{\pi},
$$

$$
d_r = 1+0.033\cos\left(\frac{2\pi d}{365}\right).
$$

Here $d$ is dimensionless, $N$ is in hours, and the source uses
$\pi=3.141592$. The current implementation calculates top-of-atmosphere
radiation as

$$
R_a = 15.392\frac{\rho_w\lambda}{1000}d_r
\left[
\omega_s\sin(\varphi)\sin(\delta)
+\cos(\varphi)\cos(\delta)\sin(\omega_s)
\right],
$$

where $\rho_w=1000\ \mathrm{kg\,m^{-3}}$. The numerical factors and the use
of the temperature-dependent $\lambda$ are retained from the executable.

## Incoming and net radiation

The shortwave radiation supplied to the surface, $R_s$, depends on the forcing
configuration. A direct radiation series is used without conversion. With
monthly climatology, the `monthly_radiation_option` selects

$$
R_s = R_a\left(0.25+0.50\frac{n}{N}\right)
\quad\text{for sunshine hours }n,
$$

$$
R_s = R_a\left(0.25+0.50\frac{p_s}{100}\right)
\quad\text{for sunshine percentage }p_s,
$$

or accepts the climatological value directly as radiation. The
[I/O reference](../architecture/io-reference.md) lists the forcing flags and record layouts.

For HRU albedo $\alpha$, net shortwave radiation is

$$
R_{ns}=R_s(1-\alpha).
$$

The emitted net longwave term is

$$
R_l = \sigma(T+273.2)^4
\left(0.34-0.14\sqrt{e_a}\right)\frac{R_s}{R_a},
$$

where $\sigma=4.903\times10^{-9}\ \mathrm{MJ\,m^{-2}\,day^{-1}\,K^{-4}}$.
The ground heat flux is calculated from the change from the preceding air
temperature $T_{-1}$:

$$
G=0.38(T-T_{-1}).
$$

The net energy available to the evapotranspiration calculation is therefore

$$
R_n=R_{ns}-R_l-G.
$$

Before Penman-Monteith is evaluated, $R_n$ is divided by 86,400 to express it
as a per-second flux. No replacement constants, cloud correction, or clipping
of these radiation terms should be inferred from the theoretical form.

## Aerodynamic resistance

The model derives separate aerodynamic resistances for vegetation and open
water. Let $z_v$ be vegetation height in metres and $u$ the supplied wind
speed in $\mathrm{m\,s^{-1}}$. The current calculation uses

$$
z_0=0.1z_v,
\qquad
u_{10}=u+0.1,
\qquad
u_2=u_{10}\frac{\ln(2/z_0)}{\ln(10/z_0)}.
$$

With $z=\min(z_v,12.5)$, vegetation resistance is

$$
r_a=
\frac{
\ln\left(\frac{10-0.67z}{0.123z}\right)
\ln\left(\frac{10-0.67z}{0.0123z}\right)
}{0.41^2u_{10}},
$$

and open-water aerodynamic resistance is

$$
r_{aw}=\frac{4.72[\ln(2/0.00137)]^2}{1+0.536u_2}.
$$

$z_0$ and $z$ are in metres, $u_{10}$ and $u_2$ are in
$\mathrm{m\,s^{-1}}$, and both resistances are in $\mathrm{s\,m^{-1}}$.

These empirical expressions are implementation details. In particular, the
$0.1\ \mathrm{m\,s^{-1}}$ wind offset and the vegetation-height cap are part
of current numerical behavior.

## Soil-moisture control of surface resistance

The monthly HRU value read from `vegetation.par` is multiplied by 1.5 during
input preparation. Call the resulting minimum resistance $r_{s,\min}$. With
soil storage $W$ and maximum storage $W_m$, the current thresholds are

$$
W_w=0.1W_m,
\qquad
W_u=0.8W_m.
$$

For $W_w<W<W_u$, the moisture multiplier is
$f_r=(W_u-W_w)/(W-W_w)$; for $W\geq W_u$, $f_r=1$. Those branches produce
$r_s=f_rr_{s,\min}$.

The dry branch has an additional retained-state detail in the current source.
The multiplier is stored across HRU calls and is not reassigned when
$W\leq W_w$. If $f_{r,prev}$ is the most recently assigned multiplier, the
literal implemented relationship is

$$
r_s=
\begin{cases}
0, & W_m<0.1,\\
\left(999999999\ \mathrm{s\,m^{-1}}\right)f_{r,prev},
& W_m\geq0.1\text{ and }W\leq W_w,\\
r_{s,\min}\dfrac{W_u-W_w}{W-W_w}, & W_w<W<W_u,\\
r_{s,\min}, & W\geq W_u.
\end{cases}
$$

The retained multiplier is initialized to zero. This cross-HRU carry-over is
an implementation behavior, not part of the conceptual Penman-Monteith
formulation. An open-water HRU is identified by $W_m<0.1\ \mathrm{mm}$ in
this calculation and uses $r_s=0$ without that multiplier.

The executable uses $0.8W_m$ as the upper soil-moisture threshold.

## Penman-Monteith demand

For aerodynamic resistance $r$, surface resistance $r_s$, specific heat of
air $c_p=0.001013\ \mathrm{MJ\,kg^{-1}\,^{\circ}C^{-1}}$, and model timestep
$\Delta t$ in seconds, the calculated evaporation depth is

$$
E(r,r_s)=
\frac{
\Delta R_n+\rho_a c_p e_d/r
}{
\Delta+\gamma(1+r_s/r)
}
\frac{1000\Delta t}{\lambda\rho_w}.
$$

The model evaluates this expression with $r=r_a$ for vegetation and with
$r=r_{aw}$ for open water. Interception demand also uses $r_a$ but sets
$r_s=0$.

## Interception and demand partitioning

Let $S_i$ be intercepted-water storage, $P$ precipitation for the timestep,
and $LAI$ the monthly leaf-area index. The maximum interception storage in the
current executable is

$$
S_{i,\max}=0.4LAI\frac{\Delta t}{86400}.
$$

The store fills before water reaches the soil:

$$
S_{i,a}=\min(S_i+P,S_{i,\max}),
\qquad
P_e=P-(S_{i,a}-S_i),
$$

where $P_e$ is precipitation remaining after interception. Potential and
actual interception evaporation are

$$
E_{i,p}=E(r_a,0),
\qquad
E_i=\min(E_{i,p},S_{i,a}),
$$

and the retained storage becomes $S_i'=S_{i,a}-E_i$.

Interception evaporation consumes energy before soil and vegetation
evapotranspiration. The remaining demand fraction is

$$
f_E=\frac{E_{i,p}-E_i}{E_{i,p}},
$$

so actual soil and vegetation demand passed to the water balance is

$$
E_s=f_E E(r_a,r_s).
$$

This ordering is important: interception is filled and evaporated before the
soil-water update for the same HRU. The treatment of flooded terrestrial area
and the limits applied when soil water is insufficient are described in
[Soil and catchment processes](soil-and-catchment-processes.md).

## Open-water evaporation

Potential open-water evaporation is $E_w=E(r_{aw},0)$. In
Muskingum-Cunge mode it is converted to discharge for the portion of a
catchment classified as a water HRU and removed at the routing boundary. In
local-inertial mode it is retained as a depth and applied over the dynamically
flooded area inside the river-volume continuity equation.

The catchment-level $E_w$ used by local-inertial routing is overwritten during
the HRU loop and therefore retains the value calculated for the last active
HRU. Because $u_2$ is derived using that HRU's vegetation roughness $z_0$,
HRU ordering is part of this open-water evaporation behavior in the current
source.
