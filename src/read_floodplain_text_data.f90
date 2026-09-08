! SPDX-License-Identifier: GPL-3.0-or-later
! Copyright (C) 2019 Hidrologia de Grande Escala (HGE)

! Read the legacy text stage-area and face-connection data.

    SUBROUTINE read_floodplain_text_data

    USE model_state
    USE inertial_state
    IMPLICIT NONE
    integer connection_index, io_status



    !Opening the level catchment_x flooded area file
    OPEN(stage_area_unit,FILE=input_directory // 'cota_area.flp',STATUS='OLD',action='READ')

    ! Reading data:
    READ(stage_area_unit,*)
    floodplain_point_count=0
    DO
        READ(stage_area_unit,*,IOSTAT=io_status) catchment_index,floodplain_bottom_elevation(catchment_index),floodplain_elevation(floodplain_point_count(catchment_index)+1,catchment_index),floodplain_area(floodplain_point_count(catchment_index)+1,catchment_index)
        IF (io_status .NE. 0) EXIT
        floodplain_point_count(catchment_index)=floodplain_point_count(catchment_index)+1
    ENDDO
    CLOSE(stage_area_unit)

    ! This legacy branch for reading face connections remains disabled.
    if (1==0) then
    OPEN(face_connection_unit,FILE=input_directory // 'face.con',STATUS='OLD',action='READ')

    ! Records contain face ID, two catchments, boundary elevations, and distance.
    connection_index=0
    DO
        READ(face_connection_unit,*,IOSTAT=io_status) connection_index,face_catchment_1(connection_index),first_face_elevation(connection_index),face_catchment_2(connection_index),second_face_elevation(connection_index),face_distance(connection_index)
        IF (io_status .NE. 0) EXIT
    ENDDO
    CLOSE(face_connection_unit)
    face_count=connection_index
    endif


    RETURN
    END
