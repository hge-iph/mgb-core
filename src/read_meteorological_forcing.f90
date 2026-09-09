! SPDX-License-Identifier: GPL-3.0-or-later
! Copyright (C) 2019 Hidrologia de Grande Escala (HGE)

! Read meteorological forcing for one model timestep.

    subroutine read_meteorological_forcing(month_number, forcing_record_index)

        use model_state
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
