! SPDX-License-Identifier: GPL-3.0-or-later
! Copyright (C) 2019 Hidrologia de Grande Escala (HGE)

! Initialize a random seed from the system clock.

	SUBROUTINE initialize_random_seed(seed_value)

    IMPLICIT NONE
    INTEGER, INTENT(OUT) :: seed_value
    INTEGER :: clock_value
    CALL SYSTEM_CLOCK(COUNT=clock_value)
    seed_value=clock_value
    RETURN
    END SUBROUTINE initialize_random_seed
