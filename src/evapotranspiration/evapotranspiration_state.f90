module evapotranspiration_state

    implicit none
    private
    save

    public :: air_pressure, air_temperature, climate_cell_count, climate_region_count, &
        & climate_station_coordinates, monthly_air_pressure, monthly_air_temperature, &
        & monthly_radiation_option, monthly_relative_humidity, monthly_solar_input, &
        & monthly_wind_speed, previous_air_temperature, relative_humidity, solar_input, &
        & use_humidity_timeseries, use_pressure_timeseries, use_radiation_timeseries, &
        & use_temperature_timeseries, use_wind_timeseries, wind_speed, albedo, &
        & evapotranspiration, interception_storage, leaf_area_index, open_water_evaporation_q, &
        & potential_open_water_et, potential_surface_radiation_et, potential_top_radiation_et, &
        & surface_resistance, vegetation_height, &
        & allocate_evapotranspiration_state, deallocate_evapotranspiration_state

    integer climate_cell_count
    integer climate_region_count
    integer use_temperature_timeseries, use_radiation_timeseries
    integer use_humidity_timeseries, use_wind_timeseries, use_pressure_timeseries
    real(4), allocatable :: monthly_air_temperature(:, :), monthly_relative_humidity(:, :)
    real(4), allocatable :: monthly_wind_speed(:, :), monthly_air_pressure(:, :)
    real(4), allocatable :: monthly_solar_input(:, :)
    real, allocatable :: climate_station_coordinates(:, :)
    real, allocatable :: previous_air_temperature(:)
    real(4), allocatable :: air_temperature(:), relative_humidity(:), wind_speed(:)
    real(4), allocatable :: solar_input(:), air_pressure(:)
    integer monthly_radiation_option
    real, allocatable :: albedo(:, :, :), leaf_area_index(:, :, :), vegetation_height(:, :, :)
    real, allocatable :: surface_resistance(:, :, :)
    real, allocatable :: interception_storage(:, :), evapotranspiration(:, :)
    real, allocatable :: open_water_evaporation_q(:)
    real, allocatable :: potential_open_water_et(:), potential_top_radiation_et(:)
    real, allocatable :: potential_surface_radiation_et(:)

contains

    subroutine allocate_evapotranspiration_state(requested_catchment_count, requested_hru_count, &
        & requested_climate_cell_count, requested_climate_region_count)
        integer, intent(in) :: requested_catchment_count, requested_climate_cell_count
        integer, intent(in) :: requested_hru_count, requested_climate_region_count
        allocate (climate_station_coordinates(requested_climate_cell_count, 2))
        allocate (monthly_air_temperature(requested_climate_cell_count, 12))
        allocate (monthly_relative_humidity(requested_climate_cell_count, 12))
        allocate (monthly_wind_speed(requested_climate_cell_count, 12))
        allocate (monthly_air_pressure(requested_climate_cell_count, 12))
        allocate (monthly_solar_input(requested_climate_cell_count, 12))
        allocate (previous_air_temperature(requested_catchment_count))
        allocate (air_temperature(requested_catchment_count))
        allocate (relative_humidity(requested_catchment_count))
        allocate (wind_speed(requested_catchment_count))
        allocate (solar_input(requested_catchment_count))
        allocate (air_pressure(requested_catchment_count))
        allocate (open_water_evaporation_q(requested_catchment_count))
        allocate (interception_storage(requested_catchment_count, requested_hru_count))
        allocate (albedo(requested_hru_count, 12, requested_climate_region_count))
        allocate (leaf_area_index(requested_hru_count, 12, requested_climate_region_count))
        allocate (vegetation_height(requested_hru_count, 12, requested_climate_region_count))
        allocate (surface_resistance(requested_hru_count, 12, requested_climate_region_count))
        allocate (evapotranspiration(requested_catchment_count, requested_hru_count))
        allocate (potential_open_water_et(requested_catchment_count))
        allocate (potential_top_radiation_et(requested_catchment_count))
        allocate (potential_surface_radiation_et(requested_catchment_count))
    end subroutine allocate_evapotranspiration_state

    subroutine deallocate_evapotranspiration_state
        if (allocated(potential_surface_radiation_et)) deallocate (potential_surface_radiation_et)
        if (allocated(potential_top_radiation_et)) deallocate (potential_top_radiation_et)
        if (allocated(potential_open_water_et)) deallocate (potential_open_water_et)
        if (allocated(evapotranspiration)) deallocate (evapotranspiration)
        if (allocated(surface_resistance)) deallocate (surface_resistance)
        if (allocated(vegetation_height)) deallocate (vegetation_height)
        if (allocated(leaf_area_index)) deallocate (leaf_area_index)
        if (allocated(albedo)) deallocate (albedo)
        if (allocated(interception_storage)) deallocate (interception_storage)
        if (allocated(open_water_evaporation_q)) deallocate (open_water_evaporation_q)
        if (allocated(air_pressure)) deallocate (air_pressure)
        if (allocated(solar_input)) deallocate (solar_input)
        if (allocated(wind_speed)) deallocate (wind_speed)
        if (allocated(relative_humidity)) deallocate (relative_humidity)
        if (allocated(air_temperature)) deallocate (air_temperature)
        if (allocated(previous_air_temperature)) deallocate (previous_air_temperature)
        if (allocated(monthly_solar_input)) deallocate (monthly_solar_input)
        if (allocated(monthly_air_pressure)) deallocate (monthly_air_pressure)
        if (allocated(monthly_wind_speed)) deallocate (monthly_wind_speed)
        if (allocated(monthly_relative_humidity)) deallocate (monthly_relative_humidity)
        if (allocated(monthly_air_temperature)) deallocate (monthly_air_temperature)
        if (allocated(climate_station_coordinates)) deallocate (climate_station_coordinates)
    end subroutine deallocate_evapotranspiration_state

end module evapotranspiration_state
