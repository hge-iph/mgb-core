! SPDX-License-Identifier: GPL-3.0-or-later
! Copyright (C) 2019 Hidrologia de Grande Escala (HGE)

! Initialize hydrological and routing state.

	subroutine initialize_model_state

	USE model_state
	USE inertial_state

	implicit none

	integer downstream_index,substitution_index,routing_delay_seconds

	!Initial conditions

	! Intercepted volume:
	interception_storage=0.0
	! Soil moisture:
	DO catchment_index=1,catchment_count
		subbasin_index=catchment_subbasin(catchment_index)
		DO hru_index=1,hru_count
			soil_water_storage(catchment_index,hru_index)=max_soil_water_storage(subbasin_index,hru_index)*0.15 !Soil has 15% of water at the beginning of simulation
		ENDDO
	ENDDO
	! Volumes in Reservoirs:
	DO catchment_index=1,catchment_count
		subbasin_index=catchment_subbasin(catchment_index)
		groundwater_storage(catchment_index)=specific_baseflow(subbasin_index)*catchment_area(catchment_index)*groundwater_routing_coefficient(subbasin_index)*3600.
		subsurface_storage(catchment_index)=0.0
		surface_storage(catchment_index)=0.0

	ENDDO
	! Flow in reservoirs:
	DO catchment_index=1,catchment_count
		! Sub-catchment
		subbasin_index=catchment_subbasin(catchment_index)

		! Underground flow:
		routing_delay_seconds=groundwater_routing_coefficient(subbasin_index)*3600.
		groundwater_q(catchment_index)=groundwater_storage(catchment_index)/routing_delay_seconds
		! Subsurface flow:
		routing_delay_seconds=subsurface_routing_coefficient(subbasin_index)*concentration_time(catchment_index)
		subsurface_q(catchment_index)=subsurface_storage(catchment_index)/routing_delay_seconds
		! Runoff:
		routing_delay_seconds=surface_routing_coefficient(subbasin_index)*concentration_time(catchment_index)
		surface_q(catchment_index)=surface_storage(catchment_index)/routing_delay_seconds
	ENDDO

	!Temperature in the last day:
	air_temperature=20.0

	! Initialize river flows to zero; changing this assumption requires a model-change branch.

	incoming_q_current=0.0
	incoming_groundwater_fraction_current=0.0
	incoming_subsurface_fraction_current=0.0
	incoming_surface_fraction_current=0.0
	incoming_q_previous=0.0
	outgoing_q_previous=0.0
	outgoing_q_current=0.0
	catchment_q_previous=0.0
	catchment_q_current=0.0
	initial_river_q=0.0
	incoming_q_boundary=0.0
	outgoing_q_boundary=0.0


	DO catchment_index=1,catchment_count
	    !Sum the flows generated in each unit-catchment
		catchment_q_current(catchment_index)=groundwater_q(catchment_index)+subsurface_q(catchment_index)+surface_q(catchment_index)
		catchment_q_previous(catchment_index)=catchment_q_current(catchment_index)

		IF(muskingum_reach_count(catchment_index).GT.0)THEN	!unit-catchment with river

			!Accumulates flow
			incoming_q_current(catchment_index)=incoming_q_current(catchment_index)+catchment_q_current(catchment_index)

			!Constant flow in river
			outgoing_q_current(catchment_index)=incoming_q_current(catchment_index)

			!Continuity
			downstream_index=downstream_catchment(catchment_index)
			if (downstream_index>0) incoming_q_current(downstream_index)=incoming_q_current(downstream_index)+outgoing_q_current(catchment_index)

		ELSE !unit-catchment without river
			outgoing_q_current(catchment_index)=catchment_q_current(catchment_index)
			incoming_q_current(catchment_index)=catchment_q_current(catchment_index)

			downstream_index=downstream_catchment(catchment_index)

			if (downstream_index>0) incoming_q_current(downstream_index)=incoming_q_current(downstream_index)+catchment_q_current(catchment_index)
		ENDIF


		! Verifies if there is flow replacement
		do substitution_index=1,substitution_count
			if (catchment_index==substitution_catchment(substitution_index)) then
				incoming_q_current(downstream_index)=substituted_q(substitution_index,1)
				exit
			endif
		enddo
	ENDDO
	outgoing_q_previous=outgoing_q_current
	incoming_q_previous=incoming_q_current

	!Muskingum-Cunge boundary conditions
	do catchment_index=1,catchment_count
		initial_river_q(catchment_index,:)=incoming_q_current(catchment_index)
		incoming_q_boundary(catchment_index,:)=incoming_q_current(catchment_index)
		outgoing_q_boundary(catchment_index,:)=outgoing_q_current(catchment_index)
	enddo

	! Inercial boundary conditinos (only to Inercial version)
    IF (inertial_catchment_count>0) then
        call initialize_inertial_routing
    End if

	return
	end subroutine
