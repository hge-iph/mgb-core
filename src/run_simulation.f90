! SPDX-License-Identifier: GPL-3.0-or-later
! Copyright (C) 2019 Hidrologia de Grande Escala (HGE)

! Manage simulation initialization, execution, and finalization.

        subroutine run_simulation
            use model_state
            use inertial_state
            implicit none

            call manage_output_files(1)

            ! Check options for reservoir and substitution flows, currently only working with
            ! inertial module
            if (routing_method(1) == 1) then
                reservoir_index_by_catchment = 0
                !! SIN_RESERV
                if (reservoir_substitution_enabled == 1) then
                    write (*, *) 'READING SUBSTITUTION FLOW DATA'
                    !! SIN_RESERV
                    call read_reservoir_data
                    !! SIN_RESERV
                end if
            end if

            ! Model initial conditions
            write (log_unit, *) 'Calling initial conditions...'
            call initialize_model_state

            ! Read water-balance and hydraulic state only for inertial routing.
            if (read_hotstart_mode == 1) then
                call read_hotstart
            end if

            ! Checks if there are multiple time steps to write initial conditions. Useful for
            ! hindcasting
            if (write_hotstart_mode == 2) then
                !Then open file for read
    open (hotstart_list_unit, file=input_directory//'hotstart_schedule.txt', status='OLD', action= &
                      'READ')

                hotstart_write_schedule = 0
                do timestep_index = 1, timestep_count
                    !Check which ITs we need to write hotstart values
                    read (hotstart_list_unit, *) hotstart_write_schedule(timestep_index)
                end do
                close (hotstart_list_unit)
            end if

            ! Time loop for water balance and routing simulation
            write (log_unit, *) 'Running main model routine...'
            call run_model

            ! Hotstart output is available only with inertial routing.
            if (write_hotstart_mode == 1 .or. write_hotstart_mode == 3) then
                !for the end of MGB simulation (to allow starting the model n time step after)
                write_hotstart_mode = 1
                call write_hotstart
            end if

            call manage_output_files(0)

            return

        end
