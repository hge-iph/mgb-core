module interpolation

    implicit none
    private
    public :: linear_interpolate

contains

    function linear_interpolate( &
        & x_values, &
        & y_values, &
        & point_count, &
        & query_x)
        implicit none

        integer, intent(in) :: point_count
        real*8, intent(in) :: x_values(point_count)
        real*8, intent(in) :: y_values(point_count)
        real*8, intent(in) :: query_x
        real*8 :: linear_interpolate
        integer :: upper_index
        integer :: lower_index
        real*8 :: x_lower
        real*8 :: x_upper
        real*8 :: y_lower
        real*8 :: y_upper

        ! x_lower    lower tabulated coordinate [same units as query_x]
        ! x_upper    upper tabulated coordinate [same units as query_x]
        ! y_lower    lower tabulated value [units of y_values]
        ! y_upper    upper tabulated value [units of y_values]

        do upper_index = 2, point_count
            x_upper = x_values(upper_index)
            y_upper = y_values(upper_index)
            if (query_x < x_upper) then
                ! Interpolate, or extrapolate below the first tabulated value.
                lower_index = upper_index - 1
                x_lower = x_values(lower_index)
                y_lower = y_values(lower_index)
                linear_interpolate = y_lower + (y_upper - y_lower)*(query_x - x_lower)/(x_upper - x_lower)
                exit
            elseif (query_x == x_upper) then
                linear_interpolate = y_upper
                exit
            elseif (upper_index == point_count) then
                ! Extrapolate above the final tabulated value.
                lower_index = upper_index - 1
                x_lower = x_values(lower_index)
                y_lower = y_values(lower_index)
                linear_interpolate = y_lower + (y_upper - y_lower)*(query_x - x_lower)/(x_upper - x_lower)
            end if
        end do
    end function linear_interpolate

end module interpolation
