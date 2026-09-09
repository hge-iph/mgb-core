! SPDX-License-Identifier: GPL-3.0-or-later
! Copyright (C) 2019 Hidrologia de Grande Escala (HGE)

! Linearly interpolate or extrapolate a tabulated value.

function linear_interpolate(x_values, y_values, point_count, query_x)
    implicit none

    integer, intent(in) :: point_count
    real*8, intent(in) :: x_values(point_count), y_values(point_count), query_x
    real*8 :: linear_interpolate
    integer :: upper_index, lower_index

    do upper_index = 2, point_count
        if (query_x < x_values(upper_index)) then
            ! Interpolate, or extrapolate below the first tabulated value.
            lower_index = upper_index - 1
            linear_interpolate = y_values(lower_index) &
                                 + (y_values(upper_index) - y_values(lower_index)) &
                                 *(query_x - x_values(lower_index))/(x_values(upper_index) - &
                                                                     x_values(lower_index))
            exit
        elseif (query_x == x_values(upper_index)) then
            linear_interpolate = y_values(upper_index)
            exit
        elseif (upper_index == point_count) then
            ! Extrapolate above the final tabulated value.
            lower_index = upper_index - 1
            linear_interpolate = y_values(lower_index) &
                                 + (y_values(upper_index) - y_values(lower_index)) &
                                 *(query_x - x_values(lower_index))/(x_values(upper_index) - &
                                                                     x_values(lower_index))
        end if
    end do
end function linear_interpolate
