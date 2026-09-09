! SPDX-License-Identifier: GPL-3.0-or-later
! Copyright (C) 2019 Hidrologia de Grande Escala (HGE)

! Read water-balance and inertial-routing state from hotstart files.

    subroutine read_hotstart
        use model_state
        use inertial_state
        use utils_date, only: format_date_string

        implicit none
        integer :: state_index, state_variable_count, reach_index
        real(4), allocatable :: water_balance_state(:)
        real*8, allocatable :: inertial_state_vector(:)
        character(len=10) :: hotstart_filename
        logical :: file_exists

      state_variable_count = (catchment_count*hru_count) + (6*catchment_count) + (catchment_count* &
                                     hru_count) + (sum(muskingum_reach_count) + catchment_count) + &
                               catchment_count
        !
        allocate (water_balance_state(state_variable_count))

        !Set the current datestring to read file (skipping minute)
        hotstart_filename = format_date_string(year, month, day, hour)

        !Check if the hotstart exists
        inquire (file=hotstart_input_directory//'water_balance_state_'//trim(hotstart_filename)// &
                 '.bin', exist=file_exists)
        if (.not. file_exists) then
            write (*, *) 'A problem occurred when reading water_balance_state_'// &
                trim(hotstart_filename)//'.bin. File does not exist, simulation aborted.'
            error stop 'Missing water balance hotstart file'
        end if

        write (*, *)
        write (*, *) 'Reading Water Balance State Variables for: ', hotstart_filename

        open (water_balance_hotstart_unit, file=hotstart_input_directory//'water_balance_state_'// &
     trim(hotstart_filename)//'.bin', status='old', recl=state_variable_count, form='UNFORMATTED', &
              access='DIRECT')

       read (water_balance_hotstart_unit, rec=1) (water_balance_state(state_index), state_index=1, &
                                                   state_variable_count)
        ! Reading state variables:

        state_index = 0
        do catchment_index = 1, catchment_count
            do hru_index = 1, hru_count
                state_index = state_index + 1
                soil_water_storage(catchment_index, hru_index) = water_balance_state(state_index)
                !Reading Soil Moisture
            end do
        end do
        do catchment_index = 1, catchment_count
            state_index = state_index + 1
            groundwater_storage(catchment_index) = water_balance_state(state_index)
            !Reading water in baseflow reservoir
        end do
        do catchment_index = 1, catchment_count
            state_index = state_index + 1
            subsurface_storage(catchment_index) = water_balance_state(state_index)
            !Reading water in subsurface reservoir
        end do
        do catchment_index = 1, catchment_count
            state_index = state_index + 1
            surface_storage(catchment_index) = water_balance_state(state_index)
            !Reading water surface volume
        end do
        do catchment_index = 1, catchment_count
            state_index = state_index + 1
            air_temperature(catchment_index) = water_balance_state(state_index)
            !Reading Temperature
        end do
        do catchment_index = 1, catchment_count
            state_index = state_index + 1
            incoming_q_current(catchment_index) = water_balance_state(state_index)
            !Reading Flow entering into the catchment
        end do
        do catchment_index = 1, catchment_count
            state_index = state_index + 1
            outgoing_q_current(catchment_index) = water_balance_state(state_index)
            !Reading Flow going out of catchment
        end do
        do catchment_index = 1, catchment_count
            do hru_index = 1, hru_count
                state_index = state_index + 1
                interception_storage(catchment_index, hru_index) = water_balance_state(state_index)
                !Reading Canopy interception volume
            end do
        end do
        do catchment_index = 1, catchment_count
            do reach_index = 1, muskingum_reach_count(catchment_index) + 1
                state_index = state_index + 1
                initial_river_q(catchment_index, reach_index) = water_balance_state(state_index)
                !Reading Canopy interception volume
            end do
        end do
        do catchment_index = 1, catchment_count
            state_index = state_index + 1
            catchment_q_current(catchment_index) = water_balance_state(state_index)
            !Reading Runoff generation at each cell
        end do

        close (water_balance_hotstart_unit)
        deallocate (water_balance_state)

        state_variable_count = (9*catchment_count)
        ! Variables from inertial routing
        allocate (inertial_state_vector(state_variable_count))

        write (*, *) 'Reading Hydraulic State Variables for: ', hotstart_filename
        write (*, *)

        open (inertial_hotstart_unit, file=hotstart_input_directory//'inertial_state_'// &
              trim(hotstart_filename)//'.bin', status='old', recl=(state_variable_count*2), form= &
              'UNFORMATTED', access='DIRECT')
        read (inertial_hotstart_unit, rec=1) (inertial_state_vector(state_index), state_index=1, &
                                              state_variable_count)
        ! Reading state variables:

        state_index = 0
        do catchment_index = 1, catchment_count
            state_index = state_index + 1
            inertial_q(catchment_index) = inertial_state_vector(state_index)
            !Streamflow at catchment (catchment_index)
        end do

        do catchment_index = 1, catchment_count
            state_index = state_index + 1
            water_depth(catchment_index) = inertial_state_vector(state_index)
            !Water depth at catchment (catchment_index)
        end do

        do catchment_index = 1, catchment_count
            state_index = state_index + 1
            water_surface_elevation(catchment_index) = inertial_state_vector(state_index)
            !Water elevation at catchment (catchment_index)
        end do

        do catchment_index = 1, catchment_count
            state_index = state_index + 1
            previous_water_volume(catchment_index) = inertial_state_vector(state_index)
            !Previous Water storage at catchment (catchment_index)
        end do

        do catchment_index = 1, catchment_count
            state_index = state_index + 1
            current_water_volume(catchment_index) = inertial_state_vector(state_index)
            !Actual Water storage at catchment (catchment_index)
        end do

        do catchment_index = 1, catchment_count
            state_index = state_index + 1
            current_flooded_area(catchment_index) = inertial_state_vector(state_index)
            !Flooded Area at catchment (catchment_index)
        end do

        do catchment_index = 1, catchment_count
            state_index = state_index + 1
            stage_table_index(catchment_index) = int(inertial_state_vector(state_index))
            !Index of Volume level at catchment (catchment_index)
        end do

        do catchment_index = 1, catchment_count
            state_index = state_index + 1
            face_q(catchment_index) = inertial_state_vector(state_index)
            !Streamflow coming (or leaving) the catchment through connections
        end do

        do catchment_index = 1, catchment_count
            state_index = state_index + 1
            neighbor_q(catchment_index) = inertial_state_vector(state_index)
            !Updated flow for interconnections (signal can be positive or negative)
        end do

        deallocate (inertial_state_vector)
        close (inertial_hotstart_unit)

        return
    end
