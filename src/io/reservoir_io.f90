module reservoir_io

    use, intrinsic :: iso_fortran_env, only: int32, real32, real64
    implicit none
    private
    public :: read_substitution_flows, read_reservoir_data

contains

    subroutine read_substitution_flows
        use config, only: &
            & header_fields, &
            & input_directory, &
            & substitution_count, &
            & io_unit_substitution_flow, &
            & timestep_count
        use forcing, only: substituted_q

        implicit none
        integer(int32) :: input_year
        integer(int32) :: input_month
        integer(int32) :: i_subst
        integer(int32) :: input_day
        integer(int32) :: i_step

        open (io_unit_substitution_flow, file=input_directory//'substitution_flows.txt', status='OLD')
        read (io_unit_substitution_flow, 701) (header_fields(i_subst), i_subst=1, substitution_count)

        do i_step = 1, timestep_count
            read (io_unit_substitution_flow, *) input_year, input_month, input_day, (substituted_q(i_subst, i_step), &
                & i_subst=1, substitution_count)
        end do

        close (io_unit_substitution_flow)
701     format(20a10)
        return

    end subroutine read_substitution_flows

    subroutine read_reservoir_data
        use date_time, only: calculate_integer_julian_day
        use config, only: &
            & catchment_count, &
            & input_directory, &
            & reservoir_count, &
            & timestep_count
        use forcing, only: &
            & allocate_reservoir_forcing, &
            & reservoir_outflow
        use attributes, only: &
            & floodplain_elevation, &
            & floodplain_point_count
        use parameters, only: &
            & area_table, &
            & reservoir_index_by_catchment, &
            & reservoir_start_timestep, &
            & routing_downstream_catchment, &
            & stage_table, &
            & upstream_topology, &
            & volume_table
        use state, only: &
            & day, &
            & month, &
            & year

        implicit none

        integer(int32), parameter :: reservoir_input_unit = 159
        integer(int32) :: reservoir_lake_catchment_count
        integer(int32) :: listed_lake_catchment_count
        integer(int32) :: ignored_reservoir_code
        integer(int32) :: reservoir_index
        integer(int32) :: lake_list_index
        integer(int32) :: floodplain_point_index
        integer(int32) :: first_outflow_timestep
        integer(int32) :: i_catch
        integer(int32) :: i_step
        integer(int32) :: upstream_count
        integer(int32) :: simulate_reservoir
        integer(int32) :: disable_lake_floodplain
        integer(int32) :: any_reservoir_substitution
        integer(int32) :: data_month
        integer(int32) :: data_day
        integer(int32) :: data_year
        integer(int32) :: skipped_outflow_timesteps
        integer(int32), dimension(catchment_count) :: reservoir_lake_catchments
        real(real32) :: incremental_volume
        real(real32) :: elevation_increment
        real(real64) :: lake_volume_increment
        integer(int32) :: simulation_julian_day
        integer(int32) :: data_julian_day
        integer(int32) :: elevation_lower
        integer(int32) :: elevation_upper
        integer(int32) :: lake_range_start
        integer(int32) :: lake_range_end
        real(real64) :: previous_volume
        character(len=15) :: reservoir_name

        call allocate_reservoir_forcing( &
            & timestep_count, &
            & reservoir_count)

        ! The first listed catchment is the dam location. Lake catchments have
        ! floodplain routing disabled, and upstream links terminate at the dam.
        open (reservoir_input_unit, file=input_directory//'reservoir_config.txt')

        listed_lake_catchment_count = 0
        reservoir_lake_catchments = 0
        any_reservoir_substitution = 0

        do reservoir_index = 1, reservoir_count
            ! Record: reservoir name/code, simulation and lake flags, count, catchment IDs.
            read (reservoir_input_unit, *) reservoir_name, ignored_reservoir_code, &
                & simulate_reservoir, disable_lake_floodplain, reservoir_lake_catchment_count, &
                & reservoir_lake_catchments(listed_lake_catchment_count + &
                & 1:reservoir_lake_catchment_count + listed_lake_catchment_count)

            ! A reservoir without listed catchments cannot be simulated.
            if (reservoir_lake_catchment_count == 0) then
                disable_lake_floodplain = 0
                simulate_reservoir = 0
            end if

            ! The first catchment in the record contains the dam.
            i_catch = reservoir_lake_catchments(listed_lake_catchment_count + 1)

            if (simulate_reservoir > 0) then
                reservoir_index_by_catchment(i_catch) = reservoir_index
                any_reservoir_substitution = 1

                ! Terminate the reservoir catchment and its direct upstream links.
                upstream_count = upstream_topology(i_catch, 1)
                if (upstream_count > 0) then
                    do lake_list_index = 1, upstream_count
                        routing_downstream_catchment(upstream_topology(i_catch, 1 + lake_list_index)) = -2
                    end do
                end if
                routing_downstream_catchment(i_catch) = -2
            end if

            if (disable_lake_floodplain > 0) then
                listed_lake_catchment_count = listed_lake_catchment_count + reservoir_lake_catchment_count
            else
                lake_range_start = listed_lake_catchment_count + 1
                lake_range_end = reservoir_lake_catchment_count + listed_lake_catchment_count
                reservoir_lake_catchments(lake_range_start:lake_range_end) = 0
            end if
        end do
        close (reservoir_input_unit)

        ! Treat reservoir-lake area as constant when updating its volume table.

        lake_list_index = 1
        do while (reservoir_lake_catchments(lake_list_index) > 0)

            i_catch = reservoir_lake_catchments(lake_list_index)
            area_table(3, i_catch) = area_table(2, i_catch)
            lake_volume_increment = area_table(3, i_catch)*(stage_table(3, i_catch) - stage_table(2, i_catch))*1000000.0
            volume_table(3, i_catch) = volume_table(2, i_catch) + lake_volume_increment

            ! Extend the constant-area table through all floodplain elevations.
            do floodplain_point_index = 1, floodplain_point_count(i_catch) - 1
                area_table(floodplain_point_index + 3, i_catch) = area_table(2, i_catch)
                elevation_lower = floodplain_elevation(floodplain_point_index, i_catch)
                elevation_upper = floodplain_elevation(floodplain_point_index + 1, i_catch)
                previous_volume = volume_table(floodplain_point_index + 2, i_catch)
                elevation_increment = elevation_upper - elevation_lower
                incremental_volume = elevation_increment*1000000.0*area_table(2, i_catch)
                volume_table(floodplain_point_index + 3, i_catch) = previous_volume + incremental_volume
            end do

            lake_list_index = lake_list_index + 1

        end do
        reservoir_outflow = -1
        ! Negative values mark unavailable outflow data.

        if (any_reservoir_substitution > 0) then

            ! Read the first observation date to align the series with the simulation.
            open (reservoir_input_unit, file=input_directory//'reservoir_outflow.txt')
            read (reservoir_input_unit, *) data_year, data_month, data_day
            close (reservoir_input_unit)

            simulation_julian_day = calculate_integer_julian_day(year, month, day)
            data_julian_day = calculate_integer_julian_day(data_year, data_month, data_day)
            skipped_outflow_timesteps = simulation_julian_day - data_julian_day

            first_outflow_timestep = 1
            if (skipped_outflow_timesteps < 0) then
                ! Simulation begins before observations.
                first_outflow_timestep = 1 - skipped_outflow_timesteps
                skipped_outflow_timesteps = 0
            end if

            open (reservoir_input_unit, file=input_directory//'reservoir_outflow.txt')

            ! Skip observations before the simulation period.
            do i_step = 1, skipped_outflow_timesteps
                read (reservoir_input_unit, *)
            end do

            do i_step = first_outflow_timestep, timestep_count
                read (reservoir_input_unit, *) data_year, data_month, data_day, &
                    & reservoir_outflow(i_step, :)
            end do

            close (reservoir_input_unit)

            ! Find the first available outflow for each simulated reservoir.
            reservoir_start_timestep = 1
            do i_catch = 1, catchment_count
                if (reservoir_index_by_catchment(i_catch) > 0) then
                    reservoir_index = reservoir_index_by_catchment(i_catch)
                    do i_step = 1, timestep_count
                        if (reservoir_outflow(i_step, reservoir_index) > 0) then
                            reservoir_start_timestep(i_catch) = i_step
                            exit
                        end if
                    end do
                end if
            end do
        end if

    end subroutine

end module reservoir_io
