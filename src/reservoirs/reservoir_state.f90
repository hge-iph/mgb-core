module reservoir_state

    use runoff_state, only: max_subbasin_count

    implicit none
    private
    save

    public :: reservoir_count, reservoir_index_by_catchment, reservoir_outflow, &
           reservoir_start_timestep, reservoir_substitution_enabled, routing_downstream_catchment, &
              substituted_q, substitution_catchment, substitution_count, substitution_enabled, &
              allocate_reservoir_state, deallocate_reservoir_state, initialize_reservoir_state

    integer substitution_count
    integer substitution_catchment(max_subbasin_count)
    integer :: reservoir_count
    real, allocatable :: substituted_q(:, :)
    integer reservoir_substitution_enabled
    integer, allocatable :: substitution_enabled(:)
    integer, dimension(:), allocatable :: reservoir_index_by_catchment
    integer, dimension(:), allocatable :: routing_downstream_catchment
    integer, dimension(:), allocatable :: reservoir_start_timestep
    real(kind=8), dimension(:, :), allocatable :: reservoir_outflow

contains

    subroutine allocate_reservoir_state(requested_catchment_count, requested_timestep_count)
        integer, intent(in) :: requested_catchment_count, requested_timestep_count
        allocate (substituted_q(substitution_count, requested_timestep_count))
        allocate (substitution_enabled(requested_catchment_count))
        allocate (reservoir_index_by_catchment(requested_catchment_count))
        allocate (routing_downstream_catchment(requested_catchment_count))
        allocate (reservoir_start_timestep(requested_catchment_count))
    end subroutine allocate_reservoir_state

    subroutine deallocate_reservoir_state
        if (allocated(reservoir_start_timestep)) deallocate (reservoir_start_timestep)
        if (allocated(routing_downstream_catchment)) deallocate (routing_downstream_catchment)
        if (allocated(reservoir_index_by_catchment)) deallocate (reservoir_index_by_catchment)
        if (allocated(substitution_enabled)) deallocate (substitution_enabled)
        if (allocated(substituted_q)) deallocate (substituted_q)
        if (allocated(reservoir_outflow)) deallocate (reservoir_outflow)
    end subroutine deallocate_reservoir_state

    subroutine initialize_reservoir_state
        reservoir_index_by_catchment = 0
    end subroutine initialize_reservoir_state

end module reservoir_state
