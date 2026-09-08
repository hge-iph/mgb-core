! SPDX-License-Identifier: GPL-3.0-or-later
! Copyright (C) 2019 Hidrologia de Grande Escala (HGE)

! Write water-balance and inertial-routing state to hotstart files.

    SUBROUTINE write_hotstart
	USE model_state
    USE inertial_state
    use utils_time, only: convert_julian_day_to_calendar
    use utils_date, only: format_date_string

	IMPLICIT NONE
    integer state_index,state_variable_count,reach_index
    real(4),allocatable:: water_balance_state(:)
    real*8,allocatable:: inertial_state_vector(:)
    character(len=10) :: hotstart_filename

	state_variable_count=(catchment_count*hru_count)+(6*catchment_count)+(catchment_count*hru_count)+(sum(muskingum_reach_count)+catchment_count)+catchment_count !

    !For option 1, model state variables are saved only at the end of simulation (state_index.e. They will allow starting the MGB one timestep after the end date)
    if (write_hotstart_mode == 1) then

        ! compute calendar date
        call convert_julian_day_to_calendar(julian_day,year,month,day,hour,minute)

    !For option 2, check if the current timestep_index is flagged to save MGB initial conditions for the beginning of each time step.
    !For option 3, model state variables will be saved for the beginning of each time step, and also for the end of simulation. write_hotstart_mode will be automatically set to 1 at the end of simulation
    endif

    !Set the current datestring to save file (skipping minute)
    hotstart_filename = format_date_string(year,month,day,hour)

    open(water_balance_hotstart_unit,FILE=hotstart_input_directory // 'statevars_wb_'// trim(hotstart_filename) // '.hot',STATUS='unknown',RECL=state_variable_count,FORM='UNFORMATTED',ACCESS='DIRECT')

    write(*,*)'Writing Water Balance State Variables for: ',hotstart_filename

    allocate(water_balance_state(state_variable_count))
	! Writing state variables:
	state_index=0
	do catchment_index=1,catchment_count
		do hru_index=1,hru_count
			state_index=state_index+1
			water_balance_state(state_index)=soil_water_storage(catchment_index,hru_index) !Soil Water for each HRU
		enddo
	enddo
	do catchment_index=1,catchment_count
			state_index=state_index+1
			water_balance_state(state_index)=groundwater_storage(catchment_index) !Reservoir Volume for baseflow
	enddo
	do catchment_index=1,catchment_count
			state_index=state_index+1
			water_balance_state(state_index)=subsurface_storage(catchment_index) !Reservoir Volume for subsurface flow
	enddo
	do catchment_index=1,catchment_count
			state_index=state_index+1
			water_balance_state(state_index)=surface_storage(catchment_index) !Reservoir Volume for surface flow
	enddo
	do catchment_index=1,catchment_count
			state_index=state_index+1
			water_balance_state(state_index)=air_temperature(catchment_index) !Temperature in previous time step
	enddo
	do catchment_index=1,catchment_count
			state_index=state_index+1
			water_balance_state(state_index)=incoming_q_current(catchment_index) !Streamflow at upstream of catchments
	enddo
	do catchment_index=1,catchment_count
			state_index=state_index+1
			water_balance_state(state_index)=outgoing_q_current(catchment_index) !Streamflow at downstream of catchments
	enddo
	do catchment_index=1,catchment_count
		do hru_index=1,hru_count
			state_index=state_index+1
			water_balance_state(state_index)=interception_storage(catchment_index,hru_index) !Intercepted water stored on canopy reservoir
		enddo
	enddo
	do catchment_index=1,catchment_count
		do reach_index=1,muskingum_reach_count(catchment_index)+1
			state_index=state_index+1
			water_balance_state(state_index)=initial_river_q(catchment_index,reach_index)
		enddo
	enddo
	do catchment_index=1,catchment_count
			state_index=state_index+1
			water_balance_state(state_index)=catchment_q_current(catchment_index) !Runoff generated at catchment
	enddo

	write(water_balance_hotstart_unit,REC=1) (water_balance_state(state_index),state_index=1,state_variable_count)
    deallocate(water_balance_state)

	close(water_balance_hotstart_unit)

    state_variable_count=(9*catchment_count)! Variables from inertial routing

    write(*,*)'Writing Hydraulic State Variables for: ',hotstart_filename
    !All variables below are in double precision (Real*8)

    open(inertial_hotstart_unit,FILE=hotstart_input_directory // 'statevars_inertial_' // trim(hotstart_filename) // '.hot',STATUS='unknown',RECL=(state_variable_count*2),FORM='UNFORMATTED',ACCESS='DIRECT')

    allocate(inertial_state_vector(state_variable_count))

    state_index=0
    do catchment_index=1,catchment_count
			state_index=state_index+1
			inertial_state_vector(state_index)=inertial_q(catchment_index) !Streamflow at catchment (catchment_index)
    enddo

    do catchment_index=1,catchment_count
			state_index=state_index+1
			inertial_state_vector(state_index)=water_depth(catchment_index) !Water depth at catchment (catchment_index)
	enddo

    do catchment_index=1,catchment_count
			state_index=state_index+1
			inertial_state_vector(state_index)=water_surface_elevation(catchment_index) !Water elevation at catchment (catchment_index)
    enddo

    do catchment_index=1,catchment_count
			state_index=state_index+1
			inertial_state_vector(state_index)=previous_water_volume(catchment_index) !Previous Water storage at catchment (catchment_index)
    enddo

    do catchment_index=1,catchment_count
			state_index=state_index+1
			inertial_state_vector(state_index)=current_water_volume(catchment_index) !Actual Water storage at catchment (catchment_index)
    enddo

    do catchment_index=1,catchment_count
			state_index=state_index+1
			inertial_state_vector(state_index)=current_flooded_area(catchment_index) !Flooded Area at catchment (catchment_index)
    enddo

    do catchment_index=1,catchment_count
			state_index=state_index+1
			inertial_state_vector(state_index)=dble(stage_table_index(catchment_index)) !index of Volume level at catchment (catchment_index)
    enddo

    do catchment_index=1,catchment_count
			state_index=state_index+1
			inertial_state_vector(state_index)=face_q(catchment_index) !Streamflow coming (or leaving) the catchment through connections
    enddo

    do catchment_index=1,catchment_count
			state_index=state_index+1
			inertial_state_vector(state_index)=neighbor_q(catchment_index) !Updated flow for interconnections (signal can be positive or negative)
    enddo

    write(inertial_hotstart_unit,REC=1) (inertial_state_vector(state_index),state_index=1,state_variable_count)

    deallocate(inertial_state_vector)
    close(inertial_hotstart_unit)

	RETURN
	END
