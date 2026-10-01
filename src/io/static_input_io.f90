module static_input_io

    use, intrinsic :: iso_fortran_env, only: int32, real32, real64
    implicit none
    private
    public :: read_catchment_inputs, read_floodplain_inputs

contains

    subroutine read_catchment_inputs
        use config, only: io_unit_log

        implicit none

        write (*, *) 'Reading vegetation parameters...'
        write (io_unit_log, *) 'Reading vegetation parameters...'
        call read_fixed_parameters
        write (*, *) 'Reading soil parameters...'
        write (io_unit_log, *) 'Reading soil parameters...'
        call read_calibrated_parameters
        write (*, *) 'Reading mini.gtp file...'
        write (io_unit_log, *) 'Reading mini.gtp file...'
        call read_catchment_data
        write (*, *) 'Reading observed discharge, substitution flows, and climate data...'
        write (io_unit_log, *) 'Reading observed discharge, substitution flows, and climate data...'
    end subroutine read_catchment_inputs

    subroutine read_floodplain_inputs
        implicit none

        call read_floodplain_binary_data
    end subroutine read_floodplain_inputs

    subroutine read_fixed_parameters
        use config, only: &
            & catchment_count, &
            & climate_region_count, &
            & io_unit_climate_region, &
            & io_unit_fixed_parameter, &
            & hru_count, &
            & input_directory
        use attributes, only: climate_region
        use parameters, only: &
            & albedo, &
            & hru_name, &
            & leaf_area_index, &
            & surface_resistance, &
            & vegetation_height
        ! File with monthly fixed parameters for each HRU.

        implicit none
        integer(int32) :: i_month
        integer(int32) :: i_cli_region
        integer(int32) :: i_catch
        integer(int32) :: i_hru
        integer(int32) :: ignored_catchment_id
        character(20) :: header_text
        character(5) :: month_labels(12)

        open (io_unit_fixed_parameter, file=input_directory//'vegetation.par', status='OLD')

        do i_cli_region = 1, climate_region_count
            ! Read albedo:
            read (io_unit_fixed_parameter, 71) header_text
            read (io_unit_fixed_parameter, 71) header_text
            !#Region
            read (io_unit_fixed_parameter, 71) header_text
            read (io_unit_fixed_parameter, 73) header_text, (month_labels(i_month), i_month=1, 12)
            do i_hru = 1, hru_count
                read (io_unit_fixed_parameter, 72) hru_name(i_hru), (albedo(i_hru, i_month, i_cli_region), &
                    & i_month=1, 12)
            end do
            ! Read leaf area index:
            read (io_unit_fixed_parameter, 71) header_text
            read (io_unit_fixed_parameter, 73) header_text, (month_labels(i_month), i_month=1, 12)
            do i_hru = 1, hru_count
                read (io_unit_fixed_parameter, 72) hru_name(i_hru), (leaf_area_index(i_hru, i_month, i_cli_region), i_month=1, 12)
            end do
            ! Read vegetation height:
            read (io_unit_fixed_parameter, 71) header_text
            read (io_unit_fixed_parameter, 73) header_text, (month_labels(i_month), i_month=1, 12)
            do i_hru = 1, hru_count
                read (io_unit_fixed_parameter, 72) hru_name(i_hru), (vegetation_height(i_hru, i_month, &
                    & i_cli_region), i_month=1, 12)
            end do
            ! Read surface resistance:
            read (io_unit_fixed_parameter, 71) header_text
            read (io_unit_fixed_parameter, 73) header_text, (month_labels(i_month), i_month=1, 12)
            do i_hru = 1, hru_count
                read (io_unit_fixed_parameter, 72) hru_name(i_hru), (surface_resistance(i_hru, i_month, &
                    & i_cli_region), i_month=1, 12)
            end do
        end do

        surface_resistance = surface_resistance*1.5
        close (io_unit_fixed_parameter)

        !Open Climate Region file
        open (io_unit_climate_region, file=input_directory//'climate.reg', status='OLD')
        read (io_unit_climate_region, 71) header_text
        do i_catch = 1, catchment_count
            read (io_unit_climate_region, 74) ignored_catchment_id, &
                & climate_region(i_catch)
        end do

71      format(a10)
72      format(a10, 12f5.2)
73      format(a10, 12a5)
74      format(2i6)

        return
    end

    subroutine read_calibrated_parameters
        use config, only: &
            & io_unit_calibrated_parameter, &
            & header_fields, &
            & hru_count, &
            & input_directory, &
            & subbasin_count
        use parameters, only: &
            & b_arno, &
            & lambda_brooks_corey, &
            & capillary_threshold_fraction, &
            & hru_name, &
            & floodplain_infiltration_rate, &
            & groundwater_conductivity, &
            & groundwater_routing_coefficient, &
            & max_capillary_flux, &
            & max_soil_water_storage, &
            & specific_baseflow, &
            & subsurface_conductivity, &
            & subsurface_routing_coefficient, &
            & surface_routing_coefficient
        ! Reads soil and routing calibration parameters.

        implicit none
        integer(int32) :: i_sub
        integer(int32) :: header_index
        integer(int32) :: i_hru

        ! Specific base flow (M3/S/KM2): specific_baseflow(subbasin_count)
        max_soil_water_storage = 0.0
        b_arno = 0.0
        subsurface_conductivity = 0.0
        groundwater_conductivity = 0.0
        lambda_brooks_corey = 0.0
        surface_routing_coefficient = 0.0
        groundwater_routing_coefficient = 0.0
        subsurface_routing_coefficient = 0.0

        open (io_unit_calibrated_parameter, file=input_directory//'soil.par', status='OLD')
        do i_sub = 1, subbasin_count
            read (io_unit_calibrated_parameter, 72) header_fields(1)
            read (io_unit_calibrated_parameter, 72) (header_fields(header_index), header_index=1, 5)
            do i_hru = 1, hru_count
                read (io_unit_calibrated_parameter, 71) hru_name(i_hru), &
                    & max_soil_water_storage(i_sub, i_hru), &
                    & b_arno(i_sub, i_hru), &
                    & groundwater_conductivity(i_sub, i_hru), &
                    & subsurface_conductivity(i_sub, i_hru), &
                    & lambda_brooks_corey(i_sub, i_hru), &
                    & max_capillary_flux(i_sub, i_hru), &
                    & capillary_threshold_fraction(i_sub, i_hru), &
                    & floodplain_infiltration_rate(i_sub, i_hru)

            end do

            read (io_unit_calibrated_parameter, 73) header_fields(1), &
                & surface_routing_coefficient(i_sub)
            read (io_unit_calibrated_parameter, 73) header_fields(2), &
                & subsurface_routing_coefficient(i_sub)
            read (io_unit_calibrated_parameter, 73) header_fields(3), &
                & groundwater_routing_coefficient(i_sub)
            read (io_unit_calibrated_parameter, 74) header_fields(4), &
                & specific_baseflow(i_sub)
        end do

        close (io_unit_calibrated_parameter)

71      format(a10, 8f8.3)
72      format(7a10)
73      format(a10, f8.1)
74      format(a10, f8.6)
        return
    end

    subroutine read_catchment_data
        use config, only: &
            & catchment_count, &
            & io_unit_catchment_data, &
            & first_subbasin, &
            & hru_count, &
            & routing_mode, &
            & input_directory, &
            & last_subbasin, &
            & routing_method
        use attributes, only: &
            & bankfull_depth, &
            & catchment_area, &
            & catchment_order, &
            & catchment_subbasin, &
            & catchment_lon, &
            & catchment_lat, &
            & downstream_catchment, &
            & drainage_area, &
            & hru_percentage, &
            & longest_reach_length, &
            & longest_reach_slope, &
            & n_manning, &
            & river_length, &
            & river_slope, &
            & river_width
        use parameters, only: &
            & max_soil_water_storage, &
            & reference_q, &
            & subbasin_outlet_catchment

        implicit none
        integer(int32) :: catchment_id(catchment_count)
        integer(int32) :: i_hru_new
        integer(int32) :: enabled_outlet_index
        integer(int32) :: input_catchment_sequence
        integer(int32) :: i_catch
        integer(int32) :: i_hru
        integer(int32) :: i_sub
        real(real32) :: max_enabled_drainage_area
        real(real32) :: redistributed_water_hru_percentage
        real(real32) :: redistributed_share

        max_enabled_drainage_area = 0.0

        open (io_unit_catchment_data, file=input_directory//'mini.gtp', status='OLD')
        read (io_unit_catchment_data, 77)

        subbasin_outlet_catchment = -999999
        do i_catch = 1, catchment_count
            read (io_unit_catchment_data, *) input_catchment_sequence, catchment_id(i_catch), &
                & catchment_lon(i_catch), catchment_lat(i_catch), &
                & catchment_subbasin(i_catch), catchment_area(i_catch), &
                & drainage_area(i_catch), river_length(i_catch), &
                & river_slope(i_catch), longest_reach_length(i_catch), &
                & longest_reach_slope(i_catch), downstream_catchment(i_catch), &
                & catchment_order(i_catch), routing_method(i_catch), &
                & river_width(i_catch), bankfull_depth(i_catch), &
                & n_manning(i_catch), (hru_percentage(i_catch, i_hru), &
                & i_hru=1, hru_count)

            reference_q(i_catch) = 0.333*drainage_area(i_catch)**0.7
            !Calculates reference initial discharge

            ! Check errors in HRU fractions:
            if (sum(hru_percentage(i_catch, :)) > 100.01 .or. &
                & sum(hru_percentage(i_catch, :)) < 99.99 .or. &
                & minval(hru_percentage(i_catch, :)) < 0.0 .or. &
                & maxval(hru_percentage(i_catch, :)) > 100.0) then
                write (*, *) 'Error in the % of HRUs in the catchments', i_catch
                write (*, *) 'Sum=', sum(hru_percentage(i_catch, :)), 'Min=', &
                    & minval(hru_percentage(i_catch, :)), 'no HRU ', &
                    & minloc(hru_percentage(i_catch, :)), 'Max=', maxval(hru_percentage(i_catch, &
                    & :)), ' at HRU', maxloc(hru_percentage(i_catch, :))
                read (*, *)
            end if
            ! Define outlet of sub-basins:
            ! Outlet equals catchment of larger ID code.
            i_sub = catchment_subbasin(i_catch)
            if (subbasin_outlet_catchment(i_sub) < &
                & catchment_id(i_catch)) &
                & subbasin_outlet_catchment(i_sub) &
                & = catchment_id(i_catch)

            ! Route catchments in disabled subbasins with the constant-slope outlet condition.
            if ((catchment_subbasin(i_catch) < first_subbasin) .or. &
                & (catchment_subbasin(i_catch) > last_subbasin)) then
                downstream_catchment(i_catch) = -1
            else
                if (drainage_area(i_catch) > max_enabled_drainage_area) then
                    enabled_outlet_index = i_catch
                    max_enabled_drainage_area = drainage_area(i_catch)
                end if
            end if

        end do

        downstream_catchment(enabled_outlet_index) = -1

        ! Sub-basins = 1
        write (*, *) ''
        write (*, *) 'Minimun reach lenght set to 2.5 km'
        ! Correct length of main river. Minimum length = 2.5 km:
        do i_catch = 1, catchment_count
            river_length(i_catch) = max(river_length(i_catch), 2.5)
        end do
        ! Change units of river slope to m/m
        write (*, *) 'Reach slopes from geometry transformed to m/m'
        river_slope = river_slope/1000.0
        ! Correct length of longest tributary:
        write (*, *) 'Minimum tributarie lenght set to 0.001 km'
        do i_catch = 1, catchment_count
            longest_reach_length(i_catch) = max(longest_reach_length(i_catch), 0.001)
        end do
        write (*, *) 'Radiation calculation is using sunshine'

        ! Redistribute the water HRU before hydrodynamic routing.
        if (routing_mode == 1) then
            write (*, *) 'Redistributing the area of HRU water to other uses'
            !read_calibrated_parameters.F90 must be called before this
            do i_catch = 1, catchment_count
                i_sub = catchment_subbasin(i_catch)
                redistributed_water_hru_percentage = 0.0
                !HRU loop
                do i_hru = 1, hru_count
                    if (max_soil_water_storage(i_sub, i_hru) < 0.001) then
                        if (hru_percentage(i_catch, i_hru) > 99.999) then
                            do i_hru_new = 1, hru_count
                                !HRUs will have the same area
                                hru_percentage(i_catch, i_hru) = 100./real(hru_count, real64)
                            end do
                        end if
                        !Eliminating HRU water
                        redistributed_water_hru_percentage = hru_percentage(i_catch, i_hru)
                        hru_percentage(i_catch, i_hru) = 0.0
                    end if
                end do
                ! Redistribute the removed water-HRU fraction among the other HRUs.
                do i_hru = 1, hru_count
                    redistributed_share = hru_percentage(i_catch, i_hru)*redistributed_water_hru_percentage
                    redistributed_share = redistributed_share/(100. - redistributed_water_hru_percentage)
                    hru_percentage(i_catch, i_hru) = hru_percentage(i_catch, i_hru) + redistributed_share
                end do
            end do
        end if

        write (*, *) ''

        close (io_unit_catchment_data)
77      format(i5, 2f15.3, i5, 2f10.1, 2i5, f10.2, f10.6, i5, 6f5.1)
        return
    end


    subroutine read_floodplain_binary_data
        use config, only: &
            & catchment_count, &
            & io_unit_face_connection, &
            & face_count, &
            & io_unit_flood_area, &
            & io_unit_flood_stage, &
            & input_directory, &
            & pseudo_2d_enabled
        use attributes, only: &
            & catchment_lon, &
            & face_catchment_1, &
            & face_catchment_2, &
            & face_distance, &
            & floodplain_area, &
            & floodplain_bottom_elevation, &
            & floodplain_elevation, &
            & floodplain_point_count
        use parameters, only: vegetation_height

        implicit none
        integer(int32) :: data_index
        integer(int32) :: record_index
        integer(int32) :: i_catch
        integer(int32) :: io_status
        integer(int32) :: flood_area_record_length
        integer(int32) :: flood_stage_record_length
        integer(int32) :: elevation_offset
        integer(int32), parameter :: floodplain_elevation_increment = 1
        !Increment in floodplain is assumed to be 1m
        integer(int32), parameter :: standard_floodplain_point_count = 100
        !Standard number of elevation points in floodplain

        floodplain_point_count = standard_floodplain_point_count
        !Setting the number of floodplain elevations

        ! Opening the flood-stage data.
        inquire (iolength=flood_stage_record_length) floodplain_bottom_elevation
        open (io_unit_flood_stage, file=input_directory//'flood_stage.bin', status='old', recl= flood_stage_record_length, &
            & form='UNFORMATTED', access='DIRECT')
        !input binary file with interpolated rainfall data

        !The Structure of interpolate_stage_area.bin file is as follows:
        !2 - Water Level elevations [i_catch = 1,2... catchment_count] as INTEGER(KIND=4)
        ! 3 - Floodplain elevations [i = 1, 2, ... standard_floodplain_point_count] as real64.

        record_index = 1
        read (io_unit_flood_stage, rec=record_index) (floodplain_bottom_elevation(i_catch), i_catch=1, catchment_count)
        !Fills the vegetation_height values of floodplain increment
        do i_catch = 1, catchment_count
            do data_index = 1, standard_floodplain_point_count
                !For each point floodplain increment, computes the elevation
                elevation_offset = int(floodplain_elevation_increment*data_index)
                floodplain_elevation(data_index, i_catch) = elevation_offset + floodplain_bottom_elevation(i_catch)
                !Multiplications between Integer and Real Must be verified
            end do
        end do

        close (io_unit_flood_stage)
        !Close water level binary file

        !Reads the Floodplain Areas
        ! Values are double precision; derive the compiler's direct-access record units.
        inquire (iolength=flood_area_record_length) floodplain_area(:, 1)
        open (io_unit_flood_area, file=input_directory//'flood_area.bin', status='old', recl= flood_area_record_length, &
            & form='UNFORMATTED', access='DIRECT')
        !input binary file with Floodplain area

        record_index = 1
        do i_catch = 1, catchment_count
            read (io_unit_flood_area, rec=record_index) (floodplain_area(data_index, i_catch), data_index=1, &
                & standard_floodplain_point_count)
            record_index = record_index + 1
        end do

        close (io_unit_flood_area)
        !Close floodplain area binary file

        ! Read lateral face connections when pseudo-2D routing is enabled.
        if (pseudo_2d_enabled == 1) then
            open (io_unit_face_connection, file=input_directory//'floodplain_connections.txt', status='OLD', action='READ')

            ! Records contain the two catchment indices and their separation in metres.
            data_index = 0
            do
                read (io_unit_face_connection, *, iostat=io_status) face_catchment_1(data_index + 1), &
                    & face_catchment_2(data_index + 1), face_distance(data_index + 1)
                if (io_status .ne. 0) exit
                data_index = data_index + 1
            end do
            close (io_unit_face_connection)
            face_count = data_index
        end if

        return
    end

    subroutine read_floodplain_text_data
        use config, only: &
            & io_unit_face_connection, &
            & face_count, &
            & input_directory, &
            & io_unit_stage_area
        use attributes, only: &
            & catchment_lon, &
            & face_catchment_1, &
            & face_catchment_2, &
            & face_distance, &
            & first_face_elevation, &
            & floodplain_area, &
            & floodplain_bottom_elevation, &
            & floodplain_elevation, &
            & floodplain_point_count, &
            & second_face_elevation

        implicit none
        integer(int32) :: connection_index
        integer(int32) :: i_catch
        integer(int32) :: io_status

        ! Opening the floodplain stage-area data.
        open (io_unit_stage_area, file=input_directory//'floodplain_stage_area.txt', status='OLD', action='READ')

        ! Reading data:
        read (io_unit_stage_area, *)
        floodplain_point_count = 0
        do
            read (io_unit_stage_area, *, iostat=io_status) i_catch, floodplain_bottom_elevation(i_catch), &
                & floodplain_elevation(floodplain_point_count(i_catch) + 1, i_catch), &
                & floodplain_area(floodplain_point_count(i_catch) + 1, i_catch)
            if (io_status .ne. 0) exit
            floodplain_point_count(i_catch) = floodplain_point_count(i_catch) + 1
        end do
        close (io_unit_stage_area)

        ! This text face-connection branch remains disabled.
        if (1 == 0) then
            open (io_unit_face_connection, file=input_directory//'floodplain_connections.txt', status='OLD', action='READ')

            ! Records contain face ID, two catchments, boundary elevations, and distance.
            connection_index = 0
            do
                read (io_unit_face_connection, *, iostat=io_status) connection_index, face_catchment_1(connection_index), &
                    & first_face_elevation(connection_index), face_catchment_2(connection_index), &
                    & second_face_elevation(connection_index), face_distance(connection_index)
                if (io_status .ne. 0) exit
            end do
            close (io_unit_face_connection)
            face_count = connection_index
        end if

        return
    end


end module static_input_io
