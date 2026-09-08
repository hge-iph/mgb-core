! SPDX-License-Identifier: GPL-3.0-or-later
! Copyright (C) 2019 Hidrologia de Grande Escala (HGE)

! Execute the model timestep loop.

	SUBROUTINE run_model

	USE model_state
	USE inertial_state
    use utils_time, only: calculate_julian_day, convert_julian_day_to_calendar

	IMPLICIT NONE

    integer, parameter :: real_kind=8
    real maximum_domain_q, completion_percentage ! Current statistics

    Write(*,*)' IT         Date       Max flow (m3/s)   % Complete'

    ! Initialize model time step
	timestep_index=0

    DO WHILE (timestep_index<timestep_count)

        ! Advance time
		timestep_index=timestep_index+1

        if (write_hotstart_mode == 2 .OR. write_hotstart_mode == 3) then
           call write_hotstart
        end if

        ! compute calendar date
        call convert_julian_day_to_calendar(julian_day,year,month,day,hour,minute)

        ! Get simulation statistics
        maximum_domain_q = maxval(outgoing_q_current)  ! Maximum flow for the entire model domain
        completion_percentage = (100. * real(timestep_index)/real(timestep_count)) !% of simulation completion
        WRITE(*,71) timestep_index,year,month,day,hour,minute,maximum_domain_q,completion_percentage

		! Reads climate data
		previous_air_temperature=air_temperature
        CALL read_meteorological_forcing(month,timestep_index) ! Read rainfall and other met variables

        ! Perform vertical water balance
		CALL update_catchment_water_balance

		if (routing_method(1)==0) then
		    CALL route_muskingum_cunge_network
		endif

		! Calculates lateral inflow
        do catchment_index=1,catchment_count
		    catchment_q_current(catchment_index) = groundwater_q(catchment_index) + subsurface_q(catchment_index) + surface_q(catchment_index) !sums surface, subsurface and
        enddo

        if (inertial_catchment_count>0) then
            CALL route_inertial_flow
        endif

        ! Store single-precision output records for this timestep.
        DO catchment_index=1,catchment_count
            q_river_output(catchment_index)=inertial_q(catchment_index)
            water_surface_elevation_output(catchment_index)=water_surface_elevation(catchment_index)
            total_water_storage_output(catchment_index) =total_water_storage(catchment_index)
            flooded_area_output(catchment_index)=current_flooded_area(catchment_index)
            catchment_q_output(catchment_index)=catchment_q_current(catchment_index)
            hand_output(catchment_index) = water_surface_elevation(catchment_index) - REAL(stage_table(1,catchment_index)) - REAL(bankfull_depth(catchment_index))
            potential_open_water_et_output(catchment_index) = potential_open_water_et(catchment_index)
        ENDDO

        CALL write_model_outputs

        ! Advance Julian date for next time step
        julian_day = calculate_julian_day(year,month,day,hour,minute) &
                      + (real(model_timestep_seconds,real_kind) / 86400.0_real_kind)

    ENDDO !End time loop

71  FORMAT(I5,"    ",I4,"-",I2.2,"-",I2.2," ",I2.2,":",I2.2,"  ",f10.1,"      ",f6.2," %")
75	FORMAT(I6,13F10.4)
66	FORMAT(<catchment_count>F10.4)


	RETURN
	END SUBROUTINE run_model
