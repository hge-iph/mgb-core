# Legacy source files and modules

The table covers every Fortran source file under `src/` at the legacy baseline
[`41146b1`](https://github.com/HGE-IPH/MGB-model/commit/41146b1). The current
owner is the primary implementation location; some responsibilities span
multiple modules after the refactor.

| Legacy file | Current file or owner | Responsibility and disposition |
| --- | --- | --- |
| `1main.f90` | `simulation/main.f90`<br>`io/log_io.f90` | Program startup, top-level lifecycle, and log setup<br><br>Split between application control and log I/O |
| `alloca_vars.f90` | `vars/attributes.f90`<br>`vars/config.f90`<br>`vars/forcing.f90`<br>`vars/parameters.f90`<br>`vars/state.f90`<br>`simulation/main.f90` | Allocation and release of shared model data<br><br>Split by namespace and lifecycle |
| `alloca_varsinerc.f90` | `vars/attributes.f90`<br>`vars/config.f90`<br>`vars/parameters.f90`<br>`vars/state.f90`<br>`simulation/main.f90` | Allocation and release of inertial-routing data<br><br>Split by namespace |
| `celula.f90` | `hydrology/catchment.f90` | Catchment and HRU water balance<br><br>Consolidated into catchment procedures |
| `condinic.f90` | `hydrology/catchment.f90` | Initial water-balance conditions<br><br>Absorbed into catchment initialization |
| `evapo.f90` | `hydrology/catchment.f90` | Evapotranspiration demand and partitioning<br><br>Absorbed into catchment calculations |
| `fint.f90` | `common/interpolation.f90` | Linear interpolation<br><br>Renamed and moved |
| `flood_continuity.f90` | `hydrology/river_inertial.f90` | Local-inertial continuity update<br><br>Consolidated in inertial routing |
| `flood_discharge.f90` | `hydrology/river_inertial.f90` | Local-inertial discharge calculation<br><br>Consolidated in inertial routing |
| `flood_inercial.f90` | `hydrology/river_inertial.f90` | Inertial-routing timestep orchestration<br><br>Renamed and consolidated |
| `flood_ini.f90` | `hydrology/river_inertial.f90` | Inertial-routing initialization<br><br>Consolidated in inertial routing |
| `flood_readfp.f90` | `io/static_input_io.f90` | Floodplain binary and connection inputs<br><br>Moved to static I/O |
| `flood_readhot.f90` | `io/hotstart_io.f90` | Hotstart state reads<br><br>Consolidated in hotstart I/O |
| `flood_tab.f90` | `hydrology/river_inertial.f90` | Floodplain stage, area, and volume tables<br><br>Consolidated in inertial routing |
| `flood_timestep.f90` | `hydrology/river_inertial.f90` | Inertial substep selection<br><br>Consolidated in inertial routing |
| `flood_topo.f90` | `hydrology/river_inertial.f90` | Upstream topology construction<br><br>Consolidated in inertial routing |
| `flood_writehot.f90` | `io/hotstart_io.f90` | Hotstart state writes<br><br>Consolidated in hotstart I/O |
| `le_reserv.f90` | `io/reservoir_io.f90`<br>`hydrology/reservoirs.f90` | Reservoir data and initialization<br><br>Split between I/O and hydrology |
| `lecell.f90` | `io/static_input_io.f90` | Catchment geometry, network, and HRU fractions<br><br>Moved to static I/O |
| `lefloodpln.f90` | `io/static_input_io.f90` | Floodplain stage-area and face-connection text<br><br>Moved to static I/O |
| `lesubst.f90` | `io/reservoir_io.f90` | Substitution-flow input<br><br>Moved to reservoir I/O |
| `leuso.f90` | `io/static_input_io.f90` | Calibrated soil and routing parameters<br><br>Moved to static I/O |
| `levar.f90` | `io/static_input_io.f90` | Vegetation parameters and climate-region assignments<br><br>Moved to static I/O |
| `met_input_files.f90` | `io/meteorological_io.f90` | Open and close meteorological streams<br><br>Consolidated in meteorological I/O |
| `modelo.f90` | `simulation/runner.f90` | Timestep loop and per-step process order<br><br>Reorganized into runner procedures |
| `musk.f90` | `hydrology/river_muskingum.f90` | Muskingum-Cunge reach routing kernel<br><br>Consolidated and renamed |
| `parcel.f90` | `hydrology/catchment.f90`<br>`hydrology/river_muskingum.f90` | Catchment and river parameter preparation<br><br>Split by responsibility |
| `parcunge.f90` | `hydrology/river_muskingum.f90` | Muskingum-Cunge routing parameters<br><br>Consolidated in routing module |
| `radiacao.f90` | `hydrology/catchment.f90` | Net radiation calculations<br><br>Absorbed into catchment energy calculations |
| `read_clim_avg.f90` | `io/meteorological_io.f90` | Monthly climatology input<br><br>Moved to meteorological I/O |
| `read_infomgb.f90` | `io/configuration_io.f90` | Runtime namelist configuration<br><br>Moved and renamed |
| `read_met.f90` | `io/meteorological_io.f90` | Meteorological forcing records<br><br>Moved to meteorological I/O |
| `rede.f90` | `hydrology/river_muskingum.f90` | Network routing and substitution-flow handoff<br><br>Consolidated in Muskingum-Cunge routing |
| `semente.f90` | `common/runtime_support.f90` | Random-seed initialization<br><br>Moved and renamed |
| `simula.f90` | `simulation/runner.f90` | Run preparation, initialization, and execution<br><br>Reorganized into lifecycle procedures |
| `solo.f90` | `hydrology/catchment.f90` | Soil-water balance<br><br>Absorbed into catchment calculations |
| `stagearea.f90` | `hydrology/river_inertial.f90` | Stage-area interpolation<br><br>Moved into inertial routing |
| `tempo.f90` | `simulation/main.f90`<br>`common/runtime_support.f90` | Elapsed-time reporting<br><br>Split between application timing and support |
| `utils_date.f90` | `common/date_time.f90` | Date parsing and formatting<br><br>Consolidated and renamed |
| `utils_time.f90` | `common/date_time.f90` | Julian-day and timestep calculations<br><br>Consolidated and renamed |
| `vars_inerc.f90` | `vars/attributes.f90`<br>`vars/config.f90`<br>`vars/parameters.f90`<br>`vars/state.f90` | Inertial-routing shared data<br><br>Split by data ownership |
| `vars_main.f90` | `vars/attributes.f90`<br>`vars/config.f90`<br>`vars/forcing.f90`<br>`vars/parameters.f90`<br>`vars/state.f90` | General shared configuration, forcing, parameters, attributes, and state<br><br>Split by responsibility |
| `write_output.f90` | `io/output_io.f90` | Model output streams<br><br>Moved and split into focused procedures |

The current module boundaries and allowed dependencies are described in
[components and dependencies](../architecture/components-and-dependencies.md).
