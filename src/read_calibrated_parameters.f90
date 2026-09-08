! SPDX-License-Identifier: GPL-3.0-or-later
! Copyright (C) 2019 Hidrologia de Grande Escala (HGE)

! Read calibrated HRU and routing parameters from paruso.cal.

	SUBROUTINE read_calibrated_parameters
	! Reads file with calibration parameters (File: paruso.cal)
	USE model_state
	IMPLICIT NONE
	INTEGER :: current_subbasin, header_index
	REAL :: unused_hru_parameters(subbasin_count,hru_count)
	REAL :: unused_routing_parameter(subbasin_count)
	! Specific base flow (M3/S/KM2): specific_baseflow(subbasin_count)
	max_soil_water_storage=0.0
	arno_b=0.0
	subsurface_conductivity=0.0
	groundwater_conductivity=0.0
	brooks_corey_lambda=0.0
	unused_hru_parameters=0.0
	surface_routing_coefficient=0.0
	unused_routing_parameter=0.0
	groundwater_routing_coefficient=0.0
	subsurface_routing_coefficient=0.0
	OPEN(calibrated_parameter_unit,FILE=input_directory // 'paruso.cal',STATUS='OLD')
	DO current_subbasin=1,subbasin_count
		READ(calibrated_parameter_unit,72)header_fields(1)
		READ(calibrated_parameter_unit,72)(header_fields(header_index),header_index=1,5)
		DO hru_index=1,hru_count
			READ(calibrated_parameter_unit,71) hru_name(hru_index), &
				max_soil_water_storage(current_subbasin,hru_index), &
				arno_b(current_subbasin,hru_index), &
				groundwater_conductivity(current_subbasin,hru_index), &
				subsurface_conductivity(current_subbasin,hru_index), &
				brooks_corey_lambda(current_subbasin,hru_index), &
				max_capillary_flux(current_subbasin,hru_index), &
				capillary_threshold_fraction(current_subbasin,hru_index), &
				floodplain_infiltration_rate(current_subbasin,hru_index)

		ENDDO
		READ(calibrated_parameter_unit,73)header_fields(1),surface_routing_coefficient(current_subbasin)
		READ(calibrated_parameter_unit,73)header_fields(2),subsurface_routing_coefficient(current_subbasin)
		READ(calibrated_parameter_unit,73)header_fields(3),groundwater_routing_coefficient(current_subbasin)
		READ(calibrated_parameter_unit,74)header_fields(4),specific_baseflow(current_subbasin)
	ENDDO
	CLOSE (calibrated_parameter_unit)
71	FORMAT(A10,8F8.3)
72	FORMAT(7A10)
73	FORMAT(A10,F8.1)
74	FORMAT(A10,F8.6)
	RETURN
	END
