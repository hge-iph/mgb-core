! SPDX-License-Identifier: GPL-3.0-or-later
! Copyright (C) 2019 Hidrologia de Grande Escala (HGE)

! Build the upstream-catchment topology used by inertial routing.

    subroutine build_flood_topology

        !Parameters and variables
        use model_state
        use inertial_state

        integer downstream_index
        integer upstream_slot

        upstream_topology = 0

        do catchment_index = 1, catchment_count
            downstream_index = downstream_catchment(catchment_index)
            !Identifying the downstream catchment of catchment_index
            if (downstream_index < 0) cycle
            !This catchment is a outlet
            upstream_topology(downstream_index, 1) = upstream_topology(downstream_index, 1) + 1
            upstream_slot = upstream_topology(downstream_index, 1)
            upstream_topology(downstream_index, 1 + upstream_slot) = catchment_index
        end do

        return
    end subroutine build_flood_topology
