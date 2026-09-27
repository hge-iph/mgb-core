module static_input_io

    implicit none
    private
    public :: read_catchment_inputs, read_floodplain_inputs, read_reservoir_inputs

contains

    subroutine read_catchment_inputs
        use config, only: &
            & io_unit_log, &
            & substitution_count

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
        call read_climatology
        write (io_unit_log, *) 'Monthly climatology loaded'
        if (substitution_count > 0) call read_substitution_flows
        write (io_unit_log, *) 'Substitution flows loaded'
    end subroutine read_catchment_inputs

    subroutine read_floodplain_inputs
        implicit none

        call read_floodplain_binary_data
    end subroutine read_floodplain_inputs

    subroutine read_reservoir_inputs
        implicit none

        call read_reservoir_data
    end subroutine read_reservoir_inputs

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
        integer :: i_month
        integer :: i_cli_region
        integer :: i_catch
        integer :: i_hru
        integer :: ignored_catchment_id
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
        integer :: i_sub
        integer :: header_index
        integer :: i_hru
        real :: unused_hru_parameters(subbasin_count, hru_count)
        real :: unused_routing_parameter(subbasin_count)
        ! Specific base flow (M3/S/KM2): specific_baseflow(subbasin_count)
        max_soil_water_storage = 0.0
        b_arno = 0.0
        subsurface_conductivity = 0.0
        groundwater_conductivity = 0.0
        lambda_brooks_corey = 0.0
        unused_hru_parameters = 0.0
        surface_routing_coefficient = 0.0
        unused_routing_parameter = 0.0
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
        integer :: catchment_id(catchment_count)
        integer :: i_hru_new
        integer :: enabled_outlet_index
        integer :: input_catchment_sequence
        integer :: i_catch
        integer :: i_hru
        integer :: i_sub
        real :: max_enabled_drainage_area
        real :: redistributed_water_hru_percentage
        real :: redistributed_share

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
        write (*, *) 'Minimun tributarie lenght set to 0.001 km'
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
                                hru_percentage(i_catch, i_hru) = 100./dble(hru_count)
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

    subroutine read_climatology
        use config, only: &
            & catchment_count, &
            & io_unit_climatology, &
            & input_directory
        use forcing, only: &
            & monthly_air_pressure, &
            & monthly_air_temperature, &
            & monthly_relative_humidity, &
            & monthly_solar_input, &
            & monthly_wind_speed

        implicit none
        integer :: i_catch
        integer :: i_month
        integer :: record_index
        integer :: record_length

        !input binary file with interpolated rainfall data
        inquire (iolength=record_length) (monthly_air_temperature(i_catch, 1), i_catch=1, catchment_count)
        open (io_unit_climatology, file=input_directory//'monthly_climatology.bin', status='old', recl=record_length, &
            & form='UNFORMATTED', access='DIRECT')

        !Binary file of CRU climatology. Order of values:
        !1 - Surface Temperature        [months: 1 ... 12]
        !2 - Relative Humidity          [months: 1 ... 12]
        !3 - Radiation                  [months: 1 ... 12]
        !4 - Wind Speed                 [months: 1 ... 12]
        !5 - Atmospheric pressure       [months: 1 ... 12]

        record_index = 1
        ! Near-surface air temperature (degrees C)
        do i_month = 1, 12
            read (io_unit_climatology, rec=record_index) (monthly_air_temperature(i_catch, i_month), &
                & i_catch=1, catchment_count)
            record_index = record_index + 1
        end do

        ! near surface relative humidity (%)
        do i_month = 1, 12
            read (io_unit_climatology, rec= record_index) (monthly_relative_humidity(i_catch, i_month), &
                & i_catch=1, catchment_count)
            record_index = record_index + 1
        end do

        ! Radiation (MJ/timestep), sunshine hours, or sunshine percent according to the
        ! configuration.
        do i_month = 1, 12
            read (io_unit_climatology, rec=record_index) (monthly_solar_input(i_catch, i_month), &
                & i_catch=1, catchment_count)
            record_index = record_index + 1
        end do

        ! Wind speed (m/s)
        do i_month = 1, 12
            read (io_unit_climatology, rec=record_index) (monthly_wind_speed(i_catch, i_month), &
                & i_catch=1, catchment_count)
            record_index = record_index + 1
        end do

        ! Atmospheric pressure (kPa)
        do i_month = 1, 12
            read (io_unit_climatology, rec=record_index) (monthly_air_pressure(i_catch, i_month), &
                & i_catch=1, catchment_count)
            record_index = record_index + 1
        end do

        close (io_unit_climatology)

        return

    end subroutine read_climatology

    subroutine read_substitution_flows
        use config, only: &
            & header_fields, &
            & input_directory, &
            & substitution_count, &
            & io_unit_substitution_flow, &
            & timestep_count
        use forcing, only: substituted_q

        implicit none
        integer :: input_year
        integer :: input_month
        integer :: i_subst
        integer :: input_day
        integer :: i_step
        open (io_unit_substitution_flow, file=input_directory//'substitution_flows.txt', status='OLD')
        read (io_unit_substitution_flow, 701) (header_fields(i_subst), i_subst=1, substitution_count)
        do i_step = 1, timestep_count
            read (io_unit_substitution_flow, *) input_year, input_month, input_day, (substituted_q(i_subst, i_step), &
                & i_subst=1, substitution_count)
        end do
        close (io_unit_substitution_flow)
701     format(20a10)
        return
    end subroutine read_substitution_flows

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
        integer :: data_index
        integer :: record_index
        integer :: i_catch
        integer :: io_status
        integer :: flood_area_record_length
        integer :: flood_stage_record_length
        integer :: elevation_offset
        integer, parameter :: floodplain_elevation_increment = 1
        !Increment in floodplain is assumed to be 1m
        integer, parameter :: standard_floodplain_point_count = 100
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
        !3 - Floodplain elevations  [i = 1, 2 ... standard_floodplain_point_count] as REAL(KIND=8)

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
        integer :: connection_index
        integer :: i_catch
        integer :: io_status

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

    subroutine read_reservoir_data
        use date_time, only: calculate_integer_julian_day
        use config, only: &
            & catchment_count, &
            & input_directory, &
            & reservoir_count, &
            & timestep_count
        use forcing, only: &
            & allocate_reservoir_forcing, &
            & reservoir_outflow
        use attributes, only: &
            & floodplain_elevation, &
            & floodplain_point_count
        use parameters, only: &
            & area_table, &
            & reservoir_index_by_catchment, &
            & reservoir_start_timestep, &
            & routing_downstream_catchment, &
            & stage_table, &
            & upstream_topology, &
            & volume_table
        use state, only: &
            & day, &
            & month, &
            & year

        implicit none

        integer, parameter :: reservoir_input_unit = 159
        integer :: reservoir_lake_catchment_count
        integer :: listed_lake_catchment_count
        integer :: ignored_reservoir_code
        integer :: reservoir_index
        integer :: lake_list_index
        integer :: floodplain_point_index
        integer :: first_outflow_timestep
        integer :: i_catch
        integer :: i_step
        integer :: upstream_count
        integer :: simulate_reservoir
        integer :: disable_lake_floodplain
        integer :: any_reservoir_substitution
        integer :: data_month
        integer :: data_day
        integer :: data_year
        integer :: skipped_outflow_timesteps
        integer, dimension(catchment_count) :: reservoir_lake_catchments
        real :: incremental_volume
        real :: elevation_increment
        real*8 :: lake_volume_increment
        integer :: simulation_julian_day
        integer :: data_julian_day
        integer :: elevation_lower
        integer :: elevation_upper
        integer :: lake_range_start
        integer :: lake_range_end
        real*8 :: previous_volume
        character(len=15) :: reservoir_name

        call allocate_reservoir_forcing( &
            & timestep_count, &
            & reservoir_count)

        ! The first listed catchment is the dam location. Lake catchments have
        ! floodplain routing disabled, and upstream links terminate at the dam.
        open (reservoir_input_unit, file=input_directory//'reservoir_config.txt')

        listed_lake_catchment_count = 0
        reservoir_lake_catchments = 0
        any_reservoir_substitution = 0

        do reservoir_index = 1, reservoir_count
            ! Record: reservoir name/code, simulation and lake flags, count, catchment IDs.
            read (reservoir_input_unit, *) reservoir_name, ignored_reservoir_code, &
                & simulate_reservoir, disable_lake_floodplain, reservoir_lake_catchment_count, &
                & reservoir_lake_catchments(listed_lake_catchment_count + &
                & 1:reservoir_lake_catchment_count + listed_lake_catchment_count)

            ! A reservoir without listed catchments cannot be simulated.
            if (reservoir_lake_catchment_count == 0) then
                disable_lake_floodplain = 0
                simulate_reservoir = 0
            end if

            ! The first catchment in the record contains the dam.
            i_catch = reservoir_lake_catchments(listed_lake_catchment_count + 1)

            if (simulate_reservoir > 0) then
                reservoir_index_by_catchment(i_catch) = reservoir_index
                any_reservoir_substitution = 1

                ! Terminate the reservoir catchment and its direct upstream links.
                upstream_count = upstream_topology(i_catch, 1)
                if (upstream_count > 0) then
                    do lake_list_index = 1, upstream_count
                        routing_downstream_catchment(upstream_topology(i_catch, 1 + lake_list_index)) = -2
                    end do
                end if
                routing_downstream_catchment(i_catch) = -2
            end if

            if (disable_lake_floodplain > 0) then
                listed_lake_catchment_count = listed_lake_catchment_count + reservoir_lake_catchment_count
            else
                lake_range_start = listed_lake_catchment_count + 1
                lake_range_end = reservoir_lake_catchment_count + listed_lake_catchment_count
                reservoir_lake_catchments(lake_range_start:lake_range_end) = 0
            end if
        end do
        close (reservoir_input_unit)

        ! Treat reservoir-lake area as constant when updating its volume table.

        lake_list_index = 1
        do while (reservoir_lake_catchments(lake_list_index) > 0)

            i_catch = reservoir_lake_catchments(lake_list_index)
            area_table(3, i_catch) = area_table(2, i_catch)
            lake_volume_increment = area_table(3, i_catch)*(stage_table(3, i_catch) - stage_table(2, i_catch))*1000000.0
            volume_table(3, i_catch) = volume_table(2, i_catch) + lake_volume_increment

            ! Extend the constant-area table through all floodplain elevations.
            do floodplain_point_index = 1, floodplain_point_count(i_catch) - 1
                area_table(floodplain_point_index + 3, i_catch) = area_table(2, i_catch)
                elevation_lower = floodplain_elevation(floodplain_point_index, i_catch)
                elevation_upper = floodplain_elevation(floodplain_point_index + 1, i_catch)
                previous_volume = volume_table(floodplain_point_index + 2, i_catch)
                elevation_increment = elevation_upper - elevation_lower
                incremental_volume = elevation_increment*1000000.0*area_table(2, i_catch)
                volume_table(floodplain_point_index + 3, i_catch) = previous_volume + incremental_volume
            end do

            lake_list_index = lake_list_index + 1

        end do
        reservoir_outflow = -1
        ! Negative values mark unavailable outflow data.

        if (any_reservoir_substitution > 0) then

            ! Read the first observation date to align the series with the simulation.
            open (reservoir_input_unit, file=input_directory//'reservoir_outflow.txt')
            read (reservoir_input_unit, *) data_year, data_month, data_day
            close (reservoir_input_unit)

            simulation_julian_day = calculate_integer_julian_day(year, month, day)
            data_julian_day = calculate_integer_julian_day(data_year, data_month, data_day)
            skipped_outflow_timesteps = simulation_julian_day - data_julian_day

            first_outflow_timestep = 1
            if (skipped_outflow_timesteps < 0) then
                ! Simulation begins before observations.
                first_outflow_timestep = 1 - skipped_outflow_timesteps
                skipped_outflow_timesteps = 0
            end if

            open (reservoir_input_unit, file=input_directory//'reservoir_outflow.txt')

            ! Skip observations before the simulation period.
            do i_step = 1, skipped_outflow_timesteps
                read (reservoir_input_unit, *)
            end do

            do i_step = first_outflow_timestep, timestep_count
                read (reservoir_input_unit, *) data_year, data_month, data_day, &
                    & reservoir_outflow(i_step, :)
            end do

            close (reservoir_input_unit)

            ! Find the first available outflow for each simulated reservoir.
            reservoir_start_timestep = 1
            do i_catch = 1, catchment_count
                if (reservoir_index_by_catchment(i_catch) > 0) then
                    reservoir_index = reservoir_index_by_catchment(i_catch)
                    do i_step = 1, timestep_count
                        if (reservoir_outflow(i_step, reservoir_index) > 0) then
                            reservoir_start_timestep(i_catch) = i_step
                            exit
                        end if
                    end do
                end if
            end do
        end if

    end subroutine

end module static_input_io
