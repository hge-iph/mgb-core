! SPDX-License-Identifier: GPL-3.0-or-later
! Copyright (C) 2019 Hidrologia de Grande Escala (HGE)

! Open or close meteorological forcing files.

        subroutine manage_meteorological_input_files(file_action)

            use model_state
            implicit none
            integer, intent(in) :: file_action

            !input met files
            ! Open forcing streams before the timestep loop.
            if (file_action == 1) then

                !input binary file with interpolated rainfall data
                open (precipitation_unit, file=input_directory//'precipitation.bin', status='old', &
                      recl=catchment_count, form='UNFORMATTED', access='DIRECT')

               if (use_temperature_timeseries == 1) open (temperature_unit, file=input_directory// &
                                                           'air_temperature.bin', &
                                   status='old', recl=catchment_count, form='UNFORMATTED', access= &
                                                           'DIRECT')

                if (use_radiation_timeseries == 1) open (radiation_unit, file=input_directory// &
                                                         'solar_radiation.bin', &
                                   status='old', recl=catchment_count, form='UNFORMATTED', access= &
                                                         'DIRECT')

                if (use_humidity_timeseries == 1) open (relative_humidity_unit, file= &
                                                        input_directory//'relative_humidity.bin', &
                                   status='old', recl=catchment_count, form='UNFORMATTED', access= &
                                                        'DIRECT')

            if (use_wind_timeseries == 1) open (wind_unit, file=input_directory//'wind_speed.bin', &
                                   status='old', recl=catchment_count, form='UNFORMATTED', access= &
                                                    'DIRECT')

  if (use_pressure_timeseries == 1) open (pressure_unit, file=input_directory//'air_pressure.bin', &
                                   status='old', recl=catchment_count, form='UNFORMATTED', access= &
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
