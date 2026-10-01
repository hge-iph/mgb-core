module config

    use, intrinsic :: iso_fortran_env, only: int32, real32, real64
    implicit none
    save

    integer(int32), parameter :: max_hru_count = 12
    integer(int32), parameter :: max_subbasin_count = 505
    integer(int32), parameter :: max_muskingum_reach_count = 150
    real(real64), parameter :: gravity = 9.81

    integer(int32) :: catchment_count
    integer(int32) :: hru_count
    integer(int32) :: subbasin_count
    integer(int32) :: climate_region_count
    integer(int32) :: substitution_count
    integer(int32) :: reservoir_count
    integer(int32) :: timestep_count
    real(real32) :: model_timestep
    integer(int32) :: first_subbasin
    integer(int32) :: last_subbasin

    integer(int32) :: use_temperature_timeseries
    integer(int32) :: use_radiation_timeseries
    integer(int32) :: use_humidity_timeseries
    integer(int32) :: use_wind_timeseries
    integer(int32) :: use_pressure_timeseries
    integer(int32) :: monthly_radiation_option
    integer(int32) :: routing_mode
    integer(int32) :: pseudo_2d_enabled
    integer(int32) :: thread_count
    integer(int32) :: inertial_catchment_count
    real(real64) :: courant_alpha
    real(real64) :: downstream_water_surface_slope
    real(real64) :: overland_flow_width
    real(real64) :: overland_manning_n
    integer(int32) :: face_count
    integer(int32) :: reservoir_substitution_enabled
    integer(int32), allocatable :: routing_method(:)
    integer(int32), allocatable :: substitution_enabled(:)

    integer(int32) :: write_discharge
    integer(int32) :: write_soil_water
    integer(int32) :: write_water_surface_elevation
    integer(int32) :: write_flooded_level
    integer(int32) :: write_total_water_storage
    integer(int32) :: write_runoff
    integer(int32) :: write_surface_water
    integer(int32) :: write_soil_saturation
    integer(int32) :: write_evapotranspiration
    integer(int32) :: write_interception_evaporation
    integer(int32) :: write_soil_vegetation_evapotranspiration
    integer(int32) :: write_open_water_evaporation
    integer(int32) :: write_water_hru_evaporation
    integer(int32) :: write_groundwater_storage
    integer(int32) :: write_subsurface_storage
    integer(int32) :: write_surface_storage
    integer(int32) :: write_interception_storage
    integer(int32) :: write_flooded_area
    integer(int32) :: write_groundwater_flux
    integer(int32) :: write_subsurface_flux
    integer(int32) :: write_surface_flux
    integer(int32) :: write_potential_open_water_evaporation
    integer(int32) :: hotstart_write_mode
    integer(int32) :: hotstart_read_mode
    integer(int32), allocatable :: hotstart_write_schedule(:)

    character(8) :: input_directory
    character(9) :: output_directory
    character(11) :: hotstart_input_directory
    integer(int32), parameter :: io_unit_config = 1
    integer(int32), parameter :: io_unit_fixed_parameter = 2
    integer(int32), parameter :: io_unit_calibrated_parameter = 3
    integer(int32), parameter :: io_unit_catchment_data = 4
    integer(int32), parameter :: io_unit_climate_region = 9
    integer(int32), parameter :: io_unit_substitution_flow = 10
    integer(int32), parameter :: io_unit_flood_stage = 14
    integer(int32), parameter :: io_unit_flood_area = 15
    integer(int32), parameter :: io_unit_climatology = 16
    integer(int32), parameter :: io_unit_water_balance_hotstart = 17
    integer(int32), parameter :: io_unit_inertial_hotstart = 18
    integer(int32), parameter :: io_unit_log = 26
    integer(int32), parameter :: io_unit_stage_area = 41
    integer(int32), parameter :: io_unit_face_connection = 42
    integer(int32), parameter :: io_unit_hotstart_list = 46
    integer(int32), parameter :: io_unit_precipitation = 50
    integer(int32), parameter :: io_unit_temperature = 51
    integer(int32), parameter :: io_unit_radiation = 52
    integer(int32), parameter :: io_unit_relative_humidity = 53
    integer(int32), parameter :: io_unit_wind = 54
    integer(int32), parameter :: io_unit_pressure = 55
    integer(int32), parameter :: io_unit_discharge_output = 1973
    integer(int32), parameter :: io_unit_et_output = 1974
    integer(int32), parameter :: io_unit_water_surface_elevation_output = 1975
    integer(int32), parameter :: io_unit_hand_output = 1976
    integer(int32), parameter :: io_unit_total_water_storage_output = 1977
    integer(int32), parameter :: io_unit_flooded_area_output = 1978
    integer(int32), parameter :: io_unit_soil_saturation_output = 1979
    integer(int32), parameter :: io_unit_interception_et_output = 1980
    integer(int32), parameter :: io_unit_soil_vegetation_et_output = 1981
    integer(int32), parameter :: io_unit_open_water_et_output = 1982
    integer(int32), parameter :: io_unit_soil_water_output = 1983
    integer(int32), parameter :: io_unit_groundwater_storage_output = 1984
    integer(int32), parameter :: io_unit_subsurface_storage_output = 1985
    integer(int32), parameter :: io_unit_surface_storage_output = 1986
    integer(int32), parameter :: io_unit_interception_storage_output = 1987
    integer(int32), parameter :: io_unit_groundwater_flux_output = 1988
    integer(int32), parameter :: io_unit_subsurface_flux_output = 1989
    integer(int32), parameter :: io_unit_surface_flux_output = 1990
    integer(int32), parameter :: io_unit_surface_water_output = 1991
    integer(int32), parameter :: io_unit_runoff_output = 1992
    integer(int32), parameter :: io_unit_water_hru_et_output = 1993
    integer(int32), parameter :: io_unit_potential_open_water_et_output = 1994
    character(10) :: header_fields(max_subbasin_count)

contains

    subroutine allocate_config( &
        & catchment_count, &
        & timestep_count)
        integer(int32), intent(in) :: catchment_count
        integer(int32), intent(in) :: timestep_count
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
