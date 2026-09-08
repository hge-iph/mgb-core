! SPDX-License-Identifier: GPL-3.0-or-later
! Copyright (C) 2019 Hidrologia de Grande Escala (HGE)

! Build the upstream-catchment topology used by inertial routing.

    SUBROUTINE build_flood_topology

    !Parameters and variables
    USE model_state
    USE inertial_state

    INTEGER downstream_index
    INTEGER upstream_slot

    upstream_topology=0

    DO catchment_index=1,catchment_count
        downstream_index=downstream_catchment(catchment_index) !Identifying the downstream catchment of catchment_index
        IF(downstream_index<0)CYCLE !This catchment is a outlet
        upstream_topology(downstream_index,1)=upstream_topology(downstream_index,1)+1
        upstream_slot=upstream_topology(downstream_index,1)
        upstream_topology(downstream_index,1+upstream_slot)=catchment_index
    ENDDO

    RETURN
    END SUBROUTINE build_flood_topology
