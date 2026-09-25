module log_io

    implicit none
    private
    public :: open_model_log, close_model_log

contains

    subroutine open_model_log
        use config, only: &
            & io_unit_log, &
            & output_directory

        implicit none

        open (io_unit_log, file=output_directory//'model.log', status='UNKNOWN')
    end subroutine open_model_log

    subroutine close_model_log
        use config, only: io_unit_log

        implicit none

        close (io_unit_log)
    end subroutine close_model_log

end module log_io
