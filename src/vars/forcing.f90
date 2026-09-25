module forcing

    implicit none
    save

    real(4), allocatable :: monthly_air_temperature(:, :)
    real(4), allocatable :: monthly_relative_humidity(:, :)
    real(4), allocatable :: monthly_wind_speed(:, :)
    real(4), allocatable :: monthly_air_pressure(:, :)
    real(4), allocatable :: monthly_solar_input(:, :)
    real, allocatable :: climate_station_coordinates(:, :)
    real, allocatable :: previous_air_temperature(:)
    real(4), allocatable :: air_temperature(:)
    real(4), allocatable :: relative_humidity(:)
    real(4), allocatable :: wind_speed(:)
    real(4), allocatable :: solar_input(:)
    real(4), allocatable :: air_pressure(:)
    real(4), allocatable :: precipitation(:)
    real, allocatable :: substituted_q(:, :)
    real(kind=8), allocatable :: reservoir_outflow(:, :)

contains

    subroutine allocate_forcing( &
        & catchment_count, &
        & substitution_count, &
        & timestep_count)
        integer, intent(in) :: catchment_count
        integer, intent(in) :: substitution_count
        integer, intent(in) :: timestep_count
        allocate (climate_station_coordinates(catchment_count, 2))
        allocate (monthly_air_temperature(catchment_count, 12))
        allocate (monthly_relative_humidity(catchment_count, 12))
        allocate (monthly_wind_speed(catchment_count, 12))
        allocate (monthly_air_pressure(catchment_count, 12))
        allocate (monthly_solar_input(catchment_count, 12))
        allocate (previous_air_temperature(catchment_count))
        allocate (air_temperature(catchment_count))
        allocate (relative_humidity(catchment_count))
        allocate (wind_speed(catchment_count))
        allocate (solar_input(catchment_count))
        allocate (air_pressure(catchment_count))
        allocate (precipitation(catchment_count))
        allocate (substituted_q(substitution_count, timestep_count))
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

    subroutine allocate_reservoir_forcing( &
        & timestep_count, &
        & reservoir_count)
        integer, intent(in) :: timestep_count
        integer, intent(in) :: reservoir_count

        allocate (reservoir_outflow(timestep_count, reservoir_count))
    end subroutine allocate_reservoir_forcing

end module forcing
