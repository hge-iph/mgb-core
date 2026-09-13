module simulation_runner

    implicit none
    private
    public :: run_simulation

contains

    subroutine run_simulation
        use catchment, only: initialize_runoff
        use hotstart_io, only: read_hotstart, read_hotstart_schedule, write_hotstart
        use river_inertial, only: initialize_inertial_routing
        use river_muskingum, only: initialize_muskingum_cunge_routing
        use output_io, only: close_model_outputs, open_model_outputs
        use static_input_io, only: read_reservoir_inputs
        use reservoirs, only: initialize_reservoir_state
        use config, only: inertial_catchment_count, log_unit, read_hotstart_mode, &
            & reservoir_substitution_enabled, routing_method, write_hotstart_mode

        implicit none
        integer :: i_step

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
        call initialize_runoff
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
        call run_timestep_loop(i_step)

        ! Hotstart output is available only with inertial routing.
        if (write_hotstart_mode == 1 .or. write_hotstart_mode == 3) then
            !for the end of MGB simulation (to allow starting the model n time step after)
            write_hotstart_mode = 1
            call write_hotstart
        end if

        call close_model_outputs

        return

    end

    subroutine run_timestep_loop(i_step)
        use date_time, only: calculate_julian_day, convert_julian_day_to_calendar
        use catchment, only: update_runoff
        use hotstart_io, only: write_hotstart
        use river_inertial, only: route_inertial_flow
        use meteorological_io, only: read_meteorological_forcing
        use river_muskingum, only: route_muskingum_cunge_network
        use output_io, only: write_model_outputs
        use config, only: catchment_count, inertial_catchment_count, model_timestep, &
            & routing_method, timestep_count, write_hotstart_mode
        use forcing, only: air_temperature, previous_air_temperature
        use attributes, only: bankfull_depth
        use parameters, only: stage_table
        use state, only: catchment_q_current, catchment_q_output, current_flooded_area, day, &
            & flooded_area_output, groundwater_q, hand_output, hour, inertial_q, julian_day, &
            & minute, month, outgoing_q_current, potential_open_water_et, &
            & potential_open_water_et_output, q_river_output, total_water_storage_output, &
            & subsurface_q, surface_q, total_water_storage, water_surface_elevation, &
            & water_surface_elevation_output, year

        implicit none

        integer, parameter :: real_kind = 8
        integer, intent(out) :: i_step
        integer :: i_catch
        real maximum_domain_q, completion_percentage
        ! Current statistics

        write (*, *) ' IT         Date       Max flow (m3/s)   % Complete'

        ! Initialize model time step
        i_step = 0

        do while (i_step < timestep_count)

            ! Advance time
            i_step = i_step + 1

            if (write_hotstart_mode == 2 .or. write_hotstart_mode == 3) then
                call write_hotstart
            end if

            ! compute calendar date
            call convert_julian_day_to_calendar(julian_day, year, month, day, hour, minute)

            ! Get simulation statistics
            maximum_domain_q = maxval(outgoing_q_current)
            ! Maximum flow for the entire model domain
            completion_percentage = (100.*real(i_step)/real(timestep_count))
            !% of simulation completion
            write (*, &
            & '(i5,"    ",i4,"-",i2.2,"-",i2.2," ",i2.2,":",i2.2,"  ",f10.1,"      ",f6.2," %")') &
                & i_step, year, month, day, hour, minute, &
                & maximum_domain_q, completion_percentage

            ! Reads climate data
            previous_air_temperature = air_temperature
            call read_meteorological_forcing(month, i_step)
            ! Read rainfall and other met variables

            ! Perform vertical water balance
            call update_runoff

            if (routing_method(1) == 0) then
                call route_muskingum_cunge_network(i_step)
            end if

            ! Calculates lateral inflow
            do i_catch = 1, catchment_count
                catchment_q_current(i_catch) = &
                    & groundwater_q(i_catch) + subsurface_q(i_catch) &
                    & + surface_q(i_catch)
                !sums surface, subsurface and
            end do

            if (inertial_catchment_count > 0) then
                call route_inertial_flow(i_step)
            end if

            ! Store single-precision output records for this timestep.
            do i_catch = 1, catchment_count
                q_river_output(i_catch) = inertial_q(i_catch)
                water_surface_elevation_output(i_catch) = &
                    & water_surface_elevation(i_catch)
                total_water_storage_output(i_catch) = total_water_storage(i_catch)
                flooded_area_output(i_catch) = current_flooded_area(i_catch)
                catchment_q_output(i_catch) = catchment_q_current(i_catch)
                hand_output(i_catch) = &
                    & water_surface_elevation(i_catch) - real(stage_table(1, &
                    & i_catch)) - real(bankfull_depth(i_catch))
                potential_open_water_et_output(i_catch) = &
                    & potential_open_water_et(i_catch)
            end do

            call write_model_outputs(i_step)

            ! Advance Julian date for next time step
            julian_day = calculate_julian_day(year, month, day, hour, &
                & minute) + (real(model_timestep, real_kind)/86400.0_real_kind)

        end do
        !End time loop

        return
    end subroutine run_timestep_loop

end module simulation_runner
