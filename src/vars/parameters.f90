module parameters

    use, intrinsic :: iso_fortran_env, only: int32, real32, real64
    implicit none
    save

    integer(int32), allocatable :: catchments_per_subbasin(:)
    character(10), allocatable :: hru_name(:)
    integer(int32), allocatable :: subbasin_outlet_catchment(:)
    real(real32), allocatable :: specific_baseflow(:)
    real(real32), allocatable :: max_soil_water_storage(:, :)
    real(real32), allocatable :: b_arno(:, :)
    real(real32), allocatable :: subsurface_conductivity(:, :)
    real(real32), allocatable :: groundwater_conductivity(:, :)
    real(real32), allocatable :: lambda_brooks_corey(:, :)
    real(real32), allocatable :: max_capillary_flux(:, :)
    real(real32), allocatable :: capillary_threshold_fraction(:, :)
    real(real32), allocatable :: floodplain_infiltration_rate(:, :)
    real(real32), allocatable :: subsurface_routing_coefficient(:)
    real(real32), allocatable :: groundwater_routing_coefficient(:)
    real(real32), allocatable :: surface_routing_coefficient(:)
    real(real32), allocatable :: albedo(:, :, :)
    real(real32), allocatable :: leaf_area_index(:, :, :)
    real(real32), allocatable :: vegetation_height(:, :, :)
    real(real32), allocatable :: surface_resistance(:, :, :)

    integer(int32), allocatable :: muskingum_reach_count(:)
    real(real32), allocatable :: muskingum_timestep(:)
    real(real32), allocatable :: wave_celerity(:)
    real(real32), allocatable :: time_of_concentration(:)
    real(real32), allocatable :: reference_q(:)

    integer(int32), allocatable :: upstream_topology(:, :)
    real(real64), allocatable :: stage_table(:, :)
    real(real64), allocatable :: volume_table(:, :)
    real(real64), allocatable :: area_table(:, :)

    integer(int32), allocatable :: reservoir_index_by_catchment(:)
    integer(int32), allocatable :: routing_downstream_catchment(:)
    integer(int32), allocatable :: reservoir_start_timestep(:)
    integer(int32), allocatable :: substitution_catchment(:)

contains

    subroutine allocate_parameters( &
        & catchment_count, &
        & subbasin_count, &
        & hru_count, &
        & climate_region_count, &
        & max_hru_count, &
        & max_subbasin_count, &
        & max_muskingum_reach_count)
        integer(int32), intent(in) :: catchment_count
        integer(int32), intent(in) :: subbasin_count
        integer(int32), intent(in) :: hru_count
        integer(int32), intent(in) :: climate_region_count
        integer(int32), intent(in) :: max_hru_count
        integer(int32), intent(in) :: max_subbasin_count
        integer(int32), intent(in) :: max_muskingum_reach_count

        allocate (catchments_per_subbasin(subbasin_count))
        allocate (hru_name(max_hru_count))
        allocate (subbasin_outlet_catchment(subbasin_count))
        allocate (subsurface_routing_coefficient(subbasin_count))
        allocate (groundwater_routing_coefficient(subbasin_count))
        allocate (surface_routing_coefficient(subbasin_count))
        allocate (lambda_brooks_corey(subbasin_count, hru_count))
        allocate (max_capillary_flux(subbasin_count, hru_count))
        allocate (capillary_threshold_fraction(subbasin_count, hru_count))
        allocate (max_soil_water_storage(subbasin_count, hru_count))
        allocate (b_arno(subbasin_count, hru_count))
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
        allocate (time_of_concentration(catchment_count))
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
        if (allocated(time_of_concentration)) deallocate (time_of_concentration)
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
        if (allocated(b_arno)) deallocate (b_arno)
        if (allocated(max_soil_water_storage)) deallocate (max_soil_water_storage)
        if (allocated(capillary_threshold_fraction)) deallocate (capillary_threshold_fraction)
        if (allocated(max_capillary_flux)) deallocate (max_capillary_flux)
        if (allocated(lambda_brooks_corey)) deallocate (lambda_brooks_corey)
        if (allocated(surface_routing_coefficient)) deallocate (surface_routing_coefficient)
        if (allocated(groundwater_routing_coefficient)) deallocate (groundwater_routing_coefficient)
        if (allocated(subsurface_routing_coefficient)) deallocate (subsurface_routing_coefficient)
        if (allocated(subbasin_outlet_catchment)) deallocate (subbasin_outlet_catchment)
        if (allocated(hru_name)) deallocate (hru_name)
        if (allocated(catchments_per_subbasin)) deallocate (catchments_per_subbasin)
    end subroutine deallocate_parameters

end module parameters
