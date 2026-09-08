! SPDX-License-Identifier: GPL-3.0-or-later
! Copyright (C) 2019 Hidrologia de Grande Escala (HGE)

! Update catchment water balance, runoff, and diagnostic outputs.

	SUBROUTINE update_catchment_water_balance

	USE model_state
	USE inertial_state
    use utils_time, only: calculate_integer_julian_day

	IMPLICIT NONE

	REAL surface_runoff_depth,subsurface_runoff_depth,groundwater_runoff_depth
    REAL accumulated_surface_q, accumulated_subsurface_q, accumulated_groundwater_q    !Accumulated runoffs for HRUs

	! Gets day of the year (day_of_year) for computing radiation
    day_of_year = calculate_integer_julian_day(year,month,day) - calculate_integer_julian_day(year,1,1) + 1

    ! Initialize variables accumulated across HRUs.
    total_water_storage=0.0
    floodplain_infiltration=0.0

    ! Initializes other variables to accumulate (are used to write output files)
    et_output=0.0
    soil_water_output=0.0
    interception_et_output=0.0
    soil_vegetation_et_output=0.0
    open_water_et_output=0.0
    interception_storage_output=0.0
    capillary_water_output=0.0
    catchment_q_output=0.0
    water_hru_et_output=0.0

	! Catchments loop
	DO catchment_index=1,catchment_count

        !Reset Surface, subsurface and groundwater runoff at each unit-catchment loop
        accumulated_surface_q=0.0
        accumulated_subsurface_q=0.0
        accumulated_groundwater_q=0.0

		if (substitution_enabled(catchment_index)==1) cycle

		subbasin_index=catchment_subbasin(catchment_index)

		IF((subbasin_index<first_subbasin).OR.(subbasin_index>last_subbasin))CYCLE ! Manual controls for specialized calibration

		open_water_evaporation_q(catchment_index)=0.0 !Direct evaporation from open waters

		! HRU loop
		DO hru_index=1,hru_count

			IF(hru_percentage(catchment_index,hru_index).LT.0.0001)THEN
				CYCLE
			ENDIF

            !Temporary variables
 			current_precipitation=precipitation(catchment_index)                         ! Loads rain
			current_soil_water_storage=soil_water_storage(catchment_index,hru_index)			             ! Soil Water storage
			current_interception_storage=interception_storage(catchment_index,hru_index)
			current_max_soil_water_storage=max_soil_water_storage(subbasin_index,hru_index)		             ! Maximum soil water storage
			current_air_pressure=air_pressure(catchment_index)                       ! air pressure
			current_air_temperature=air_temperature(catchment_index)			             ! air temperature
			current_wind_speed=wind_speed(catchment_index)			             ! wind speed
			current_relative_humidity=relative_humidity(catchment_index)			             ! relative humidity
			current_solar_input=solar_input(catchment_index)		             ! solar radiation (or number of hours-insolation)
			current_brooks_corey_lambda=brooks_corey_lambda(subbasin_index,hru_index)		             ! lambda parameter from ARNO model
			previous_temperature=previous_air_temperature(catchment_index)                    ! day before air temperature
			current_temperature=air_temperature(catchment_index)                        ! air temperature
			current_leaf_area_index=leaf_area_index(hru_index,month,climate_region(catchment_index))   ! leaf-area index
			current_albedo=albedo(hru_index,month,climate_region(catchment_index))     ! albedo
			current_vegetation_height=vegetation_height(hru_index,month,climate_region(catchment_index))		 ! vegetation height
			current_surface_resistance=surface_resistance(hru_index,month,climate_region(catchment_index))		 ! surface resistnace
			current_arno_b=arno_b(subbasin_index,hru_index)	                     ! arno_b parameter from ARNO model
			current_subsurface_conductivity=subsurface_conductivity(subbasin_index,hru_index)                  ! Subsurface water flow
			current_groundwater_conductivity=groundwater_conductivity(subbasin_index,hru_index)                  ! Groundwater flow
			current_capillary_flux=max_capillary_flux(subbasin_index,hru_index)	                 ! Capilarity
			! Limit the threshold to avoid exhausting groundwater storage.
			current_capillary_threshold_fraction=capillary_threshold_fraction(subbasin_index,hru_index)
            current_floodplain_infiltration_rate=floodplain_infiltration_rate(subbasin_index,hru_index)                ! Infiltration rate of saturated soil in floodplain

			IF(current_air_temperature.LT.-50.0.OR.current_air_temperature.GT.50.0) STOP 'ERROR AIR TEMP SUB CELULA'
			IF(current_wind_speed.LT.0.0.OR.current_wind_speed.GT.100.)STOP 'ERROR WIND SUB CELULA'
			IF(current_relative_humidity.LT.0.0.OR.current_relative_humidity.GT.100.01)STOP 'ERROR UMIDITY SUB CELULA'

			! Calculates Net Radiation
			latitude_degrees=catchment_y(catchment_index)      !Loads catchment latitude
			CALL calculate_net_radiation   !Returns net_radiation - Net radiation

			! Calculates evapotranspiration and interception (updates current_precipitation)
			CALL calculate_evapotranspiration

            current_catchment_area=catchment_area(catchment_index)
			! Soil water balance
			IF(current_max_soil_water_storage.GT.0.001) THEN
				CALL update_soil_water_balance(current_precipitation,soil_vegetation_et, &
					current_soil_water_storage,current_max_soil_water_storage,current_arno_b, &
					current_subsurface_conductivity,current_groundwater_conductivity, &
					current_brooks_corey_lambda,surface_runoff_depth,subsurface_runoff_depth, &
					groundwater_runoff_depth,current_capillary_flux, &
					current_capillary_threshold_fraction,model_timestep_seconds,catchment_index, &
					current_catchment_area,current_floodplain_infiltration_rate)
				current_total_et=soil_vegetation_et+actual_interception_et
			ELSE
				IF (routing_method(catchment_index)==0) THEN            !if open water (max_soil_water_storage=0.0), surface flow equals interception
					surface_runoff_depth=current_precipitation
					subsurface_runoff_depth=0.0
					groundwater_runoff_depth=0.0
					current_capillary_flux=0.0
					open_water_evaporation_q(catchment_index)=(potential_open_water_et_current*1000.*catchment_area(catchment_index)*(hru_percentage(catchment_index,hru_index)/100.))/model_timestep_seconds !Direct evaporation from open waters in m3/s
               	ELSE
					! Considers evaporation in floodplain water
					surface_runoff_depth=current_precipitation
					subsurface_runoff_depth=0.0
					groundwater_runoff_depth=0.0
					current_capillary_flux=0.0
					open_water_evaporation_q(catchment_index)=potential_open_water_et_current
              	ENDIF
				current_total_et=potential_interception_et
            ENDIF

			evapotranspiration(catchment_index,hru_index)=current_total_et

			soil_water_storage(catchment_index,hru_index)=current_soil_water_storage
			interception_storage(catchment_index,hru_index)=current_interception_storage
			capillary_flux(catchment_index,hru_index)=current_capillary_flux

			hru_area_fraction=hru_percentage(catchment_index,hru_index)/100. 	!HRU area  fraction
			catchment_soil_water_sum=catchment_soil_water_sum+current_soil_water_storage*hru_area_fraction 			!Average Water Soil-Storage in catchment
            minimum_soil_storage=minimum_soil_storage+current_max_soil_water_storage*hru_area_fraction   !Average max_soil_water_storage in the catchment

            !Flow to linear reservoirs
            surface_runoff_depth=((surface_runoff_depth*1000.)*catchment_area(catchment_index)*(hru_percentage(catchment_index,hru_index)/100.))/(model_timestep_seconds)
		    subsurface_runoff_depth=((subsurface_runoff_depth*1000.)*catchment_area(catchment_index)*(hru_percentage(catchment_index,hru_index)/100.))/(model_timestep_seconds)
		    groundwater_runoff_depth=((groundwater_runoff_depth*1000.)*catchment_area(catchment_index)*(hru_percentage(catchment_index,hru_index)/100.))/(model_timestep_seconds)
            !Accumulate generated Runoff (m³/s)
            accumulated_surface_q=accumulated_surface_q + surface_runoff_depth
            accumulated_subsurface_q=accumulated_subsurface_q + subsurface_runoff_depth
            accumulated_groundwater_q=accumulated_groundwater_q + groundwater_runoff_depth

            !Storing evapotranspiration
            et_output(catchment_index)=et_output(catchment_index)+(soil_vegetation_et+actual_interception_et)*(hru_percentage(catchment_index,hru_index)/100.)
            interception_et_output(catchment_index)=interception_et_output(catchment_index)+(actual_interception_et)*(hru_percentage(catchment_index,hru_index)/100.)
            soil_vegetation_et_output(catchment_index)=soil_vegetation_et_output(catchment_index)+(soil_vegetation_et)*(hru_percentage(catchment_index,hru_index)/100.)

            if (routing_method(catchment_index)==1) then
                !Summing infiltration for continuity equation
                 floodplain_infiltration(catchment_index)=floodplain_infiltration(catchment_index)+current_floodplain_infiltration*hru_percentage(catchment_index,hru_index)/100.*catchment_area(catchment_index)/current_flooded_area(catchment_index)  !CEAA infilt
            endif

            !Capillary flux - converts from mm/model_timestep_seconds to m3/s
            catchment_capillary_q=catchment_capillary_q+(hru_percentage(catchment_index,hru_index)/100.)*(current_capillary_flux*1000.*catchment_area(catchment_index))/(model_timestep_seconds)

			!Updates linear reservoir volumes(m3)
			groundwater_storage(catchment_index)=groundwater_storage(catchment_index)+groundwater_runoff_depth*model_timestep_seconds   !groundwater_storage(catchment_index)=groundwater_storage(catchment_index)+groundwater_runoff_depth*3600.*24.
			subsurface_storage(catchment_index)=subsurface_storage(catchment_index)+subsurface_runoff_depth*model_timestep_seconds   !subsurface_storage(catchment_index)=subsurface_storage(catchment_index)+subsurface_runoff_depth*3600.*24.
			surface_storage(catchment_index)=surface_storage(catchment_index)+surface_runoff_depth*model_timestep_seconds   !surface_storage(catchment_index)=surface_storage(catchment_index)+surface_runoff_depth*3600.*24.

            !Updates Terrestrial Water Storage (mm)
            total_water_storage(catchment_index)=total_water_storage(catchment_index)+(interception_storage(catchment_index,hru_index)+soil_water_storage(catchment_index,hru_index))*(hru_percentage(catchment_index,hru_index)/100.0) !VAS - GRACE

            !Storages
            soil_water_output(catchment_index)=soil_water_output(catchment_index)+(soil_water_storage(catchment_index,hru_index))*(hru_percentage(catchment_index,hru_index)/100.0)
            interception_storage_output(catchment_index)=interception_storage_output(catchment_index)+interception_storage(catchment_index,hru_index)*(hru_percentage(catchment_index,hru_index)/100.0)

        ENDDO !end HRU loop

		! Takes water from groundwater reservoir by Capillary flux
        !Check Negative volumes after retrieving water from groundwater reservoir
        if(groundwater_storage(catchment_index)-catchment_capillary_q*model_timestep_seconds<0.0)then
            write(*,*)'Capillarity very high! Vbas went dry. Please check CAP and WC.'
        endif
		groundwater_storage(catchment_index)=MAX(groundwater_storage(catchment_index)-catchment_capillary_q*model_timestep_seconds,0.0) 					      !Update volumes. Fernando & Paulo fixed in 25/01/2013 - limit negative volume in linear reservoir. FMF

		catchment_capillary_q=0.0

        !Calculate soil moisture as saturation degree (soil_water_storage/max_soil_water_storage weighted by HRU) !ASF 2020
        soil_saturation_output(catchment_index)=catchment_soil_water_sum/minimum_soil_storage

		! Calculates catchment discharges
		groundwater_delay(catchment_index)=groundwater_routing_coefficient(subbasin_index)*3600. 	!groundwater_routing_coefficient is defined in hours in parameter file ! convert to seconds
		subsurface_delay(catchment_index)=subsurface_routing_coefficient(subbasin_index)*concentration_time(catchment_index) !subsurface_routing_coefficient is defined in parameter file
		surface_delay(catchment_index)=surface_routing_coefficient(subbasin_index)*concentration_time(catchment_index) !surface_routing_coefficient is defined in parameter file
		groundwater_q(catchment_index)=groundwater_storage(catchment_index)/groundwater_delay(catchment_index)
		subsurface_q(catchment_index)=subsurface_storage(catchment_index)/subsurface_delay(catchment_index)
		surface_q(catchment_index)=surface_storage(catchment_index)/surface_delay(catchment_index)

		! Updates Volumes (m3)
		remaining_groundwater_storage=groundwater_storage(catchment_index)-groundwater_q(catchment_index)*model_timestep_seconds
		remaining_subsurface_storage=subsurface_storage(catchment_index)-subsurface_q(catchment_index)*model_timestep_seconds
		remaining_surface_storage=surface_storage(catchment_index)-surface_q(catchment_index)*model_timestep_seconds

		! Assume that surface reservoir can have negative volumes to address floodplain evaporation
		if (routing_method(catchment_index)==0) then
			IF(remaining_surface_storage.LT.0.0)THEN 		!surface
				surface_q(catchment_index)=surface_storage(catchment_index)/(model_timestep_seconds)
				surface_storage(catchment_index)=0.0
			ELSE
				surface_storage(catchment_index)=remaining_surface_storage
			ENDIF
		else

			IF(surface_storage(catchment_index)<0.0)THEN
				! Negative discharge is instantly taken in next time interval, without phase shift
				surface_q(catchment_index)=surface_storage(catchment_index)/(model_timestep_seconds)
				surface_storage(catchment_index)=0.0
			ELSEIF(remaining_surface_storage<0.0)THEN
				surface_q(catchment_index)=surface_storage(catchment_index)/(model_timestep_seconds)
				surface_storage(catchment_index)=0.0
			ELSE
				surface_storage(catchment_index)=remaining_surface_storage
			ENDIF

		endif

		IF(remaining_subsurface_storage.LT.0.0)THEN !sub-surface
			subsurface_q(catchment_index)=subsurface_storage(catchment_index)/(model_timestep_seconds)
			subsurface_storage(catchment_index)=0.0
		ELSE
			subsurface_storage(catchment_index)=remaining_subsurface_storage
		ENDIF
		IF(remaining_groundwater_storage.LT.0.0)THEN !groundwater
			groundwater_q(catchment_index)=groundwater_storage(catchment_index)/(model_timestep_seconds)
			groundwater_storage(catchment_index)=0.0
		ELSE
			groundwater_storage(catchment_index)=remaining_groundwater_storage
        ENDIF
		!Ends drying linear reservoirs verification

		!clear temporary variables
        catchment_soil_water_sum=0.0
        minimum_soil_storage=0.0

		! Calculates evapotranspiration indicators
		! Evaporation from open water
		potential_open_water_et(catchment_index)=potential_open_water_et_current !mm/model_timestep_seconds
		! Potential ET using all energy at the top of the atmosphere.
		potential_top_radiation_et(catchment_index)=1000.*top_atmosphere_radiation/(water_density*latent_heat_vaporization)
		! Potential ET using shortwave radiation at the terrestrial surface.
		potential_surface_radiation_et(catchment_index)=1000.*incoming_shortwave_radiation/(water_density*latent_heat_vaporization)
        !VAS (30/09/2016)= Precipitation must be corrected (i.e. considering interception) for floodplain vertical balance in flood continuity eq.
        precipitation(catchment_index)=current_precipitation

        !Updating Terrestrial Water Storage with Linear reservoirs (mm)
        total_water_storage(catchment_index)=total_water_storage(catchment_index)+(groundwater_storage(catchment_index)+subsurface_storage(catchment_index)+surface_storage(catchment_index))/(catchment_area(catchment_index)*1000.0) ! VAS - GRACE

        groundwater_storage_depth_output(catchment_index)=(groundwater_storage(catchment_index)/(catchment_area(catchment_index)*1000.0))
        subsurface_storage_depth_output(catchment_index)=(subsurface_storage(catchment_index)/(catchment_area(catchment_index)*1000.0))
        surface_storage_depth_output(catchment_index)=(surface_storage(catchment_index)/(catchment_area(catchment_index)*1000.0))

        !Changed to runoff aggregated
        groundwater_runoff_depth_output(catchment_index)=(accumulated_groundwater_q/(catchment_area(catchment_index)*1000.0))*model_timestep_seconds
        subsurface_runoff_depth_output(catchment_index)=(accumulated_subsurface_q/(catchment_area(catchment_index)*1000.0))*model_timestep_seconds
        surface_runoff_depth_output(catchment_index)=(accumulated_surface_q/(catchment_area(catchment_index)*1000.0))*model_timestep_seconds


	ENDDO !End catchment loop

79	FORMAT(I5,12F6.1)
	RETURN
	END SUBROUTINE update_catchment_water_balance
