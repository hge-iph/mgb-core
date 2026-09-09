! SPDX-License-Identifier: GPL-3.0-or-later
! Copyright (C) 2019 Hidrologia de Grande Escala (HGE)

! Update soil storage and vertical water fluxes for one HRU.

        subroutine update_soil_water_balance(current_precipitation, soil_vegetation_et, &
                       current_soil_water_storage, current_max_soil_water_storage, current_arno_b, &
                                current_subsurface_conductivity, current_groundwater_conductivity, &
                       current_brooks_corey_lambda, surface_runoff_depth, subsurface_runoff_depth, &
                                             groundwater_runoff_depth, current_capillary_flux, &
                    current_capillary_threshold_fraction, model_timestep_seconds, catchment_index, &
                                             current_catchment_area, &
                                             current_floodplain_infiltration_rate)
            use inertial_state
            implicit none

            real current_soil_water_storage
            ! In-soil water storage
            real current_arno_b, current_max_soil_water_storage
            ! Parameters for storage
            real current_subsurface_conductivity, current_groundwater_conductivity
            ! Hydraulic Conductivity
            real current_floodplain_infiltration_rate
            ! Infiltration rate in floodplains
            real subsurface_flow_threshold, groundwater_flow_threshold
            real current_brooks_corey_lambda
            ! shape parameter for subsurface flow
            real current_capillary_flux, current_capillary_threshold_fraction, &
                capillary_flux_threshold
! ascending fluxes
            real current_precipitation, soil_vegetation_et
            ! precipitation and evaporation
            real surface_runoff_depth, subsurface_runoff_depth, groundwater_runoff_depth
            ! surface, subsurface and groundwater drainage
            real infiltration_shape_term
            real previous_soil_storage
            real model_timestep_seconds
            ! time step in seconds
            real effective_precipitation
            ! Correction of precipitation in soil balance due to flooded areas
            integer catchment_index
            real current_catchment_area

            ! The Brooks-Corey pore-size index controls subsurface drainage; typical
            ! values range from 0.165 for clay to 0.694 for sand (Rawls).

            !limiters
            if (current_capillary_threshold_fraction > 0.1) current_capillary_threshold_fraction = &
                0.1
!High values of capillary_flux_threshold can lead groundwater_storage getting dry

            groundwater_flow_threshold = current_capillary_threshold_fraction* &
                                         current_max_soil_water_storage

            ! Use the groundwater-generation threshold for subsurface flow as well.
            subsurface_flow_threshold = groundwater_flow_threshold

            capillary_flux_threshold = current_capillary_threshold_fraction* &
                                       current_max_soil_water_storage
! capillary_flux_threshold is the limit to start ascending Capillary flux

            ! Calculates direct flow (surface waters)
            if (current_precipitation .gt. 0.0) then

                infiltration_shape_term = (1.-current_soil_water_storage/ &
             current_max_soil_water_storage)**(1./(current_arno_b + 1.)) - (current_precipitation/ &
                                                                           ((current_arno_b + 1.)* &
                                                                    current_max_soil_water_storage))

                if (infiltration_shape_term .le. 0.0) then
                    ! Rainfall saturates soil

                    surface_runoff_depth = max(current_precipitation - &
                                    (current_max_soil_water_storage - current_soil_water_storage), &
                                               0.0)
                    !Fernando & Paulo Correction 25/01/2013)

                else
                    ! Rainfall does not saturates soil

                    surface_runoff_depth = max(current_precipitation - &
                                   (current_max_soil_water_storage - current_soil_water_storage) + &
                                               current_max_soil_water_storage* &
                                               (infiltration_shape_term)**(current_arno_b + 1.), &
                                               0.0)
                    !Fernando & Paulo Correction 25/01/2013)

                end if

            else

                surface_runoff_depth = 0.0
                ! if timestep_index does not rain, there is no surface flow

            end if

            ! Calculates groundwater (slow flows)
            if (current_soil_water_storage .ge. groundwater_flow_threshold) then
                groundwater_runoff_depth = current_groundwater_conductivity* &
                                        (current_soil_water_storage - groundwater_flow_threshold)/ &
                                           (current_max_soil_water_storage - &
                                            groundwater_flow_threshold)
                !simple linear approach
            else
                groundwater_runoff_depth = 0.0
            end if

            ! Calculate upward capillary flux.
            current_capillary_flux = max(current_capillary_flux* &
                 (capillary_flux_threshold - current_soil_water_storage)/capillary_flux_threshold, &
                                         0.0)
            ! Bremicker.

            ! Calculates subsurface flow (intermediate)
            ! uses Brooks & Corey relation (5.6 from Handbook of Hydrology)
            if (current_soil_water_storage .le. subsurface_flow_threshold) then
                subsurface_runoff_depth = 0.0
                ! No drainage in low moisture condition
            else
                subsurface_runoff_depth = current_subsurface_conductivity* &
                                        ((current_soil_water_storage - subsurface_flow_threshold)/ &
                            (current_max_soil_water_storage - subsurface_flow_threshold))**(3.+2./ &
                                                                        current_brooks_corey_lambda)
            end if

            ! Limits drainage to avoid negative storage
            subsurface_runoff_depth = min(subsurface_runoff_depth, current_soil_water_storage/10.0)
            ! this assumptions are ok cause
            subsurface_runoff_depth = max(subsurface_runoff_depth, 0.0)
            ! hydr. conductivy can drop fast

            ! Updates in-soil stored water for calibration
            previous_soil_storage = current_soil_water_storage
            effective_precipitation = current_precipitation

            !Calculates infiltration from floodplain (Inertial module only)
            if (routing_method(catchment_index) == 0) then
                current_floodplain_infiltration = 0.0
                !Inertial module is disabled
            else
                ! Limit floodplain infiltration to the subsurface rate or 20 mm/day.
                current_floodplain_infiltration_rate = min(current_subsurface_conductivity, 20.0)
                !Infilttration rate when Inertial module is enabled !in mm/day
                current_floodplain_infiltration = (current_flooded_area(catchment_index)/ &
     current_catchment_area)*current_floodplain_infiltration_rate*(1 - current_soil_water_storage/ &
                                                                  current_max_soil_water_storage)**1

                !Correcting fluxes due to flooded area
                surface_runoff_depth = surface_runoff_depth*max(current_catchment_area - &
                                                      current_flooded_area(catchment_index), 0.0)/ &
                                       current_catchment_area
                effective_precipitation = effective_precipitation*max(current_catchment_area - &
                                                      current_flooded_area(catchment_index), 0.0)/ &
                                          current_catchment_area
                soil_vegetation_et = soil_vegetation_et*max(current_catchment_area - &
                                                      current_flooded_area(catchment_index), 0.0)/ &
                                     current_catchment_area

            end if
            current_floodplain_infiltration = max(current_floodplain_infiltration, 0.0)

            ! Convert to time-step when necessary (smaller than daily)
            surface_runoff_depth = surface_runoff_depth
            current_capillary_flux = current_capillary_flux*model_timestep_seconds/86400.
            subsurface_runoff_depth = subsurface_runoff_depth*model_timestep_seconds/86400.
            groundwater_runoff_depth = groundwater_runoff_depth*model_timestep_seconds/86400.
         current_floodplain_infiltration = current_floodplain_infiltration*model_timestep_seconds/ &
                                              86400.

            ! Starts vertical balance loop
            !  ends only if calculated storage is not negative
            do

               current_soil_water_storage = current_soil_water_storage + effective_precipitation + &
                  (current_floodplain_infiltration + current_capillary_flux - soil_vegetation_et - &
                                              surface_runoff_depth - subsurface_runoff_depth - &
                                              groundwater_runoff_depth)
                !updates water balance with corrected variables according to flooded area

                ! New adjustment (Paiva)
                ! Considers adjusting evapotranspiration and drainage
                if (current_soil_water_storage < current_max_soil_water_storage + 0.01 .and. &
                    current_soil_water_storage > &
                    current_max_soil_water_storage) current_soil_water_storage = &
                    current_max_soil_water_storage
                if (current_soil_water_storage > -0.01 .and. current_soil_water_storage < &
                    0.0) current_soil_water_storage = 0.0
                if (current_soil_water_storage > current_max_soil_water_storage) then
                    surface_runoff_depth = surface_runoff_depth + &
                                         current_soil_water_storage - current_max_soil_water_storage
                    current_soil_water_storage = previous_soil_storage

                elseif (current_soil_water_storage < 0.0) then

                    soil_vegetation_et = soil_vegetation_et - (-current_soil_water_storage)
                    if (soil_vegetation_et >= 0.0) then
                        current_soil_water_storage = previous_soil_storage
                        cycle
                    end if
                    current_soil_water_storage = soil_vegetation_et
                    !accept storage as the residual
                    soil_vegetation_et = 0.0
                    !then zero evaporation

                    ! reduces percolation
                    groundwater_runoff_depth = groundwater_runoff_depth - (- &
                                                                         current_soil_water_storage)
                    if (groundwater_runoff_depth >= 0.0) then
                        current_soil_water_storage = previous_soil_storage
                        cycle
                    end if
                    ! percolation is zero but water balance is not closed
                    current_soil_water_storage = groundwater_runoff_depth
                    !accept storage as the residual
                    groundwater_runoff_depth = 0.0
                    !zero groundwater flux

                    ! reduces subsurface
                    subsurface_runoff_depth = subsurface_runoff_depth - (- &
                                                                         current_soil_water_storage)
                    if (subsurface_runoff_depth >= 0.0) then
                        current_soil_water_storage = previous_soil_storage
                        cycle
                    end if
                    ! subsurface is zero but water balance is not closed
                    current_soil_water_storage = subsurface_runoff_depth
                    !accept storage as the residual
                    subsurface_runoff_depth = 0.0

                    ! reduces surface water
                    surface_runoff_depth = surface_runoff_depth - (-current_soil_water_storage)
                    if (surface_runoff_depth >= 0.0) then
                        current_soil_water_storage = previous_soil_storage
                        cycle
                    end if
                    surface_runoff_depth = 0.0

                    ! surface water is zero but water balance didnt close
                    ! nothing to do anymore.
                    write (*, *) 'Soil went dry'
                    current_soil_water_storage = 0.001
                    exit
                else
                    exit
                end if

            end do

            return
        end subroutine update_soil_water_balance
