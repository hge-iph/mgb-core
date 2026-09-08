! SPDX-License-Identifier: GPL-3.0-or-later
! Copyright (C) 2019 Hidrologia de Grande Escala (HGE)

! Allocate or release state used by inertial routing.

    SUBROUTINE allocate_inertial_state(allocation_mode)
	USE model_state
    USE inertial_state

	IMPLICIT NONE
	INTEGER allocation_mode
    SAVE

	allocation_action: SELECT CASE (allocation_mode)
	CASE (0) ! Allocate.
		ALLOCATE (routing_method(catchment_count))
		ALLOCATE (upstream_topology(catchment_count,10))
		ALLOCATE (floodplain_point_count(catchment_count),floodplain_bottom_elevation(catchment_count))
		ALLOCATE (floodplain_elevation(100,catchment_count))
		ALLOCATE (floodplain_area(100,catchment_count))
		ALLOCATE (bankfull_depth(catchment_count))
		ALLOCATE (stage_table(102,catchment_count),volume_table(102,catchment_count))
		ALLOCATE (area_table(102,catchment_count))
		ALLOCATE (inertial_q(catchment_count))
		ALLOCATE (upstream_q(3))
		ALLOCATE (current_water_volume(catchment_count),previous_water_volume(catchment_count))
		ALLOCATE (current_flooded_area(catchment_count))
		ALLOCATE (water_depth(catchment_count),water_surface_elevation(catchment_count))
		ALLOCATE (face_catchment_1(catchment_count),face_catchment_2(catchment_count), &
                  first_face_elevation(catchment_count),second_face_elevation(catchment_count), &
                  face_distance(catchment_count),face_q(catchment_count),neighbor_q(catchment_count))

		ALLOCATE (stage_table_index(catchment_count))


		ALLOCATE (inertial_manning_n(catchment_count))

        ALLOCATE(floodplain_infiltration(catchment_count))
        allocate (grace_total_water_storage(catchment_count))

	CASE (1) ! Deallocate.
		DEALLOCATE (routing_method)
		DEALLOCATE (upstream_topology)
		DEALLOCATE (floodplain_point_count,floodplain_bottom_elevation)
		DEALLOCATE (floodplain_elevation)
		DEALLOCATE (floodplain_area)
		DEALLOCATE (bankfull_depth)
		DEALLOCATE (stage_table,volume_table)
		DEALLOCATE (area_table)
		DEALLOCATE (inertial_q)
		DEALLOCATE (upstream_q)
		DEALLOCATE (current_water_volume,previous_water_volume)
		DEALLOCATE (current_flooded_area)
		DEALLOCATE (water_depth,water_surface_elevation)
		DEALLOCATE (face_catchment_1,face_catchment_2,first_face_elevation,second_face_elevation, &
                    face_distance,face_q,neighbor_q)
		DEALLOCATE (stage_table_index)
		deallocate (grace_total_water_storage)


		DEALLOCATE (inertial_manning_n)

	CASE DEFAULT
		STOP ' ERRO: IOP DESCONHECIDO NO ROTINA ALLOCA_CALIB!!!'
	END SELECT allocation_action


	END
