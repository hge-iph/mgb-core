! SPDX-License-Identifier: GPL-3.0-or-later
! Copyright (C) 2019 Hidrologia de Grande Escala (HGE)

! Route flow through one catchment with the Muskingum-Cunge method.

	SUBROUTINE route_muskingum_cunge(upstream_boundary_q,downstream_boundary_q, &
		reach_count_argument,interval_count_argument,coefficient_1,coefficient_2,coefficient_3)

	USE model_state
	IMPLICIT NONE
	INTEGER interval_index,reach_index

	!Muskingum-Cunge Coefficients
	REAL coefficient_1,coefficient_2,coefficient_3
	!Auxiliary variables
	REAL upstream_boundary_q,downstream_boundary_q
	!Sub-Rivers number / Number of intervals in a day
	INTEGER reach_count_argument,interval_count_argument

	REAL,ALLOCATABLE:: routed_q(:,:)
	REAL q_loss
	ALLOCATE (routed_q(reach_count_argument+1,interval_count_argument+1))


	IF(reach_count_argument>max_muskingum_reach_count) STOP 'MUITOS SUBTRECHOS NA ROTINA MUSK'

	routed_q=0.0
	outgoing_q_boundary(catchment_index,1)=upstream_boundary_q


	q_loss=0.0


	!Upstream boundary conditions
	DO interval_index=1,interval_count_argument+1
	    ! Remove open-water evaporation and prescribed losses at the upstream boundary.
		routed_q(1,interval_index)=MAX(incoming_q_boundary(catchment_index,interval_index)-open_water_evaporation_q(catchment_index)-q_loss,0.0)
	ENDDO


	!Initial conditions
	DO reach_index=1,reach_count_argument+1
		routed_q(reach_index,1)=initial_river_q(catchment_index,reach_index)
	ENDDO

	DO interval_index=1,interval_count_argument
		DO reach_index=1,reach_count_argument
			routed_q(reach_index+1,interval_index+1)=coefficient_1*routed_q(reach_index,interval_index)+coefficient_2*routed_q(reach_index,interval_index+1)+coefficient_3*routed_q(reach_index+1,interval_index)
			!Avoid negative flows
			routed_q(reach_index+1,interval_index+1)=MAX(routed_q(reach_index+1,interval_index+1),0.0)
		ENDDO
		!Save output flows (all stretches and times)
		outgoing_q_boundary(catchment_index,interval_index+1)=routed_q(reach_count_argument+1,interval_index+1)
	ENDDO

    !Save Initial Condition values to next Muskingum-Cunge simulation
	initial_river_q(catchment_index,1)=incoming_q_boundary(catchment_index,interval_count_argument+1)
	DO reach_index=2,reach_count_argument+1
		initial_river_q(catchment_index,reach_index)=routed_q(reach_index,interval_count_argument+1)
	ENDDO

	!Save last downstream value. This value is returned to route_muskingum_cunge_network SUBROUTINE.
	downstream_boundary_q=routed_q(reach_count_argument+1,interval_count_argument+1)

	DEALLOCATE (routed_q)
	RETURN
	END SUBROUTINE route_muskingum_cunge
