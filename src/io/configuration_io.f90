module configuration_io

    implicit none
    private
    public :: read_model_configuration

contains

    subroutine read_model_configuration
        use date_time, only: calculate_julian_day, calculate_timestep_count, &
                             convert_julian_day_to_calendar, parse_date_string
        use simulation_state, only: day, first_subbasin_state => first_subbasin, hour, &
                                    julian_day, last_subbasin_state => last_subbasin, minute, &
                                 model_timestep_state => model_timestep, month, timestep_count, year
        use runoff_state, only: catchment_count_state => catchment_count, &
                                hru_count_state => hru_count, subbasin_count_state => subbasin_count
        use evapotranspiration_state, only: climate_cell_count_state => climate_cell_count, &
                                            climate_region_count_state => climate_region_count, &
                                       monthly_radiation_option_state => monthly_radiation_option, &
                                         use_humidity_timeseries_state => use_humidity_timeseries, &
                                         use_pressure_timeseries_state => use_pressure_timeseries, &
                                       use_radiation_timeseries_state => use_radiation_timeseries, &
                                   use_temperature_timeseries_state => use_temperature_timeseries, &
                                            use_wind_timeseries_state => use_wind_timeseries
        use reservoir_state, only: reservoir_count_state => reservoir_count, &
                              reservoir_substitution_enabled_state => reservoir_substitution_enabled
        use inertial_state, only: downstream_water_surface_slope, inertial_routing_enabled, &
                                  overland_flow_width, overland_manning_n, pseudo_two_d_enabled, &
                            courant_alpha_state => courant_alpha, thread_count_state => thread_count
        use io_state, only: config_unit, input_directory
        use output_state, only: hotstart_read_mode_state => read_hotstart_mode, &
                         hotstart_write_mode_state => write_hotstart_mode, write_discharge_output, &
                                write_et_output, &
                                write_flooded_area_output, write_groundwater_flux_output, &
                                write_groundwater_storage_output, write_hand_output, &
                                write_interception_et_output, write_interception_storage_output, &
                                write_open_water_et_output, write_potential_open_water_et_output, &
                    write_runoff_output, write_soil_moisture_output, write_soil_saturation_output, &
                                write_soil_vegetation_et_output, write_subsurface_flux_output, &
                                write_subsurface_storage_output, write_surface_flux_output, &
                                write_surface_storage_output, write_surface_water_output, &
                                write_total_water_storage_output, write_water_hru_et_output, &
                                write_water_surface_elevation_output

        implicit none

        integer :: catchment_count, hru_count
        integer :: subbasin_count, climate_region_count
        integer :: hotstart_read_mode, hotstart_write_mode
        integer :: first_subbasin, last_subbasin
        real(4) :: timestep
        ! Meteorological forcing timestep in seconds.
        integer :: reservoir_substitution_enabled, reservoir_count
        character(len=40) :: simulation_start, simulation_end

        integer i_yr_end, i_mo_end, i_day_end, i_hr_end, i_min_end
        real(8) jday_end

        integer :: use_temperature_timeseries
        integer :: use_radiation_timeseries
        integer :: use_humidity_timeseries
        integer :: use_wind_timeseries
        integer :: use_pressure_timeseries
        integer :: monthly_radiation_option

        integer :: routing_mode, thread_count
        real :: downstream_boundary_slope, courant_alpha
        ! Downstream boundary slope in metres per kilometre.

        integer :: write_discharge, write_soil_water, write_water_surface_elevation
        integer :: write_flooded_level, write_total_water_storage, write_runoff
        integer :: write_surface_water, write_soil_saturation
        integer :: write_evapotranspiration, write_interception_evaporation
        integer :: write_soil_vegetation_evapotranspiration
        integer :: write_open_water_evaporation, write_water_hru_evaporation
        integer :: write_potential_open_water_evaporation
        integer :: write_groundwater_storage, write_subsurface_storage
        integer :: write_surface_storage, write_interception_storage
        integer :: write_groundwater_flux, write_subsurface_flux, write_surface_flux
        integer :: write_flooded_area

        namelist /model/ simulation_start, simulation_end, timestep, &
            hotstart_read_mode, hotstart_write_mode, first_subbasin, &
            last_subbasin, catchment_count, hru_count, subbasin_count, &
            climate_region_count, reservoir_substitution_enabled, reservoir_count
        namelist /forcing/ use_temperature_timeseries, use_radiation_timeseries, &
            use_humidity_timeseries, use_wind_timeseries, use_pressure_timeseries, &
            monthly_radiation_option
        namelist /routing/ routing_mode, thread_count, &
            downstream_boundary_slope, courant_alpha
        namelist /output/ write_discharge, write_water_surface_elevation, &
            write_flooded_level, write_runoff, write_soil_water, &
            write_soil_saturation, write_total_water_storage, write_surface_water, &
            write_evapotranspiration, write_interception_evaporation, &
            write_soil_vegetation_evapotranspiration, write_open_water_evaporation, &
            write_water_hru_evaporation, write_potential_open_water_evaporation, &
            write_groundwater_storage, write_subsurface_storage, write_surface_storage, &
            write_interception_storage, write_groundwater_flux, write_subsurface_flux, &
            write_surface_flux, write_flooded_area

        open (config_unit, file=input_directory//'config.nml', status='old', action='read')
        read (config_unit, nml=model)

        model_timestep_state = timestep
        catchment_count_state = catchment_count
        climate_cell_count_state = catchment_count
        hru_count_state = hru_count
        subbasin_count_state = subbasin_count
        climate_region_count_state = climate_region_count
        reservoir_substitution_enabled_state = reservoir_substitution_enabled
        hotstart_read_mode_state = hotstart_read_mode
        hotstart_write_mode_state = hotstart_write_mode
        reservoir_count_state = reservoir_count
        first_subbasin_state = first_subbasin
        last_subbasin_state = last_subbasin

        ! Parse start and end simulation dates from strings
        call parse_date_string(simulation_start, year, month, day, hour, minute)
        call parse_date_string(simulation_end, i_yr_end, i_mo_end, i_day_end, i_hr_end, i_min_end)

        ! Compute number of time steps using start/end julian day and hour
        julian_day = calculate_julian_day(year, month, day, hour, minute)
        jday_end = calculate_julian_day(i_yr_end, i_mo_end, i_day_end, i_hr_end, i_min_end)
        timestep_count = calculate_timestep_count(jday_end, julian_day, &
                                                  real(model_timestep_state, 8)) + 1

        read (config_unit, nml=forcing)

        use_temperature_timeseries_state = use_temperature_timeseries
        use_radiation_timeseries_state = use_radiation_timeseries
        use_humidity_timeseries_state = use_humidity_timeseries
        use_wind_timeseries_state = use_wind_timeseries
        use_pressure_timeseries_state = use_pressure_timeseries
        monthly_radiation_option_state = monthly_radiation_option

        ! Pseudo-2D routing remains disabled by the current runtime interface.
        pseudo_two_d_enabled = 0
        overland_flow_width = 10.0
        overland_manning_n = 0.1

        read (config_unit, nml=routing)

        courant_alpha_state = courant_alpha
        inertial_routing_enabled = routing_mode
        thread_count_state = thread_count
        downstream_water_surface_slope = downstream_boundary_slope
        downstream_water_surface_slope = downstream_water_surface_slope*0.001

        read (config_unit, nml=output)

        write_discharge_output = write_discharge
        write_water_surface_elevation_output = write_water_surface_elevation
        write_hand_output = write_flooded_level
        write_runoff_output = write_runoff
        write_soil_moisture_output = write_soil_water
        write_soil_saturation_output = write_soil_saturation
        write_total_water_storage_output = write_total_water_storage
        write_surface_water_output = write_surface_water
        write_et_output = write_evapotranspiration
        write_interception_et_output = write_interception_evaporation
        write_soil_vegetation_et_output = write_soil_vegetation_evapotranspiration
        write_open_water_et_output = write_open_water_evaporation
        write_water_hru_et_output = write_water_hru_evaporation
        write_potential_open_water_et_output = write_potential_open_water_evaporation
        write_groundwater_storage_output = write_groundwater_storage
        write_subsurface_storage_output = write_subsurface_storage
        write_surface_storage_output = write_surface_storage
        write_interception_storage_output = write_interception_storage
        write_groundwater_flux_output = write_groundwater_flux
        write_subsurface_flux_output = write_subsurface_flux
        write_surface_flux_output = write_surface_flux
        write_flooded_area_output = write_flooded_area

        close (config_unit)

        return
    end

end module configuration_io
