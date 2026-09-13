module config

    implicit none
    save

    integer, parameter :: max_hru_count = 12
    integer, parameter :: max_subbasin_count = 505
    integer, parameter :: max_muskingum_reach_count = 150
    real*8, parameter :: gravity = 9.81

    integer :: catchment_count, hru_count, subbasin_count
    integer :: climate_cell_count, climate_region_count
    integer :: substitution_count, reservoir_count
    integer :: timestep_count
    real :: model_timestep
    integer :: first_subbasin, last_subbasin

    integer :: use_temperature_timeseries, use_radiation_timeseries
    integer :: use_humidity_timeseries, use_wind_timeseries, use_pressure_timeseries
    integer :: monthly_radiation_option
    integer :: inertial_routing_enabled, pseudo_two_d_enabled, thread_count
    integer :: inertial_catchment_count
    real*8 :: courant_alpha, downstream_water_surface_slope
    real*8 :: overland_flow_width, overland_manning_n
    integer :: face_count
    integer :: reservoir_substitution_enabled
    integer, allocatable :: routing_method(:), substitution_enabled(:)

    integer :: write_discharge_output, write_soil_moisture_output
    integer :: write_water_surface_elevation_output, write_hand_output
    integer :: write_total_water_storage_output, write_runoff_output, write_surface_water_output
    integer :: write_soil_saturation_output, write_et_output, write_interception_et_output
    integer :: write_soil_vegetation_et_output, write_open_water_et_output
    integer :: write_water_hru_et_output
    integer :: write_groundwater_storage_output, write_subsurface_storage_output
    integer :: write_surface_storage_output, write_interception_storage_output
    integer :: write_flooded_area_output
    integer :: write_groundwater_flux_output, write_subsurface_flux_output
    integer :: write_surface_flux_output
    integer :: write_potential_open_water_et_output
    integer :: write_hotstart_mode, read_hotstart_mode
    integer, allocatable :: hotstart_write_schedule(:)

    character(8) :: input_directory
    character(9) :: output_directory
    character(11) :: hotstart_input_directory
    integer, parameter :: config_unit = 1
    integer, parameter :: fixed_parameter_unit = 2
    integer, parameter :: calibrated_parameter_unit = 3
    integer, parameter :: catchment_data_unit = 4
    integer, parameter :: climate_region_unit = 9
    integer, parameter :: substitution_flow_unit = 10
    integer, parameter :: flood_stage_unit = 14
    integer, parameter :: flood_area_unit = 15
    integer, parameter :: climatology_unit = 16
    integer, parameter :: water_balance_hotstart_unit = 17
    integer, parameter :: inertial_hotstart_unit = 18
    integer, parameter :: log_unit = 26
    integer, parameter :: stage_area_unit = 41
    integer, parameter :: face_connection_unit = 42
    integer, parameter :: hotstart_list_unit = 46
    integer, parameter :: precipitation_unit = 50
    integer, parameter :: temperature_unit = 51
    integer, parameter :: radiation_unit = 52
    integer, parameter :: relative_humidity_unit = 53
    integer, parameter :: wind_unit = 54
    integer, parameter :: pressure_unit = 55
    integer, parameter :: discharge_output_unit = 1973
    integer, parameter :: et_output_unit = 1974
    integer, parameter :: water_surface_elevation_output_unit = 1975
    integer, parameter :: hand_output_unit = 1976
    integer, parameter :: total_water_storage_output_unit = 1977
    integer, parameter :: flooded_area_output_unit = 1978
    integer, parameter :: soil_saturation_output_unit = 1979
    integer, parameter :: interception_et_output_unit = 1980
    integer, parameter :: soil_vegetation_et_output_unit = 1981
    integer, parameter :: open_water_et_output_unit = 1982
    integer, parameter :: soil_water_output_unit = 1983
    integer, parameter :: groundwater_storage_output_unit = 1984
    integer, parameter :: subsurface_storage_output_unit = 1985
    integer, parameter :: surface_storage_output_unit = 1986
    integer, parameter :: interception_storage_output_unit = 1987
    integer, parameter :: groundwater_flux_output_unit = 1988
    integer, parameter :: subsurface_flux_output_unit = 1989
    integer, parameter :: surface_flux_output_unit = 1990
    integer, parameter :: surface_water_output_unit = 1991
    integer, parameter :: runoff_output_unit = 1992
    integer, parameter :: water_hru_et_output_unit = 1993
    integer, parameter :: potential_open_water_et_output_unit = 1994
    character(10) :: header_fields(max_subbasin_count)

contains

    subroutine allocate_config(catchment_count, timestep_count)
        integer, intent(in) :: catchment_count, timestep_count
        allocate (routing_method(catchment_count))
        allocate (substitution_enabled(catchment_count))
        allocate (hotstart_write_schedule(timestep_count))
    end subroutine allocate_config

    subroutine deallocate_config
        if (allocated(hotstart_write_schedule)) deallocate (hotstart_write_schedule)
        if (allocated(substitution_enabled)) deallocate (substitution_enabled)
        if (allocated(routing_method)) deallocate (routing_method)
    end subroutine deallocate_config

end module config
