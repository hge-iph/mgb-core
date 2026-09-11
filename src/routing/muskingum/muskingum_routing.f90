module muskingum_routing

    implicit none
    private
    public :: calculate_muskingum_cunge_parameters, initialize_muskingum_cunge_routing, &
              route_muskingum_cunge_network

contains

    subroutine initialize_muskingum_cunge_routing
        use runoff_state, only: catchment_count, catchment_index, downstream_catchment
        use runoff_state, only: catchment_q_current, catchment_q_previous, &
                                groundwater_q, subsurface_q, surface_q
        use reservoir_state, only: substituted_q, substitution_catchment, substitution_count
        use muskingum_state, only: incoming_q_boundary, incoming_q_current, incoming_q_previous, &
                                   incoming_groundwater_fraction_current, &
                                   incoming_subsurface_fraction_current, &
                                   incoming_surface_fraction_current, initial_river_q, &
                                   muskingum_reach_count, outgoing_q_boundary, outgoing_q_current, &
                                   outgoing_q_previous

        implicit none

        integer :: downstream_index, substitution_index

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

        do catchment_index = 1, catchment_count
            catchment_q_current(catchment_index) = groundwater_q(catchment_index) + &
                                                   subsurface_q(catchment_index) + &
                                                   surface_q(catchment_index)
            catchment_q_previous(catchment_index) = catchment_q_current(catchment_index)
            if (muskingum_reach_count(catchment_index) .gt. 0) then
                incoming_q_current(catchment_index) = incoming_q_current(catchment_index) + &
                                                      catchment_q_current(catchment_index)
                outgoing_q_current(catchment_index) = incoming_q_current(catchment_index)
                downstream_index = downstream_catchment(catchment_index)
                if (downstream_index > 0) incoming_q_current(downstream_index) = &
                    incoming_q_current(downstream_index) + outgoing_q_current(catchment_index)
            else
                outgoing_q_current(catchment_index) = catchment_q_current(catchment_index)
                incoming_q_current(catchment_index) = catchment_q_current(catchment_index)
                downstream_index = downstream_catchment(catchment_index)
                if (downstream_index > 0) incoming_q_current(downstream_index) = &
                    incoming_q_current(downstream_index) + catchment_q_current(catchment_index)
            end if
            do substitution_index = 1, substitution_count
                if (catchment_index == substitution_catchment(substitution_index)) then
                    incoming_q_current(downstream_index) = substituted_q(substitution_index, 1)
                    exit
                end if
            end do
        end do
        outgoing_q_previous = outgoing_q_current
        incoming_q_previous = incoming_q_current
        do catchment_index = 1, catchment_count
            initial_river_q(catchment_index, :) = incoming_q_current(catchment_index)
            incoming_q_boundary(catchment_index, :) = incoming_q_current(catchment_index)
            outgoing_q_boundary(catchment_index, :) = outgoing_q_current(catchment_index)
        end do
    end subroutine initialize_muskingum_cunge_routing

    subroutine calculate_muskingum_cunge_parameters
        use simulation_state, only: model_timestep
        use runoff_state, only: catchment_count, catchment_index, catchment_order, &
                                current_river_width, river_length, river_slope, river_width
        use muskingum_state, only: current_reference_q, manning_n, max_muskingum_reach_count, &
                               muskingum_reach_count, muskingum_timestep, reference_q, wave_celerity

        implicit none
        integer interval_count, reach_count
        real celerity_coefficient, model_step, routing_timestep
        real ideal_reach_length
        real current_slope, total_reach_length, current_celerity

        do catchment_index = 1, catchment_count
            if (catchment_order(catchment_index) > 1) then
                ! Unit-Catchmento order
                celerity_coefficient = 1.67*river_slope(catchment_index)**0.3/ &
                                       manning_n(catchment_index)**0.6
                wave_celerity(catchment_index) = celerity_coefficient* &
                                                 (reference_q(catchment_index)/ &
                                                  river_width(catchment_index))**0.4
                model_step = model_timestep
                routing_timestep = model_step
                routing_timestep = model_step/24.
                interval_count = 24

                current_reference_q = reference_q(catchment_index)
                current_slope = river_slope(catchment_index)
                current_river_width = river_width(catchment_index)
                current_celerity = wave_celerity(catchment_index)
                ! Ideal ideal_reach_length using Fread Equation - Fread(1992) Flow Routing, in
                ! Handbook of Hydrology, Maidment
                ideal_reach_length = 0.5*current_celerity*routing_timestep*(1 + (1 + 1.5* &
                                   (current_reference_q/current_river_width)/(current_celerity**2* &
                                                                                    current_slope* &
                                                                            routing_timestep))**0.5)
                total_reach_length = river_length(catchment_index)*1000.
                !To meters
                reach_count = nint(total_reach_length/ideal_reach_length)
                !Calculates reach_count number
                reach_count = max(reach_count, 1)
                if (reach_count .gt. max_muskingum_reach_count) then
                    write (*, *), catchment_index
                    write (*, *) 'ntrech number greater then', max_muskingum_reach_count, &
                        ' in parcunge subroutine!!!'
                    error stop 'ntrech number greater than NUMUSK in parcunge'
                end if
                muskingum_timestep(catchment_index) = routing_timestep
                muskingum_reach_count(catchment_index) = reach_count

            else
                muskingum_timestep(catchment_index) = 0.0
                muskingum_reach_count(catchment_index) = 0
            end if

        end do

        return
    end

    subroutine route_muskingum_cunge_network
        use simulation_state, only: first_subbasin, last_subbasin, model_timestep, &
                                    timestep_index
        use runoff_state, only: catchment_count, catchment_index, catchment_subbasin, &
                        catchment_x, downstream_catchment, river_length, river_slope, river_width, &
                                subbasin_index
        use runoff_state, only: catchment_q_current, catchment_q_previous, groundwater_q, &
                                subsurface_q, surface_q
        use reservoir_state, only: substituted_q, substitution_catchment, substitution_count, &
                                   substitution_enabled
        use muskingum_state, only: flow_velocity, groundwater_routing_volume, &
                    incoming_groundwater_fraction_current, incoming_groundwater_fraction_previous, &
                                   incoming_q_boundary, incoming_q_current, incoming_q_previous, &
                      incoming_subsurface_fraction_current, incoming_subsurface_fraction_previous, &
                 incoming_surface_fraction_current, incoming_surface_fraction_previous, manning_n, &
                 muskingum_reach_count, muskingum_timestep, outgoing_groundwater_fraction_current, &
                  outgoing_groundwater_fraction_previous, outgoing_q_boundary, outgoing_q_current, &
                                   outgoing_q_previous, outgoing_subsurface_fraction_current, &
                         outgoing_subsurface_fraction_previous, outgoing_surface_fraction_current, &
                       outgoing_surface_fraction_previous, reference_q, subsurface_routing_volume, &
                                   surface_routing_volume, wave_celerity
        use inertial_state, only: inertial_q, routing_method
        use output_state, only: groundwater_q_output, incremental_q_output
        !This Sub-Routine calculates the flow routing in drainage network .

        implicit none
        real reach_step_length
!Space-step
        real muskingum_x, muskingum_k
!catchment_x E K: Muskingum-Cunge parameters
        real incoming_q_value_previous, incoming_q_value_current
        real outgoing_q_value_previous, outgoing_q_value_current
        real routing_timestep, coefficient_denominator, routing_volume_total
        integer downstream_index
        !Auxiliary variables
        integer reach_count, interval_count
        real coefficient_1, coefficient_2, coefficient_3
        !Muskingum-Cunge coefficients

        real depth_iteration_previous, depth_iteration_current
!To compute velocities

        !Counters
        integer muskingum_interval_count, interval_index
        integer substitution_search_index, substitution_index

        if (muskingum_timestep(catchment_count) < &
            0.00001) stop 'Something wrong in time-step on rede.f90'
        muskingum_interval_count = model_timestep/muskingum_timestep(catchment_count)

        !Initial conditions: initialize_model_state.f90

        ! In each time-step variables substitution_search_index+1 are changed to
        ! substitution_search_index
        do catchment_index = 1, catchment_count
            incoming_q_previous(catchment_index) = incoming_q_current(catchment_index)
            outgoing_q_previous(catchment_index) = outgoing_q_current(catchment_index)
            incoming_q_current(catchment_index) = 0.0
            outgoing_q_current(catchment_index) = 0.0
            incoming_groundwater_fraction_previous(catchment_index) = &
                incoming_groundwater_fraction_current(catchment_index)
            incoming_subsurface_fraction_previous(catchment_index) = &
                incoming_subsurface_fraction_current(catchment_index)
            incoming_surface_fraction_previous(catchment_index) = &
                incoming_surface_fraction_current(catchment_index)
            outgoing_groundwater_fraction_previous(catchment_index) = &
                outgoing_groundwater_fraction_current(catchment_index)
            outgoing_subsurface_fraction_previous(catchment_index) = &
                outgoing_subsurface_fraction_current(catchment_index)
            outgoing_surface_fraction_previous(catchment_index) = &
                outgoing_surface_fraction_current(catchment_index)
            catchment_q_previous(catchment_index) = catchment_q_current(catchment_index)
        end do
        incoming_q_boundary = 0.0
        outgoing_q_boundary = 0.0

        do catchment_index = 1, catchment_count

            if (substitution_enabled(catchment_index) == 1) cycle
            ! RP:  Does not compute upstream catchments of replacement catchments

            subbasin_index = catchment_subbasin(catchment_index)

            !code used to calibraton
            if ((subbasin_index < first_subbasin) .or. (subbasin_index > last_subbasin)) cycle
            ! Manual controls for specialized calibration

            catchment_q_current(catchment_index) = groundwater_q(catchment_index) + &
                                                   subsurface_q(catchment_index) + &
                                                   surface_q(catchment_index)
            !Total of flow in each catchment

            ! Flag used to HD model:
            if (routing_method(catchment_index) == 1) cycle

            !Catchment with river
            if (muskingum_reach_count(catchment_index) .gt. 0) then

                routing_timestep = muskingum_timestep(catchment_index)
                reach_step_length = river_length(catchment_index)*1000./ &
                                    muskingum_reach_count(catchment_index)
                muskingum_k = reach_step_length/wave_celerity(catchment_index)
                muskingum_x = 0.5*(1.0 - (reference_q(catchment_index)/ &
                                       (river_width(catchment_index)*river_slope(catchment_index)* &
                                           wave_celerity(catchment_index)*reach_step_length)))

                ! Verification of catchment_x and K values:
                ! Enforce the stable Muskingum-Cunge range 0.2 <= x <= 0.5.
                if (muskingum_x < 0.2) then
                    muskingum_x = 0.2
                    muskingum_k = routing_timestep/(3.125*muskingum_x**1.25)
                    ! Tucci, equation 4.111
                elseif (muskingum_x < 0.4) then
                elseif (muskingum_x < 0.5) then

                else
                    muskingum_x = 0.5
                    muskingum_k = routing_timestep
                end if

                coefficient_denominator = 2.*muskingum_k*(1.-muskingum_x) + routing_timestep
                coefficient_1 = (2.*muskingum_k*muskingum_x + routing_timestep)/ &
                                coefficient_denominator
                coefficient_2 = (routing_timestep - 2.*muskingum_k*muskingum_x)/ &
                                coefficient_denominator
                coefficient_3 = (2.*muskingum_k*(1.-muskingum_x) - routing_timestep)/ &
                                coefficient_denominator

                !Lateral inflow are used upstream of same catchment

                !Proportions to Flows
                incoming_groundwater_fraction_current(catchment_index) = &
                    incoming_groundwater_fraction_current(catchment_index)* &
                    incoming_q_current(catchment_index)
                !underground flow
                incoming_subsurface_fraction_current(catchment_index) = &
                    incoming_subsurface_fraction_current(catchment_index)* &
                    incoming_q_current(catchment_index)
                !subsurface flow
                incoming_surface_fraction_current(catchment_index) = &
                    incoming_surface_fraction_current(catchment_index)* &
                    incoming_q_current(catchment_index)
                !runoff

                incoming_q_current(catchment_index) = incoming_q_current(catchment_index) + &
                                      surface_q(catchment_index) + subsurface_q(catchment_index) + &
                                                      groundwater_q(catchment_index)

                !MUSKINGUM-CUNGE Boundary conditions
                do interval_index = 1, muskingum_interval_count + 1
                    incoming_q_boundary(catchment_index, interval_index) = &
                        incoming_q_boundary(catchment_index, interval_index) + &
                        catchment_q_previous(catchment_index) + (interval_index - 1)* &
                        (catchment_q_current(catchment_index) - &
                         catchment_q_previous(catchment_index))/muskingum_interval_count
                end do

                !Update proportions
                incoming_groundwater_fraction_current(catchment_index) = &
                    (incoming_groundwater_fraction_current(catchment_index) + &
                     groundwater_q(catchment_index))/incoming_q_current(catchment_index)
                incoming_subsurface_fraction_current(catchment_index) = &
                    (incoming_subsurface_fraction_current(catchment_index) + &
                     subsurface_q(catchment_index))/incoming_q_current(catchment_index)
                incoming_surface_fraction_current(catchment_index) = &
                    (incoming_surface_fraction_current(catchment_index) + &
                     surface_q(catchment_index))/incoming_q_current(catchment_index)

                !Update volume proportions
                groundwater_routing_volume(catchment_index) = &
                    groundwater_routing_volume(catchment_index) + &
                    incoming_groundwater_fraction_current(catchment_index)* &
                    incoming_q_current(catchment_index)*model_timestep
                ! groundwater_routing_volume(catchment_index)=groundwater_routing_volume(cat
                ! chment_index)+incoming_groundwater_fraction_current(catchment_index)*incom
                ! ing_q_current(catchment_index)*3600.*24.
                subsurface_routing_volume(catchment_index) = &
                    subsurface_routing_volume(catchment_index) + &
                    incoming_subsurface_fraction_current(catchment_index)* &
                    incoming_q_current(catchment_index)*model_timestep
                ! subsurface_routing_volume(catchment_index)=subsurface_routing_volume(catch
                ! ment_index)+incoming_subsurface_fraction_current(catchment_index)*incoming
                ! _q_current(catchment_index)*3600.*24.
                surface_routing_volume(catchment_index) = &
                    surface_routing_volume(catchment_index) + &
                    incoming_surface_fraction_current(catchment_index)* &
                    incoming_q_current(catchment_index)*model_timestep
                ! surface_routing_volume(catchment_index)=surface_routing_volume(catchment_i
                ! ndex)+incoming_surface_fraction_current(catchment_index)*incoming_q_curren
                ! t(catchment_index)*3600.*24.

                incoming_q_value_previous = incoming_q_previous(catchment_index)
                incoming_q_value_current = incoming_q_current(catchment_index)
                outgoing_q_value_previous = outgoing_q_previous(catchment_index)
                reach_count = muskingum_reach_count(catchment_index)
                interval_count = model_timestep/muskingum_timestep(catchment_index)
                !interval_count=3600.*24./muskingum_timestep(catchment_index)

                call route_muskingum_cunge(outgoing_q_value_previous, outgoing_q_value_current, &
                                        reach_count, interval_count, coefficient_1, coefficient_2, &
                                           coefficient_3)
                outgoing_q_current(catchment_index) = outgoing_q_value_current

                !Update volume proportions
                routing_volume_total = groundwater_routing_volume(catchment_index) + &
                                       subsurface_routing_volume(catchment_index) + &
                                       surface_routing_volume(catchment_index)
                outgoing_groundwater_fraction_current(catchment_index) = &
                    groundwater_routing_volume(catchment_index)/routing_volume_total
                outgoing_subsurface_fraction_current(catchment_index) = &
                    subsurface_routing_volume(catchment_index)/routing_volume_total
                outgoing_surface_fraction_current(catchment_index) = &
                    surface_routing_volume(catchment_index)/routing_volume_total
                groundwater_routing_volume(catchment_index) = max(0.0, &
                                                     groundwater_routing_volume(catchment_index) - &
                                           outgoing_groundwater_fraction_current(catchment_index)* &
                                                              outgoing_q_current(catchment_index)* &
                                                                  model_timestep)
                ! groundwater_routing_volume(catchment_index)=MAX(0.0,groundwater_routing_vo
                ! lume(catchment_index)-
                ! outgoing_groundwater_fraction_current(catchment_index)*outgoing_q_current(
                ! catchment_index)*3600.*24.)
                subsurface_routing_volume(catchment_index) = max(0.0, &
                                                      subsurface_routing_volume(catchment_index) - &
                                            outgoing_subsurface_fraction_current(catchment_index)* &
                                                              outgoing_q_current(catchment_index)* &
                                                                 model_timestep)
                ! subsurface_routing_volume(catchment_index)=MAX(0.0,subsurface_routing_volu
                ! me(catchment_index)-
                ! outgoing_subsurface_fraction_current(catchment_index)*outgoing_q_current(c
                ! atchment_index)*3600.*24.)
                surface_routing_volume(catchment_index) = max(0.0, &
                                                         surface_routing_volume(catchment_index) - &
                                               outgoing_surface_fraction_current(catchment_index)* &
                                                              outgoing_q_current(catchment_index)* &
                                                              model_timestep)
                ! surface_routing_volume(catchment_index)=MAX(0.0,surface_routing_volume(cat
                ! chment_index)-
                ! outgoing_surface_fraction_current(catchment_index)*outgoing_q_current(catc
                ! hment_index)*3600.*24.)

                ! Flows routing in each catchment are used as upstream boundary in downstream
                ! catchment
                downstream_index = downstream_catchment(catchment_index)

                if (downstream_index > 0) then

                    incoming_groundwater_fraction_current(downstream_index) = &
                        incoming_groundwater_fraction_current(downstream_index)* &
                        incoming_q_current(downstream_index)
                    !underground flow
                    incoming_subsurface_fraction_current(downstream_index) = &
                        incoming_subsurface_fraction_current(downstream_index)* &
                        incoming_q_current(downstream_index)
                    !subsurface flow
                    incoming_surface_fraction_current(downstream_index) = &
                        incoming_surface_fraction_current(downstream_index)* &
                        incoming_q_current(downstream_index)
                    !runoff

                    incoming_q_current(downstream_index) = &
                        incoming_q_current(downstream_index) + &
                        outgoing_q_current(catchment_index)

                    !Muskingum-Cunge boundary condition
                    !Tests if calculated flow must be replaced by flow by file
                    substitution_index = 0
                    do substitution_search_index = 1, substitution_count
                        if (timestep_index > 1 .and. catchment_index == &
                            substitution_catchment(substitution_search_index)) then
                            substitution_index = substitution_search_index
                            exit
                        else
                            substitution_index = 0
                        end if
                    end do

                    if (substitution_index > 0) then
                        if (substituted_q(substitution_index, timestep_index) < 0.0) then
                            !Problem in read data
                            incoming_q_current(downstream_index) = &
                                incoming_q_current(downstream_index)
                            !Uses calculated flow
                            do interval_index = 1, muskingum_interval_count + 1
                                incoming_q_boundary(downstream_index, &
                                                    interval_index) = &
                                    incoming_q_boundary(downstream_index, &
                                                        interval_index) + &
                                    outgoing_q_boundary(catchment_index, &
                                                        interval_index)
                                !update boundary
                            end do
                        else
                            !use flow from file
                          incoming_q_current(downstream_index) = substituted_q(substitution_index, &
                                                                                 timestep_index)
                            do interval_index = 1, muskingum_interval_count + 1
                                !Replaces calculated flow by read flow (from file)
                                incoming_q_boundary(downstream_index, &
                                                    interval_index) = &
                                    substituted_q(substitution_index, &
                                                  timestep_index - 1) + (interval_index - 1)* &
                                    (substituted_q(substitution_index, &
                                                   timestep_index) - &
                                     substituted_q(substitution_index, &
                                                   timestep_index - 1))/ &
                                    muskingum_interval_count
                            end do
                        end if
                    else
                        do interval_index = 1, muskingum_interval_count + 1
                            incoming_q_boundary(downstream_index, &
                                                interval_index) = &
                                incoming_q_boundary(downstream_index, &
                                                    interval_index) + &
                                outgoing_q_boundary(catchment_index, interval_index)
                            !Update boundary
                        end do
                    end if

                    !Update proportions
                    incoming_groundwater_fraction_current(downstream_index) = &
                        (incoming_groundwater_fraction_current(downstream_index) + &
                         outgoing_groundwater_fraction_current(catchment_index)* &
                         outgoing_q_current(catchment_index))/ &
                        incoming_q_current(downstream_index)
                    incoming_subsurface_fraction_current(downstream_index) = &
                        (incoming_subsurface_fraction_current(downstream_index) + &
                         outgoing_subsurface_fraction_current(catchment_index)* &
                         outgoing_q_current(catchment_index))/ &
                        incoming_q_current(downstream_index)
                    incoming_surface_fraction_current(downstream_index) = &
                        (incoming_surface_fraction_current(downstream_index) + &
                         outgoing_surface_fraction_current(catchment_index)* &
                         outgoing_q_current(catchment_index))/ &
                        incoming_q_current(downstream_index)
                end if

                !headboard catchment
            else
                reach_step_length = 0.0
                muskingum_k = 0.0
                muskingum_x = 0.0

                outgoing_q_current(catchment_index) = groundwater_q(catchment_index) + &
                                                      subsurface_q(catchment_index) + &
                                                      surface_q(catchment_index)
                outgoing_groundwater_fraction_current(catchment_index) = &
                    groundwater_q(catchment_index)/outgoing_q_current(catchment_index)
                outgoing_subsurface_fraction_current(catchment_index) = &
                    subsurface_q(catchment_index)/outgoing_q_current(catchment_index)
                outgoing_surface_fraction_current(catchment_index) = &
                    surface_q(catchment_index)/outgoing_q_current(catchment_index)

                ! Flows routing in each catchment are used as upstream boundary in downstream
                ! catchment
                downstream_index = downstream_catchment(catchment_index)

                if (downstream_index > 0) then

                    incoming_groundwater_fraction_current(downstream_index) = &
                        incoming_groundwater_fraction_current(downstream_index)* &
                        incoming_q_current(downstream_index)
                    !underground flow
                    incoming_subsurface_fraction_current(downstream_index) = &
                        incoming_subsurface_fraction_current(downstream_index)* &
                        incoming_q_current(downstream_index)
                    !subsurface flow
                    incoming_surface_fraction_current(downstream_index) = &
                        incoming_surface_fraction_current(downstream_index)* &
                        incoming_q_current(downstream_index)
                    !runoff

                    incoming_q_current(downstream_index) = &
                        incoming_q_current(downstream_index) + surface_q(catchment_index) + &
                        subsurface_q(catchment_index) + groundwater_q(catchment_index)

                    !MUSKINGUM-CUNGE boundary condition
                    do interval_index = 1, muskingum_interval_count + 1
                        incoming_q_boundary(downstream_index, interval_index) = &
                            incoming_q_boundary(downstream_index, interval_index) + &
                            (outgoing_q_previous(catchment_index) + (interval_index - 1)* &
                             (outgoing_q_current(catchment_index) - &
                              outgoing_q_previous(catchment_index))/ &
                             muskingum_interval_count)
                    end do

                    !update proportions
                    incoming_groundwater_fraction_current(downstream_index) = &
                        (incoming_groundwater_fraction_current(downstream_index) + &
                         groundwater_q(catchment_index))/incoming_q_current(downstream_index)
                    incoming_subsurface_fraction_current(downstream_index) = &
                        (incoming_subsurface_fraction_current(downstream_index) + &
                         subsurface_q(catchment_index))/incoming_q_current(downstream_index)
                    incoming_surface_fraction_current(downstream_index) = &
                        (incoming_surface_fraction_current(downstream_index) + &
                         surface_q(catchment_index))/incoming_q_current(downstream_index)
                end if
            end if

            !STORE OUTPUT INFORMATION
            inertial_q(catchment_index) = outgoing_q_current(catchment_index)
            !Saves in inertial_q #v1.41
            incremental_q_output(catchment_index) = catchment_q_current(catchment_index)
            ! incremental_q_output(catchment_index,timestep_index)=catchment_q_current(catchmen
            ! t
            ! _index)
            groundwater_q_output(catchment_index) = groundwater_q(catchment_index)
            ! groundwater_q_output(catchment_index,timestep_index)=groundwater_q(catchment_inde
            ! x)

            !Iteration to find river velocity by inversion of manning eq.
            depth_iteration_previous = 3.0
            do
                depth_iteration_current = ((outgoing_q_current(catchment_index)* &
                              manning_n(catchment_index)/river_slope(catchment_index)**0.5)**0.6)* &
                             ((river_width(catchment_index) + 2*depth_iteration_previous)**(0.4))/ &
                                          river_width(catchment_index)
                if (abs(depth_iteration_current - depth_iteration_previous) < 0.005) exit
                depth_iteration_previous = depth_iteration_current
            end do

            flow_velocity(catchment_index) = outgoing_q_current(catchment_index)/ &
                                             (depth_iteration_current* &
                                              river_width(catchment_index))

        end do
        return
    end subroutine route_muskingum_cunge_network

    subroutine route_muskingum_cunge(upstream_boundary_q, downstream_boundary_q, &
                      reach_count_argument, interval_count_argument, coefficient_1, coefficient_2, &
                                     coefficient_3)
        use simulation_state, only: day
        use runoff_state, only: catchment_index
        use evapotranspiration_state, only: open_water_evaporation_q
        use muskingum_state, only: incoming_q_boundary, initial_river_q, &
                                   max_muskingum_reach_count, outgoing_q_boundary

        implicit none
        integer interval_index, reach_index

        !Muskingum-Cunge Coefficients
        real coefficient_1, coefficient_2, coefficient_3
        !Auxiliary variables
        real upstream_boundary_q, downstream_boundary_q
        !Sub-Rivers number / Number of intervals in a day
        integer reach_count_argument, interval_count_argument

        real, allocatable :: routed_q(:, :)
        real q_loss
        allocate (routed_q(reach_count_argument + 1, interval_count_argument + 1))

        if (reach_count_argument > &
            max_muskingum_reach_count) stop 'MUITOS SUBTRECHOS NA ROTINA MUSK'

        routed_q = 0.0
        outgoing_q_boundary(catchment_index, 1) = upstream_boundary_q

        q_loss = 0.0

        !Upstream boundary conditions
        do interval_index = 1, interval_count_argument + 1
            ! Remove open-water evaporation and prescribed losses at the upstream boundary.
          routed_q(1, interval_index) = max(incoming_q_boundary(catchment_index, interval_index) - &
                                              open_water_evaporation_q(catchment_index) - q_loss, &
                                              0.0)
        end do

        !Initial conditions
        do reach_index = 1, reach_count_argument + 1
            routed_q(reach_index, 1) = initial_river_q(catchment_index, reach_index)
        end do

        do interval_index = 1, interval_count_argument
            do reach_index = 1, reach_count_argument
                routed_q(reach_index + 1, interval_index + 1) = coefficient_1* &
                       routed_q(reach_index, interval_index) + coefficient_2*routed_q(reach_index, &
                                     interval_index + 1) + coefficient_3*routed_q(reach_index + 1, &
                                                                                     interval_index)
                !Avoid negative flows
routed_q(reach_index + 1, interval_index + 1) = max(routed_q(reach_index + 1, interval_index + 1), &
                                                                    0.0)
            end do
            !Save output flows (all stretches and times)
            outgoing_q_boundary(catchment_index, interval_index + 1) = &
                routed_q(reach_count_argument + 1, interval_index + 1)
        end do

        !Save Initial Condition values to next Muskingum-Cunge simulation
   initial_river_q(catchment_index,1)=incoming_q_boundary(catchment_index,interval_count_argument+ &
                                                               1)
        do reach_index = 2, reach_count_argument + 1
   initial_river_q(catchment_index, reach_index) = routed_q(reach_index, interval_count_argument + &
                                                                     1)
        end do

        ! Save last downstream value. This value is returned to route_muskingum_cunge_network
        ! SUBROUTINE.
        downstream_boundary_q = routed_q(reach_count_argument + 1, interval_count_argument + 1)

        deallocate (routed_q)
        return
    end subroutine route_muskingum_cunge

end module muskingum_routing
