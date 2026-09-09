! SPDX-License-Identifier: GPL-3.0-or-later
! Copyright (C) 2019 Hidrologia de Grande Escala (HGE)

! Initialize a random seed from the system clock.

        subroutine initialize_random_seed(seed_value)

            implicit none
            integer, intent(out) :: seed_value
            integer :: clock_value
            call system_clock(count=clock_value)
            seed_value = clock_value
            return
        end subroutine initialize_random_seed
