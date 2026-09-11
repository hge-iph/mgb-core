module meteorological_io

    implicit none
    private
    public :: open_meteorological_inputs, read_meteorological_forcing, close_meteorological_inputs

contains

    subroutine open_meteorological_inputs
        implicit none

        call manage_meteorological_input_files(1)
    end subroutine open_meteorological_inputs

    subroutine close_meteorological_inputs
        implicit none

        call manage_meteorological_input_files(0)
    end subroutine close_meteorological_inputs

    subroutine manage_meteorological_input_files(file_action)
        use runoff_state, only: catchment_count, precipitation
        use evapotranspiration_state, only: air_pressure, air_temperature, &
                              relative_humidity, use_humidity_timeseries, use_pressure_timeseries, &
                        use_radiation_timeseries, use_temperature_timeseries, use_wind_timeseries, &
                                            wind_speed
        use io_state, only: input_directory, precipitation_unit, pressure_unit, radiation_unit, &
                            relative_humidity_unit, temperature_unit, wind_unit

        implicit none
        integer, intent(in) :: file_action
        integer :: record_length

        !input met files
        ! Open forcing streams before the timestep loop.
        if (file_action == 1) then
            inquire (iolength=record_length) precipitation(1:catchment_count)

            !input binary file with interpolated rainfall data
            open (precipitation_unit, file=input_directory//'precipitation.bin', status='old', &
                  recl=record_length, form='UNFORMATTED', access='DIRECT')

            if (use_temperature_timeseries == 1) open (temperature_unit, file=input_directory// &
                                                       'air_temperature.bin', &
                                     status='old', recl=record_length, form='UNFORMATTED', access= &
                                                       'DIRECT')

            if (use_radiation_timeseries == 1) open (radiation_unit, file=input_directory// &
                                                     'solar_radiation.bin', &
                                     status='old', recl=record_length, form='UNFORMATTED', access= &
                                                     'DIRECT')

            if (use_humidity_timeseries == 1) open (relative_humidity_unit, file= &
                                                    input_directory//'relative_humidity.bin', &
                                     status='old', recl=record_length, form='UNFORMATTED', access= &
                                                    'DIRECT')

            if (use_wind_timeseries == 1) open (wind_unit, file=input_directory//'wind_speed.bin', &
                                     status='old', recl=record_length, form='UNFORMATTED', access= &
                                                'DIRECT')

  if (use_pressure_timeseries == 1) open (pressure_unit, file=input_directory//'air_pressure.bin', &
                                     status='old', recl=record_length, form='UNFORMATTED', access= &
                                                    'DIRECT')

        else
            ! Closing met files
            close (precipitation_unit)
            close (temperature_unit)
            close (radiation_unit)
            close (relative_humidity_unit)
            close (wind_unit)
            close (pressure_unit)

        end if

    end subroutine

    subroutine read_meteorological_forcing(month_number, forcing_record_index)
        use simulation_state, only: month
        use runoff_state, only: catchment_count, precipitation
        use evapotranspiration_state, only: air_pressure, air_temperature, monthly_air_pressure, &
                          monthly_air_temperature, monthly_relative_humidity, monthly_solar_input, &
                                            monthly_wind_speed, relative_humidity, solar_input, &
                       use_humidity_timeseries, use_pressure_timeseries, use_radiation_timeseries, &
                                         use_temperature_timeseries, use_wind_timeseries, wind_speed
        use io_state, only: precipitation_unit, pressure_unit, radiation_unit, &
                            relative_humidity_unit, temperature_unit, wind_unit

        implicit none

        integer, intent(in) :: month_number
        ! Calendar month
        integer, intent(in) :: forcing_record_index
        ! timestep for reading binaries
        integer :: climate_cell_index

        ! Using vectorized read for monthly data
        if (use_temperature_timeseries == 0) air_temperature(:) = monthly_air_temperature(:, &
                                                                                       month_number)
        if (use_radiation_timeseries == 0) solar_input(:) = monthly_solar_input(:, month_number)
        if (use_humidity_timeseries == 0) relative_humidity(:) = monthly_relative_humidity(:, &
                                                                                       month_number)
        if (use_wind_timeseries == 0) wind_speed(:) = monthly_wind_speed(:, month_number)
        if (use_pressure_timeseries == 0) air_pressure(:) = monthly_air_pressure(:, month_number)

        ! Reads precipitation data
        read (precipitation_unit, rec=forcing_record_index) (precipitation(climate_cell_index), &
                                                             climate_cell_index=1, catchment_count)

        ! Reads meteorological data at the same time interval of precipitation
        if (use_temperature_timeseries == 1) read (temperature_unit, rec= &
                 forcing_record_index) (air_temperature(climate_cell_index), climate_cell_index=1, &
                                                                          catchment_count)
        if (use_radiation_timeseries == 1) read (radiation_unit, rec= &
                     forcing_record_index) (solar_input(climate_cell_index), climate_cell_index=1, &
                                                                        catchment_count)
        if (use_humidity_timeseries == 1) read (relative_humidity_unit, rec= &
               forcing_record_index) (relative_humidity(climate_cell_index), climate_cell_index=1, &
                                                                       catchment_count)
        if (use_wind_timeseries == 1) read (wind_unit, rec= &
                      forcing_record_index) (wind_speed(climate_cell_index), climate_cell_index=1, &
                                                                   catchment_count)
        if (use_pressure_timeseries == 1) read (pressure_unit, rec= &
                    forcing_record_index) (air_pressure(climate_cell_index), climate_cell_index=1, &
                                                                       catchment_count)

    end subroutine read_meteorological_forcing

end module meteorological_io
