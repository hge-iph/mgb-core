module runtime_support

    use, intrinsic :: iso_fortran_env, only: int32
    implicit none
    private
    public :: initialize_random_seed, update_legacy_timer

contains

    subroutine initialize_random_seed( &
        & seed_value)

        implicit none
        integer(int32), intent(out) :: seed_value
        integer(int32) :: clock_value
        call system_clock(count=clock_value)
        seed_value = clock_value
        return
    end subroutine initialize_random_seed

    subroutine update_legacy_timer( &
        & timer_action, &
        & seed_value)
        implicit none
        integer(int32) :: timer_action
        integer(int32) :: clock_value
        integer(int32) :: seed_value

        timer_actions:select case(timer_action)
        case (0)
        ! Initialize the seed from the system clock.
        call system_clock(count=clock_value)
        seed_value = clock_value
        case (1)
        ! The legacy stop action has no implementation.
        continue
        end select timer_actions
        return
    end

end module runtime_support
