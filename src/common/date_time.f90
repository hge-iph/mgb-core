module date_time

    use, intrinsic :: iso_fortran_env, only: int32, real32, real64
    implicit none
    private
    public :: format_date_string, parse_date_string, calculate_integer_julian_day, &
        & calculate_julian_day, convert_julian_day_to_calendar, calculate_timestep_count
contains

    function format_date_string( &
        & year, &
        & month, &
        & day, &
        & hour) result(date_text)
        implicit none

        integer(int32), intent(in) :: year
        integer(int32), intent(in) :: month
        integer(int32), intent(in) :: day
        integer(int32), intent(in) :: hour
        character(10) :: date_text

        write (date_text, "(I4,I2.2,I2.2,I2.2)") year, month, day, hour

    end function format_date_string

    ! Subroutine to parse date string in the format "YYYY-MM-DD HH:mm" and return integers
    subroutine parse_date_string( &
        & date_str, &
        & year, &
        & month, &
        & day, &
        & hour, &
        & minute)

        implicit none
        character(len=40), intent(in) :: date_str
        integer(int32), intent(out) :: year
        integer(int32), intent(out) :: month
        integer(int32), intent(out) :: day
        integer(int32), intent(out) :: hour
        integer(int32), intent(out) :: minute

        ! Read date in format "YYYY-MM-DD HH:mm"
        read (date_str, '(I4,1X,I2,1X,I2,1X,I2,1X,I2)') year, month, day, hour, minute

        if (hour > 23) error stop 'Hour cannot be larger than 23.'
        if (hour < 0) error stop 'Hour cannot be negative.'
        if (month < 1 .or. day < 1 .or. year < 1) error stop 'Calendar date cannot be negative.'
        if (month > 12 .or. day > 31) error stop 'Calendar date is not allowed.'

    end subroutine

    integer(int32) function calculate_integer_julian_day( &
        & year, &
        & month, &
        & day)
        implicit none

        integer(int32), intent(in) :: year
        integer(int32), intent(in) :: month
        integer(int32), intent(in) :: day
        integer(int32) :: month_shift
        integer(int32) :: year_term
        integer(int32) :: month_term
        integer(int32) :: century_term

        month_shift = (month - 14)/12
        year_term = 1461*(year + 4800 + month_shift)/4
        month_term = 367*(month - 2 - month_shift*12)/12
        century_term = 3*((year + 4900 + month_shift)/100)/4
        calculate_integer_julian_day = day - 32075 + year_term + month_term - century_term

    end function calculate_integer_julian_day

    ! function to compute julian date (real)
    function calculate_julian_day( &
        & year, &
        & month, &
        & day, &
        & hour, &
        & minute) result(julian_day_result)
        implicit none

        integer(int32), intent(in) :: year
        integer(int32), intent(in) :: month
        integer(int32), intent(in) :: day
        integer(int32), intent(in) :: hour
        integer(int32), intent(in) :: minute
        integer(int32) :: julian_day_number
        real(real64) :: julian_day_result
        real(real64) :: julian_with_hour

        julian_day_number = calculate_integer_julian_day(year, month, day)
        julian_with_hour = real(julian_day_number, real64) + real(hour, real64)/24.0_real64
        julian_day_result = julian_with_hour + real(minute, real64)/1440.0_real64

    end function calculate_julian_day

    ! Subroutine to compute calendar yyyy-mm-dd HH:MM from julian
    subroutine convert_julian_day_to_calendar( &
        & julian, &
        & year, &
        & month, &
        & day, &
        & hour, &
        & minute)
        implicit none

        real(real64), intent(in) :: julian
        integer(int32), intent(out) :: year
        integer(int32), intent(out) :: month
        integer(int32), intent(out) :: day
        integer(int32), intent(out) :: hour
        integer(int32), intent(out) :: minute

        real(real64) :: fractional_day
        integer(int32) :: year_cycle_index
        integer(int32) :: month_index
        integer(int32) :: intermediate_l
        integer(int32) :: century_index
        integer(int32) :: int_julian

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
        fractional_day = julian - real(int_julian, real64)

        hour = int(fractional_day*24.0_real64)
        minute = nint((fractional_day*24.0_real64 - real(hour, real64))*60.0_real64)

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
    integer(int32) function calculate_timestep_count( &
        & julian_end, &
        & julian_start, &
        & model_timestep)
        implicit none

        real(real64), intent(in) :: julian_end
        real(real64), intent(in) :: julian_start
        real(real64), intent(in) :: model_timestep
        ! model_timestep is expressed in seconds.

        ! Avoiding rounding errors
        calculate_timestep_count = int(real(((julian_end - julian_start)*86400.0_real64/model_timestep), real32))

    end function calculate_timestep_count

end module date_time
