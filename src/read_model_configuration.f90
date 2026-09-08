! SPDX-License-Identifier: GPL-3.0-or-later
! Copyright (C) 2019 Hidrologia de Grande Escala (HGE)

! Read infomgb.sim and populate internal model configuration.

    SUBROUTINE read_model_configuration

    USE model_state
    USE inertial_state
    use utils_time, only: calculate_julian_day, convert_julian_day_to_calendar, calculate_timestep_count
    use utils_date, only: parse_date_string

	IMPLICIT NONE

    !Variables for mgb_config_global

    INTEGER N_UNIT_CATCHM, N_HRUS
    INTEGER N_SUBASINS, N_CLI_REGIONS
    INTEGER HOTSTART_READ, HOTSTART_WRITE, SUBASIN_START, SUBASIN_END
    REAL(4) SIM_TIMESTEP
    INTEGER OPT_RES_SUB, N_RES_SUB
    character(len=40) :: SIM_START_DATE, SIM_END_DATE

    integer i_yr_end, i_mo_end, i_day_end, i_hr_end, i_min_end
    real(8) jday_end

    !Variables for mgb_forcing
    INTEGER TS_TEMP, TS_RAD, TS_RH, TS_WIND, TS_PRES
    INTEGER OPT_MONTH_RAD

    !Variables for mgb_routing
    INTEGER OPT_ROUTING, N_THREADS
    REAL IN_COURANT_ALPHA, IN_DOWN_SLOPE

    !Variables for writing output files
    INTEGER OUT_FLOW, OUT_SM, OUT_WSE, OUT_HAND, OUT_TWS, OUT_RUNOFF, OUT_SURFWAT
    INTEGER OUT_ET, OUT_ETINT, OUT_ETSOILVEG, OUT_ETOPENWAT, OUT_ETURHWAT, OUT_SSAT
    INTEGER OUT_VBAS, OUT_VINT, OUT_VSUP, OUT_VINTERC, OUT_FLAREA
    INTEGER OUT_DBAS, OUT_DINT, OUT_DSUP
    integer OUT_POTETWAT


    !Namelist definition - (MGB GENERAL CONFIG)
    namelist /mgb_config_global/     &

        & SIM_START_DATE,     &
        & SIM_END_DATE,       &
        & SIM_TIMESTEP,       &
        & HOTSTART_READ,      &
        & HOTSTART_WRITE,     &
        & SUBASIN_START,      &
        & SUBASIN_END,        &
        & N_UNIT_CATCHM,      &
        & N_HRUS,             &
        & N_SUBASINS,         &
        & N_CLI_REGIONS,      &
        & OPT_RES_SUB,        &
        & N_RES_SUB


    ! Opens input file contaning simulation setup parameters
	OPEN(config_unit,FILE=input_directory // 'infomgb.sim',STATUS='OLD',ACTION='READ')
    READ(config_unit, nml = mgb_config_global)

    model_timestep_seconds             = SIM_TIMESTEP
    catchment_count              = N_UNIT_CATCHM
    climate_cell_count            = catchment_count ! Temporary, all climate_cell_count must be changed to catchment_count
    hru_count              = N_HRUS
    subbasin_count              = N_SUBASINS
    climate_region_count            = N_CLI_REGIONS
    reservoir_substitution_enabled    = OPT_RES_SUB
    read_hotstart_mode    = HOTSTART_READ
    write_hotstart_mode   = HOTSTART_WRITE
    reservoir_count            = N_RES_SUB
    first_subbasin          = SUBASIN_START
    last_subbasin          = SUBASIN_END

     ! Parse start and end simulation dates from strings
    CALL parse_date_string(SIM_START_DATE,year,month,day,hour,minute)
    CALL parse_date_string(SIM_END_DATE,i_yr_end,i_mo_end,i_day_end,i_hr_end,i_min_end)

    ! Compute number of time steps using start/end julian day and hour
    julian_day     = calculate_julian_day(year,month,day,hour,minute)
    jday_end = calculate_julian_day(i_yr_end, i_mo_end, i_day_end, i_hr_end, i_min_end)
    timestep_count =       calculate_timestep_count(jday_end, julian_day, real(model_timestep_seconds,8)) + 1

    !Namelist definition - (MGB met CONFIG)
    namelist /mgb_config_forcing/     &

        & TS_TEMP,          &
        & TS_RAD,           &
        & TS_RH,            &
        & TS_WIND,          &
        & TS_PRES,          &
        & OPT_MONTH_RAD

    ! Reads input file contaning simulation setup parameters
    READ(config_unit, nml = mgb_config_forcing)

    use_temperature_timeseries    = TS_TEMP
    use_radiation_timeseries     = TS_RAD
    use_humidity_timeseries      = TS_RH
    use_wind_timeseries    = TS_WIND
    use_pressure_timeseries    = TS_PRES
    monthly_radiation_option       = OPT_MONTH_RAD

    !Namelist definition - (ROUTING)
    namelist /mgb_config_routing/   &

        & OPT_ROUTING,           &
        & IN_DOWN_SLOPE,         &
        & IN_COURANT_ALPHA,      &
        & N_THREADS

    !Manual setup for disabled options (Pseudo2D configuration)
    pseudo_two_d_enabled = 0
    overland_flow_width    = 10.0
    overland_manning_n     = 0.1

    ! Reads input file contaning simulation setup parameters
    READ(config_unit, nml = mgb_config_routing)

    !Reads routing parameters
    courant_alpha           = IN_COURANT_ALPHA
    inertial_routing_enabled   = OPT_ROUTING
    thread_count    = N_THREADS
    downstream_water_surface_slope         = IN_DOWN_SLOPE
    downstream_water_surface_slope         = downstream_water_surface_slope*0.001 !converting from m/km to m/m


    !Namelist definition - (output variables)
    namelist /mgb_config_output/     &

        & OUT_FLOW,        &
        & OUT_WSE,         &
        & OUT_HAND,        &
        & OUT_RUNOFF,      &
        & OUT_SM,          &
        & OUT_SSAT,        &
        & OUT_TWS,         &
        & OUT_SURFWAT,     &
        & OUT_ET,          &
        & OUT_ETINT,       &
        & OUT_ETSOILVEG,   &
        & OUT_ETOPENWAT,   &
        & OUT_ETURHWAT,    &
        & OUT_POTETWAT,    &
        & OUT_VBAS,        &
        & OUT_VINT,        &
        & OUT_VSUP,        &
        & OUT_DBAS,        &
        & OUT_DINT,        &
        & OUT_DSUP,        &
        & OUT_VINTERC,     &
        & OUT_FLAREA

    ! Reads input file contaning output variables parameters
    READ(config_unit, nml = mgb_config_output)

    write_discharge_output       = OUT_FLOW
    write_water_surface_elevation_output        = OUT_WSE
    write_hand_output       = OUT_HAND
    write_runoff_output     = OUT_RUNOFF
    write_soil_moisture_output         = OUT_SM
    write_soil_saturation_output      = OUT_SSAT
    write_total_water_storage_output        = OUT_TWS
    write_surface_water_output    = OUT_SURFWAT
    write_et_output         = OUT_ET
    write_interception_et_output      = OUT_ETINT
    write_soil_vegetation_et_output  = OUT_ETSOILVEG
    write_open_water_et_output  = OUT_ETOPENWAT
    write_water_hru_et_output   = OUT_ETURHWAT
    write_potential_open_water_et_output   = OUT_POTETWAT
    write_groundwater_storage_output       = OUT_VBAS
    write_subsurface_storage_output       = OUT_VINT
    write_surface_storage_output       = OUT_VSUP
    write_interception_storage_output    = OUT_VINTERC
    write_groundwater_flux_output       = OUT_DBAS
    write_subsurface_flux_output       = OUT_DINT
    write_surface_flux_output       = OUT_DSUP
    write_flooded_area_output     = OUT_FLAREA

	CLOSE (config_unit)

	RETURN
	END
