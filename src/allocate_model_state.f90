! SPDX-License-Identifier: GPL-3.0-or-later
! Copyright (C) 2019 Hidrologia de Grande Escala (HGE)

! Allocate or release the main model state.

subroutine allocate_model_state(allocation_mode)

    use model_state
    implicit none

    integer, intent(in) :: allocation_mode
    save

! Select the case how the subroutine is working: for allocation, or for deallocation.

    allocation_action:select case(allocation_mode)
    ! Checks for allocation or deallocation. allocation_mode=0 means allocation, and
    ! allocation_mode=1 means deallocation.
    case (0)
    ! Allocation
    allocate (q_river_output(catchment_count), water_surface_elevation_output(catchment_count))
    allocate (flooded_area_output(catchment_count), total_water_storage_output(catchment_count))
    allocate (hand_output(catchment_count))
    allocate (open_water_evaporation_q(catchment_count))
    allocate (initial_river_q(catchment_count, max_muskingum_reach_count + 1))
    allocate (incoming_q_boundary(catchment_count+1,25),outgoing_q_boundary(catchment_count+1,25))
    allocate (interception_storage(catchment_count, hru_count))
    allocate (climate_station_coordinates(climate_cell_count, 2))
    allocate (monthly_air_temperature(climate_cell_count, 12), &
              monthly_relative_humidity(climate_cell_count, 12), &
              monthly_wind_speed(climate_cell_count, 12))
   allocate (monthly_air_pressure(climate_cell_count, 12), monthly_solar_input(climate_cell_count, &
                                                                                12))

    allocate (reference_q(catchment_count))
    allocate (hru_percentage(catchment_count, hru_count))
    allocate (catchment_area(catchment_count), drainage_area(catchment_count), &
              river_length(catchment_count), river_slope(catchment_count))
    allocate (catchment_x(catchment_count), catchment_y(catchment_count))
    allocate (climate_region(catchment_count))
    allocate (catchment_subbasin(catchment_count), longest_reach_slope(catchment_count), &
              longest_reach_length(catchment_count), downstream_catchment(catchment_count), &
              routing_downstream_catchment(catchment_count))
    allocate (river_width(catchment_count))
    allocate (subbasin_outlet_catchment(subbasin_count))
    allocate (subsurface_routing_coefficient(subbasin_count), &
              groundwater_routing_coefficient(subbasin_count), &
              surface_routing_coefficient(subbasin_count))
    allocate (brooks_corey_lambda(subbasin_count, hru_count), &
              max_capillary_flux(subbasin_count, hru_count), &
              capillary_threshold_fraction(subbasin_count, hru_count))

    allocate (max_soil_water_storage(subbasin_count, hru_count), arno_b(subbasin_count, &
                                   hru_count), subsurface_conductivity(subbasin_count, hru_count), &
              groundwater_conductivity(subbasin_count, hru_count), &
              floodplain_infiltration_rate(subbasin_count, hru_count))
    allocate (muskingum_reach_count(catchment_count))
    allocate (muskingum_timestep(catchment_count))
    allocate (wave_celerity(catchment_count), concentration_time(catchment_count))
    allocate (albedo(hru_count, 12, climate_region_count), leaf_area_index(hru_count, 12, &
                    climate_region_count), vegetation_height(hru_count, 12, climate_region_count), &
              surface_resistance(hru_count, 12, climate_region_count))
    allocate (specific_baseflow(subbasin_count))
    allocate (catchments_per_subbasin(subbasin_count))
    allocate (substituted_q(substitution_count, timestep_count))

    allocate (incoming_q_previous(catchment_count + 1), &
              outgoing_q_previous(catchment_count), incoming_q_current(catchment_count + 1), &
              outgoing_q_current(catchment_count))
    allocate (catchment_q_previous(catchment_count), catchment_q_current(catchment_count))
    allocate (incoming_groundwater_fraction_current(catchment_count + 1), &
              incoming_subsurface_fraction_current(catchment_count + 1), &
              incoming_surface_fraction_current(catchment_count + 1), &
              outgoing_groundwater_fraction_current(catchment_count + 1), &
              outgoing_subsurface_fraction_current(catchment_count + 1), &
              outgoing_surface_fraction_current(catchment_count + 1))
    allocate (groundwater_routing_volume(catchment_count), &
              subsurface_routing_volume(catchment_count), &
              surface_routing_volume(catchment_count))
    allocate (evapotranspiration(catchment_count, hru_count))
    allocate (capillary_flux(catchment_count, hru_count))
    allocate (soil_water_storage(catchment_count, hru_count))
    allocate (groundwater_q(catchment_count), subsurface_q(catchment_count), &
              surface_q(catchment_count))
    allocate (groundwater_storage(catchment_count), subsurface_storage(catchment_count), &
              surface_storage(catchment_count))
    allocate (previous_air_temperature(catchment_count))
    allocate (precipitation(catchment_count))
    allocate (air_temperature(catchment_count), relative_humidity(catchment_count), &
              wind_speed(catchment_count), solar_input(catchment_count), &
              air_pressure(catchment_count))

    allocate (catchment_order(catchment_count))

    allocate (substitution_enabled(catchment_count))

    ! Variables to calculate indicators of maximum evapotranspiration:
    allocate (potential_open_water_et(catchment_count), &
              potential_top_radiation_et(catchment_count), &
              potential_surface_radiation_et(catchment_count))

    allocate (incremental_q_output(catchment_count))
    allocate (et_output(catchment_count))
    allocate (interception_et_output(catchment_count))
    allocate (water_hru_et_output(catchment_count))
    allocate (soil_vegetation_et_output(catchment_count))
    allocate (open_water_et_output(catchment_count))
    allocate (potential_open_water_et_output(catchment_count))
    allocate (soil_water_output(catchment_count))
    allocate (interception_storage_output(catchment_count))
    allocate (capillary_water_output(catchment_count))
    allocate (groundwater_storage_depth_output(catchment_count))
    allocate (surface_storage_depth_output(catchment_count))
    allocate (subsurface_storage_depth_output(catchment_count))
    allocate (groundwater_runoff_depth_output(catchment_count))
    allocate (surface_runoff_depth_output(catchment_count))
    allocate (subsurface_runoff_depth_output(catchment_count))
    allocate (catchment_q_output(catchment_count))
    allocate (surface_water_output(catchment_count))
    allocate (groundwater_q_output(catchment_count))
    allocate (soil_saturation_output(catchment_count))
    allocate (total_water_storage(catchment_count))
    allocate (flow_velocity(catchment_count))
    allocate (hotstart_write_schedule(timestep_count))

    allocate (manning_n(catchment_count))
    allocate (reservoir_index_by_catchment(catchment_count), &
              reservoir_start_timestep(catchment_count))

    !VINICIUS SIQUEIRA IN 07-11-2016
    !Arrays declarations inside subroutines have been taken to this module

    allocate (groundwater_delay(catchment_count), subsurface_delay(catchment_count), &
              surface_delay(catchment_count))
    allocate (incoming_groundwater_fraction_previous(catchment_count + 1), &
              incoming_subsurface_fraction_previous(catchment_count + 1), &
              incoming_surface_fraction_previous(catchment_count + 1))
    allocate (outgoing_groundwater_fraction_previous(catchment_count), &
              outgoing_subsurface_fraction_previous(catchment_count), &
              outgoing_surface_fraction_previous(catchment_count))

    case (1)
    ! Deallocation
    deallocate (q_river_output)
    deallocate (open_water_evaporation_q)
    deallocate (incoming_q_boundary, outgoing_q_boundary)

    deallocate (climate_station_coordinates)
    deallocate (monthly_air_temperature, monthly_relative_humidity, monthly_wind_speed)
    deallocate (monthly_air_pressure, monthly_solar_input)

    deallocate (reference_q)
    deallocate (hru_percentage)
    deallocate (catchment_area, drainage_area, river_length, river_slope)
    deallocate (catchment_x, catchment_y)
    deallocate (climate_region)
    deallocate (catchment_subbasin, longest_reach_slope, longest_reach_length, &
                downstream_catchment)
    deallocate (river_width)
    deallocate (subbasin_outlet_catchment)
    deallocate (subsurface_routing_coefficient, groundwater_routing_coefficient, &
                surface_routing_coefficient)
    deallocate (brooks_corey_lambda, max_capillary_flux, capillary_threshold_fraction)
    deallocate (max_soil_water_storage, arno_b, subsurface_conductivity, &
                groundwater_conductivity, floodplain_infiltration_rate)
    deallocate (muskingum_reach_count, muskingum_timestep)
    deallocate (wave_celerity, concentration_time)
    deallocate (albedo, leaf_area_index, vegetation_height, surface_resistance)
    deallocate (specific_baseflow)
    deallocate (catchments_per_subbasin)
    deallocate (interception_storage)
    deallocate (incoming_q_previous, outgoing_q_previous, incoming_q_current, outgoing_q_current)
    deallocate (incoming_groundwater_fraction_current, &
                incoming_subsurface_fraction_current, incoming_surface_fraction_current, &
                outgoing_groundwater_fraction_current, outgoing_subsurface_fraction_current, &
                outgoing_surface_fraction_current)
    deallocate (groundwater_routing_volume, subsurface_routing_volume, surface_routing_volume)
    deallocate (evapotranspiration)
    deallocate (capillary_flux)
    deallocate (soil_water_storage)
    deallocate (groundwater_q, subsurface_q, surface_q)
    deallocate (groundwater_storage, subsurface_storage, surface_storage)
    deallocate (previous_air_temperature)
    deallocate (precipitation)
    deallocate (air_temperature, relative_humidity, wind_speed, solar_input, air_pressure)
    deallocate (catchment_q_previous, catchment_q_current)
    deallocate (substituted_q)

    deallocate (catchment_order)

    deallocate (incremental_q_output)
    deallocate (et_output)
    deallocate (interception_et_output)
    deallocate (water_hru_et_output)
    deallocate (soil_vegetation_et_output)
    deallocate (open_water_et_output)
    deallocate (potential_open_water_et_output)
    deallocate (soil_water_output)
    deallocate (interception_storage_output)
    deallocate (capillary_water_output)
    deallocate (surface_storage_depth_output)
    deallocate (subsurface_storage_depth_output)
    deallocate (groundwater_storage_depth_output)
    deallocate (surface_runoff_depth_output)
    deallocate (subsurface_runoff_depth_output)
    deallocate (groundwater_runoff_depth_output)
    deallocate (surface_water_output)
    deallocate (catchment_q_output)
    deallocate (groundwater_q_output)
    deallocate (soil_saturation_output)
    deallocate (total_water_storage)
    deallocate (flow_velocity)
    deallocate (hotstart_write_schedule)
    deallocate (water_surface_elevation_output)
    deallocate (flooded_area_output)
    deallocate (total_water_storage_output)
    deallocate (hand_output)

    deallocate (manning_n)

    !VINICIUS SIQUEIRA IN 07-11-2016
    !Arrays declarations inside subroutines have been taken to this module

    deallocate (groundwater_delay, subsurface_delay, surface_delay)
    deallocate (incoming_groundwater_fraction_previous, &
                incoming_subsurface_fraction_previous, incoming_surface_fraction_previous)
    deallocate (outgoing_groundwater_fraction_previous, &
                outgoing_subsurface_fraction_previous, outgoing_surface_fraction_previous)

    case default
    stop ' ERROR: IOP UNKNOWN AT ROUTINE ALLOCA_CALIB!!!'
    end select allocation_action

    ! End of the routine.
end subroutine allocate_model_state
