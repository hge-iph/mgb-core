module forcing

    implicit none
    save

    real(4), allocatable :: monthly_air_temperature(:, :), monthly_relative_humidity(:, :)
    real(4), allocatable :: monthly_wind_speed(:, :), monthly_air_pressure(:, :)
    real(4), allocatable :: monthly_solar_input(:, :)
    real, allocatable :: climate_station_coordinates(:, :)
    real, allocatable :: previous_air_temperature(:)
    real(4), allocatable :: air_temperature(:), relative_humidity(:), wind_speed(:)
    real(4), allocatable :: solar_input(:), air_pressure(:), precipitation(:)
    real, allocatable :: substituted_q(:, :)
    real(kind=8), allocatable :: reservoir_outflow(:, :)

contains

    subroutine allocate_forcing(requested_catchment_count, requested_climate_cell_count, &
        & requested_substitution_count, requested_timestep_count)
        integer, intent(in) :: requested_catchment_count, requested_climate_cell_count
        integer, intent(in) :: requested_substitution_count, requested_timestep_count
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
        allocate (precipitation(requested_catchment_count))
        allocate (substituted_q(requested_substitution_count, requested_timestep_count))
    end subroutine allocate_forcing

    subroutine deallocate_forcing
        if (allocated(reservoir_outflow)) deallocate (reservoir_outflow)
        if (allocated(substituted_q)) deallocate (substituted_q)
        if (allocated(precipitation)) deallocate (precipitation)
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
    end subroutine deallocate_forcing

    subroutine allocate_reservoir_forcing(requested_timestep_count, requested_reservoir_count)
        integer, intent(in) :: requested_timestep_count, requested_reservoir_count

        allocate (reservoir_outflow(requested_timestep_count, requested_reservoir_count))
    end subroutine allocate_reservoir_forcing

end module forcing
