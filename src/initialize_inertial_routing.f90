! SPDX-License-Identifier: GPL-3.0-or-later
! Copyright (C) 2019 Hidrologia de Grande Escala (HGE)

! Initialize inertial-routing storage and water levels.

subroutine initialize_inertial_routing

    use inertial_state
    use model_state
    implicit none

    real*8 linear_interpolate, rating_curve_scale, rating_curve_exponent
    remaining_model_timestep = dble(model_timestep)
    neighbor_q = 0.0
    grace_total_water_storage = 0.0

    do catchment_index = 1, catchment_count

        rating_curve_scale = (inertial_manning_n(catchment_index) &
                              *(dble(river_width(catchment_index))**(2.0/3.0)))**0.6 &
                             /((river_slope(catchment_index)**0.5)**0.6)
        rating_curve_exponent = 0.6
        inertial_q(catchment_index) = reference_q(catchment_index)
        face_q = reference_q(catchment_index)
        water_depth(catchment_index) = rating_curve_scale &
                                       *(inertial_q(catchment_index)**rating_curve_exponent) &
                                       /dble(river_width(catchment_index)) + 0.00001
        water_surface_elevation(catchment_index) = stage_table(1, catchment_index) + &
                                                   water_depth(catchment_index)
        previous_water_volume(catchment_index) = water_depth(catchment_index)* &
                                dble(river_width(catchment_index))*(river_length(catchment_index)* &
                                                                                     1000.)
        current_water_volume(catchment_index) = previous_water_volume(catchment_index)
        current_flooded_area(catchment_index) = linear_interpolate( &
                                 volume_table(:, catchment_index), area_table(:, catchment_index), &
                                                floodplain_point_count(catchment_index) + 2, &
                                                current_water_volume(catchment_index))
        current_flooded_area(catchment_index) = max(current_flooded_area(catchment_index), &
                                                    catchment_area(catchment_index))
        stage_table_index(catchment_index) = 1

    end do

end subroutine
