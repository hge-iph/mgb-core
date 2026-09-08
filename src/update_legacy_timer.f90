! SPDX-License-Identifier: GPL-3.0-or-later
! Copyright (C) 2019 Hidrologia de Grande Escala (HGE)

! Retain the legacy system-clock timer interface.

    SUBROUTINE update_legacy_timer(timer_action,seed_value)
    IMPLICIT NONE
    INTEGER timer_action
    INTEGER clock_value
    INTEGER seed_value

    timer_actions: SELECT CASE(timer_action)
    CASE(0) ! Initialize the seed from the system clock.
        CALL SYSTEM_CLOCK(COUNT=clock_value)
        seed_value=clock_value
    CASE(1) ! The legacy stop action has no implementation.
        CONTINUE
    END SELECT timer_actions
    RETURN
    END
