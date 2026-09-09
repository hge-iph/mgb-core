! SPDX-License-Identifier: GPL-3.0-or-later

module inertial_routing

    implicit none
    private
    public :: prepare_inertial_routing, initialize_inertial_routing, route_inertial_flow

contains

    subroutine prepare_inertial_routing
        use catchment_state, only: downstream_catchment
        use reservoir_state, only: routing_downstream_catchment

        implicit none

        call build_flood_topology
        call build_floodplain_tables
        routing_downstream_catchment = downstream_catchment
    end subroutine prepare_inertial_routing

    subroutine build_flood_topology
        use catchment_state, only: catchment_count, catchment_index, downstream_catchment
        use inertial_state, only: upstream_topology

        !Parameters and variables

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

    subroutine build_floodplain_tables
        use catchment_state, only: catchment_count, catchment_index, river_length, river_width
        use inertial_state, only: area_table, bankfull_depth, floodplain_area, &
                        floodplain_bottom_elevation, floodplain_elevation, floodplain_point_count, &
                                  stage_table, volume_table

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

    subroutine initialize_inertial_routing
        use interpolation, only: linear_interpolate
        use simulation_state, only: model_timestep
        use catchment_state, only: catchment_area, catchment_count, catchment_index, &
                                   river_length, river_slope, river_width
        use muskingum_state, only: reference_q
        use inertial_state, only: area_table, current_flooded_area, current_water_volume, face_q, &
                floodplain_point_count, grace_total_water_storage, inertial_manning_n, inertial_q, &
                         neighbor_q, previous_water_volume, remaining_model_timestep, stage_table, &
                               stage_table_index, volume_table, water_depth, water_surface_elevation

        implicit none

        real*8 rating_curve_scale, rating_curve_exponent
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

    subroutine route_inertial_flow
        use inertial_state, only: inertial_elapsed_time, inertial_timestep, &
                                  remaining_model_timestep

        implicit none

        !Initializes aggregating time step loop variable
        inertial_elapsed_time = 0.0

        !Intertial Routing loop
        do while (inertial_elapsed_time < remaining_model_timestep)

            call calculate_inertial_timestep

            ! Needed to adjust routing time step at last loop interval (i.e. in order to not exceed
            ! Water balance timestep in seconds.
            inertial_timestep = min(inertial_timestep, remaining_model_timestep - &
                                    inertial_elapsed_time)

            !Updates the loop variable
            inertial_elapsed_time = inertial_elapsed_time + inertial_timestep

            call calculate_inertial_discharge
            call update_inertial_continuity

        end do

        return
    end subroutine

    subroutine calculate_inertial_timestep
        use simulation_state, only: first_subbasin, last_subbasin, model_timestep
        use catchment_state, only: catchment_count, catchment_index, catchment_subbasin, &
                                   river_length, subbasin_index
        use inertial_state, only: courant_alpha, gravity, inertial_timestep, &
                                  max_inertial_timestep, max_water_depth, water_depth

        implicit none

        real*8 minimum_catchment_timestep
        real*8 candidate_timestep

        candidate_timestep = dble(model_timestep)

        do catchment_index = 1, catchment_count
            !Catchment loop

            subbasin_index = catchment_subbasin(catchment_index)
            if ((subbasin_index < first_subbasin) .or. (subbasin_index > last_subbasin)) cycle
            ! Manual controls for specialized calibration

            ! MAX H to calculates the time-step of Inertial model:
            max_water_depth = (water_depth(catchment_index))
            ! Correct if equal to zero:
            max_water_depth = max(max_water_depth, 0.001)
            ! Compute time interval:
            inertial_timestep = courant_alpha*river_length(catchment_index)*1000./(gravity* &
                                                                               max_water_depth)**0.5
            if (inertial_timestep < candidate_timestep) candidate_timestep = inertial_timestep
        end do

        ! Do not exceed the main model timestep.
        max_inertial_timestep = dble(model_timestep)
        minimum_catchment_timestep = candidate_timestep
        inertial_timestep = min(max_inertial_timestep, minimum_catchment_timestep)

    end subroutine

    subroutine calculate_inertial_discharge
        use simulation_state, only: first_subbasin, last_subbasin, timestep_index
        use catchment_state, only: catchment_count, catchment_index, catchment_subbasin, &
                                   river_length, river_width, subbasin_index
        use reservoir_state, only: reservoir_index_by_catchment, reservoir_outflow, &
                                   routing_downstream_catchment
        use muskingum_state, only: flow_velocity, outgoing_q_current
        use inertial_state, only: bankfull_depth, downstream_catchment_index, &
                   downstream_water_surface_slope, face_catchment_1, face_catchment_2, face_count, &
               face_distance, face_index, face_q, first_bed_elevation, first_face_catchment_index, &
               first_water_surface_elevation, flow_depth, flow_length, flow_manning_n, flow_slope, &
                       flow_width, gravity, inertial_elapsed_time, inertial_manning_n, inertial_q, &
                           inertial_timestep, neighbor_q, overland_flow_width, overland_manning_n, &
                         previous_unit_width_q, pseudo_two_d_enabled, q, remaining_model_timestep, &
                second_bed_elevation, second_face_catchment_index, second_water_surface_elevation, &
                                  stage_table, thread_count, water_depth
        use output_state, only: q_river_output

        use omp_lib

        implicit none

        !Start catchment loop
        !$omp parallel num_threads(thread_count)

        !$omp do private(subbasin_index,first_water_surface_elevation,second_water_surface_elevation,first_bed_elevation,second_bed_elevation,downstream_catchment_index,flow_depth,flow_length,flow_width,flow_manning_n,previous_unit_width_q,flow_slope,q)
        do catchment_index = 1, catchment_count

            ! Manual controls for specialized calibration
            subbasin_index = catchment_subbasin(catchment_index)
            if ((subbasin_index < first_subbasin) .or. (subbasin_index > last_subbasin)) cycle

            ! Bottom level and water level of catchment_index catchment:
            first_bed_elevation = stage_table(1, catchment_index)
            first_water_surface_elevation = water_depth(catchment_index) + first_bed_elevation

            ! Bottom level and water level of downstream catchment_index catchment:
            downstream_catchment_index = routing_downstream_catchment(catchment_index)
            ! SIN_RESERV

            ! Negative indices mark a basin outlet (-1) or reservoir dam (-2).
            if (downstream_catchment_index < 0) then
                ! SIN_RESERV

                ! Reservoir-dam boundaries use a fixed 0.1 m/km fall.
                if (downstream_catchment_index == -2) then
                    ! SIN_RESERV
           second_bed_elevation = first_bed_elevation - 0.0001*dble(river_length(catchment_index)* &
                                                                             1000.)
! SIN_RESERV (0.1 m/km)
                    second_water_surface_elevation = first_water_surface_elevation - 0.0001* &
                                                     dble(river_length(catchment_index)*1000.)
                    ! SIN_RESERV (0.1 m/km)
                elseif (downstream_water_surface_slope <= 0.000000000001) then
                    ! If slope = 0.00, water is reaching Oceans/Endorreic Lakes -> Fixed level
                    ! condition !
                    second_bed_elevation = first_bed_elevation
                    second_water_surface_elevation = dble(bankfull_depth(catchment_index)) + &
                                                     second_bed_elevation
                else
                    ! Use the configured downstream boundary condition.
                    second_bed_elevation = first_bed_elevation - downstream_water_surface_slope* &
                                           dble(river_length(catchment_index)*1000.)
                    second_water_surface_elevation = first_water_surface_elevation - &
                                downstream_water_surface_slope*dble(river_length(catchment_index)* &
                                                                                         1000.)
                end if

            else
                !Computes downstream water elevation
                second_bed_elevation = stage_table(1, downstream_catchment_index)
                second_water_surface_elevation = water_depth(downstream_catchment_index) + &
                                                 second_bed_elevation
            end if

            ! Calculates the flow_depth variable:
            flow_depth = max(second_water_surface_elevation, first_water_surface_elevation) - &
                         max(second_bed_elevation, first_bed_elevation)
            flow_depth = max(flow_depth, 0.0)

            if (downstream_catchment_index /= -1) then
                flow_length = dble(river_length(catchment_index)*1000.) + &
                              dble(river_length(downstream_catchment_index)*1000.)
                flow_length = flow_length/2.
                !River width
                flow_width = dble(river_width(catchment_index)) + &
                             dble(river_width(downstream_catchment_index))
                flow_width = flow_width/2.
            else

                !Considering the upstream length
                flow_length = dble(river_length(catchment_index)*1000.)
                flow_width = dble(river_width(catchment_index))
            end if

            !River manning coefficient
            flow_manning_n = inertial_manning_n(catchment_index)

            ! Flow in the last time-step
            previous_unit_width_q = inertial_q(catchment_index)/flow_width
            ! in m2/s

            ! Water table slope:
            flow_slope = -(first_water_surface_elevation - second_water_surface_elevation)/ &
                         flow_length

            ! Calculates flow from Inertial equation (m2/s) for each catchment_index:
            if (flow_depth > 0.0) then
              q = (previous_unit_width_q - (gravity*inertial_timestep*flow_depth*flow_slope))/(1.+ &
                               gravity*inertial_timestep*flow_depth*flow_manning_n*flow_manning_n* &
                                                    abs(previous_unit_width_q)/(flow_depth**(10.0/ &
                                                                                              3.0)))
                q = q*flow_width
                !(m3/s)

                !Froude limiter for supercritical flow conditions

                if (q > 0) then
                    q = min(q, flow_width*(flow_depth**1.5)*9.81**0.5)
                    !avoid supercritical flow
                else
                    q = max(q, -flow_width*(flow_depth**1.5)*9.81**0.5)
                    !avoid supercritical flow
                end if
                !endif

            else
                q = 0.0
            end if

            !! SIN_RESERV
            if (reservoir_index_by_catchment(catchment_index) > 0) then
          if (reservoir_outflow(timestep_index, reservoir_index_by_catchment(catchment_index)) > - &
                    0.01) then
                    q = q_river_output(catchment_index) + inertial_elapsed_time/ &
                        remaining_model_timestep*(reservoir_outflow(timestep_index, &
                                                  reservoir_index_by_catchment(catchment_index)) - &
                                                  q_river_output(catchment_index))
                end if
            end if
            !! SIN_RESERV

            ! Updates variable flow inertial:
            inertial_q(catchment_index) = q
            ! in m3/s
            outgoing_q_current(catchment_index) = inertial_q(catchment_index)
            ! in m3/s
            flow_velocity(catchment_index) = real(q/(flow_width*flow_depth))
            !Flow velocity
        end do
        !$omp end do
        !$omp end parallel

        ! Route lateral flow through pseudo-two-dimensional face connections.
        if (pseudo_two_d_enabled == 1) then
            !turn on lateral connections

            !PLEASE, BE CAREFUL CLEARING THESE VARIABLES! (neighbor_q and face_q)
            neighbor_q = 0.0

            ! !$OMP PARALLEL DO NUM_THREADS(thread_count) DEFAULT (SHARED)
            !PRIVATE ()
            do face_index = 1, face_count

                first_face_catchment_index = face_catchment_1(face_index)
                second_face_catchment_index = face_catchment_2(face_index)

                ! Bed and water-surface elevations for the two connected catchments.
                first_bed_elevation = stage_table(1, first_face_catchment_index)
                first_water_surface_elevation = water_depth(first_face_catchment_index) + &
                                                first_bed_elevation
                second_bed_elevation = stage_table(1, second_face_catchment_index)
                second_water_surface_elevation = water_depth(second_face_catchment_index) + &
                                                 second_bed_elevation

                ! Lateral connections are set for overland flow only. Turn off to use
                ! bifurcation mode
                if ((second_water_surface_elevation > first_water_surface_elevation) .and. &
                    (water_depth(second_face_catchment_index) > &
                     bankfull_depth(second_face_catchment_index))) then
                    !OK Water is passing through lateral connections
                elseif ((first_water_surface_elevation > second_water_surface_elevation) .and. &
                        (water_depth(first_face_catchment_index) > &
                         bankfull_depth(first_face_catchment_index))) then
                    !OK Water is passing through lateral connections
                else
                    cycle
                    !Water is not passing through lateral connections
                end if

                ! Flow depth above the higher bed controls the connection.
                flow_depth = max(second_water_surface_elevation, first_water_surface_elevation) - &
                             max(second_bed_elevation, first_bed_elevation)
                ! Prevent a negative flow depth.
                flow_depth = max(flow_depth, 0.0)

                flow_length = dble(face_distance(face_index))

                ! These values are configured by the routing namelist.

                ! Discharge per unit width from the preceding inertial timestep.
                previous_unit_width_q = face_q(face_index)/overland_flow_width
                ! m2/s

                ! Water-surface slope across the connection.
                flow_slope = -(first_water_surface_elevation - second_water_surface_elevation)/ &
                             flow_length

                ! Inertial discharge per unit width at the downstream face.
                if (flow_depth > 0.0) then
              q = (previous_unit_width_q - (gravity*inertial_timestep*flow_depth*flow_slope))/(1.+ &
                       gravity*inertial_timestep*flow_depth*overland_manning_n*overland_manning_n* &
                                                    abs(previous_unit_width_q)/(flow_depth**(10.0/ &
                                                                                              3.0)))
                    q = q*overland_flow_width
                else
                    q = 0.0
                end if

                ! Store discharge for the next inertial timestep.
                face_q(face_index) = q
                ! m3/s
                neighbor_q(first_face_catchment_index) = neighbor_q(first_face_catchment_index) - &
                                                         face_q(face_index)
               neighbor_q(second_face_catchment_index) = neighbor_q(second_face_catchment_index) + &
                                                          face_q(face_index)

            end do
!    !$OMP END PARALLEL DO
        end if

    end subroutine calculate_inertial_discharge

    subroutine update_inertial_continuity
        use simulation_state, only: first_subbasin, last_subbasin, model_timestep, &
                                    timestep_index
        use catchment_state, only: catchment_area, catchment_count, catchment_index, &
                                   catchment_subbasin, subbasin_index
        use meteorological_state, only: precipitation
        use water_balance_state, only: catchment_q_current, floodplain_infiltration, &
                                       potential_open_water_et, total_water_storage
        use reservoir_state, only: reservoir_index_by_catchment, reservoir_start_timestep
        use inertial_state, only: area_table, current_flooded_area, current_water_volume, &
                     floodplain_point_count, inertial_elapsed_time, inertial_q, inertial_timestep, &
                         interpolated_area, interpolated_stage, neighbor_q, previous_water_volume, &
                         remaining_model_timestep, stage_table, stage_table_index, sum_upstream_q, &
                       thread_count, upstream_count, upstream_topology, volume_table, water_depth, &
                                  water_surface_elevation
        use output_state, only: et_output, open_water_et_output, surface_water_output

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

    subroutine interpolate_stage_area(current_water_volume, volume_table, stage_table_index, &
                          target_catchment_index, stage_table, area_table, floodplain_point_count, &
                                    catchment_count_argument, interpolated_stage, interpolated_area)

        implicit none

        integer, intent(in) :: target_catchment_index, catchment_count_argument
        integer, intent(in) :: floodplain_point_count(catchment_count_argument)
        integer, intent(inout) :: stage_table_index(catchment_count_argument)
        real(kind=8), intent(in) :: current_water_volume(catchment_count_argument)
        real(kind=8), intent(in) :: volume_table(102, catchment_count_argument)
        real(kind=8), intent(in) :: stage_table(102, catchment_count_argument)
        real(kind=8), intent(in) :: area_table(102, catchment_count_argument)
        real(kind=8), intent(out) :: interpolated_stage
        real(kind=8), intent(out) :: interpolated_area
        real(kind=8) :: interpolation_fraction

        do
            if ((current_water_volume(target_catchment_index) >= &
            volume_table(stage_table_index(target_catchment_index), target_catchment_index)) .and. &
                (current_water_volume(target_catchment_index) <= &
                 volume_table(stage_table_index(target_catchment_index) + 1, &
                              target_catchment_index))) then

                !Finds the % over the actual index of stage-area-volume table:
                interpolation_fraction = (current_water_volume(target_catchment_index) - &
                 volume_table(stage_table_index(target_catchment_index), target_catchment_index))/ &
                                      (volume_table(stage_table_index(target_catchment_index) + 1, &
                                                       target_catchment_index) - &
                                          volume_table(stage_table_index(target_catchment_index), &
                                                       target_catchment_index))
                !Interpolates values based on % above:
                interpolated_stage = stage_table(stage_table_index(target_catchment_index), &
                target_catchment_index) + (stage_table(stage_table_index(target_catchment_index) + &
               1, target_catchment_index) - stage_table(stage_table_index(target_catchment_index), &
                                                                         target_catchment_index))* &
                                     interpolation_fraction
                interpolated_area = area_table(stage_table_index(target_catchment_index), &
                 target_catchment_index) + (area_table(stage_table_index(target_catchment_index) + &
                1, target_catchment_index) - area_table(stage_table_index(target_catchment_index), &
                                                                         target_catchment_index))* &
                                    interpolation_fraction

                exit

            elseif (current_water_volume(target_catchment_index) > &
                    volume_table(stage_table_index(target_catchment_index) + 1, &
                                 target_catchment_index)) then
           stage_table_index(target_catchment_index) = stage_table_index(target_catchment_index) + &
                                                            1

                !Check for outside (upper) table bounds
 if (stage_table_index(target_catchment_index) > (floodplain_point_count(target_catchment_index) + &
                                                                 1)) then

                    ! In this case, an extrapolation is needed. We consider a constant flooded area
                    ! over
                    ! the upper bound in stage_table
                    ! Calculates the difference (dV) between the actual volume and maximum volume
                    ! of the stage-area table.
                    ! area-volume table
                    ! Level is computed as Zmax + dV/Amax, where A is assumed to be constant in this
                    ! interval.

                    interpolated_stage = stage_table(stage_table_index(target_catchment_index), &
                         target_catchment_index) + (current_water_volume(target_catchment_index) - &
                                           volume_table(stage_table_index(target_catchment_index), &
                                                                         target_catchment_index))/ &
                                         (area_table(stage_table_index(target_catchment_index), &
                                                     target_catchment_index)*1000000.0)
                    !interpolated_area remains unchanged
                    interpolated_area = area_table(stage_table_index(target_catchment_index), &
                                                   target_catchment_index)

                    ! Avoids access violation of array upper bounds when calling this subroutine.
                    ! again)
           stage_table_index(target_catchment_index) = stage_table_index(target_catchment_index) - &
                                                                1
                    exit
                    !Exit subroutine %Vinicius Siqueira, 27/12/2016
                end if

            else
           stage_table_index(target_catchment_index) = stage_table_index(target_catchment_index) - &
                                                            1
            end if

        end do

    end subroutine interpolate_stage_area

end module inertial_routing
