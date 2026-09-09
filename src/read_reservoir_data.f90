! SPDX-License-Identifier: GPL-3.0-or-later

! Read hydropower-reservoir topology and outflow time series.

subroutine read_reservoir_data

    use model_state
    use inertial_state
    use utils_time, only: calculate_integer_julian_day

    implicit none

    integer, parameter :: reservoir_input_unit = 159
    integer :: reservoir_lake_catchment_count, listed_lake_catchment_count
    integer :: ignored_reservoir_code, reservoir_index, lake_list_index
    integer :: floodplain_point_index, first_outflow_timestep
    integer :: simulate_reservoir, disable_lake_floodplain
    integer :: any_reservoir_substitution
    integer :: data_month, data_day, data_year, skipped_outflow_timesteps
    integer, dimension(catchment_count) :: reservoir_lake_catchments
    real :: incremental_volume
    character(len=15) :: reservoir_name

    allocate (reservoir_outflow(timestep_count, reservoir_count))

! The first listed catchment is the dam location. Lake catchments have
! floodplain routing disabled, and upstream links terminate at the dam.
    open (reservoir_input_unit, file=input_directory//'reservoir_config.txt')

    listed_lake_catchment_count = 0
    reservoir_lake_catchments = 0
    any_reservoir_substitution = 0

    do reservoir_index = 1, reservoir_count
        ! Record: reservoir name/code, simulation and lake flags, count, catchment IDs.
        read (reservoir_input_unit, *) reservoir_name, ignored_reservoir_code, simulate_reservoir, &
            disable_lake_floodplain, reservoir_lake_catchment_count, &
            reservoir_lake_catchments(listed_lake_catchment_count + 1: &
                                      reservoir_lake_catchment_count + listed_lake_catchment_count)

        ! A reservoir without listed catchments cannot be simulated.
        if (reservoir_lake_catchment_count == 0) then
            disable_lake_floodplain = 0
            simulate_reservoir = 0
        end if

        ! The first catchment in the record contains the dam.
        catchment_index = reservoir_lake_catchments(listed_lake_catchment_count + 1)

        if (simulate_reservoir > 0) then
            reservoir_index_by_catchment(catchment_index) = reservoir_index
            any_reservoir_substitution = 1

            ! Terminate the reservoir catchment and its direct upstream links.
            upstream_count = upstream_topology(catchment_index, 1)
            if (upstream_count > 0) then
                do lake_list_index = 1, upstream_count
           routing_downstream_catchment(upstream_topology(catchment_index, 1 + lake_list_index)) = &
                        -2
                end do
            end if
            routing_downstream_catchment(catchment_index) = -2
        end if

        if (disable_lake_floodplain > 0) then
            listed_lake_catchment_count = listed_lake_catchment_count + &
                                          reservoir_lake_catchment_count
        else
     reservoir_lake_catchments((listed_lake_catchment_count + 1):(reservoir_lake_catchment_count + &
                                                                   listed_lake_catchment_count)) = &
                0
        end if
    end do
    close (reservoir_input_unit)

! Treat reservoir-lake area as constant when updating its volume table.

    lake_list_index = 1
    do while (reservoir_lake_catchments(lake_list_index) > 0)

        catchment_index = reservoir_lake_catchments(lake_list_index)
        area_table(3, catchment_index) = area_table(2, catchment_index)
        volume_table(3, catchment_index) = volume_table(2, catchment_index) &
                                           + area_table(3, catchment_index) &
                             *(stage_table(3, catchment_index) - stage_table(2, catchment_index))* &
                                           1000000.0

        ! Extend the constant-area table through all floodplain elevations.
        do floodplain_point_index = 1, floodplain_point_count(catchment_index) - 1
            area_table(floodplain_point_index + 3, catchment_index) = area_table(2, &
                                                                                 catchment_index)
            incremental_volume = (floodplain_elevation(floodplain_point_index + 1, &
                                                       catchment_index) &
                                  - floodplain_elevation(floodplain_point_index, &
                                                         catchment_index)) &
                                 *1000000.0*area_table(2, catchment_index)
            volume_table(floodplain_point_index + 3, catchment_index) &
                = volume_table(floodplain_point_index + 2, catchment_index) + incremental_volume
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

        skipped_outflow_timesteps = calculate_integer_julian_day(year, month, day) - &
                                    calculate_integer_julian_day(data_year, data_month, data_day)

        first_outflow_timestep = 1
        if (skipped_outflow_timesteps < 0) then
            ! Simulation begins before observations.
            first_outflow_timestep = 1 - skipped_outflow_timesteps
            skipped_outflow_timesteps = 0
        end if

        open (reservoir_input_unit, file=input_directory//'reservoir_outflow.txt')

        ! Skip observations before the simulation period.
        do timestep_index = 1, skipped_outflow_timesteps
            read (reservoir_input_unit, *)
        end do

        do timestep_index = first_outflow_timestep, timestep_count
 read (reservoir_input_unit, *) data_year, data_month, data_day, reservoir_outflow(timestep_index, &
                                                                                              :)
        end do

        close (reservoir_input_unit)

        ! Find the first available outflow for each simulated reservoir.
        reservoir_start_timestep = 1
        do catchment_index = 1, catchment_count
            if (reservoir_index_by_catchment(catchment_index) > 0) then
                reservoir_index = reservoir_index_by_catchment(catchment_index)
                do timestep_index = 1, timestep_count
                    if (reservoir_outflow(timestep_index, reservoir_index) > 0) then
                        reservoir_start_timestep(catchment_index) = timestep_index
                        exit
                    end if
                end do
            end if
        end do
    end if

end subroutine
