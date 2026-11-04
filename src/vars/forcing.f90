module forcing

    use, intrinsic :: iso_fortran_env, only: int32, real32, real64
    implicit none
    save

    real(real32), allocatable :: monthly_air_temperature(:, :)
    real(real32), allocatable :: monthly_relative_humidity(:, :)
    real(real32), allocatable :: monthly_wind_speed(:, :)
    real(real32), allocatable :: monthly_air_pressure(:, :)
    real(real32), allocatable :: monthly_solar_input(:, :)
    real(real32), allocatable :: climate_station_coordinates(:, :)
    real(real32), allocatable :: previous_air_temperature(:)
    real(real32), allocatable :: air_temperature(:)
    real(real32), allocatable :: relative_humidity(:)
    real(real32), allocatable :: wind_speed(:)
    real(real32), allocatable :: solar_input(:)
    real(real32), allocatable :: air_pressure(:)
    real(real32), allocatable :: precipitation(:)
    real(real32), allocatable :: substituted_q(:, :)
    real(real64), allocatable :: reservoir_outflow(:, :)

contains

    subroutine allocate_forcing( &
        & catchment_count, &
        & substitution_count, &
        & timestep_count)
        integer(int32), intent(in) :: catchment_count
        integer(int32), intent(in) :: substitution_count
        integer(int32), intent(in) :: timestep_count
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
        integer(int32), intent(in) :: timestep_count
        integer(int32), intent(in) :: reservoir_count

        allocate (reservoir_outflow(timestep_count, reservoir_count))
    end subroutine allocate_reservoir_forcing

end module forcing
