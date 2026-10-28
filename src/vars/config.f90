module config

    implicit none
    save

    integer, parameter :: max_hru_count = 12
    integer, parameter :: max_subbasin_count = 505
    integer, parameter :: max_muskingum_reach_count = 150
    real*8, parameter :: gravity = 9.81

    integer :: catchment_count
    integer :: hru_count
    integer :: subbasin_count
    integer :: climate_region_count
    integer :: substitution_count
    integer :: reservoir_count
    integer :: water_use_enabled = 1
    integer :: water_use_returns_enabled = 1
    real :: water_use_scale = 1000.0
    integer :: timestep_count
    real :: model_timestep
    integer :: first_subbasin
    integer :: last_subbasin

    integer :: use_temperature_timeseries
    integer :: use_radiation_timeseries
    integer :: use_humidity_timeseries
    integer :: use_wind_timeseries
    integer :: use_pressure_timeseries
    integer :: monthly_radiation_option
    integer :: routing_mode
    integer :: pseudo_2d_enabled
    integer :: thread_count
    integer :: inertial_catchment_count
    real*8 :: courant_alpha
    real*8 :: downstream_water_surface_slope
    real*8 :: overland_flow_width
    real*8 :: overland_manning_n
    integer :: face_count
    integer :: reservoir_substitution_enabled
    integer, allocatable :: routing_method(:)
    integer, allocatable :: substitution_enabled(:)

    integer :: write_discharge
    integer :: write_soil_water
    integer :: write_water_surface_elevation
    integer :: write_flooded_level
    integer :: write_total_water_storage
    integer :: write_runoff
    integer :: write_surface_water
    integer :: write_soil_saturation
    integer :: write_evapotranspiration
    integer :: write_interception_evaporation
    integer :: write_soil_vegetation_evapotranspiration
    integer :: write_open_water_evaporation
    integer :: write_water_hru_evaporation
    integer :: write_groundwater_storage
    integer :: write_subsurface_storage
    integer :: write_surface_storage
    integer :: write_interception_storage
    integer :: write_flooded_area
    integer :: write_groundwater_flux
    integer :: write_subsurface_flux
    integer :: write_surface_flux
    integer :: write_potential_open_water_evaporation
    integer :: hotstart_write_mode
    integer :: hotstart_read_mode
    integer, allocatable :: hotstart_write_schedule(:)

    character(8) :: input_directory
    character(9) :: output_directory
    character(11) :: hotstart_input_directory
    integer, parameter :: io_unit_config = 1
    integer, parameter :: io_unit_fixed_parameter = 2
    integer, parameter :: io_unit_calibrated_parameter = 3
    integer, parameter :: io_unit_catchment_data = 4
    integer, parameter :: io_unit_climate_region = 9
    integer, parameter :: io_unit_substitution_flow = 10
    integer, parameter :: io_unit_flood_stage = 14
    integer, parameter :: io_unit_flood_area = 15
    integer, parameter :: io_unit_climatology = 16
    integer, parameter :: io_unit_water_balance_hotstart = 17
    integer, parameter :: io_unit_inertial_hotstart = 18
    integer, parameter :: io_unit_log = 26
    integer, parameter :: io_unit_stage_area = 41
    integer, parameter :: io_unit_face_connection = 42
    integer, parameter :: io_unit_hotstart_list = 46
    integer, parameter :: io_unit_precipitation = 50
    integer, parameter :: io_unit_temperature = 51
    integer, parameter :: io_unit_radiation = 52
    integer, parameter :: io_unit_relative_humidity = 53
    integer, parameter :: io_unit_wind = 54
    integer, parameter :: io_unit_pressure = 55
    integer, parameter :: io_unit_discharge_output = 1973
    integer, parameter :: io_unit_et_output = 1974
    integer, parameter :: io_unit_water_surface_elevation_output = 1975
    integer, parameter :: io_unit_hand_output = 1976
    integer, parameter :: io_unit_total_water_storage_output = 1977
    integer, parameter :: io_unit_flooded_area_output = 1978
    integer, parameter :: io_unit_soil_saturation_output = 1979
    integer, parameter :: io_unit_interception_et_output = 1980
    integer, parameter :: io_unit_soil_vegetation_et_output = 1981
    integer, parameter :: io_unit_open_water_et_output = 1982
    integer, parameter :: io_unit_soil_water_output = 1983
    integer, parameter :: io_unit_groundwater_storage_output = 1984
    integer, parameter :: io_unit_subsurface_storage_output = 1985
    integer, parameter :: io_unit_surface_storage_output = 1986
    integer, parameter :: io_unit_interception_storage_output = 1987
    integer, parameter :: io_unit_groundwater_flux_output = 1988
    integer, parameter :: io_unit_subsurface_flux_output = 1989
    integer, parameter :: io_unit_surface_flux_output = 1990
    integer, parameter :: io_unit_surface_water_output = 1991
    integer, parameter :: io_unit_runoff_output = 1992
    integer, parameter :: io_unit_water_hru_et_output = 1993
    integer, parameter :: io_unit_potential_open_water_et_output = 1994
    character(10) :: header_fields(max_subbasin_count)

contains

    subroutine allocate_config( &
        & catchment_count, &
        & timestep_count)
        integer, intent(in) :: catchment_count
        integer, intent(in) :: timestep_count
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
