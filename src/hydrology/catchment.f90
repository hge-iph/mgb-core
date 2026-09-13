module catchment

    implicit none
    private
    public :: calculate_catchment_time_of_concentration, initialize_runoff, update_runoff

contains

    subroutine initialize_runoff
        use config, only: &
            & catchment_count, &
            & hru_count
        use forcing, only: air_temperature
        use attributes, only: &
            & catchment_area, &
            & catchment_subbasin
        use parameters, only: &
            & time_of_concentration, &
            & groundwater_routing_coefficient, &
            & max_soil_water_storage, &
            & specific_baseflow, &
            & subsurface_routing_coefficient, &
            & surface_routing_coefficient
        use state, only: &
            & groundwater_q, &
            & groundwater_storage, &
            & interception_storage, &
            & soil_water_storage, &
            & subsurface_q, &
            & subsurface_storage, &
            & surface_q, &
            & surface_storage

        implicit none

        ! Symbols:
        ! i_catch  catchment index [1]
        ! i_hru    HRU index [1]
        ! i_sub    subbasin index [1]
        ! tk_bas   groundwater-reservoir delay [s]
        ! tk_int   subsurface-reservoir delay [s]
        ! tk_sup   surface-reservoir delay [s]
        ! v_bas    initial groundwater-reservoir volume [m3]
        integer :: i_catch
        integer :: i_hru
        integer :: i_sub
        integer :: tk_bas
        integer :: tk_int
        integer :: tk_sup
        real, volatile :: v_bas

        interception_storage = 0.0
        do i_catch = 1, catchment_count
            i_sub = catchment_subbasin(i_catch)
            do i_hru = 1, hru_count
                soil_water_storage(i_catch, i_hru) = max_soil_water_storage(i_sub, i_hru)*0.15
            end do
        end do
        do i_catch = 1, catchment_count
            i_sub = catchment_subbasin(i_catch)
            v_bas = specific_baseflow(i_sub)*catchment_area(i_catch)
            v_bas = v_bas*groundwater_routing_coefficient(i_sub)
            groundwater_storage(i_catch) = v_bas*3600.
            subsurface_storage(i_catch) = 0.0
            surface_storage(i_catch) = 0.0
        end do
        do i_catch = 1, catchment_count
            i_sub = catchment_subbasin(i_catch)
            tk_bas = groundwater_routing_coefficient(i_sub)*3600.
            groundwater_q(i_catch) = groundwater_storage(i_catch)/tk_bas
            tk_int = subsurface_routing_coefficient(i_sub)*time_of_concentration(i_catch)
            subsurface_q(i_catch) = subsurface_storage(i_catch)/tk_int
            tk_sup = surface_routing_coefficient(i_sub)*time_of_concentration(i_catch)
            surface_q(i_catch) = surface_storage(i_catch)/tk_sup
        end do
        air_temperature = 20.0
    end subroutine initialize_runoff

    subroutine calculate_catchment_time_of_concentration
        use config, only: catchment_count
        use attributes, only: &
            & longest_reach_length, &
            & longest_reach_slope
        use parameters, only: time_of_concentration

        implicit none
        ! Symbols:
        ! i_catch catchment index [1]
        ! l_reach longest reach length [km]
        ! dh      reach elevation difference [m]
        integer :: i_catch
        real :: l_reach
        real :: dh

        ! Calculates Time of Concentration (i.e. time of travel) for Catchment
        do i_catch = 1, catchment_count
            l_reach = longest_reach_length(i_catch)
            dh = longest_reach_slope(i_catch)*longest_reach_length(i_catch)
            time_of_concentration(i_catch) = 3600.*((0.868*l_reach**3.0)/dh)**0.385
        end do

        return
    end

    subroutine update_runoff
        use date_time, only: calculate_integer_julian_day
        use config, only: &
            & catchment_count, &
            & first_subbasin, &
            & hru_count, &
            & last_subbasin, &
            & model_timestep, &
            & routing_method, &
            & substitution_enabled
        use forcing, only: &
            & air_pressure, &
            & air_temperature, &
            & precipitation, &
            & previous_air_temperature, &
            & relative_humidity, &
            & solar_input, &
            & wind_speed
        use attributes, only: &
            & catchment_area, &
            & catchment_subbasin, &
            & catchment_y, &
            & climate_region, &
            & hru_percentage
        use parameters, only: &
            & albedo, &
            & b_arno, &
            & lambda_brooks_corey, &
            & capillary_threshold_fraction, &
            & time_of_concentration, &
            & floodplain_infiltration_rate, &
            & groundwater_conductivity, &
            & groundwater_routing_coefficient, &
            & leaf_area_index, &
            & max_capillary_flux, &
            & max_soil_water_storage, &
            & subsurface_conductivity, &
            & subsurface_routing_coefficient, &
            & surface_resistance, &
            & surface_routing_coefficient, &
            & vegetation_height
        use state, only: &
            & capillary_flux, &
            & capillary_water_output, &
            & catchment_q_output, &
            & current_flooded_area, &
            & day, &
            & day_of_year, &
            & evapotranspiration, &
            & interception_storage, &
            & open_water_evaporation_q, &
            & potential_open_water_et, &
            & potential_surface_radiation_et, &
            & potential_top_radiation_et, &
            & floodplain_infiltration, &
            & groundwater_q, &
            & groundwater_storage, &
            & soil_water_storage, &
            & subsurface_q, &
            & subsurface_storage, &
            & surface_q, &
            & surface_storage, &
            & total_water_storage, &
            & month, &
            & year, &
            & et_output, &
            & groundwater_runoff_depth_output, &
            & groundwater_storage_depth_output, &
            & interception_et_output, &
            & interception_storage_output, &
            & open_water_et_output, &
            & soil_saturation_output, &
            & soil_vegetation_et_output, &
            & soil_water_output, &
            & subsurface_runoff_depth_output, &
            & subsurface_storage_depth_output, &
            & surface_runoff_depth_output, &
            & surface_storage_depth_output, &
            & water_hru_et_output

        implicit none

        ! Symbols:
        ! i_catch      catchment index [1]
        ! i_hru        HRU index [1]
        ! i_sub        subbasin index [1]
        ! p            precipitation [mm per step]
        ! w            soil-water storage [mm]
        ! wm           maximum soil-water storage [mm]
        ! pa           air pressure [kPa]
        ! ta           air temperature [deg C]
        ! wind         wind speed [m/s]
        ! rh           relative humidity [%]
        ! solar        solar forcing [hours, percent, or MJ/m2/day by option]
        ! t_prev       previous-step air temperature [deg C]
        ! lai          leaf-area index [1]
        ! alb          albedo [1]
        ! z_veg        vegetation height [m]
        ! rs           surface resistance [s/m]
        ! si           interception storage [mm]
        ! lat          catchment latitude [deg]
        ! b            ARNO saturation-curve parameter [1]
        ! k_int        subsurface conductivity [mm/day]
        ! k_bas        groundwater conductivity [mm/day]
        ! lambda       Brooks-Corey pore-size index [1]
        ! cap          capillary flux [mm/day before scaling; mm per step after]
        ! wc           capillary activation fraction [1]
        ! k_inf        saturated floodplain infiltration rate [mm/day]
        ! et_soil      soil evapotranspiration depth [mm per step]
        ! et_int       interception evapotranspiration depth [mm per step]
        ! et_total     total evapotranspiration depth [mm per step]
        ! et_int_pot   potential interception evapotranspiration depth [mm per step]
        ! et_water_pot potential open-water evapotranspiration depth [mm per step]
        ! lambda_e     latent heat [MJ/kg]
        ! r_top        top-of-atmosphere radiation [MJ/m2/day]
        ! r_short      surface shortwave radiation [MJ/m2/day]
        ! d_sup        surface-runoff depth [mm per step]
        ! d_int        subsurface-runoff depth [mm per step]
        ! d_bas        groundwater-runoff depth [mm per step]
        ! d_infil      floodplain-infiltration depth [mm per step]
        ! q_sup        surface-runoff discharge [m3/s]
        ! q_int        subsurface-runoff discharge [m3/s]
        ! q_bas        groundwater-runoff discharge [m3/s]
        ! q_sup_acc    accumulated surface-runoff discharge [m3/s]
        ! q_int_acc    accumulated subsurface-runoff discharge [m3/s]
        ! q_bas_acc    accumulated groundwater-runoff discharge [m3/s]
        ! q_cap_acc    accumulated capillary-flux discharge [m3/s]
        ! hru_percent  HRU percentage [%]
        ! w_mean_acc   weighted soil-water storage [mm]
        ! wm_mean_acc  weighted maximum soil-water storage [mm]
        ! tk_bas       groundwater-reservoir delay [s]
        ! tk_int       subsurface-reservoir delay [s]
        ! tk_sup       surface-reservoir delay [s]
        ! v_bas_next   next groundwater-reservoir volume [m3]
        ! v_int_next   next subsurface-reservoir volume [m3]
        ! v_sup_next   next surface-reservoir volume [m3]
        ! area_catch   catchment area [km2]
        integer :: i_catch
        integer :: i_hru
        integer :: i_sub
        real, volatile :: p
        real, volatile :: w
        real, volatile :: wm
        real, volatile :: pa
        real, volatile :: ta
        real, volatile :: wind
        real, volatile :: rh
        real, volatile :: solar
        real, volatile :: t_prev
        real, volatile :: lai
        real, volatile :: alb
        real, volatile :: z_veg
        real, volatile :: rs
        real, volatile :: si
        real, volatile :: lat
        real, volatile :: b
        real, volatile :: k_int
        real, volatile :: k_bas
        real, volatile :: lambda
        real, volatile :: cap
        real, volatile :: wc
        real, volatile :: k_inf
        real, volatile :: et_soil
        real, volatile :: et_int
        real, volatile :: et_total
        real, volatile :: et_int_pot
        real, volatile :: et_water_pot
        real, volatile :: lambda_e
        real, volatile :: r_top
        real, volatile :: r_short
        real, volatile :: d_sup
        real, volatile :: d_int
        real, volatile :: d_bas
        real, volatile :: d_infil
        real, volatile :: q_sup
        real, volatile :: q_int
        real, volatile :: q_bas
        real, volatile :: q_sup_acc
        real, volatile :: q_int_acc
        real, volatile :: q_bas_acc
        real, volatile :: q_cap_acc
        real, volatile :: hru_percent
        real, volatile :: w_mean_acc
        real, volatile :: wm_mean_acc
        real, volatile :: tk_bas
        real, volatile :: tk_int
        real, volatile :: tk_sup
        real, volatile :: v_bas_next
        real, volatile :: v_int_next
        real, volatile :: v_sup_next
        real, volatile :: area_catch
        real, volatile :: linear_storage_total
        real, volatile :: d_infil_catch
        real, parameter :: rho_w = 1000.0

        ! Gets day of the year (day_of_year) for computing radiation
        day_of_year = calculate_integer_julian_day(year, month, day) - calculate_integer_julian_day(year, 1, 1) + 1

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
        do i_catch = 1, catchment_count

            !Reset Surface, subsurface and groundwater runoff at each unit-catchment loop
            q_sup_acc = 0.0
            q_int_acc = 0.0
            q_bas_acc = 0.0

            if (substitution_enabled(i_catch) == 1) cycle

            i_sub = catchment_subbasin(i_catch)
            
            ! Manual controls for specialized calibration
            if ((i_sub < first_subbasin) .or. (i_sub > last_subbasin)) cycle
            
            area_catch = catchment_area(i_catch)

            w_mean_acc = 0.0
            wm_mean_acc = 0.0
            q_cap_acc = 0.0

            open_water_evaporation_q(i_catch) = 0.0
            !Direct evaporation from open waters

            ! HRU loop
            do i_hru = 1, hru_count

                if (hru_percentage(i_catch, i_hru) .lt. 0.0001) then
                    cycle
                end if

                hru_percent = hru_percentage(i_catch, i_hru)

                !Temporary variables
                p = precipitation(i_catch)
                w = soil_water_storage(i_catch, i_hru)
                si = interception_storage(i_catch, i_hru)
                wm = max_soil_water_storage(i_sub, i_hru)
                lat = catchment_y(i_catch)
                pa = air_pressure(i_catch)
                ta = air_temperature(i_catch)
                wind = wind_speed(i_catch)
                rh = relative_humidity(i_catch)
                solar = solar_input(i_catch)
                lambda = lambda_brooks_corey(i_sub, i_hru)
                t_prev = previous_air_temperature(i_catch)
                lai = leaf_area_index(i_hru, month, climate_region(i_catch))
                alb = albedo(i_hru, month, climate_region(i_catch))
                z_veg = vegetation_height(i_hru, month, climate_region(i_catch))
                rs = surface_resistance(i_hru, month, climate_region(i_catch))
                b = b_arno(i_sub, i_hru)
                k_int = subsurface_conductivity(i_sub, i_hru)
                k_bas = groundwater_conductivity(i_sub, i_hru)
                cap = max_capillary_flux(i_sub, i_hru)
                wc = capillary_threshold_fraction(i_sub, i_hru)
                k_inf = floodplain_infiltration_rate(i_sub, i_hru)
                d_infil = 0.0

                if (ta .lt. -50.0 .or. ta .gt. 50.0) stop 'ERROR AIR TEMP SUB CELULA'
                if (wind .lt. 0.0 .or. wind .gt. 100.) stop 'ERROR WIND SUB CELULA'
                if (rh .lt. 0.0 .or. rh .gt. 100.01) stop 'ERROR UMIDITY SUB CELULA'

                ! Calculates radiation, evapotranspiration, and interception (updates p)
                call calculate_evapotranspiration( &
                    & p, &
                    & w, &
                    & wm, &
                    & pa, &
                    & ta, &
                    & wind, &
                    & rh, &
                    & solar, &
                    & t_prev, &
                    & lai, &
                    & alb, &
                    & z_veg, &
                    & rs, &
                    & si, &
                    & lat, &
                    & et_soil, &
                    & et_int, &
                    & et_total, &
                    & et_int_pot, &
                    & et_water_pot, &
                    & lambda_e, &
                    & r_top, &
                    & r_short)

                ! Soil water balance
                if (wm .gt. 0.001) then
                    call update_soil_water_balance( &
                        & p, &
                        & et_soil, &
                        & w, &
                        & wm, &
                        & b, &
                        & k_int, &
                        & k_bas, &
                        & lambda, &
                        & d_sup, &
                        & d_int, &
                        & d_bas, &
                        & cap, &
                        & wc, &
                        & d_infil, &
                        & model_timestep, &
                        & i_catch, &
                        & area_catch, &
                        & k_inf)
                    et_total = et_soil + et_int
                else
                    if (routing_method(i_catch) == 0) then
                        ! if open water (max_soil_water_storage=0.0), surface flow equals
                        ! interception
                        d_sup = p
                        d_int = 0.0
                        d_bas = 0.0
                        cap = 0.0
                        open_water_evaporation_q(i_catch) = (et_water_pot*1000.*area_catch*(hru_percent/100.))/model_timestep
                        !Direct evaporation from open waters in m3/s
                    else
                        ! Considers evaporation in floodplain water
                        d_sup = p
                        d_int = 0.0
                        d_bas = 0.0
                        cap = 0.0
                        open_water_evaporation_q(i_catch) = et_water_pot
                    end if
                    et_total = et_int_pot
                end if

                evapotranspiration(i_catch, i_hru) = et_total

                soil_water_storage(i_catch, i_hru) = w
                interception_storage(i_catch, i_hru) = si
                capillary_flux(i_catch, i_hru) = cap

                !HRU area  fraction
                w_mean_acc = w_mean_acc + w*(hru_percent/100.)
                !Average Water Soil-Storage in catchment
                wm_mean_acc = wm_mean_acc + wm*(hru_percent/100.)
                !Average max_soil_water_storage in the catchment

                !Flow to linear reservoirs
                q_sup = ((d_sup*1000.)*area_catch*(hru_percent/100.))/(model_timestep)
                q_int = ((d_int*1000.)*area_catch*(hru_percent/100.))/(model_timestep)
                q_bas = ((d_bas*1000.)*area_catch*(hru_percent/100.))/(model_timestep)

                !Accumulate generated Runoff (m³/s)
                q_sup_acc = q_sup_acc + q_sup
                q_int_acc = q_int_acc + q_int
                q_bas_acc = q_bas_acc + q_bas

                !Storing evapotranspiration
                et_output(i_catch) = et_output(i_catch) + (et_soil + et_int)*(hru_percent/100.)
                interception_et_output(i_catch) = interception_et_output(i_catch) + et_int*(hru_percent/100.)
                soil_vegetation_et_output(i_catch) = soil_vegetation_et_output(i_catch) + et_soil*(hru_percent/100.)

                if (routing_method(i_catch) == 1) then
                    !Summing infiltration for continuity equation
                    d_infil_catch = d_infil*hru_percent/100.*area_catch/current_flooded_area(i_catch)
                    floodplain_infiltration(i_catch) = floodplain_infiltration(i_catch) + d_infil_catch
                    !CEAA infilt
                end if

                ! Capillary flux converts from mm per model timestep to m3/s.
                q_cap_acc = q_cap_acc + (hru_percent/100.)*(cap*1000.*area_catch)/(model_timestep)

                ! Updates linear reservoir volumes(m3)
                groundwater_storage(i_catch) = groundwater_storage(i_catch) + q_bas*model_timestep
                subsurface_storage(i_catch) = subsurface_storage(i_catch) + q_int*model_timestep
                surface_storage(i_catch) = surface_storage(i_catch) + q_sup*model_timestep

                ! Updates Terrestrial Water Storage (mm)
                total_water_storage(i_catch) = total_water_storage(i_catch) + (si + w)*(hru_percent/100.0)
                ! VAS - GRACE

                ! Storages
                soil_water_output(i_catch) = soil_water_output(i_catch) + w*(hru_percent/100.0)
                interception_storage_output(i_catch) = interception_storage_output(i_catch) + si*(hru_percent/100.0)

            end do
            ! end HRU loop

            ! Takes water from groundwater reservoir by Capillary flux
            ! Check Negative volumes after retrieving water from groundwater reservoir
            if (groundwater_storage(i_catch) - q_cap_acc*model_timestep < 0.0) then
                write (*, *) 'Capillarity very high! Vbas went dry. Please check CAP and WC.'
            end if
            groundwater_storage(i_catch) = max(groundwater_storage(i_catch) - q_cap_acc*model_timestep, 0.0)
            ! Update volumes. Fernando & Paulo fixed in 25/01/2013 - limit negative volume in
            ! linear reservoir. FMF

            ! Calculate soil moisture as saturation degree
            ! (soil_water_storage/max_soil_water_storage weighted by HRU) !ASF 2020
            soil_saturation_output(i_catch) = w_mean_acc/wm_mean_acc

            ! Calculates catchment discharges
            tk_bas = groundwater_routing_coefficient(i_sub)*3600.
            ! groundwater_routing_coefficient is defined in hours in parameter file ! convert to
            ! seconds
            tk_int = subsurface_routing_coefficient(i_sub)*time_of_concentration(i_catch)
            ! subsurface_routing_coefficient is defined in parameter file
            tk_sup = surface_routing_coefficient(i_sub)*time_of_concentration(i_catch)
            ! surface_routing_coefficient is defined in parameter file
            groundwater_q(i_catch) = groundwater_storage(i_catch)/tk_bas
            subsurface_q(i_catch) = subsurface_storage(i_catch)/tk_int
            surface_q(i_catch) = surface_storage(i_catch)/tk_sup

            ! Updates Volumes (m3)
            v_bas_next = groundwater_storage(i_catch) - groundwater_q(i_catch)*model_timestep
            v_int_next = subsurface_storage(i_catch) - subsurface_q(i_catch)*model_timestep
            v_sup_next = surface_storage(i_catch) - surface_q(i_catch)*model_timestep

            ! Assume that surface reservoir can have negative volumes to address floodplain
            ! evaporation
            if (routing_method(i_catch) == 0) then
                if (v_sup_next .lt. 0.0) then
                    !surface
                    surface_q(i_catch) = surface_storage(i_catch)/(model_timestep)
                    surface_storage(i_catch) = 0.0
                else
                    surface_storage(i_catch) = v_sup_next
                end if
            else

                if (surface_storage(i_catch) < 0.0) then
                    ! Negative discharge is instantly taken in next time interval, without phase shift
                    surface_q(i_catch) = surface_storage(i_catch)/(model_timestep)
                    surface_storage(i_catch) = 0.0
                elseif (v_sup_next < 0.0) then
                    surface_q(i_catch) = surface_storage(i_catch)/(model_timestep)
                    surface_storage(i_catch) = 0.0
                else
                    surface_storage(i_catch) = v_sup_next
                end if

            end if

            if (v_int_next .lt. 0.0) then
                !sub-surface
                subsurface_q(i_catch) = subsurface_storage(i_catch)/(model_timestep)
                subsurface_storage(i_catch) = 0.0
            else
                subsurface_storage(i_catch) = v_int_next
            end if
            if (v_bas_next .lt. 0.0) then
                !groundwater
                groundwater_q(i_catch) = groundwater_storage(i_catch)/(model_timestep)
                groundwater_storage(i_catch) = 0.0
            else
                groundwater_storage(i_catch) = v_bas_next
            end if
            !Ends drying linear reservoirs verification

            ! Calculates evapotranspiration indicators
            ! Evaporation from open water
            potential_open_water_et(i_catch) = et_water_pot
            ! mm per model timestep.
            ! Potential ET using all energy at the top of the atmosphere.
            potential_top_radiation_et(i_catch) = 1000.*r_top/(rho_w*lambda_e)
            ! Potential ET using shortwave radiation at the terrestrial surface.
            potential_surface_radiation_et(i_catch) = 1000.*r_short/(rho_w*lambda_e)
            ! VAS (30/09/2016)= Precipitation must be corrected (i.e. considering interception)
            ! for floodplain vertical balance in flood continuity eq.
            precipitation(i_catch) = p

            !Updating Terrestrial Water Storage with Linear reservoirs (mm)
            linear_storage_total = groundwater_storage(i_catch) + subsurface_storage(i_catch) + surface_storage(i_catch)
            total_water_storage(i_catch) = total_water_storage(i_catch) + linear_storage_total/(area_catch*1000.0)
            ! VAS - GRACE

            groundwater_storage_depth_output(i_catch) = groundwater_storage(i_catch)/(area_catch*1000.0)
            subsurface_storage_depth_output(i_catch) = subsurface_storage(i_catch)/(area_catch*1000.0)
            surface_storage_depth_output(i_catch) = surface_storage(i_catch)/(area_catch*1000.0)

            !Changed to runoff aggregated
            groundwater_runoff_depth_output(i_catch) = (q_bas_acc/(area_catch*1000.0))*model_timestep
            subsurface_runoff_depth_output(i_catch) = (q_int_acc/(area_catch*1000.0))*model_timestep
            surface_runoff_depth_output(i_catch) = (q_sup_acc/(area_catch*1000.0))*model_timestep

        end do
        !End catchment loop

79      format(i5, 12f6.1)
        return
    end subroutine update_runoff

    subroutine calculate_evapotranspiration( &
        & p, &
        & w, &
        & wm, &
        & pa, &
        & ta, &
        & wind, &
        & rh, &
        & solar, &
        & t_prev, &
        & lai, &
        & alb, &
        & z_veg, &
        & rs, &
        & si, &
        & lat, &
        & et_soil, &
        & et_int, &
        & et_total, &
        & et_int_pot, &
        & et_water_pot, &
        & lambda_e, &
        & r_top, &
        & r_short)
        use config, only: model_timestep

        implicit none

        ! Symbols:
        ! p            precipitation [mm per step]
        ! w            soil-water storage [mm]
        ! wm           maximum soil-water storage [mm]
        ! pa           air pressure [kPa]
        ! ta           air temperature [deg C]
        ! wind         wind speed [m/s]
        ! rh           relative humidity [%]
        ! solar        solar forcing [hours, percent, or MJ/m2/day by option]
        ! t_prev       previous-step air temperature [deg C]
        ! lai          leaf-area index [1]
        ! alb          albedo [1]
        ! z_veg        vegetation height [m]
        ! rs           surface resistance [s/m]
        ! si           interception storage [mm]
        ! lat          catchment latitude [deg]
        ! et_soil      soil evapotranspiration depth [mm per step]
        ! et_int       interception evapotranspiration depth [mm per step]
        ! et_total     total evapotranspiration depth [mm per step]
        ! et_int_pot   potential interception evapotranspiration depth [mm per step]
        ! et_water_pot potential open-water evapotranspiration depth [mm per step]
        ! lambda_e     latent heat [MJ/kg]
        ! r_top        top-of-atmosphere radiation [MJ/m2/day]
        ! r_short      surface shortwave radiation [MJ/m2/day]
        ! rho_w        water density [kg/m3]
        ! c_p          specific heat of air [MJ/(kg deg C)]
        ! r_net        net radiation flux [MJ/(m2 s)]
        ! e_a          actual vapor pressure [kPa]
        ! e_s          saturation vapor pressure [kPa]
        ! e_d          vapor-pressure deficit [kPa]
        ! s_e          slope of the saturation-vapor-pressure curve [kPa/deg C]
        ! gamma        psychrometric constant [kPa/deg C]
        ! rho_a        air density [kg/m3]
        ! z0           vegetation roughness length [m]
        ! z            capped vegetation height [m]
        ! u10          wind speed at 10 m [m/s]
        ! u2           wind speed at 2 m [m/s]
        ! r_a          aerodynamic resistance for vegetation [s/m]
        ! r_aw         aerodynamic resistance for open water [s/m]
        ! w_u          upper soil-water threshold [mm]
        ! w_w          wilting soil-water threshold [mm]
        ! f_rs         soil-moisture resistance factor [1]
        ! si_a         available interception storage [mm]
        ! si_m         maximum interception storage [mm]
        ! f_et         remaining potential-evapotranspiration fraction [1]
        real, intent(inout) :: p
        real, intent(inout) :: si
        real, intent(inout) :: rs
        real, intent(in) :: w
        real, intent(in) :: wm
        real, intent(in) :: pa
        real, intent(in) :: ta
        real, intent(in) :: wind
        real, intent(in) :: rh
        real, intent(in) :: solar
        real, intent(in) :: t_prev
        real, intent(in) :: lai
        real, intent(in) :: alb
        real, intent(in) :: z_veg
        real, intent(in) :: lat
        real, intent(out) :: et_soil
        real, intent(out) :: et_int
        real, intent(out) :: et_total
        real, intent(out) :: et_int_pot
        real, intent(out) :: et_water_pot
        real, intent(out) :: lambda_e
        real, intent(out) :: r_top
        real, intent(out) :: r_short
        real, parameter :: rho_w = 1000.0
        real, parameter :: c_p = 0.001013
        real, volatile :: r_net
        real, volatile :: e_a
        real, volatile :: e_s
        real, volatile :: e_d
        real, volatile :: s_e
        real, volatile :: gamma
        real, volatile :: rho_a
        real, volatile :: z0
        real, volatile :: z
        real, volatile :: u10
        real, volatile :: u2
        real, volatile :: r_a
        real, volatile :: r_aw
        real, volatile :: w_u
        real, volatile :: w_w
        real, save :: f_rs = 0.0
        real, volatile :: si_a
        real, volatile :: si_m
        real, volatile :: f_et

        call calculate_net_radiation( &
            & solar, &
            & ta, &
            & t_prev, &
            & rh, &
            & alb, &
            & lat, &
            & lambda_e, &
            & r_net, &
            & r_top, &
            & r_short, &
            & e_a, &
            & e_s)

        e_d = e_s - e_a
        gamma = 0.0016286*pa/lambda_e
        s_e = (4098.0*e_s)/((237.3 + ta)**2.)
        rho_a = 3.486*(pa/(275.0 + ta))
        r_net = r_net/(3600.0*24.0)
        z0 = 0.1*z_veg
        u10 = wind + 0.1
        u2 = u10/((log(10.0/z0))/log(2.0/z0))
        z = min(z_veg, 12.5)
        r_a = ((log((10.-z*0.67)/(z*0.123)))*(log((10.-z*0.67)/(z*0.0123))))/(0.41*0.41*u10)
        r_aw = (4.72*(log(2./0.00137))**2.)/(1.+0.536*u2)
        w_u = 0.8*wm
        w_w = 0.1*wm

        if (wm < 0.1) then
            rs = 0.0
        else
            if (w .le. w_w) then
                rs = 999999999.0
            elseif (w .lt. w_u) then
                f_rs = (w - w_w)/(w_u - w_w)
                f_rs = 1./f_rs
            else
                f_rs = 1.0
            end if
            rs = f_rs*rs
        end if

        si_m = 0.4*lai*(model_timestep/86400.)
        si_a = min(si + p, si_m)
        p = p - (si_a - si)
        et_int_pot = ((s_e*r_net + rho_a*c_p*e_d/r_a)/(s_e + gamma*(1.0 + 0.0/r_a)))*((1000.0*model_timestep)/(lambda_e*rho_w))
        et_water_pot = ((s_e*r_net + rho_a*c_p*e_d/r_aw)/(s_e + gamma*(1.0 + 0.0/r_aw)))*((1000.0*model_timestep)/(lambda_e*rho_w))
        et_int = min(et_int_pot, si_a)
        si = si_a - et_int
        f_et = (et_int_pot - et_int)/et_int_pot
        et_soil = ((s_e*r_net + rho_a*c_p*e_d/r_a)/(s_e + gamma*(1.0 + rs/r_a)))*((1000.0*model_timestep)/(lambda_e*rho_w))
        et_soil = f_et*et_soil
        et_total = et_soil + et_int
        et_soil = et_soil*1.0

    end subroutine calculate_evapotranspiration

    subroutine calculate_net_radiation( &
        & solar, &
        & ta, &
        & t_prev, &
        & rh, &
        & alb, &
        & lat, &
        & lambda_e, &
        & r_net, &
        & r_top, &
        & r_short, &
        & e_a, &
        & e_s)

        use config, only: &
            & monthly_radiation_option, &
            & use_radiation_timeseries
        use state, only: day_of_year

        implicit none

        ! Symbols:
        ! solar    solar forcing [hours, percent, or MJ/m2/day by option]
        ! ta       air temperature [deg C]
        ! t_prev   previous-step air temperature [deg C]
        ! rh       relative humidity [%]
        ! alb      albedo [1]
        ! lat      catchment latitude [deg]
        ! lambda_e latent heat [MJ/kg]
        ! r_net    net radiation [MJ/m2/day]
        ! r_top    top-of-atmosphere radiation [MJ/m2/day]
        ! r_short  surface shortwave radiation [MJ/m2/day]
        ! e_a      actual vapor pressure [kPa]
        ! e_s      saturation vapor pressure [kPa]
        ! pi       circle constant [1]
        ! rho_w    water density [kg/m3]
        ! sigma    Stefan-Boltzmann constant [MJ/(m2 day K4)]
        ! d        day of year [day]
        ! delta    solar declination [rad]
        ! omega    sunset hour angle [rad]
        ! n_sun    maximum sunshine duration [hours]
        ! d_r      relative Earth-Sun distance [1]
        ! r_sn     net shortwave radiation [MJ/m2/day]
        ! r_l      net longwave radiation [MJ/m2/day]
        ! g        ground heat flux [MJ/m2/day]
        real, intent(in) :: solar
        real, intent(in) :: ta
        real, intent(in) :: t_prev
        real, intent(in) :: rh
        real, intent(in) :: alb
        real, intent(in) :: lat
        real, intent(out) :: lambda_e
        real, intent(out) :: r_net
        real, intent(out) :: r_top
        real, intent(out) :: r_short
        real, intent(out) :: e_a
        real, intent(out) :: e_s
        real, parameter :: pi = 3.141592
        real, parameter :: rho_w = 1000.0
        real, parameter :: sigma = 4.903e-9
        real, volatile :: d
        real, volatile :: delta
        real, volatile :: omega
        real, volatile :: n_sun
        real, volatile :: d_r
        real, volatile :: r_sn
        real, volatile :: r_l
        real, volatile :: g

        lambda_e = 2.501 - 0.002361*ta
        e_s = 0.6108*exp((17.27*ta)/(237.3 + ta))
        e_a = e_s*rh/100.0
        d = day_of_year
        delta = 0.4093*sin((2*pi/365.0)*d - 1.405)
        omega = acos(-tand(lat)*tan(delta))
        n_sun = 24*omega/pi
        d_r = 1.0 + 0.033*cos(2*pi*d/365.0)
        r_top = 15.392*d_r*(omega*sind(lat)*sin(delta) + cosd(lat)*cos(delta)*sin(omega))
        r_top = r_top/1000.0
        r_top = r_top*rho_w*lambda_e

        if (use_radiation_timeseries == 0) then
            if (monthly_radiation_option == 0) then
                r_short = r_top*(0.25 + 0.5*solar/n_sun)
            elseif (monthly_radiation_option == 1) then
                r_short = r_top*(0.25 + 0.5*solar/100.)
            elseif (monthly_radiation_option == 2) then
                r_short = solar
            end if
        else
            r_short = solar
        end if

        r_sn = r_short*(1 - alb)
        r_l = sigma*(ta + 273.2)**4.0
        r_l = r_l*(0.34 - 0.14*(e_a)**0.5)
        r_l = r_l*(1.0*r_short/r_top + 0.0)
        g = 0.38*(ta - t_prev)
        r_net = r_sn - r_l - g

    end subroutine calculate_net_radiation

    subroutine update_soil_water_balance( &
        & p, &
        & et_soil, &
        & w, &
        & wm, &
        & b, &
        & k_int, &
        & k_bas, &
        & lambda, &
        & d_sup, &
        & d_int, &
        & d_bas, &
        & cap, &
        & wc, &
        & d_infil, &
        & dt, &
        & i_catch, &
        & area_catch, &
        & k_inf)
        
        use config, only: routing_method
        use state, only: current_flooded_area

        implicit none

        ! Symbols:
        ! p          precipitation [mm per step]
        ! et_soil    soil evapotranspiration depth [mm per step]
        ! w          soil-water storage [mm]
        ! wm         maximum soil-water storage [mm]
        ! b          ARNO saturation-curve parameter [1]
        ! k_int      subsurface conductivity [mm/day]
        ! k_bas      groundwater conductivity [mm/day]
        ! lambda     Brooks-Corey pore-size index [1]
        ! d_sup      surface-runoff depth [mm per step]
        ! d_int      subsurface drainage rate, then depth [mm/day before scaling; mm per step after]
        ! d_bas      groundwater drainage rate, then depth [mm/day before scaling; mm per step after]
        ! cap        capillary flux rate, then depth [mm/day before scaling; mm per step after]
        ! wc         capillary activation fraction [1]
        ! d_infil    floodplain infiltration rate, then depth [mm/day before scaling; mm per step after]
        ! dt         model timestep [s]
        ! i_catch    catchment index [1]
        ! area_catch catchment area [km2]
        ! k_inf      saturated floodplain infiltration rate [mm/day]
        ! w_int      subsurface-flow soil-water threshold [mm]
        ! w_bas      groundwater-flow soil-water threshold [mm]
        ! w_cap      capillary-flux soil-water threshold [mm]
        ! shape      ARNO saturation-curve remainder [1]
        ! w_prev     soil-water storage at iteration start [mm]
        ! p_eff      effective precipitation [mm per step]
        real, intent(in) :: p
        real, intent(in) :: wm
        real, intent(in) :: b
        real, intent(in) :: k_int
        real, intent(in) :: k_bas
        real, intent(in) :: lambda
        real, intent(in) :: dt
        real, intent(in) :: area_catch
        real, intent(inout) :: w
        real, intent(inout) :: et_soil
        real, intent(inout) :: cap
        real, intent(inout) :: wc
        real, intent(inout) :: k_inf
        real, intent(out) :: d_sup
        real, intent(out) :: d_int
        real, intent(out) :: d_bas
        real, intent(out) :: d_infil
        integer, intent(in) :: i_catch
        real, volatile :: w_int
        real, volatile :: w_bas
        real, volatile :: w_cap
        real, volatile :: shape
        real, volatile :: w_prev
        real, volatile :: p_eff

        ! The Brooks-Corey pore-size index controls subsurface drainage; typical
        ! values range from 0.165 for clay to 0.694 for sand (Rawls).

        !limiters
        if (wc > 0.1) wc = 0.1
        !High values of w_cap can lead groundwater_storage getting dry

        w_bas = wc*wm

        ! Use the groundwater-generation threshold for subsurface flow as well.
        w_int = w_bas

        w_cap = wc*wm
        ! w_cap is the limit to start ascending Capillary flux

        ! Calculates direct flow (surface waters)
        if (p .gt. 0.0) then

            shape = (1.-w/wm)**(1./(b + 1.)) - p/((b + 1.)*wm)

            if (shape .le. 0.0) then
                ! Rainfall saturates soil

                d_sup = max(p - (wm - w), 0.0)
                !Fernando & Paulo Correction 25/01/2013)

            else
                ! Rainfall does not saturates soil

                d_sup = max(p - (wm - w) + wm*(shape)**(b + 1.), 0.0)
                !Fernando & Paulo Correction 25/01/2013)

            end if

        else

            d_sup = 0.0
            ! If precipitation is zero, there is no surface flow.

        end if

        ! Calculates groundwater (slow flows)
        if (w .ge. w_bas) then
            d_bas = k_bas*(w - w_bas)/(wm - w_bas)
            !simple linear approach
        else
            d_bas = 0.0
        end if

        ! Calculate upward capillary flux.
        cap = max(cap*(w_cap - w)/w_cap, 0.0)
        ! Bremicker.

        ! Calculates subsurface flow (intermediate)
        ! uses Brooks & Corey relation (5.6 from Handbook of Hydrology)
        if (w .le. w_int) then
            d_int = 0.0
            ! No drainage in low moisture condition
        else
            d_int = k_int*((w - w_int)/(wm - w_int))**(3.+2./lambda)
        end if

        ! Limits drainage to avoid negative storage
        d_int = min(d_int, w/10.0)
        ! this assumptions are ok cause
        d_int = max(d_int, 0.0)
        ! hydr. conductivy can drop fast

        ! Updates in-soil stored water for calibration
        w_prev = w
        p_eff = p

        !Calculates infiltration from floodplain (Inertial module only)
        if (routing_method(i_catch) == 0) then
            d_infil = 0.0
            !Inertial module is disabled
        else
            ! Limit floodplain infiltration to the subsurface rate or 20 mm/day.
            k_inf = min(k_int, 20.0)
            !Infilttration rate when Inertial module is enabled !in mm/day
            d_infil = (current_flooded_area(i_catch)/area_catch)*k_inf*(1 - w/wm)**1

            !Correcting fluxes due to flooded area
            d_sup = d_sup*max(area_catch - current_flooded_area(i_catch), 0.0)/area_catch
            p_eff = p_eff*max(area_catch - current_flooded_area(i_catch), 0.0)/area_catch
            et_soil = et_soil*max(area_catch - current_flooded_area(i_catch), 0.0)/area_catch

        end if
        d_infil = max(d_infil, 0.0)

        ! Convert to time-step when necessary (smaller than daily)
        cap = cap*dt/86400.
        d_int = d_int*dt/86400.
        d_bas = d_bas*dt/86400.
        d_infil = d_infil*dt/86400.

        ! Starts vertical balance loop
        !  ends only if calculated storage is not negative
        do

            w = w + p_eff + (d_infil + cap - et_soil - d_sup - d_int - d_bas)
            !updates water balance with corrected variables according to flooded area

            ! New adjustment (Paiva)
            ! Considers adjusting evapotranspiration and drainage
            if (w < wm + 0.01 .and. w > wm) w = wm
            if (w > -0.01 .and. w < 0.0) w = 0.0
            if (w > wm) then
                d_sup = d_sup + w - wm
                w = w_prev

            elseif (w < 0.0) then

                et_soil = et_soil - (-w)
                if (et_soil >= 0.0) then
                    w = w_prev
                    cycle
                end if
                w = et_soil
                !accept storage as the residual
                et_soil = 0.0
                !then zero evaporation

                ! reduces percolation
                d_bas = d_bas - (-w)
                if (d_bas >= 0.0) then
                    w = w_prev
                    cycle
                end if
                ! percolation is zero but water balance is not closed
                w = d_bas
                !accept storage as the residual
                d_bas = 0.0
                !zero groundwater flux

                ! reduces subsurface
                d_int = d_int - (-w)
                if (d_int >= 0.0) then
                    w = w_prev
                    cycle
                end if
                ! subsurface is zero but water balance is not closed
                w = d_int
                !accept storage as the residual
                d_int = 0.0

                ! reduces surface water
                d_sup = d_sup - (-w)
                if (d_sup >= 0.0) then
                    w = w_prev
                    cycle
                end if
                d_sup = 0.0

                ! surface water is zero but water balance didnt close
                ! nothing to do anymore.
                write (*, *) 'Soil went dry'
                w = 0.001
                exit
            else
                exit
            end if

        end do

        return
    end subroutine update_soil_water_balance

end module catchment
