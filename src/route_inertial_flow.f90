! SPDX-License-Identifier: GPL-3.0-or-later
! Copyright (C) 2019 Hidrologia de Grande Escala (HGE)

! Advance inertial routing across one model timestep.

    subroutine route_inertial_flow

        use model_state
        use inertial_state
        use ifport

        implicit none

        !Initializes aggregating time step loop variable
        inertial_elapsed_time = 0.0

        !Intertial Routing loop
        do while (inertial_elapsed_time < remaining_model_timestep)

            call calculate_inertial_timestep

            ! Needed to adjust routing time step at last loop interval (i.e. in order to not exceed
            ! water balance [model_timestep_seconds] time step)
            inertial_timestep = min(inertial_timestep, remaining_model_timestep - &
                                    inertial_elapsed_time)

            !Updates the loop variable
            inertial_elapsed_time = inertial_elapsed_time + inertial_timestep

            call calculate_inertial_discharge
            call update_inertial_continuity

        end do

        return
    end subroutine

