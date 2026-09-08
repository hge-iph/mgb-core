! SPDX-License-Identifier: GPL-3.0-or-later
! Copyright (C) 2019 Hidrologia de Grande Escala (HGE)

! Allocate or release the main model state.

SUBROUTINE allocate_model_state(allocation_mode)


	USE model_state
	IMPLICIT NONE

    INTEGER, INTENT(IN) :: allocation_mode
    SAVE

! Select the case how the subroutine is working: for allocation, or for deallocation.

	allocation_action: SELECT CASE (allocation_mode) !Checks for allocation or deallocation. allocation_mode=0 means allocation, and allocation_mode=1 means deallocation.
    CASE (0) ! Allocation
        ALLOCATE (q_river_output(catchment_count),water_surface_elevation_output(catchment_count))
        ALLOCATE (flooded_area_output(catchment_count),total_water_storage_output(catchment_count))
        ALLOCATE (hand_output(catchment_count))
		ALLOCATE (open_water_evaporation_q(catchment_count))
		ALLOCATE (initial_river_q(catchment_count,max_muskingum_reach_count+1))
		ALLOCATE (incoming_q_boundary(catchment_count+1,25),outgoing_q_boundary(catchment_count+1,25))
		ALLOCATE (interception_storage(catchment_count,hru_count))
		ALLOCATE (climate_station_coordinates(climate_cell_count,2))
		ALLOCATE (monthly_air_temperature(climate_cell_count,12),monthly_relative_humidity(climate_cell_count,12),monthly_wind_speed(climate_cell_count,12))
		ALLOCATE (monthly_air_pressure(climate_cell_count,12),monthly_solar_input(climate_cell_count,12))

		ALLOCATE (reference_q(catchment_count))
	 	ALLOCATE (hru_percentage(catchment_count,hru_count))
	 	ALLOCATE (catchment_area(catchment_count),drainage_area(catchment_count),river_length(catchment_count),river_slope(catchment_count))
		ALLOCATE (catchment_x(catchment_count),catchment_y(catchment_count))
        ALLOCATE (climate_region(catchment_count))
		ALLOCATE (catchment_subbasin(catchment_count),longest_reach_slope(catchment_count),longest_reach_length(catchment_count),downstream_catchment(catchment_count),routing_downstream_catchment(catchment_count))
		ALLOCATE (river_width(catchment_count))
		ALLOCATE (subbasin_outlet_catchment(subbasin_count))
		ALLOCATE (subsurface_routing_coefficient(subbasin_count),groundwater_routing_coefficient(subbasin_count),surface_routing_coefficient(subbasin_count))
		ALLOCATE (brooks_corey_lambda(subbasin_count,hru_count),max_capillary_flux(subbasin_count,hru_count),capillary_threshold_fraction(subbasin_count,hru_count))

		ALLOCATE (max_soil_water_storage(subbasin_count,hru_count),arno_b(subbasin_count,hru_count),subsurface_conductivity(subbasin_count,hru_count),groundwater_conductivity(subbasin_count,hru_count),floodplain_infiltration_rate(subbasin_count,hru_count))
		ALLOCATE (muskingum_reach_count(catchment_count))
		ALLOCATE (muskingum_timestep(catchment_count))
		ALLOCATE (wave_celerity(catchment_count),concentration_time(catchment_count))
		ALLOCATE (albedo(hru_count,12,climate_region_count),leaf_area_index(hru_count,12,climate_region_count),vegetation_height(hru_count,12,climate_region_count),surface_resistance(hru_count,12,climate_region_count))
		ALLOCATE (specific_baseflow(subbasin_count))
		ALLOCATE (catchments_per_subbasin(subbasin_count))
		ALLOCATE (substituted_q(substitution_count,timestep_count))

		ALLOCATE (incoming_q_previous(catchment_count+1),outgoing_q_previous(catchment_count),incoming_q_current(catchment_count+1),outgoing_q_current(catchment_count))
		ALLOCATE (catchment_q_previous(catchment_count),catchment_q_current(catchment_count))
		ALLOCATE (incoming_groundwater_fraction_current(catchment_count+1),incoming_subsurface_fraction_current(catchment_count+1),incoming_surface_fraction_current(catchment_count+1),outgoing_groundwater_fraction_current(catchment_count+1),outgoing_subsurface_fraction_current(catchment_count+1),outgoing_surface_fraction_current(catchment_count+1))
		ALLOCATE (groundwater_routing_volume(catchment_count),subsurface_routing_volume(catchment_count),surface_routing_volume(catchment_count))
		ALLOCATE (evapotranspiration(catchment_count,hru_count))
		ALLOCATE (capillary_flux(catchment_count,hru_count))
		ALLOCATE (soil_water_storage(catchment_count,hru_count))
		ALLOCATE (groundwater_q(catchment_count),subsurface_q(catchment_count),surface_q(catchment_count))
		ALLOCATE (groundwater_storage(catchment_count),subsurface_storage(catchment_count),surface_storage(catchment_count))
		ALLOCATE (previous_air_temperature(catchment_count))
		ALLOCATE (precipitation(catchment_count))
		ALLOCATE (air_temperature(catchment_count),relative_humidity(catchment_count),wind_speed(catchment_count),solar_input(catchment_count),air_pressure(catchment_count))

		allocate (catchment_order(catchment_count))


		allocate (substitution_enabled(catchment_count))

		! Variables to calculate indicators of maximum evapotranspiration:
		allocate (potential_open_water_et(catchment_count),potential_top_radiation_et(catchment_count),potential_surface_radiation_et(catchment_count))


        ALLOCATE (incremental_q_output(catchment_count))
	    ALLOCATE (et_output(catchment_count))
        ALLOCATE (interception_et_output(catchment_count))
        ALLOCATE (water_hru_et_output(catchment_count))
        ALLOCATE (soil_vegetation_et_output(catchment_count))
        ALLOCATE (open_water_et_output(catchment_count))
        ALLOCATE (potential_open_water_et_output(catchment_count))
        ALLOCATE (soil_water_output(catchment_count))
        ALLOCATE (interception_storage_output(catchment_count))
        ALLOCATE (capillary_water_output(catchment_count))
        ALLOCATE (groundwater_storage_depth_output(catchment_count))
        ALLOCATE (surface_storage_depth_output(catchment_count))
        ALLOCATE (subsurface_storage_depth_output(catchment_count))
        ALLOCATE (groundwater_runoff_depth_output(catchment_count))
        ALLOCATE (surface_runoff_depth_output(catchment_count))
        ALLOCATE (subsurface_runoff_depth_output(catchment_count))
        allocate (catchment_q_output(catchment_count))
        ALLOCATE (surface_water_output(catchment_count))
        ALLOCATE (groundwater_q_output(catchment_count))
		ALLOCATE (soil_saturation_output(catchment_count))
		ALLOCATE (total_water_storage(catchment_count))
        ALLOCATE (flow_velocity(catchment_count))
        ALLOCATE (hotstart_write_schedule(timestep_count))

		ALLOCATE (manning_n(catchment_count))
        allocate (reservoir_index_by_catchment(catchment_count), reservoir_start_timestep(catchment_count))

    !VINICIUS SIQUEIRA IN 07-11-2016
    !Arrays declarations inside subroutines have been taken to this module

        ALLOCATE (groundwater_delay(catchment_count),subsurface_delay(catchment_count),surface_delay(catchment_count))
        ALLOCATE (incoming_groundwater_fraction_previous(catchment_count+1),incoming_subsurface_fraction_previous(catchment_count+1),incoming_surface_fraction_previous(catchment_count+1))
	    ALLOCATE (outgoing_groundwater_fraction_previous(catchment_count),outgoing_subsurface_fraction_previous(catchment_count),outgoing_surface_fraction_previous(catchment_count))


    CASE (1) ! Deallocation
	    DEALLOCATE (q_river_output)
		DEALLOCATE (open_water_evaporation_q)
		DEALLOCATE (incoming_q_boundary,outgoing_q_boundary)

		DEALLOCATE (climate_station_coordinates)
		DEALLOCATE (monthly_air_temperature,monthly_relative_humidity,monthly_wind_speed)
		DEALLOCATE (monthly_air_pressure,monthly_solar_input)

		DEALLOCATE (reference_q)
	 	DEALLOCATE (hru_percentage)
	 	DEALLOCATE (catchment_area,drainage_area,river_length,river_slope)
		DEALLOCATE (catchment_x,catchment_y)
        DEALLOCATE (climate_region)
		DEALLOCATE (catchment_subbasin,longest_reach_slope,longest_reach_length,downstream_catchment)
		DEALLOCATE (river_width)
		DEALLOCATE (subbasin_outlet_catchment)
		DEALLOCATE (subsurface_routing_coefficient,groundwater_routing_coefficient,surface_routing_coefficient)
		DEALLOCATE (brooks_corey_lambda,max_capillary_flux,capillary_threshold_fraction)
		DEALLOCATE (max_soil_water_storage,arno_b,subsurface_conductivity,groundwater_conductivity,floodplain_infiltration_rate)
		DEALLOCATE (muskingum_reach_count,muskingum_timestep)
		DEALLOCATE (wave_celerity,concentration_time)
		DEALLOCATE (albedo,leaf_area_index,vegetation_height,surface_resistance)
		DEALLOCATE (specific_baseflow)
		DEALLOCATE (catchments_per_subbasin)
		DEALLOCATE (interception_storage)
		DEALLOCATE (incoming_q_previous,outgoing_q_previous,incoming_q_current,outgoing_q_current)
		DEALLOCATE (incoming_groundwater_fraction_current,incoming_subsurface_fraction_current,incoming_surface_fraction_current,outgoing_groundwater_fraction_current,outgoing_subsurface_fraction_current,outgoing_surface_fraction_current)
		DEALLOCATE (groundwater_routing_volume,subsurface_routing_volume,surface_routing_volume)
		DEALLOCATE (evapotranspiration)
		DEALLOCATE (capillary_flux)
		DEALLOCATE (soil_water_storage)
		DEALLOCATE (groundwater_q,subsurface_q,surface_q)
		DEALLOCATE (groundwater_storage,subsurface_storage,surface_storage)
		DEALLOCATE (previous_air_temperature)
		DEALLOCATE (precipitation)
		DEALLOCATE (air_temperature,relative_humidity,wind_speed,solar_input,air_pressure)
		DEALLOCATE (catchment_q_previous,catchment_q_current)
		DEALLOCATE (substituted_q)

		deallocate (catchment_order)

        DEALLOCATE (incremental_q_output)
	    DEALLOCATE (et_output)
        DEALLOCATE (interception_et_output)
        DEALLOCATE (water_hru_et_output)
        DEALLOCATE (soil_vegetation_et_output)
        DEALLOCATE (open_water_et_output)
        DEALLOCATE (potential_open_water_et_output)
        DEALLOCATE (soil_water_output)
        DEALLOCATE (interception_storage_output)
        DEALLOCATE (capillary_water_output)
        DEALLOCATE (surface_storage_depth_output)
        DEALLOCATE (subsurface_storage_depth_output)
        DEALLOCATE (groundwater_storage_depth_output)
        DEALLOCATE (surface_runoff_depth_output)
        DEALLOCATE (subsurface_runoff_depth_output)
        DEALLOCATE (groundwater_runoff_depth_output)
        deallocate (surface_water_output)
        deallocate (catchment_q_output)
	    DEALLOCATE (groundwater_q_output)
		DEALLOCATE (soil_saturation_output)
        deallocate (total_water_storage)
        deallocate (flow_velocity)
		DEALLOCATE (hotstart_write_schedule)
        DEALLOCATE (water_surface_elevation_output)
        DEALLOCATE (flooded_area_output)
        DEALLOCATE (total_water_storage_output)
        DEALLOCATE (hand_output)


		DEALLOCATE (manning_n)

    !VINICIUS SIQUEIRA IN 07-11-2016
    !Arrays declarations inside subroutines have been taken to this module

		DEALLOCATE (groundwater_delay,subsurface_delay,surface_delay)
		DEALLOCATE (incoming_groundwater_fraction_previous,incoming_subsurface_fraction_previous,incoming_surface_fraction_previous)
	    DEALLOCATE (outgoing_groundwater_fraction_previous,outgoing_subsurface_fraction_previous,outgoing_surface_fraction_previous)

	CASE DEFAULT
		STOP ' ERROR: IOP UNKNOWN AT ROUTINE ALLOCA_CALIB!!!'
	END SELECT allocation_action

	! End of the routine.
	END SUBROUTINE allocate_model_state
