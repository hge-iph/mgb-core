module river_muskingum

    implicit none
    private
    public :: calculate_muskingum_cunge_parameters, initialize_muskingum_cunge_routing, &
        & route_muskingum_cunge_network

contains
write("oi")
write("teste")
    subroutine initialize_muskingum_cunge_routing
        use config, only: &
            & catchment_count, &
            & substitution_count
        use forcing, only: substituted_q
        use attributes, only: downstream_catchment
        use parameters, only: &
            & muskingum_reach_count, &
            & substitution_catchment
        use state, only: &
            & catchment_q_current, &
            & catchment_q_previous, &
            & groundwater_q, &
            & incoming_q_boundary, &
            & incoming_q_current, &
            & incoming_q_previous, &
            & incoming_groundwater_fraction_current, &
            & incoming_subsurface_fraction_current, &
            & incoming_surface_fraction_current, &
            & initial_river_q, &
            & outgoing_q_boundary, &
            & outgoing_q_current, &
            & outgoing_q_previous, &
            & subsurface_q, &
            & surface_q

        implicit none

        ! Symbols:
        ! i_catch catchment index [1]
        ! i_down  downstream-catchment index [1]
        ! i_subst substitution index [1]
        ! r       catchment runoff entering the river [m3/s]
        ! q       routed river discharge [m3/s]
        integer :: i_catch
        integer :: i_down
        integer :: i_subst
        real :: r
        real :: q

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
            r = groundwater_q(i_catch) + subsurface_q(i_catch) + surface_q(i_catch)
            catchment_q_current(i_catch) = r
            catchment_q_previous(i_catch) = r
            if (muskingum_reach_count(i_catch) .gt. 0) then
                q = incoming_q_current(i_catch) + r
                incoming_q_current(i_catch) = q
                outgoing_q_current(i_catch) = q
                i_down = downstream_catchment(i_catch)
                if (i_down > 0) incoming_q_current(i_down) = incoming_q_current(i_down) + q
            else
                q = r
                outgoing_q_current(i_catch) = q
                incoming_q_current(i_catch) = q
                i_down = downstream_catchment(i_catch)
                if (i_down > 0) incoming_q_current(i_down) = incoming_q_current(i_down) + q
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
        use config, only: &
            & catchment_count, &
            & max_muskingum_reach_count, &
            & model_timestep
        use attributes, only: &
            & catchment_order, &
            & n_manning, &
            & river_length, &
            & river_slope, &
            & river_width
        use parameters, only: &
            & muskingum_reach_count, &
            & muskingum_timestep, &
            & reference_q, &
            & wave_celerity

        implicit none
        ! Symbols:
        ! i_catch       catchment index [1]
        ! q_ref      reference river discharge [m3/s]
        ! celerity   wave celerity [m/s]
        ! c_factor   celerity coefficient [1]
        ! dt_model   model timestep [s]
        ! dt_route   routing timestep [s]
        ! dx_ideal   ideal reach length [m]
        ! l_total    total river length [m]
        ! b_river    river width [m]
        ! slope      river slope [1]
        ! roughness  Manning roughness [s/m^(1/3)]
        ! n_reach    routing-reach count [1]
        ! n_step     routing-substep count [1]
        integer :: i_catch
        integer :: n_step
        integer :: n_reach
        real :: c_factor
        real :: dt_model
        real :: dt_route
        real :: dx_ideal
        real :: q_ref
        real :: b_river
        real :: slope
        real :: l_total
        real :: celerity
        real :: roughness

        do i_catch = 1, catchment_count
            if (catchment_order(i_catch) > 1) then
                ! Unit-Catchmento order
                q_ref = reference_q(i_catch)
                slope = river_slope(i_catch)
                b_river = river_width(i_catch)
                roughness = n_manning(i_catch)
                l_total = river_length(i_catch)*1000.
                dt_model = model_timestep
                n_step = 24.
                dt_route = dt_model/n_step

                c_factor = 1.67*slope**0.3/roughness**0.6
                celerity = c_factor*(q_ref/b_river)**0.4
                ! Ideal dx_ideal using Fread Equation - Fread(1992) Flow Routing, in
                ! Handbook of Hydrology, Maidment
                dx_ideal = 0.5*celerity*dt_route*(1 + (1 + 1.5*(q_ref/b_river)/(celerity**2*slope*dt_route))**0.5)
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
                wave_celerity(i_catch) = celerity

            else
                muskingum_timestep(i_catch) = 0.0
                muskingum_reach_count(i_catch) = 0
            end if

        end do

        return
    end

    subroutine route_muskingum_cunge_network( &
        & i_model_step)
        use config, only: &
            & catchment_count, &
            & first_subbasin, &
            & last_subbasin, &
            & model_timestep, &
            & routing_method, &
            & substitution_count, &
            & substitution_enabled
        use forcing, only: substituted_q
        use attributes, only: &
            & catchment_subbasin, &
            & downstream_catchment, &
            & n_manning, &
            & river_length, &
            & river_slope, &
            & river_width
        use parameters, only: &
            & muskingum_reach_count, &
            & muskingum_timestep, &
            & reference_q, &
            & substitution_catchment, &
            & wave_celerity
        use state, only: &
            & catchment_q_current, &
            & catchment_q_previous, &
            & flow_velocity, &
            & groundwater_q, &
            & groundwater_q_output, &
            & groundwater_routing_volume, &
            & incremental_q_output, &
            & inertial_q, &
            & incoming_groundwater_fraction_current, &
            & incoming_groundwater_fraction_previous, &
            & incoming_q_boundary, &
            & incoming_q_current, &
            & incoming_q_previous, &
            & incoming_subsurface_fraction_current, &
            & incoming_subsurface_fraction_previous, &
            & incoming_surface_fraction_current, &
            & incoming_surface_fraction_previous, &
            & outgoing_groundwater_fraction_current, &
            & outgoing_groundwater_fraction_previous, &
            & outgoing_q_boundary, &
            & outgoing_q_current, &
            & outgoing_q_previous, &
            & outgoing_subsurface_fraction_current, &
            & outgoing_subsurface_fraction_previous, &
            & outgoing_surface_fraction_current, &
            & outgoing_surface_fraction_previous, &
            & subsurface_q, &
            & subsurface_routing_volume, &
            & surface_q, &
            & surface_routing_volume
        !This Sub-Routine calculates the flow routing in drainage network .

        implicit none

        integer, intent(in) :: i_model_step

        ! Symbols:
        ! i_model_step    current model timestep index [1]
        ! i_catch      catchment index [1]
        ! i_sub        subbasin index [1]
        ! i_down       downstream-catchment index [1]
        ! i_step       routing-substep index [1]
        ! i_search     substitution-search index [1]
        ! i_subst      substitution index [1]
        ! r            catchment runoff entering the river [m3/s]
        ! r_groundwater groundwater-runoff discharge [m3/s]
        ! r_subsurface subsurface-runoff discharge [m3/s]
        ! r_surface    surface-runoff discharge [m3/s]
        ! q            routed river discharge [m3/s]
        ! q_prev       previous routed river discharge [m3/s]
        ! q_down       routed discharge entering the downstream catchment [m3/s]
        ! q_boundary   interpolated routing-boundary discharge [m3/s]
        ! q_boundary_change interpolated change in routing-boundary discharge [m3/s]
        ! q_groundwater groundwater component of incoming river discharge [m3/s]
        ! q_subsurface subsurface component of incoming river discharge [m3/s]
        ! q_surface    surface component of incoming river discharge [m3/s]
        ! r_prev       previous catchment runoff entering the river [m3/s]
        ! dx           routing-reach length [m]
        ! k_musk       Muskingum travel-time parameter [s]
        ! dt_route     routing-substep duration [s]
        ! q_ref        reference river discharge [m3/s]
        ! b_river      river width [m]
        ! slope        river slope [1]
        ! celerity     wave celerity [m/s]
        ! x_musk       Muskingum weighting factor [1]
        ! c_up_prev    previous upstream-flow coefficient [1]
        ! c_up_curr    current upstream-flow coefficient [1]
        ! c_down_prev  previous downstream-flow coefficient [1]
        ! c_denom      coefficient denominator [s]
        ! v_route      total routed component volume [m3]
        ! f_groundwater groundwater fraction of routed discharge [1]
        ! f_subsurface subsurface fraction of routed discharge [1]
        ! f_surface    surface fraction of routed discharge [1]
        ! v_groundwater groundwater routing volume [m3]
        ! v_subsurface subsurface routing volume [m3]
        ! v_surface    surface routing volume [m3]
        ! roughness    Manning roughness coefficient [s/m**(1/3)]
        ! depth_discharge_term discharge term in the Manning inversion [m**(8/5)]
        ! depth_geometry_term geometry term in the Manning inversion [m**(2/5)]
        ! i_down       downstream catchment index [1]
        ! h_prev       previous trial flow depth [m]
        ! h_curr       current trial flow depth [m]
        ! n_reach      routing-reach count [1]
        ! n_step       routing-substep count [1]
        ! n_route_steps model-step routing-substep count [1]
        ! i_step       routing-substep index [1]
        integer :: i_catch
        integer :: i_sub
        real :: dx
        !Space-step
        real :: x_musk
        real :: k_musk
        real :: q_ref
        real :: b_river
        real :: slope
        real :: celerity
        real :: roughness
        real :: depth_discharge_term
        real :: depth_geometry_term
        ! Muskingum-Cunge reach parameters.
        real :: r
        real :: r_groundwater
        real :: r_subsurface
        real :: r_surface
        real :: q
        real :: q_prev
        real :: q_down
        real :: q_boundary
        real :: q_boundary_change
        real :: q_groundwater
        real :: q_subsurface
        real :: q_surface
        real :: r_prev
        real :: f_groundwater
        real :: f_subsurface
        real :: f_surface
        real :: v_groundwater
        real :: v_subsurface
        real :: v_surface
        real :: dt_route
        real :: c_denom
        real :: v_route
        integer :: i_down
        !Auxiliary variables
        integer :: n_reach
        integer :: n_step
        real :: c_up_prev
        real :: c_up_curr
        real :: c_down_prev
        !Muskingum-Cunge coefficients

        real :: h_prev
        real :: h_curr
        !To compute velocities

        !Counters
        integer :: n_route_steps
        integer :: i_step
        integer :: i_search
        integer :: i_subst

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
            incoming_groundwater_fraction_previous(i_catch) = incoming_groundwater_fraction_current(i_catch)
            incoming_subsurface_fraction_previous(i_catch) = incoming_subsurface_fraction_current(i_catch)
            incoming_surface_fraction_previous(i_catch) = incoming_surface_fraction_current(i_catch)
            outgoing_groundwater_fraction_previous(i_catch) = outgoing_groundwater_fraction_current(i_catch)
            outgoing_subsurface_fraction_previous(i_catch) = outgoing_subsurface_fraction_current(i_catch)
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

            r_groundwater = groundwater_q(i_catch)
            r_subsurface = subsurface_q(i_catch)
            r_surface = surface_q(i_catch)
            r = r_groundwater + r_subsurface + r_surface
            r_prev = catchment_q_previous(i_catch)
            b_river = river_width(i_catch)
            slope = river_slope(i_catch)
            roughness = n_manning(i_catch)
            catchment_q_current(i_catch) = r
            !Total of flow in each catchment

            ! Flag used to HD model:
            if (routing_method(i_catch) == 1) cycle

            !Catchment with river
            if (muskingum_reach_count(i_catch) .gt. 0) then

                dt_route = muskingum_timestep(i_catch)
                dx = river_length(i_catch)*1000./muskingum_reach_count(i_catch)
                k_musk = dx/wave_celerity(i_catch)
                q_ref = reference_q(i_catch)
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
                q = incoming_q_current(i_catch)
                q_groundwater = incoming_groundwater_fraction_current(i_catch)*q
                !underground flow
                q_subsurface = incoming_subsurface_fraction_current(i_catch)*q
                !subsurface flow
                q_surface = incoming_surface_fraction_current(i_catch)*q
                !runoff

                q = q + r
                incoming_q_current(i_catch) = q

                !MUSKINGUM-CUNGE Boundary conditions
                do i_step = 1, n_route_steps + 1
                    q_boundary_change = (i_step - 1)*(r - r_prev)/n_route_steps
                    incoming_q_boundary(i_catch, i_step) = incoming_q_boundary(i_catch, i_step) + r_prev + q_boundary_change
                end do

                !Update proportions
                f_groundwater = (q_groundwater + r_groundwater)/q
                f_subsurface = (q_subsurface + r_subsurface)/q
                f_surface = (q_surface + r_surface)/q
                incoming_groundwater_fraction_current(i_catch) = f_groundwater
                incoming_subsurface_fraction_current(i_catch) = f_subsurface
                incoming_surface_fraction_current(i_catch) = f_surface

                !Update volume proportions
                v_groundwater = groundwater_routing_volume(i_catch) + f_groundwater*q*model_timestep
                v_subsurface = subsurface_routing_volume(i_catch) + f_subsurface*q*model_timestep
                v_surface = surface_routing_volume(i_catch) + f_surface*q*model_timestep

                q_prev = outgoing_q_previous(i_catch)
                n_reach = muskingum_reach_count(i_catch)
                n_step = model_timestep/muskingum_timestep(i_catch)

                call route_muskingum_cunge( &
                    & i_catch, &
                    & q_prev, &
                    & q, &
                    & n_reach, &
                    & n_step, &
                    & c_up_prev, &
                    & c_up_curr, &
                    & c_down_prev)
                outgoing_q_current(i_catch) = q

                !Update volume proportions
                v_route = v_groundwater + v_subsurface + v_surface
                f_groundwater = v_groundwater/v_route
                f_subsurface = v_subsurface/v_route
                f_surface = v_surface/v_route
                outgoing_groundwater_fraction_current(i_catch) = f_groundwater
                outgoing_subsurface_fraction_current(i_catch) = f_subsurface
                outgoing_surface_fraction_current(i_catch) = f_surface
                groundwater_routing_volume(i_catch) = max(0.0, v_groundwater - f_groundwater*q*model_timestep)
                subsurface_routing_volume(i_catch) = max(0.0, v_subsurface - f_subsurface*q*model_timestep)
                surface_routing_volume(i_catch) = max(0.0, v_surface - f_surface*q*model_timestep)

                ! Flows routing in each catchment are used as upstream boundary in downstream
                ! catchment
                i_down = downstream_catchment(i_catch)

                if (i_down > 0) then

                    q_down = incoming_q_current(i_down)
                    q_groundwater = incoming_groundwater_fraction_current(i_down)*q_down
                    !underground flow
                    q_subsurface = incoming_subsurface_fraction_current(i_down)*q_down
                    !subsurface flow
                    q_surface = incoming_surface_fraction_current(i_down)*q_down
                    !runoff

                    q_down = q_down + q
                    incoming_q_current(i_down) = q_down

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
                                q_boundary = outgoing_q_boundary(i_catch, i_step)
                                incoming_q_boundary(i_down, i_step) = incoming_q_boundary(i_down, i_step) + q_boundary
                                !update boundary
                            end do
                        else
                            !use flow from file
                            incoming_q_current(i_down) = substituted_q(i_subst, i_model_step)
                            q_down = incoming_q_current(i_down)
                            do i_step = 1, n_route_steps + 1
                                !Replaces calculated flow by read flow (from file)
                                q_prev = substituted_q(i_subst, i_model_step - 1)
                                q_boundary = substituted_q(i_subst, i_model_step)
                                incoming_q_boundary(i_down, i_step) = q_prev + (i_step - 1)*(q_boundary - q_prev)/n_route_steps
                            end do
                        end if
                    else
                        do i_step = 1, n_route_steps + 1
                            q_boundary = outgoing_q_boundary(i_catch, i_step)
                            incoming_q_boundary(i_down, i_step) = incoming_q_boundary(i_down, i_step) + q_boundary
                            !Update boundary
                        end do
                    end if

                    !Update proportions
                    f_groundwater = (q_groundwater + outgoing_groundwater_fraction_current(i_catch)*q)/q_down
                    f_subsurface = (q_subsurface + outgoing_subsurface_fraction_current(i_catch)*q)/q_down
                    f_surface = (q_surface + outgoing_surface_fraction_current(i_catch)*q)/q_down
                    incoming_groundwater_fraction_current(i_down) = f_groundwater
                    incoming_subsurface_fraction_current(i_down) = f_subsurface
                    incoming_surface_fraction_current(i_down) = f_surface
                end if

                !headboard catchment
            else
                dx = 0.0
                k_musk = 0.0
                x_musk = 0.0

                q = r
                outgoing_q_current(i_catch) = q
                outgoing_groundwater_fraction_current(i_catch) = r_groundwater/q
                outgoing_subsurface_fraction_current(i_catch) = r_subsurface/q
                outgoing_surface_fraction_current(i_catch) = r_surface/q

                ! Flows routing in each catchment are used as upstream boundary in downstream
                ! catchment
                i_down = downstream_catchment(i_catch)

                if (i_down > 0) then

                    q_down = incoming_q_current(i_down)
                    q_groundwater = incoming_groundwater_fraction_current(i_down)*q_down
                    !underground flow
                    q_subsurface = incoming_subsurface_fraction_current(i_down)*q_down
                    !subsurface flow
                    q_surface = incoming_surface_fraction_current(i_down)*q_down
                    !runoff

                    q_down = q_down + r
                    incoming_q_current(i_down) = q_down

                    !MUSKINGUM-CUNGE boundary condition
                    do i_step = 1, n_route_steps + 1
                        q_prev = outgoing_q_previous(i_catch)
                        q_boundary_change = (i_step - 1)*(q - q_prev)/n_route_steps
                        incoming_q_boundary(i_down, i_step) = incoming_q_boundary(i_down, i_step) + q_prev + q_boundary_change
                    end do

                    !update proportions
                    incoming_groundwater_fraction_current(i_down) = (q_groundwater + r_groundwater)/q_down
                    incoming_subsurface_fraction_current(i_down) = (q_subsurface + r_subsurface)/q_down
                    incoming_surface_fraction_current(i_down) = (q_surface + r_surface)/q_down
                end if
            end if

            !STORE OUTPUT INFORMATION
            inertial_q(i_catch) = q
            !Saves in inertial_q #v1.41
            incremental_q_output(i_catch) = r
            groundwater_q_output(i_catch) = r_groundwater

            !Iteration to find river velocity by inversion of manning eq.
            h_prev = 3.0
            do
                depth_discharge_term = (q*roughness/slope**0.5)**0.6
                depth_geometry_term = (b_river + 2*h_prev)**0.4
                h_curr = depth_discharge_term*depth_geometry_term/b_river
                if (abs(h_curr - h_prev) < 0.005) exit
                h_prev = h_curr
            end do

            flow_velocity(i_catch) = q/(h_curr*b_river)

        end do
        return
    end subroutine route_muskingum_cunge_network

    subroutine route_muskingum_cunge( &
        & i_catch, &
        & q_in, &
        & q_out, &
        & n_reach, &
        & n_step, &
        & c_up_prev, &
        & c_up_curr, &
        & c_down_prev)
        use config, only: max_muskingum_reach_count
        use state, only: &
            & incoming_q_boundary, &
            & initial_river_q, &
            & open_water_evaporation_q, &
            & outgoing_q_boundary

        implicit none
        ! Symbols:
        ! i_catch    catchment index [1]
        ! n_reach    routing-reach count [1]
        ! n_step     routing-substep count [1]
        ! q_in       upstream river discharge [m3/s]
        ! q_out      downstream routed river discharge [m3/s]
        ! c_up_prev  previous upstream-flow coefficient [1]
        ! c_up_curr  current upstream-flow coefficient [1]
        ! c_down_prev previous downstream-flow coefficient [1]
        ! q          reach river-discharge array [m3/s]
        ! q_loss     prescribed upstream loss [m3/s]
        ! q_next     routed river discharge at the next reach and timestep [m3/s]
        integer, intent(in) :: i_catch
        integer, intent(in) :: n_reach
        integer, intent(in) :: n_step
        real, intent(in) :: q_in
        real, intent(in) :: c_up_prev
        real, intent(in) :: c_up_curr
        real, intent(in) :: c_down_prev
        real, intent(out) :: q_out
        integer :: i_step
        integer :: i_reach

        real, allocatable :: q(:, :)
        real :: q_loss
        real :: q_next
        allocate (q(n_reach + 1, n_step + 1))

        if (n_reach > max_muskingum_reach_count) stop &
            & 'MUITOS SUBTRECHOS NA ROTINA MUSK'

        q = 0.0
        outgoing_q_boundary(i_catch, 1) = q_in

        q_loss = 0.0

        !Upstream boundary conditions
        do i_step = 1, n_step + 1
            ! Remove open-water evaporation and prescribed losses at the upstream boundary.
            q(1, i_step) = max(incoming_q_boundary(i_catch, i_step) - open_water_evaporation_q(i_catch) - q_loss, 0.0)
        end do

        !Initial conditions
        do i_reach = 1, n_reach + 1
            q(i_reach, 1) = initial_river_q(i_catch, i_reach)
        end do

        do i_step = 1, n_step
            do i_reach = 1, n_reach
                q_next = c_up_prev*q(i_reach, i_step) + c_up_curr*q(i_reach, i_step + 1) + c_down_prev*q(i_reach + 1, i_step)
                q(i_reach + 1, i_step + 1) = q_next
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
