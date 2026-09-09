# Legacy header disposition ledger

This ledger audits every Fortran source file present on main at the start of
the language migration. Header material was reviewed item by item. Valid
license text is represented by the root GPL license and SPDX headers; authors
and contributors are represented in project-history.md; citations are
represented in references.md; and process, format, and numerical assumptions
are represented in model-processes.md and io-reference.md.

Repeated boilerplate was not copied into source comments. Dated modification
banners, manual call inventories, and comments that only restated code were
rejected as stale or maintenance noise. Disabled experimental branches and
claims about files not opened by the current executable were rejected as
non-authoritative.

| Legacy source at main | New source | Header disposition |
| --- | --- | --- |
| 1main.f90 | main.f90 | License, contributors, historical purpose, process notes, and citations moved to the project pages; obsolete version banner and duplicated call narrative rejected. |
| vars_main.f90 | model_state.f90 | State-variable meanings and units moved to the I/O/process pages; global declaration boilerplate retained only where local code needs it. |
| vars_inerc.f90 | inertial_state.f90 | Flood-routing state meanings and units moved to model-processes.md; repeated declaration descriptions rejected. |
| alloca_vars.f90 | allocate_model_state.f90 | Allocation purpose moved to model-process documentation; stale private-list and dated edit notes rejected. |
| alloca_varsinerc.f90 | allocate_inertial_state.f90 | Inertial table dimensions and ownership moved to model-processes.md; duplicate allocation comments rejected. |
| celula.f90 | update_catchment_water_balance.f90 | Vertical balance sequence, reservoirs, capillary flow, and units moved to model-processes.md; dated correction banners retained only as history in version control. |
| solo.f90 | update_soil_water_balance.f90 | ARNO infiltration and soil-balance assumptions moved to model-processes.md; comments that repeated formulas rejected. |
| evapo.f90 | calculate_evapotranspiration.f90 | ET components and water-availability limits moved to model-processes.md; repeated variable descriptions rejected. |
| radiacao.f90 | calculate_net_radiation.f90 | Radiation inputs, units, and monthly options moved to model-processes.md and io-reference.md; stale prose about unused data rejected. |
| condinic.f90 | initialize_model_state.f90 | Initial storage and routing-state assumptions moved to model-processes.md; duplicate initialization narration rejected. |
| simula.f90 | run_simulation.f90 | Startup order, input loading, and hotstart selection moved to io-reference.md; disabled experimental paths rejected. |
| modelo.f90 | run_model.f90 | Timestep execution order moved to model-processes.md; old call inventory and repeated loop comments rejected. |
| rede.f90 | route_muskingum_cunge_network.f90 | Network ordering and boundary assumptions moved to model-processes.md; duplicate topology prose rejected. |
| musk.f90 | route_muskingum_cunge.f90 | Reach subdivision and routing assumptions moved to model-processes.md; stale Portuguese warnings rejected. |
| parcel.f90 | calculate_catchment_parameters.f90 | Derived geometry and unit assumptions moved to io-reference.md; comments that restated assignments rejected. |
| parcunge.f90 | calculate_muskingum_cunge_parameters.f90 | Celerity and reach-parameter purpose moved to model-processes.md; duplicate formula comments rejected. |
| lecell.f90 | read_catchment_data.f90 | Catchment text layout and HRU ordering moved to io-reference.md; old filename notes migrated to migration.md. |
| leuso.f90 | read_calibrated_parameters.f90 | Calibration row layout and HRU naming moved to io-reference.md; stale calibration-tool references rejected. |
| levar.f90 | read_fixed_parameters.f90 | Vegetation and climate-region layouts moved to io-reference.md; duplicate format descriptions rejected. |
| lesubst.f90 | read_substitution_flows.f90 | Substitution-flow record order moved to io-reference.md; old extension references moved to migration.md. |
| le_reserv.f90 | read_reservoir_data.f90 | Reservoir configuration and outflow formats moved to io-reference.md; historical routine banner and unused-file claims rejected. |
| flood_readfp.f90 | read_floodplain_binary_data.f90 | Stage and area binary layout moved to io-reference.md; an inaccurate rainfall comment was rejected. |
| lefloodpln.f90 | read_floodplain_text_data.f90 | Text floodplain layout and inactive face path documented in io-reference.md; disabled-path commentary kept out of local code. |
| read_infomgb.f90 | read_model_configuration.f90 | Namelist groups, keys, and units moved to io-reference.md and migration.md; old interface text replaced by the canonical interface. |
| read_clim_avg.f90 | read_climatology.f90 | Monthly record order and precision moved to io-reference.md; duplicate file-open commentary rejected. |
| read_met.f90 | read_meteorological_forcing.f90 | Forcing flags, record order, and units moved to io-reference.md; old abbreviated labels moved to migration.md. |
| met_input_files.f90 | manage_meteorological_input_files.f90 | Canonical meteorological filenames and direct-access behavior moved to io-reference.md; legacy headers and date banners rejected. |
| write_output.f90 | write_model_outputs.f90 | Output mapping, record ordering, and units moved to io-reference.md; duplicate output flag comments rejected. |
| flood_topo.f90 | build_flood_topology.f90 | Upstream topology assumptions moved to model-processes.md; disabled pseudo-2D narrative rejected where not active. |
| flood_tab.f90 | build_floodplain_tables.f90 | Stage-area-volume construction moved to model-processes.md; repeated array descriptions rejected. |
| flood_timestep.f90 | calculate_inertial_timestep.f90 | CFL and internal-timestep assumptions moved to model-processes.md; formula-restating comments rejected. |
| flood_discharge.f90 | calculate_inertial_discharge.f90 | Inertial discharge and reservoir boundary behavior moved to model-processes.md; stale debugging notes rejected. |
| flood_continuity.f90 | update_inertial_continuity.f90 | Floodplain continuity terms and units moved to model-processes.md; duplicate equation comments rejected. |
| flood_inercial.f90 | route_inertial_flow.f90 | Internal substep execution order moved to model-processes.md; spelling/history notes rejected. |
| flood_ini.f90 | initialize_inertial_routing.f90 | Initial inertial state assumptions moved to model-processes.md; repeated initialization comments rejected. |
| flood_readhot.f90 | read_hotstart.f90 | Hotstart filenames, vector ordering, precision, and date convention moved to io-reference.md; old names moved to migration.md. |
| flood_writehot.f90 | write_hotstart.f90 | Hotstart write vector ordering and modes moved to io-reference.md; duplicate state labels rejected. |
| stagearea.f90 | interpolate_stage_area.f90 | Interpolation and upper-bound constant-area extrapolation moved to model-processes.md; formula-restating comments rejected. |
| fint.f90 | linear_interpolate.f90 | Generic interpolation purpose documented by the process page; source header was duplicate boilerplate. |
| semente.f90 | initialize_random_seed.f90 | Utility purpose required no unique scientific header item; license attribution is covered by SPDX and project history. |
| tempo.f90 | update_legacy_timer.f90 | Legacy timing utility retained without historical claims; old diagnostics were stale and rejected. |
| utils_date.f90 | utils_date.f90 | Date-string format and hotstart naming convention moved to io-reference.md; duplicate utility header rejected. |
| utils_time.f90 | utils_time.f90 | Julian-date and timestep assumptions moved to model-processes.md; repeated routine descriptions rejected. |

## Header items rejected globally

The audit found several categories that must not return to source headers:

- duplicate GPL paragraphs when the root license and SPDX identifier are
  present;
- stale file lists referring to interfaces no longer opened by the executable;
- disabled calibration, forecasting, assimilation, and pseudo-2D branches that
  are not part of the current CMake target;
- comments whose date, author, or version claim could not be reconciled with
  repository history; and
- output names or units contradicted by the active writer.

These rejections are deliberate dispositions, not missing documentation.
