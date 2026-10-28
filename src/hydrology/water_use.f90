module water_use

    implicit none
    private
    public :: read_water_use_inputs
    public :: apply_outlet_withdrawal, apply_outlet_return
    public :: apply_outlet_withdrawal_double, apply_outlet_return_double
    public :: apply_inertial_withdrawal_volume

    real(kind=8), parameter :: return_flow_fraction = 0.7_8
    real, allocatable :: withdrawal_by_year(:, :)
    real, allocatable :: consumption_by_year(:, :)
    ! Rate actually removed at the start of the routing interval, by catchment.
    real(kind=8), allocatable :: withdrawn_rate_by_catchment(:)
    ! Portion of the realized withdrawal consumed instead of returned.
    real(kind=8), allocatable :: consumed_rate_by_catchment(:)
    integer :: first_water_use_year = 1
    integer :: last_water_use_year = 0

contains

    subroutine read_water_use_inputs
        use attributes, only: catchment_id
        use config, only: catchment_count, input_directory, water_use_enabled, water_use_scale

        implicit none
        character(len=256) :: consumption_path
        character(len=256) :: withdrawal_path
        integer :: first_year
        integer :: last_year
        integer :: row_count

        if (water_use_enabled /= 1) return

        withdrawal_path = water_use_file_path(input_directory, 'retirada.csv')
        consumption_path = water_use_file_path(input_directory, 'consumo.csv')

        first_year = huge(first_year)
        last_year = -huge(last_year)
        call scan_water_use_file(withdrawal_path, first_year, last_year, row_count)

        if (first_year > last_year) then
            first_year = 1
            last_year = 0
        end if
        first_water_use_year = first_year
        last_water_use_year = last_year
        allocate (withdrawal_by_year(catchment_count, first_year:last_year))
        allocate (consumption_by_year(catchment_count, first_year:last_year))
        allocate (withdrawn_rate_by_catchment(catchment_count))
        allocate (consumed_rate_by_catchment(catchment_count))
        withdrawal_by_year = 0.0
        ! Preserve the historical 70% return flow when consumption data is absent.
        consumption_by_year = real(1.0_8 - return_flow_fraction)
        withdrawn_rate_by_catchment = 0.0_8
        consumed_rate_by_catchment = 0.0_8

        call load_water_use_file(withdrawal_path, catchment_id, withdrawal_by_year)
        withdrawal_by_year = withdrawal_by_year * water_use_scale
        consumption_by_year = consumption_by_year * withdrawal_by_year
        if (len_trim(consumption_path) > 0) then
            ! Both CSV files store rates in the same source units. Scale the
            ! explicit consumption values as well so withdrawal and return
            ! calculations use matching units. Missing rows retain the 30%
            ! consumption default derived from the scaled withdrawal.
            call load_water_use_file(consumption_path, catchment_id, consumption_by_year, water_use_scale)
        end if
    end subroutine read_water_use_inputs

    subroutine scan_water_use_file(file_path, first_year, last_year, row_count)
        implicit none
        character(len=*), intent(in) :: file_path
        integer, intent(inout) :: first_year
        integer, intent(inout) :: last_year
        integer, intent(out) :: row_count
        character(len=512) :: line
        integer :: file_unit
        integer :: io_status
        integer :: data_year
        real :: mini_value
        real :: use_value
        real :: year_value

        row_count = 0
        if (len_trim(file_path) == 0) return
        open (newunit=file_unit, file=trim(file_path), status='old', action='read', iostat=io_status)
        if (io_status /= 0) return

        read (file_unit, '(A)', iostat=io_status) line
        if (io_status /= 0) then
            close (file_unit)
            return
        end if
        do
            read (file_unit, '(A)', iostat=io_status) line
            if (io_status /= 0) exit
            if (len_trim(line) == 0) cycle
            read (line, *, iostat=io_status) mini_value, use_value, year_value
            if (io_status /= 0) error stop 'Invalid water-use CSV row.'
            data_year = nint(year_value)
            first_year = min(first_year, data_year)
            last_year = max(last_year, data_year)
            row_count = row_count + 1
        end do
        close (file_unit)
    end subroutine scan_water_use_file

    subroutine load_water_use_file(file_path, catchment_ids, water_use_by_year, value_scale)
        implicit none
        character(len=*), intent(in) :: file_path
        integer, intent(in) :: catchment_ids(:)
        real, intent(inout) :: water_use_by_year(:, :)
        real, intent(in), optional :: value_scale
        character(len=512) :: line
        integer :: file_unit
        integer :: io_status
        integer :: mini_id
        integer :: data_year
        integer :: year_index
        integer :: i_catch
        real :: applied_scale
        real :: mini_value
        real :: use_value
        real :: year_value

        if (len_trim(file_path) == 0) return
        applied_scale = 1.0
        if (present(value_scale)) applied_scale = value_scale
        open (newunit=file_unit, file=trim(file_path), status='old', action='read', iostat=io_status)
        if (io_status /= 0) return

        read (file_unit, '(A)', iostat=io_status) line
        if (io_status /= 0) then
            close (file_unit)
            return
        end if
        do
            read (file_unit, '(A)', iostat=io_status) line
            if (io_status /= 0) exit
            if (len_trim(line) == 0) cycle
            read (line, *, iostat=io_status) mini_value, use_value, year_value
            if (io_status /= 0) error stop 'Invalid water-use CSV row.'
            mini_id = nint(mini_value)
            data_year = nint(year_value)
            i_catch = catchment_index(mini_id, catchment_ids)
            if (i_catch == 0) cycle
            if (data_year < first_water_use_year .or. data_year > last_water_use_year) cycle
            ! Assumed-shape dummy arrays start at index 1 unless a lower bound
            ! is declared, even when the actual array uses calendar-year bounds.
            year_index = data_year - first_water_use_year + 1
            water_use_by_year(i_catch, year_index) = use_value * applied_scale
        end do
        close (file_unit)
    end subroutine load_water_use_file

    integer function catchment_index(mini_id, catchment_ids)
        implicit none
        integer, intent(in) :: mini_id
        integer, intent(in) :: catchment_ids(:)
        integer :: i_catch

        catchment_index = 0
        do i_catch = 1, size(catchment_ids)
            if (catchment_ids(i_catch) == mini_id) then
                catchment_index = i_catch
                return
            end if
        end do
    end function catchment_index

    function water_use_file_path(input_directory, file_name) result(file_path)
        implicit none
        character(len=*), intent(in) :: input_directory
        character(len=*), intent(in) :: file_name
        character(len=256) :: file_path
        logical :: file_exists

        file_path = trim(input_directory)//trim(file_name)
        inquire (file=trim(file_path), exist=file_exists)
        if (file_exists) return

        file_path = trim(file_name)
        inquire (file=trim(file_path), exist=file_exists)
        if (.not. file_exists) file_path = ''  
        !consumption_by_year = consumption_by_year * withdrawal_by_year  
        !consumption_by_year = consumption_by_year * withdrawal_by_year
    end function water_use_file_path

    subroutine apply_outlet_withdrawal(discharge, i_catch)
        use state, only: year
        implicit none
        real, intent(inout) :: discharge
        integer, intent(in) :: i_catch
        real(kind=8) :: withdrawal_rate

        if (.not. allocated(withdrawn_rate_by_catchment)) return
        withdrawal_rate = max(0.0_8, withdrawal_rate_for(i_catch, year))
        withdrawn_rate_by_catchment(i_catch) = min(max(real(discharge, kind=8), 0.0_8), withdrawal_rate)
        consumed_rate_by_catchment(i_catch) = min( &
            & max(0.0_8, consumption_rate_for(i_catch, year)), withdrawn_rate_by_catchment(i_catch))
        discharge = real(max(0.0_8, real(discharge, kind=8) - withdrawn_rate_by_catchment(i_catch)), &
                         kind=kind(discharge))
    end subroutine apply_outlet_withdrawal

    subroutine apply_outlet_return(discharge, i_catch)
        use config, only: water_use_returns_enabled
        implicit none
        real, intent(inout) :: discharge
        integer, intent(in) :: i_catch
        real(kind=8) :: return_rate

        if (water_use_returns_enabled /= 1) return
        if (.not. allocated(withdrawn_rate_by_catchment)) return
        return_rate = withdrawn_rate_by_catchment(i_catch) - consumed_rate_by_catchment(i_catch)
        discharge = discharge + real(return_rate, kind=kind(discharge))
    end subroutine apply_outlet_return

    subroutine apply_outlet_withdrawal_double(discharge, i_catch)
        use state, only: year
        implicit none
        real(kind=8), intent(inout) :: discharge
        integer, intent(in) :: i_catch
        real(kind=8) :: withdrawal_rate

        if (.not. allocated(withdrawn_rate_by_catchment)) return
        withdrawal_rate = max(0.0_8, withdrawal_rate_for(i_catch, year))
        withdrawn_rate_by_catchment(i_catch) = min(max(discharge, 0.0_8), withdrawal_rate)
        consumed_rate_by_catchment(i_catch) = min( &
            & max(0.0_8, consumption_rate_for(i_catch, year)), withdrawn_rate_by_catchment(i_catch))
        discharge = max(0.0_8, discharge - withdrawn_rate_by_catchment(i_catch))
    end subroutine apply_outlet_withdrawal_double

    subroutine apply_outlet_return_double(discharge, i_catch)
        use config, only: water_use_returns_enabled
        implicit none
        real(kind=8), intent(inout) :: discharge
        integer, intent(in) :: i_catch
        real(kind=8) :: return_rate

        if (water_use_returns_enabled /= 1) return
        if (.not. allocated(withdrawn_rate_by_catchment)) return
        return_rate = withdrawn_rate_by_catchment(i_catch) - consumed_rate_by_catchment(i_catch)
        discharge = discharge + return_rate
    end subroutine apply_outlet_return_double

    subroutine apply_inertial_withdrawal_volume(volume, i_catch, dt_route)
        use config, only: water_use_returns_enabled
        use state, only: year
        implicit none
        real(kind=8), intent(inout) :: volume
        integer, intent(in) :: i_catch
        real(kind=8), intent(in) :: dt_route
        real(kind=8) :: available_volume
        real(kind=8) :: requested_volume
        real(kind=8) :: withdrawn_volume
        real(kind=8) :: consumed_volume

        if (.not. allocated(withdrawn_rate_by_catchment)) return

        requested_volume = max(0.0_8, withdrawal_rate_for(i_catch, year))*dt_route
        available_volume = max(volume, 0.0_8)
        withdrawn_volume = min(available_volume, requested_volume)
        consumed_volume = min( &
            & max(0.0_8, consumption_rate_for(i_catch, year))*dt_route, withdrawn_volume)

        withdrawn_rate_by_catchment(i_catch) = withdrawn_volume/dt_route
        consumed_rate_by_catchment(i_catch) = consumed_volume/dt_route
        if (water_use_returns_enabled == 1) then
            volume = available_volume - consumed_volume
        else
            volume = available_volume - withdrawn_volume
        end if
    end subroutine apply_inertial_withdrawal_volume

    real(kind=8) function withdrawal_rate_for(i_catch, data_year)
        implicit none
        integer, intent(in) :: i_catch
        integer, intent(in) :: data_year

        withdrawal_rate_for = 0.0_8
        if (.not. allocated(withdrawal_by_year)) return
        if (data_year < first_water_use_year .or. data_year > last_water_use_year) return
        withdrawal_rate_for = real(withdrawal_by_year(i_catch, data_year), kind=8)
    end function withdrawal_rate_for

    real(kind=8) function consumption_rate_for(i_catch, data_year)
        implicit none
        integer, intent(in) :: i_catch
        integer, intent(in) :: data_year

        consumption_rate_for = 0.0_8
        if (.not. allocated(consumption_by_year)) return
        if (data_year < first_water_use_year .or. data_year > last_water_use_year) return
        consumption_rate_for = real(consumption_by_year(i_catch, data_year), kind=8)
    end function consumption_rate_for

end module water_use
