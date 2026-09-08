! SPDX-License-Identifier: GPL-3.0-or-later
! Copyright (C) 2019 Hidrologia de Grande Escala (HGE)

! Read water-balance and inertial-routing state from hotstart files.

    SUBROUTINE read_hotstart
	USE model_state
	USE inertial_state
    use utils_date, only: format_date_string

	IMPLICIT NONE
    integer:: state_index,state_variable_count,reach_index
    real(4),allocatable:: water_balance_state(:)
    real*8,allocatable:: inertial_state_vector(:)
    character(len=10) :: hotstart_filename
    LOGICAL :: file_exists

	state_variable_count=(catchment_count*hru_count)+(6*catchment_count)+(catchment_count*hru_count)+(sum(muskingum_reach_count)+catchment_count)+catchment_count !
	allocate(water_balance_state(state_variable_count))

    !Set the current datestring to read file (skipping minute)
    hotstart_filename = format_date_string(year,month,day,hour)

    !Check if the hotstart exists
     INQUIRE(FILE=hotstart_input_directory // 'statevars_wb_'// trim(hotstart_filename) // '.hot', EXIST=file_exists)
        IF(.NOT. file_exists) then
            write(*,*)'A problem occurred when reading statevars_wb_'// trim(hotstart_filename) // '.hot. File does not exist, simulation aborted.'
            ERROR STOP 'Missing water balance hotstart file'
      endif

    write(*,*)
    write(*,*)'Reading Water Balance State Variables for: ',hotstart_filename

    open(water_balance_hotstart_unit,FILE=hotstart_input_directory // 'statevars_wb_'// trim(hotstart_filename) // '.hot',STATUS='old',RECL=state_variable_count,FORM='UNFORMATTED',ACCESS='DIRECT')

	read(water_balance_hotstart_unit,REC=1) (water_balance_state(state_index),state_index=1,state_variable_count) ! Reading state variables:

    state_index=0
	do catchment_index=1,catchment_count
		do hru_index=1,hru_count
			state_index=state_index+1
			soil_water_storage(catchment_index,hru_index)=water_balance_state(state_index) !Reading Soil Moisture
		enddo
	enddo
	do catchment_index=1,catchment_count
			state_index=state_index+1
			groundwater_storage(catchment_index)=water_balance_state(state_index) !Reading water in baseflow reservoir
	enddo
	do catchment_index=1,catchment_count
			state_index=state_index+1
			subsurface_storage(catchment_index)=water_balance_state(state_index) !Reading water in subsurface reservoir
	enddo
	do catchment_index=1,catchment_count
			state_index=state_index+1
			surface_storage(catchment_index)=water_balance_state(state_index) !Reading water surface volume
	enddo
	do catchment_index=1,catchment_count
			state_index=state_index+1
			air_temperature(catchment_index)=water_balance_state(state_index)  !Reading Temperature
	enddo
	do catchment_index=1,catchment_count
			state_index=state_index+1
			incoming_q_current(catchment_index)=water_balance_state(state_index) !Reading Flow entering into the catchment
	enddo
	do catchment_index=1,catchment_count
			state_index=state_index+1
			outgoing_q_current(catchment_index)=water_balance_state(state_index) !Reading Flow going out of catchment
	enddo
	do catchment_index=1,catchment_count
		do hru_index=1,hru_count
			state_index=state_index+1
			interception_storage(catchment_index,hru_index)=water_balance_state(state_index)  !Reading Canopy interception volume
		enddo
	enddo
	do catchment_index=1,catchment_count
		do reach_index=1,muskingum_reach_count(catchment_index)+1
			state_index=state_index+1
			initial_river_q(catchment_index,reach_index)=water_balance_state(state_index)  !Reading Canopy interception volume
		enddo
	enddo
	do catchment_index=1,catchment_count
			state_index=state_index+1
			catchment_q_current(catchment_index)=water_balance_state(state_index)   !Reading Runoff generation at each cell
	enddo

	close(water_balance_hotstart_unit)
    deallocate(water_balance_state)

    state_variable_count=(9*catchment_count)! Variables from inertial routing
    allocate(inertial_state_vector(state_variable_count))

    write(*,*)'Reading Hydraulic State Variables for: ',hotstart_filename
    write(*,*)

    open(inertial_hotstart_unit,FILE=hotstart_input_directory // 'statevars_inertial_'// trim(hotstart_filename) // '.hot',STATUS='old',RECL=(state_variable_count*2),FORM='UNFORMATTED',ACCESS='DIRECT')
    read(inertial_hotstart_unit,REC=1) (inertial_state_vector(state_index),state_index=1,state_variable_count) ! Reading state variables:

    state_index=0
    do catchment_index=1,catchment_count
			state_index=state_index+1
			inertial_q(catchment_index)=inertial_state_vector(state_index) !Streamflow at catchment (catchment_index)
    enddo

    do catchment_index=1,catchment_count
			state_index=state_index+1
			water_depth(catchment_index)=inertial_state_vector(state_index) !Water depth at catchment (catchment_index)
	enddo

    do catchment_index=1,catchment_count
			state_index=state_index+1
			water_surface_elevation(catchment_index)=inertial_state_vector(state_index) !Water elevation at catchment (catchment_index)
    enddo

    do catchment_index=1,catchment_count
			state_index=state_index+1
			previous_water_volume(catchment_index)=inertial_state_vector(state_index) !Previous Water storage at catchment (catchment_index)
    enddo

    do catchment_index=1,catchment_count
			state_index=state_index+1
			current_water_volume(catchment_index)=inertial_state_vector(state_index) !Actual Water storage at catchment (catchment_index)
    enddo

    do catchment_index=1,catchment_count
			state_index=state_index+1
			current_flooded_area(catchment_index)=inertial_state_vector(state_index) !Flooded Area at catchment (catchment_index)
    enddo

    do catchment_index=1,catchment_count
			state_index=state_index+1
			stage_table_index(catchment_index)=int(inertial_state_vector(state_index)) !Index of Volume level at catchment (catchment_index)
    enddo

    do catchment_index=1,catchment_count
			state_index=state_index+1
			face_q(catchment_index)=inertial_state_vector(state_index) !Streamflow coming (or leaving) the catchment through connections
    enddo

    do catchment_index=1,catchment_count
			state_index=state_index+1
			neighbor_q(catchment_index)=inertial_state_vector(state_index) !Updated flow for interconnections (signal can be positive or negative)
    enddo

    deallocate(inertial_state_vector)
    close(inertial_hotstart_unit)

	RETURN
	END
