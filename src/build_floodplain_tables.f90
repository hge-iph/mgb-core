! SPDX-License-Identifier: GPL-3.0-or-later
! Copyright (C) 2019 Hidrologia de Grande Escala (HGE)

! Build per-catchment stage-area-volume lookup tables.

    subroutine build_floodplain_tables

        use model_state
        use inertial_state
        implicit none
        integer :: floodplain_point_index
        real :: incremental_volume

        do catchment_index = 1, catchment_count

            ! The first three points describe the channel and first floodplain level.
            stage_table(1, catchment_index) = floodplain_bottom_elevation(catchment_index) - &
                                              bankfull_depth(catchment_index)
            volume_table(1, catchment_index) = 0.0
            area_table(1, catchment_index) = dble(river_width(catchment_index))* &
                                             dble(river_length(catchment_index))/1000.0
            stage_table(2, catchment_index) = floodplain_bottom_elevation(catchment_index)
            volume_table(2, catchment_index) = dble(river_width(catchment_index))* &
                              bankfull_depth(catchment_index)*dble(river_length(catchment_index))* &
                                               1000.0
            area_table(2, catchment_index) = area_table(1, catchment_index)
            stage_table(3, catchment_index) = floodplain_elevation(1, catchment_index)
           area_table(3, catchment_index) = max(area_table(2, catchment_index), floodplain_area(1, &
                                                                                   catchment_index))

     volume_table(3, catchment_index) = volume_table(2, catchment_index) + 0.5*(floodplain_area(1, &
      catchment_index) + 0.0)*(stage_table(3, catchment_index) - stage_table(2, catchment_index))* &
                                               1000000.0

            ! Integrate later levels with the trapezoidal rule.
            do floodplain_point_index = 1, floodplain_point_count(catchment_index) - 1
                stage_table(floodplain_point_index + 3, catchment_index) = &
                    floodplain_elevation(floodplain_point_index + 1, catchment_index)
                area_table(floodplain_point_index + 3, catchment_index) = &
                    floodplain_area(floodplain_point_index + 1, catchment_index)
         incremental_volume = (floodplain_elevation(floodplain_point_index + 1, catchment_index) - &
                         floodplain_elevation(floodplain_point_index, catchment_index))*1000000.0* &
                                     ((floodplain_area(floodplain_point_index, catchment_index) + &
                                    floodplain_area(floodplain_point_index + 1, catchment_index))* &
                                      0.5)
                volume_table(floodplain_point_index + 3, catchment_index) = &
                    volume_table(floodplain_point_index + 2, catchment_index) + incremental_volume
            end do

        end do

        return
    end subroutine build_floodplain_tables
