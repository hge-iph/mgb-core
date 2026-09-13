module reservoirs

    implicit none
    private
    public :: initialize_reservoir_state

contains

    subroutine initialize_reservoir_state
        use parameters, only: reservoir_index_by_catchment

        reservoir_index_by_catchment = 0
    end subroutine initialize_reservoir_state

end module reservoirs
