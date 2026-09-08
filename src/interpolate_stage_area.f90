! SPDX-License-Identifier: GPL-3.0-or-later
! Copyright (C) 2019 Hidrologia de Grande Escala (HGE)

! Interpolate water level and flooded area from stored volume.

SUBROUTINE interpolate_stage_area(current_water_volume,volume_table,stage_table_index, &
    target_catchment_index,stage_table,area_table,floodplain_point_count, &
    catchment_count_argument,interpolated_stage,interpolated_area)

    implicit none

    INTEGER, INTENT(IN) :: target_catchment_index, catchment_count_argument
    INTEGER, INTENT(IN) :: floodplain_point_count(catchment_count_argument)
    INTEGER, INTENT(INOUT) :: stage_table_index(catchment_count_argument)
    REAL(KIND=8), INTENT(IN) :: current_water_volume(catchment_count_argument)
    REAL(KIND=8), INTENT(IN) :: volume_table(102,catchment_count_argument)
    REAL(KIND=8), INTENT(IN) :: stage_table(102,catchment_count_argument)
    REAL(KIND=8), INTENT(IN) :: area_table(102,catchment_count_argument)
    REAL(KIND=8), INTENT(OUT) :: interpolated_stage
    REAL(KIND=8), INTENT(OUT) :: interpolated_area
    REAL(KIND=8) :: interpolation_fraction

	do
	   if(  (current_water_volume(target_catchment_index)>=volume_table( stage_table_index(target_catchment_index) ,target_catchment_index) )   .AND.   ( current_water_volume(target_catchment_index) <= volume_table( stage_table_index(target_catchment_index)+1 ,target_catchment_index))   )then

			!Finds the % over the actual index of stage-area-volume table:
	        interpolation_fraction = (current_water_volume(target_catchment_index) - volume_table( stage_table_index(target_catchment_index) ,target_catchment_index))/(volume_table( stage_table_index(target_catchment_index)+1 ,target_catchment_index) - volume_table( stage_table_index(target_catchment_index) ,target_catchment_index))
			!Interpolates values based on % above:
	        interpolated_stage=stage_table( stage_table_index(target_catchment_index) ,target_catchment_index)+(stage_table( stage_table_index(target_catchment_index)+1 ,target_catchment_index)-stage_table( stage_table_index(target_catchment_index) ,target_catchment_index))* interpolation_fraction
	        interpolated_area=area_table( stage_table_index(target_catchment_index) ,target_catchment_index)+(area_table( stage_table_index(target_catchment_index)+1 ,target_catchment_index)-area_table( stage_table_index(target_catchment_index) ,target_catchment_index))* interpolation_fraction

			exit

	   elseif(current_water_volume(target_catchment_index)>volume_table( stage_table_index(target_catchment_index)+1 ,target_catchment_index))then
	        stage_table_index(target_catchment_index)=stage_table_index(target_catchment_index)+1

			!Check for outside (upper) table bounds
	        if(stage_table_index(target_catchment_index)>(floodplain_point_count(target_catchment_index)+1))then

				!In this case, an extrapolation is needed. We consider a constant flooded area over the upper bound in stage_table
				!Calculates the difference (dV) between the actual volume and max volume of stage-area-volume table
				!Level is computed as Zmax + dV/Amax, where A is assumed to be constant in this interval.

	            interpolated_stage = stage_table( stage_table_index(target_catchment_index) ,target_catchment_index) + (current_water_volume(target_catchment_index) - volume_table( stage_table_index(target_catchment_index) ,target_catchment_index)) / (area_table( stage_table_index(target_catchment_index) ,target_catchment_index)*1000000.0)
				!interpolated_area remains unchanged
	            interpolated_area=area_table( stage_table_index(target_catchment_index) ,target_catchment_index)

				!Avoids access violation of array upper bounds (when calling for this subroutine again)
	            stage_table_index(target_catchment_index)=stage_table_index(target_catchment_index)-1
                exit !Exit subroutine %Vinicius Siqueira, 27/12/2016
	        endif

	   else
	        stage_table_index(target_catchment_index)=stage_table_index(target_catchment_index)-1
	   endif


    enddo

	END SUBROUTINE interpolate_stage_area
