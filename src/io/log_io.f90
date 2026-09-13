module log_io

    implicit none
    private
    public :: open_model_log, close_model_log

contains

    subroutine open_model_log
        use config, only: &
            & log_unit, &
            & output_directory

        implicit none

        open (log_unit, file=output_directory//'model.log', status='UNKNOWN')
    end subroutine open_model_log

    subroutine close_model_log
        use config, only: log_unit

        implicit none

        close (log_unit)
    end subroutine close_model_log

end module log_io
