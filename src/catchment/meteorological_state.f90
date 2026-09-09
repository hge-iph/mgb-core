! SPDX-License-Identifier: GPL-3.0-or-later
! Copyright (C) 2019 Hidrologia de Grande Escala (HGE)

module meteorological_state

    implicit none
    private
    save

    public :: air_pressure, air_temperature, climate_cell_count, climate_region_count, &
              climate_station_coordinates, monthly_air_pressure, monthly_air_temperature, &
              monthly_radiation_option, monthly_relative_humidity, monthly_solar_input, &
              monthly_wind_speed, precipitation, previous_air_temperature, relative_humidity, &
          solar_input, use_humidity_timeseries, use_pressure_timeseries, use_radiation_timeseries, &
              use_temperature_timeseries, use_wind_timeseries, wind_speed, &
              allocate_meteorological_state, deallocate_meteorological_state

    integer climate_cell_count
    integer climate_region_count
    integer use_temperature_timeseries, use_radiation_timeseries
    integer use_humidity_timeseries, use_wind_timeseries, use_pressure_timeseries
    real(4), allocatable :: monthly_air_temperature(:, :), monthly_relative_humidity(:, :)
    real(4), allocatable :: monthly_wind_speed(:, :), monthly_air_pressure(:, :)
    real(4), allocatable :: monthly_solar_input(:, :)
    real, allocatable :: climate_station_coordinates(:, :)
    real, allocatable :: previous_air_temperature(:)
    real(4), allocatable :: precipitation(:)
    real(4), allocatable :: air_temperature(:), relative_humidity(:), wind_speed(:)
    real(4), allocatable :: solar_input(:), air_pressure(:)
    integer monthly_radiation_option

contains

   subroutine allocate_meteorological_state(requested_catchment_count, requested_climate_cell_count)
        integer, intent(in) :: requested_catchment_count, requested_climate_cell_count
        allocate (climate_station_coordinates(requested_climate_cell_count, 2))
        allocate (monthly_air_temperature(requested_climate_cell_count, 12))
        allocate (monthly_relative_humidity(requested_climate_cell_count, 12))
        allocate (monthly_wind_speed(requested_climate_cell_count, 12))
        allocate (monthly_air_pressure(requested_climate_cell_count, 12))
        allocate (monthly_solar_input(requested_climate_cell_count, 12))
        allocate (previous_air_temperature(requested_catchment_count))
        allocate (precipitation(requested_catchment_count))
        allocate (air_temperature(requested_catchment_count))
        allocate (relative_humidity(requested_catchment_count))
        allocate (wind_speed(requested_catchment_count))
        allocate (solar_input(requested_catchment_count))
        allocate (air_pressure(requested_catchment_count))
    end subroutine allocate_meteorological_state

    subroutine deallocate_meteorological_state
        if (allocated(air_pressure)) deallocate (air_pressure)
        if (allocated(solar_input)) deallocate (solar_input)
        if (allocated(wind_speed)) deallocate (wind_speed)
        if (allocated(relative_humidity)) deallocate (relative_humidity)
        if (allocated(air_temperature)) deallocate (air_temperature)
        if (allocated(precipitation)) deallocate (precipitation)
        if (allocated(previous_air_temperature)) deallocate (previous_air_temperature)
        if (allocated(monthly_solar_input)) deallocate (monthly_solar_input)
        if (allocated(monthly_air_pressure)) deallocate (monthly_air_pressure)
        if (allocated(monthly_wind_speed)) deallocate (monthly_wind_speed)
        if (allocated(monthly_relative_humidity)) deallocate (monthly_relative_humidity)
        if (allocated(monthly_air_temperature)) deallocate (monthly_air_temperature)
        if (allocated(climate_station_coordinates)) deallocate (climate_station_coordinates)
    end subroutine deallocate_meteorological_state

end module meteorological_state
