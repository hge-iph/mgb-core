! SPDX-License-Identifier: GPL-3.0-or-later
! Copyright (C) 2019 Hidrologia de Grande Escala (HGE)

! Calculate a stable timestep for inertial routing.

        subroutine calculate_inertial_timestep
            use inertial_state
            use model_state
            implicit none

            real*8 minimum_catchment_timestep
            real*8 candidate_timestep

            candidate_timestep = dble(model_timestep_seconds)

            do catchment_index = 1, catchment_count
                !Catchment loop

                subbasin_index = catchment_subbasin(catchment_index)
                if ((subbasin_index < first_subbasin) .or. (subbasin_index > last_subbasin)) cycle
                ! Manual controls for specialized calibration

                ! MAX H to calculates the time-step of Inertial model:
                max_water_depth = (water_depth(catchment_index))
                ! Correct if equal to zero:
                max_water_depth = max(max_water_depth, 0.001)
                ! Compute time interval:
                inertial_timestep = courant_alpha*river_length(catchment_index)*1000./(gravity* &
                                                                               max_water_depth)**0.5
                if (inertial_timestep < candidate_timestep) candidate_timestep = inertial_timestep
            end do

            ! Do not exceed the main model timestep.
            max_inertial_timestep = dble(model_timestep_seconds)
            minimum_catchment_timestep = candidate_timestep
            inertial_timestep = min(max_inertial_timestep, minimum_catchment_timestep)

        end subroutine
