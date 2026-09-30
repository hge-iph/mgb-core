# Legacy source files and modules

The table covers every Fortran source file under `src/` at the legacy baseline
[`41146b1`](https://github.com/HGE-IPH/MGB-model/commit/41146b1). The current
owner is the primary implementation location; some responsibilities span
multiple modules after the refactor.

| Legacy file | Current file or owner | Responsibility | Disposition |
| --- | --- | --- | --- |
| `1main.f90` | `simulation/main.f90`, `io/log_io.f90` | Program startup, top-level lifecycle, and log setup | Split between application control and log I/O |
| `alloca_vars.f90` | `vars/attributes.f90`, `vars/config.f90`, `vars/forcing.f90`, `vars/parameters.f90`, `vars/state.f90`; `simulation/main.f90` | Allocation and release of shared model data | Split by namespace and lifecycle |
| `alloca_varsinerc.f90` | `vars/attributes.f90`, `vars/config.f90`, `vars/parameters.f90`, `vars/state.f90`; `simulation/main.f90` | Allocation and release of inertial-routing data | Split by namespace |
| `celula.f90` | `hydrology/catchment.f90` | Catchment and HRU water balance | Consolidated into catchment procedures |
| `condinic.f90` | `hydrology/catchment.f90` | Initial water-balance conditions | Absorbed into catchment initialization |
| `evapo.f90` | `hydrology/catchment.f90` | Evapotranspiration demand and partitioning | Absorbed into catchment calculations |
| `fint.f90` | `common/interpolation.f90` | Linear interpolation | Renamed and moved |
| `flood_continuity.f90` | `hydrology/river_inertial.f90` | Local-inertial continuity update | Consolidated in inertial routing |
| `flood_discharge.f90` | `hydrology/river_inertial.f90` | Local-inertial discharge calculation | Consolidated in inertial routing |
| `flood_inercial.f90` | `hydrology/river_inertial.f90` | Inertial-routing timestep orchestration | Renamed and consolidated |
| `flood_ini.f90` | `hydrology/river_inertial.f90` | Inertial-routing initialization | Consolidated in inertial routing |
| `flood_readfp.f90` | `io/static_input_io.f90` | Floodplain binary and connection inputs | Moved to static I/O |
| `flood_readhot.f90` | `io/hotstart_io.f90` | Hotstart state reads | Consolidated in hotstart I/O |
| `flood_tab.f90` | `hydrology/river_inertial.f90` | Floodplain stage, area, and volume tables | Consolidated in inertial routing |
| `flood_timestep.f90` | `hydrology/river_inertial.f90` | Inertial substep selection | Consolidated in inertial routing |
| `flood_topo.f90` | `hydrology/river_inertial.f90` | Upstream topology construction | Consolidated in inertial routing |
| `flood_writehot.f90` | `io/hotstart_io.f90` | Hotstart state writes | Consolidated in hotstart I/O |
| `le_reserv.f90` | `io/reservoir_io.f90`, `hydrology/reservoirs.f90` | Reservoir data and initialization | Split between I/O and hydrology |
| `lecell.f90` | `io/static_input_io.f90` | Catchment geometry, network, and HRU fractions | Moved to static I/O |
| `lefloodpln.f90` | `io/static_input_io.f90` | Floodplain stage-area and face-connection text | Moved to static I/O |
| `lesubst.f90` | `io/reservoir_io.f90` | Substitution-flow input | Moved to reservoir I/O |
| `leuso.f90` | `io/static_input_io.f90` | Calibrated soil and routing parameters | Moved to static I/O |
| `levar.f90` | `io/static_input_io.f90` | Vegetation parameters and climate-region assignments | Moved to static I/O |
| `met_input_files.f90` | `io/meteorological_io.f90` | Open and close meteorological streams | Consolidated in meteorological I/O |
| `modelo.f90` | `simulation/runner.f90` | Timestep loop and per-step process order | Reorganized into runner procedures |
| `musk.f90` | `hydrology/river_muskingum.f90` | Muskingum-Cunge reach routing kernel | Consolidated and renamed |
| `parcel.f90` | `hydrology/catchment.f90`, `hydrology/river_muskingum.f90` | Catchment and river parameter preparation | Split by responsibility |
| `parcunge.f90` | `hydrology/river_muskingum.f90` | Muskingum-Cunge routing parameters | Consolidated in routing module |
| `radiacao.f90` | `hydrology/catchment.f90` | Net radiation calculations | Absorbed into catchment energy calculations |
| `read_clim_avg.f90` | `io/meteorological_io.f90` | Monthly climatology input | Moved to meteorological I/O |
| `read_infomgb.f90` | `io/configuration_io.f90` | Runtime namelist configuration | Moved and renamed |
| `read_met.f90` | `io/meteorological_io.f90` | Meteorological forcing records | Moved to meteorological I/O |
| `rede.f90` | `hydrology/river_muskingum.f90` | Network routing and substitution-flow handoff | Consolidated in Muskingum-Cunge routing |
| `semente.f90` | `common/runtime_support.f90` | Random-seed initialization | Moved and renamed |
| `simula.f90` | `simulation/runner.f90` | Run preparation, initialization, and execution | Reorganized into lifecycle procedures |
| `solo.f90` | `hydrology/catchment.f90` | Soil-water balance | Absorbed into catchment calculations |
| `stagearea.f90` | `hydrology/river_inertial.f90` | Stage-area interpolation | Moved into inertial routing |
| `tempo.f90` | `simulation/main.f90`, `common/runtime_support.f90` | Elapsed-time reporting | Split between application timing and support |
| `utils_date.f90` | `common/date_time.f90` | Date parsing and formatting | Consolidated and renamed |
| `utils_time.f90` | `common/date_time.f90` | Julian-day and timestep calculations | Consolidated and renamed |
| `vars_inerc.f90` | `vars/attributes.f90`, `vars/config.f90`, `vars/parameters.f90`, `vars/state.f90` | Inertial-routing shared data | Split by data ownership |
| `vars_main.f90` | All five `vars/*.f90` modules | General shared configuration, forcing, parameters, attributes, and state | Split by responsibility |
| `write_output.f90` | `io/output_io.f90` | Model output streams | Moved and split into focused procedures |

The current module boundaries and allowed dependencies are described in
[components and dependencies](../architecture/components-and-dependencies.md).
