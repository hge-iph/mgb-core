! SPDX-License-Identifier: GPL-3.0-or-later
! Copyright (C) 2019 Hidrologia de Grande Escala (HGE)

module muskingum_state

    implicit none
    private
    save

    public :: concentration_time, current_reach_length, current_reference_q, &
              elevation_difference, flow_velocity, groundwater_routing_volume, &
              incoming_groundwater_fraction_current, incoming_groundwater_fraction_previous, &
              incoming_q_boundary, incoming_q_current, incoming_q_previous, &
              incoming_subsurface_fraction_current, incoming_subsurface_fraction_previous, &
           incoming_surface_fraction_current, incoming_surface_fraction_previous, initial_river_q, &
              manning_n, max_muskingum_reach_count, muskingum_reach_count, muskingum_timestep, &
              outgoing_groundwater_fraction_current, outgoing_groundwater_fraction_previous, &
              outgoing_q_boundary, outgoing_q_current, outgoing_q_previous, &
              outgoing_subsurface_fraction_current, outgoing_subsurface_fraction_previous, &
              outgoing_surface_fraction_current, outgoing_surface_fraction_previous, reference_q, &
              subsurface_routing_volume, surface_routing_volume, wave_celerity, &
              allocate_muskingum_state, deallocate_muskingum_state

    integer, parameter :: max_muskingum_reach_count = 150
    integer, allocatable :: muskingum_reach_count(:)
    real, allocatable :: muskingum_timestep(:)
    real, allocatable :: wave_celerity(:), concentration_time(:)
    real, allocatable :: reference_q(:)
    real current_reference_q
    real current_reach_length, elevation_difference
    real, allocatable :: incoming_q_previous(:), outgoing_q_previous(:)
    real, allocatable :: incoming_q_current(:), outgoing_q_current(:)
    real, allocatable :: incoming_groundwater_fraction_current(:)
  real, allocatable :: incoming_subsurface_fraction_current(:), incoming_surface_fraction_current(:)
    real, allocatable :: outgoing_groundwater_fraction_current(:)
  real, allocatable :: outgoing_subsurface_fraction_current(:), outgoing_surface_fraction_current(:)
    real, allocatable :: groundwater_routing_volume(:), subsurface_routing_volume(:)
    real, allocatable :: surface_routing_volume(:)
    real, allocatable :: incoming_q_boundary(:, :), outgoing_q_boundary(:, :)
    real, allocatable :: initial_river_q(:, :)
    real, allocatable :: flow_velocity(:)
    real, allocatable :: manning_n(:)
    real, allocatable :: incoming_groundwater_fraction_previous(:)
    real, allocatable :: incoming_subsurface_fraction_previous(:)
    real, allocatable :: incoming_surface_fraction_previous(:)
    real, allocatable :: outgoing_groundwater_fraction_previous(:)
    real, allocatable :: outgoing_subsurface_fraction_previous(:)
    real, allocatable :: outgoing_surface_fraction_previous(:)

contains

    subroutine allocate_muskingum_state(requested_catchment_count)
        integer, intent(in) :: requested_catchment_count
        allocate (initial_river_q(requested_catchment_count, max_muskingum_reach_count + 1))
        allocate (reference_q(requested_catchment_count))
        allocate (incoming_q_boundary(requested_catchment_count + 1, 25))
        allocate (outgoing_q_boundary(requested_catchment_count + 1, 25))
        allocate (muskingum_reach_count(requested_catchment_count))
        allocate (muskingum_timestep(requested_catchment_count))
        allocate (wave_celerity(requested_catchment_count))
        allocate (concentration_time(requested_catchment_count))
        allocate (incoming_q_previous(requested_catchment_count + 1))
        allocate (outgoing_q_previous(requested_catchment_count))
        allocate (incoming_q_current(requested_catchment_count + 1))
        allocate (outgoing_q_current(requested_catchment_count))
        allocate (incoming_groundwater_fraction_current(requested_catchment_count + 1))
        allocate (incoming_subsurface_fraction_current(requested_catchment_count + 1))
        allocate (incoming_surface_fraction_current(requested_catchment_count + 1))
        allocate (outgoing_groundwater_fraction_current(requested_catchment_count + 1))
        allocate (outgoing_subsurface_fraction_current(requested_catchment_count + 1))
        allocate (outgoing_surface_fraction_current(requested_catchment_count + 1))
        allocate (groundwater_routing_volume(requested_catchment_count))
        allocate (subsurface_routing_volume(requested_catchment_count))
        allocate (surface_routing_volume(requested_catchment_count))
        allocate (manning_n(requested_catchment_count))
        allocate (flow_velocity(requested_catchment_count))
        allocate (incoming_groundwater_fraction_previous(requested_catchment_count + 1))
        allocate (incoming_subsurface_fraction_previous(requested_catchment_count + 1))
        allocate (incoming_surface_fraction_previous(requested_catchment_count + 1))
        allocate (outgoing_groundwater_fraction_previous(requested_catchment_count))
        allocate (outgoing_subsurface_fraction_previous(requested_catchment_count))
        allocate (outgoing_surface_fraction_previous(requested_catchment_count))
    end subroutine allocate_muskingum_state

    subroutine deallocate_muskingum_state
  if (allocated(outgoing_surface_fraction_previous)) deallocate (outgoing_surface_fraction_previous)
        if (allocated(outgoing_subsurface_fraction_previous)) &
            deallocate (outgoing_subsurface_fraction_previous)
        if (allocated(outgoing_groundwater_fraction_previous)) &
            deallocate (outgoing_groundwater_fraction_previous)
  if (allocated(incoming_surface_fraction_previous)) deallocate (incoming_surface_fraction_previous)
        if (allocated(incoming_subsurface_fraction_previous)) &
            deallocate (incoming_subsurface_fraction_previous)
        if (allocated(incoming_groundwater_fraction_previous)) &
            deallocate (incoming_groundwater_fraction_previous)
        if (allocated(flow_velocity)) deallocate (flow_velocity)
        if (allocated(manning_n)) deallocate (manning_n)
        if (allocated(surface_routing_volume)) deallocate (surface_routing_volume)
        if (allocated(subsurface_routing_volume)) deallocate (subsurface_routing_volume)
        if (allocated(groundwater_routing_volume)) deallocate (groundwater_routing_volume)
    if (allocated(outgoing_surface_fraction_current)) deallocate (outgoing_surface_fraction_current)
        if (allocated(outgoing_subsurface_fraction_current)) &
            deallocate (outgoing_subsurface_fraction_current)
        if (allocated(outgoing_groundwater_fraction_current)) &
            deallocate (outgoing_groundwater_fraction_current)
    if (allocated(incoming_surface_fraction_current)) deallocate (incoming_surface_fraction_current)
        if (allocated(incoming_subsurface_fraction_current)) &
            deallocate (incoming_subsurface_fraction_current)
        if (allocated(incoming_groundwater_fraction_current)) &
            deallocate (incoming_groundwater_fraction_current)
        if (allocated(outgoing_q_current)) deallocate (outgoing_q_current)
        if (allocated(incoming_q_current)) deallocate (incoming_q_current)
        if (allocated(outgoing_q_previous)) deallocate (outgoing_q_previous)
        if (allocated(incoming_q_previous)) deallocate (incoming_q_previous)
        if (allocated(concentration_time)) deallocate (concentration_time)
        if (allocated(wave_celerity)) deallocate (wave_celerity)
        if (allocated(muskingum_timestep)) deallocate (muskingum_timestep)
        if (allocated(muskingum_reach_count)) deallocate (muskingum_reach_count)
        if (allocated(outgoing_q_boundary)) deallocate (outgoing_q_boundary)
        if (allocated(incoming_q_boundary)) deallocate (incoming_q_boundary)
        if (allocated(reference_q)) deallocate (reference_q)
        if (allocated(initial_river_q)) deallocate (initial_river_q)
    end subroutine deallocate_muskingum_state

end module muskingum_state
