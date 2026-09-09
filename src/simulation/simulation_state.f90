! SPDX-License-Identifier: GPL-3.0-or-later
! Copyright (C) 2019 Hidrologia de Grande Escala (HGE)

module simulation_state

    implicit none
    private
    save

    public :: day, day_of_year, first_subbasin, hour, julian_day, last_subbasin, minute, &
              model_timestep, month, timestep_count, timestep_index, year

    integer timestep_count
    integer timestep_index
    integer day, month, year, hour, minute
    integer day_of_year
    real(8) julian_day
    real model_timestep
    integer first_subbasin, last_subbasin

end module simulation_state
