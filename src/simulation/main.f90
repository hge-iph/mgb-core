! Read model inputs, initialize state, run the simulation, and release resources.

program mgb_model

    use attributes, only: &
        & allocate_attributes, &
        & deallocate_attributes
    use config, only: &
        & allocate_config, &
        & catchment_count, &
        & climate_cell_count, &
        & climate_region_count, &
        & courant_alpha, &
        & deallocate_config, &
        & downstream_water_surface_slope, &
        & first_subbasin, &
        & hotstart_input_directory, &
        & hru_count, &
        & inertial_routing_enabled, &
        & input_directory, &
        & last_subbasin, &
        & log_unit, &
        & max_hru_count, &
        & max_muskingum_reach_count, &
        & max_subbasin_count, &
        & model_timestep, &
        & monthly_radiation_option, &
        & output_directory, &
        & pseudo_2d_enabled, &
        & read_hotstart_mode, &
        & reservoir_substitution_enabled, &
        & subbasin_count, &
        & substitution_count, &
        & thread_count, &
        & timestep_count, &
        & write_hotstart_mode
    use forcing, only: &
        & allocate_forcing, &
        & deallocate_forcing
    use parameters, only: &
        & allocate_parameters, &
        & deallocate_parameters
    use state, only: &
        & allocate_state, &
        & day, &
        & deallocate_state, &
        & hour, &
        & minute, &
        & month, &
        & year
    use configuration_io, only: read_model_configuration
    use log_io, only: &
        & close_model_log, &
        & open_model_log
    use runner, only: &
        & prepare_simulation, &
        & run_simulation

    implicit none
    !States that non declared variables cannot be used
    real(8) elapsed_time
    ! Processing time in seconds.
    integer :: clock_start
    integer :: clock_end
    integer :: clock_rate
    integer :: clock_max
    integer :: clock_ticks
    character(8) :: noninteractive_env
    logical :: noninteractive
    !  Statements used to calculate the processing time

    call system_clock(count=clock_start, count_rate=clock_rate, count_max=clock_max)
    noninteractive = .false.
    noninteractive_env = ''
    call get_environment_variable('MGB_NONINTERACTIVE', noninteractive_env)
    if (trim(adjustl(noninteractive_env)) == '1') noninteractive = .true.

    !   Input and output directories and log file
    input_directory = trim(adjustl(('./input/')))
    output_directory = trim(adjustl(('./output/')))
    hotstart_input_directory = trim(adjustl(('./hotstart/')))

    call open_model_log
    !output file with simulation LOG

    write (*, *) 'Modelo Hidrologico de Grandes Bacias: MGB v2'
    write (log_unit, *) 'Modelo Hidrologico de Grandes Bacias: MGB v2'

    write (*, *) 'Reading config.nml file...'
    write (log_unit, *) 'Reading config.nml file...'

    !Suboutine that reads the model main input files with the running main information
    call read_model_configuration

    write (*, *) 'Allocating variables...'
    write (log_unit, *) 'Allocating variables...'
    call allocate_config( &
        & catchment_count, &
        & timestep_count)
    call allocate_forcing( &
        & catchment_count, &
        & climate_cell_count, &
        & substitution_count, &
        & timestep_count)
    call allocate_attributes( &
        & catchment_count, &
        & hru_count)
    call allocate_parameters( &
        & catchment_count, &
        & subbasin_count, &
        & hru_count, &
        & climate_region_count, &
        & max_hru_count, &
        & max_subbasin_count, &
        & max_muskingum_reach_count)
    call allocate_state( &
        & catchment_count, &
        & hru_count, &
        & max_muskingum_reach_count)

    call prepare_simulation

    !  Ask for verification
    !  Informs the model general setup
    write (log_unit, *) 'Input data reading process ended'
    write (log_unit, *) ''
    write (log_unit, '(A30,I8)') 'Number of catchments:', catchment_count
    write (log_unit, '(A30,I8)') 'Number of subbasins:', subbasin_count
    write (log_unit, '(A30,I8)') 'Number of HRUs:', hru_count
    write (log_unit, '(A30,I6,"-",I2.2,"-",I2.2," ",I2.2,":",I2.2)') 'Start date:', year, month, &
        & day, hour, minute
    write (log_unit, '(A30,F16.2)') 'Time step (s):', model_timestep
    write (log_unit, '(A30,I8)') 'Number of time steps:', timestep_count
    write (log_unit, '(A30,I8)') 'Number of substitution gauges:', substitution_count
    write (log_unit, '(A30,I8)') 'Number of climate gauges:', climate_cell_count
    write (log_unit, '(A30,I8)') 'Number of climate regions:', climate_region_count
    write (log_unit, '(A30,2I8)') 'first_subbasin / last_subbasin:', first_subbasin, last_subbasin
    write (log_unit, *) ''
    write (log_unit, *), 'monthly_radiation_option (0=sun.hours; 1=sun.perc; 2=radiation):'
    write (log_unit, '(A30,I8)') 'monthly_radiation_option:', monthly_radiation_option
    write (log_unit, '(A40,I8)') 'reservoir_substitution_enabled (0=no; 1=yes):', reservoir_substitution_enabled
    write (log_unit, '(A40,I8)') 'routing_mode (0=Muskingum; 1=inertial):', inertial_routing_enabled
    write (log_unit, '(A40,I8)') 'thread_count:', thread_count
    write (log_unit, '(A40,I8)') 'Pseudo 2D routing Flag (0=no; 1=yes):', pseudo_2d_enabled
    write (log_unit, '(A40,I8)') 'hotstart_read_mode (0=no; 1=yes):', read_hotstart_mode
    write (log_unit, '(A40,I8)') 'hotstart_write_mode (0=no; 1=yes):', write_hotstart_mode
    write (log_unit, '(A40,F10.2)') 'courant_alpha:', courant_alpha
    write (log_unit, '(A40,F10.6)') 'downstream boundary slope (m/m):', &
        & downstream_water_surface_slope
    write (log_unit, *) ''
    write (log_unit, *) 'PLEASE VERIFY INPUT INFORMATION AND PRESS ENTER TO START RUN...'
    write (log_unit, *) ''

    write (*, *) 'Input data reading process ended'
    write (*, *) ''
    write (*, '(A30,I8)') 'Number of catchments:', catchment_count
    write (*, '(A30,I8)') 'Number of subbasins:', subbasin_count
    write (*, '(A30,I8)') 'Number of HRUs:', hru_count
    write (*, '(A30,I6,"-",I2.2,"-",I2.2," ",I2.2,":",I2.2)') 'Start date:', year, month, &
        & day, hour, minute
    write (*, '(A30,F16.2)') 'Time step (s):', model_timestep
    write (*, '(A30,I8)') 'Number of time steps:', timestep_count
    write (*, '(A30,I8)') 'Number of substitution gauges:', substitution_count
    write (*, '(A30,I8)') 'Number of climate gauges:', climate_cell_count
    write (*, '(A30,I8)') 'Number of climate regions:', climate_region_count
    write (*, '(A30,2I8)') 'first_subbasin / last_subbasin:', first_subbasin, last_subbasin
    write (*, *)
    write (*, *), 'monthly_radiation_option (0=sun.hours; 1=sun.perc; 2=radiation):'
    write (*, '(A30,I8)') 'monthly_radiation_option:', monthly_radiation_option
    write (*, *)
    write (*, '(A40,I8)') 'reservoir_substitution_enabled (0=no; 1=yes):', reservoir_substitution_enabled
    write (*, '(A40,I8)') 'routing_mode (0=Muskingum; 1=inertial):', inertial_routing_enabled
    write (*, '(A40,I8)') 'thread_count:', thread_count
    write (*, '(A40,I8)') 'hotstart_read_mode (0=no; 1=yes):', read_hotstart_mode
    write (*, '(A40,I8)') 'hotstart_write_mode (0=no; 1=yes):', write_hotstart_mode
    write (*, '(A40,F10.2)') 'courant_alpha:', courant_alpha
    write (*, '(A40,F10.6)') 'downstream boundary slope (m/m):', downstream_water_surface_slope
    write (*, *)
    if (noninteractive) then
        write (*, *) 'NON-INTERACTIVE MODE ENABLED. STARTUP CONFIRMATION SKIPPED.'
        write (log_unit, *) 'NON-INTERACTIVE MODE ENABLED. STARTUP CONFIRMATION SKIPPED.'
    else
        write (*, *) 'PLEASE VERIFY INPUT INFORMATION AND PRESS ENTER TO START RUN...'
        write (*, *) ''
        write (*, *) 'REMEMBER THAT RESULT FILES WILL BE OVERWRITTEN. ARE YOU SURE?'
        read (*, *)
    end if

    write (*, *) 'SIMULATION MODE'
    !Warns about the chosen mode
    write (log_unit, *) 'SIMULATION MODE'
    !Warns about the chosen mode
    call run_simulation

    !  After running the model, finish the time count, close all files, and clean all variables

    call deallocate_state
    call deallocate_parameters
    call deallocate_attributes
    call deallocate_forcing
    call deallocate_config

    ! End of closings and cleanings

    ! Inform the user that the model run is over and informations about total processing time

    write (*, *) 'MGB MODEL ENDED SUCCESSFULLY'
    write (log_unit, *) 'MGB MODEL ENDED SUCCESSFULLY'
    print *, char(7)
    call system_clock(count=clock_end)
    if (clock_end >= clock_start) then
        clock_ticks = clock_end - clock_start
    else
        clock_ticks = (clock_max - clock_start + 1) + clock_end
    end if
    elapsed_time = dble(clock_ticks)/dble(clock_rate)
    write (*, *) 'TOTAL TIME:', elapsed_time/60., 'MINUTES'
    write (log_unit, *) 'TOTAL TIME:', elapsed_time/60., 'MINUTES'

    if (noninteractive) then
        write (*, *) 'NON-INTERACTIVE MODE ENABLED. EXIT PROMPT SKIPPED.'
        write (log_unit, *) 'NON-INTERACTIVE MODE ENABLED. EXIT PROMPT SKIPPED.'
    else
        write (*, *) 'PRESS ENTER TO CLOSE...'
        write (log_unit, *) 'PRESS ENTER TO CLOSE...'
    end if

    call close_model_log

    if (.not. noninteractive) then
        read (*, *)
    end if

end
