! SPDX-License-Identifier: GPL-3.0-or-later
! Copyright (C) 2019 Hidrologia de Grande Escala (HGE)

! Calculate Muskingum-Cunge reach counts and timesteps.

	SUBROUTINE calculate_muskingum_cunge_parameters

	USE model_state
	IMPLICIT NONE
	INTEGER interval_count,reach_count
	REAL celerity_coefficient,model_step,routing_timestep
	REAL ideal_reach_length
	REAL current_slope,total_reach_length,current_celerity


	DO catchment_index=1,catchment_count
		IF(catchment_order(catchment_index)>1)THEN ! Unit-Catchmento order
			celerity_coefficient=1.67*river_slope(catchment_index)**0.3/manning_n(catchment_index)**0.6
			wave_celerity(catchment_index)=celerity_coefficient*(reference_q(catchment_index)/river_width(catchment_index))**0.4
			model_step=model_timestep_seconds
			routing_timestep=model_step
			routing_timestep=model_step/24.
			interval_count=24

			current_reference_q=reference_q(catchment_index)
			current_slope=river_slope(catchment_index)
			current_river_width=river_width(catchment_index)
			current_celerity=wave_celerity(catchment_index)
            ! Ideal ideal_reach_length using Fread Equation - Fread(1992) Flow Routing, in Handbook of Hydrology, Maidment
			ideal_reach_length=0.5*current_celerity*routing_timestep*(1+(1+1.5*(current_reference_q/current_river_width)/(current_celerity**2*current_slope*routing_timestep))**0.5)
			total_reach_length=river_length(catchment_index)*1000. !To meters
			reach_count=NINT(total_reach_length/ideal_reach_length) !Calculates reach_count number
			reach_count=MAX(reach_count,1)
			IF(reach_count.GT.max_muskingum_reach_count)THEN
                write(*,*),catchment_index
				WRITE(*,*) 'ntrech number greater then', max_muskingum_reach_count,' in parcunge subroutine!!!'
				ERROR STOP 'ntrech number greater than NUMUSK in parcunge'
			ENDIF
			muskingum_timestep(catchment_index)=routing_timestep
			muskingum_reach_count(catchment_index)=reach_count

		ELSE
			muskingum_timestep(catchment_index)=0.0
			muskingum_reach_count(catchment_index)=0
		ENDIF

	ENDDO

	RETURN
	END
