! SPDX-License-Identifier: GPL-3.0-or-later
! Copyright (C) 2019 Hidrologia de Grande Escala (HGE)

! Route flow through the drainage network with the Muskingum-Cunge method.

	SUBROUTINE route_muskingum_cunge_network
	!This Sub-Routine calculates the flow routing in drainage network .

	USE model_state
	USE inertial_state

	IMPLICIT NONE
	REAL reach_step_length		                                                       !Space-step
	REAL muskingum_x,muskingum_k		                                                   !catchment_x E K: Muskingum-Cunge parameters
	REAL incoming_q_value_previous,incoming_q_value_current
	REAL outgoing_q_value_previous,outgoing_q_value_current
	REAL routing_timestep,coefficient_denominator,routing_volume_total
	INTEGER downstream_index                                                        !Auxiliary variables
	INTEGER reach_count,interval_count
	REAL coefficient_1,coefficient_2,coefficient_3 	                                                   !Muskingum-Cunge coefficients

    real depth_iteration_previous,depth_iteration_current                                             !To compute velocities

	!Counters
	INTEGER muskingum_interval_count,interval_index
	INTEGER substitution_search_index,substitution_index

	IF(muskingum_timestep(catchment_count)<0.00001)STOP 'Something wrong in time-step on rede.f90'
	muskingum_interval_count=model_timestep_seconds/muskingum_timestep(catchment_count)

    !Initial conditions: initialize_model_state.f90

	!In each time-step variables substitution_search_index+1 are changed to substitution_search_index
	DO catchment_index=1,catchment_count
		incoming_q_previous(catchment_index)=incoming_q_current(catchment_index)
		outgoing_q_previous(catchment_index)=outgoing_q_current(catchment_index)
		incoming_q_current(catchment_index)=0.0
		outgoing_q_current(catchment_index)=0.0
		incoming_groundwater_fraction_previous(catchment_index)=incoming_groundwater_fraction_current(catchment_index)
		incoming_subsurface_fraction_previous(catchment_index)=incoming_subsurface_fraction_current(catchment_index)
		incoming_surface_fraction_previous(catchment_index)=incoming_surface_fraction_current(catchment_index)
		outgoing_groundwater_fraction_previous(catchment_index)=outgoing_groundwater_fraction_current(catchment_index)
		outgoing_subsurface_fraction_previous(catchment_index)=outgoing_subsurface_fraction_current(catchment_index)
		outgoing_surface_fraction_previous(catchment_index)=outgoing_surface_fraction_current(catchment_index)
		catchment_q_previous(catchment_index)=catchment_q_current(catchment_index)
	ENDDO
	incoming_q_boundary=0.0
	outgoing_q_boundary=0.0

	DO catchment_index=1,catchment_count


		if (substitution_enabled(catchment_index)==1) cycle ! RP:  Does not compute upstream catchments of replacement catchments

		subbasin_index=catchment_subbasin(catchment_index)

		!code used to calibraton
		IF((subbasin_index<first_subbasin).OR.(subbasin_index>last_subbasin))CYCLE ! Manual controls for specialized calibration

		catchment_q_current(catchment_index)=groundwater_q(catchment_index)+subsurface_q(catchment_index)+surface_q(catchment_index) !Total of flow in each catchment


		! Flag used to HD model:
		IF (routing_method(catchment_index)==1) CYCLE


        !Catchment with river
		IF(muskingum_reach_count(catchment_index).GT.0)THEN

			routing_timestep=muskingum_timestep(catchment_index)
			reach_step_length=river_length(catchment_index)*1000./muskingum_reach_count(catchment_index)
			muskingum_k=reach_step_length/wave_celerity(catchment_index)
			muskingum_x=0.5*(1.0-(reference_q(catchment_index)/(river_width(catchment_index)*river_slope(catchment_index)*wave_celerity(catchment_index)*reach_step_length)))

			! Verification of catchment_x and K values:
			! Enforce the stable Muskingum-Cunge range 0.2 <= x <= 0.5.
			if (muskingum_x<0.2) then
				muskingum_x=0.2
				muskingum_k=routing_timestep/(3.125*muskingum_x**1.25) ! Tucci, equation 4.111
			elseif(muskingum_x<0.4) then
			elseif (muskingum_x<0.5) then

			else
				muskingum_x=0.5
				muskingum_k=routing_timestep
			endif


			coefficient_denominator=2.*muskingum_k*(1.-muskingum_x)+routing_timestep
			coefficient_1=(2.*muskingum_k*muskingum_x+routing_timestep)/coefficient_denominator
			coefficient_2=(routing_timestep-2.*muskingum_k*muskingum_x)/coefficient_denominator
			coefficient_3=(2.*muskingum_k*(1.-muskingum_x)-routing_timestep)/coefficient_denominator

            !Lateral inflow are used upstream of same catchment

			!Proportions to Flows
			incoming_groundwater_fraction_current(catchment_index)=incoming_groundwater_fraction_current(catchment_index)*incoming_q_current(catchment_index) !underground flow
			incoming_subsurface_fraction_current(catchment_index)=incoming_subsurface_fraction_current(catchment_index)*incoming_q_current(catchment_index) !subsurface flow
			incoming_surface_fraction_current(catchment_index)=incoming_surface_fraction_current(catchment_index)*incoming_q_current(catchment_index) !runoff

			incoming_q_current(catchment_index)=incoming_q_current(catchment_index)+surface_q(catchment_index)+subsurface_q(catchment_index)+groundwater_q(catchment_index)


			!MUSKINGUM-CUNGE Boundary conditions
			DO interval_index=1,muskingum_interval_count+1
				incoming_q_boundary(catchment_index,interval_index)=incoming_q_boundary(catchment_index,interval_index)+catchment_q_previous(catchment_index)+(interval_index-1)*(catchment_q_current(catchment_index)-catchment_q_previous(catchment_index))/muskingum_interval_count
			ENDDO

			!Update proportions
			incoming_groundwater_fraction_current(catchment_index)=(incoming_groundwater_fraction_current(catchment_index)+groundwater_q(catchment_index))/incoming_q_current(catchment_index)
			incoming_subsurface_fraction_current(catchment_index)=(incoming_subsurface_fraction_current(catchment_index)+subsurface_q(catchment_index))/incoming_q_current(catchment_index)
			incoming_surface_fraction_current(catchment_index)=(incoming_surface_fraction_current(catchment_index)+surface_q(catchment_index))/incoming_q_current(catchment_index)

			!Update volume proportions
			groundwater_routing_volume(catchment_index)=groundwater_routing_volume(catchment_index)+incoming_groundwater_fraction_current(catchment_index)*incoming_q_current(catchment_index)*model_timestep_seconds	!groundwater_routing_volume(catchment_index)=groundwater_routing_volume(catchment_index)+incoming_groundwater_fraction_current(catchment_index)*incoming_q_current(catchment_index)*3600.*24.
			subsurface_routing_volume(catchment_index)=subsurface_routing_volume(catchment_index)+incoming_subsurface_fraction_current(catchment_index)*incoming_q_current(catchment_index)*model_timestep_seconds	!subsurface_routing_volume(catchment_index)=subsurface_routing_volume(catchment_index)+incoming_subsurface_fraction_current(catchment_index)*incoming_q_current(catchment_index)*3600.*24.
			surface_routing_volume(catchment_index)=surface_routing_volume(catchment_index)+incoming_surface_fraction_current(catchment_index)*incoming_q_current(catchment_index)*model_timestep_seconds	!surface_routing_volume(catchment_index)=surface_routing_volume(catchment_index)+incoming_surface_fraction_current(catchment_index)*incoming_q_current(catchment_index)*3600.*24.

			incoming_q_value_previous=incoming_q_previous(catchment_index)
			incoming_q_value_current=incoming_q_current(catchment_index)
			outgoing_q_value_previous=outgoing_q_previous(catchment_index)
			reach_count=muskingum_reach_count(catchment_index)
			interval_count=model_timestep_seconds/muskingum_timestep(catchment_index)			                !interval_count=3600.*24./muskingum_timestep(catchment_index)

			CALL route_muskingum_cunge(outgoing_q_value_previous,outgoing_q_value_current, &
				reach_count,interval_count,coefficient_1,coefficient_2,coefficient_3)
			outgoing_q_current(catchment_index)=outgoing_q_value_current


			!Update volume proportions
			routing_volume_total=groundwater_routing_volume(catchment_index)+subsurface_routing_volume(catchment_index)+surface_routing_volume(catchment_index)
			outgoing_groundwater_fraction_current(catchment_index)=groundwater_routing_volume(catchment_index)/routing_volume_total
			outgoing_subsurface_fraction_current(catchment_index)=subsurface_routing_volume(catchment_index)/routing_volume_total
			outgoing_surface_fraction_current(catchment_index)=surface_routing_volume(catchment_index)/routing_volume_total
			groundwater_routing_volume(catchment_index)=MAX(0.0,groundwater_routing_volume(catchment_index)-outgoing_groundwater_fraction_current(catchment_index)*outgoing_q_current(catchment_index)*model_timestep_seconds)	!groundwater_routing_volume(catchment_index)=MAX(0.0,groundwater_routing_volume(catchment_index)-outgoing_groundwater_fraction_current(catchment_index)*outgoing_q_current(catchment_index)*3600.*24.)
			subsurface_routing_volume(catchment_index)=MAX(0.0,subsurface_routing_volume(catchment_index)-outgoing_subsurface_fraction_current(catchment_index)*outgoing_q_current(catchment_index)*model_timestep_seconds)	!subsurface_routing_volume(catchment_index)=MAX(0.0,subsurface_routing_volume(catchment_index)-outgoing_subsurface_fraction_current(catchment_index)*outgoing_q_current(catchment_index)*3600.*24.)
			surface_routing_volume(catchment_index)=MAX(0.0,surface_routing_volume(catchment_index)-outgoing_surface_fraction_current(catchment_index)*outgoing_q_current(catchment_index)*model_timestep_seconds)	!surface_routing_volume(catchment_index)=MAX(0.0,surface_routing_volume(catchment_index)-outgoing_surface_fraction_current(catchment_index)*outgoing_q_current(catchment_index)*3600.*24.)

			!Flows routing in each catchment are used as upstream boundary in downstream catchment
			downstream_index=downstream_catchment(catchment_index)

			if (downstream_index>0) then

				incoming_groundwater_fraction_current(downstream_index)=incoming_groundwater_fraction_current(downstream_index)*incoming_q_current(downstream_index) !underground flow
				incoming_subsurface_fraction_current(downstream_index)=incoming_subsurface_fraction_current(downstream_index)*incoming_q_current(downstream_index) !subsurface flow
				incoming_surface_fraction_current(downstream_index)=incoming_surface_fraction_current(downstream_index)*incoming_q_current(downstream_index) !runoff

				incoming_q_current(downstream_index)=incoming_q_current(downstream_index)+outgoing_q_current(catchment_index)


				!Muskingum-Cunge boundary condition
				!Tests if calculated flow must be replaced by flow by file
				substitution_index=0
				DO substitution_search_index=1,substitution_count
					IF(timestep_index>1.AND.catchment_index==substitution_catchment(substitution_search_index))THEN
						substitution_index=substitution_search_index
						EXIT
					ELSE
						substitution_index=0
					ENDIF
				ENDDO

				IF(substitution_index>0)THEN
					IF(substituted_q(substitution_index,timestep_index)<0.0)then !Problem in read data
						incoming_q_current(downstream_index)=incoming_q_current(downstream_index) !Uses calculated flow
						DO interval_index=1,muskingum_interval_count+1
							incoming_q_boundary(downstream_index,interval_index)=incoming_q_boundary(downstream_index,interval_index)+outgoing_q_boundary(catchment_index,interval_index) !update boundary
						ENDDO
					ELSE !use flow from file
						incoming_q_current(downstream_index)=substituted_q(substitution_index,timestep_index)
						DO interval_index=1,muskingum_interval_count+1 !Replaces calculated flow by read flow (from file)
							incoming_q_boundary(downstream_index,interval_index)=substituted_q(substitution_index,timestep_index-1)+(interval_index-1)*(substituted_q(substitution_index,timestep_index)-substituted_q(substitution_index,timestep_index-1))/muskingum_interval_count
						ENDDO
					ENDIF
				ELSE
					DO interval_index=1,muskingum_interval_count+1
						incoming_q_boundary(downstream_index,interval_index)=incoming_q_boundary(downstream_index,interval_index)+outgoing_q_boundary(catchment_index,interval_index) !Update boundary
					ENDDO
				ENDIF

				!Update proportions
				incoming_groundwater_fraction_current(downstream_index)=(incoming_groundwater_fraction_current(downstream_index)+outgoing_groundwater_fraction_current(catchment_index)*outgoing_q_current(catchment_index))/incoming_q_current(downstream_index)
				incoming_subsurface_fraction_current(downstream_index)=(incoming_subsurface_fraction_current(downstream_index)+outgoing_subsurface_fraction_current(catchment_index)*outgoing_q_current(catchment_index))/incoming_q_current(downstream_index)
				incoming_surface_fraction_current(downstream_index)=(incoming_surface_fraction_current(downstream_index)+outgoing_surface_fraction_current(catchment_index)*outgoing_q_current(catchment_index))/incoming_q_current(downstream_index)
			endif

        !headboard catchment
		ELSE
			reach_step_length=0.0
			muskingum_k=0.0
			muskingum_x=0.0

			outgoing_q_current(catchment_index)=groundwater_q(catchment_index)+subsurface_q(catchment_index)+surface_q(catchment_index)
			outgoing_groundwater_fraction_current(catchment_index)=groundwater_q(catchment_index)/outgoing_q_current(catchment_index)
			outgoing_subsurface_fraction_current(catchment_index)=subsurface_q(catchment_index)/outgoing_q_current(catchment_index)
			outgoing_surface_fraction_current(catchment_index)=surface_q(catchment_index)/outgoing_q_current(catchment_index)

            !Flows routing in each catchment are used as upstream boundary in downstream catchment
			downstream_index=downstream_catchment(catchment_index)

			if (downstream_index>0) then

				incoming_groundwater_fraction_current(downstream_index)=incoming_groundwater_fraction_current(downstream_index)*incoming_q_current(downstream_index) !underground flow
				incoming_subsurface_fraction_current(downstream_index)=incoming_subsurface_fraction_current(downstream_index)*incoming_q_current(downstream_index) !subsurface flow
				incoming_surface_fraction_current(downstream_index)=incoming_surface_fraction_current(downstream_index)*incoming_q_current(downstream_index) !runoff

				incoming_q_current(downstream_index)=incoming_q_current(downstream_index)+surface_q(catchment_index)+subsurface_q(catchment_index)+groundwater_q(catchment_index)

				!MUSKINGUM-CUNGE boundary condition
				DO interval_index=1,muskingum_interval_count+1
					incoming_q_boundary(downstream_index,interval_index)=incoming_q_boundary(downstream_index,interval_index)+(outgoing_q_previous(catchment_index)+(interval_index-1)*(outgoing_q_current(catchment_index)-outgoing_q_previous(catchment_index))/muskingum_interval_count)
				ENDDO

				!update proportions
				incoming_groundwater_fraction_current(downstream_index)=(incoming_groundwater_fraction_current(downstream_index)+groundwater_q(catchment_index))/incoming_q_current(downstream_index)
				incoming_subsurface_fraction_current(downstream_index)=(incoming_subsurface_fraction_current(downstream_index)+subsurface_q(catchment_index))/incoming_q_current(downstream_index)
				incoming_surface_fraction_current(downstream_index)=(incoming_surface_fraction_current(downstream_index)+surface_q(catchment_index))/incoming_q_current(downstream_index)
			endif
        ENDIF

		!STORE OUTPUT INFORMATION
        inertial_q(catchment_index)=outgoing_q_current(catchment_index) !Saves in inertial_q #v1.41
		incremental_q_output(catchment_index)=catchment_q_current(catchment_index) !incremental_q_output(catchment_index,timestep_index)=catchment_q_current(catchment_index)
		groundwater_q_output(catchment_index)=groundwater_q(catchment_index) !groundwater_q_output(catchment_index,timestep_index)=groundwater_q(catchment_index)


        !Iteration to find river velocity by inversion of manning eq.
        depth_iteration_previous=3.0
        do
            depth_iteration_current=((outgoing_q_current(catchment_index)*manning_n(catchment_index)/river_slope(catchment_index)**0.5)**0.6)*((river_width(catchment_index)+2*depth_iteration_previous)**(0.4))/river_width(catchment_index)
            if (abs(depth_iteration_current-depth_iteration_previous)<0.005) exit
            depth_iteration_previous=depth_iteration_current
        enddo

        flow_velocity(catchment_index)=outgoing_q_current(catchment_index)/(depth_iteration_current*river_width(catchment_index))

	ENDDO
	RETURN
	END SUBROUTINE route_muskingum_cunge_network
