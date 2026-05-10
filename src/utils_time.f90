    
    
    ! Module that includes functions/subroutines for time computations
    
    ! julday and caldat computations is based on Fortran Astrodynamics Toolkit
    ! https://github.com/jacobwilliams/Fortran-Astrodynamics-Toolkit

    !Copyright (c) 2014-2025, Jacob Williams
    
    module utils_time
    
    implicit none
    integer, parameter, private :: wp=8
    
    contains
    
    ! function to compute julian date (integer)
     integer function julday_int(year,month,day)
        implicit none
        
        integer,intent(in) :: year, month, day        
  
        julday_int = day - 32075 + 1461 * (year + 4800 + (month - 14) / 12) / 4  &
                    + 367 * (month - 2 - (month - 14) / 12 * 12) / 12 &
                    - 3 * ((year + 4900 +(month - 14) / 12) / 100) / 4
  
     end function julday_int
   
     
    ! function to compute julian date (real)
    function julday_rl(year,month,day,hour,min) result(jdr) 
        implicit none  
        
        integer, intent(in) :: year, month, day, hour, min
        integer :: jd_number 
        real(wp) :: jdr  
        
        jd_number = julday_int(year, month, day)
           
        jdr = real(jd_number,wp) &
            + real(hour,wp) / 24.0_wp &
            + real(min,wp) / 1440.0_wp
        
    end function julday_rl
    
      
    ! Subroutine to compute calendar yyyy-mm-dd HH:MM from julian 
    subroutine caldat_rl(julian,year,month,day,hour,min)
        implicit none
  
        real(wp),intent(in)  :: julian 
        integer,intent(out)  :: year, month, day, hour, min
    
        real(wp) :: diff
        integer :: i,j,l,n
        integer :: int_julian
        
        int_julian = int(julian)

        ! Fliegel & Van Flandern algorithm
        l = int_julian + 68569
        n = (4 * l) / 146097
        l = l - (146097 * n + 3) / 4
        i = (4000 * (l + 1)) / 1461001
        l = l - (1461 * i) / 4 + 31
        j = (80 * l) / 2447
        day = l - (2447 * j) / 80
        l = j / 11
        month = j + 2 - 12 * l
        year = 100 * (n - 49) + i + l

        ! fractional day -> hours and minutes
        diff = julian - real(int_julian,wp) 

        hour = int(diff * 24.0_wp)
        min = nint((diff * 24.0_wp - real(hour,wp)) * 60.0_wp)

        if (min == 60) then
            min = 0
            hour = hour + 1
        end if
        
        if (hour == 24) then
            hour = 0
            day = day + 1
        end if

    end subroutine caldat_rl
 
    
    ! Function to compute the number of time steps between to julian dates 
    integer function time_diff(julian_end, julian_start, dtp)
        implicit none
        
        real(wp), intent(in) :: julian_end, julian_start, dtp
        
        ! Avoiding rounding errors
        time_diff = int(real(((julian_end - julian_start) * 86400.0_wp / dtp), 4))

    end function time_diff
      
    
end module utils_time