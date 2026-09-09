module catchment_hydrology

    implicit none
    private
    public :: calculate_catchment_time_of_concentration, initialize_catchment_hydrology, &
              update_catchment_hydrology

contains

    subroutine initialize_catchment_hydrology
        use catchment_state, only: catchment_area, catchment_count, catchment_index, &
                                   catchment_subbasin, hru_count, hru_index, subbasin_index
        use meteorological_state, only: air_temperature
        use water_balance_state, only: groundwater_q, groundwater_routing_coefficient, &
                                       groundwater_storage, interception_storage, &
                                       max_soil_water_storage, soil_water_storage, &
                                       specific_baseflow, subsurface_q, &
                                       subsurface_routing_coefficient, subsurface_storage, &
                                       surface_q, surface_routing_coefficient, surface_storage
        use muskingum_state, only: concentration_time

        implicit none

        integer :: routing_delay

        interception_storage = 0.0
        do catchment_index = 1, catchment_count
            subbasin_index = catchment_subbasin(catchment_index)
            do hru_index = 1, hru_count
                soil_water_storage(catchment_index, hru_index) = &
                    max_soil_water_storage(subbasin_index, hru_index)*0.15
            end do
        end do
        do catchment_index = 1, catchment_count
            subbasin_index = catchment_subbasin(catchment_index)
            groundwater_storage(catchment_index) = specific_baseflow(subbasin_index)* &
                  catchment_area(catchment_index)*groundwater_routing_coefficient(subbasin_index)* &
                                                   3600.
            subsurface_storage(catchment_index) = 0.0
            surface_storage(catchment_index) = 0.0
        end do
        do catchment_index = 1, catchment_count
            subbasin_index = catchment_subbasin(catchment_index)
            routing_delay = groundwater_routing_coefficient(subbasin_index)*3600.
            groundwater_q(catchment_index) = groundwater_storage(catchment_index)/routing_delay
            routing_delay = subsurface_routing_coefficient(subbasin_index)* &
                            concentration_time(catchment_index)
            subsurface_q(catchment_index) = subsurface_storage(catchment_index)/routing_delay
            routing_delay = surface_routing_coefficient(subbasin_index)* &
                            concentration_time(catchment_index)
            surface_q(catchment_index) = surface_storage(catchment_index)/routing_delay
        end do
        air_temperature = 20.0
    end subroutine initialize_catchment_hydrology

    subroutine calculate_catchment_time_of_concentration
        use catchment_state, only: catchment_count, longest_reach_length, longest_reach_slope
        use muskingum_state, only: concentration_time, current_reach_length, &
                                   elevation_difference

        implicit none
        integer catchment_parameter_index

        ! Calculates Time of Concentration (i.e. time of travel) for Catchment
        do catchment_parameter_index = 1, catchment_count
            current_reach_length = longest_reach_length(catchment_parameter_index)
            ! km
            elevation_difference = longest_reach_slope(catchment_parameter_index) &
                                   *longest_reach_length(catchment_parameter_index)
            ! m

            concentration_time(catchment_parameter_index) = 3600. &
                                                            *((0.868*current_reach_length**3.0)/ &
                                                              elevation_difference)**0.385
        end do

        return
    end

    subroutine update_catchment_hydrology
        use date_time, only: calculate_integer_julian_day
        use simulation_state, only: day, day_of_year, first_subbasin, last_subbasin, &
                                    model_timestep, month, year
        use catchment_state, only: catchment_area, catchment_count, catchment_index, &
               catchment_subbasin, catchment_y, climate_region, current_catchment_area, hru_count, &
                                   hru_index, hru_percentage, subbasin_index
        use meteorological_state, only: air_pressure, air_temperature, precipitation, &
                                previous_air_temperature, relative_humidity, solar_input, wind_speed
        use water_balance_state, only: actual_interception_et, albedo, arno_b, &
                                brooks_corey_lambda, capillary_flux, capillary_threshold_fraction, &
                            catchment_capillary_q, catchment_soil_water_sum, current_air_pressure, &
             current_air_temperature, current_albedo, current_arno_b, current_brooks_corey_lambda, &
                                     current_capillary_flux, current_capillary_threshold_fraction, &
                            current_floodplain_infiltration, current_floodplain_infiltration_rate, &
                                   current_groundwater_conductivity, current_interception_storage, &
                   current_leaf_area_index, current_max_soil_water_storage, current_precipitation, &
                       current_relative_humidity, current_soil_water_storage, current_solar_input, &
                 current_subsurface_conductivity, current_surface_resistance, current_temperature, &
              current_total_et, current_vegetation_height, current_wind_speed, evapotranspiration, &
                  floodplain_infiltration, floodplain_infiltration_rate, groundwater_conductivity, &
                                groundwater_delay, groundwater_q, groundwater_routing_coefficient, &
                             groundwater_storage, hru_area_fraction, incoming_shortwave_radiation, &
                        interception_storage, latent_heat_vaporization, latitude, leaf_area_index, &
                  max_capillary_flux, max_soil_water_storage, minimum_soil_storage, net_radiation, &
                     open_water_evaporation_q, potential_interception_et, potential_open_water_et, &
                                  potential_open_water_et_current, potential_surface_radiation_et, &
                  potential_top_radiation_et, previous_temperature, remaining_groundwater_storage, &
                      remaining_subsurface_storage, remaining_surface_storage, soil_vegetation_et, &
                      soil_water_storage, subsurface_conductivity, subsurface_delay, subsurface_q, &
                     subsurface_routing_coefficient, subsurface_storage, surface_delay, surface_q, &
                                 surface_resistance, surface_routing_coefficient, surface_storage, &
                     top_atmosphere_radiation, total_water_storage, vegetation_height, water_density
        use reservoir_state, only: substitution_enabled
        use muskingum_state, only: concentration_time
        use inertial_state, only: current_flooded_area, routing_method
        use output_state, only: capillary_water_output, catchment_q_output, et_output, &
                                groundwater_runoff_depth_output, groundwater_storage_depth_output, &
                        interception_et_output, interception_storage_output, open_water_et_output, &
                             soil_saturation_output, soil_vegetation_et_output, soil_water_output, &
                                subsurface_runoff_depth_output, subsurface_storage_depth_output, &
                      surface_runoff_depth_output, surface_storage_depth_output, water_hru_et_output

        implicit none

        real surface_runoff_depth, subsurface_runoff_depth, groundwater_runoff_depth
        real accumulated_surface_q, accumulated_subsurface_q, accumulated_groundwater_q
        !Accumulated runoffs for HRUs

        ! Gets day of the year (day_of_year) for computing radiation
 day_of_year = calculate_integer_julian_day(year, month, day) - calculate_integer_julian_day(year, &
                                                                                           1, 1) + &
                      1

        ! Initialize variables accumulated across HRUs.
        total_water_storage = 0.0
        floodplain_infiltration = 0.0

        ! Initializes other variables to accumulate (are used to write output files)
        et_output = 0.0
        soil_water_output = 0.0
        interception_et_output = 0.0
        soil_vegetation_et_output = 0.0
        open_water_et_output = 0.0
        interception_storage_output = 0.0
        capillary_water_output = 0.0
        catchment_q_output = 0.0
        water_hru_et_output = 0.0

        ! Catchments loop
        do catchment_index = 1, catchment_count

            !Reset Surface, subsurface and groundwater runoff at each unit-catchment loop
            accumulated_surface_q = 0.0
            accumulated_subsurface_q = 0.0
            accumulated_groundwater_q = 0.0

            if (substitution_enabled(catchment_index) == 1) cycle

            subbasin_index = catchment_subbasin(catchment_index)

            if ((subbasin_index < first_subbasin) .or. (subbasin_index > last_subbasin)) cycle
            ! Manual controls for specialized calibration

            open_water_evaporation_q(catchment_index) = 0.0
            !Direct evaporation from open waters

            ! HRU loop
            do hru_index = 1, hru_count

                if (hru_percentage(catchment_index, hru_index) .lt. 0.0001) then
                    cycle
                end if

                !Temporary variables
                current_precipitation = precipitation(catchment_index)
                ! Loads rain
                current_soil_water_storage = soil_water_storage(catchment_index, hru_index)
                ! Soil Water storage
                current_interception_storage = interception_storage(catchment_index, hru_index)
                current_max_soil_water_storage = max_soil_water_storage(subbasin_index, &
                                                                        hru_index)
                ! Maximum soil water storage
                current_air_pressure = air_pressure(catchment_index)
                ! air pressure
                current_air_temperature = air_temperature(catchment_index)
! air temperature
                current_wind_speed = wind_speed(catchment_index)
                ! wind speed
                current_relative_humidity = relative_humidity(catchment_index)
! relative humidity
                current_solar_input = solar_input(catchment_index)
                ! solar radiation (or number of hours-insolation)
                current_brooks_corey_lambda = brooks_corey_lambda(subbasin_index, hru_index)
                ! lambda parameter from ARNO model
                previous_temperature = previous_air_temperature(catchment_index)
! day before air temperature
                current_temperature = air_temperature(catchment_index)
                ! air temperature
                current_leaf_area_index = leaf_area_index(hru_index, month, &
                                                          climate_region(catchment_index))
! leaf-area index
                current_albedo = albedo(hru_index, month, climate_region(catchment_index))
                ! albedo
                current_vegetation_height = vegetation_height(hru_index, month, &
                                                              climate_region(catchment_index))
                ! vegetation height
                current_surface_resistance = surface_resistance(hru_index, month, &
                                                                climate_region(catchment_index))
                ! surface resistnace
                current_arno_b = arno_b(subbasin_index, hru_index)
                ! arno_b parameter from ARNO model
                current_subsurface_conductivity = subsurface_conductivity(subbasin_index, &
                                                                          hru_index)
! Subsurface water flow
                current_groundwater_conductivity = groundwater_conductivity(subbasin_index, &
                                                                            hru_index)
! Groundwater flow
                current_capillary_flux = max_capillary_flux(subbasin_index, hru_index)
! Capilarity
                ! Limit the threshold to avoid exhausting groundwater storage.
               current_capillary_threshold_fraction = capillary_threshold_fraction(subbasin_index, &
                                                                                    hru_index)
               current_floodplain_infiltration_rate = floodplain_infiltration_rate(subbasin_index, &
                                                                                    hru_index)
                ! Infiltration rate of saturated soil in floodplain

                if (current_air_temperature .lt. -50.0 .or. current_air_temperature .gt. &
                    50.0) stop 'ERROR AIR TEMP SUB CELULA'
                if (current_wind_speed .lt. 0.0 .or. current_wind_speed .gt. &
                    100.) stop 'ERROR WIND SUB CELULA'
                if (current_relative_humidity .lt. 0.0 .or. current_relative_humidity .gt. &
                    100.01) stop 'ERROR UMIDITY SUB CELULA'

                ! Calculates Net Radiation
                latitude = catchment_y(catchment_index)
                !Loads catchment latitude
                call calculate_net_radiation
                !Returns net_radiation - Net radiation

                ! Calculates evapotranspiration and interception (updates
                ! current_precipitation)
                call calculate_evapotranspiration

                current_catchment_area = catchment_area(catchment_index)
                ! Soil water balance
                if (current_max_soil_water_storage .gt. 0.001) then
                    call update_soil_water_balance(current_precipitation, soil_vegetation_et, &
                       current_soil_water_storage, current_max_soil_water_storage, current_arno_b, &
                                current_subsurface_conductivity, current_groundwater_conductivity, &
                       current_brooks_corey_lambda, surface_runoff_depth, subsurface_runoff_depth, &
                                                 groundwater_runoff_depth, current_capillary_flux, &
                            current_capillary_threshold_fraction, model_timestep, catchment_index, &
                                                   current_catchment_area, &
                                                   current_floodplain_infiltration_rate)
                    current_total_et = soil_vegetation_et + actual_interception_et
                else
                    if (routing_method(catchment_index) == 0) then
                        ! if open water (max_soil_water_storage=0.0), surface flow equals
                        ! interception
                        surface_runoff_depth = current_precipitation
                        subsurface_runoff_depth = 0.0
                        groundwater_runoff_depth = 0.0
                        current_capillary_flux = 0.0
                        open_water_evaporation_q(catchment_index) = &
                            (potential_open_water_et_current*1000.* &
                             catchment_area(catchment_index)* &
                             (hru_percentage(catchment_index, hru_index)/100.))/ &
                            model_timestep
                        !Direct evaporation from open waters in m3/s
                    else
                        ! Considers evaporation in floodplain water
                        surface_runoff_depth = current_precipitation
                        subsurface_runoff_depth = 0.0
                        groundwater_runoff_depth = 0.0
                        current_capillary_flux = 0.0
                        open_water_evaporation_q(catchment_index) = &
                            potential_open_water_et_current
                    end if
                    current_total_et = potential_interception_et
                end if

                evapotranspiration(catchment_index, hru_index) = current_total_et

                soil_water_storage(catchment_index, hru_index) = current_soil_water_storage
                interception_storage(catchment_index, hru_index) = current_interception_storage
                capillary_flux(catchment_index, hru_index) = current_capillary_flux

                hru_area_fraction = hru_percentage(catchment_index, hru_index)/100.
                !HRU area  fraction
                catchment_soil_water_sum = catchment_soil_water_sum + &
                                           current_soil_water_storage*hru_area_fraction
                !Average Water Soil-Storage in catchment
                minimum_soil_storage = minimum_soil_storage + current_max_soil_water_storage* &
                                       hru_area_fraction
!Average max_soil_water_storage in the catchment

                !Flow to linear reservoirs
             surface_runoff_depth = ((surface_runoff_depth*1000.)*catchment_area(catchment_index)* &
                                        (hru_percentage(catchment_index, hru_index)/100.))/ &
                                       (model_timestep)
                subsurface_runoff_depth = ((subsurface_runoff_depth*1000.)* &
                      catchment_area(catchment_index)*(hru_percentage(catchment_index, hru_index)/ &
                                                                            100.))/ &
                                          (model_timestep)
                groundwater_runoff_depth = ((groundwater_runoff_depth*1000.)* &
                      catchment_area(catchment_index)*(hru_percentage(catchment_index, hru_index)/ &
                                                                             100.))/ &
                                           (model_timestep)
                !Accumulate generated Runoff (m³/s)
                accumulated_surface_q = accumulated_surface_q + surface_runoff_depth
                accumulated_subsurface_q = accumulated_subsurface_q + subsurface_runoff_depth
                accumulated_groundwater_q = accumulated_groundwater_q + &
                                            groundwater_runoff_depth

                !Storing evapotranspiration
                et_output(catchment_index) = et_output(catchment_index) + (soil_vegetation_et + &
                              actual_interception_et)*(hru_percentage(catchment_index, hru_index)/ &
                                                                                               100.)
               interception_et_output(catchment_index) = interception_et_output(catchment_index) + &
                             (actual_interception_et)*(hru_percentage(catchment_index, hru_index)/ &
                                                                                    100.)
         soil_vegetation_et_output(catchment_index) = soil_vegetation_et_output(catchment_index) + &
                                 (soil_vegetation_et)*(hru_percentage(catchment_index, hru_index)/ &
                                                                                   100.)

                if (routing_method(catchment_index) == 1) then
                    !Summing infiltration for continuity equation
             floodplain_infiltration(catchment_index) = floodplain_infiltration(catchment_index) + &
                  current_floodplain_infiltration*hru_percentage(catchment_index, hru_index)/100.* &
                                                               catchment_area(catchment_index)/ &
                                                               current_flooded_area(catchment_index)
                    !CEAA infilt
                end if

                ! Capillary flux converts from mm per model timestep to m3/s.
      catchment_capillary_q = catchment_capillary_q + (hru_percentage(catchment_index, hru_index)/ &
                             100.)*(current_capillary_flux*1000.*catchment_area(catchment_index))/ &
                                        (model_timestep)

                !Updates linear reservoir volumes(m3)
                groundwater_storage(catchment_index) = groundwater_storage(catchment_index) + &
                                                       groundwater_runoff_depth* &
                                                       model_timestep
                ! groundwater_storage(catchment_index)=groundwater_storage(catchment_index)+
                ! groundwater_runoff_depth*3600.*24.
                subsurface_storage(catchment_index) = subsurface_storage(catchment_index) + &
                                                      subsurface_runoff_depth* &
                                                      model_timestep
                ! subsurface_storage(catchment_index)=subsurface_storage(catchment_index)+su
                ! bsurface_runoff_depth*3600.*24.
                surface_storage(catchment_index) = surface_storage(catchment_index) + &
                                                   surface_runoff_depth*model_timestep
                ! surface_storage(catchment_index)=surface_storage(catchment_index)+surface_
                ! runoff_depth*3600.*24.

                !Updates Terrestrial Water Storage (mm)
                total_water_storage(catchment_index) = total_water_storage(catchment_index) + &
           (interception_storage(catchment_index, hru_index) + soil_water_storage(catchment_index, &
                                          hru_index))*(hru_percentage(catchment_index, hru_index)/ &
                                                                                              100.0)
                !VAS - GRACE

                !Storages
                soil_water_output(catchment_index) = soil_water_output(catchment_index) + &
                 (soil_water_storage(catchment_index, hru_index))*(hru_percentage(catchment_index, &
                                                                                       hru_index)/ &
                                                                                              100.0)
                interception_storage_output(catchment_index) = &
              interception_storage_output(catchment_index) + interception_storage(catchment_index, &
                                           hru_index)*(hru_percentage(catchment_index, hru_index)/ &
                                                                                              100.0)

            end do
            !end HRU loop

            ! Takes water from groundwater reservoir by Capillary flux
            !Check Negative volumes after retrieving water from groundwater reservoir
            if (groundwater_storage(catchment_index) - catchment_capillary_q*model_timestep < &
                0.0) then
                write (*, *) 'Capillarity very high! Vbas went dry. Please check CAP and WC.'
            end if
            groundwater_storage(catchment_index) = max(groundwater_storage(catchment_index) - &
                                                       catchment_capillary_q*model_timestep, &
                                                       0.0)
            ! Update volumes. Fernando & Paulo fixed in 25/01/2013 - limit negative volume in
            ! linear reservoir. FMF

            catchment_capillary_q = 0.0

            ! Calculate soil moisture as saturation degree
            ! (soil_water_storage/max_soil_water_storage weighted by HRU) !ASF 2020
            soil_saturation_output(catchment_index) = catchment_soil_water_sum/ &
                                                      minimum_soil_storage

            ! Calculates catchment discharges
            groundwater_delay(catchment_index) = groundwater_routing_coefficient(subbasin_index)* &
                                                 3600.
!groundwater_routing_coefficient is defined in hours in parameter file ! convert to seconds
            subsurface_delay(catchment_index) = subsurface_routing_coefficient(subbasin_index)* &
                                                concentration_time(catchment_index)
            !subsurface_routing_coefficient is defined in parameter file
            surface_delay(catchment_index) = surface_routing_coefficient(subbasin_index)* &
                                             concentration_time(catchment_index)
            !surface_routing_coefficient is defined in parameter file
            groundwater_q(catchment_index) = groundwater_storage(catchment_index)/ &
                                             groundwater_delay(catchment_index)
            subsurface_q(catchment_index) = subsurface_storage(catchment_index)/ &
                                            subsurface_delay(catchment_index)
            surface_q(catchment_index) = surface_storage(catchment_index)/ &
                                         surface_delay(catchment_index)

            ! Updates Volumes (m3)
            remaining_groundwater_storage = groundwater_storage(catchment_index) - &
                                            groundwater_q(catchment_index)* &
                                            model_timestep
            remaining_subsurface_storage = subsurface_storage(catchment_index) - &
                                           subsurface_q(catchment_index)*model_timestep
            remaining_surface_storage = surface_storage(catchment_index) - &
                                        surface_q(catchment_index)*model_timestep

            ! Assume that surface reservoir can have negative volumes to address floodplain
            ! evaporation
            if (routing_method(catchment_index) == 0) then
                if (remaining_surface_storage .lt. 0.0) then
                    !surface
                    surface_q(catchment_index) = surface_storage(catchment_index)/ &
                                                 (model_timestep)
                    surface_storage(catchment_index) = 0.0
                else
                    surface_storage(catchment_index) = remaining_surface_storage
                end if
            else

                if (surface_storage(catchment_index) < 0.0) then
                    ! Negative discharge is instantly taken in next time interval, without
                    ! phase
                    ! shift
                    surface_q(catchment_index) = surface_storage(catchment_index)/ &
                                                 (model_timestep)
                    surface_storage(catchment_index) = 0.0
                elseif (remaining_surface_storage < 0.0) then
                    surface_q(catchment_index) = surface_storage(catchment_index)/ &
                                                 (model_timestep)
                    surface_storage(catchment_index) = 0.0
                else
                    surface_storage(catchment_index) = remaining_surface_storage
                end if

            end if

            if (remaining_subsurface_storage .lt. 0.0) then
                !sub-surface
                subsurface_q(catchment_index) = subsurface_storage(catchment_index)/ &
                                                (model_timestep)
                subsurface_storage(catchment_index) = 0.0
            else
                subsurface_storage(catchment_index) = remaining_subsurface_storage
            end if
            if (remaining_groundwater_storage .lt. 0.0) then
                !groundwater
                groundwater_q(catchment_index) = groundwater_storage(catchment_index)/ &
                                                 (model_timestep)
                groundwater_storage(catchment_index) = 0.0
            else
                groundwater_storage(catchment_index) = remaining_groundwater_storage
            end if
            !Ends drying linear reservoirs verification

            !clear temporary variables
            catchment_soil_water_sum = 0.0
            minimum_soil_storage = 0.0

            ! Calculates evapotranspiration indicators
            ! Evaporation from open water
            potential_open_water_et(catchment_index) = potential_open_water_et_current
            ! mm per model timestep.
            ! Potential ET using all energy at the top of the atmosphere.
            potential_top_radiation_et(catchment_index) = 1000.*top_atmosphere_radiation/ &
                                                          (water_density* &
                                                           latent_heat_vaporization)
            ! Potential ET using shortwave radiation at the terrestrial surface.
            potential_surface_radiation_et(catchment_index) = 1000.*incoming_shortwave_radiation/ &
                                                              (water_density* &
                                                               latent_heat_vaporization)
            ! VAS (30/09/2016)= Precipitation must be corrected (i.e. considering interception)
            ! for floodplain vertical balance in flood continuity eq.
            precipitation(catchment_index) = current_precipitation

            !Updating Terrestrial Water Storage with Linear reservoirs (mm)
            total_water_storage(catchment_index) = total_water_storage(catchment_index) + &
                     (groundwater_storage(catchment_index) + subsurface_storage(catchment_index) + &
                               surface_storage(catchment_index))/(catchment_area(catchment_index)* &
                                                                                       1000.0)
            ! VAS - GRACE

        groundwater_storage_depth_output(catchment_index) = (groundwater_storage(catchment_index)/ &
                                                                 (catchment_area(catchment_index)* &
                                                                  1000.0))
          subsurface_storage_depth_output(catchment_index) = (subsurface_storage(catchment_index)/ &
                                                                (catchment_area(catchment_index)* &
                                                                 1000.0))
            surface_storage_depth_output(catchment_index) = (surface_storage(catchment_index)/ &
                                                             (catchment_area(catchment_index)* &
                                                              1000.0))

            !Changed to runoff aggregated
            groundwater_runoff_depth_output(catchment_index) = (accumulated_groundwater_q/ &
                                                        (catchment_area(catchment_index)*1000.0))* &
                                                               model_timestep
            subsurface_runoff_depth_output(catchment_index) = (accumulated_subsurface_q/ &
                                                        (catchment_area(catchment_index)*1000.0))* &
                                                              model_timestep
            surface_runoff_depth_output(catchment_index) = (accumulated_surface_q/ &
                                                        (catchment_area(catchment_index)*1000.0))* &
                                                           model_timestep

        end do
        !End catchment loop

79      format(i5, 12f6.1)
        return
    end subroutine update_catchment_hydrology

    subroutine update_soil_water_balance(current_precipitation, soil_vegetation_et, &
                       current_soil_water_storage, current_max_soil_water_storage, current_arno_b, &
                                current_subsurface_conductivity, current_groundwater_conductivity, &
                       current_brooks_corey_lambda, surface_runoff_depth, subsurface_runoff_depth, &
                                         groundwater_runoff_depth, current_capillary_flux, &
                            current_capillary_threshold_fraction, model_timestep, catchment_index, &
                                         current_catchment_area, &
                                         current_floodplain_infiltration_rate)
        use simulation_state, only: day, timestep_index
        use meteorological_state, only: precipitation
        use water_balance_state, only: current_floodplain_infiltration, evapotranspiration, &
                                       groundwater_storage
        use inertial_state, only: current_flooded_area, routing_method

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
        real model_timestep
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
        current_capillary_flux = current_capillary_flux*model_timestep/86400.
        subsurface_runoff_depth = subsurface_runoff_depth*model_timestep/86400.
        groundwater_runoff_depth = groundwater_runoff_depth*model_timestep/86400.
        current_floodplain_infiltration = current_floodplain_infiltration*model_timestep/ &
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

    subroutine calculate_evapotranspiration
        use simulation_state, only: model_timestep
        use water_balance_state, only: actual_interception_et, actual_vapor_pressure, &
                              aerodynamic_resistance, air_density, available_interception_storage, &
                      current_air_pressure, current_air_temperature, current_interception_storage, &
                   current_leaf_area_index, current_max_soil_water_storage, current_precipitation, &
                         current_soil_water_storage, current_surface_resistance, current_total_et, &
                                current_vegetation_height, current_wind_speed, evapotranspiration, &
                                latent_heat_vaporization, max_interception_storage, net_radiation, &
                                     open_water_aerodynamic_resistance, potential_interception_et, &
                                       potential_open_water_et_current, psychrometric_constant, &
                                       remaining_et_demand_fraction, saturation_vapor_pressure, &
                            saturation_vapor_pressure_slope, soil_moisture_unlimited_et_threshold, &
                                 soil_vegetation_et, surface_resistance_factor, surface_roughness, &
                      vapor_pressure_deficit, water_density, wet_air_specific_heat, wilting_point, &
                                       wind_speed_reference

        implicit none

        vapor_pressure_deficit = saturation_vapor_pressure - actual_vapor_pressure
        ! Vapor pressure deficit in KPa
        psychrometric_constant = 0.0016286*current_air_pressure/latent_heat_vaporization
        ! KPa/C (EQ. 4.2.28)
        saturation_vapor_pressure_slope = (4098.0*saturation_vapor_pressure)/((237.3 + &
                                                                       current_air_temperature)**2.)
        ! (EQ. 4.2.3)
        air_density = 3.486*(current_air_pressure/(275.0 + current_air_temperature))
! KG/M3 (EQ. 4.2.4)

        net_radiation = net_radiation/(3600.0*24.0)
        ! Net Radiation in MJ/m2/s

        ! Aerodynamic roughness of vegetation
        surface_roughness = 0.1*current_vegetation_height

        ! Aerodynamic resistance is based on Bremicker work
        ! Fix wind speed at 2m to 10m above the ground
        ! Considering current_wind_speed input as wind at 10m
        current_wind_speed = current_wind_speed + 0.1
        !        Avoid zero value issues
        wind_speed_reference = current_wind_speed/((log(10.0/surface_roughness))/log(2.0/ &
                                                                                 surface_roughness))
!wind speed at 2m for calculation of aerodynamic_resistance and potential evapotranspiration

        ! Aerodynamic resistance according to Shuttleworth
        current_vegetation_height = min(current_vegetation_height, 12.5)
        !limits vegetation height to avoid problems
        aerodynamic_resistance = ((log((10.-current_vegetation_height*0.67)/ &
                    (current_vegetation_height*0.123)))*(log((10.-current_vegetation_height*0.67)/ &
                                                 (current_vegetation_height*0.0123))))/(0.41*0.41* &
                                                                                 current_wind_speed)
        open_water_aerodynamic_resistance = (4.72*(log(2./0.00137))**2.)/(1.+0.536* &
                                                                          wind_speed_reference)
!aerodynamic_resistance for open water evaporation ! (EQ.4.2.29) from Shuttleworth

        ! Calculate Surface Resistance (current_surface_resistance) for soil moisture
        ! conditions
        soil_moisture_unlimited_et_threshold = 0.8*current_max_soil_water_storage
! Limit from which soil moisture dont limit evapotranspiration !calculate_evapotranspiration 0.8
        wilting_point = 0.1*current_max_soil_water_storage
        ! Wilting Point

        ! Surface Resistance Variation with Soil moisture (Wigmosta evapotranspiration al. 1994
        ! - eq. 16)
        if (current_max_soil_water_storage < 0.1) then
            ! Open water has no surface resistance
            current_surface_resistance = 0.0
        else
            if (current_soil_water_storage .le. wilting_point) then
                current_surface_resistance = 999999999.0
                ! Dry soil, assume superhigh surface resistance
            elseif (current_soil_water_storage .lt. soil_moisture_unlimited_et_threshold) then
                surface_resistance_factor = (current_soil_water_storage - wilting_point)/ &
                                            (soil_moisture_unlimited_et_threshold - &
                                             wilting_point)
                surface_resistance_factor = 1./surface_resistance_factor
                ! Moisture deficit
            else
                surface_resistance_factor = 1.0
            end if
            current_surface_resistance = surface_resistance_factor*current_surface_resistance
            !if surface_resistance_factor>1 increases surface resistance
        end if

        ! Calculates evaporation from intercepted water
        ! Maximum Interception
        ! Maximum interception storage varies with leaf area and timestep length.
        max_interception_storage = 0.4*current_leaf_area_index*(model_timestep/86400.)
! max_interception_storage=0.2*current_leaf_area_index !According to Wigmosta evapotranspiration
! al.
! 1994, also used by Bremicker

        ! Adds Rainfall to water that can be evaporated.
        available_interception_storage = min(current_interception_storage + current_precipitation, &
                                             max_interception_storage)
        ! Updates Rainfall
        current_precipitation = current_precipitation - &
                                (available_interception_storage - current_interception_storage)

        ! Potential Evaporation from interception (note: current_surface_resistance = 0.0)
        potential_interception_et = ((saturation_vapor_pressure_slope*net_radiation + air_density* &
                             wet_air_specific_heat*vapor_pressure_deficit/aerodynamic_resistance)/ &
   (saturation_vapor_pressure_slope + psychrometric_constant*(1.0 + 0.0/aerodynamic_resistance)))* &
                                    ((1000.0*model_timestep)/(latent_heat_vaporization* &
                                                              water_density))
        ! mm per model timestep.
        potential_open_water_et_current = ((saturation_vapor_pressure_slope*net_radiation + &
                                         air_density*wet_air_specific_heat*vapor_pressure_deficit/ &
     open_water_aerodynamic_resistance)/(saturation_vapor_pressure_slope + psychrometric_constant* &
                         (1.0 + 0.0/open_water_aerodynamic_resistance)))*((1000.0*model_timestep)/ &
                                                                        (latent_heat_vaporization* &
                                                                                     water_density))
        ! mm per model timestep for open water (Shuttleworth).

        actual_interception_et = min(potential_interception_et, available_interception_storage)
        ! evaporation of intercepted water
        ! Takes from interception reservoir
        current_interception_storage = available_interception_storage - actual_interception_et

        ! Calculates evaporative demand fraction after evaporation
        remaining_et_demand_fraction = (potential_interception_et - actual_interception_et)/ &
                                       potential_interception_et

        ! Calculates Penman in mm per model timestep.
        soil_vegetation_et = ((saturation_vapor_pressure_slope*net_radiation + air_density* &
                             wet_air_specific_heat*vapor_pressure_deficit/aerodynamic_resistance)/ &
      (saturation_vapor_pressure_slope + psychrometric_constant*(1.0 + current_surface_resistance/ &
                     aerodynamic_resistance)))*((1000.0*model_timestep)/(latent_heat_vaporization* &
                                                                                     water_density))
        ! mm per model timestep.
        soil_vegetation_et = remaining_et_demand_fraction*soil_vegetation_et
        ! evaporation through soil+plant
        current_total_et = soil_vegetation_et + actual_interception_et
        ! total evaporation (interception+ soil/plant)

        soil_vegetation_et = soil_vegetation_et*1.0

        return
    end

    subroutine calculate_net_radiation
        use simulation_state, only: day, day_of_year, hour
        use meteorological_state, only: monthly_radiation_option, use_radiation_timeseries
        use water_balance_state, only: actual_vapor_pressure, albedo, current_albedo, &
                              current_relative_humidity, current_solar_input, current_temperature, &
                                    day_of_year_real, earth_sun_distance_factor, ground_heat_flux, &
             incoming_shortwave_radiation, latent_heat_vaporization, latitude, longwave_radiation, &
                                max_sunshine_duration, net_radiation, net_shortwave_radiation, pi, &
                               previous_temperature, saturation_vapor_pressure, solar_declination, &
                           stefan_boltzmann_constant, sunset_hour_angle, top_atmosphere_radiation, &
                                       water_density

        implicit none

        !internal variables

        ! latent heat of vaporization (MJ/Kg) - ch4. Handbook of Hydrology
        latent_heat_vaporization = (2.501 - 0.002361*current_temperature)
        ! Temperature is in degrees C.

        ! Saturation Vapor pressure
        saturation_vapor_pressure = 0.6108*exp((17.27*current_temperature)/(237.3 + &
                                                                            current_temperature))
!in KPa  !calculate_evapotranspiration ATUALIZADO

        actual_vapor_pressure = saturation_vapor_pressure*current_relative_humidity/100.0
!in KPa

        ! - ch4. - Handbook of Hydrology
        ! Solar Declination (rad)
        day_of_year_real = day_of_year
        solar_declination = 0.4093*sin((2*pi/365.0)*day_of_year_real - 1.405)

        ! Sunset hour angle (rad)
        sunset_hour_angle = acos(-tand(latitude)*tan(solar_declination))
        !intrinsic function TAND is for degree arguments

        ! maximum insolation (hours)
        max_sunshine_duration = 24*sunset_hour_angle/pi
        ! - ch4. - !

        ! Distance Earth-Sun
        earth_sun_distance_factor = 1.0 + 0.033*cos(2*pi*day_of_year_real/365.0)

        ! Top-of-atmosphere Radiation (mm/day)
        top_atmosphere_radiation = 15.392*earth_sun_distance_factor*(sunset_hour_angle* &
                                           sind(latitude)*sin(solar_declination) + cosd(latitude)* &
                                                                     cos(solar_declination)* &
                                                                     sin(sunset_hour_angle))

        ! Convert to MJ/m2.day
        top_atmosphere_radiation = top_atmosphere_radiation/1000.0
        ! to meters/day
        top_atmosphere_radiation = top_atmosphere_radiation*water_density* &
                                   latent_heat_vaporization
! to MJ/m2.day

        !Calculates incoming radiation to terr. surface
        if (use_radiation_timeseries == 0) then
            !Options for monthly radiation data (flag rad = 0)

            if (monthly_radiation_option == 0) then
                !INMET
          incoming_shortwave_radiation = top_atmosphere_radiation*(0.25 + 0.5*current_solar_input/ &
                                                                         max_sunshine_duration)
                !from insolation (eq. 4.2.6 from Handbook Hydrology)

            elseif (monthly_radiation_option == 1) then
                !CRU
        incoming_shortwave_radiation = top_atmosphere_radiation*(0.25 + 0.5*(current_solar_input)/ &
                                                                         100.)
! Sunshine data in % for CRU data

            elseif (monthly_radiation_option == 2) then
                !WorldClim v2.1
                incoming_shortwave_radiation = current_solar_input
                ! Sunshine data already in radiation (MJ/m².day) for WorldClim data
            end if
        else
            !from incident shortwave on terr surface data
            incoming_shortwave_radiation = current_solar_input
        end if

        ! Discount reflection (albedo)
        net_shortwave_radiation = incoming_shortwave_radiation*(1 - current_albedo)

        ! Long-wave losses
        longwave_radiation = stefan_boltzmann_constant*(current_temperature + 273.2)**4.0
! Temperature is converted to Kelvin
        longwave_radiation = longwave_radiation*(0.34 - 0.14*(actual_vapor_pressure)**0.5)
        ! Emissivity correction

        ! Cloudness
        ! current_solar_input is in terms of solar radiation, then uses Handbook of Hydrology
        ! eq.
        ! Parameters from wetlands to address Amazon basin
        longwave_radiation = longwave_radiation*(1.0*incoming_shortwave_radiation/ &
                                                 top_atmosphere_radiation + 0.0)
        ! Cloudness correction

        ! Ground heat flux !MJ/m2.dia
        ground_heat_flux = 0.38*(current_temperature - previous_temperature)
! eq. 4.2.18 (Handbook of Hydrology)

        ! Net Radiation (Energy Available) (MJ/m2.dia) - discount longwave and groun heatflux
        net_radiation = net_shortwave_radiation - longwave_radiation - ground_heat_flux

        return
    end

end module catchment_hydrology
