! SPDX-License-Identifier: GPL-3.0-or-later
! Copyright (C) 2019 Hidrologia de Grande Escala (HGE)

! Calculate catchment concentration-time parameters.

        subroutine calculate_catchment_parameters

            use model_state
            use inertial_state
            implicit none
            integer catchment_parameter_index

            ! Calculates Time of Concentration (i.e. time of travel) for Catchment
            do catchment_parameter_index = 1, catchment_count
                current_reach_length = longest_reach_length(catchment_parameter_index)
                ! km
                elevation_difference = longest_reach_slope(catchment_parameter_index) &
                                       *longest_reach_length(catchment_parameter_index)
                ! m

                concentration_time(catchment_parameter_index) = 3600. &
                                                              *((0.868*current_reach_length**3.0)/ &
                                                                  elevation_difference)**0.385
            end do

            return
        end
