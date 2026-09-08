! SPDX-License-Identifier: GPL-3.0-or-later
! Copyright (C) 2019 Hidrologia de Grande Escala (HGE)

! Open or close meteorological forcing files.

	SUBROUTINE manage_meteorological_input_files(file_action)


    USE model_state
    implicit none
    integer, intent(in) :: file_action

    !input met files
    ! Open forcing streams before the timestep loop.
    if (file_action == 1) then

		!input binary file with interpolated rainfall data
		OPEN(precipitation_unit,FILE=input_directory // 'chuvabin.pbi', STATUS='old',RECL=catchment_count,FORM='UNFORMATTED',ACCESS='DIRECT')

        if (use_temperature_timeseries==1)   OPEN(temperature_unit,FILE=input_directory // 'met_temp.pbi', &
                                    STATUS='old',RECL=catchment_count,FORM='UNFORMATTED',ACCESS='DIRECT')

		if (use_radiation_timeseries==1)    OPEN(radiation_unit,FILE=input_directory // 'met_radiation.pbi', &
                                    STATUS='old',RECL=catchment_count,FORM='UNFORMATTED',ACCESS='DIRECT')

		if (use_humidity_timeseries==1)     OPEN(relative_humidity_unit,FILE=input_directory // 'met_relh.pbi', &
                                    STATUS='old',RECL=catchment_count,FORM='UNFORMATTED',ACCESS='DIRECT')

        if (use_wind_timeseries==1)   OPEN(wind_unit,FILE=input_directory // 'met_wind.pbi', &
                                    STATUS='old',RECL=catchment_count,FORM='UNFORMATTED',ACCESS='DIRECT')

        if (use_pressure_timeseries==1)   OPEN(pressure_unit,FILE=input_directory // 'met_pres.pbi', &
                                    STATUS='old',RECL=catchment_count,FORM='UNFORMATTED',ACCESS='DIRECT')

	else
		! Closing met files
		close(precipitation_unit)
		close(temperature_unit)
		close(radiation_unit)
		close(relative_humidity_unit)
		close(wind_unit)
		close(pressure_unit)

    end if

    end subroutine

