    subroutine date_parser(date_full,y,mm,d,h,m)
    
    implicit none    
    character(len=40), intent(in) :: date_full
    integer, intent(out) :: y,mm,d,h,m
    
    ! Read date in format "YYYY-MM-DD HH:mm"
    read(date_full,'(I4,1X,I2,1X,I2,1X,I2,1X,I2)') y,mm,d,h,m
    
    if (h > 23) error stop 'Hour cannot be larger than 23.'
    if (h < 0) error stop 'Hour cannot be negative.'
    if (mm < 1 .OR. d < 1 .OR. y < 1) error stop 'Calendar date cannot be negative.'
    if (mm > 12 .OR. d > 31) error stop 'Calendar date is not allowed.'
    
    end subroutine
    
    
    