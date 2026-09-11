module evapotranspiration_state

    implicit none
    private
    save

    public :: air_pressure, air_temperature, climate_cell_count, climate_region_count, &
        & climate_station_coordinates, monthly_air_pressure, monthly_air_temperature, &
        & monthly_radiation_option, monthly_relative_humidity, monthly_solar_input, &
        & monthly_wind_speed, previous_air_temperature, relative_humidity, solar_input, &
        & use_humidity_timeseries, use_pressure_timeseries, use_radiation_timeseries, &
        & use_temperature_timeseries, use_wind_timeseries, wind_speed, actual_interception_et, &
        & actual_vapor_pressure, aerodynamic_resistance, air_density, albedo, &
        & available_interception_storage, current_air_pressure, current_air_temperature, &
        & current_albedo, current_interception_storage, current_leaf_area_index, &
        & current_relative_humidity, current_solar_input, current_surface_resistance, &
        & current_temperature, current_total_et, current_vegetation_height, current_wind_speed, &
        & day_of_year_real, earth_sun_distance_factor, evapotranspiration, ground_heat_flux, &
        & incoming_shortwave_radiation, interception_storage, latent_heat_vaporization, latitude, &
        & leaf_area_index, longwave_radiation, max_interception_storage, max_sunshine_duration, &
        & net_radiation, net_shortwave_radiation, open_water_aerodynamic_resistance, &
        & open_water_evaporation_q, pi, potential_interception_et, potential_open_water_et, &
        & potential_open_water_et_current, potential_surface_radiation_et, &
        & potential_top_radiation_et, previous_temperature, psychrometric_constant, &
        & remaining_et_demand_fraction, saturation_vapor_pressure, &
        & saturation_vapor_pressure_slope, soil_moisture_unlimited_et_threshold, &
        & soil_vegetation_et, solar_declination, stefan_boltzmann_constant, sunset_hour_angle, &
        & surface_resistance, surface_resistance_factor, surface_roughness, &
        & top_atmosphere_radiation, vapor_pressure_deficit, vegetation_height, water_density, &
        & wet_air_specific_heat, wilting_point, wind_speed_reference, &
        & allocate_evapotranspiration_state, deallocate_evapotranspiration_state

    integer climate_cell_count
    integer climate_region_count
    integer use_temperature_timeseries, use_radiation_timeseries
    integer use_humidity_timeseries, use_wind_timeseries, use_pressure_timeseries
    real(4), allocatable :: monthly_air_temperature(:, :), monthly_relative_humidity(:, :)
    real(4), allocatable :: monthly_wind_speed(:, :), monthly_air_pressure(:, :)
    real(4), allocatable :: monthly_solar_input(:, :)
    real, allocatable :: climate_station_coordinates(:, :)
    real, allocatable :: previous_air_temperature(:)
    real(4), allocatable :: air_temperature(:), relative_humidity(:), wind_speed(:)
    real(4), allocatable :: solar_input(:), air_pressure(:)
    integer monthly_radiation_option
    real, allocatable :: albedo(:, :, :), leaf_area_index(:, :, :), vegetation_height(:, :, :)
    real, allocatable :: surface_resistance(:, :, :)
    real, allocatable :: interception_storage(:, :), evapotranspiration(:, :)
    real latitude
    real current_solar_input, previous_temperature, current_albedo, net_radiation
    real day_of_year_real, current_relative_humidity
    real, parameter :: water_density = 1000.0
    real, parameter :: pi = 3.141592
    real, parameter :: stefan_boltzmann_constant = 4.903e-9
    real latent_heat_vaporization
    real solar_declination, sunset_hour_angle, max_sunshine_duration, earth_sun_distance_factor
    real ground_heat_flux, top_atmosphere_radiation
    real incoming_shortwave_radiation, net_shortwave_radiation
    real actual_vapor_pressure, saturation_vapor_pressure, longwave_radiation
    real current_air_pressure, current_air_temperature, current_wind_speed
    real current_leaf_area_index, current_vegetation_height, soil_vegetation_et
    real current_interception_storage, wind_speed_reference
    real current_temperature, current_surface_resistance, current_total_et
    real vapor_pressure_deficit, saturation_vapor_pressure_slope, psychrometric_constant
    real air_density, surface_roughness, available_interception_storage, max_interception_storage
    real potential_interception_et, potential_open_water_et_current
    real, allocatable :: open_water_evaporation_q(:)
    real actual_interception_et, remaining_et_demand_fraction
    real, parameter :: wet_air_specific_heat = 0.001013
    real aerodynamic_resistance, open_water_aerodynamic_resistance
    real soil_moisture_unlimited_et_threshold, wilting_point, surface_resistance_factor
    real, allocatable :: potential_open_water_et(:), potential_top_radiation_et(:)
    real, allocatable :: potential_surface_radiation_et(:)

contains

    subroutine allocate_evapotranspiration_state(requested_catchment_count, requested_hru_count, &
        & requested_climate_cell_count, requested_climate_region_count)
        integer, intent(in) :: requested_catchment_count, requested_climate_cell_count
        integer, intent(in) :: requested_hru_count, requested_climate_region_count
        allocate (climate_station_coordinates(requested_climate_cell_count, 2))
        allocate (monthly_air_temperature(requested_climate_cell_count, 12))
        allocate (monthly_relative_humidity(requested_climate_cell_count, 12))
        allocate (monthly_wind_speed(requested_climate_cell_count, 12))
        allocate (monthly_air_pressure(requested_climate_cell_count, 12))
        allocate (monthly_solar_input(requested_climate_cell_count, 12))
        allocate (previous_air_temperature(requested_catchment_count))
        allocate (air_temperature(requested_catchment_count))
        allocate (relative_humidity(requested_catchment_count))
        allocate (wind_speed(requested_catchment_count))
        allocate (solar_input(requested_catchment_count))
        allocate (air_pressure(requested_catchment_count))
        allocate (open_water_evaporation_q(requested_catchment_count))
        allocate (interception_storage(requested_catchment_count, requested_hru_count))
        allocate (albedo(requested_hru_count, 12, requested_climate_region_count))
        allocate (leaf_area_index(requested_hru_count, 12, requested_climate_region_count))
        allocate (vegetation_height(requested_hru_count, 12, requested_climate_region_count))
        allocate (surface_resistance(requested_hru_count, 12, requested_climate_region_count))
        allocate (evapotranspiration(requested_catchment_count, requested_hru_count))
        allocate (potential_open_water_et(requested_catchment_count))
        allocate (potential_top_radiation_et(requested_catchment_count))
        allocate (potential_surface_radiation_et(requested_catchment_count))
    end subroutine allocate_evapotranspiration_state

    subroutine deallocate_evapotranspiration_state
        if (allocated(potential_surface_radiation_et)) deallocate (potential_surface_radiation_et)
        if (allocated(potential_top_radiation_et)) deallocate (potential_top_radiation_et)
        if (allocated(potential_open_water_et)) deallocate (potential_open_water_et)
        if (allocated(evapotranspiration)) deallocate (evapotranspiration)
        if (allocated(surface_resistance)) deallocate (surface_resistance)
        if (allocated(vegetation_height)) deallocate (vegetation_height)
        if (allocated(leaf_area_index)) deallocate (leaf_area_index)
        if (allocated(albedo)) deallocate (albedo)
        if (allocated(interception_storage)) deallocate (interception_storage)
        if (allocated(open_water_evaporation_q)) deallocate (open_water_evaporation_q)
        if (allocated(air_pressure)) deallocate (air_pressure)
        if (allocated(solar_input)) deallocate (solar_input)
        if (allocated(wind_speed)) deallocate (wind_speed)
        if (allocated(relative_humidity)) deallocate (relative_humidity)
        if (allocated(air_temperature)) deallocate (air_temperature)
        if (allocated(previous_air_temperature)) deallocate (previous_air_temperature)
        if (allocated(monthly_solar_input)) deallocate (monthly_solar_input)
        if (allocated(monthly_air_pressure)) deallocate (monthly_air_pressure)
        if (allocated(monthly_wind_speed)) deallocate (monthly_wind_speed)
        if (allocated(monthly_relative_humidity)) deallocate (monthly_relative_humidity)
        if (allocated(monthly_air_temperature)) deallocate (monthly_air_temperature)
        if (allocated(climate_station_coordinates)) deallocate (climate_station_coordinates)
    end subroutine deallocate_evapotranspiration_state

end module evapotranspiration_state
