! SPDX-License-Identifier: GPL-3.0-or-later
! Copyright (C) 2026 Hidrologia de Grande Escala (HGE)

! Read model inputs, initialize state, run the simulation, and release resources.

   PROGRAM mgb_model

	USE model_state   !module containing the main variables used in the model
	USE inertial_state  !module containing the variables of the model Local Inertial flow routing model


	IMPLICIT NONE !States that non declared variables cannot be used
	REAL(8) elapsed_seconds !Variable to calculate the processing time
    INTEGER clock_start
    INTEGER clock_end
    INTEGER clock_rate
    INTEGER clock_max
    INTEGER clock_ticks
    CHARACTER(8) noninteractive_env
    LOGICAL noninteractive
!  Statements used to calculate the processing time

    CALL SYSTEM_CLOCK(COUNT=clock_start, COUNT_RATE=clock_rate, COUNT_MAX=clock_max)
    noninteractive = .FALSE.
    noninteractive_env = ''
    CALL GET_ENVIRONMENT_VARIABLE('MGB_NONINTERACTIVE',noninteractive_env)
    IF (TRIM(ADJUSTL(noninteractive_env)) == '1') noninteractive = .TRUE.

!   Input and output directories and log file
    input_directory = TRIM(adjustl(('./input/')))
    output_directory = TRIM(adjustl(('./output/')))
    hotstart_input_directory = TRIM(adjustl(('./hotstart/')))

	OPEN(log_unit,FILE=output_directory // 'log_mgb.txt',STATUS='UNKNOWN') !output file with simulation LOG

    WRITE(*,*)'Modelo Hidrologico de Grandes Bacias: MGB v2'
    WRITE(log_unit,*)'Modelo Hidrologico de Grandes Bacias: MGB v2'

	WRITE(*,*)'Reading infomgb.sim file...'
	WRITE(log_unit,*)'Reading infomgb.sim file...'

    !Suboutine that reads the model main input files with the running main information
	CALL read_model_configuration

    WRITE(*,*)'Allocating variables...'
	WRITE(log_unit,*)'Allocating variables...'
	CALL allocate_model_state(0)
	CALL allocate_inertial_state(0)

	WRITE(*,*)'Reading fixed parameters file...'
	WRITE(log_unit,*)'Reading fixed parameters file...'
	CALL read_fixed_parameters
	WRITE(*,*)'Reading calibrated parameters file...'
	WRITE(log_unit,*)'Reading calibrated parameters file...'
	CALL read_calibrated_parameters
	WRITE(*,*)'Reading model topology (mini.gtp) file...'
	WRITE(log_unit,*)'Reading calibrated parameters file...'
	CALL read_catchment_data

	WRITE(*,*)'Reading observed flows, substituted flows, and climate files...'
	WRITE(log_unit,*)'Reading observed flows, substituted flows, and climate files...'

	CALL read_climatology
    WRITE(log_unit,*)'CLIMED OK'

    IF(substitution_count>0)THEN !If the input setup identified that streamflow substitution is being done
		CALL read_substitution_flows
	ENDIF
	WRITE(log_unit,*)'QSUBS OK'

	! Hydrodynamic modeling:
    If (inertial_routing_enabled==1) THEN
        routing_method=1
    Else
        routing_method=0
    end if

	inertial_catchment_count=sum(routing_method) ! Test
	If(routing_method(1)==1)THEN
        WRITE(*,*)'Reading Floodplain data...'
	    WRITE(log_unit,*)'Reading Floodplain data...'

	    !Subroutine for reading the file with a table containing a table of water-depth vs. area at each MiniBasin obtained by DEM preprocessing (File: cota_area.flp)
        CALL read_floodplain_binary_data
	    WRITE(log_unit,*)'FLOODPLAIN READ OK'
	ENDIF

!  End of subroutines related to input files that are read only once reading and MGB variables allocation

    WRITE(*,*)'Calculating river geometry information...'
    WRITE(log_unit,*)'Calculating river geometry information...'
	CALL calculate_catchment_parameters
	WRITE(*,*)'PARCEL OK'
	WRITE(log_unit,*)'PARCEL Routine OK'
	CALL calculate_muskingum_cunge_parameters
    WRITE(log_unit,*)'PARCUNGE Routine OK'
    WRITE(*,*)'PARCUNGE OK'

    If(routing_method(1)==1)THEN
	    CALL build_flood_topology
	    WRITE(log_unit,*)'FLOOD TOPOLOGY OK'
	    WRITE(*,*)'FLOOD TOPOLOGY OK'
	    CALL build_floodplain_tables
        WRITE(log_unit,*)'FLOOD TAB OK'
        WRITE(*,*)'FLOOD TAB OK OK'
        ! Reservoir substitutions use a separate downstream-boundary map.
        routing_downstream_catchment=downstream_catchment
    ENDIF

!  End of subroutines that calculates Unit-catchments, rivers channels, and floodplains characteristics

!  Openning of MGB input files that are read during the simulation
    WRITE(*,*)'Opening input meteorological files...'
    WRITE(log_unit,*)'Opening input meteorological files...'
	call manage_meteorological_input_files(1)

!  End of openning MGB-IPH main input and output files that are read and written over the simulation

!  Ask for verification
!  Informs the model general setup
    WRITE(log_unit,*)'Input data reading process ended'
    WRITE(log_unit,*)''
    WRITE(log_unit,'(A30,I8)')'Number of catchments:',catchment_count
    WRITE(log_unit,'(A30,I8)')'Number of subbasins:',subbasin_count
    WRITE(log_unit,'(A30,I8)')'Number of HRUs:',hru_count
    WRITE(log_unit,'(A30,I6,"-",I2.2,"-",I2.2," ",I2.2,":",I2.2)')'Start date:',year,month,day,hour,minute
    WRITE(log_unit,'(A30,F16.2)')'Time step (s):',model_timestep_seconds
    WRITE(log_unit,'(A30,I8)')'Number of time steps:',timestep_count
    WRITE(log_unit,'(A30,I8)')'Number of substitution gauges:',substitution_count
    WRITE(log_unit,'(A30,I8)')'Number of climate gauges:',climate_cell_count
    WRITE(log_unit,'(A30,I8)')'Number of climate regions:',climate_region_count
    WRITE(log_unit,'(A30,2I8)')'Sim. interval for subasins:',first_subbasin,last_subbasin
    write(log_unit,*)''
    WRITE(log_unit,*),'Opt. Monthly radiation (0=sun.hours; 1=sun.perc; 2=radiation):'
    WRITE(log_unit,'(A30,I8)')'FLAG_CLI_OPT:',monthly_radiation_option
    WRITE(log_unit,'(A40,I8)')'Reservoir substitution flag (0=no; 1=yes):',reservoir_substitution_enabled
    WRITE(log_unit,'(A40,I8)')'Inertial routing Flag (0=no; 1=yes):',inertial_routing_enabled
    WRITE(log_unit,'(A40,I8)')'Number of threads for OMP parallel:',thread_count
    WRITE(log_unit,'(A40,I8)')'Pseudo 2D routing Flag (0=no; 1=yes):',pseudo_two_d_enabled
    WRITE(log_unit,'(A40,I8)')'Read HotStart values: (0=no; 1=yes)', read_hotstart_mode
    WRITE(log_unit,'(A40,I8)')'Write HotStart values (0=no; 1=yes):',write_hotstart_mode
    WRITE(log_unit,'(A40,F10.2)')'Alpha for Inertial routing:',courant_alpha
    WRITE(log_unit,'(A40,F10.6)')'Downstream Bound.Cond: (m/m)',downstream_water_surface_slope
    write(log_unit,*)''
    WRITE(log_unit,*)'PLEASE VERIFY INPUT INFORMATION AND PRESS ENTER TO START RUN...'
    WRITE(log_unit,*)''

    WRITE(*,*)'Input data reading process ended'
    WRITE(*,*)''
    WRITE(*,'(A30,I8)')'Number of catchments:',catchment_count
    WRITE(*,'(A30,I8)')'Number of subbasins:',subbasin_count
    WRITE(*,'(A30,I8)')'Number of HRUs:',hru_count
    WRITE(*,'(A30,I6,"-",I2.2,"-",I2.2," ",I2.2,":",I2.2)')'Start date:',year,month,day,hour,minute
    WRITE(*,'(A30,F16.2)')'Time step (s):',model_timestep_seconds
    WRITE(*,'(A30,I8)')'Number of time steps:',timestep_count
    WRITE(*,'(A30,I8)')'Number of substitution gauges:',substitution_count
    WRITE(*,'(A30,I8)')'Number of climate gauges:',climate_cell_count
    WRITE(*,'(A30,I8)')'Number of climate regions:',climate_region_count
    WRITE(*,'(A30,2I8)')'Sim. interval for subasins:',first_subbasin,last_subbasin
    write(*,*)
    WRITE(*,*),'Opt. Monthly radiation (0=sun.hours; 1=sun.perc; 2=radiation):'
    WRITE(*,'(A30,I8)')'MONTH_CLI_OPT:',monthly_radiation_option
    write(*,*)
    WRITE(*,'(A40,I8)')'Reservoir substitution flag (0=no; 1=yes):',reservoir_substitution_enabled
    WRITE(*,'(A40,I8)')'Inertial routing Flag (0=no; 1=yes):',inertial_routing_enabled
    WRITE(*,'(A40,I8)')'Number of threads for OMP parallel:',thread_count
    WRITE(*,'(A40,I8)')'Read HotStart values: (0=no; 1=yes)', read_hotstart_mode
    WRITE(*,'(A40,I8)')'Write HotStart values (0=no; 1=yes):',write_hotstart_mode
    WRITE(*,'(A40,F10.2)')'Alpha for Inertial routing:',courant_alpha
    WRITE(*,'(A40,F10.6)')'Downstream Bound.Cond: (m/m)',downstream_water_surface_slope
    write(*,*)
    IF (noninteractive) THEN
        WRITE(*,*)'NON-INTERACTIVE MODE ENABLED. STARTUP CONFIRMATION SKIPPED.'
        WRITE(log_unit,*)'NON-INTERACTIVE MODE ENABLED. STARTUP CONFIRMATION SKIPPED.'
    ELSE
        WRITE(*,*)'PLEASE VERIFY INPUT INFORMATION AND PRESS ENTER TO START RUN...'
        WRITE(*,*)''
        WRITE(*,*)'REMEMBER THAT RESULT FILES WILL BE OVERWRITTEN. ARE YOU SURE?'
        READ(*,*)
    ENDIF

    WRITE(*,*)'SIMULATION MODE' !Warns about the chosen mode
	WRITE(log_unit,*)'SIMULATION MODE' !Warns about the chosen mode
	CALL run_simulation

!  After running the model, finish the time count, close all files, and clean all variables

    call manage_meteorological_input_files(0)

	CALL allocate_model_state(1)

! End of closings and cleanings

! Inform the user that the model run is over and informations about total processing time

	WRITE(*,*)'MGB MODEL ENDED SUCCESSFULLY'
	WRITE(log_unit,*)'MGB MODEL ENDED SUCCESSFULLY'
	print *, char(7)
    CALL SYSTEM_CLOCK(COUNT=clock_end)
    IF (clock_end >= clock_start) THEN
        clock_ticks = clock_end - clock_start
    ELSE
        clock_ticks = (clock_max - clock_start + 1) + clock_end
    ENDIF
    elapsed_seconds = DBLE(clock_ticks) / DBLE(clock_rate)
	WRITE(*,*)'TOTAL TIME:',elapsed_seconds/60.,'MINUTES'
	WRITE(log_unit,*)'TOTAL TIME:',elapsed_seconds/60.,'MINUTES'

    IF (noninteractive) THEN
        WRITE(*,*)'NON-INTERACTIVE MODE ENABLED. EXIT PROMPT SKIPPED.'
        WRITE(log_unit,*)'NON-INTERACTIVE MODE ENABLED. EXIT PROMPT SKIPPED.'
    ELSE
	    WRITE(*,*)'PRESS ENTER TO CLOSE...'
	    WRITE(log_unit,*)'PRESS ENTER TO CLOSE...'
    ENDIF

    CLOSE(log_unit)

    IF (.NOT. noninteractive) THEN
	    READ(*,*)
    ENDIF

	END
