module output_state

    implicit none
    private
    save

    public :: capillary_water_output, catchment_q_output, et_output, flooded_area_output, &
        & groundwater_q_output, groundwater_runoff_depth_output, groundwater_storage_depth_output, &
        & hand_output, hotstart_write_schedule, incremental_q_output, interception_et_output, &
        & interception_storage_output, open_water_et_output, potential_open_water_et_output, &
        & q_river_output, read_hotstart_mode, soil_saturation_output, soil_vegetation_et_output, &
        & soil_water_output, subsurface_runoff_depth_output, subsurface_storage_depth_output, &
        & surface_runoff_depth_output, surface_storage_depth_output, surface_water_output, &
        & total_water_storage_output, water_hru_et_output, water_surface_elevation_output, &
        & write_discharge_output, write_et_output, write_flooded_area_output, &
        & write_groundwater_flux_output, write_groundwater_storage_output, write_hand_output, &
        & write_hotstart_mode, write_interception_et_output, write_interception_storage_output, &
        & write_open_water_et_output, write_potential_open_water_et_output, write_runoff_output, &
        & write_soil_moisture_output, write_soil_saturation_output, &
        & write_soil_vegetation_et_output, write_subsurface_flux_output, &
        & write_subsurface_storage_output, &
        & write_surface_flux_output, write_surface_storage_output, &
        & write_surface_water_output, write_total_water_storage_output, write_water_hru_et_output, &
        & write_water_surface_elevation_output, allocate_output_state, deallocate_output_state

    integer write_discharge_output, write_soil_moisture_output
    integer write_water_surface_elevation_output, write_hand_output
    integer write_total_water_storage_output, write_runoff_output, write_surface_water_output
    integer write_soil_saturation_output, write_et_output, write_interception_et_output
    integer write_soil_vegetation_et_output, write_open_water_et_output, write_water_hru_et_output
    integer write_groundwater_storage_output, write_subsurface_storage_output
    integer write_surface_storage_output, write_interception_storage_output
    integer write_flooded_area_output
    integer write_groundwater_flux_output, write_subsurface_flux_output, write_surface_flux_output
    integer write_potential_open_water_et_output
    real(4), allocatable :: q_river_output(:), water_surface_elevation_output(:)
    real(4), allocatable :: total_water_storage_output(:), flooded_area_output(:), hand_output(:)
    real(4), allocatable :: incremental_q_output(:)
    real(4), allocatable :: et_output(:)
    real(4), allocatable :: groundwater_q_output(:)
    real(4), allocatable :: soil_saturation_output(:)
    real(4), allocatable :: interception_et_output(:), soil_vegetation_et_output(:)
    real(4), allocatable :: open_water_et_output(:), water_hru_et_output(:)
    real(4), allocatable :: potential_open_water_et_output(:)
    real(4), allocatable :: soil_water_output(:), capillary_water_output(:)
    real(4), allocatable :: interception_storage_output(:)
    real(4), allocatable :: surface_storage_depth_output(:), subsurface_storage_depth_output(:)
    real(4), allocatable :: groundwater_storage_depth_output(:)
    real(4), allocatable :: surface_runoff_depth_output(:), subsurface_runoff_depth_output(:)
    real(4), allocatable :: groundwater_runoff_depth_output(:)
    real(4), allocatable :: surface_water_output(:)
    real(4), allocatable :: catchment_q_output(:)
    integer, allocatable :: hotstart_write_schedule(:)
    integer write_hotstart_mode, read_hotstart_mode

contains

    subroutine allocate_output_state(requested_catchment_count, requested_timestep_count)
        integer, intent(in) :: requested_catchment_count, requested_timestep_count
        allocate (q_river_output(requested_catchment_count))
        allocate (water_surface_elevation_output(requested_catchment_count))
        allocate (flooded_area_output(requested_catchment_count))
        allocate (total_water_storage_output(requested_catchment_count))
        allocate (hand_output(requested_catchment_count))
        allocate (incremental_q_output(requested_catchment_count))
        allocate (et_output(requested_catchment_count))
        allocate (interception_et_output(requested_catchment_count))
        allocate (water_hru_et_output(requested_catchment_count))
        allocate (soil_vegetation_et_output(requested_catchment_count))
        allocate (open_water_et_output(requested_catchment_count))
        allocate (potential_open_water_et_output(requested_catchment_count))
        allocate (soil_water_output(requested_catchment_count))
        allocate (interception_storage_output(requested_catchment_count))
        allocate (capillary_water_output(requested_catchment_count))
        allocate (groundwater_storage_depth_output(requested_catchment_count))
        allocate (surface_storage_depth_output(requested_catchment_count))
        allocate (subsurface_storage_depth_output(requested_catchment_count))
        allocate (groundwater_runoff_depth_output(requested_catchment_count))
        allocate (surface_runoff_depth_output(requested_catchment_count))
        allocate (subsurface_runoff_depth_output(requested_catchment_count))
        allocate (catchment_q_output(requested_catchment_count))
        allocate (surface_water_output(requested_catchment_count))
        allocate (groundwater_q_output(requested_catchment_count))
        allocate (soil_saturation_output(requested_catchment_count))
        allocate (hotstart_write_schedule(requested_timestep_count))
    end subroutine allocate_output_state

    subroutine deallocate_output_state
        if (allocated(hotstart_write_schedule)) deallocate (hotstart_write_schedule)
        if (allocated(soil_saturation_output)) deallocate (soil_saturation_output)
        if (allocated(groundwater_q_output)) deallocate (groundwater_q_output)
        if (allocated(surface_water_output)) deallocate (surface_water_output)
        if (allocated(catchment_q_output)) deallocate (catchment_q_output)
        if (allocated(subsurface_runoff_depth_output)) deallocate (subsurface_runoff_depth_output)
        if (allocated(surface_runoff_depth_output)) deallocate (surface_runoff_depth_output)
        if (allocated(groundwater_runoff_depth_output)) deallocate (groundwater_runoff_depth_output)
        if (allocated(subsurface_storage_depth_output)) deallocate (subsurface_storage_depth_output)
        if (allocated(surface_storage_depth_output)) deallocate (surface_storage_depth_output)
        if (allocated(groundwater_storage_depth_output)) &
            & deallocate (groundwater_storage_depth_output)
        if (allocated(capillary_water_output)) deallocate (capillary_water_output)
        if (allocated(interception_storage_output)) deallocate (interception_storage_output)
        if (allocated(soil_water_output)) deallocate (soil_water_output)
        if (allocated(potential_open_water_et_output)) deallocate (potential_open_water_et_output)
        if (allocated(open_water_et_output)) deallocate (open_water_et_output)
        if (allocated(soil_vegetation_et_output)) deallocate (soil_vegetation_et_output)
        if (allocated(water_hru_et_output)) deallocate (water_hru_et_output)
        if (allocated(interception_et_output)) deallocate (interception_et_output)
        if (allocated(et_output)) deallocate (et_output)
        if (allocated(incremental_q_output)) deallocate (incremental_q_output)
        if (allocated(hand_output)) deallocate (hand_output)
        if (allocated(total_water_storage_output)) deallocate (total_water_storage_output)
        if (allocated(flooded_area_output)) deallocate (flooded_area_output)
        if (allocated(water_surface_elevation_output)) deallocate (water_surface_elevation_output)
        if (allocated(q_river_output)) deallocate (q_river_output)
    end subroutine deallocate_output_state

end module output_state
