! SPDX-License-Identifier: GPL-3.0-or-later
! Copyright (C) 2019 Hidrologia de Grande Escala (HGE)

! Read text stage-area and face-connection data.

    subroutine read_floodplain_text_data

        use model_state
        use inertial_state
        implicit none
        integer connection_index, io_status

        !Opening the level catchment_x flooded area file
   open (stage_area_unit, file=input_directory//'floodplain_stage_area.txt', status='OLD', action= &
              'READ')

        ! Reading data:
        read (stage_area_unit, *)
        floodplain_point_count = 0
        do
            read (stage_area_unit, *, iostat=io_status) catchment_index, &
                floodplain_bottom_elevation(catchment_index), &
               floodplain_elevation(floodplain_point_count(catchment_index) + 1, catchment_index), &
                floodplain_area(floodplain_point_count(catchment_index) + 1, catchment_index)
            if (io_status .ne. 0) exit
            floodplain_point_count(catchment_index) = floodplain_point_count(catchment_index) + 1
        end do
        close (stage_area_unit)

        ! This text face-connection branch remains disabled.
        if (1 == 0) then
     open (face_connection_unit, file=input_directory//'floodplain_connections.txt', status='OLD', &
                  action='READ')

            ! Records contain face ID, two catchments, boundary elevations, and distance.
            connection_index = 0
            do
                read (face_connection_unit, *, iostat=io_status) connection_index, &
                    face_catchment_1(connection_index), first_face_elevation(connection_index), &
                    face_catchment_2(connection_index), second_face_elevation(connection_index), &
                    face_distance(connection_index)
                if (io_status .ne. 0) exit
            end do
            close (face_connection_unit)
            face_count = connection_index
        end if

        return
    end
