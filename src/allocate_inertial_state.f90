! SPDX-License-Identifier: GPL-3.0-or-later
! Copyright (C) 2019 Hidrologia de Grande Escala (HGE)

! Allocate or release state used by inertial routing.

    subroutine allocate_inertial_state(allocation_mode)
        use model_state
        use inertial_state

        implicit none
        integer allocation_mode
        save

        allocation_action:select case(allocation_mode)
        case (0)
        ! Allocate.
        allocate (routing_method(catchment_count))
        allocate (upstream_topology(catchment_count, 10))
        allocate (floodplain_point_count(catchment_count), &
                  floodplain_bottom_elevation(catchment_count))
        allocate (floodplain_elevation(100, catchment_count))
        allocate (floodplain_area(100, catchment_count))
        allocate (bankfull_depth(catchment_count))
        allocate (stage_table(102, catchment_count), volume_table(102, catchment_count))
        allocate (area_table(102, catchment_count))
        allocate (inertial_q(catchment_count))
        allocate (upstream_q(3))
        allocate (current_water_volume(catchment_count), previous_water_volume(catchment_count))
        allocate (current_flooded_area(catchment_count))
        allocate (water_depth(catchment_count), water_surface_elevation(catchment_count))
        allocate (face_catchment_1(catchment_count), face_catchment_2(catchment_count), &
                  first_face_elevation(catchment_count), second_face_elevation(catchment_count), &
                  face_distance(catchment_count), face_q(catchment_count), &
                  neighbor_q(catchment_count))

        allocate (stage_table_index(catchment_count))

        allocate (inertial_manning_n(catchment_count))

        allocate (floodplain_infiltration(catchment_count))
        allocate (grace_total_water_storage(catchment_count))

        case (1)
        ! Deallocate.
        deallocate (routing_method)
        deallocate (upstream_topology)
        deallocate (floodplain_point_count, floodplain_bottom_elevation)
        deallocate (floodplain_elevation)
        deallocate (floodplain_area)
        deallocate (bankfull_depth)
        deallocate (stage_table, volume_table)
        deallocate (area_table)
        deallocate (inertial_q)
        deallocate (upstream_q)
        deallocate (current_water_volume, previous_water_volume)
        deallocate (current_flooded_area)
        deallocate (water_depth, water_surface_elevation)
      deallocate (face_catchment_1, face_catchment_2, first_face_elevation, second_face_elevation, &
                    face_distance, face_q, neighbor_q)
        deallocate (stage_table_index)
        deallocate (grace_total_water_storage)

        deallocate (inertial_manning_n)

        case default
        stop ' ERRO: IOP DESCONHECIDO NO ROTINA ALLOCA_CALIB!!!'
        end select allocation_action

    end
