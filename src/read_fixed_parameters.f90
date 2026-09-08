! SPDX-License-Identifier: GPL-3.0-or-later
! Copyright (C) 2019 Hidrologia de Grande Escala (HGE)

! Read fixed monthly vegetation parameters and climate regions.

	SUBROUTINE read_fixed_parameters
	! File with fixed parameters for each HRU (ALBEDOS, IAF, surface_resistance, vegetation_height; mounthly) (File: albiaf.fix)
	USE model_state
	IMPLICIT NONE
	INTEGER :: month_index, climate_region_index_loop, catchment_record_index
    INTEGER :: ignored_catchment_id
	CHARACTER(20) :: header_text
	CHARACTER(5) :: month_labels(12)
	OPEN(fixed_parameter_unit,FILE=input_directory // 'albiaf.fix',STATUS='OLD')

    DO climate_region_index_loop=1,climate_region_count
        ! Read albedo:
        READ(fixed_parameter_unit,71)header_text
	    READ(fixed_parameter_unit,71)header_text !#Region
        READ(fixed_parameter_unit,71)header_text
	    READ(fixed_parameter_unit,73)header_text,(month_labels(month_index),month_index=1,12)
	    DO hru_index=1,hru_count
	    	READ(fixed_parameter_unit,72)hru_name(hru_index),(albedo(hru_index,month_index,climate_region_index_loop),month_index=1,12)
	    ENDDO
	    ! Read leaf area index:
	    READ(fixed_parameter_unit,71)header_text
	    READ(fixed_parameter_unit,73)header_text,(month_labels(month_index),month_index=1,12)
	    DO hru_index=1,hru_count
	    	READ(fixed_parameter_unit,72)hru_name(hru_index),(leaf_area_index(hru_index,month_index,climate_region_index_loop),month_index=1,12)
	    ENDDO
	    ! Read vegetation height:
	    READ(fixed_parameter_unit,71)header_text
	    READ(fixed_parameter_unit,73)header_text,(month_labels(month_index),month_index=1,12)
	    DO hru_index=1,hru_count
	    	READ(fixed_parameter_unit,72)hru_name(hru_index),(vegetation_height(hru_index,month_index,climate_region_index_loop),month_index=1,12)
	    ENDDO
	    ! Read surface resistance:
	    READ(fixed_parameter_unit,71)header_text
	    READ(fixed_parameter_unit,73)header_text,(month_labels(month_index),month_index=1,12)
	    DO hru_index=1,hru_count
	    	READ(fixed_parameter_unit,72)hru_name(hru_index),(surface_resistance(hru_index,month_index,climate_region_index_loop),month_index=1,12)
        ENDDO
    END DO

    surface_resistance=surface_resistance*1.5
    CLOSE(fixed_parameter_unit)

    !Open Climate Region file
    OPEN(climate_region_unit,FILE=input_directory // 'climate_regions.fix',STATUS='OLD')
    READ(climate_region_unit,71)header_text
    DO catchment_record_index=1,catchment_count
        READ(climate_region_unit,74)ignored_catchment_id,climate_region(catchment_record_index)
    END DO


71  FORMAT(A10)
72	FORMAT(A10,12F5.2)
73  FORMAT(A10,12A5)
74  FORMAT(2I6)

	RETURN
	END
