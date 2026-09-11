module runoff_state

    implicit none
    private
    save

    public :: catchment_area, catchment_count, catchment_index, catchment_order, &
        & catchment_subbasin, catchment_x, catchment_y, catchments_per_subbasin, climate_region, &
        & current_catchment_area, current_river_width, downstream_catchment, drainage_area, &
        & hru_count, hru_index, hru_name, hru_percentage, longest_reach_length, &
        & longest_reach_slope, max_hru_count, max_subbasin_count, river_length, river_slope, &
        & river_width, subbasin_count, subbasin_index, subbasin_outlet_catchment, arno_b, &
        & brooks_corey_lambda, capillary_flux, capillary_threshold_fraction, &
        & catchment_capillary_q, &
        & catchment_q_current, catchment_q_previous, catchment_soil_water_sum, current_arno_b, &
        & current_brooks_corey_lambda, current_capillary_flux, &
        & current_capillary_threshold_fraction, current_floodplain_infiltration, &
        & current_floodplain_infiltration_rate, current_groundwater_conductivity, &
        & current_max_soil_water_storage, current_precipitation, current_soil_water_storage, &
        & current_subsurface_conductivity, floodplain_infiltration, floodplain_infiltration_rate, &
        & groundwater_conductivity, groundwater_delay, groundwater_q, &
        & groundwater_routing_coefficient, groundwater_storage, hru_area_fraction, &
        & max_capillary_flux, max_soil_water_storage, minimum_soil_storage, precipitation, &
        & remaining_groundwater_storage, remaining_subsurface_storage, remaining_surface_storage, &
        & soil_water_storage, specific_baseflow, subsurface_conductivity, subsurface_delay, &
        & subsurface_q, subsurface_routing_coefficient, subsurface_storage, surface_delay, &
        & surface_q, surface_routing_coefficient, surface_storage, total_water_storage, &
        & allocate_runoff_state, deallocate_runoff_state

    integer, parameter :: max_hru_count = 12
    integer, parameter :: max_subbasin_count = 505
    integer catchment_count, hru_count
    integer subbasin_count
    integer, allocatable :: catchments_per_subbasin(:)
    character(10) hru_name(max_hru_count)
    integer, allocatable :: subbasin_outlet_catchment(:)
    real, allocatable :: river_width(:)
    real current_river_width
    integer, allocatable :: catchment_subbasin(:), downstream_catchment(:)
    real, allocatable :: longest_reach_slope(:), longest_reach_length(:)
    real, allocatable :: catchment_x(:), catchment_y(:)
    integer, allocatable :: climate_region(:)
    real, allocatable :: catchment_area(:), drainage_area(:), river_length(:), river_slope(:)
    real, allocatable :: hru_percentage(:, :)
    integer catchment_index
    integer subbasin_index, hru_index
    integer, allocatable :: catchment_order(:)
    real current_catchment_area
    real, allocatable :: specific_baseflow(:)
    real, allocatable :: max_soil_water_storage(:, :), arno_b(:, :)
    real, allocatable :: subsurface_conductivity(:, :), groundwater_conductivity(:, :)
    real, allocatable :: brooks_corey_lambda(:, :), max_capillary_flux(:, :)
    real, allocatable :: capillary_threshold_fraction(:, :), floodplain_infiltration_rate(:, :)
    real, allocatable :: subsurface_routing_coefficient(:)
    real, allocatable :: groundwater_routing_coefficient(:), surface_routing_coefficient(:)
    real, allocatable :: catchment_q_previous(:), catchment_q_current(:)
    real, allocatable :: capillary_flux(:, :), soil_water_storage(:, :)
    real, allocatable :: groundwater_q(:), subsurface_q(:), surface_q(:)
    real, allocatable :: groundwater_storage(:), subsurface_storage(:), surface_storage(:)
    real(4), allocatable :: precipitation(:)
    real current_soil_water_storage, current_max_soil_water_storage, current_arno_b
    real current_subsurface_conductivity, current_groundwater_conductivity
    real current_precipitation, current_floodplain_infiltration_rate, current_brooks_corey_lambda
    real current_capillary_flux, current_capillary_threshold_fraction
    real remaining_groundwater_storage, remaining_subsurface_storage, remaining_surface_storage
    real hru_area_fraction, catchment_soil_water_sum, catchment_capillary_q
    real, allocatable :: total_water_storage(:)
    real minimum_soil_storage
    real, allocatable :: groundwater_delay(:), subsurface_delay(:), surface_delay(:)
    real, allocatable :: floodplain_infiltration(:)
    real current_floodplain_infiltration

contains

    subroutine allocate_runoff_state()
        allocate (catchments_per_subbasin(subbasin_count))
        allocate (hru_percentage(catchment_count, hru_count))
        allocate (catchment_area(catchment_count))
        allocate (drainage_area(catchment_count))
        allocate (river_length(catchment_count))
        allocate (river_slope(catchment_count))
        allocate (catchment_x(catchment_count))
        allocate (catchment_y(catchment_count))
        allocate (climate_region(catchment_count))
        allocate (catchment_subbasin(catchment_count))
        allocate (longest_reach_slope(catchment_count))
        allocate (longest_reach_length(catchment_count))
        allocate (downstream_catchment(catchment_count))
        allocate (river_width(catchment_count))
        allocate (subbasin_outlet_catchment(subbasin_count))
        allocate (catchment_order(catchment_count))
        allocate (subsurface_routing_coefficient(subbasin_count))
        allocate (groundwater_routing_coefficient(subbasin_count))
        allocate (surface_routing_coefficient(subbasin_count))
        allocate (brooks_corey_lambda(subbasin_count, hru_count))
        allocate (max_capillary_flux(subbasin_count, hru_count))
        allocate (capillary_threshold_fraction(subbasin_count, hru_count))
        allocate (max_soil_water_storage(subbasin_count, hru_count))
        allocate (arno_b(subbasin_count, hru_count))
        allocate (subsurface_conductivity(subbasin_count, hru_count))
        allocate (groundwater_conductivity(subbasin_count, hru_count))
        allocate (floodplain_infiltration_rate(subbasin_count, hru_count))
        allocate (specific_baseflow(subbasin_count))
        allocate (catchment_q_previous(catchment_count))
        allocate (catchment_q_current(catchment_count))
        allocate (capillary_flux(catchment_count, hru_count))
        allocate (soil_water_storage(catchment_count, hru_count))
        allocate (groundwater_q(catchment_count))
        allocate (subsurface_q(catchment_count))
        allocate (surface_q(catchment_count))
        allocate (groundwater_storage(catchment_count))
        allocate (subsurface_storage(catchment_count))
        allocate (surface_storage(catchment_count))
        allocate (precipitation(catchment_count))
        allocate (total_water_storage(catchment_count))
        allocate (groundwater_delay(catchment_count))
        allocate (subsurface_delay(catchment_count))
        allocate (surface_delay(catchment_count))
        allocate (floodplain_infiltration(catchment_count))
    end subroutine allocate_runoff_state

    subroutine deallocate_runoff_state
        if (allocated(floodplain_infiltration)) deallocate (floodplain_infiltration)
        if (allocated(surface_delay)) deallocate (surface_delay)
        if (allocated(subsurface_delay)) deallocate (subsurface_delay)
        if (allocated(groundwater_delay)) deallocate (groundwater_delay)
        if (allocated(total_water_storage)) deallocate (total_water_storage)
        if (allocated(precipitation)) deallocate (precipitation)
        if (allocated(surface_storage)) deallocate (surface_storage)
        if (allocated(subsurface_storage)) deallocate (subsurface_storage)
        if (allocated(groundwater_storage)) deallocate (groundwater_storage)
        if (allocated(surface_q)) deallocate (surface_q)
        if (allocated(subsurface_q)) deallocate (subsurface_q)
        if (allocated(groundwater_q)) deallocate (groundwater_q)
        if (allocated(soil_water_storage)) deallocate (soil_water_storage)
        if (allocated(capillary_flux)) deallocate (capillary_flux)
        if (allocated(catchment_q_current)) deallocate (catchment_q_current)
        if (allocated(catchment_q_previous)) deallocate (catchment_q_previous)
        if (allocated(specific_baseflow)) deallocate (specific_baseflow)
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
        if (allocated(catchment_order)) deallocate (catchment_order)
        if (allocated(subbasin_outlet_catchment)) deallocate (subbasin_outlet_catchment)
        if (allocated(river_width)) deallocate (river_width)
        if (allocated(downstream_catchment)) deallocate (downstream_catchment)
        if (allocated(longest_reach_length)) deallocate (longest_reach_length)
        if (allocated(longest_reach_slope)) deallocate (longest_reach_slope)
        if (allocated(catchment_subbasin)) deallocate (catchment_subbasin)
        if (allocated(climate_region)) deallocate (climate_region)
        if (allocated(catchment_y)) deallocate (catchment_y)
        if (allocated(catchment_x)) deallocate (catchment_x)
        if (allocated(river_slope)) deallocate (river_slope)
        if (allocated(river_length)) deallocate (river_length)
        if (allocated(drainage_area)) deallocate (drainage_area)
        if (allocated(catchment_area)) deallocate (catchment_area)
        if (allocated(hru_percentage)) deallocate (hru_percentage)
        if (allocated(catchments_per_subbasin)) deallocate (catchments_per_subbasin)
    end subroutine deallocate_runoff_state

end module runoff_state
