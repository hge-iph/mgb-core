module output_io

    implicit none
    private
    public :: open_model_log, open_model_outputs, write_model_outputs, close_model_outputs, &
        & close_model_log

contains

    subroutine open_model_log
        use io_state, only: log_unit, output_directory

        implicit none

        open (log_unit, file=output_directory//'model.log', status='UNKNOWN')
    end subroutine open_model_log

    subroutine close_model_log
        use io_state, only: log_unit

        implicit none

        close (log_unit)
    end subroutine close_model_log

    subroutine open_model_outputs
        implicit none

        call manage_output_files(1)
    end subroutine open_model_outputs

    subroutine close_model_outputs
        implicit none

        call manage_output_files(0)
    end subroutine close_model_outputs

    subroutine write_model_outputs
        use simulation_state, only: timestep_index
        use runoff_state, only: catchment_count, catchment_index
        use evapotranspiration_state, only: evapotranspiration, interception_storage
        use runoff_state, only: groundwater_storage, subsurface_storage, surface_storage, &
            & total_water_storage
        use io_state, only: discharge_output_unit, et_output_unit, flooded_area_output_unit, &
            & groundwater_flux_output_unit, groundwater_storage_output_unit, hand_output_unit, &
            & interception_et_output_unit, interception_storage_output_unit, &
            & open_water_et_output_unit, output_directory, potential_open_water_et_output_unit, &
            & runoff_output_unit, soil_saturation_output_unit, soil_vegetation_et_output_unit, &
            & soil_water_output_unit, subsurface_flux_output_unit, subsurface_storage_output_unit, &
            & surface_flux_output_unit, surface_storage_output_unit, surface_water_output_unit, &
            & total_water_storage_output_unit, water_hru_et_output_unit, &
            & water_surface_elevation_output_unit
        use output_state, only: catchment_q_output, et_output, flooded_area_output, &
            & groundwater_runoff_depth_output, groundwater_storage_depth_output, hand_output, &
            & interception_et_output, interception_storage_output, open_water_et_output, &
            & potential_open_water_et_output, q_river_output, soil_saturation_output, &
            & soil_vegetation_et_output, soil_water_output, subsurface_runoff_depth_output, &
            & subsurface_storage_depth_output, surface_runoff_depth_output, &
            & surface_storage_depth_output, surface_water_output, total_water_storage_output, &
            & water_hru_et_output, water_surface_elevation_output, write_discharge_output, &
            & write_et_output, write_flooded_area_output, write_groundwater_flux_output, &
            & write_groundwater_storage_output, write_hand_output, write_interception_et_output, &
            & write_interception_storage_output, write_open_water_et_output, &
            & write_potential_open_water_et_output, write_runoff_output, &
            & write_soil_moisture_output, write_soil_saturation_output, &
            & write_soil_vegetation_et_output, write_subsurface_flux_output, &
            & write_subsurface_storage_output, write_surface_flux_output, &
            & write_surface_storage_output, write_surface_water_output, &
            & write_total_water_storage_output, write_water_hru_et_output, &
            & write_water_surface_elevation_output

        implicit none

        !Writing outputs for selected variables in configuration file
        if (write_discharge_output == 1) write (discharge_output_unit, rec= &
            & timestep_index) (q_river_output(catchment_index), catchment_index=1, catchment_count)
        if (write_water_surface_elevation_output == 1) write (water_surface_elevation_output_unit, &
            & rec=timestep_index) (water_surface_elevation_output(catchment_index), &
            & catchment_index=1, catchment_count)
        if (write_runoff_output == 1) write (runoff_output_unit, rec= &
            & timestep_index) (catchment_q_output(catchment_index), catchment_index=1, &
            & catchment_count)
        if (write_soil_moisture_output == 1) write (soil_water_output_unit, rec= &
            & timestep_index) (soil_water_output(catchment_index), catchment_index=1, &
            & catchment_count)
        if (write_soil_saturation_output == 1) write (soil_saturation_output_unit, rec= &
            & timestep_index) (soil_saturation_output(catchment_index), catchment_index=1, &
            & catchment_count)
        if (write_total_water_storage_output == 1) write (total_water_storage_output_unit, rec= &
            & timestep_index) (total_water_storage_output(catchment_index), catchment_index=1, &
            & catchment_count)
        if (write_hand_output == 1) write (hand_output_unit, rec= &
            & timestep_index) (hand_output(catchment_index), catchment_index=1, catchment_count)
        if (write_et_output == 1) write (et_output_unit, rec= &
            & timestep_index) (et_output(catchment_index), catchment_index=1, catchment_count)
        if (write_interception_et_output == 1) write (interception_et_output_unit, rec= &
            & timestep_index) (interception_et_output(catchment_index), catchment_index=1, &
            & catchment_count)
        if (write_soil_vegetation_et_output == 1) write (soil_vegetation_et_output_unit, rec= &
            & timestep_index) (soil_vegetation_et_output(catchment_index), catchment_index=1, &
            & catchment_count)
        if (write_open_water_et_output == 1) write (open_water_et_output_unit, rec= &
            & timestep_index) (open_water_et_output(catchment_index), catchment_index=1, &
            & catchment_count)
        if (write_water_hru_et_output == 1) write (water_hru_et_output_unit, rec= &
            & timestep_index) (water_hru_et_output(catchment_index), catchment_index=1, &
            & catchment_count)
        if (write_potential_open_water_et_output == 1) write (potential_open_water_et_output_unit, &
            & rec=timestep_index) (potential_open_water_et_output(catchment_index), &
            & catchment_index=1, catchment_count)
        if (write_surface_water_output == 1) write (surface_water_output_unit, rec= &
            & timestep_index) (surface_water_output(catchment_index), catchment_index=1, &
            & catchment_count)
        if (write_groundwater_storage_output == 1) write (groundwater_storage_output_unit, rec= &
            & timestep_index) (groundwater_storage_depth_output(catchment_index), catchment_index= &
            & 1, catchment_count)
        if (write_subsurface_storage_output == 1) write (subsurface_storage_output_unit, rec= &
            & timestep_index) (subsurface_storage_depth_output(catchment_index), catchment_index= &
            & 1, catchment_count)
        if (write_surface_storage_output == 1) write (surface_storage_output_unit, rec= &
            & timestep_index) (surface_storage_depth_output(catchment_index), catchment_index=1, &
            & catchment_count)
        if (write_interception_storage_output == 1) write (interception_storage_output_unit, rec= &
            & timestep_index) (interception_storage_output(catchment_index), catchment_index=1, &
            & catchment_count)
        if (write_groundwater_flux_output == 1) write (groundwater_flux_output_unit, rec= &
            & timestep_index) (groundwater_runoff_depth_output(catchment_index), catchment_index= &
            & 1, catchment_count)
        if (write_subsurface_flux_output == 1) write (subsurface_flux_output_unit, rec= &
            & timestep_index) (subsurface_runoff_depth_output(catchment_index), catchment_index=1, &
            & catchment_count)
        if (write_surface_flux_output == 1) write (surface_flux_output_unit, rec= &
            & timestep_index) (surface_runoff_depth_output(catchment_index), catchment_index=1, &
            & catchment_count)
        if (write_flooded_area_output == 1) write (flooded_area_output_unit, rec= &
            & timestep_index) (flooded_area_output(catchment_index), catchment_index=1, &
            & catchment_count)

    end subroutine

    ! Open or close the configured output streams.
    subroutine manage_output_files(file_action)

        use runoff_state, only: catchment_count
        use io_state, only: discharge_output_unit, et_output_unit, flooded_area_output_unit, &
            & groundwater_flux_output_unit, groundwater_storage_output_unit, hand_output_unit, &
            & interception_et_output_unit, interception_storage_output_unit, &
            & open_water_et_output_unit, output_directory, potential_open_water_et_output_unit, &
            & runoff_output_unit, soil_saturation_output_unit, soil_vegetation_et_output_unit, &
            & soil_water_output_unit, subsurface_flux_output_unit, subsurface_storage_output_unit, &
            & surface_flux_output_unit, surface_storage_output_unit, surface_water_output_unit, &
            & total_water_storage_output_unit, water_hru_et_output_unit, &
            & water_surface_elevation_output_unit
        use output_state, only: q_river_output, write_discharge_output, write_et_output, &
            & write_flooded_area_output, write_groundwater_flux_output, &
            & write_groundwater_storage_output, write_hand_output, write_interception_et_output, &
            & write_interception_storage_output, write_open_water_et_output, &
            & write_potential_open_water_et_output, write_runoff_output, &
            & write_soil_moisture_output, write_soil_saturation_output, &
            & write_soil_vegetation_et_output, write_subsurface_flux_output, &
            & write_subsurface_storage_output, write_surface_flux_output, &
            & write_surface_storage_output, write_surface_water_output, &
            & write_total_water_storage_output, write_water_hru_et_output, &
            & write_water_surface_elevation_output

        implicit none
        integer, intent(in) :: file_action
        integer :: record_length

        if (file_action == 1) then
            inquire (iolength=record_length) q_river_output(1:catchment_count)
            if (write_discharge_output == 1) open (discharge_output_unit, file= &
                & output_directory//'discharge.bin', status='REPLACE', recl=record_length, form= &
                & 'UNFORMATTED', access='DIRECT')

            if (write_water_surface_elevation_output == 1) &
                & open (water_surface_elevation_output_unit, file=output_directory//'level.bin', &
                & status='REPLACE', recl=record_length, form='UNFORMATTED', access='DIRECT')

            if (write_runoff_output == 1) open (runoff_output_unit, file= &
                & output_directory//'runoff.bin', status='REPLACE', recl=record_length, form= &
                & 'UNFORMATTED', access='DIRECT')

            if (write_soil_moisture_output == 1) open (soil_water_output_unit, file= &
                & output_directory//'soil_water.bin', status='REPLACE', recl=record_length, form= &
                & 'UNFORMATTED', access='DIRECT')

            if (write_soil_saturation_output == 1) open (soil_saturation_output_unit, file= &
                & output_directory//'soil_saturation.bin', status='REPLACE', recl=record_length, &
                & form='UNFORMATTED', access='DIRECT')

            if (write_total_water_storage_output == 1) open (total_water_storage_output_unit, &
                & file=output_directory//'total_water_storage.bin', status='REPLACE', recl= &
                & record_length, form='UNFORMATTED', access='DIRECT')

            if (write_hand_output == 1) open (hand_output_unit, file= &
                & output_directory//'flooded_level.bin', status='REPLACE', recl=record_length, &
                & form='UNFORMATTED', access='DIRECT')

            if (write_et_output == 1) open (et_output_unit, file= &
                & output_directory//'evapotranspiration.bin', status='REPLACE', recl= &
                & record_length, form='UNFORMATTED', access='DIRECT')

            if (write_interception_et_output == 1) open (interception_et_output_unit, file= &
                & output_directory//'interception_evaporation.bin', status='REPLACE', recl= &
                & record_length, form='UNFORMATTED', access='DIRECT')

            if (write_soil_vegetation_et_output == 1) open (soil_vegetation_et_output_unit, file= &
                & output_directory//'soil_vegetation_evapotranspiration.bin', status='REPLACE', &
                & recl=record_length, form='UNFORMATTED', access='DIRECT')

            if (write_open_water_et_output == 1) open (open_water_et_output_unit, file= &
                & output_directory//'open_water_evaporation.bin', status='REPLACE', recl= &
                & record_length, form='UNFORMATTED', access='DIRECT')

            if (write_water_hru_et_output == 1) open (water_hru_et_output_unit, file= &
                & output_directory//'water_hru_evaporation.bin', status='REPLACE', recl= &
                & record_length, form='UNFORMATTED', access='DIRECT')

            if (write_potential_open_water_et_output == 1) &
                & open (potential_open_water_et_output_unit, file= &
                & output_directory//'potential_open_water_evaporation.bin', status='REPLACE', &
                & recl=record_length, form='UNFORMATTED', access='DIRECT')

            if (write_surface_water_output == 1) open (surface_water_output_unit, file= &
                & output_directory//'surface_water.bin', status='REPLACE', recl=record_length, &
                & form='UNFORMATTED', access='DIRECT')

            if (write_groundwater_storage_output == 1) open (groundwater_storage_output_unit, &
                & file=output_directory//'groundwater_storage.bin', status='REPLACE', recl= &
                & record_length, form='UNFORMATTED', access='DIRECT')

            if (write_subsurface_storage_output == 1) open (subsurface_storage_output_unit, file= &
                & output_directory//'subsurface_storage.bin', status='REPLACE', recl= &
                & record_length, form='UNFORMATTED', access='DIRECT')

            if (write_surface_storage_output == 1) open (surface_storage_output_unit, file= &
                & output_directory//'surface_storage.bin', status='REPLACE', recl=record_length, &
                & form='UNFORMATTED', access='DIRECT')

            if (write_interception_storage_output == 1) open (interception_storage_output_unit, &
                & file=output_directory//'interception_storage.bin', status='REPLACE', recl= &
                & record_length, form='UNFORMATTED', access='DIRECT')

            if (write_groundwater_flux_output == 1) open (groundwater_flux_output_unit, file= &
                & output_directory//'groundwater_flux.bin', status='REPLACE', recl=record_length, &
                & form='UNFORMATTED', access='DIRECT')

            if (write_subsurface_flux_output == 1) open (subsurface_flux_output_unit, file= &
                & output_directory//'subsurface_flux.bin', status='REPLACE', recl=record_length, &
                & form='UNFORMATTED', access='DIRECT')

            if (write_surface_flux_output == 1) open (surface_flux_output_unit, file= &
                & output_directory//'surface_flux.bin', status='REPLACE', recl=record_length, &
                & form='UNFORMATTED', access='DIRECT')

            if (write_flooded_area_output == 1) open (flooded_area_output_unit, file= &
                & output_directory//'flooded_area.bin', status='REPLACE', recl=record_length, &
                & form='UNFORMATTED', access='DIRECT')

        else
            ! output files are being closed
            close (discharge_output_unit)
            close (water_surface_elevation_output_unit)
            close (runoff_output_unit)
            close (soil_water_output_unit)
            close (soil_saturation_output_unit)
            close (total_water_storage_output_unit)
            close (hand_output_unit)
            close (et_output_unit)
            close (interception_et_output_unit)
            close (soil_vegetation_et_output_unit)
            close (open_water_et_output_unit)
            close (water_hru_et_output_unit)
            close (potential_open_water_et_output_unit)
            close (surface_water_output_unit)
            close (groundwater_storage_output_unit)
            close (subsurface_storage_output_unit)
            close (surface_storage_output_unit)
            close (interception_storage_output_unit)
            close (groundwater_flux_output_unit)
            close (subsurface_flux_output_unit)
            close (surface_flux_output_unit)
            close (flooded_area_output_unit)

        end if

    end subroutine manage_output_files

end module output_io
