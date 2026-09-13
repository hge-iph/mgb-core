module hotstart_io

    implicit none
    private
    public :: read_hotstart, read_hotstart_schedule, write_hotstart

contains

    subroutine read_hotstart_schedule
        use config, only: &
            & hotstart_list_unit, &
            & hotstart_write_schedule, &
            & input_directory, &
            & timestep_count

        implicit none

        integer :: i_step

        open (hotstart_list_unit, file=input_directory//'hotstart_schedule.txt', status='OLD', action='READ')
        hotstart_write_schedule = 0
        do i_step = 1, timestep_count
            read (hotstart_list_unit, *) hotstart_write_schedule(i_step)
        end do
        close (hotstart_list_unit)
    end subroutine read_hotstart_schedule

    subroutine read_hotstart
        use date_time, only: format_date_string
        use config, only: &
            & catchment_count, &
            & hotstart_input_directory, &
            & hru_count, &
            & inertial_hotstart_unit, &
            & water_balance_hotstart_unit
        use forcing, only: air_temperature
        use parameters, only: muskingum_reach_count
        use state, only: &
            & catchment_q_current, &
            & current_flooded_area, &
            & current_water_volume, &
            & day, &
            & face_q, &
            & groundwater_storage, &
            & hour, &
            & incoming_q_current, &
            & inertial_q, &
            & initial_river_q, &
            & interception_storage, &
            & minute, &
            & month, &
            & neighbor_q, &
            & previous_water_volume, &
            & stage_table_index, &
            & water_depth, &
            & water_surface_elevation, &
            & outgoing_q_current, &
            & soil_water_storage, &
            & subsurface_storage, &
            & surface_storage, &
            & year

        implicit none
        integer :: i_catch
        integer :: i_hru
        integer :: record_length
        integer :: state_index
        integer :: state_variable_count
        integer :: reach_index
        real(4), allocatable :: hotstart_water_balance_vector(:)
        real*8, allocatable :: inertial_state_vector(:)
        character(len=10) :: hotstart_filename
        logical :: file_exists

        state_variable_count = catchment_count*hru_count
        state_variable_count = state_variable_count + 6*catchment_count
        state_variable_count = state_variable_count + catchment_count*hru_count
        state_variable_count = state_variable_count + sum(muskingum_reach_count) + catchment_count
        state_variable_count = state_variable_count + catchment_count
        !
        allocate (hotstart_water_balance_vector(state_variable_count))
        inquire (iolength=record_length) hotstart_water_balance_vector

        !Set the current datestring to read file (skipping minute)
        hotstart_filename = format_date_string(year, month, day, hour)

        !Check if the hotstart exists
        inquire (file=hotstart_input_directory//'runoff_state_'//trim(hotstart_filename)//'.bin', exist=file_exists)
        if (.not. file_exists) then
            write (*, *) 'A problem occurred when reading runoff_state_'// &
                & trim(hotstart_filename)//'.bin. File does not exist, simulation aborted.'
            error stop 'Missing water balance hotstart file'
        end if

        write (*, *)
        write (*, *) 'Reading Water Balance State Variables for: ', hotstart_filename

        open (water_balance_hotstart_unit, file= hotstart_input_directory//'runoff_state_'//trim(hotstart_filename)//'.bin', &
            & status= 'old', recl=record_length, form='UNFORMATTED', access='DIRECT')

        read (water_balance_hotstart_unit, rec=1) (hotstart_water_balance_vector(state_index), state_index=1, state_variable_count)
        ! Reading state variables:

        state_index = 0
        do i_catch = 1, catchment_count
            do i_hru = 1, hru_count
                state_index = state_index + 1
                soil_water_storage(i_catch, i_hru) = hotstart_water_balance_vector(state_index)
                !Reading Soil Moisture
            end do
        end do
        do i_catch = 1, catchment_count
            state_index = state_index + 1
            groundwater_storage(i_catch) = hotstart_water_balance_vector(state_index)
            !Reading water in baseflow reservoir
        end do
        do i_catch = 1, catchment_count
            state_index = state_index + 1
            subsurface_storage(i_catch) = hotstart_water_balance_vector(state_index)
            !Reading water in subsurface reservoir
        end do
        do i_catch = 1, catchment_count
            state_index = state_index + 1
            surface_storage(i_catch) = hotstart_water_balance_vector(state_index)
            !Reading water surface volume
        end do
        do i_catch = 1, catchment_count
            state_index = state_index + 1
            air_temperature(i_catch) = hotstart_water_balance_vector(state_index)
            !Reading Temperature
        end do
        do i_catch = 1, catchment_count
            state_index = state_index + 1
            incoming_q_current(i_catch) = hotstart_water_balance_vector(state_index)
            !Reading Flow entering into the catchment
        end do
        do i_catch = 1, catchment_count
            state_index = state_index + 1
            outgoing_q_current(i_catch) = hotstart_water_balance_vector(state_index)
            !Reading Flow going out of catchment
        end do
        do i_catch = 1, catchment_count
            do i_hru = 1, hru_count
                state_index = state_index + 1
                interception_storage(i_catch, i_hru) = hotstart_water_balance_vector(state_index)
                !Reading Canopy interception volume
            end do
        end do
        do i_catch = 1, catchment_count
            do reach_index = 1, muskingum_reach_count(i_catch) + 1
                state_index = state_index + 1
                initial_river_q(i_catch, reach_index) = hotstart_water_balance_vector(state_index)
                !Reading Canopy interception volume
            end do
        end do
        do i_catch = 1, catchment_count
            state_index = state_index + 1
            catchment_q_current(i_catch) = hotstart_water_balance_vector(state_index)
            !Reading Runoff generation at each cell
        end do

        close (water_balance_hotstart_unit)
        deallocate (hotstart_water_balance_vector)

        state_variable_count = (9*catchment_count)
        ! Variables from inertial routing
        allocate (inertial_state_vector(state_variable_count))
        inquire (iolength=record_length) inertial_state_vector

        write (*, *) 'Reading Hydraulic State Variables for: ', hotstart_filename
        write (*, *)

        open (inertial_hotstart_unit, file= hotstart_input_directory//'inertial_state_'//trim(hotstart_filename)//'.bin', &
            & status='old', recl=record_length, form='UNFORMATTED', access='DIRECT')
        read (inertial_hotstart_unit, rec=1) (inertial_state_vector(state_index), state_index=1, state_variable_count)
        ! Reading state variables:

        state_index = 0
        do i_catch = 1, catchment_count
            state_index = state_index + 1
            inertial_q(i_catch) = inertial_state_vector(state_index)
            !Streamflow at catchment (i_catch)
        end do

        do i_catch = 1, catchment_count
            state_index = state_index + 1
            water_depth(i_catch) = inertial_state_vector(state_index)
            !Water depth at catchment (i_catch)
        end do

        do i_catch = 1, catchment_count
            state_index = state_index + 1
            water_surface_elevation(i_catch) = inertial_state_vector(state_index)
            !Water elevation at catchment (i_catch)
        end do

        do i_catch = 1, catchment_count
            state_index = state_index + 1
            previous_water_volume(i_catch) = inertial_state_vector(state_index)
            !Previous Water storage at catchment (i_catch)
        end do

        do i_catch = 1, catchment_count
            state_index = state_index + 1
            current_water_volume(i_catch) = inertial_state_vector(state_index)
            !Actual Water storage at catchment (i_catch)
        end do

        do i_catch = 1, catchment_count
            state_index = state_index + 1
            current_flooded_area(i_catch) = inertial_state_vector(state_index)
            !Flooded Area at catchment (i_catch)
        end do

        do i_catch = 1, catchment_count
            state_index = state_index + 1
            stage_table_index(i_catch) = int(inertial_state_vector(state_index))
            !Index of Volume level at catchment (i_catch)
        end do

        do i_catch = 1, catchment_count
            state_index = state_index + 1
            face_q(i_catch) = inertial_state_vector(state_index)
            !Streamflow coming (or leaving) the catchment through connections
        end do

        do i_catch = 1, catchment_count
            state_index = state_index + 1
            neighbor_q(i_catch) = inertial_state_vector(state_index)
            !Updated flow for interconnections (signal can be positive or negative)
        end do

        deallocate (inertial_state_vector)
        close (inertial_hotstart_unit)

        return
    end

    subroutine write_hotstart
        use date_time, only: &
            & convert_julian_day_to_calendar, &
            & format_date_string
        use config, only: &
            & catchment_count, &
            & hotstart_input_directory, &
            & hru_count, &
            & inertial_hotstart_unit, &
            & water_balance_hotstart_unit, &
            & write_hotstart_mode
        use forcing, only: air_temperature
        use parameters, only: muskingum_reach_count
        use state, only: &
            & catchment_q_current, &
            & current_flooded_area, &
            & current_water_volume, &
            & day, &
            & face_q, &
            & groundwater_storage, &
            & hour, &
            & incoming_q_current, &
            & inertial_q, &
            & initial_river_q, &
            & interception_storage, &
            & julian_day, &
            & minute, &
            & month, &
            & neighbor_q, &
            & previous_water_volume, &
            & stage_table_index, &
            & water_depth, &
            & water_surface_elevation, &
            & outgoing_q_current, &
            & soil_water_storage, &
            & subsurface_storage, &
            & surface_storage, &
            & year

        implicit none
        integer :: i_catch
        integer :: i_hru
        integer :: record_length
        integer :: state_index
        integer :: state_variable_count
        integer :: reach_index
        real(4), allocatable :: hotstart_water_balance_vector(:)
        real*8, allocatable :: inertial_state_vector(:)
        character(len=10) :: hotstart_filename

        state_variable_count = catchment_count*hru_count
        state_variable_count = state_variable_count + 6*catchment_count
        state_variable_count = state_variable_count + catchment_count*hru_count
        state_variable_count = state_variable_count + sum(muskingum_reach_count) + catchment_count
        state_variable_count = state_variable_count + catchment_count
        !

        ! For option 1, model state variables are saved only at the end of simulation
        ! (state_index.e. They will allow starting the MGB one timestep after the end date)
        if (write_hotstart_mode == 1) then

            ! compute calendar date
            call convert_julian_day_to_calendar( &
                & julian_day, &
                & year, &
                & month, &
                & day, &
                & hour, &
                & minute)

            ! For option 2, check if the current timestep is flagged to save MGB initial
            ! conditions for the beginning of each time step.
            ! For option 3, model state variables will be saved for the beginning of each time
            ! step,
            ! and also for the end of simulation. write_hotstart_mode will be automatically set to
            ! 1
            ! at the end of simulation
        end if

        !Set the current datestring to save file (skipping minute)
        hotstart_filename = format_date_string(year, month, day, hour)

        allocate (hotstart_water_balance_vector(state_variable_count))
        inquire (iolength=record_length) hotstart_water_balance_vector

        open (water_balance_hotstart_unit, file= hotstart_input_directory//'runoff_state_'//trim(hotstart_filename)//'.bin', &
            & status= 'unknown', recl=record_length, form='UNFORMATTED', access='DIRECT')

        write (*, *) 'Writing Water Balance State Variables for: ', hotstart_filename

        ! Writing state variables:
        state_index = 0
        do i_catch = 1, catchment_count
            do i_hru = 1, hru_count
                state_index = state_index + 1
                hotstart_water_balance_vector(state_index) = soil_water_storage(i_catch, i_hru)
                !Soil Water for each HRU
            end do
        end do
        do i_catch = 1, catchment_count
            state_index = state_index + 1
            hotstart_water_balance_vector(state_index) = groundwater_storage(i_catch)
            !Reservoir Volume for baseflow
        end do
        do i_catch = 1, catchment_count
            state_index = state_index + 1
            hotstart_water_balance_vector(state_index) = subsurface_storage(i_catch)
            !Reservoir Volume for subsurface flow
        end do
        do i_catch = 1, catchment_count
            state_index = state_index + 1
            hotstart_water_balance_vector(state_index) = surface_storage(i_catch)
            !Reservoir Volume for surface flow
        end do
        do i_catch = 1, catchment_count
            state_index = state_index + 1
            hotstart_water_balance_vector(state_index) = air_temperature(i_catch)
            !Temperature in previous time step
        end do
        do i_catch = 1, catchment_count
            state_index = state_index + 1
            hotstart_water_balance_vector(state_index) = incoming_q_current(i_catch)
            !Streamflow at upstream of catchments
        end do
        do i_catch = 1, catchment_count
            state_index = state_index + 1
            hotstart_water_balance_vector(state_index) = outgoing_q_current(i_catch)
            !Streamflow at downstream of catchments
        end do
        do i_catch = 1, catchment_count
            do i_hru = 1, hru_count
                state_index = state_index + 1
                hotstart_water_balance_vector(state_index) = interception_storage(i_catch, i_hru)
                !Intercepted water stored on canopy reservoir
            end do
        end do
        do i_catch = 1, catchment_count
            do reach_index = 1, muskingum_reach_count(i_catch) + 1
                state_index = state_index + 1
                hotstart_water_balance_vector(state_index) = initial_river_q(i_catch, reach_index)
            end do
        end do
        do i_catch = 1, catchment_count
            state_index = state_index + 1
            hotstart_water_balance_vector(state_index) = catchment_q_current(i_catch)
            !Runoff generated at catchment
        end do

        write (water_balance_hotstart_unit, rec=1) (hotstart_water_balance_vector(state_index), state_index=1, state_variable_count)
        deallocate (hotstart_water_balance_vector)

        close (water_balance_hotstart_unit)

        state_variable_count = (9*catchment_count)
        ! Variables from inertial routing

        write (*, *) 'Writing Hydraulic State Variables for: ', hotstart_filename
        !All variables below are in double precision (Real*8)

        allocate (inertial_state_vector(state_variable_count))
        inquire (iolength=record_length) inertial_state_vector

        open (inertial_hotstart_unit, file= hotstart_input_directory//'inertial_state_'//trim(hotstart_filename)//'.bin', &
            & status='unknown', recl=record_length, form='UNFORMATTED', access='DIRECT')

        state_index = 0
        do i_catch = 1, catchment_count
            state_index = state_index + 1
            inertial_state_vector(state_index) = inertial_q(i_catch)
            !Streamflow at catchment (i_catch)
        end do

        do i_catch = 1, catchment_count
            state_index = state_index + 1
            inertial_state_vector(state_index) = water_depth(i_catch)
            !Water depth at catchment (i_catch)
        end do

        do i_catch = 1, catchment_count
            state_index = state_index + 1
            inertial_state_vector(state_index) = water_surface_elevation(i_catch)
            !Water elevation at catchment (i_catch)
        end do

        do i_catch = 1, catchment_count
            state_index = state_index + 1
            inertial_state_vector(state_index) = previous_water_volume(i_catch)
            !Previous Water storage at catchment (i_catch)
        end do

        do i_catch = 1, catchment_count
            state_index = state_index + 1
            inertial_state_vector(state_index) = current_water_volume(i_catch)
            !Actual Water storage at catchment (i_catch)
        end do

        do i_catch = 1, catchment_count
            state_index = state_index + 1
            inertial_state_vector(state_index) = current_flooded_area(i_catch)
            !Flooded Area at catchment (i_catch)
        end do

        do i_catch = 1, catchment_count
            state_index = state_index + 1
            inertial_state_vector(state_index) = dble(stage_table_index(i_catch))
            !index of Volume level at catchment (i_catch)
        end do

        do i_catch = 1, catchment_count
            state_index = state_index + 1
            inertial_state_vector(state_index) = face_q(i_catch)
            !Streamflow coming (or leaving) the catchment through connections
        end do

        do i_catch = 1, catchment_count
            state_index = state_index + 1
            inertial_state_vector(state_index) = neighbor_q(i_catch)
            !Updated flow for interconnections (signal can be positive or negative)
        end do

        write (inertial_hotstart_unit, rec=1) (inertial_state_vector(state_index), state_index=1, state_variable_count)

        deallocate (inertial_state_vector)
        close (inertial_hotstart_unit)

        return
    end

end module hotstart_io
