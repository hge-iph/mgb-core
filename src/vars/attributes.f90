module attributes

    implicit none
    save

    real, allocatable :: river_width(:)
    integer, allocatable :: catchment_subbasin(:)
    integer, allocatable :: downstream_catchment(:)
    real, allocatable :: longest_reach_slope(:)
    real, allocatable :: longest_reach_length(:)
    real, allocatable :: catchment_lon(:)
    real, allocatable :: catchment_lat(:)
    integer, allocatable :: climate_region(:)
    real, allocatable :: catchment_area(:)
    real, allocatable :: drainage_area(:)
    real, allocatable :: river_length(:)
    real, allocatable :: river_slope(:)
    real, allocatable :: hru_percentage(:, :)
    integer, allocatable :: catchment_order(:)
    real, allocatable :: n_manning(:)

    integer, allocatable :: floodplain_point_count(:)
    integer, allocatable :: floodplain_bottom_elevation(:)
    integer, allocatable :: floodplain_elevation(:, :)
    real*8, allocatable :: floodplain_area(:, :)
    real*8, allocatable :: bankfull_depth(:)
    real*8, allocatable :: face_catchment_1(:)
    real*8, allocatable :: face_catchment_2(:)
    real*8, allocatable :: first_face_elevation(:)
    real*8, allocatable :: second_face_elevation(:)
    real*8, allocatable :: face_distance(:)

contains

    subroutine allocate_attributes( &
        & catchment_count, &
        & hru_count)
        integer, intent(in) :: catchment_count
        integer, intent(in) :: hru_count

        allocate (river_width(catchment_count))
        allocate (catchment_subbasin(catchment_count))
        allocate (downstream_catchment(catchment_count))
        allocate (longest_reach_slope(catchment_count))
        allocate (longest_reach_length(catchment_count))
        allocate (catchment_lon(catchment_count))
        allocate (catchment_lat(catchment_count))
        allocate (climate_region(catchment_count))
        allocate (catchment_area(catchment_count))
        allocate (drainage_area(catchment_count))
        allocate (river_length(catchment_count))
        allocate (river_slope(catchment_count))
        allocate (hru_percentage(catchment_count, hru_count))
        allocate (catchment_order(catchment_count))
        allocate (n_manning(catchment_count))

        allocate (floodplain_point_count(catchment_count))
        allocate (floodplain_bottom_elevation(catchment_count))
        allocate (floodplain_elevation(100, catchment_count))
        allocate (floodplain_area(100, catchment_count))
        allocate (bankfull_depth(catchment_count))
        allocate (face_catchment_1(catchment_count))
        allocate (face_catchment_2(catchment_count))
        allocate (first_face_elevation(catchment_count))
        allocate (second_face_elevation(catchment_count))
        allocate (face_distance(catchment_count))
    end subroutine allocate_attributes

    subroutine deallocate_attributes
        if (allocated(face_distance)) deallocate (face_distance)
        if (allocated(second_face_elevation)) deallocate (second_face_elevation)
        if (allocated(first_face_elevation)) deallocate (first_face_elevation)
        if (allocated(face_catchment_2)) deallocate (face_catchment_2)
        if (allocated(face_catchment_1)) deallocate (face_catchment_1)
        if (allocated(bankfull_depth)) deallocate (bankfull_depth)
        if (allocated(floodplain_area)) deallocate (floodplain_area)
        if (allocated(floodplain_elevation)) deallocate (floodplain_elevation)
        if (allocated(floodplain_bottom_elevation)) deallocate (floodplain_bottom_elevation)
        if (allocated(floodplain_point_count)) deallocate (floodplain_point_count)

        if (allocated(n_manning)) deallocate (n_manning)
        if (allocated(catchment_order)) deallocate (catchment_order)
        if (allocated(hru_percentage)) deallocate (hru_percentage)
        if (allocated(river_slope)) deallocate (river_slope)
        if (allocated(river_length)) deallocate (river_length)
        if (allocated(drainage_area)) deallocate (drainage_area)
        if (allocated(catchment_area)) deallocate (catchment_area)
        if (allocated(climate_region)) deallocate (climate_region)
        if (allocated(catchment_lat)) deallocate (catchment_lat)
        if (allocated(catchment_lon)) deallocate (catchment_lon)
        if (allocated(longest_reach_length)) deallocate (longest_reach_length)
        if (allocated(longest_reach_slope)) deallocate (longest_reach_slope)
        if (allocated(downstream_catchment)) deallocate (downstream_catchment)
        if (allocated(catchment_subbasin)) deallocate (catchment_subbasin)
        if (allocated(river_width)) deallocate (river_width)
    end subroutine deallocate_attributes

end module attributes
