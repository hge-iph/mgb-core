! SPDX-License-Identifier: GPL-3.0-or-later
! Copyright (C) 2019 Hidrologia de Grande Escala (HGE)

! Read monthly climatological forcing fields.

        subroutine read_climatology
            use model_state
            implicit none
            integer :: climate_cell_index, month_index, record_index

            !input binary file with interpolated rainfall data
      open (climatology_unit, file=input_directory//'monthly_climatology.bin', status='old', recl= &
                  catchment_count, form='UNFORMATTED', access='DIRECT')

            !Binary file of CRU climatology. Order of values:
            !1 - Surface Temperature        [months: 1 ... 12]
            !2 - Relative Humidity          [months: 1 ... 12]
            !3 - Radiation                  [months: 1 ... 12]
            !4 - Wind Speed                 [months: 1 ... 12]
            !5 - Atmospheric pressure       [months: 1 ... 12]

            record_index = 1
            ! Near-surface air temperature (degrees C)
            do month_index = 1, 12
            read (climatology_unit, rec=record_index) (monthly_air_temperature(climate_cell_index, &
                                                               month_index), climate_cell_index=1, &
                                                           catchment_count)
                record_index = record_index + 1
            end do

            ! near surface relative humidity (%)
            do month_index = 1, 12
                read (climatology_unit, rec= &
                      record_index) (monthly_relative_humidity(climate_cell_index, month_index), &
                                     climate_cell_index=1, catchment_count)
                record_index = record_index + 1
            end do

            ! Radiation (MJ/timestep), sunshine hours, or sunshine percent according to the
            ! configuration.
            do month_index = 1, 12
                read (climatology_unit, rec=record_index) (monthly_solar_input(climate_cell_index, &
                                                               month_index), climate_cell_index=1, &
                                                           catchment_count)
                record_index = record_index + 1
            end do

            ! Wind speed (m/s)
            do month_index = 1, 12
                read (climatology_unit, rec=record_index) (monthly_wind_speed(climate_cell_index, &
                                                               month_index), climate_cell_index=1, &
                                                           catchment_count)
                record_index = record_index + 1
            end do

            ! Atmospheric pressure (kPa)
            do month_index = 1, 12
               read (climatology_unit, rec=record_index) (monthly_air_pressure(climate_cell_index, &
                                                               month_index), climate_cell_index=1, &
                                                           catchment_count)
                record_index = record_index + 1
            end do

            close (climatology_unit)

            return

        end subroutine read_climatology
