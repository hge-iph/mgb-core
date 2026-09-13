module river_muskingum

    implicit none
    private
    public :: calculate_muskingum_cunge_parameters, initialize_muskingum_cunge_routing, &
        & route_muskingum_cunge_network

contains

    subroutine initialize_muskingum_cunge_routing
        use config, only: catchment_count, substitution_count
        use forcing, only: substituted_q
        use attributes, only: downstream_catchment
        use parameters, only: muskingum_reach_count, substitution_catchment
        use state, only: catchment_q_current, catchment_q_previous, groundwater_q, &
            & incoming_q_boundary, incoming_q_current, incoming_q_previous, &
            & incoming_groundwater_fraction_current, incoming_subsurface_fraction_current, &
            & incoming_surface_fraction_current, initial_river_q, &
            & outgoing_q_boundary, outgoing_q_current, outgoing_q_previous, subsurface_q, surface_q

        implicit none

        ! Symbols:
        ! i_catch, i_down, i_subst catchment, downstream, and substitution indices [1]
        integer :: i_catch, i_down, i_subst

        incoming_q_current = 0.0
        incoming_groundwater_fraction_current = 0.0
        incoming_subsurface_fraction_current = 0.0
        incoming_surface_fraction_current = 0.0
        incoming_q_previous = 0.0
        outgoing_q_previous = 0.0
        outgoing_q_current = 0.0
        catchment_q_previous = 0.0
        catchment_q_current = 0.0
        initial_river_q = 0.0
        incoming_q_boundary = 0.0
        outgoing_q_boundary = 0.0

        do i_catch = 1, catchment_count
            catchment_q_current(i_catch) = groundwater_q(i_catch) + subsurface_q(i_catch) + &
                & surface_q(i_catch)
            catchment_q_previous(i_catch) = catchment_q_current(i_catch)
            if (muskingum_reach_count(i_catch) .gt. 0) then
                incoming_q_current(i_catch) = incoming_q_current(i_catch) + &
                    & catchment_q_current(i_catch)
                outgoing_q_current(i_catch) = incoming_q_current(i_catch)
                i_down = downstream_catchment(i_catch)
                if (i_down > 0) incoming_q_current(i_down) = incoming_q_current(i_down) + &
                    & outgoing_q_current(i_catch)
            else
                outgoing_q_current(i_catch) = catchment_q_current(i_catch)
                incoming_q_current(i_catch) = catchment_q_current(i_catch)
                i_down = downstream_catchment(i_catch)
                if (i_down > 0) incoming_q_current(i_down) = incoming_q_current(i_down) + &
                    & catchment_q_current(i_catch)
            end if
            do i_subst = 1, substitution_count
                if (i_catch == substitution_catchment(i_subst)) then
                    incoming_q_current(i_down) = substituted_q(i_subst, 1)
                    exit
                end if
            end do
        end do
        outgoing_q_previous = outgoing_q_current
        incoming_q_previous = incoming_q_current
        do i_catch = 1, catchment_count
            initial_river_q(i_catch, :) = incoming_q_current(i_catch)
            incoming_q_boundary(i_catch, :) = incoming_q_current(i_catch)
            outgoing_q_boundary(i_catch, :) = outgoing_q_current(i_catch)
        end do
    end subroutine initialize_muskingum_cunge_routing

    subroutine calculate_muskingum_cunge_parameters
        use config, only: catchment_count, max_muskingum_reach_count, model_timestep
        use attributes, only: catchment_order, manning_n, river_length, river_slope, river_width
        use parameters, only: muskingum_reach_count, muskingum_timestep, reference_q, wave_celerity

        implicit none
        ! Symbols:
        ! i_catch       catchment index [1]
        ! q_ref, celerity reference discharge [m3/s] and wave celerity [m/s]
        ! c_factor         celerity coefficient [1]
        ! dt_model, dt_route model and routing timesteps [s]
        ! dx_ideal, l_total ideal and total reach lengths [m]
        ! b_river, slope   river width and slope [m, 1]
        ! n_reach, n_step  reach and routing-substep counts [1]
        integer :: i_catch, n_step, n_reach
        real :: c_factor, dt_model, dt_route, dx_ideal
        real :: q_ref, b_river, slope, l_total, celerity

        do i_catch = 1, catchment_count
            if (catchment_order(i_catch) > 1) then
                ! Unit-Catchmento order
                c_factor = 1.67*river_slope(i_catch)**0.3/manning_n(i_catch)**0.6
                wave_celerity(i_catch) = c_factor*(reference_q(i_catch)/river_width(i_catch))**0.4
                dt_model = model_timestep
                n_step = 24.
                dt_route = dt_model/n_step

                q_ref = reference_q(i_catch)
                slope = river_slope(i_catch)
                b_river = river_width(i_catch)
                celerity = wave_celerity(i_catch)
                ! Ideal dx_ideal using Fread Equation - Fread(1992) Flow Routing, in
                ! Handbook of Hydrology, Maidment
                dx_ideal = 0.5*celerity*dt_route*(1 + (1 + 1.5*(q_ref/b_river)/ &
                    & (celerity**2*slope*dt_route))**0.5)
                l_total = river_length(i_catch)*1000.
                !To meters
                n_reach = nint(l_total/dx_ideal)
                !Calculates n_reach number
                n_reach = max(n_reach, 1)
                if (n_reach .gt. max_muskingum_reach_count) then
                    write (*, *), i_catch
                    write (*, *) 'ntrech number greater then', max_muskingum_reach_count, &
                        & ' in parcunge subroutine!!!'
                    error stop 'ntrech number greater than NUMUSK in parcunge'
                end if
                muskingum_timestep(i_catch) = dt_route
                muskingum_reach_count(i_catch) = n_reach

            else
                muskingum_timestep(i_catch) = 0.0
                muskingum_reach_count(i_catch) = 0
            end if

        end do

        return
    end

    subroutine route_muskingum_cunge_network(i_model_step)
        use config, only: catchment_count, first_subbasin, last_subbasin, model_timestep, &
            & routing_method, substitution_count, substitution_enabled
        use forcing, only: substituted_q
        use attributes, only: catchment_subbasin, downstream_catchment, manning_n, river_length, &
            & river_slope, river_width
        use parameters, only: muskingum_reach_count, muskingum_timestep, reference_q, &
            & substitution_catchment, wave_celerity
        use state, only: catchment_q_current, catchment_q_previous, flow_velocity, groundwater_q, &
            & groundwater_q_output, groundwater_routing_volume, incremental_q_output, inertial_q, &
            & incoming_groundwater_fraction_current, incoming_groundwater_fraction_previous, &
            & incoming_q_boundary, incoming_q_current, incoming_q_previous, &
            & incoming_subsurface_fraction_current, incoming_subsurface_fraction_previous, &
            & incoming_surface_fraction_current, incoming_surface_fraction_previous, &
            & outgoing_groundwater_fraction_current, &
            & outgoing_groundwater_fraction_previous, outgoing_q_boundary, outgoing_q_current, &
            & outgoing_q_previous, outgoing_subsurface_fraction_current, &
            & outgoing_subsurface_fraction_previous, outgoing_surface_fraction_current, &
            & outgoing_surface_fraction_previous, subsurface_q, subsurface_routing_volume, &
            & surface_q, surface_routing_volume
        !This Sub-Routine calculates the flow routing in drainage network .

        implicit none

        integer, intent(in) :: i_model_step

        ! Symbols:
        ! i_model_step    current model timestep index [1]
        ! i_catch, i_sub, i_down, i_step, i_search, i_subst indices [1]
        ! q_out_prev, q_out_curr upstream and downstream discharge [m3/s]
        ! dx, k_musk      reach length and travel-time parameter [m, s]
        ! dt_route        routing substep duration [s]
        ! q_ref, b_river, slope, celerity equation inputs [m3/s, m, 1, m/s]
        ! x_musk          Muskingum weighting factor [1]
        ! c_up_prev, c_up_curr, c_down_prev routing equation coefficients [1]
        ! c_denom         coefficient denominator [s]
        ! v_route         routed component volume [m3]
        ! h_prev, h_curr  trial flow depths used for velocity [m]
        ! n_reach, n_step, n_route_steps reach and substep counts [1]
        integer :: i_catch, i_sub
        real dx
        !Space-step
        real x_musk, k_musk
        real q_ref, b_river, slope, celerity
        ! Muskingum-Cunge reach parameters.
        real q_out_prev, q_out_curr
        real dt_route, c_denom, v_route
        integer i_down
        !Auxiliary variables
        integer n_reach, n_step
        real c_up_prev, c_up_curr, c_down_prev
        !Muskingum-Cunge coefficients

        real h_prev, h_curr
        !To compute velocities

        !Counters
        integer n_route_steps, i_step
        integer i_search, i_subst

        if (muskingum_timestep(catchment_count) < 0.00001) stop &
            & 'Something wrong in time-step on rede.f90'
        n_route_steps = model_timestep/muskingum_timestep(catchment_count)

        !Initial conditions: initialize_model_state.f90

        ! Advance the previous/current routing state for this model step.
        do i_catch = 1, catchment_count
            incoming_q_previous(i_catch) = incoming_q_current(i_catch)
            outgoing_q_previous(i_catch) = outgoing_q_current(i_catch)
            incoming_q_current(i_catch) = 0.0
            outgoing_q_current(i_catch) = 0.0
            incoming_groundwater_fraction_previous(i_catch) = &
                & incoming_groundwater_fraction_current(i_catch)
            incoming_subsurface_fraction_previous(i_catch) = &
                & incoming_subsurface_fraction_current(i_catch)
            incoming_surface_fraction_previous(i_catch) = incoming_surface_fraction_current(i_catch)
            outgoing_groundwater_fraction_previous(i_catch) = &
                & outgoing_groundwater_fraction_current(i_catch)
            outgoing_subsurface_fraction_previous(i_catch) = &
                & outgoing_subsurface_fraction_current(i_catch)
            outgoing_surface_fraction_previous(i_catch) = outgoing_surface_fraction_current(i_catch)
            catchment_q_previous(i_catch) = catchment_q_current(i_catch)
        end do
        incoming_q_boundary = 0.0
        outgoing_q_boundary = 0.0

        do i_catch = 1, catchment_count

            if (substitution_enabled(i_catch) == 1) cycle
            ! RP:  Does not compute upstream catchments of replacement catchments

            i_sub = catchment_subbasin(i_catch)

            !code used to calibraton
            if ((i_sub < first_subbasin) .or. (i_sub > last_subbasin)) cycle
            ! Manual controls for specialized calibration

            catchment_q_current(i_catch) = groundwater_q(i_catch) + subsurface_q(i_catch) + &
                & surface_q(i_catch)
            !Total of flow in each catchment

            ! Flag used to HD model:
            if (routing_method(i_catch) == 1) cycle

            !Catchment with river
            if (muskingum_reach_count(i_catch) .gt. 0) then

                dt_route = muskingum_timestep(i_catch)
                dx = river_length(i_catch)*1000./muskingum_reach_count(i_catch)
                k_musk = dx/wave_celerity(i_catch)
                q_ref = reference_q(i_catch)
                b_river = river_width(i_catch)
                slope = river_slope(i_catch)
                celerity = wave_celerity(i_catch)
                x_musk = 0.5*(1.0 - (q_ref/(b_river*slope*celerity*dx)))

                ! Verify the reach and travel-time parameters:
                ! Enforce the stable Muskingum-Cunge range 0.2 <= x <= 0.5.
                if (x_musk < 0.2) then
                    x_musk = 0.2
                    k_musk = dt_route/(3.125*x_musk**1.25)
                    ! Tucci, equation 4.111
                elseif (x_musk < 0.4) then
                elseif (x_musk < 0.5) then

                else
                    x_musk = 0.5
                    k_musk = dt_route
                end if

                c_denom = 2.*k_musk*(1.-x_musk) + dt_route
                c_up_prev = (2.*k_musk*x_musk + dt_route)/c_denom
                c_up_curr = (dt_route - 2.*k_musk*x_musk)/c_denom
                c_down_prev = (2.*k_musk*(1.-x_musk) - dt_route)/c_denom

                !Lateral inflow are used upstream of same catchment

                !Proportions to Flows
                incoming_groundwater_fraction_current(i_catch) = &
                    & incoming_groundwater_fraction_current(i_catch)* &
                    & incoming_q_current(i_catch)
                !underground flow
                incoming_subsurface_fraction_current(i_catch) = &
                    & incoming_subsurface_fraction_current(i_catch)* &
                    & incoming_q_current(i_catch)
                !subsurface flow
                incoming_surface_fraction_current(i_catch) = &
                    & incoming_surface_fraction_current(i_catch)* &
                    & incoming_q_current(i_catch)
                !runoff

                incoming_q_current(i_catch) = incoming_q_current(i_catch) + surface_q(i_catch) + &
                    & subsurface_q(i_catch) + groundwater_q(i_catch)

                !MUSKINGUM-CUNGE Boundary conditions
                do i_step = 1, n_route_steps + 1
                    incoming_q_boundary(i_catch, i_step) = incoming_q_boundary(i_catch, i_step) + &
                        & catchment_q_previous(i_catch) + (i_step - 1)* &
                        & (catchment_q_current(i_catch) - &
                        & catchment_q_previous(i_catch))/n_route_steps
                end do

                !Update proportions
                incoming_groundwater_fraction_current(i_catch) = &
                    & (incoming_groundwater_fraction_current(i_catch) &
                    & + groundwater_q(i_catch))/incoming_q_current(i_catch)
                incoming_subsurface_fraction_current(i_catch) = &
                    & (incoming_subsurface_fraction_current(i_catch) &
                    & + subsurface_q(i_catch))/incoming_q_current(i_catch)
                incoming_surface_fraction_current(i_catch) = &
                    & (incoming_surface_fraction_current(i_catch) &
                    & + surface_q(i_catch))/incoming_q_current(i_catch)

                !Update volume proportions
                groundwater_routing_volume(i_catch) = groundwater_routing_volume(i_catch) + &
                    & incoming_groundwater_fraction_current(i_catch)* &
                    & incoming_q_current(i_catch)*model_timestep
                subsurface_routing_volume(i_catch) = subsurface_routing_volume(i_catch) + &
                    & incoming_subsurface_fraction_current(i_catch)* &
                    & incoming_q_current(i_catch)*model_timestep
                surface_routing_volume(i_catch) = surface_routing_volume(i_catch) + &
                    & incoming_surface_fraction_current(i_catch)* &
                    & incoming_q_current(i_catch)*model_timestep

                q_out_prev = outgoing_q_previous(i_catch)
                n_reach = muskingum_reach_count(i_catch)
                n_step = model_timestep/muskingum_timestep(i_catch)

                call route_muskingum_cunge(i_catch, q_out_prev, q_out_curr, n_reach, n_step, &
                    & c_up_prev, c_up_curr, c_down_prev)
                outgoing_q_current(i_catch) = q_out_curr

                !Update volume proportions
                v_route = groundwater_routing_volume(i_catch) + &
                    & subsurface_routing_volume(i_catch) + surface_routing_volume(i_catch)
                outgoing_groundwater_fraction_current(i_catch) = &
                    & groundwater_routing_volume(i_catch)/v_route
                outgoing_subsurface_fraction_current(i_catch) = &
                    & subsurface_routing_volume(i_catch)/v_route
                outgoing_surface_fraction_current(i_catch) = surface_routing_volume(i_catch)/v_route
                groundwater_routing_volume(i_catch) = max(0.0, &
                    & groundwater_routing_volume(i_catch) - &
                    & outgoing_groundwater_fraction_current(i_catch)* &
                    & outgoing_q_current(i_catch)*model_timestep)
                subsurface_routing_volume(i_catch) = max(0.0, &
                    & subsurface_routing_volume(i_catch) - &
                    & outgoing_subsurface_fraction_current(i_catch)* &
                    & outgoing_q_current(i_catch)*model_timestep)
                surface_routing_volume(i_catch) = max(0.0, &
                    & surface_routing_volume(i_catch) - &
                    & outgoing_surface_fraction_current(i_catch)* &
                    & outgoing_q_current(i_catch)*model_timestep)

                ! Flows routing in each catchment are used as upstream boundary in downstream
                ! catchment
                i_down = downstream_catchment(i_catch)

                if (i_down > 0) then

                    incoming_groundwater_fraction_current(i_down) = &
                        & incoming_groundwater_fraction_current(i_down)* &
                        & incoming_q_current(i_down)
                    !underground flow
                    incoming_subsurface_fraction_current(i_down) = &
                        & incoming_subsurface_fraction_current(i_down)* &
                        & incoming_q_current(i_down)
                    !subsurface flow
                    incoming_surface_fraction_current(i_down) = &
                        & incoming_surface_fraction_current(i_down)* &
                        & incoming_q_current(i_down)
                    !runoff

                    incoming_q_current(i_down) = &
                        & incoming_q_current(i_down) + outgoing_q_current(i_catch)

                    !Muskingum-Cunge boundary condition
                    !Tests if calculated flow must be replaced by flow by file
                    i_subst = 0
                    do i_search = 1, substitution_count
                        if (i_model_step > 1 .and. i_catch == substitution_catchment(i_search)) then
                            i_subst = i_search
                            exit
                        else
                            i_subst = 0
                        end if
                    end do

                    if (i_subst > 0) then
                        if (substituted_q(i_subst, i_model_step) < 0.0) then
                            !Problem in read data
                            !Uses calculated flow
                            do i_step = 1, n_route_steps + 1
                                incoming_q_boundary(i_down, i_step) = &
                                    & incoming_q_boundary(i_down, i_step) + &
                                    & outgoing_q_boundary(i_catch, i_step)
                                !update boundary
                            end do
                        else
                            !use flow from file
                            incoming_q_current(i_down) = substituted_q(i_subst, i_model_step)
                            do i_step = 1, n_route_steps + 1
                                !Replaces calculated flow by read flow (from file)
                                incoming_q_boundary(i_down, i_step) = &
                                    & substituted_q(i_subst, i_model_step - 1) + (i_step - 1)* &
                                    & (substituted_q(i_subst, i_model_step) - &
                                    & substituted_q(i_subst, i_model_step - 1))/n_route_steps
                            end do
                        end if
                    else
                        do i_step = 1, n_route_steps + 1
                            incoming_q_boundary(i_down, i_step) = &
                                & incoming_q_boundary(i_down, i_step) + &
                                & outgoing_q_boundary(i_catch, i_step)
                            !Update boundary
                        end do
                    end if

                    !Update proportions
                    incoming_groundwater_fraction_current(i_down) = &
                        & (incoming_groundwater_fraction_current(i_down) &
                        & + outgoing_groundwater_fraction_current(i_catch)* &
                        & outgoing_q_current(i_catch))/incoming_q_current(i_down)
                    incoming_subsurface_fraction_current(i_down) = &
                        & (incoming_subsurface_fraction_current(i_down) &
                        & + outgoing_subsurface_fraction_current(i_catch)* &
                        & outgoing_q_current(i_catch))/incoming_q_current(i_down)
                    incoming_surface_fraction_current(i_down) = &
                        & (incoming_surface_fraction_current(i_down) &
                        & + outgoing_surface_fraction_current(i_catch)* &
                        & outgoing_q_current(i_catch))/incoming_q_current(i_down)
                end if

                !headboard catchment
            else
                dx = 0.0
                k_musk = 0.0
                x_musk = 0.0

                outgoing_q_current(i_catch) = groundwater_q(i_catch) + subsurface_q(i_catch) + &
                    & surface_q(i_catch)
                outgoing_groundwater_fraction_current(i_catch) = &
                    & groundwater_q(i_catch)/outgoing_q_current(i_catch)
                outgoing_subsurface_fraction_current(i_catch) = &
                    & subsurface_q(i_catch)/outgoing_q_current(i_catch)
                outgoing_surface_fraction_current(i_catch) = surface_q(i_catch)/ &
                    & outgoing_q_current(i_catch)

                ! Flows routing in each catchment are used as upstream boundary in downstream
                ! catchment
                i_down = downstream_catchment(i_catch)

                if (i_down > 0) then

                    incoming_groundwater_fraction_current(i_down) = &
                        & incoming_groundwater_fraction_current(i_down)* &
                        & incoming_q_current(i_down)
                    !underground flow
                    incoming_subsurface_fraction_current(i_down) = &
                        & incoming_subsurface_fraction_current(i_down)* &
                        & incoming_q_current(i_down)
                    !subsurface flow
                    incoming_surface_fraction_current(i_down) = &
                        & incoming_surface_fraction_current(i_down)* &
                        & incoming_q_current(i_down)
                    !runoff

                    incoming_q_current(i_down) = incoming_q_current(i_down) + surface_q(i_catch) + &
                        & subsurface_q(i_catch) + groundwater_q(i_catch)

                    !MUSKINGUM-CUNGE boundary condition
                    do i_step = 1, n_route_steps + 1
                        incoming_q_boundary(i_down, i_step) = &
                            & incoming_q_boundary(i_down, i_step) + outgoing_q_previous(i_catch) &
                            & + (i_step - 1)*(outgoing_q_current(i_catch) - &
                            & outgoing_q_previous(i_catch))/n_route_steps
                    end do

                    !update proportions
                    incoming_groundwater_fraction_current(i_down) = &
                        & (incoming_groundwater_fraction_current(i_down) &
                        & + groundwater_q(i_catch))/incoming_q_current(i_down)
                    incoming_subsurface_fraction_current(i_down) = &
                        & (incoming_subsurface_fraction_current(i_down) &
                        & + subsurface_q(i_catch))/incoming_q_current(i_down)
                    incoming_surface_fraction_current(i_down) = &
                        & (incoming_surface_fraction_current(i_down) &
                        & + surface_q(i_catch))/incoming_q_current(i_down)
                end if
            end if

            !STORE OUTPUT INFORMATION
            inertial_q(i_catch) = outgoing_q_current(i_catch)
            !Saves in inertial_q #v1.41
            incremental_q_output(i_catch) = catchment_q_current(i_catch)
            groundwater_q_output(i_catch) = groundwater_q(i_catch)

            !Iteration to find river velocity by inversion of manning eq.
            h_prev = 3.0
            do
                h_curr = ((outgoing_q_current(i_catch)*manning_n(i_catch)/ &
                    & river_slope(i_catch)**0.5)**0.6)*((river_width(i_catch) + 2*h_prev)**0.4)/ &
                    & river_width(i_catch)
                if (abs(h_curr - h_prev) < 0.005) exit
                h_prev = h_curr
            end do

            flow_velocity(i_catch) = outgoing_q_current(i_catch)/(h_curr*river_width(i_catch))

        end do
        return
    end subroutine route_muskingum_cunge_network

    subroutine route_muskingum_cunge(i_catch, q_in, q_out, n_reach, n_step, c_up_prev, &
        & c_up_curr, c_down_prev)
        use config, only: max_muskingum_reach_count
        use state, only: incoming_q_boundary, initial_river_q, open_water_evaporation_q, &
            & outgoing_q_boundary

        implicit none
        ! Symbols:
        ! i_catch, n_reach, n_step catchment, reach, and substep indices [1]
        ! q_in, q_out       upstream and downstream boundary discharges [m3/s]
        ! c_up_prev, c_up_curr, c_down_prev routing coefficients [1]
        ! q                  reach discharge array [m3/s]
        ! q_loss             prescribed upstream loss [m3/s]
        integer, intent(in) :: i_catch, n_reach, n_step
        real, intent(in) :: q_in, c_up_prev, c_up_curr, c_down_prev
        real, intent(out) :: q_out
        integer :: i_step, i_reach

        real, allocatable :: q(:, :)
        real q_loss
        allocate (q(n_reach + 1, n_step + 1))

        if (n_reach > max_muskingum_reach_count) stop &
            & 'MUITOS SUBTRECHOS NA ROTINA MUSK'

        q = 0.0
        outgoing_q_boundary(i_catch, 1) = q_in

        q_loss = 0.0

        !Upstream boundary conditions
        do i_step = 1, n_step + 1
            ! Remove open-water evaporation and prescribed losses at the upstream boundary.
            q(1, i_step) = max(incoming_q_boundary(i_catch, i_step) - &
                & open_water_evaporation_q(i_catch) - q_loss, 0.0)
        end do

        !Initial conditions
        do i_reach = 1, n_reach + 1
            q(i_reach, 1) = initial_river_q(i_catch, i_reach)
        end do

        do i_step = 1, n_step
            do i_reach = 1, n_reach
                q(i_reach + 1, i_step + 1) = c_up_prev*q(i_reach, i_step) + c_up_curr* &
                    & q(i_reach, i_step + 1) + c_down_prev*q(i_reach + 1, i_step)
                !Avoid negative flows
                q(i_reach + 1, i_step + 1) = max(q(i_reach + 1, i_step + 1), 0.0)
            end do
            !Save output flows (all stretches and times)
            outgoing_q_boundary(i_catch, i_step + 1) = q(n_reach + 1, i_step + 1)
        end do

        !Save Initial Condition values to next Muskingum-Cunge simulation
        initial_river_q(i_catch, 1) = incoming_q_boundary(i_catch, n_step + 1)
        do i_reach = 2, n_reach + 1
            initial_river_q(i_catch, i_reach) = q(i_reach, n_step + 1)
        end do

        ! Save last downstream value. This value is returned to route_muskingum_cunge_network
        ! SUBROUTINE.
        q_out = q(n_reach + 1, n_step + 1)

        deallocate (q)
        return
    end subroutine route_muskingum_cunge

end module river_muskingum
