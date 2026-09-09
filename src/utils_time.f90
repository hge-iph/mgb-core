! SPDX-License-Identifier: GPL-3.0-or-later
! Portions copyright (C) 2014-2025 Jacob Williams

! Provide Julian-date and calendar conversion utilities.

module utils_time

    implicit none
    integer, parameter, private :: real_kind = 8

contains

    ! function to compute julian date (integer)
    integer function calculate_integer_julian_day(year, month, day)
        implicit none

        integer, intent(in) :: year, month, day

        calculate_integer_julian_day = day - 32075 + 1461*(year + 4800 + (month - 14)/12)/4 &
                                       + 367*(month - 2 - (month - 14)/12*12)/12 &
                                       - 3*((year + 4900 + (month - 14)/12)/100)/4

    end function calculate_integer_julian_day

    ! function to compute julian date (real)
    function calculate_julian_day(year, month, day, hour, minute) result(julian_day_result)
        implicit none

        integer, intent(in) :: year, month, day, hour, minute
        integer :: julian_day_number
        real(real_kind) :: julian_day_result

        julian_day_number = calculate_integer_julian_day(year, month, day)

        julian_day_result = real(julian_day_number, real_kind) &
                            + real(hour, real_kind)/24.0_real_kind &
                            + real(minute, real_kind)/1440.0_real_kind

    end function calculate_julian_day

    ! Subroutine to compute calendar yyyy-mm-dd HH:MM from julian
    subroutine convert_julian_day_to_calendar(julian, year, month, day, hour, minute)
        implicit none

        real(real_kind), intent(in) :: julian
        integer, intent(out) :: year, month, day, hour, minute

        real(real_kind) :: fractional_day
        integer :: year_cycle_index, month_index, intermediate_l, century_index
        integer :: int_julian

        int_julian = int(julian)

        ! Fliegel & Van Flandern algorithm
        intermediate_l = int_julian + 68569
        century_index = (4*intermediate_l)/146097
        intermediate_l = intermediate_l - (146097*century_index + 3)/4
        year_cycle_index = (4000*(intermediate_l + 1))/1461001
        intermediate_l = intermediate_l - (1461*year_cycle_index)/4 + 31
        month_index = (80*intermediate_l)/2447
        day = intermediate_l - (2447*month_index)/80
        intermediate_l = month_index/11
        month = month_index + 2 - 12*intermediate_l
        year = 100*(century_index - 49) + year_cycle_index + intermediate_l

        ! fractional day -> hours and minutes
        fractional_day = julian - real(int_julian, real_kind)

        hour = int(fractional_day*24.0_real_kind)
        minute = nint((fractional_day*24.0_real_kind - real(hour, real_kind))*60.0_real_kind)

        if (minute == 60) then
            minute = 0
            hour = hour + 1
        end if

        if (hour == 24) then
            hour = 0
            day = day + 1
        end if

    end subroutine convert_julian_day_to_calendar

    ! Function to compute the number of time steps between two Julian dates.
    integer function calculate_timestep_count(julian_end, julian_start, model_timestep)
        implicit none

        real(real_kind), intent(in) :: julian_end, julian_start, model_timestep
        ! model_timestep is expressed in seconds.

        ! Avoiding rounding errors
        calculate_timestep_count = int(real(((julian_end - julian_start)*86400.0_real_kind/ &
                                             model_timestep), 4))

    end function calculate_timestep_count

end module utils_time
