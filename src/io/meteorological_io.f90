module meteorological_io

    implicit none
    private
    public :: open_meteorological_inputs, read_climatology, read_meteorological_forcing, &
              & close_meteorological_inputs

contains

    subroutine open_meteorological_inputs
        implicit none

        call manage_meteorological_input_files( &
            & 1)
    end subroutine open_meteorological_inputs

    subroutine close_meteorological_inputs
        implicit none

        call manage_meteorological_input_files( &
            & 0)
    end subroutine close_meteorological_inputs

    subroutine read_climatology
        use config, only: &
            & catchment_count, &
            & io_unit_climatology, &
            & input_directory
        use forcing, only: &
            & monthly_air_pressure, &
            & monthly_air_temperature, &
            & monthly_relative_humidity, &
            & monthly_solar_input, &
            & monthly_wind_speed
        
        implicit none
        integer :: i_catch
        integer :: i_month
        integer :: record_index
        integer :: record_length

        inquire (iolength=record_length) (monthly_air_temperature(i_catch, 1), i_catch=1, catchment_count)
        open (io_unit_climatology, file=input_directory//'monthly_climatology.bin', status='old', recl=record_length, &
            & form='UNFORMATTED', access='DIRECT')

        record_index = 1
        do i_month = 1, 12
            read (io_unit_climatology, rec=record_index) (monthly_air_temperature(i_catch, i_month), &
                & i_catch=1, catchment_count)
            record_index = record_index + 1
        end do
        do i_month = 1, 12
            read (io_unit_climatology, rec=record_index) (monthly_relative_humidity(i_catch, i_month), &
                & i_catch=1, catchment_count)
            record_index = record_index + 1
        end do
        do i_month = 1, 12
            read (io_unit_climatology, rec=record_index) (monthly_solar_input(i_catch, i_month), &
                & i_catch=1, catchment_count)
            record_index = record_index + 1
        end do
        do i_month = 1, 12
            read (io_unit_climatology, rec=record_index) (monthly_wind_speed(i_catch, i_month), &
                & i_catch=1, catchment_count)
            record_index = record_index + 1
        end do
        do i_month = 1, 12
            read (io_unit_climatology, rec=record_index) (monthly_air_pressure(i_catch, i_month), &
                & i_catch=1, catchment_count)
            record_index = record_index + 1
        end do
        
        close (io_unit_climatology)
    
    end subroutine read_climatology


    subroutine manage_meteorological_input_files( &
        & file_action)
        use config, only: &
            & catchment_count, &
            & input_directory, &
            & io_unit_precipitation, &
            & io_unit_pressure, &
            & io_unit_radiation, &
            & io_unit_relative_humidity, &
            & io_unit_temperature, &
            & use_humidity_timeseries, &
            & use_pressure_timeseries, &
            & use_radiation_timeseries, &
            & use_temperature_timeseries, &
            & use_wind_timeseries, &
            & io_unit_wind
        use forcing, only: &
            & air_pressure, &
            & air_temperature, &
            & precipitation, &
            & relative_humidity, &
            & wind_speed

        implicit none
        integer, intent(in) :: file_action
        integer :: record_length

        !input met files
        ! Open forcing streams before the timestep loop.
        if (file_action == 1) then
            inquire (iolength=record_length) precipitation(1:catchment_count)

            !input binary file with interpolated rainfall data
            open (io_unit_precipitation, file=input_directory//'precipitation.bin', status='old', recl=record_length, &
                & form='UNFORMATTED', access='DIRECT')

            if (use_temperature_timeseries == 1) open (io_unit_temperature, file= &
                & input_directory//'air_temperature.bin', status='old', recl=record_length, form= &
                & 'UNFORMATTED', access='DIRECT')

            if (use_radiation_timeseries == 1) open (io_unit_radiation, file= &
                & input_directory//'solar_radiation.bin', status='old', recl=record_length, form= &
                & 'UNFORMATTED', access='DIRECT')

            if (use_humidity_timeseries == 1) open (io_unit_relative_humidity, file= &
                & input_directory//'relative_humidity.bin', status='old', recl=record_length, &
                & form='UNFORMATTED', access='DIRECT')

            if (use_wind_timeseries == 1) open (io_unit_wind, file=input_directory//'wind_speed.bin', &
                & status='old', recl=record_length, form='UNFORMATTED', access='DIRECT')

            if (use_pressure_timeseries == 1) open (io_unit_pressure, file= &
                & input_directory//'air_pressure.bin', status='old', recl=record_length, form= &
                & 'UNFORMATTED', access='DIRECT')

        else
            ! Closing met files
            close (io_unit_precipitation)
            close (io_unit_temperature)
            close (io_unit_radiation)
            close (io_unit_relative_humidity)
            close (io_unit_wind)
            close (io_unit_pressure)

        end if

    end subroutine

    subroutine read_meteorological_forcing( &
        & month_number, &
        & record_index)
        use config, only: &
            & catchment_count, &
            & io_unit_precipitation, &
            & io_unit_pressure, &
            & io_unit_radiation, &
            & io_unit_relative_humidity, &
            & io_unit_temperature, &
            & use_humidity_timeseries, &
            & use_pressure_timeseries, &
            & use_radiation_timeseries, &
            & use_temperature_timeseries, &
            & use_wind_timeseries, &
            & io_unit_wind
        use forcing, only: &
            & air_pressure, &
            & air_temperature, &
            & monthly_air_pressure, &
            & monthly_air_temperature, &
            & monthly_relative_humidity, &
            & monthly_solar_input, &
            & monthly_wind_speed, &
            & precipitation, &
            & relative_humidity, &
            & solar_input, &
            & wind_speed

        implicit none

        ! Calendar month
        integer, intent(in) :: month_number
        ! timestep for reading binaries
        integer, intent(in) :: record_index        
        integer :: i_catch

        ! Using vectorized read for monthly climatological data
        if (use_temperature_timeseries == 0) air_temperature(:) = monthly_air_temperature(:, &
            & month_number)
        if (use_radiation_timeseries == 0) solar_input(:) = monthly_solar_input(:, month_number)
        if (use_humidity_timeseries == 0) relative_humidity(:) = monthly_relative_humidity(:, &
            & month_number)
        if (use_wind_timeseries == 0) wind_speed(:) = monthly_wind_speed(:, month_number)
        if (use_pressure_timeseries == 0) air_pressure(:) = monthly_air_pressure(:, month_number)

        ! Reads precipitation data
        read (io_unit_precipitation, rec=record_index) (precipitation(i_catch), i_catch=1, &
            & catchment_count)

        ! Reads meteorological data at the same time interval of precipitation
        if (use_temperature_timeseries == 1) read (io_unit_temperature, rec= &
            & record_index) (air_temperature(i_catch), i_catch=1, &
            & catchment_count)
       
        if (use_radiation_timeseries == 1) read (io_unit_radiation, rec= &
            & record_index) (solar_input(i_catch), i_catch=1, &
            & catchment_count)
        
        if (use_humidity_timeseries == 1) read (io_unit_relative_humidity, rec= &
            & record_index) (relative_humidity(i_catch), i_catch=1, &
            & catchment_count)
       
        if (use_wind_timeseries == 1) read (io_unit_wind, rec= &
            & record_index) (wind_speed(i_catch), i_catch=1, &
            & catchment_count)
       
        if (use_pressure_timeseries == 1) read (io_unit_pressure, rec= &
            & record_index) (air_pressure(i_catch), i_catch=1, &
            & catchment_count)

    end subroutine read_meteorological_forcing

end module meteorological_io
