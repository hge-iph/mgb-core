! SPDX-License-Identifier: GPL-3.0-or-later
! Copyright (C) 2019 Hidrologia de Grande Escala (HGE)

! Manage output files and write selected model results.

    SUBROUTINE write_model_outputs

    USE model_state

	IMPLICIT NONE

    !Writing outputs for selected variables in configuration file
    if (write_discharge_output==1)       WRITE(discharge_output_unit,REC=timestep_index)(q_river_output(catchment_index),catchment_index=1,catchment_count)
    if (write_water_surface_elevation_output==1)        WRITE(water_surface_elevation_output_unit,REC=timestep_index)(water_surface_elevation_output(catchment_index),catchment_index=1,catchment_count)
    if (write_runoff_output==1)     WRITE(runoff_output_unit,REC=timestep_index)(catchment_q_output(catchment_index),catchment_index=1,catchment_count)
    if (write_soil_moisture_output==1)         WRITE(soil_water_output_unit,REC=timestep_index)(soil_water_output(catchment_index),catchment_index=1,catchment_count)
    if (write_soil_saturation_output==1)      WRITE(soil_saturation_output_unit,REC=timestep_index)(soil_saturation_output(catchment_index),catchment_index=1,catchment_count)
    if (write_total_water_storage_output==1)        WRITE(total_water_storage_output_unit,REC=timestep_index)(total_water_storage_output(catchment_index),catchment_index=1,catchment_count)
	if (write_hand_output==1)       WRITE(hand_output_unit,REC=timestep_index)(hand_output(catchment_index),catchment_index=1,catchment_count)
	if (write_et_output==1)         WRITE(et_output_unit,REC=timestep_index)(et_output(catchment_index),catchment_index=1,catchment_count)
	if (write_interception_et_output==1)      WRITE(interception_et_output_unit,REC=timestep_index)(interception_et_output(catchment_index),catchment_index=1,catchment_count)
	if (write_soil_vegetation_et_output==1)  WRITE(soil_vegetation_et_output_unit,REC=timestep_index)(soil_vegetation_et_output(catchment_index),catchment_index=1,catchment_count)
	if (write_open_water_et_output==1)  WRITE(open_water_et_output_unit,REC=timestep_index)(open_water_et_output(catchment_index),catchment_index=1,catchment_count)
	if (write_water_hru_et_output==1)   WRITE(water_hru_et_output_unit,REC=timestep_index)(water_hru_et_output(catchment_index),catchment_index=1,catchment_count)
    if (write_potential_open_water_et_output==1)   WRITE(potential_open_water_et_output_unit,REC=timestep_index)(potential_open_water_et_output(catchment_index),catchment_index=1,catchment_count)
	if (write_surface_water_output==1)    WRITE(surface_water_output_unit,REC=timestep_index)(surface_water_output(catchment_index),catchment_index=1,catchment_count)
	if (write_groundwater_storage_output==1)       WRITE(groundwater_storage_output_unit,REC=timestep_index)(groundwater_storage_depth_output(catchment_index),catchment_index=1,catchment_count)
	if (write_subsurface_storage_output==1)       WRITE(subsurface_storage_output_unit,REC=timestep_index)(subsurface_storage_depth_output(catchment_index),catchment_index=1,catchment_count)
	if (write_surface_storage_output==1)       WRITE(surface_storage_output_unit,REC=timestep_index)(surface_storage_depth_output(catchment_index),catchment_index=1,catchment_count)
	if (write_interception_storage_output==1)    WRITE(interception_storage_output_unit,REC=timestep_index)(interception_storage_output(catchment_index),catchment_index=1,catchment_count)
   	if (write_groundwater_flux_output==1)       WRITE(groundwater_flux_output_unit,REC=timestep_index)(groundwater_runoff_depth_output(catchment_index),catchment_index=1,catchment_count)
	if (write_subsurface_flux_output==1)       WRITE(subsurface_flux_output_unit,REC=timestep_index)(subsurface_runoff_depth_output(catchment_index),catchment_index=1,catchment_count)
	if (write_surface_flux_output==1)       WRITE(surface_flux_output_unit,REC=timestep_index)(surface_runoff_depth_output(catchment_index),catchment_index=1,catchment_count)
	if (write_flooded_area_output==1)     WRITE(flooded_area_output_unit,REC=timestep_index)(flooded_area_output(catchment_index),catchment_index=1,catchment_count)

    END SUBROUTINE

    ! Open or close the configured output streams.
    SUBROUTINE manage_output_files(file_action)

    USE model_state
    implicit none
    integer, intent(in) :: file_action

    if (file_action == 1) then
        if (write_discharge_output==1)       OPEN(discharge_output_unit,FILE=output_directory // 'qtudo.mgb', &
                                        STATUS='REPLACE',RECL=catchment_count,FORM='UNFORMATTED',ACCESS='DIRECT')

        if (write_water_surface_elevation_output==1)        OPEN(water_surface_elevation_output_unit,FILE=output_directory // 'ytudo.mgb', &
                                        STATUS='REPLACE',RECL=catchment_count,FORM='UNFORMATTED',ACCESS='DIRECT')

        if (write_runoff_output==1)     OPEN(runoff_output_unit,FILE=output_directory // 'qceltudo.mgb', &
                                        STATUS='REPLACE',RECL=catchment_count,FORM='UNFORMATTED',ACCESS='DIRECT')

        if (write_soil_moisture_output==1)         OPEN(soil_water_output_unit,FILE=output_directory // 'soilwater.mgb', &
                                        STATUS='REPLACE',RECL=catchment_count,FORM='UNFORMATTED',ACCESS='DIRECT')

        if (write_soil_saturation_output==1)      OPEN(soil_saturation_output_unit,FILE=output_directory // 'wsatdegree.mgb', &
                                        STATUS='REPLACE',RECL=catchment_count,FORM='UNFORMATTED',ACCESS='DIRECT')

        if (write_total_water_storage_output==1)        OPEN(total_water_storage_output_unit,FILE=output_directory // 'twstudo.mgb', &
                                        STATUS='REPLACE',RECL=catchment_count,FORM='UNFORMATTED',ACCESS='DIRECT')

        if (write_hand_output==1)       OPEN(hand_output_unit,FILE=output_directory // 'handtudo.mgb', &
                                        STATUS='REPLACE',RECL=catchment_count,FORM='UNFORMATTED',ACCESS='DIRECT')

        if (write_et_output==1)         OPEN(et_output_unit,FILE=output_directory // 'evaptudo.mgb', &
                                        STATUS='REPLACE',RECL=catchment_count,FORM='UNFORMATTED',ACCESS='DIRECT')

        if (write_interception_et_output==1)      OPEN(interception_et_output_unit,FILE=output_directory // 'evapinterc.mgb', &
                                        STATUS='REPLACE',RECL=catchment_count,FORM='UNFORMATTED',ACCESS='DIRECT')

        if (write_soil_vegetation_et_output==1)  OPEN(soil_vegetation_et_output_unit,FILE=output_directory // 'evapsoilplant.mgb', &
                                        STATUS='REPLACE',RECL=catchment_count,FORM='UNFORMATTED',ACCESS='DIRECT')

        if (write_open_water_et_output==1)  OPEN(open_water_et_output_unit,FILE=output_directory // 'evapopenwater.mgb', &
                                        STATUS='REPLACE',RECL=catchment_count,FORM='UNFORMATTED',ACCESS='DIRECT')

        if (write_water_hru_et_output==1)   OPEN(water_hru_et_output_unit,FILE=output_directory // 'evapurhagua.mgb',&
                                        STATUS='REPLACE', RECL=catchment_count,FORM='UNFORMATTED',ACCESS='DIRECT')

        if (write_potential_open_water_et_output==1)   OPEN(potential_open_water_et_output_unit,FILE=output_directory // 'evappotagua.mgb',&
                                        STATUS='REPLACE', RECL=catchment_count,FORM='UNFORMATTED',ACCESS='DIRECT')

        if (write_surface_water_output==1)    OPEN(surface_water_output_unit,FILE=output_directory // 'surfwater.mgb', &
                                        STATUS='REPLACE',RECL=catchment_count,FORM='UNFORMATTED',ACCESS='DIRECT')

        if (write_groundwater_storage_output==1)       OPEN(groundwater_storage_output_unit,FILE=output_directory // 'vbas.mgb', &
                                        STATUS='REPLACE',RECL=catchment_count,FORM='UNFORMATTED',ACCESS='DIRECT')

        if (write_subsurface_storage_output==1)       OPEN(subsurface_storage_output_unit,FILE=output_directory // 'vint.mgb', &
                                        STATUS='REPLACE',RECL=catchment_count,FORM='UNFORMATTED',ACCESS='DIRECT')

        if (write_surface_storage_output==1)       OPEN(surface_storage_output_unit,FILE=output_directory // 'vsup.mgb', &
                                        STATUS='REPLACE',RECL=catchment_count,FORM='UNFORMATTED',ACCESS='DIRECT')

        if (write_interception_storage_output==1)    OPEN(interception_storage_output_unit,FILE=output_directory // 'vinterc.mgb', &
                                        STATUS='REPLACE',RECL=catchment_count,FORM='UNFORMATTED',ACCESS='DIRECT')

        if (write_groundwater_flux_output==1)       OPEN(groundwater_flux_output_unit,FILE=output_directory // 'dbas.mgb', &
                                        STATUS='REPLACE',RECL=catchment_count,FORM='UNFORMATTED',ACCESS='DIRECT')

        if (write_subsurface_flux_output==1)       OPEN(subsurface_flux_output_unit,FILE=output_directory // 'dint.mgb', &
                                        STATUS='REPLACE',RECL=catchment_count,FORM='UNFORMATTED',ACCESS='DIRECT')

        if (write_surface_flux_output==1)       OPEN(surface_flux_output_unit,FILE=output_directory // 'dsup.mgb', &
                                        STATUS='REPLACE',RECL=catchment_count,FORM='UNFORMATTED',ACCESS='DIRECT')

        if (write_flooded_area_output==1)     OPEN(flooded_area_output_unit,FILE=output_directory // 'floodtudo.mgb', &
                                        STATUS='REPLACE',RECL=catchment_count,FORM='UNFORMATTED',ACCESS='DIRECT')

    else
        ! output files are being closed
        close(discharge_output_unit)
        close(water_surface_elevation_output_unit)
        close(runoff_output_unit)
        close(soil_water_output_unit)
        close(soil_saturation_output_unit)
        close(total_water_storage_output_unit)
        close(hand_output_unit)
        close(et_output_unit)
        close(interception_et_output_unit)
        close(soil_vegetation_et_output_unit)
        close(open_water_et_output_unit)
        close(water_hru_et_output_unit)
        close(potential_open_water_et_output_unit)
        close(surface_water_output_unit)
        close(groundwater_storage_output_unit)
        close(subsurface_storage_output_unit)
        close(surface_storage_output_unit)
        close(interception_storage_output_unit)
        close(groundwater_flux_output_unit)
        close(subsurface_flux_output_unit)
        close(surface_flux_output_unit)
        close(flooded_area_output_unit)

    end if

    END SUBROUTINE manage_output_files
