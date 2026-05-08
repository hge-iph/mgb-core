    
    module utils_date
    
    implicit none
    
    contains
    
    ! Convert calendar date integers to string in the format YYYYMMDDHH
    function date_string(year,month,day,hour) result(strDate)
        implicit none
    
        integer, intent(in)  ::  year,month,day,hour 
        character(10) :: strDate
             
        write (strDate,"(I4,I2.2,I2.2,I2.2)") year,month,day,hour
      
    end function date_string
    
    
    ! Subroutine to parse date string in the format "YYYY-MM-DD HH:mm" and return integers
    subroutine date_parser(date_str,year,month,day,hour,minute)
    
        implicit none    
        character(len=40), intent(in) :: date_str
        integer, intent(out) :: year,month,day,hour,minute
    
        ! Read date in format "YYYY-MM-DD HH:mm"
        read(date_str,'(I4,1X,I2,1X,I2,1X,I2,1X,I2)') year,month,day,hour,minute
    
        if (hour > 23) error stop 'Hour cannot be larger than 23.'
        if (hour < 0) error stop 'Hour cannot be negative.'
        if (month < 1 .OR. day < 1 .OR. year < 1) error stop 'Calendar date cannot be negative.'
        if (month > 12 .OR. day > 31) error stop 'Calendar date is not allowed.'
    
    end subroutine
    
end module utils_date