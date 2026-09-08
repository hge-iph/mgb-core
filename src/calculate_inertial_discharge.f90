! SPDX-License-Identifier: GPL-3.0-or-later
! Copyright (C) 2019 Hidrologia de Grande Escala (HGE)

! Calculate channel and lateral discharge for inertial routing.

	subroutine calculate_inertial_discharge

	use inertial_state
	use model_state
    use omp_lib

	implicit none

	!Start catchment loop
	!$OMP PARALLEL NUM_THREADS(thread_count)

    !$OMP DO PRIVATE(subbasin_index,first_water_surface_elevation,second_water_surface_elevation,first_bed_elevation,second_bed_elevation,downstream_catchment_index,flow_depth,flow_length,flow_width,flow_manning_n,previous_unit_width_q,flow_slope,q)
	do catchment_index=1,catchment_count

        ! Manual controls for specialized calibration
        subbasin_index=catchment_subbasin(catchment_index)
		IF((subbasin_index<first_subbasin).OR.(subbasin_index>last_subbasin))CYCLE

            ! Bottom level and water level of catchment_index catchment:
            first_bed_elevation=stage_table(1,catchment_index)
            first_water_surface_elevation=water_depth(catchment_index)+first_bed_elevation

            ! Bottom level and water level of downstream catchment_index catchment:
            downstream_catchment_index = routing_downstream_catchment(catchment_index) ! SIN_RESERV

			! Negative indices mark a basin outlet (-1) or reservoir dam (-2).
            if(downstream_catchment_index < 0) then ! SIN_RESERV

                ! Reservoir-dam boundaries use a fixed 0.1 m/km fall.
                if (downstream_catchment_index==-2) then  ! SIN_RESERV
                    second_bed_elevation=first_bed_elevation-0.0001*DBLE(river_length(catchment_index)*1000.) ! SIN_RESERV (0.1 m/km)
                    second_water_surface_elevation=first_water_surface_elevation-0.0001*DBLE(river_length(catchment_index)*1000.) ! SIN_RESERV (0.1 m/km)
                elseif(downstream_water_surface_slope<=0.000000000001)then !If slope = 0.00, water is reaching Oceans/Endorreic Lakes -> Fixed level condition !
                    second_bed_elevation=first_bed_elevation
                    second_water_surface_elevation=Dble(bankfull_depth(catchment_index))+second_bed_elevation
                else
                    !Using downstream boundary condition from InfoMGB.sim
                    second_bed_elevation=first_bed_elevation-downstream_water_surface_slope*DBLE(river_length(catchment_index)*1000.)
                    second_water_surface_elevation=first_water_surface_elevation-downstream_water_surface_slope*DBLE(river_length(catchment_index)*1000.)
                end if


            else
			    !Computes downstream water elevation
                second_bed_elevation=stage_table(1,downstream_catchment_index)
                second_water_surface_elevation=water_depth(downstream_catchment_index)+second_bed_elevation
            endif

            ! Calculates the flow_depth variable:
            flow_depth=max(second_water_surface_elevation,first_water_surface_elevation)-max(second_bed_elevation,first_bed_elevation)
            flow_depth=max(flow_depth,0.0)


            if(downstream_catchment_index /= -1)then
                flow_length=DBLE(river_length(catchment_index)*1000.) + DBLE(river_length(downstream_catchment_index)*1000.)
                flow_length=flow_length/2.
                !River width
                flow_width=DBLE(river_width(catchment_index)) + DBLE(river_width(downstream_catchment_index))
                flow_width=flow_width/2.
            else

                !Considering the upstream length
                flow_length=DBLE(river_length(catchment_index)*1000.)
                flow_width=DBLE(river_width(catchment_index))
            endif

            !River manning coefficient
            flow_manning_n=inertial_manning_n(catchment_index)

            ! Flow in the last time-step
            previous_unit_width_q=inertial_q(catchment_index)/flow_width ! in m2/s

            ! Water table slope:
            flow_slope=-(first_water_surface_elevation-second_water_surface_elevation)/flow_length

            ! Calculates flow from Inertial equation (m2/s) for each catchment_index:
            if (flow_depth>0.0) then
                q=(previous_unit_width_q-(gravity*inertial_timestep*flow_depth*flow_slope))/(1.+gravity*inertial_timestep*flow_depth*flow_manning_n*flow_manning_n*abs(previous_unit_width_q)/(flow_depth**(10.0/3.0)))
                q=q*flow_width !(m3/s)

            !Froude limiter for supercritical flow conditions

                if (q>0)then
                    q=min(q,flow_width*(flow_depth**1.5)*9.81**0.5) !avoid supercritical flow
                else
                    q=max(q,-flow_width*(flow_depth**1.5)*9.81**0.5) !avoid supercritical flow
                endif
            !endif

            else
                q=0.0;
            endif

            !! SIN_RESERV
            if (reservoir_index_by_catchment(catchment_index)>0) then
                if (reservoir_outflow(timestep_index,reservoir_index_by_catchment(catchment_index))>-0.01) then
                    q=q_river_output(catchment_index)+inertial_elapsed_time/remaining_model_timestep*(reservoir_outflow(timestep_index,reservoir_index_by_catchment(catchment_index))-q_river_output(catchment_index))
                endif
            endif
            !! SIN_RESERV


            ! Updates variable flow inertial:
            inertial_q(catchment_index)=q ! in m3/s
            outgoing_q_current(catchment_index)=inertial_q(catchment_index) ! in m3/s
            flow_velocity(catchment_index)=real(q/(flow_width*flow_depth)) !Flow velocity
    enddo
    !$OMP END DO
	!$OMP END PARALLEL

    ! Route lateral flow through pseudo-two-dimensional face connections.
    if (pseudo_two_d_enabled==1) then !turn on lateral connections

    !PLEASE, BE CAREFUL CLEARING THESE VARIABLES! (neighbor_q and face_q)
    neighbor_q=0.0

    ! !$OMP PARALLEL DO NUM_THREADS(thread_count) DEFAULT (SHARED)
     !PRIVATE ()
    do face_index=1,face_count

            first_face_catchment_index=face_catchment_1(face_index)
            second_face_catchment_index=face_catchment_2(face_index)

            ! Bed and water-surface elevations for the two connected catchments.
            first_bed_elevation=stage_table(1,first_face_catchment_index)
            first_water_surface_elevation=water_depth(first_face_catchment_index)+first_bed_elevation
            second_bed_elevation=stage_table(1,second_face_catchment_index)
            second_water_surface_elevation=water_depth(second_face_catchment_index)+second_bed_elevation

             !Lateral connections are set for overland flow only. Turn off to use bifurcation mode
           if ((second_water_surface_elevation>first_water_surface_elevation).AND.(water_depth(second_face_catchment_index)>bankfull_depth(second_face_catchment_index)))then
               !OK Water is passing through lateral connections
           elseif ((first_water_surface_elevation>second_water_surface_elevation).AND.(water_depth(first_face_catchment_index)>bankfull_depth(first_face_catchment_index)))then
               !OK Water is passing through lateral connections
           else
                CYCLE !Water is not passing through lateral connections
           endif

            ! Flow depth above the higher bed controls the connection.
            flow_depth=max(second_water_surface_elevation,first_water_surface_elevation)-max(second_bed_elevation,first_bed_elevation)
            ! Prevent a negative flow depth.
            flow_depth=max(flow_depth,0.0)

            flow_length=DBLE(face_distance(face_index))

            !Variables below were moved to infomgb.sim

            ! Discharge per unit width from the preceding inertial timestep.
            previous_unit_width_q=face_q(face_index)/overland_flow_width ! m2/s

            ! Water-surface slope across the connection.
            flow_slope=-(first_water_surface_elevation-second_water_surface_elevation)/flow_length

            ! Inertial discharge per unit width at the downstream face.
            if (flow_depth>0.0) then
                q=(previous_unit_width_q-(gravity*inertial_timestep*flow_depth*flow_slope))/(1.+gravity*inertial_timestep*flow_depth*overland_manning_n*overland_manning_n*abs(previous_unit_width_q)/(flow_depth**(10.0/3.0)))
                q=q*overland_flow_width
            else
                q=0.0;
            endif

            ! Store discharge for the next inertial timestep.
            face_q(face_index)=q ! m3/s
            neighbor_q(first_face_catchment_index)=neighbor_q(first_face_catchment_index)-face_q(face_index)
            neighbor_q(second_face_catchment_index)=neighbor_q(second_face_catchment_index)+face_q(face_index)

    enddo
!    !$OMP END PARALLEL DO
    endif

	END SUBROUTINE calculate_inertial_discharge
