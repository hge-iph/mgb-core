module output_io

    use, intrinsic :: iso_fortran_env, only: int32
    implicit none
    private
    public :: open_model_outputs, write_model_outputs, close_model_outputs

contains

    subroutine open_model_outputs
        implicit none

        call manage_output_files( &
            & 1)
    end subroutine open_model_outputs

    subroutine close_model_outputs
        implicit none

        call manage_output_files( &
            & 0)
    end subroutine close_model_outputs

    subroutine write_model_outputs( &
        & i_step)
        use config, only: &
            & catchment_count, &
            & io_unit_discharge_output, &
            & io_unit_et_output, &
            & io_unit_flooded_area_output, &
            & io_unit_groundwater_flux_output, &
            & io_unit_groundwater_storage_output, &
            & io_unit_hand_output, &
            & io_unit_interception_et_output, &
            & io_unit_interception_storage_output, &
            & io_unit_open_water_et_output, &
            & io_unit_potential_open_water_et_output, &
            & io_unit_runoff_output, &
            & io_unit_soil_saturation_output, &
            & io_unit_soil_vegetation_et_output, &
            & io_unit_soil_water_output, &
            & io_unit_subsurface_flux_output, &
            & io_unit_subsurface_storage_output, &
            & io_unit_surface_flux_output, &
            & io_unit_surface_storage_output, &
            & io_unit_surface_water_output, &
            & io_unit_total_water_storage_output, &
            & io_unit_water_hru_et_output, &
            & io_unit_water_surface_elevation_output, &
            & write_discharge, &
            & write_evapotranspiration, &
            & write_flooded_area, &
            & write_groundwater_flux, &
            & write_groundwater_storage, &
            & write_flooded_level, &
            & write_interception_evaporation, &
            & write_interception_storage, &
            & write_open_water_evaporation, &
            & write_potential_open_water_evaporation, &
            & write_runoff, &
            & write_soil_water, &
            & write_soil_saturation, &
            & write_soil_vegetation_evapotranspiration, &
            & write_subsurface_flux, &
            & write_subsurface_storage, &
            & write_surface_flux, &
            & write_surface_storage, &
            & write_surface_water, &
            & write_total_water_storage, &
            & write_water_hru_evaporation, &
            & write_water_surface_elevation
        use state, only: &
            & catchment_q_output, &
            & et_output, &
            & flooded_area_output, &
            & groundwater_runoff_depth_output, &
            & groundwater_storage_depth_output, &
            & hand_output, &
            & interception_et_output, &
            & interception_storage_output, &
            & open_water_et_output, &
            & potential_open_water_et_output, &
            & q_river_output, &
            & soil_saturation_output, &
            & soil_vegetation_et_output, &
            & soil_water_output, &
            & subsurface_runoff_depth_output, &
            & subsurface_storage_depth_output, &
            & surface_runoff_depth_output, &
            & surface_storage_depth_output, &
            & surface_water_output, &
            & total_water_storage_output, &
            & water_hru_et_output, &
            & water_surface_elevation_output

        implicit none

        integer(int32), intent(in) :: i_step
        integer(int32) :: i_catch

        !Writing outputs for selected variables in configuration file
        if (write_discharge == 1) &
            & write (io_unit_discharge_output, rec=i_step) (q_river_output(i_catch), i_catch=1, catchment_count)

        if (write_water_surface_elevation == 1) &
            & write (io_unit_water_surface_elevation_output, rec=i_step) (water_surface_elevation_output(i_catch), &
            & i_catch=1, catchment_count)

        if (write_runoff == 1) &
            & write (io_unit_runoff_output, rec=i_step) (catchment_q_output(i_catch), i_catch=1, catchment_count)

        if (write_soil_water == 1) &
            & write (io_unit_soil_water_output, rec=i_step) (soil_water_output(i_catch), i_catch=1, catchment_count)

        if (write_soil_saturation == 1) &
            & write (io_unit_soil_saturation_output, rec=i_step) (soil_saturation_output(i_catch), i_catch=1, catchment_count)

        if (write_total_water_storage == 1) &
            & write (io_unit_total_water_storage_output, rec=i_step) (total_water_storage_output(i_catch), &
            & i_catch=1, catchment_count)

        if (write_flooded_level == 1) &
            & write (io_unit_hand_output, rec=i_step) (hand_output(i_catch), i_catch=1, catchment_count)

        if (write_evapotranspiration == 1) &
            & write (io_unit_et_output, rec=i_step) (et_output(i_catch), i_catch=1, catchment_count)

        if (write_interception_evaporation == 1) &
            & write (io_unit_interception_et_output, rec=i_step) (interception_et_output(i_catch), &
            & i_catch=1, catchment_count)

        if (write_soil_vegetation_evapotranspiration == 1) &
            & write (io_unit_soil_vegetation_et_output, rec=i_step) (soil_vegetation_et_output(i_catch), &
            & i_catch=1, catchment_count)

        if (write_open_water_evaporation == 1) &
            & write (io_unit_open_water_et_output, rec=i_step) (open_water_et_output(i_catch), i_catch=1, catchment_count)

        if (write_water_hru_evaporation == 1) &
            & write (io_unit_water_hru_et_output, rec=i_step) (water_hru_et_output(i_catch), i_catch=1, catchment_count)

        if (write_potential_open_water_evaporation == 1) &
            & write (io_unit_potential_open_water_et_output, rec=i_step) (potential_open_water_et_output(i_catch), &
            & i_catch=1, catchment_count)

        if (write_surface_water == 1) &
            & write (io_unit_surface_water_output, rec=i_step) (surface_water_output(i_catch), i_catch=1, catchment_count)

        if (write_groundwater_storage == 1) &
            & write (io_unit_groundwater_storage_output, rec=i_step) (groundwater_storage_depth_output(i_catch), &
            & i_catch=1, catchment_count)

        if (write_subsurface_storage == 1) &
            & write (io_unit_subsurface_storage_output, rec=i_step) (subsurface_storage_depth_output(i_catch), &
            & i_catch=1, catchment_count)

        if (write_surface_storage == 1) &
            & write (io_unit_surface_storage_output, rec=i_step) (surface_storage_depth_output(i_catch), &
            & i_catch=1, catchment_count)

        if (write_interception_storage == 1) &
            & write (io_unit_interception_storage_output, rec=i_step) (interception_storage_output(i_catch), &
            & i_catch=1, catchment_count)

        if (write_groundwater_flux == 1) &
            & write (io_unit_groundwater_flux_output, rec=i_step) (groundwater_runoff_depth_output(i_catch), &
            & i_catch=1, catchment_count)

        if (write_subsurface_flux == 1) &
            & write (io_unit_subsurface_flux_output, rec=i_step) (subsurface_runoff_depth_output(i_catch), &
            & i_catch=1, catchment_count)

        if (write_surface_flux == 1) &
            & write (io_unit_surface_flux_output, rec=i_step) (surface_runoff_depth_output(i_catch), &
            & i_catch=1, catchment_count)

        if (write_flooded_area == 1) &
            & write (io_unit_flooded_area_output, rec=i_step) (flooded_area_output(i_catch), i_catch=1, catchment_count)

    end subroutine

    ! Open or close the configured output streams.
    subroutine manage_output_files( &
        & file_action)

        use config, only: &
            & catchment_count, &
            & io_unit_discharge_output, &
            & io_unit_et_output, &
            & io_unit_flooded_area_output, &
            & io_unit_groundwater_flux_output, &
            & io_unit_groundwater_storage_output, &
            & io_unit_hand_output, &
            & io_unit_interception_et_output, &
            & io_unit_interception_storage_output, &
            & io_unit_open_water_et_output, &
            & output_directory, &
            & io_unit_potential_open_water_et_output, &
            & io_unit_runoff_output, &
            & io_unit_soil_saturation_output, &
            & io_unit_soil_vegetation_et_output, &
            & io_unit_soil_water_output, &
            & io_unit_subsurface_flux_output, &
            & io_unit_subsurface_storage_output, &
            & io_unit_surface_flux_output, &
            & io_unit_surface_storage_output, &
            & io_unit_surface_water_output, &
            & io_unit_total_water_storage_output, &
            & io_unit_water_hru_et_output, &
            & io_unit_water_surface_elevation_output, &
            & write_discharge, &
            & write_evapotranspiration, &
            & write_flooded_area, &
            & write_groundwater_flux, &
            & write_groundwater_storage, &
            & write_flooded_level, &
            & write_interception_evaporation, &
            & write_interception_storage, &
            & write_open_water_evaporation, &
            & write_potential_open_water_evaporation, &
            & write_runoff, &
            & write_soil_water, &
            & write_soil_saturation, &
            & write_soil_vegetation_evapotranspiration, &
            & write_subsurface_flux, &
            & write_subsurface_storage, &
            & write_surface_flux, &
            & write_surface_storage, &
            & write_surface_water, &
            & write_total_water_storage, &
            & write_water_hru_evaporation, &
            & write_water_surface_elevation
        use state, only: q_river_output

        implicit none
        integer(int32), intent(in) :: file_action
        integer(int32) :: record_length

        if (file_action == 1) then
            inquire (iolength=record_length) q_river_output(1:catchment_count)
            if (write_discharge == 1) open (io_unit_discharge_output, file= &
                & output_directory//'discharge.bin', status='REPLACE', recl=record_length, form= &
                & 'UNFORMATTED', access='DIRECT')

            if (write_water_surface_elevation == 1) &
                & open (io_unit_water_surface_elevation_output, file=output_directory//'level.bin', &
                & status='REPLACE', recl=record_length, form='UNFORMATTED', access='DIRECT')

            if (write_runoff == 1) open (io_unit_runoff_output, file= &
                & output_directory//'runoff.bin', status='REPLACE', recl=record_length, form= &
                & 'UNFORMATTED', access='DIRECT')

            if (write_soil_water == 1) open (io_unit_soil_water_output, file= &
                & output_directory//'soil_water.bin', status='REPLACE', recl=record_length, form= &
                & 'UNFORMATTED', access='DIRECT')

            if (write_soil_saturation == 1) open (io_unit_soil_saturation_output, file= &
                & output_directory//'soil_saturation.bin', status='REPLACE', recl=record_length, &
                & form='UNFORMATTED', access='DIRECT')

            if (write_total_water_storage == 1) open (io_unit_total_water_storage_output, &
                & file=output_directory//'total_water_storage.bin', status='REPLACE', recl= &
                & record_length, form='UNFORMATTED', access='DIRECT')

            if (write_flooded_level == 1) open (io_unit_hand_output, file= &
                & output_directory//'flooded_level.bin', status='REPLACE', recl=record_length, &
                & form='UNFORMATTED', access='DIRECT')

            if (write_evapotranspiration == 1) open (io_unit_et_output, file= &
                & output_directory//'evapotranspiration.bin', status='REPLACE', recl= &
                & record_length, form='UNFORMATTED', access='DIRECT')

            if (write_interception_evaporation == 1) open (io_unit_interception_et_output, file= &
                & output_directory//'interception_evaporation.bin', status='REPLACE', recl= &
                & record_length, form='UNFORMATTED', access='DIRECT')

            if (write_soil_vegetation_evapotranspiration == 1) open (io_unit_soil_vegetation_et_output, file= &
                & output_directory//'soil_vegetation_evapotranspiration.bin', status='REPLACE', &
                & recl=record_length, form='UNFORMATTED', access='DIRECT')

            if (write_open_water_evaporation == 1) open (io_unit_open_water_et_output, file= &
                & output_directory//'open_water_evaporation.bin', status='REPLACE', recl= &
                & record_length, form='UNFORMATTED', access='DIRECT')

            if (write_water_hru_evaporation == 1) open (io_unit_water_hru_et_output, file= &
                & output_directory//'water_hru_evaporation.bin', status='REPLACE', recl= &
                & record_length, form='UNFORMATTED', access='DIRECT')

            if (write_potential_open_water_evaporation == 1) &
                & open (io_unit_potential_open_water_et_output, file= &
                & output_directory//'potential_open_water_evaporation.bin', status='REPLACE', &
                & recl=record_length, form='UNFORMATTED', access='DIRECT')

            if (write_surface_water == 1) open (io_unit_surface_water_output, file= &
                & output_directory//'surface_water.bin', status='REPLACE', recl=record_length, &
                & form='UNFORMATTED', access='DIRECT')

            if (write_groundwater_storage == 1) open (io_unit_groundwater_storage_output, &
                & file=output_directory//'groundwater_storage.bin', status='REPLACE', recl= &
                & record_length, form='UNFORMATTED', access='DIRECT')

            if (write_subsurface_storage == 1) open (io_unit_subsurface_storage_output, file= &
                & output_directory//'subsurface_storage.bin', status='REPLACE', recl= &
                & record_length, form='UNFORMATTED', access='DIRECT')

            if (write_surface_storage == 1) open (io_unit_surface_storage_output, file= &
                & output_directory//'surface_storage.bin', status='REPLACE', recl=record_length, &
                & form='UNFORMATTED', access='DIRECT')

            if (write_interception_storage == 1) open (io_unit_interception_storage_output, &
                & file=output_directory//'interception_storage.bin', status='REPLACE', recl= &
                & record_length, form='UNFORMATTED', access='DIRECT')

            if (write_groundwater_flux == 1) open (io_unit_groundwater_flux_output, file= &
                & output_directory//'groundwater_flux.bin', status='REPLACE', recl=record_length, &
                & form='UNFORMATTED', access='DIRECT')

            if (write_subsurface_flux == 1) open (io_unit_subsurface_flux_output, file= &
                & output_directory//'subsurface_flux.bin', status='REPLACE', recl=record_length, &
                & form='UNFORMATTED', access='DIRECT')

            if (write_surface_flux == 1) open (io_unit_surface_flux_output, file= &
                & output_directory//'surface_flux.bin', status='REPLACE', recl=record_length, &
                & form='UNFORMATTED', access='DIRECT')

            if (write_flooded_area == 1) open (io_unit_flooded_area_output, file= &
                & output_directory//'flooded_area.bin', status='REPLACE', recl=record_length, &
                & form='UNFORMATTED', access='DIRECT')

        else
            ! output files are being closed
            close (io_unit_discharge_output)
            close (io_unit_water_surface_elevation_output)
            close (io_unit_runoff_output)
            close (io_unit_soil_water_output)
            close (io_unit_soil_saturation_output)
            close (io_unit_total_water_storage_output)
            close (io_unit_hand_output)
            close (io_unit_et_output)
            close (io_unit_interception_et_output)
            close (io_unit_soil_vegetation_et_output)
            close (io_unit_open_water_et_output)
            close (io_unit_water_hru_et_output)
            close (io_unit_potential_open_water_et_output)
            close (io_unit_surface_water_output)
            close (io_unit_groundwater_storage_output)
            close (io_unit_subsurface_storage_output)
            close (io_unit_surface_storage_output)
            close (io_unit_interception_storage_output)
            close (io_unit_groundwater_flux_output)
            close (io_unit_subsurface_flux_output)
            close (io_unit_surface_flux_output)
            close (io_unit_flooded_area_output)

        end if

    end subroutine manage_output_files

end module output_io
