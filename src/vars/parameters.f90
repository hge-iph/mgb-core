module parameters

    implicit none
    save

    integer, allocatable :: catchments_per_subbasin(:)
    character(10), allocatable :: hru_name(:)
    integer, allocatable :: subbasin_outlet_catchment(:)
    real, allocatable :: specific_baseflow(:)
    real, allocatable :: max_soil_water_storage(:, :), arno_b(:, :)
    real, allocatable :: subsurface_conductivity(:, :), groundwater_conductivity(:, :)
    real, allocatable :: brooks_corey_lambda(:, :), max_capillary_flux(:, :)
    real, allocatable :: capillary_threshold_fraction(:, :), floodplain_infiltration_rate(:, :)
    real, allocatable :: subsurface_routing_coefficient(:)
    real, allocatable :: groundwater_routing_coefficient(:), surface_routing_coefficient(:)
    real, allocatable :: albedo(:, :, :), leaf_area_index(:, :, :), vegetation_height(:, :, :)
    real, allocatable :: surface_resistance(:, :, :)

    integer, allocatable :: muskingum_reach_count(:)
    real, allocatable :: muskingum_timestep(:)
    real, allocatable :: wave_celerity(:), concentration_time(:), reference_q(:)

    integer, allocatable :: upstream_topology(:, :)
    real*8, allocatable :: stage_table(:, :), volume_table(:, :), area_table(:, :)

    integer, allocatable :: reservoir_index_by_catchment(:), routing_downstream_catchment(:)
    integer, allocatable :: reservoir_start_timestep(:)
    integer, allocatable :: substitution_catchment(:)

contains

    subroutine allocate_parameters(catchment_count, subbasin_count, hru_count, &
        & climate_region_count, max_hru_count, max_subbasin_count, max_muskingum_reach_count)
        integer, intent(in) :: catchment_count, subbasin_count, hru_count, climate_region_count
        integer, intent(in) :: max_hru_count, max_subbasin_count, max_muskingum_reach_count

        allocate (catchments_per_subbasin(subbasin_count))
        allocate (hru_name(max_hru_count))
        allocate (subbasin_outlet_catchment(subbasin_count))
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
        allocate (albedo(hru_count, 12, climate_region_count))
        allocate (leaf_area_index(hru_count, 12, climate_region_count))
        allocate (vegetation_height(hru_count, 12, climate_region_count))
        allocate (surface_resistance(hru_count, 12, climate_region_count))

        allocate (muskingum_reach_count(catchment_count))
        allocate (muskingum_timestep(catchment_count))
        allocate (wave_celerity(catchment_count))
        allocate (concentration_time(catchment_count))
        allocate (reference_q(catchment_count))

        allocate (upstream_topology(catchment_count, 10))
        allocate (stage_table(102, catchment_count))
        allocate (volume_table(102, catchment_count))
        allocate (area_table(102, catchment_count))

        allocate (reservoir_index_by_catchment(catchment_count))
        allocate (routing_downstream_catchment(catchment_count))
        allocate (reservoir_start_timestep(catchment_count))
        allocate (substitution_catchment(max_subbasin_count))
    end subroutine allocate_parameters

    subroutine deallocate_parameters
        if (allocated(substitution_catchment)) deallocate (substitution_catchment)
        if (allocated(reservoir_start_timestep)) deallocate (reservoir_start_timestep)
        if (allocated(routing_downstream_catchment)) deallocate (routing_downstream_catchment)
        if (allocated(reservoir_index_by_catchment)) deallocate (reservoir_index_by_catchment)
        if (allocated(area_table)) deallocate (area_table)
        if (allocated(volume_table)) deallocate (volume_table)
        if (allocated(stage_table)) deallocate (stage_table)
        if (allocated(upstream_topology)) deallocate (upstream_topology)
        if (allocated(reference_q)) deallocate (reference_q)
        if (allocated(concentration_time)) deallocate (concentration_time)
        if (allocated(wave_celerity)) deallocate (wave_celerity)
        if (allocated(muskingum_timestep)) deallocate (muskingum_timestep)
        if (allocated(muskingum_reach_count)) deallocate (muskingum_reach_count)
        if (allocated(surface_resistance)) deallocate (surface_resistance)
        if (allocated(vegetation_height)) deallocate (vegetation_height)
        if (allocated(leaf_area_index)) deallocate (leaf_area_index)
        if (allocated(albedo)) deallocate (albedo)
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
        if (allocated(subbasin_outlet_catchment)) deallocate (subbasin_outlet_catchment)
        if (allocated(hru_name)) deallocate (hru_name)
        if (allocated(catchments_per_subbasin)) deallocate (catchments_per_subbasin)
    end subroutine deallocate_parameters

end module parameters
