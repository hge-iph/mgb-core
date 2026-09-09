module water_balance_state

    implicit none
    private
    save

    public :: actual_interception_et, actual_vapor_pressure, aerodynamic_resistance, air_density, &
              albedo, arno_b, available_interception_storage, brooks_corey_lambda, capillary_flux, &
              capillary_threshold_fraction, catchment_capillary_q, catchment_q_current, &
              catchment_q_previous, catchment_soil_water_sum, current_air_pressure, &
              current_air_temperature, current_albedo, current_area, current_arno_b, &
              current_brooks_corey_lambda, current_capillary_flux, &
              current_capillary_threshold_fraction, current_floodplain_infiltration, &
              current_floodplain_infiltration_rate, current_groundwater_conductivity, &
            current_interception_storage, current_leaf_area_index, current_max_soil_water_storage, &
              current_precipitation, current_relative_humidity, current_soil_water_storage, &
              current_solar_input, current_subsurface_conductivity, current_surface_resistance, &
             current_temperature, current_total_et, current_vegetation_height, current_wind_speed, &
         day_of_year_real, earth_sun_distance_factor, evapotranspiration, floodplain_infiltration, &
              floodplain_infiltration_rate, ground_heat_flux, groundwater_conductivity, &
           groundwater_delay, groundwater_q, groundwater_routing_coefficient, groundwater_storage, &
              hru_area_fraction, incoming_shortwave_radiation, interception_storage, &
              latent_heat_vaporization, latitude, leaf_area_index, longwave_radiation, &
              max_capillary_flux, max_interception_storage, max_soil_water_storage, &
              max_sunshine_duration, minimum_soil_storage, net_radiation, net_shortwave_radiation, &
              open_water_aerodynamic_resistance, open_water_evaporation_q, pi, &
              potential_interception_et, potential_open_water_et, potential_open_water_et_current, &
              potential_surface_radiation_et, potential_top_radiation_et, previous_temperature, &
              psychrometric_constant, remaining_et_demand_fraction, remaining_groundwater_storage, &
              remaining_subsurface_storage, remaining_surface_storage, saturation_vapor_pressure, &
              saturation_vapor_pressure_slope, soil_moisture_unlimited_et_threshold, &
              soil_vegetation_et, soil_water_storage, solar_declination, specific_baseflow, &
              stefan_boltzmann_constant, subsurface_conductivity, subsurface_delay, subsurface_q, &
             subsurface_routing_coefficient, subsurface_storage, sunset_hour_angle, surface_delay, &
              surface_q, surface_resistance, surface_resistance_factor, surface_roughness, &
              surface_routing_coefficient, surface_storage, top_atmosphere_radiation, &
              total_water_storage, vapor_pressure_deficit, vegetation_height, water_density, &
         wet_air_specific_heat, wilting_point, wind_speed_reference, allocate_water_balance_state, &
              deallocate_water_balance_state

    real, allocatable :: specific_baseflow(:)
    real, allocatable :: albedo(:, :, :), leaf_area_index(:, :, :), vegetation_height(:, :, :)
    real, allocatable :: surface_resistance(:, :, :)
    real, allocatable :: max_soil_water_storage(:, :), arno_b(:, :)
    real, allocatable :: subsurface_conductivity(:, :), groundwater_conductivity(:, :)
    real, allocatable :: brooks_corey_lambda(:, :), max_capillary_flux(:, :)
    real, allocatable :: capillary_threshold_fraction(:, :), floodplain_infiltration_rate(:, :)
    real, allocatable :: subsurface_routing_coefficient(:)
    real, allocatable :: groundwater_routing_coefficient(:), surface_routing_coefficient(:)
    real, allocatable :: interception_storage(:, :)
    real current_area
    real, allocatable :: catchment_q_previous(:), catchment_q_current(:)
    real, allocatable :: evapotranspiration(:, :)
    real, allocatable :: capillary_flux(:, :)
    real, allocatable :: soil_water_storage(:, :)
    real, allocatable :: groundwater_q(:), subsurface_q(:), surface_q(:)
    real, allocatable :: groundwater_storage(:), subsurface_storage(:), surface_storage(:)
    real latitude
    real current_solar_input, previous_temperature
    real current_albedo
    real net_radiation
    real day_of_year_real
    real current_relative_humidity
    real, parameter :: water_density = 1000.0
    real, parameter :: pi = 3.141592
    real, parameter :: stefan_boltzmann_constant = 4.903e-9
    real latent_heat_vaporization
    real solar_declination, sunset_hour_angle
    real max_sunshine_duration
    real earth_sun_distance_factor
    real ground_heat_flux, top_atmosphere_radiation
    real incoming_shortwave_radiation, net_shortwave_radiation
    real actual_vapor_pressure, saturation_vapor_pressure
    real longwave_radiation
    real current_soil_water_storage, current_max_soil_water_storage, current_air_pressure
    real current_air_temperature, current_wind_speed, current_arno_b
    real current_subsurface_conductivity, current_groundwater_conductivity
    real current_leaf_area_index, current_vegetation_height, soil_vegetation_et
    real current_precipitation, current_interception_storage, wind_speed_reference
    real current_floodplain_infiltration_rate, current_brooks_corey_lambda
    real current_temperature, current_surface_resistance, current_capillary_flux, current_total_et
    real current_capillary_threshold_fraction, remaining_groundwater_storage
    real remaining_subsurface_storage, remaining_surface_storage, hru_area_fraction
    real catchment_soil_water_sum, catchment_capillary_q
    real vapor_pressure_deficit
    real saturation_vapor_pressure_slope
    real psychrometric_constant
    real air_density
    real surface_roughness
    real available_interception_storage
    real max_interception_storage
    real potential_interception_et
    real potential_open_water_et_current
    real, allocatable :: open_water_evaporation_q(:)
    real actual_interception_et
    real remaining_et_demand_fraction
    real, parameter :: wet_air_specific_heat = 0.001013
    real aerodynamic_resistance
    real open_water_aerodynamic_resistance
    real soil_moisture_unlimited_et_threshold
    real wilting_point
    real surface_resistance_factor
    real, allocatable :: potential_open_water_et(:), potential_top_radiation_et(:)
    real, allocatable :: potential_surface_radiation_et(:)
    real, allocatable :: total_water_storage(:)
    real minimum_soil_storage
    real, allocatable :: groundwater_delay(:), subsurface_delay(:), surface_delay(:)
    real, allocatable :: floodplain_infiltration(:)
    real current_floodplain_infiltration

contains

    subroutine allocate_water_balance_state(requested_catchment_count, requested_hru_count, &
                                            requested_subbasin_count, &
                                            requested_climate_region_count)
        integer, intent(in) :: requested_catchment_count, requested_hru_count
        integer, intent(in) :: requested_subbasin_count, requested_climate_region_count
        allocate (open_water_evaporation_q(requested_catchment_count))
        allocate (interception_storage(requested_catchment_count, requested_hru_count))
        allocate (subsurface_routing_coefficient(requested_subbasin_count))
        allocate (groundwater_routing_coefficient(requested_subbasin_count))
        allocate (surface_routing_coefficient(requested_subbasin_count))
        allocate (brooks_corey_lambda(requested_subbasin_count, requested_hru_count))
        allocate (max_capillary_flux(requested_subbasin_count, requested_hru_count))
        allocate (capillary_threshold_fraction(requested_subbasin_count, requested_hru_count))
        allocate (max_soil_water_storage(requested_subbasin_count, requested_hru_count))
        allocate (arno_b(requested_subbasin_count, requested_hru_count))
        allocate (subsurface_conductivity(requested_subbasin_count, requested_hru_count))
        allocate (groundwater_conductivity(requested_subbasin_count, requested_hru_count))
        allocate (floodplain_infiltration_rate(requested_subbasin_count, requested_hru_count))
        allocate (albedo(requested_hru_count, 12, requested_climate_region_count))
        allocate (leaf_area_index(requested_hru_count, 12, requested_climate_region_count))
        allocate (vegetation_height(requested_hru_count, 12, requested_climate_region_count))
        allocate (surface_resistance(requested_hru_count, 12, requested_climate_region_count))
        allocate (specific_baseflow(requested_subbasin_count))
        allocate (catchment_q_previous(requested_catchment_count))
        allocate (catchment_q_current(requested_catchment_count))
        allocate (evapotranspiration(requested_catchment_count, requested_hru_count))
        allocate (capillary_flux(requested_catchment_count, requested_hru_count))
        allocate (soil_water_storage(requested_catchment_count, requested_hru_count))
        allocate (groundwater_q(requested_catchment_count))
        allocate (subsurface_q(requested_catchment_count))
        allocate (surface_q(requested_catchment_count))
        allocate (groundwater_storage(requested_catchment_count))
        allocate (subsurface_storage(requested_catchment_count))
        allocate (surface_storage(requested_catchment_count))
        allocate (potential_open_water_et(requested_catchment_count))
        allocate (potential_top_radiation_et(requested_catchment_count))
        allocate (potential_surface_radiation_et(requested_catchment_count))
        allocate (total_water_storage(requested_catchment_count))
        allocate (groundwater_delay(requested_catchment_count))
        allocate (subsurface_delay(requested_catchment_count))
        allocate (surface_delay(requested_catchment_count))
        allocate (floodplain_infiltration(requested_catchment_count))
    end subroutine allocate_water_balance_state

    subroutine deallocate_water_balance_state
        if (allocated(floodplain_infiltration)) deallocate (floodplain_infiltration)
        if (allocated(surface_delay)) deallocate (surface_delay)
        if (allocated(subsurface_delay)) deallocate (subsurface_delay)
        if (allocated(groundwater_delay)) deallocate (groundwater_delay)
        if (allocated(total_water_storage)) deallocate (total_water_storage)
        if (allocated(potential_surface_radiation_et)) deallocate (potential_surface_radiation_et)
        if (allocated(potential_top_radiation_et)) deallocate (potential_top_radiation_et)
        if (allocated(potential_open_water_et)) deallocate (potential_open_water_et)
        if (allocated(surface_storage)) deallocate (surface_storage)
        if (allocated(subsurface_storage)) deallocate (subsurface_storage)
        if (allocated(groundwater_storage)) deallocate (groundwater_storage)
        if (allocated(surface_q)) deallocate (surface_q)
        if (allocated(subsurface_q)) deallocate (subsurface_q)
        if (allocated(groundwater_q)) deallocate (groundwater_q)
        if (allocated(soil_water_storage)) deallocate (soil_water_storage)
        if (allocated(capillary_flux)) deallocate (capillary_flux)
        if (allocated(evapotranspiration)) deallocate (evapotranspiration)
        if (allocated(catchment_q_current)) deallocate (catchment_q_current)
        if (allocated(catchment_q_previous)) deallocate (catchment_q_previous)
        if (allocated(specific_baseflow)) deallocate (specific_baseflow)
        if (allocated(surface_resistance)) deallocate (surface_resistance)
        if (allocated(vegetation_height)) deallocate (vegetation_height)
        if (allocated(leaf_area_index)) deallocate (leaf_area_index)
        if (allocated(albedo)) deallocate (albedo)
        if (allocated(floodplain_infiltration_rate)) deallocate (floodplain_infiltration_rate)
        if (allocated(groundwater_conductivity)) deallocate (groundwater_conductivity)
        if (allocated(subsurface_conductivity)) deallocate (subsurface_conductivity)
        if (allocated(arno_b)) deallocate (arno_b)
        if (allocated(max_soil_water_storage)) deallocate (max_soil_water_storage)
        if (allocated(capillary_threshold_fraction)) deallocate (capillary_threshold_fraction)
        if (allocated(max_capillary_flux)) deallocate (max_capillary_flux)
        if (allocated(brooks_corey_lambda)) deallocate (brooks_corey_lambda)
        if (allocated(surface_routing_coefficient)) deallocate (surface_routing_coefficient)
        if (allocated(groundwater_routing_coefficient)) deallocate (groundwater_routing_coefficient)
        if (allocated(subsurface_routing_coefficient)) deallocate (subsurface_routing_coefficient)
        if (allocated(interception_storage)) deallocate (interception_storage)
        if (allocated(open_water_evaporation_q)) deallocate (open_water_evaporation_q)
    end subroutine deallocate_water_balance_state

end module water_balance_state
