! SPDX-License-Identifier: GPL-3.0-or-later
! Copyright (C) 2019 Hidrologia de Grande Escala (HGE)

! Read discharge series that replace simulated flow at selected catchments.

        subroutine read_substitution_flows
            use model_state
            implicit none
            integer :: input_year, input_month, substitution_index, input_day
            open (substitution_flow_unit, file=input_directory//'substitution_flows.txt', status= &
                  'OLD')
      read (substitution_flow_unit, 701) (header_fields(substitution_index), substitution_index=1, &
                                                substitution_count)
            do timestep_index = 1, timestep_count
                read (substitution_flow_unit, *) input_year, input_month, input_day, &
                    (substituted_q(substitution_index, timestep_index), substitution_index=1, &
                     substitution_count)
            end do
            close (substitution_flow_unit)
701         format(20a10)
            return
        end subroutine read_substitution_flows
