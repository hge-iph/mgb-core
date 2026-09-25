module configuration_io

    implicit none
    private
    public :: read_model_configuration

contains

    subroutine read_model_configuration
        use date_time, only: &
            & calculate_julian_day, &
            & calculate_timestep_count, &
            & convert_julian_day_to_calendar, &
            & parse_date_string
        use state, only: &
            & day, &
            & hour, &
            & julian_day, &
            & minute, &
            & month, &
            & year
        use config, only: &
            & catchment_count, &
            & climate_region_count, &
            & io_unit_config, &
            & downstream_water_surface_slope, &
            & first_subbasin, &
            & hru_count, &
            & input_directory, &
            & last_subbasin, &
            & model_timestep, &
            & monthly_radiation_option, &
            & overland_flow_width, &
            & overland_manning_n, &
            & pseudo_2d_enabled, &
            & reservoir_count, &
            & reservoir_substitution_enabled, &
            & routing_mode, &
            & subbasin_count, &
            & thread_count, &
            & timestep_count, &
            & courant_alpha, &
            & use_humidity_timeseries, &
            & use_pressure_timeseries, &
            & use_radiation_timeseries, &
            & use_temperature_timeseries, &
            & use_wind_timeseries, &
            & hotstart_read_mode, &
            & hotstart_write_mode, &
            & write_discharge, &
            & write_evapotranspiration, &
            & write_flooded_area, &
            & write_groundwater_flux, &
            & write_groundwater_storage, &
            & write_flooded_level, &
            & write_interception_evaporation, &
            & write_interception_storage, &
            & write_open_water_evaporation, &
            & write_potential_open_water_evaporation, &
            & write_runoff, &
            & write_soil_water, &
            & write_soil_saturation, &
            & write_soil_vegetation_evapotranspiration, &
            & write_subsurface_flux, &
            & write_subsurface_storage, &
            & write_surface_flux, &
            & write_surface_storage, &
            & write_surface_water, &
            & write_total_water_storage, &
            & write_water_hru_evaporation, &
            & write_water_surface_elevation

        implicit none

        ! Meteorological forcing timestep in seconds.
        character(len=40) :: simulation_start
        character(len=40) :: simulation_end

        integer :: i_yr_end
        integer :: i_mo_end
        integer :: i_day_end
        integer :: i_hr_end
        integer :: i_min_end
        real(8) jday_end

        real :: downstream_boundary_slope
        ! Downstream boundary slope in metres per kilometre.

        ! Output controls are imported from config and used directly by the namelist.

        namelist /model/ simulation_start, simulation_end, model_timestep, hotstart_read_mode, &
            & hotstart_write_mode, first_subbasin, last_subbasin, catchment_count, hru_count, &
            & subbasin_count, climate_region_count, reservoir_substitution_enabled, reservoir_count

        namelist /forcing/ use_temperature_timeseries, use_radiation_timeseries, &
            & use_humidity_timeseries, use_wind_timeseries, use_pressure_timeseries, &
            & monthly_radiation_option

        namelist /routing/ routing_mode, thread_count, downstream_boundary_slope, courant_alpha

        namelist /output/ write_discharge, write_water_surface_elevation, write_flooded_level, &
            & write_runoff, write_soil_water, write_soil_saturation, write_total_water_storage, &
            & write_surface_water, write_evapotranspiration, write_interception_evaporation, &
            & write_soil_vegetation_evapotranspiration, write_open_water_evaporation, &
            & write_water_hru_evaporation, write_potential_open_water_evaporation, &
            & write_groundwater_storage, write_subsurface_storage, write_surface_storage, &
            & write_interception_storage, write_groundwater_flux, write_subsurface_flux, &
            & write_surface_flux, write_flooded_area

        open (io_unit_config, file=input_directory//'config.nml', status='old', action='read')
        read (io_unit_config, nml=model)

        ! Parse start and end simulation dates from strings
        call parse_date_string( &
            & simulation_start, &
            & year, &
            & month, &
            & day, &
            & hour, &
            & minute)
        call parse_date_string( &
            & simulation_end, &
            & i_yr_end, &
            & i_mo_end, &
            & i_day_end, &
            & i_hr_end, &
            & i_min_end)

        ! Compute number of time steps using start/end julian day and hour
        julian_day = calculate_julian_day(year, month, day, hour, minute)
        jday_end = calculate_julian_day(i_yr_end, i_mo_end, i_day_end, i_hr_end, i_min_end)
        timestep_count = calculate_timestep_count(jday_end, julian_day, real(model_timestep, 8)) + 1

        read (io_unit_config, nml=forcing)

        ! Pseudo-2D routing remains disabled by the current runtime interface.
        pseudo_2d_enabled = 0
        overland_flow_width = 10.0
        overland_manning_n = 0.1

        read (io_unit_config, nml=routing)

        downstream_water_surface_slope = downstream_boundary_slope
        downstream_water_surface_slope = downstream_water_surface_slope*0.001

        read (io_unit_config, nml=output)

        close (io_unit_config)

        return
    end

end module configuration_io
