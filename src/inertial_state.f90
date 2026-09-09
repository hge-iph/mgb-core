! SPDX-License-Identifier: GPL-3.0-or-later
! Copyright (C) 2019 Hidrologia de Grande Escala (HGE)

! Declare shared state used by inertial routing.

module inertial_state
    implicit none
    save

    real*8 courant_alpha
    ! Courant coefficient from config.nml.
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
    real*8 current_bankfull_depth
    real*8, allocatable :: stage_table(:, :)
    real*8, allocatable :: volume_table(:, :)
    real*8, allocatable :: area_table(:, :)
    real*8 max_inertial_timestep, inertial_timestep
    real*8 remaining_model_timestep, inertial_elapsed_time
    real*8 max_water_depth
    real*8, allocatable :: inertial_q(:)
    real*8, allocatable :: upstream_q(:), current_water_volume(:), previous_water_volume(:)
    real*8 :: sum_upstream_q
    real*8, allocatable :: current_flooded_area(:)
    real*8, allocatable :: water_depth(:), water_surface_elevation(:)

    ! Shared work variables used inside OpenMP routing regions.
    real*8 first_bed_elevation, first_water_surface_elevation
    real*8 second_bed_elevation, second_water_surface_elevation, flow_slope, flow_depth
    real*8 flow_length, flow_width, previous_unit_width_q, q, flow_manning_n
    real*8 overland_flow_width, overland_manning_n
    !Parameters for lateral connections, considering overland flow
    real*8 downstream_water_surface_slope
    integer downstream_catchment_index

    integer upstream_count
    real*8 updated_water_surface_elevation

    integer :: face_count, face_index, first_face_catchment_index, second_face_catchment_index
    real*8, allocatable :: face_catchment_1(:), face_catchment_2(:), face_q(:)
    real*8, allocatable :: first_face_elevation(:), second_face_elevation(:), face_distance(:), &
                           neighbor_q(:)
    integer, allocatable :: stage_table_index(:)

    real, allocatable :: floodplain_infiltration(:)
    !INFILTRATION FROM FLOODPLAIN TO SOIL
    real current_floodplain_infiltration
    !INFILTRATION FROM FLOODPLAIN TO SOIL

    real*8 interpolated_area, interpolated_stage
    real*8, allocatable :: grace_total_water_storage(:)
    !For comparison to GRACE data

    integer write_hotstart_mode, read_hotstart_mode
    !Flag for writing or reading hotstart values

    real(kind=8), dimension(:, :), allocatable :: reservoir_outflow

end module inertial_state
