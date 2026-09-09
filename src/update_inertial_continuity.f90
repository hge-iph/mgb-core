! SPDX-License-Identifier: GPL-3.0-or-later
! Copyright (C) 2019 Hidrologia de Grande Escala (HGE)

! Update inertial-routing volume, depth, stage, and flooded area.

        subroutine update_inertial_continuity

            use inertial_state
            use model_state
            use omp_lib

            implicit none

            surface_water_output = 0.0

            !$omp parallel num_threads(thread_count)
            !$omp do private(subbasin_index,upstream_count,sum_upstream_q,interpolated_area,interpolated_stage)
            do catchment_index = 1, catchment_count

                subbasin_index = catchment_subbasin(catchment_index)
                if ((subbasin_index < first_subbasin) .or. (subbasin_index > last_subbasin)) cycle
                ! Manual controls for specialized calibration

                !Number of upstream catchments of catchment_index
                upstream_count = upstream_topology(catchment_index, 1)

                !Sum of downstream catchment_index flows
                if (upstream_topology(catchment_index, 1) == 0) then
                    sum_upstream_q = 0.0
                else
                    sum_upstream_q = sum(inertial_q(upstream_topology(catchment_index, 2:1 + &
                                                                      upstream_count)))
                end if

                !to use lateral connections
                current_water_volume(catchment_index) = previous_water_volume(catchment_index) + &
                        inertial_timestep*(sum_upstream_q + catchment_q_current(catchment_index) - &
                                      inertial_q(catchment_index) + neighbor_q(catchment_index)) - &
            (potential_open_water_et(catchment_index) + floodplain_infiltration(catchment_index) - &
                                                precipitation(catchment_index))*inertial_timestep* &
                                  current_flooded_area(catchment_index)*1000000.0/(model_timestep* &
                                                                                              1000.)
                current_water_volume(catchment_index) = max(current_water_volume(catchment_index), &
                                                            0.0)

            !! SIN_RESERV
                if (reservoir_index_by_catchment(catchment_index) > 0 .and. &
                    reservoir_start_timestep(catchment_index) <= timestep_index) then
                current_water_volume(catchment_index) = min(current_water_volume(catchment_index), &
                                                                volume_table(2, catchment_index))
                    ! max vol calha cheia
                end if
            !! SIN_RESERV

            !!Added to include evaporation of open waters from floodplain dynamics
                et_output(catchment_index) = et_output(catchment_index) + &
                                     ((potential_open_water_et(catchment_index)*inertial_timestep* &
                          current_flooded_area(catchment_index)*1000000.0/(model_timestep*1000.))/ &
                                              (catchment_area(catchment_index)*1000))
                ! mm per model timestep
                open_water_et_output(catchment_index) = open_water_et_output(catchment_index) + &
                                     ((potential_open_water_et(catchment_index)*inertial_timestep* &
                          current_flooded_area(catchment_index)*1000000.0/(model_timestep*1000.))/ &
                                                         (catchment_area(catchment_index)*1000))
                ! mm per model timestep

                !Interpolates the Area and Level from Volume
                call interpolate_stage_area(current_water_volume, volume_table, stage_table_index, &
                catchment_index, stage_table, area_table, floodplain_point_count, catchment_count, &
                                            interpolated_stage, interpolated_area)

                current_flooded_area(catchment_index) = min(interpolated_area, &
                                                            catchment_area(catchment_index))

                !Updates variables:
                water_surface_elevation(catchment_index) = max(interpolated_stage, stage_table(1, &
                                                                                catchment_index) + &
                                                               0.001)

                !Calculates depth
          water_depth(catchment_index) = water_surface_elevation(catchment_index) - stage_table(1, &
                                                                                    catchment_index)

                !Updates the volume
                previous_water_volume(catchment_index) = current_water_volume(catchment_index)

                if (inertial_elapsed_time/remaining_model_timestep == 1) then

                    !Update Terrestrial Water Storage at the end of inertial loop
                    total_water_storage(catchment_index) = total_water_storage(catchment_index) + &
                  real(current_water_volume(catchment_index)/dble(catchment_area(catchment_index)* &
                                                                                            1000.0))
                   surface_water_output(catchment_index) = surface_water_output(catchment_index) + &
                  real(current_water_volume(catchment_index)/dble(catchment_area(catchment_index)* &
                                                                                            1000.0))

                end if

            end do
            !$omp end do
            !$omp end parallel

        end subroutine
