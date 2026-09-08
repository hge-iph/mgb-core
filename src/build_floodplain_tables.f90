! SPDX-License-Identifier: GPL-3.0-or-later
! Copyright (C) 2019 Hidrologia de Grande Escala (HGE)

! Build per-catchment stage-area-volume lookup tables.

    SUBROUTINE build_floodplain_tables

    USE model_state
    USE inertial_state
    IMPLICIT NONE
    INTEGER :: floodplain_point_index
    REAL :: incremental_volume

    DO catchment_index=1,catchment_count

        ! The first three points describe the channel and first floodplain level.
        stage_table(1,catchment_index)=floodplain_bottom_elevation(catchment_index)-bankfull_depth(catchment_index)
        volume_table(1,catchment_index)=0.0
        area_table(1,catchment_index)=DBLE(river_width(catchment_index))*DBLE(river_length(catchment_index))/1000.0
        stage_table(2,catchment_index)=floodplain_bottom_elevation(catchment_index)
        volume_table(2,catchment_index)=DBLE(river_width(catchment_index))*bankfull_depth(catchment_index)*DBLE(river_length(catchment_index))*1000.0
        area_table(2,catchment_index)=area_table(1,catchment_index)
        stage_table(3,catchment_index)=floodplain_elevation(1,catchment_index)
        area_table(3,catchment_index)=MAX(area_table(2,catchment_index),floodplain_area(1,catchment_index))

        volume_table(3,catchment_index)=volume_table(2,catchment_index)+0.5*(floodplain_area(1,catchment_index)+0.0)*(stage_table(3,catchment_index)-stage_table(2,catchment_index))*1000000.0


        ! Integrate later levels with the trapezoidal rule.
        DO floodplain_point_index=1,floodplain_point_count(catchment_index)-1
            stage_table(floodplain_point_index+3,catchment_index)=floodplain_elevation(floodplain_point_index+1,catchment_index)
            area_table(floodplain_point_index+3,catchment_index)=floodplain_area(floodplain_point_index+1,catchment_index)
            incremental_volume=(floodplain_elevation(floodplain_point_index+1,catchment_index)-floodplain_elevation(floodplain_point_index,catchment_index))*1000000.0*((floodplain_area(floodplain_point_index,catchment_index)+floodplain_area(floodplain_point_index+1,catchment_index))*0.5)
            volume_table(floodplain_point_index+3,catchment_index)=volume_table(floodplain_point_index+2,catchment_index)+incremental_volume
        ENDDO

    ENDDO

    RETURN
    END SUBROUTINE build_floodplain_tables
