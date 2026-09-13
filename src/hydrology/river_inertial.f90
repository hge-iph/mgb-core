module river_inertial

    implicit none
    private
    public :: prepare_inertial_routing, initialize_inertial_routing, route_inertial_flow

contains

    subroutine prepare_inertial_routing
        use attributes, only: downstream_catchment
        use parameters, only: routing_downstream_catchment

        implicit none

        call build_flood_topology
        call build_floodplain_tables
        routing_downstream_catchment = downstream_catchment
    end subroutine prepare_inertial_routing

    subroutine build_flood_topology
        use config, only: catchment_count
        use attributes, only: downstream_catchment
        use parameters, only: upstream_topology

        implicit none

        ! Symbols:
        ! i_catch   catchment index [1]
        ! i_down    downstream-catchment index [1]
        ! i_up_slot upstream-topology slot index [1]
        integer :: i_catch
        integer :: i_down
        integer :: i_up_slot

        upstream_topology = 0

        do i_catch = 1, catchment_count
            i_down = downstream_catchment(i_catch)
            !Identifying the downstream catchment of i_catch
            if (i_down < 0) cycle
            !This catchment is a outlet
            upstream_topology(i_down, 1) = upstream_topology(i_down, 1) + 1
            i_up_slot = upstream_topology(i_down, 1)
            upstream_topology(i_down, 1 + i_up_slot) = i_catch
        end do

        return
    end subroutine build_flood_topology

    subroutine build_floodplain_tables
        use config, only: catchment_count
        use attributes, only: &
            & bankfull_depth, &
            & floodplain_area, &
            & floodplain_bottom_elevation, &
            & floodplain_elevation, &
            & floodplain_point_count, &
            & river_length, &
            & river_width
        use parameters, only: &
            & area_table, &
            & stage_table, &
            & volume_table

        implicit none
        ! Symbols:
        ! i_catch  catchment index [1]
        ! i_point  floodplain-point index [1]
        ! dz       elevation increment [m]
        ! dv       volume increment [m3]
        ! a_prev   preceding floodplain area [km2]
        ! a_curr   current floodplain area [km2]
        integer :: i_catch
        integer :: i_point
        real :: dz
        real :: dv
        real*8 :: a_prev
        real*8 :: a_curr
        real*8 :: first_level_volume
        real*8 :: first_level_depth

        do i_catch = 1, catchment_count

            ! The first three points describe the channel and first floodplain level.
            stage_table(1, i_catch) = floodplain_bottom_elevation(i_catch) - bankfull_depth(i_catch)
            volume_table(1, i_catch) = 0.0
            area_table(1, i_catch) = dble(river_width(i_catch))*dble(river_length(i_catch))/1000.0
            stage_table(2, i_catch) = floodplain_bottom_elevation(i_catch)
            volume_table(2, i_catch) = dble(river_width(i_catch))*bankfull_depth(i_catch)*dble(river_length(i_catch))*1000.0
            area_table(2, i_catch) = area_table(1, i_catch)
            stage_table(3, i_catch) = floodplain_elevation(1, i_catch)
            area_table(3, i_catch) = max(area_table(2, i_catch), floodplain_area(1, i_catch))

            volume_table(3, i_catch) = volume_table(2, i_catch) + &
                & 0.5*(floodplain_area(1, i_catch) + 0.0)* &
                & (stage_table(3, i_catch) - stage_table(2, i_catch))*1000000.0

            ! Integrate later levels with the trapezoidal rule.
            do i_point = 1, floodplain_point_count(i_catch) - 1
                stage_table(i_point + 3, i_catch) = floodplain_elevation(i_point + 1, i_catch)
                area_table(i_point + 3, i_catch) = floodplain_area(i_point + 1, i_catch)
                dz = floodplain_elevation(i_point + 1, i_catch) - floodplain_elevation(i_point, i_catch)
                a_prev = floodplain_area(i_point, i_catch)
                a_curr = floodplain_area(i_point + 1, i_catch)
                dv = dz*1000000.0*((a_prev + a_curr)*0.5)
                volume_table(i_point + 3, i_catch) = volume_table(i_point + 2, i_catch) + dv
            end do

        end do

        return
    end subroutine build_floodplain_tables

    subroutine initialize_inertial_routing
        use interpolation, only: linear_interpolate
        use config, only: catchment_count
        use attributes, only: &
            & catchment_area, &
            & floodplain_point_count, &
            & n_manning, &
            & river_length, &
            & river_slope, &
            & river_width
        use parameters, only: &
            & area_table, &
            & reference_q, &
            & stage_table, &
            & volume_table
        use state, only: &
            & current_flooded_area, &
            & current_water_volume, &
            & face_q, &
            & grace_total_water_storage, &
            & inertial_q, &
            & neighbor_q, &
            & previous_water_volume, &
            & stage_table_index, &
            & water_depth, &
            & water_surface_elevation

        implicit none

        ! Symbols:
        ! i_catch catchment index [1]
        ! c_r       hydraulic rating-curve scale [m^0.2 s^0.6]
        ! e_r       hydraulic rating-curve exponent [1]
        ! q         routed river discharge [m3/s]
        ! v         river-water volume [m3]
        ! a         flooded area [km2]
        ! n_points  stage-area table point count [1]
        integer :: i_catch
        integer :: n_points
        real*8 :: c_r
        real*8 :: e_r
        real*8 :: q
        real*8 :: v
        real*8 :: a
        neighbor_q = 0.0
        grace_total_water_storage = 0.0

        do i_catch = 1, catchment_count

            c_r = (n_manning(i_catch)*(dble(river_width(i_catch))**(2.0/3.0)))**0.6/((river_slope(i_catch)**0.5)**0.6)
            e_r = 0.6
            inertial_q(i_catch) = reference_q(i_catch)
            face_q = reference_q(i_catch)
            water_depth(i_catch) = c_r*(inertial_q(i_catch)**e_r)/dble(river_width(i_catch)) + 0.00001
            water_surface_elevation(i_catch) = stage_table(1, i_catch) + water_depth(i_catch)
            previous_water_volume(i_catch) = water_depth(i_catch)*dble(river_width(i_catch))*(river_length(i_catch)*1000.)
            current_water_volume(i_catch) = previous_water_volume(i_catch)
            current_flooded_area(i_catch) = linear_interpolate( &
                & volume_table(:, i_catch), area_table(:, i_catch), floodplain_point_count(i_catch) + 2, current_water_volume(i_catch))
            current_flooded_area(i_catch) = max(current_flooded_area(i_catch), catchment_area(i_catch))
            stage_table_index(i_catch) = 1

        end do

    end subroutine

    subroutine route_inertial_flow( &
        & i_step)
        use config, only: model_timestep

        implicit none

        ! Symbols:
        ! i_step        current model timestep index [1]
        ! dt_route      selected inertial substep [s]
        ! dt_elapsed    elapsed time in the current model step [s]
        ! dt_remaining  model timestep duration [s]
        integer, intent(in) :: i_step
        real*8, volatile :: dt_elapsed
        real*8, volatile :: dt_route
        real*8, volatile :: dt_remaining

        !Initializes aggregating time step loop variable
        dt_elapsed = 0.0
        dt_remaining = dble(model_timestep)

        !Intertial Routing loop
        do while (dt_elapsed < dt_remaining)

            call calculate_inertial_timestep( &
                & dt_route)

            ! Needed to adjust routing time step at last loop interval (i.e. in order to not exceed
            ! Water balance timestep in seconds.
            dt_route = min(dt_route, dt_remaining - dt_elapsed)

            !Updates the loop variable
            dt_elapsed = dt_elapsed + dt_route

            call calculate_inertial_discharge( &
                & i_step, &
                & dt_route, &
                & dt_elapsed, &
                & dt_remaining)
            call update_inertial_continuity( &
                & i_step, &
                & dt_route, &
                & dt_elapsed, &
                & dt_remaining)

        end do

        return
    end subroutine

    subroutine calculate_inertial_timestep( &
        & dt_route)
        use config, only: &
            & catchment_count, &
            & courant_alpha, &
            & first_subbasin, &
            & gravity, &
            & last_subbasin, &
            & model_timestep
        use attributes, only: &
            & catchment_subbasin, &
            & river_length
        use state, only: water_depth

        implicit none

        ! Symbols:
        ! i_catch      catchment index [1]
        ! i_sub        subbasin index [1]
        ! h_max        flow depth used by the CFL condition [m]
        ! dt_route     selected inertial timestep [s]
        ! dt_cand      candidate inertial timestep [s]
        ! dt_min       minimum timestep bound [s]
        ! dt_cfl       CFL timestep candidate [s]
        ! dt_max       maximum timestep bound [s]
        real*8, intent(out) :: dt_route
        integer :: i_catch
        integer :: i_sub
        real*8, volatile :: h_max
        real*8, volatile :: dt_min
        real*8, volatile :: dt_cand
        real*8, volatile :: dt_cfl
        real*8, volatile :: dt_max

        dt_cand = dble(model_timestep)

        do i_catch = 1, catchment_count
            !Catchment loop

            i_sub = catchment_subbasin(i_catch)
            if ((i_sub < first_subbasin) .or. (i_sub > last_subbasin)) cycle
            ! Manual controls for specialized calibration

            ! MAX H to calculates the time-step of Inertial model:
            h_max = (water_depth(i_catch))
            ! Correct if equal to zero:
            h_max = max(h_max, 0.001)
            ! Compute time interval:
            dt_cfl = courant_alpha*river_length(i_catch)*1000./(gravity*h_max)**0.5
            if (dt_cfl < dt_cand) dt_cand = dt_cfl
        end do

        ! Do not exceed the main model timestep.
        dt_max = dble(model_timestep)
        dt_min = dt_cand
        dt_route = min(dt_max, dt_min)

    end subroutine

    subroutine calculate_inertial_discharge( &
        & i_step, &
        & dt_route, &
        & dt_elapsed, &
        & dt_remaining)
        use config, only: &
            & catchment_count, &
            & downstream_water_surface_slope, &
            & face_count, &
            & first_subbasin, &
            & gravity, &
            & last_subbasin, &
            & overland_flow_width, &
            & overland_manning_n, &
            & pseudo_two_d_enabled, &
            & thread_count
        use forcing, only: reservoir_outflow
        use attributes, only: &
            & bankfull_depth, &
            & catchment_subbasin, &
            & face_catchment_1, &
            & face_catchment_2, &
            & face_distance, &
            & n_manning, &
            & river_length, &
            & river_width
        use parameters, only: &
            & reservoir_index_by_catchment, &
            & routing_downstream_catchment, &
            & stage_table
        use state, only: &
            & face_q, &
            & flow_velocity, &
            & inertial_q, &
            & neighbor_q, &
            & outgoing_q_current, &
            & q_river_output, &
            & water_depth

        use omp_lib

        implicit none

        integer, intent(in) :: i_step
        real*8, intent(in) :: dt_route
        real*8, intent(in) :: dt_elapsed
        real*8, intent(in) :: dt_remaining

        ! Symbols:
        ! i_catch       catchment index [1]
        ! i_sub         subbasin index [1]
        ! i_down        downstream-catchment index [1]
        ! i_face        lateral-face index [1]
        ! i_face_up     first face-catchment index [1]
        ! i_face_down   second face-catchment index [1]
        ! i_res         reservoir index [1]
        ! z_up          upstream bed elevation [m]
        ! z_down        downstream bed elevation [m]
        ! y_up          upstream water-surface elevation [m]
        ! y_down        downstream water-surface elevation [m]
        ! h_flow        flow depth [m]
        ! dx            flow-path length [m]
        ! b_flow        river-flow width [m]
        ! n_flow         Manning roughness [s/m^(1/3)]
        ! q_width_prev   previous discharge per unit width [m2/s]
        ! s_flow         water-surface slope [1]
        ! q              updated discharge [m3/s]
        ! b_face        lateral-face width [m]
        ! n_face        lateral-face Manning roughness [s/m^(1/3)]
        ! q_numerator   inertial-equation momentum numerator [m2/s]
        ! q_denominator inertial-equation friction denominator [1]
        ! q_previous    previous routed river discharge [m3/s]
        ! q_target      prescribed reservoir discharge [m3/s]
        integer :: i_catch
        integer :: i_sub
        integer :: i_down
        integer :: i_face
        integer :: i_face_up
        integer :: i_face_down
        integer :: i_res
        real*8, volatile :: z_up
        real*8, volatile :: z_down
        real*8, volatile :: y_up
        real*8, volatile :: y_down
        real*8, volatile :: h_flow
        real*8, volatile :: dx
        real*8, volatile :: b_flow
        real*8, volatile :: n_flow
        real*8, volatile :: q_width_prev
        real*8, volatile :: s_flow
        real*8, volatile :: q
        real*8, volatile :: b_face
        real*8, volatile :: n_face
        real*8 :: q_numerator
        real*8 :: q_denominator
        real*8 :: q_previous
        real*8 :: q_target

        b_face = overland_flow_width
        n_face = overland_manning_n
        !Start catchment loop
        !$omp parallel num_threads(thread_count)

        !$omp do &
        !$omp& private(i_sub,y_up,y_down,z_up,z_down,i_down,i_res,h_flow,dx,b_flow,n_flow,q_width_prev,s_flow,q, &
        !$omp& q_numerator,q_denominator,q_previous,q_target)
        do i_catch = 1, catchment_count

            ! Manual controls for specialized calibration
            i_sub = catchment_subbasin(i_catch)
            if ((i_sub < first_subbasin) .or. (i_sub > last_subbasin)) cycle

            ! Bottom level and water level of i_catch catchment:
            z_up = stage_table(1, i_catch)
            y_up = water_depth(i_catch) + z_up

            ! Bottom level and water level of downstream i_catch catchment:
            i_down = routing_downstream_catchment(i_catch)
            ! SIN_RESERV

            ! Negative indices mark a basin outlet (-1) or reservoir dam (-2).
            if (i_down < 0) then
                ! SIN_RESERV

                ! Reservoir-dam boundaries use a fixed 0.1 m/km fall.
                if (i_down == -2) then
                    ! SIN_RESERV
                    z_down = z_up - 0.0001*dble(river_length(i_catch)*1000.)
                    ! SIN_RESERV (0.1 m/km)
                    y_down = y_up - 0.0001*dble(river_length(i_catch)*1000.)
                    ! SIN_RESERV (0.1 m/km)
                elseif (downstream_water_surface_slope <= 0.000000000001) then
                    ! If slope = 0.00, water is reaching Oceans/Endorreic Lakes -> Fixed level
                    ! condition !
                    z_down = z_up
                    y_down = dble(bankfull_depth(i_catch)) + z_down
                else
                    ! Use the configured downstream boundary condition.
                    z_down = z_up - downstream_water_surface_slope*dble(river_length(i_catch)*1000.)
                    y_down = y_up - downstream_water_surface_slope*dble(river_length(i_catch)*1000.)
                end if

            else
                !Computes downstream water elevation
                z_down = stage_table(1, i_down)
                y_down = water_depth(i_down) + z_down
            end if

            ! Calculates the h_flow variable:
            h_flow = max(y_down, y_up) - max(z_down, z_up)
            h_flow = max(h_flow, 0.0)

            if (i_down /= -1) then
                dx = dble(river_length(i_catch)*1000.) + dble(river_length(i_down)*1000.)
                dx = dx/2.
                !River width
                b_flow = dble(river_width(i_catch)) + dble(river_width(i_down))
                b_flow = b_flow/2.
            else

                !Considering the upstream length
                dx = dble(river_length(i_catch)*1000.)
                b_flow = dble(river_width(i_catch))
            end if

            !River manning coefficient
            n_flow = n_manning(i_catch)

            ! Flow in the last time-step
            q_width_prev = inertial_q(i_catch)/b_flow
            ! in m2/s

            ! Water table slope:
            s_flow = -(y_up - y_down)/dx

            ! Calculates flow from Inertial equation (m2/s) for each i_catch:
            if (h_flow > 0.0) then
                q_numerator = q_width_prev - gravity*dt_route*h_flow*s_flow
                q_denominator = 1. + gravity*dt_route*h_flow*n_flow*n_flow*abs(q_width_prev)/(h_flow**(10.0/3.0))
                q = q_numerator/q_denominator
                q = q*b_flow
                !(m3/s)

                !Froude limiter for supercritical flow conditions

                if (q > 0) then
                    q = min(q, b_flow*(h_flow**1.5)*9.81**0.5)
                    !avoid supercritical flow
                else
                    q = max(q, -b_flow*(h_flow**1.5)*9.81**0.5)
                    !avoid supercritical flow
                end if
                !endif

            else
                q = 0.0
            end if

            !! SIN_RESERV
            i_res = reservoir_index_by_catchment(i_catch)
            if (i_res > 0) then
                if (reservoir_outflow(i_step, i_res) > -0.01) then
                    q_previous = q_river_output(i_catch)
                    q_target = reservoir_outflow(i_step, i_res)
                    q = q_previous + dt_elapsed/dt_remaining*(q_target - q_previous)
                end if
            end if
            !! SIN_RESERV

            ! Updates variable flow inertial:
            inertial_q(i_catch) = q
            ! in m3/s
            outgoing_q_current(i_catch) = inertial_q(i_catch)
            ! in m3/s
            flow_velocity(i_catch) = real(q/(b_flow*h_flow))
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
            do i_face = 1, face_count

                i_face_up = face_catchment_1(i_face)
                i_face_down = face_catchment_2(i_face)

                ! Bed and water-surface elevations for the two connected catchments.
                z_up = stage_table(1, i_face_up)
                y_up = water_depth(i_face_up) + z_up
                z_down = stage_table(1, i_face_down)
                y_down = water_depth(i_face_down) + z_down

                ! Lateral connections are set for overland flow only. Turn off to use
                ! bifurcation mode
                if ((y_down > y_up) .and. &
                    & (water_depth(i_face_down) > bankfull_depth(i_face_down))) then
                    !OK Water is passing through lateral connections
                elseif ((y_up > y_down) .and. &
                    & (water_depth(i_face_up) > bankfull_depth(i_face_up))) then
                    !OK Water is passing through lateral connections
                else
                    cycle
                    !Water is not passing through lateral connections
                end if

                ! Flow depth above the higher bed controls the connection.
                h_flow = max(y_down, y_up) - max(z_down, z_up)
                ! Prevent a negative flow depth.
                h_flow = max(h_flow, 0.0)

                dx = dble(face_distance(i_face))

                ! These values are configured by the routing namelist.

                ! Discharge per unit width from the preceding inertial timestep.
                q_width_prev = face_q(i_face)/b_face
                ! m2/s

                ! Water-surface slope across the connection.
                s_flow = -(y_up - y_down)/dx

                ! Inertial discharge per unit width at the downstream face.
                if (h_flow > 0.0) then
                    q_numerator = q_width_prev - gravity*dt_route*h_flow*s_flow
                    q_denominator = 1. + gravity*dt_route*h_flow*n_face*n_face*abs(q_width_prev)/(h_flow**(10.0/3.0))
                    q = q_numerator/q_denominator
                    q = q*b_face
                else
                    q = 0.0
                end if

                ! Store discharge for the next inertial timestep.
                face_q(i_face) = q
                ! m3/s
                neighbor_q(i_face_up) = neighbor_q(i_face_up) - face_q(i_face)
                neighbor_q(i_face_down) = neighbor_q(i_face_down) + face_q(i_face)

            end do
            !    !$OMP END PARALLEL DO
        end if

    end subroutine calculate_inertial_discharge

    subroutine update_inertial_continuity( &
        & i_step, &
        & dt_route, &
        & dt_elapsed, &
        & dt_remaining)
        use config, only: &
            & catchment_count, &
            & first_subbasin, &
            & last_subbasin, &
            & model_timestep, &
            & thread_count
        use forcing, only: precipitation
        use attributes, only: &
            & catchment_area, &
            & catchment_subbasin, &
            & floodplain_point_count
        use parameters, only: &
            & area_table, &
            & reservoir_index_by_catchment, &
            & reservoir_start_timestep, &
            & stage_table, &
            & upstream_topology, &
            & volume_table
        use state, only: &
            & catchment_q_current, &
            & current_flooded_area, &
            & current_water_volume, &
            & et_output, &
            & floodplain_infiltration, &
            & inertial_q, &
            & neighbor_q, &
            & open_water_et_output, &
            & potential_open_water_et, &
            & previous_water_volume, &
            & stage_table_index, &
            & surface_water_output, &
            & total_water_storage, &
            & water_depth, &
            & water_surface_elevation

        use omp_lib

        implicit none

        integer, intent(in) :: i_step
        real*8, intent(in) :: dt_route
        real*8, intent(in) :: dt_elapsed
        real*8, intent(in) :: dt_remaining

        ! Symbols:
        ! i_catch       catchment index [1]
        ! i_sub         subbasin index [1]
        ! n_up          upstream-catchment count [1]
        ! r             catchment runoff entering the river [m3/s]
        ! q             routed river discharge [m3/s]
        ! q_up          total upstream river discharge [m3/s]
        ! q_neighbor    net lateral river discharge [m3/s]
        ! q_net         net horizontal discharge into river storage [m3/s]
        ! p             precipitation [mm per model timestep]
        ! d_et          potential open-water evaporation [mm per model timestep]
        ! d_infil       floodplain infiltration [mm per model timestep]
        ! d_vertical    net vertical water-loss depth [mm per model timestep]
        ! a_flood       flooded area [km2]
        ! a_catch       catchment area [km2]
        ! v_prev        previous river-water volume [m3]
        ! v             updated river-water volume [m3]
        ! d_et_output   open-water evaporation output depth [mm per model timestep]
        ! d_storage     river-storage output depth [mm]
        ! y             interpolated water-surface elevation [m]
        ! a             interpolated flooded area [km2]
        integer :: i_catch
        integer :: i_sub
        integer :: n_up
        real*8, volatile :: q_up
        real*8, volatile :: q_net
        real*8, volatile :: y
        real*8, volatile :: a
        real, volatile :: r
        real*8, volatile :: q
        real*8, volatile :: q_neighbor
        real, volatile :: p
        real, volatile :: d_et
        real, volatile :: d_infil
        real, volatile :: d_vertical
        real*8, volatile :: a_flood
        real, volatile :: a_catch
        real*8, volatile :: v_prev
        real*8, volatile :: v
        real*8, volatile :: d_et_output
        real, volatile :: d_storage

        surface_water_output = 0.0

        !$omp parallel num_threads(thread_count)
        !$omp do &
        !$omp& private(i_sub,n_up,r,q,q_up,q_neighbor,q_net,p,d_et,d_infil,d_vertical,a_flood,a_catch,v_prev,v, &
        !$omp& d_et_output,d_storage,a,y)
        do i_catch = 1, catchment_count

            i_sub = catchment_subbasin(i_catch)
            if ((i_sub < first_subbasin) .or. (i_sub > last_subbasin)) cycle
            ! Manual controls for specialized calibration

            r = catchment_q_current(i_catch)
            q = inertial_q(i_catch)
            q_neighbor = neighbor_q(i_catch)
            p = precipitation(i_catch)
            d_et = potential_open_water_et(i_catch)
            d_infil = floodplain_infiltration(i_catch)
            a_flood = current_flooded_area(i_catch)
            a_catch = catchment_area(i_catch)
            v_prev = previous_water_volume(i_catch)

            !Number of upstream catchments of i_catch
            n_up = upstream_topology(i_catch, 1)

            !Sum of downstream i_catch flows
            if (upstream_topology(i_catch, 1) == 0) then
                q_up = 0.0
            else
                q_up = sum(inertial_q(upstream_topology(i_catch, 2:1 + n_up)))
            end if

            !to use lateral connections
            d_vertical = d_et + d_infil - p
            q_net = q_up + r - q + q_neighbor
            v = v_prev + dt_route*q_net - d_vertical*dt_route*a_flood*1000000.0/(model_timestep*1000.)
            v = max(v, 0.0)
            current_water_volume(i_catch) = v

            !! SIN_RESERV
            if (reservoir_index_by_catchment(i_catch) > 0 .and. &
                & reservoir_start_timestep(i_catch) <= i_step) then
                current_water_volume(i_catch) = min(current_water_volume(i_catch), volume_table(2, i_catch))
                ! max vol calha cheia
            end if
            !! SIN_RESERV

            !!Added to include evaporation of open waters from floodplain dynamics
            d_et_output = ((d_et*dt_route*a_flood*1000000.0/(model_timestep*1000.))/(a_catch*1000))
            et_output(i_catch) = et_output(i_catch) + d_et_output
            ! mm per model timestep
            open_water_et_output(i_catch) = open_water_et_output(i_catch) + d_et_output
            ! mm per model timestep

            !Interpolates the Area and Level from Volume
            call interpolate_stage_area( &
                & current_water_volume, &
                & volume_table, &
                & stage_table_index, &
                & i_catch, &
                & stage_table, &
                & area_table, &
                & floodplain_point_count, &
                & catchment_count, &
                & y, &
                & a)

            current_flooded_area(i_catch) = min(a, catchment_area(i_catch))

            !Updates variables:
            water_surface_elevation(i_catch) = max(y, stage_table(1, i_catch) + 0.001)

            !Calculates depth
            water_depth(i_catch) = water_surface_elevation(i_catch) - stage_table(1, i_catch)

            !Updates the volume
            previous_water_volume(i_catch) = current_water_volume(i_catch)

            if (dt_elapsed/dt_remaining == 1) then

                !Update Terrestrial Water Storage at the end of inertial loop
                d_storage = real(current_water_volume(i_catch)/dble(a_catch*1000.0))
                total_water_storage(i_catch) = total_water_storage(i_catch) + d_storage
                surface_water_output(i_catch) = surface_water_output(i_catch) + d_storage

            end if

        end do
        !$omp end do
        !$omp end parallel

    end subroutine

    subroutine interpolate_stage_area( &
        & v, &
        & vt, &
        & j_stage, &
        & i_catch, &
        & st, &
        & at, &
        & n_pts, &
        & n_catch, &
        & y, &
        & a)

        implicit none

        ! Symbols:
        ! i_catch catchment index [1]
        ! n_catch catchment table count [1]
        ! j_stage current stage-table index [1]
        ! n_pts   stage-table point count [1]
        ! v       current water volume [m3]
        ! vt      tabulated water volume [m3]
        ! st      tabulated stage [m]
        ! at      tabulated flooded area [km2]
        ! f       interpolation fraction [1]
        ! y       interpolated stage [m]
        ! a       interpolated flooded area [km2]
        ! dv      tabulated volume interval [m3]
        ! v_excess volume above the tabulated range [m3]
        integer, intent(in) :: i_catch
        integer, intent(in) :: n_catch
        integer, intent(in) :: n_pts(n_catch)
        integer, intent(inout) :: j_stage(n_catch)
        real(kind=8), intent(in) :: v(n_catch)
        real(kind=8), intent(in) :: vt(102, n_catch)
        real(kind=8), intent(in) :: st(102, n_catch)
        real(kind=8), intent(in) :: at(102, n_catch)
        real(kind=8), intent(out) :: y
        real(kind=8), intent(out) :: a
        real(kind=8) :: f
        real(kind=8) :: dv
        real(kind=8) :: v_excess

        do
            if ((v(i_catch) >= vt(j_stage(i_catch), i_catch)) .and. &
                & (v(i_catch) <= vt(j_stage(i_catch) + 1, i_catch))) then

                !Finds the % over the actual index of stage-area-volume table:
                f = (v(i_catch) - vt(j_stage(i_catch), i_catch))/ &
                    & (vt(j_stage(i_catch) + 1, i_catch) - vt(j_stage(i_catch), i_catch))
                !Interpolates values based on % above:
                y = st(j_stage(i_catch), i_catch) + (st(j_stage(i_catch) + 1, i_catch) - st(j_stage(i_catch), i_catch))*f
                a = at(j_stage(i_catch), i_catch) + (at(j_stage(i_catch) + 1, i_catch) - at(j_stage(i_catch), i_catch))*f

                exit

            elseif (v(i_catch) > vt(j_stage(i_catch) + 1, i_catch)) then
                j_stage(i_catch) = j_stage(i_catch) + 1

                !Check for outside (upper) table bounds
                if (j_stage(i_catch) > (n_pts(i_catch) + 1)) then

                    ! In this case, an extrapolation is needed. We consider a constant flooded area
                    ! over
                    ! the upper bound in stage_table
                    ! Calculates the difference (dV) between the actual volume and maximum volume
                    ! of the stage-area table.
                    ! area-volume table
                    ! Level is computed as Zmax + dV/Amax, where A is assumed to be constant in this
                    ! interval.

                    y = st(j_stage(i_catch), i_catch) + (v(i_catch) - &
                        & vt(j_stage(i_catch), i_catch))/(at(j_stage(i_catch), i_catch)*1000000.0)
                    !a remains unchanged
                    a = at(j_stage(i_catch), i_catch)

                    ! Avoids access violation of array upper bounds when calling this subroutine.
                    ! again)
                    j_stage(i_catch) = j_stage(i_catch) - 1
                    exit
                    !Exit subroutine %Vinicius Siqueira, 27/12/2016
                end if

            else
                j_stage(i_catch) = j_stage(i_catch) - 1
            end if

        end do

    end subroutine interpolate_stage_area

end module river_inertial
