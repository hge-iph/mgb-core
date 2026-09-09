! SPDX-License-Identifier: GPL-3.0-or-later
! Copyright (C) 2019 Hidrologia de Grande Escala (HGE)

! Execute the model timestep loop.

        subroutine run_model

            use model_state
            use inertial_state
            use utils_time, only: calculate_julian_day, convert_julian_day_to_calendar

            implicit none

            integer, parameter :: real_kind = 8
            real maximum_domain_q, completion_percentage
            ! Current statistics

            write (*, *) ' IT         Date       Max flow (m3/s)   % Complete'

            ! Initialize model time step
            timestep_index = 0

            do while (timestep_index < timestep_count)

                ! Advance time
                timestep_index = timestep_index + 1

                if (write_hotstart_mode == 2 .or. write_hotstart_mode == 3) then
                    call write_hotstart
                end if

                ! compute calendar date
                call convert_julian_day_to_calendar(julian_day, year, month, day, hour, minute)

                ! Get simulation statistics
                maximum_domain_q = maxval(outgoing_q_current)
                ! Maximum flow for the entire model domain
                completion_percentage = (100.*real(timestep_index)/real(timestep_count))
                !% of simulation completion
                write (*, &
               '(i5,"    ",i4,"-",i2.2,"-",i2.2," ",i2.2,":",i2.2,"  ",f10.1,"      ",f6.2," %")') &
                    timestep_index, year, month, day, hour, minute, maximum_domain_q, &
                    completion_percentage

                ! Reads climate data
                previous_air_temperature = air_temperature
                call read_meteorological_forcing(month, timestep_index)
                ! Read rainfall and other met variables

                ! Perform vertical water balance
                call update_catchment_water_balance

                if (routing_method(1) == 0) then
                    call route_muskingum_cunge_network
                end if

                ! Calculates lateral inflow
                do catchment_index = 1, catchment_count
                    catchment_q_current(catchment_index) = groundwater_q(catchment_index) + &
                                                           subsurface_q(catchment_index) + &
                                                           surface_q(catchment_index)
                    !sums surface, subsurface and
                end do

                if (inertial_catchment_count > 0) then
                    call route_inertial_flow
                end if

                ! Store single-precision output records for this timestep.
                do catchment_index = 1, catchment_count
                    q_river_output(catchment_index) = inertial_q(catchment_index)
                    water_surface_elevation_output(catchment_index) = &
                        water_surface_elevation(catchment_index)
                    total_water_storage_output(catchment_index) = &
                        total_water_storage(catchment_index)
                    flooded_area_output(catchment_index) = current_flooded_area(catchment_index)
                    catchment_q_output(catchment_index) = catchment_q_current(catchment_index)
                    hand_output(catchment_index) = water_surface_elevation(catchment_index) - &
                                                   real(stage_table(1, catchment_index)) - &
                                                   real(bankfull_depth(catchment_index))
                    potential_open_water_et_output(catchment_index) = &
                        potential_open_water_et(catchment_index)
                end do

                call write_model_outputs

                ! Advance Julian date for next time step
                julian_day = calculate_julian_day(year, month, day, hour, minute) &
                             + (real(model_timestep_seconds, real_kind)/86400.0_real_kind)

            end do
            !End time loop

75          format(i6, 13f10.4)
66          format(<catchment_count > f10.4)

            return
        end subroutine run_model
