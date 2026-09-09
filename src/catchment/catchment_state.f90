module catchment_state

    implicit none
    private
    save

    public :: catchment_area, catchment_count, catchment_index, catchment_order, &
            catchment_subbasin, catchment_x, catchment_y, catchments_per_subbasin, climate_region, &
              current_catchment_area, current_river_width, downstream_catchment, drainage_area, &
              hru_count, hru_index, hru_name, hru_percentage, longest_reach_length, &
              longest_reach_slope, max_hru_count, max_subbasin_count, river_length, river_slope, &
              river_width, subbasin_count, subbasin_index, subbasin_outlet_catchment, &
              allocate_catchment_state, deallocate_catchment_state

    integer, parameter :: max_hru_count = 12
    integer, parameter :: max_subbasin_count = 505
    integer catchment_count, hru_count
    integer subbasin_count
    integer, allocatable :: catchments_per_subbasin(:)
    character(10) hru_name(max_hru_count)
    integer, allocatable :: subbasin_outlet_catchment(:)
    real, allocatable :: river_width(:)
    real current_river_width
    integer, allocatable :: catchment_subbasin(:), downstream_catchment(:)
    real, allocatable :: longest_reach_slope(:), longest_reach_length(:)
    real, allocatable :: catchment_x(:), catchment_y(:)
    integer, allocatable :: climate_region(:)
    real, allocatable :: catchment_area(:), drainage_area(:), river_length(:), river_slope(:)
    real, allocatable :: hru_percentage(:, :)
    integer catchment_index
    integer subbasin_index, hru_index
    integer, allocatable :: catchment_order(:)
    real current_catchment_area

contains

    subroutine allocate_catchment_state()
        allocate (catchments_per_subbasin(subbasin_count))
        allocate (hru_percentage(catchment_count, hru_count))
        allocate (catchment_area(catchment_count))
        allocate (drainage_area(catchment_count))
        allocate (river_length(catchment_count))
        allocate (river_slope(catchment_count))
        allocate (catchment_x(catchment_count))
        allocate (catchment_y(catchment_count))
        allocate (climate_region(catchment_count))
        allocate (catchment_subbasin(catchment_count))
        allocate (longest_reach_slope(catchment_count))
        allocate (longest_reach_length(catchment_count))
        allocate (downstream_catchment(catchment_count))
        allocate (river_width(catchment_count))
        allocate (subbasin_outlet_catchment(subbasin_count))
        allocate (catchment_order(catchment_count))
    end subroutine allocate_catchment_state

    subroutine deallocate_catchment_state
        if (allocated(catchment_order)) deallocate (catchment_order)
        if (allocated(subbasin_outlet_catchment)) deallocate (subbasin_outlet_catchment)
        if (allocated(river_width)) deallocate (river_width)
        if (allocated(downstream_catchment)) deallocate (downstream_catchment)
        if (allocated(longest_reach_length)) deallocate (longest_reach_length)
        if (allocated(longest_reach_slope)) deallocate (longest_reach_slope)
        if (allocated(catchment_subbasin)) deallocate (catchment_subbasin)
        if (allocated(climate_region)) deallocate (climate_region)
        if (allocated(catchment_y)) deallocate (catchment_y)
        if (allocated(catchment_x)) deallocate (catchment_x)
        if (allocated(river_slope)) deallocate (river_slope)
        if (allocated(river_length)) deallocate (river_length)
        if (allocated(drainage_area)) deallocate (drainage_area)
        if (allocated(catchment_area)) deallocate (catchment_area)
        if (allocated(hru_percentage)) deallocate (hru_percentage)
        if (allocated(catchments_per_subbasin)) deallocate (catchments_per_subbasin)
    end subroutine deallocate_catchment_state

end module catchment_state
