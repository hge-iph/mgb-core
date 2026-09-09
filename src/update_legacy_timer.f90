! SPDX-License-Identifier: GPL-3.0-or-later
! Copyright (C) 2019 Hidrologia de Grande Escala (HGE)

! Retain the legacy system-clock timer interface.

    subroutine update_legacy_timer(timer_action, seed_value)
        implicit none
        integer timer_action
        integer clock_value
        integer seed_value

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
