! SPDX-License-Identifier: GPL-3.0-or-later
! Copyright (C) 2019 Hidrologia de Grande Escala (HGE)

! Read catchment topology, geometry, and HRU fractions from mini.gtp.

	SUBROUTINE read_catchment_data
	USE model_state
	USE inertial_state
	IMPLICIT NONE
	INTEGER :: catchment_id(catchment_count)
	INTEGER :: catchment_record_index, hru_input_index, current_subbasin, secondary_hru_index
	INTEGER :: enabled_outlet_index, input_catchment_sequence
	REAL :: max_enabled_drainage_area, redistributed_water_hru_percentage

    max_enabled_drainage_area=0.0

	! Opens mini.gtp:
	OPEN(catchment_data_unit,FILE=input_directory // 'mini.gtp',STATUS='OLD')
	READ(catchment_data_unit,77)
	subbasin_outlet_catchment=-999999
	DO catchment_record_index=1,catchment_count
		READ(catchment_data_unit,*) input_catchment_sequence, catchment_id(catchment_record_index), &
			catchment_x(catchment_record_index), catchment_y(catchment_record_index), &
			catchment_subbasin(catchment_record_index), catchment_area(catchment_record_index), &
			drainage_area(catchment_record_index), river_length(catchment_record_index), &
			river_slope(catchment_record_index), longest_reach_length(catchment_record_index), &
			longest_reach_slope(catchment_record_index), downstream_catchment(catchment_record_index), &
			catchment_order(catchment_record_index), routing_method(catchment_record_index), &
			river_width(catchment_record_index), bankfull_depth(catchment_record_index), &
			manning_n(catchment_record_index), &
			(hru_percentage(catchment_record_index,hru_input_index),hru_input_index=1,hru_count)


        reference_q(catchment_record_index)=0.333*drainage_area(catchment_record_index)**0.7 !Calculates reference initial discharge

		inertial_manning_n(catchment_record_index)=manning_n(catchment_record_index) !Reads inertial model subroutines manning

		! Check errors in HRU fractions:
		if (sum(hru_percentage(catchment_record_index,:))>100.01.or. &
			sum(hru_percentage(catchment_record_index,:))<99.99.or. &
			minval(hru_percentage(catchment_record_index,:))<0.0.or. &
			maxval(hru_percentage(catchment_record_index,:))>100.0) then
			write(*,*) 'Error in the % of HRUs in the catchments',catchment_record_index
			write(*,*) 'Sum=',sum(hru_percentage(catchment_record_index,:)),'Min=',minval(hru_percentage(catchment_record_index,:)),'no HRU ',minloc(hru_percentage(catchment_record_index,:)),'Max=',maxval(hru_percentage(catchment_record_index,:)),' at HRU',maxloc(hru_percentage(catchment_record_index,:))
			read(*,*)
		endif
		! Define outlet of sub-basins:
		! Outlet equals catchment of larger ID code.
		current_subbasin=catchment_subbasin(catchment_record_index)
		IF(subbasin_outlet_catchment(current_subbasin)<catchment_id(catchment_record_index)) subbasin_outlet_catchment(current_subbasin)=catchment_id(catchment_record_index)

        ! Route catchments in disabled subbasins with the constant-slope outlet condition.
        IF((catchment_subbasin(catchment_record_index)<first_subbasin).OR.(catchment_subbasin(catchment_record_index)>last_subbasin))then
            downstream_catchment(catchment_record_index)=-1
        else
           IF(drainage_area(catchment_record_index)>max_enabled_drainage_area)then
            enabled_outlet_index=catchment_record_index
            max_enabled_drainage_area=drainage_area(catchment_record_index)
           End if
        End if

    ENDDO

    downstream_catchment(enabled_outlet_index)=-1

	! Sub-basins = 1
	write(*,*)''
	write(*,*)'Minimun reach lenght set to 2.5 km'
	! Correct length of main river. Minimum length = 2.5 km:
	do catchment_index=1,catchment_count
		river_length(catchment_index)=max(river_length(catchment_index),2.5)
	enddo
	! Change units of river slope to m/m
	write(*,*)'Reach slopes from geometry transformed to m/m'
	river_slope=river_slope/1000.0
	! Correct length of longest tributary:
	write(*,*)'Minimun tributarie lenght set to 0.001 km'
	do catchment_index=1,catchment_count
		longest_reach_length(catchment_index)=max(longest_reach_length(catchment_index),0.001)
	enddo
	write(*,*)'Radiation calculation is using sunshine'

    ! Redistribute the water HRU before hydrodynamic routing.
    if(inertial_routing_enabled==1) then
    write(*,*)'Redistributing the area of HRU water to other uses'
    !read_calibrated_parameters.F90 must be called before this
        do catchment_index=1,catchment_count
            subbasin_index=catchment_subbasin(catchment_index)
            redistributed_water_hru_percentage=0.0
            !HRU loop
            do hru_index=1,hru_count
                if(max_soil_water_storage(subbasin_index,hru_index)<0.001) then
                    if(hru_percentage(catchment_index,hru_index)>99.999) then
                        do secondary_hru_index=1,hru_count
                            !HRUs will have the same area
                            hru_percentage(catchment_index,hru_index)=100./DBLE(hru_count)
                        enddo
                    endif
                    !Eliminating HRU water
                    redistributed_water_hru_percentage=hru_percentage(catchment_index,hru_index)
                    hru_percentage(catchment_index,hru_index)=0.0
                endif
            enddo
            ! Redistribute the removed water-HRU fraction among the other HRUs.
            do hru_index=1,hru_count
                hru_percentage(catchment_index,hru_index)=hru_percentage(catchment_index,hru_index)+hru_percentage(catchment_index,hru_index)*redistributed_water_hru_percentage/(100.-redistributed_water_hru_percentage)
            enddo
        enddo
    endif

	write(*,*)''

	CLOSE (catchment_data_unit)
77	FORMAT(I5,2F15.3,I5,2F10.1,2I5,F10.2,F10.6,I5,6F5.1)
	RETURN
	END
