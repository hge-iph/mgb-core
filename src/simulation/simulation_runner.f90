! SPDX-License-Identifier: GPL-3.0-or-later

module simulation_runner

    implicit none
    private
    public :: run_simulation

contains

    subroutine run_simulation
        use catchment_hydrology, only: initialize_catchment_hydrology
        use hotstart_io, only: read_hotstart, read_hotstart_schedule, write_hotstart
        use inertial_routing, only: initialize_inertial_routing
        use muskingum_cunge_routing, only: initialize_muskingum_cunge_routing
        use output_io, only: close_model_outputs, open_model_outputs
        use static_input_io, only: read_reservoir_inputs
        use reservoir_state, only: initialize_reservoir_state, reservoir_substitution_enabled
        use inertial_state, only: inertial_catchment_count, routing_method
        use io_state, only: log_unit
        use output_state, only: read_hotstart_mode, write_hotstart_mode

        implicit none

        call open_model_outputs

        ! Check options for reservoir and substitution flows, currently only working with
        ! inertial module
        if (routing_method(1) == 1) then
            call initialize_reservoir_state
                !! SIN_RESERV
            if (reservoir_substitution_enabled == 1) then
                write (*, *) 'READING SUBSTITUTION FLOW DATA'
                    !! SIN_RESERV
                call read_reservoir_inputs
                    !! SIN_RESERV
            end if
        end if

        ! Model initial conditions
        write (log_unit, *) 'Calling initial conditions...'
        call initialize_catchment_hydrology
        call initialize_muskingum_cunge_routing
        if (inertial_catchment_count > 0) call initialize_inertial_routing

        ! Read water-balance and hydraulic state only for inertial routing.
        if (read_hotstart_mode == 1) then
            call read_hotstart
        end if

        ! Checks if there are multiple time steps to write initial conditions. Useful for
        ! hindcasting
        if (write_hotstart_mode == 2) then
            call read_hotstart_schedule
        end if

        ! Time loop for water balance and routing simulation
        write (log_unit, *) 'Running main model routine...'
        call run_timestep_loop

        ! Hotstart output is available only with inertial routing.
        if (write_hotstart_mode == 1 .or. write_hotstart_mode == 3) then
            !for the end of MGB simulation (to allow starting the model n time step after)
            write_hotstart_mode = 1
            call write_hotstart
        end if

        call close_model_outputs

        return

    end

    subroutine run_timestep_loop
        use date_time, only: calculate_julian_day, convert_julian_day_to_calendar
        use catchment_hydrology, only: update_catchment_hydrology
        use hotstart_io, only: write_hotstart
        use inertial_routing, only: route_inertial_flow
        use meteorological_io, only: read_meteorological_forcing
        use muskingum_cunge_routing, only: route_muskingum_cunge_network
        use output_io, only: write_model_outputs
        use simulation_state, only: day, hour, julian_day, minute, model_timestep, month, &
                                    timestep_count, timestep_index, year
        use catchment_state, only: catchment_count, catchment_index
        use meteorological_state, only: air_temperature, previous_air_temperature
        use water_balance_state, only: catchment_q_current, groundwater_q, &
                               potential_open_water_et, subsurface_q, surface_q, total_water_storage
        use muskingum_state, only: outgoing_q_current
        use inertial_state, only: bankfull_depth, current_flooded_area, inertial_catchment_count, &
                                  inertial_q, routing_method, stage_table, water_surface_elevation
        use output_state, only: catchment_q_output, flooded_area_output, hand_output, &
                       potential_open_water_et_output, q_river_output, total_water_storage_output, &
                                water_surface_elevation_output, write_hotstart_mode

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
            call update_catchment_hydrology

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
                         + (real(model_timestep, real_kind)/86400.0_real_kind)

        end do
        !End time loop

        return
    end subroutine run_timestep_loop

end module simulation_runner
