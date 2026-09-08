! SPDX-License-Identifier: GPL-3.0-or-later
! Copyright (C) 2019 Hidrologia de Grande Escala (HGE)

! Read monthly climatological forcing fields.

	SUBROUTINE read_climatology
	USE model_state
	IMPLICIT NONE
	INTEGER :: climate_cell_index, month_index, record_index

    !input binary file with interpolated rainfall data
    OPEN(climatology_unit,FILE=input_directory // 'medias_cru.bin',STATUS='old',RECL=catchment_count,FORM='UNFORMATTED',ACCESS='DIRECT')

    !Binary file of CRU climatology. Order of values:
    !1 - Surface Temperature        [months: 1 ... 12]
    !2 - Relative Humidity          [months: 1 ... 12]
    !3 - Radiation                  [months: 1 ... 12]
    !4 - Wind Speed                 [months: 1 ... 12]
    !5 - Atmospheric pressure       [months: 1 ... 12]

    record_index=1
	! Near-surface air temperature (degrees C)
	DO month_index=1,12
	    READ(climatology_unit,REC=record_index)(monthly_air_temperature(climate_cell_index,month_index),climate_cell_index=1,catchment_count)
        record_index=record_index+1
    ENDDO

	! near surface relative humidity (%)
	DO month_index=1,12
		READ(climatology_unit,REC=record_index)(monthly_relative_humidity(climate_cell_index,month_index),climate_cell_index=1,catchment_count)
        record_index=record_index+1
	ENDDO

	! Radiation (MJ/timestep) (can be also sunshine hours or sunshine %, check infomgb)
 	DO month_index=1,12
 	    READ(climatology_unit,REC=record_index)(monthly_solar_input(climate_cell_index,month_index),climate_cell_index=1,catchment_count)
        record_index=record_index+1
    ENDDO

	! Wind speed (m/s)
	DO month_index=1,12
		READ(climatology_unit,REC=record_index)(monthly_wind_speed(climate_cell_index,month_index),climate_cell_index=1,catchment_count)
        record_index=record_index+1
	ENDDO

	! Atmospheric pressure (kPa)
	DO month_index=1,12
		 READ(climatology_unit,REC=record_index)(monthly_air_pressure(climate_cell_index,month_index),climate_cell_index=1,catchment_count)
         record_index=record_index+1
	ENDDO

	CLOSE(climatology_unit)

	RETURN

	END SUBROUTINE read_climatology
