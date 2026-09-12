module inertial_state

    implicit none
    private
    save

    public :: area_table, bankfull_depth, courant_alpha, current_flooded_area, &
        & current_water_volume, downstream_water_surface_slope, face_catchment_1, &
        & face_catchment_2, face_count, face_distance, face_q, first_face_elevation, &
        & floodplain_area, floodplain_bottom_elevation, floodplain_elevation, &
        & floodplain_point_count, grace_total_water_storage, gravity, &
        & inertial_catchment_count, inertial_manning_n, inertial_q, inertial_routing_enabled, &
        & neighbor_q, &
        & overland_flow_width, overland_manning_n, previous_water_volume, pseudo_two_d_enabled, &
        & routing_method, second_face_elevation, stage_table, stage_table_index, thread_count, &
        & upstream_q, upstream_topology, &
        & volume_table, water_depth, water_surface_elevation, allocate_inertial_state, &
        & deallocate_inertial_state

    integer inertial_routing_enabled
    integer pseudo_two_d_enabled
    real*8 courant_alpha
    real*8, parameter :: gravity = 9.81
    real*8, allocatable :: inertial_manning_n(:)
    integer thread_count
    integer, allocatable :: routing_method(:)
    integer inertial_catchment_count
    integer, allocatable :: upstream_topology(:, :)
    integer, allocatable :: floodplain_point_count(:)
    integer, allocatable :: floodplain_bottom_elevation(:)
    integer, allocatable :: floodplain_elevation(:, :)
    real*8, allocatable :: floodplain_area(:, :)
    real*8, allocatable :: bankfull_depth(:)
    real*8, allocatable :: stage_table(:, :)
    real*8, allocatable :: volume_table(:, :)
    real*8, allocatable :: area_table(:, :)
    real*8, allocatable :: inertial_q(:)
    real*8, allocatable :: upstream_q(:), current_water_volume(:), previous_water_volume(:)
    real*8, allocatable :: current_flooded_area(:)
    real*8, allocatable :: water_depth(:), water_surface_elevation(:)
    real*8 downstream_water_surface_slope
    real*8 overland_flow_width, overland_manning_n
    integer :: face_count
    real*8, allocatable :: face_catchment_1(:), face_catchment_2(:), face_q(:)
    real*8, allocatable :: first_face_elevation(:), second_face_elevation(:), face_distance(:)
    real*8, allocatable :: neighbor_q(:)
    integer, allocatable :: stage_table_index(:)
    real*8, allocatable :: grace_total_water_storage(:)

contains

    subroutine allocate_inertial_state(requested_catchment_count)
        integer, intent(in) :: requested_catchment_count
        allocate (routing_method(requested_catchment_count))
        allocate (upstream_topology(requested_catchment_count, 10))
        allocate (floodplain_point_count(requested_catchment_count))
        allocate (floodplain_bottom_elevation(requested_catchment_count))
        allocate (floodplain_elevation(100, requested_catchment_count))
        allocate (floodplain_area(100, requested_catchment_count))
        allocate (bankfull_depth(requested_catchment_count))
        allocate (stage_table(102, requested_catchment_count))
        allocate (volume_table(102, requested_catchment_count))
        allocate (area_table(102, requested_catchment_count))
        allocate (inertial_q(requested_catchment_count))
        allocate (upstream_q(3))
        allocate (current_water_volume(requested_catchment_count))
        allocate (previous_water_volume(requested_catchment_count))
        allocate (current_flooded_area(requested_catchment_count))
        allocate (water_depth(requested_catchment_count))
        allocate (water_surface_elevation(requested_catchment_count))
        allocate (face_catchment_1(requested_catchment_count))
        allocate (face_catchment_2(requested_catchment_count))
        allocate (first_face_elevation(requested_catchment_count))
        allocate (second_face_elevation(requested_catchment_count))
        allocate (face_distance(requested_catchment_count))
        allocate (face_q(requested_catchment_count))
        allocate (neighbor_q(requested_catchment_count))
        allocate (stage_table_index(requested_catchment_count))
        allocate (inertial_manning_n(requested_catchment_count))
        allocate (grace_total_water_storage(requested_catchment_count))
    end subroutine allocate_inertial_state

    subroutine deallocate_inertial_state
        if (allocated(grace_total_water_storage)) deallocate (grace_total_water_storage)
        if (allocated(inertial_manning_n)) deallocate (inertial_manning_n)
        if (allocated(stage_table_index)) deallocate (stage_table_index)
        if (allocated(neighbor_q)) deallocate (neighbor_q)
        if (allocated(face_q)) deallocate (face_q)
        if (allocated(face_distance)) deallocate (face_distance)
        if (allocated(second_face_elevation)) deallocate (second_face_elevation)
        if (allocated(first_face_elevation)) deallocate (first_face_elevation)
        if (allocated(face_catchment_2)) deallocate (face_catchment_2)
        if (allocated(face_catchment_1)) deallocate (face_catchment_1)
        if (allocated(water_surface_elevation)) deallocate (water_surface_elevation)
        if (allocated(water_depth)) deallocate (water_depth)
        if (allocated(current_flooded_area)) deallocate (current_flooded_area)
        if (allocated(previous_water_volume)) deallocate (previous_water_volume)
        if (allocated(current_water_volume)) deallocate (current_water_volume)
        if (allocated(upstream_q)) deallocate (upstream_q)
        if (allocated(inertial_q)) deallocate (inertial_q)
        if (allocated(area_table)) deallocate (area_table)
        if (allocated(volume_table)) deallocate (volume_table)
        if (allocated(stage_table)) deallocate (stage_table)
        if (allocated(bankfull_depth)) deallocate (bankfull_depth)
        if (allocated(floodplain_area)) deallocate (floodplain_area)
        if (allocated(floodplain_elevation)) deallocate (floodplain_elevation)
        if (allocated(floodplain_bottom_elevation)) deallocate (floodplain_bottom_elevation)
        if (allocated(floodplain_point_count)) deallocate (floodplain_point_count)
        if (allocated(upstream_topology)) deallocate (upstream_topology)
        if (allocated(routing_method)) deallocate (routing_method)
    end subroutine deallocate_inertial_state

end module inertial_state
