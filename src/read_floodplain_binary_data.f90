! SPDX-License-Identifier: GPL-3.0-or-later
! Copyright (C) 2019 Hidrologia de Grande Escala (HGE)

! Read binary floodplain elevation and area data.

    subroutine read_floodplain_binary_data

        use model_state
        use inertial_state
        implicit none
        integer data_index, direct_access_record, io_status
        integer, parameter :: floodplain_elevation_increment = 1
        !Increment in floodplain is assumed to be 1m
        integer, parameter :: standard_floodplain_point_count = 100
        !Standard number of elevation points in floodplain

        floodplain_point_count = standard_floodplain_point_count
        !Setting the number of floodplain elevations

        !Opening the level catchment_x flooded area files
        open (flood_stage_unit, file=input_directory//'flood_stage.bin', status='old', recl= &
              catchment_count, form='UNFORMATTED', access='DIRECT')
        !input binary file with interpolated rainfall data

        !The Structure of interpolate_stage_area.bin file is as follows:
        !2 - Water Level elevations [catchment_index = 1,2... catchment_count] as INTEGER(KIND=4)
        !3 - Floodplain elevations  [i = 1, 2 ... standard_floodplain_point_count] as REAL(KIND=8)

        direct_access_record = 1
  read (flood_stage_unit, rec=direct_access_record) (floodplain_bottom_elevation(catchment_index), &
                                                           catchment_index=1, catchment_count)
        !Fills the vegetation_height values of floodplain increment
        do catchment_index = 1, catchment_count
            do data_index = 1, standard_floodplain_point_count
                !For each point floodplain increment, computes the elevation
           floodplain_elevation(data_index, catchment_index) = int(floodplain_elevation_increment* &
                                                                        data_index) + &
                                                        floodplain_bottom_elevation(catchment_index)
                !Multiplications between Integer and Real Must be verified
            end do
        end do

        close (flood_stage_unit)
        !Close water level binary file

        !Reads the Floodplain Areas
        !Values are in real*8. RECL must be multiplied by 2
        open (flood_area_unit, file=input_directory//'flood_area.bin', status='old', recl=(2* &
                                     standard_floodplain_point_count), form='UNFORMATTED', access= &
              'DIRECT')
        !input binary file with Floodplain area

        direct_access_record = 1
        do catchment_index = 1, catchment_count
            read (flood_area_unit, rec=direct_access_record) (floodplain_area(data_index, &
                                                                   catchment_index), data_index=1, &
                                                              standard_floodplain_point_count)
            direct_access_record = direct_access_record + 1
        end do

        close (flood_area_unit)
        !Close floodplain area binary file

        ! Read lateral face connections when pseudo-2D routing is enabled.
        if (pseudo_two_d_enabled == 1) then
     open (face_connection_unit, file=input_directory//'floodplain_connections.txt', status='OLD', &
                  action='READ')

            ! Records contain the two catchment indices and their separation in metres.
            data_index = 0
            do
                read (face_connection_unit, *, iostat=io_status) face_catchment_1(data_index + 1), &
                    face_catchment_2(data_index + 1), face_distance(data_index + 1)
                if (io_status .ne. 0) exit
                data_index = data_index + 1
            end do
            close (face_connection_unit)
            face_count = data_index
        end if

        return
    end
