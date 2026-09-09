! SPDX-License-Identifier: GPL-3.0-or-later

module static_input_io

    implicit none
    private
    public :: read_catchment_inputs, read_floodplain_inputs, read_reservoir_inputs

contains

    subroutine read_catchment_inputs
        use io_state, only: log_unit
        use reservoir_state, only: substitution_count

        implicit none

        write (*, *) 'Reading vegetation parameters...'
        write (log_unit, *) 'Reading vegetation parameters...'
        call read_fixed_parameters
        write (*, *) 'Reading soil parameters...'
        write (log_unit, *) 'Reading soil parameters...'
        call read_calibrated_parameters
        write (*, *) 'Reading mini.gtp file...'
        write (log_unit, *) 'Reading mini.gtp file...'
        call read_catchment_data
        write (*, *) 'Reading observed discharge, substitution flows, and climate data...'
        write (log_unit, *) 'Reading observed discharge, substitution flows, and climate data...'
        call read_climatology
        write (log_unit, *) 'Monthly climatology loaded'
        if (substitution_count > 0) call read_substitution_flows
        write (log_unit, *) 'Substitution flows loaded'
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
        use catchment_state, only: catchment_count, climate_region, hru_count, hru_index, &
                                   hru_name
        use meteorological_state, only: climate_region_count
        use water_balance_state, only: albedo, leaf_area_index, surface_resistance, &
                                       vegetation_height
        use io_state, only: climate_region_unit, fixed_parameter_unit, input_directory
        ! File with monthly fixed parameters for each HRU.

        implicit none
        integer :: month_index, climate_region_index_loop, catchment_record_index
        integer :: ignored_catchment_id
        character(20) :: header_text
        character(5) :: month_labels(12)
        open (fixed_parameter_unit, file=input_directory//'vegetation.par', status= &
              'OLD')

        do climate_region_index_loop = 1, climate_region_count
            ! Read albedo:
            read (fixed_parameter_unit, 71) header_text
            read (fixed_parameter_unit, 71) header_text
            !#Region
            read (fixed_parameter_unit, 71) header_text
           read (fixed_parameter_unit, 73) header_text, (month_labels(month_index), month_index=1, &
                                                          12)
            do hru_index = 1, hru_count
              read (fixed_parameter_unit, 72) hru_name(hru_index), (albedo(hru_index, month_index, &
                                                        climate_region_index_loop), month_index=1, &
                                                                      12)
            end do
            ! Read leaf area index:
            read (fixed_parameter_unit, 71) header_text
           read (fixed_parameter_unit, 73) header_text, (month_labels(month_index), month_index=1, &
                                                          12)
            do hru_index = 1, hru_count
                read (fixed_parameter_unit, 72) hru_name(hru_index), (leaf_area_index(hru_index, &
                                           month_index, climate_region_index_loop), month_index=1, &
                                                                      12)
            end do
            ! Read vegetation height:
            read (fixed_parameter_unit, 71) header_text
           read (fixed_parameter_unit, 73) header_text, (month_labels(month_index), month_index=1, &
                                                          12)
            do hru_index = 1, hru_count
                read (fixed_parameter_unit, 72) hru_name(hru_index), (vegetation_height(hru_index, &
                                           month_index, climate_region_index_loop), month_index=1, &
                                                                      12)
            end do
            ! Read surface resistance:
            read (fixed_parameter_unit, 71) header_text
           read (fixed_parameter_unit, 73) header_text, (month_labels(month_index), month_index=1, &
                                                          12)
            do hru_index = 1, hru_count
               read (fixed_parameter_unit, 72) hru_name(hru_index), (surface_resistance(hru_index, &
                                           month_index, climate_region_index_loop), month_index=1, &
                                                                      12)
            end do
        end do

        surface_resistance = surface_resistance*1.5
        close (fixed_parameter_unit)

        !Open Climate Region file
        open (climate_region_unit, file=input_directory//'climate.reg', status='OLD')
        read (climate_region_unit, 71) header_text
        do catchment_record_index = 1, catchment_count
            read (climate_region_unit, 74) ignored_catchment_id, &
                climate_region(catchment_record_index)
        end do

71      format(a10)
72      format(a10, 12f5.2)
73      format(a10, 12a5)
74      format(2i6)

        return
    end

    subroutine read_calibrated_parameters
        use catchment_state, only: hru_count, hru_index, hru_name, subbasin_count
        use water_balance_state, only: arno_b, brooks_corey_lambda, capillary_threshold_fraction, &
                                       floodplain_infiltration_rate, groundwater_conductivity, &
                      groundwater_routing_coefficient, max_capillary_flux, max_soil_water_storage, &
                       specific_baseflow, subsurface_conductivity, subsurface_routing_coefficient, &
                                       surface_routing_coefficient
        use io_state, only: calibrated_parameter_unit, header_fields, input_directory
        ! Reads soil and routing calibration parameters.

        implicit none
        integer :: current_subbasin, header_index
        real :: unused_hru_parameters(subbasin_count, hru_count)
        real :: unused_routing_parameter(subbasin_count)
        ! Specific base flow (M3/S/KM2): specific_baseflow(subbasin_count)
        max_soil_water_storage = 0.0
        arno_b = 0.0
        subsurface_conductivity = 0.0
        groundwater_conductivity = 0.0
        brooks_corey_lambda = 0.0
        unused_hru_parameters = 0.0
        surface_routing_coefficient = 0.0
        unused_routing_parameter = 0.0
        groundwater_routing_coefficient = 0.0
        subsurface_routing_coefficient = 0.0
        open (calibrated_parameter_unit, file=input_directory//'soil.par', status= &
              'OLD')
        do current_subbasin = 1, subbasin_count
            read (calibrated_parameter_unit, 72) header_fields(1)
            read (calibrated_parameter_unit, 72) (header_fields(header_index), header_index=1, &
                                                  5)
            do hru_index = 1, hru_count
                read (calibrated_parameter_unit, 71) hru_name(hru_index), &
                    max_soil_water_storage(current_subbasin, hru_index), &
                    arno_b(current_subbasin, hru_index), &
                    groundwater_conductivity(current_subbasin, hru_index), &
                    subsurface_conductivity(current_subbasin, hru_index), &
                    brooks_corey_lambda(current_subbasin, hru_index), &
                    max_capillary_flux(current_subbasin, hru_index), &
                    capillary_threshold_fraction(current_subbasin, hru_index), &
                    floodplain_infiltration_rate(current_subbasin, hru_index)

            end do
            read (calibrated_parameter_unit, 73) header_fields(1), &
                surface_routing_coefficient(current_subbasin)
            read (calibrated_parameter_unit, 73) header_fields(2), &
                subsurface_routing_coefficient(current_subbasin)
            read (calibrated_parameter_unit, 73) header_fields(3), &
                groundwater_routing_coefficient(current_subbasin)
            read (calibrated_parameter_unit, 74) header_fields(4), &
                specific_baseflow(current_subbasin)
        end do
        close (calibrated_parameter_unit)
71      format(a10, 8f8.3)
72      format(7a10)
73      format(a10, f8.1)
74      format(a10, f8.6)
        return
    end

    subroutine read_catchment_data
        use simulation_state, only: first_subbasin, last_subbasin
        use catchment_state, only: catchment_area, catchment_count, catchment_index, &
              catchment_order, catchment_subbasin, catchment_x, catchment_y, downstream_catchment, &
                        drainage_area, hru_count, hru_index, hru_percentage, longest_reach_length, &
                      longest_reach_slope, river_length, river_slope, river_width, subbasin_index, &
                                   subbasin_outlet_catchment
        use water_balance_state, only: max_soil_water_storage
        use muskingum_state, only: manning_n, reference_q
        use inertial_state, only: bankfull_depth, inertial_manning_n, inertial_routing_enabled, &
                                  routing_method
        use io_state, only: catchment_data_unit, input_directory

        implicit none
        integer :: catchment_id(catchment_count)
        integer :: catchment_record_index, hru_input_index, current_subbasin, &
                   secondary_hru_index
        integer :: enabled_outlet_index, input_catchment_sequence
        real :: max_enabled_drainage_area, redistributed_water_hru_percentage

        max_enabled_drainage_area = 0.0

        open (catchment_data_unit, file=input_directory//'mini.gtp', status='OLD')
        read (catchment_data_unit, 77)
        subbasin_outlet_catchment = -999999
        do catchment_record_index = 1, catchment_count
     read (catchment_data_unit, *) input_catchment_sequence, catchment_id(catchment_record_index), &
                catchment_x(catchment_record_index), catchment_y(catchment_record_index), &
               catchment_subbasin(catchment_record_index), catchment_area(catchment_record_index), &
                drainage_area(catchment_record_index), river_length(catchment_record_index), &
                river_slope(catchment_record_index), longest_reach_length(catchment_record_index), &
        longest_reach_slope(catchment_record_index), downstream_catchment(catchment_record_index), &
                catchment_order(catchment_record_index), routing_method(catchment_record_index), &
                river_width(catchment_record_index), bankfull_depth(catchment_record_index), &
                manning_n(catchment_record_index), &
                (hru_percentage(catchment_record_index, hru_input_index), hru_input_index=1, &
                 hru_count)

            reference_q(catchment_record_index) = 0.333* &
                                                  drainage_area(catchment_record_index)**0.7
!Calculates reference initial discharge

            inertial_manning_n(catchment_record_index) = manning_n(catchment_record_index)
            !Reads inertial model subroutines manning

            ! Check errors in HRU fractions:
            if (sum(hru_percentage(catchment_record_index, :)) > 100.01 .or. &
                sum(hru_percentage(catchment_record_index, :)) < 99.99 .or. &
                minval(hru_percentage(catchment_record_index, :)) < 0.0 .or. &
                maxval(hru_percentage(catchment_record_index, :)) > 100.0) then
                write (*, *) 'Error in the % of HRUs in the catchments', catchment_record_index
                write (*, *) 'Sum=', sum(hru_percentage(catchment_record_index, :)), 'Min=', &
                    minval(hru_percentage(catchment_record_index, :)), 'no HRU ', &
                    minloc(hru_percentage(catchment_record_index, :)), 'Max=', &
                    maxval(hru_percentage(catchment_record_index, :)), ' at HRU', &
                    maxloc(hru_percentage(catchment_record_index, :))
                read (*, *)
            end if
            ! Define outlet of sub-basins:
            ! Outlet equals catchment of larger ID code.
            current_subbasin = catchment_subbasin(catchment_record_index)
            if (subbasin_outlet_catchment(current_subbasin) < &
               catchment_id(catchment_record_index)) subbasin_outlet_catchment(current_subbasin) = &
                catchment_id(catchment_record_index)

            ! Route catchments in disabled subbasins with the constant-slope outlet condition.
            if ((catchment_subbasin(catchment_record_index) < first_subbasin) .or. &
                (catchment_subbasin(catchment_record_index) > last_subbasin)) then
                downstream_catchment(catchment_record_index) = -1
            else
                if (drainage_area(catchment_record_index) > max_enabled_drainage_area) then
                    enabled_outlet_index = catchment_record_index
                    max_enabled_drainage_area = drainage_area(catchment_record_index)
                end if
            end if

        end do

        downstream_catchment(enabled_outlet_index) = -1

        ! Sub-basins = 1
        write (*, *) ''
        write (*, *) 'Minimun reach lenght set to 2.5 km'
        ! Correct length of main river. Minimum length = 2.5 km:
        do catchment_index = 1, catchment_count
            river_length(catchment_index) = max(river_length(catchment_index), 2.5)
        end do
        ! Change units of river slope to m/m
        write (*, *) 'Reach slopes from geometry transformed to m/m'
        river_slope = river_slope/1000.0
        ! Correct length of longest tributary:
        write (*, *) 'Minimun tributarie lenght set to 0.001 km'
        do catchment_index = 1, catchment_count
            longest_reach_length(catchment_index) = max(longest_reach_length(catchment_index), &
                                                        0.001)
        end do
        write (*, *) 'Radiation calculation is using sunshine'

        ! Redistribute the water HRU before hydrodynamic routing.
        if (inertial_routing_enabled == 1) then
            write (*, *) 'Redistributing the area of HRU water to other uses'
            !read_calibrated_parameters.F90 must be called before this
            do catchment_index = 1, catchment_count
                subbasin_index = catchment_subbasin(catchment_index)
                redistributed_water_hru_percentage = 0.0
                !HRU loop
                do hru_index = 1, hru_count
                    if (max_soil_water_storage(subbasin_index, hru_index) < 0.001) then
                        if (hru_percentage(catchment_index, hru_index) > 99.999) then
                            do secondary_hru_index = 1, hru_count
                                !HRUs will have the same area
                                hru_percentage(catchment_index, hru_index) = 100./ &
                                                                             dble(hru_count)
                            end do
                        end if
                        !Eliminating HRU water
                        redistributed_water_hru_percentage = hru_percentage(catchment_index, &
                                                                            hru_index)
                        hru_percentage(catchment_index, hru_index) = 0.0
                    end if
                end do
                ! Redistribute the removed water-HRU fraction among the other HRUs.
                do hru_index = 1, hru_count
                    hru_percentage(catchment_index, hru_index) = hru_percentage(catchment_index, &
                                          hru_index) + hru_percentage(catchment_index, hru_index)* &
                                                         redistributed_water_hru_percentage/(100.- &
                                                                 redistributed_water_hru_percentage)
                end do
            end do
        end if

        write (*, *) ''

        close (catchment_data_unit)
77      format(i5, 2f15.3, i5, 2f10.1, 2i5, f10.2, f10.6, i5, 6f5.1)
        return
    end

    subroutine read_climatology
        use catchment_state, only: catchment_count
        use meteorological_state, only: monthly_air_pressure, monthly_air_temperature, &
                                  monthly_relative_humidity, monthly_solar_input, monthly_wind_speed
        use io_state, only: climatology_unit, input_directory

        implicit none
        integer :: climate_cell_index, month_index, record_index

        !input binary file with interpolated rainfall data
      open (climatology_unit, file=input_directory//'monthly_climatology.bin', status='old', recl= &
              catchment_count, form='UNFORMATTED', access='DIRECT')

        !Binary file of CRU climatology. Order of values:
        !1 - Surface Temperature        [months: 1 ... 12]
        !2 - Relative Humidity          [months: 1 ... 12]
        !3 - Radiation                  [months: 1 ... 12]
        !4 - Wind Speed                 [months: 1 ... 12]
        !5 - Atmospheric pressure       [months: 1 ... 12]

        record_index = 1
        ! Near-surface air temperature (degrees C)
        do month_index = 1, 12
            read (climatology_unit, rec=record_index) (monthly_air_temperature(climate_cell_index, &
                                                               month_index), climate_cell_index=1, &
                                                       catchment_count)
            record_index = record_index + 1
        end do

        ! near surface relative humidity (%)
        do month_index = 1, 12
            read (climatology_unit, rec= &
                  record_index) (monthly_relative_humidity(climate_cell_index, month_index), &
                                 climate_cell_index=1, catchment_count)
            record_index = record_index + 1
        end do

        ! Radiation (MJ/timestep), sunshine hours, or sunshine percent according to the
        ! configuration.
        do month_index = 1, 12
            read (climatology_unit, rec=record_index) (monthly_solar_input(climate_cell_index, &
                                                               month_index), climate_cell_index=1, &
                                                       catchment_count)
            record_index = record_index + 1
        end do

        ! Wind speed (m/s)
        do month_index = 1, 12
            read (climatology_unit, rec=record_index) (monthly_wind_speed(climate_cell_index, &
                                                               month_index), climate_cell_index=1, &
                                                       catchment_count)
            record_index = record_index + 1
        end do

        ! Atmospheric pressure (kPa)
        do month_index = 1, 12
            read (climatology_unit, rec=record_index) (monthly_air_pressure(climate_cell_index, &
                                                               month_index), climate_cell_index=1, &
                                                       catchment_count)
            record_index = record_index + 1
        end do

        close (climatology_unit)

        return

    end subroutine read_climatology

    subroutine read_substitution_flows
        use simulation_state, only: timestep_count, timestep_index
        use reservoir_state, only: substituted_q, substitution_count
        use io_state, only: header_fields, input_directory, substitution_flow_unit

        implicit none
        integer :: input_year, input_month, substitution_index, input_day
        open (substitution_flow_unit, file=input_directory//'substitution_flows.txt', status= &
              'OLD')
      read (substitution_flow_unit, 701) (header_fields(substitution_index), substitution_index=1, &
                                            substitution_count)
        do timestep_index = 1, timestep_count
            read (substitution_flow_unit, *) input_year, input_month, input_day, &
                (substituted_q(substitution_index, timestep_index), substitution_index=1, &
                 substitution_count)
        end do
        close (substitution_flow_unit)
701     format(20a10)
        return
    end subroutine read_substitution_flows

    subroutine read_floodplain_binary_data
        use catchment_state, only: catchment_count, catchment_index, catchment_x
        use water_balance_state, only: vegetation_height
        use inertial_state, only: face_catchment_1, face_catchment_2, face_count, face_distance, &
                               floodplain_area, floodplain_bottom_elevation, floodplain_elevation, &
                                  floodplain_point_count, pseudo_two_d_enabled
        use io_state, only: face_connection_unit, flood_area_unit, flood_stage_unit, &
                            input_directory

        implicit none
        integer data_index, direct_access_record, io_status
        integer, parameter :: floodplain_elevation_increment = 1
        !Increment in floodplain is assumed to be 1m
        integer, parameter :: standard_floodplain_point_count = 100
        !Standard number of elevation points in floodplain

        floodplain_point_count = standard_floodplain_point_count
        !Setting the number of floodplain elevations

        !Opening the level catchment_x flooded area files
        open (flood_stage_unit, file=input_directory//'flood_stage.bin', status='old', recl= &
              catchment_count, form='UNFORMATTED', access='DIRECT')
        !input binary file with interpolated rainfall data

        !The Structure of interpolate_stage_area.bin file is as follows:
        !2 - Water Level elevations [catchment_index = 1,2... catchment_count] as INTEGER(KIND=4)
        !3 - Floodplain elevations  [i = 1, 2 ... standard_floodplain_point_count] as REAL(KIND=8)

        direct_access_record = 1
  read (flood_stage_unit, rec=direct_access_record) (floodplain_bottom_elevation(catchment_index), &
                                                           catchment_index=1, catchment_count)
        !Fills the vegetation_height values of floodplain increment
        do catchment_index = 1, catchment_count
            do data_index = 1, standard_floodplain_point_count
                !For each point floodplain increment, computes the elevation
           floodplain_elevation(data_index, catchment_index) = int(floodplain_elevation_increment* &
                                                                        data_index) + &
                                                        floodplain_bottom_elevation(catchment_index)
                !Multiplications between Integer and Real Must be verified
            end do
        end do

        close (flood_stage_unit)
        !Close water level binary file

        !Reads the Floodplain Areas
        !Values are in real*8. RECL must be multiplied by 2
        open (flood_area_unit, file=input_directory//'flood_area.bin', status='old', recl=(2* &
                                     standard_floodplain_point_count), form='UNFORMATTED', access= &
              'DIRECT')
        !input binary file with Floodplain area

        direct_access_record = 1
        do catchment_index = 1, catchment_count
            read (flood_area_unit, rec=direct_access_record) (floodplain_area(data_index, &
                                                                   catchment_index), data_index=1, &
                                                              standard_floodplain_point_count)
            direct_access_record = direct_access_record + 1
        end do

        close (flood_area_unit)
        !Close floodplain area binary file

        ! Read lateral face connections when pseudo-2D routing is enabled.
        if (pseudo_two_d_enabled == 1) then
     open (face_connection_unit, file=input_directory//'floodplain_connections.txt', status='OLD', &
                  action='READ')

            ! Records contain the two catchment indices and their separation in metres.
            data_index = 0
            do
                read (face_connection_unit, *, iostat=io_status) face_catchment_1(data_index + 1), &
                    face_catchment_2(data_index + 1), face_distance(data_index + 1)
                if (io_status .ne. 0) exit
                data_index = data_index + 1
            end do
            close (face_connection_unit)
            face_count = data_index
        end if

        return
    end

    subroutine read_floodplain_text_data
        use catchment_state, only: catchment_index, catchment_x
        use inertial_state, only: face_catchment_1, face_catchment_2, face_count, face_distance, &
                               first_face_elevation, floodplain_area, floodplain_bottom_elevation, &
                                 floodplain_elevation, floodplain_point_count, second_face_elevation
        use io_state, only: face_connection_unit, input_directory, stage_area_unit

        implicit none
        integer connection_index, io_status

        !Opening the level catchment_x flooded area file
   open (stage_area_unit, file=input_directory//'floodplain_stage_area.txt', status='OLD', action= &
              'READ')

        ! Reading data:
        read (stage_area_unit, *)
        floodplain_point_count = 0
        do
            read (stage_area_unit, *, iostat=io_status) catchment_index, &
                floodplain_bottom_elevation(catchment_index), &
               floodplain_elevation(floodplain_point_count(catchment_index) + 1, catchment_index), &
                floodplain_area(floodplain_point_count(catchment_index) + 1, catchment_index)
            if (io_status .ne. 0) exit
            floodplain_point_count(catchment_index) = floodplain_point_count(catchment_index) + 1
        end do
        close (stage_area_unit)

        ! This text face-connection branch remains disabled.
        if (1 == 0) then
     open (face_connection_unit, file=input_directory//'floodplain_connections.txt', status='OLD', &
                  action='READ')

            ! Records contain face ID, two catchments, boundary elevations, and distance.
            connection_index = 0
            do
                read (face_connection_unit, *, iostat=io_status) connection_index, &
                    face_catchment_1(connection_index), first_face_elevation(connection_index), &
                    face_catchment_2(connection_index), second_face_elevation(connection_index), &
                    face_distance(connection_index)
                if (io_status .ne. 0) exit
            end do
            close (face_connection_unit)
            face_count = connection_index
        end if

        return
    end

    subroutine read_reservoir_data
        use date_time, only: calculate_integer_julian_day
        use simulation_state, only: day, month, timestep_count, timestep_index, year
        use catchment_state, only: catchment_count, catchment_index
        use reservoir_state, only: reservoir_count, reservoir_index_by_catchment, &
                           reservoir_outflow, reservoir_start_timestep, routing_downstream_catchment
        use inertial_state, only: area_table, floodplain_elevation, floodplain_point_count, &
                                  stage_table, upstream_count, upstream_topology, volume_table
        use io_state, only: input_directory

        implicit none

        integer, parameter :: reservoir_input_unit = 159
        integer :: reservoir_lake_catchment_count, listed_lake_catchment_count
        integer :: ignored_reservoir_code, reservoir_index, lake_list_index
        integer :: floodplain_point_index, first_outflow_timestep
        integer :: simulate_reservoir, disable_lake_floodplain
        integer :: any_reservoir_substitution
        integer :: data_month, data_day, data_year, skipped_outflow_timesteps
        integer, dimension(catchment_count) :: reservoir_lake_catchments
        real :: incremental_volume
        character(len=15) :: reservoir_name

        allocate (reservoir_outflow(timestep_count, reservoir_count))

! The first listed catchment is the dam location. Lake catchments have
! floodplain routing disabled, and upstream links terminate at the dam.
        open (reservoir_input_unit, file=input_directory//'reservoir_config.txt')

        listed_lake_catchment_count = 0
        reservoir_lake_catchments = 0
        any_reservoir_substitution = 0

        do reservoir_index = 1, reservoir_count
            ! Record: reservoir name/code, simulation and lake flags, count, catchment IDs.
        read (reservoir_input_unit, *) reservoir_name, ignored_reservoir_code, simulate_reservoir, &
                disable_lake_floodplain, reservoir_lake_catchment_count, &
                reservoir_lake_catchments(listed_lake_catchment_count + 1: &
                                       reservoir_lake_catchment_count + listed_lake_catchment_count)

            ! A reservoir without listed catchments cannot be simulated.
            if (reservoir_lake_catchment_count == 0) then
                disable_lake_floodplain = 0
                simulate_reservoir = 0
            end if

            ! The first catchment in the record contains the dam.
            catchment_index = reservoir_lake_catchments(listed_lake_catchment_count + 1)

            if (simulate_reservoir > 0) then
                reservoir_index_by_catchment(catchment_index) = reservoir_index
                any_reservoir_substitution = 1

                ! Terminate the reservoir catchment and its direct upstream links.
                upstream_count = upstream_topology(catchment_index, 1)
                if (upstream_count > 0) then
                    do lake_list_index = 1, upstream_count
           routing_downstream_catchment(upstream_topology(catchment_index, 1 + lake_list_index)) = &
                            -2
                    end do
                end if
                routing_downstream_catchment(catchment_index) = -2
            end if

            if (disable_lake_floodplain > 0) then
                listed_lake_catchment_count = listed_lake_catchment_count + &
                                              reservoir_lake_catchment_count
            else
     reservoir_lake_catchments((listed_lake_catchment_count + 1):(reservoir_lake_catchment_count + &
                                                                   listed_lake_catchment_count)) = &
                    0
            end if
        end do
        close (reservoir_input_unit)

! Treat reservoir-lake area as constant when updating its volume table.

        lake_list_index = 1
        do while (reservoir_lake_catchments(lake_list_index) > 0)

            catchment_index = reservoir_lake_catchments(lake_list_index)
            area_table(3, catchment_index) = area_table(2, catchment_index)
            volume_table(3, catchment_index) = volume_table(2, catchment_index) &
                                               + area_table(3, catchment_index) &
                             *(stage_table(3, catchment_index) - stage_table(2, catchment_index))* &
                                               1000000.0

            ! Extend the constant-area table through all floodplain elevations.
            do floodplain_point_index = 1, floodplain_point_count(catchment_index) - 1
                area_table(floodplain_point_index + 3, catchment_index) = area_table(2, &
                                                                                    catchment_index)
                incremental_volume = (floodplain_elevation(floodplain_point_index + 1, &
                                                           catchment_index) &
                                      - floodplain_elevation(floodplain_point_index, &
                                                             catchment_index)) &
                                     *1000000.0*area_table(2, catchment_index)
                volume_table(floodplain_point_index + 3, catchment_index) &
                    = volume_table(floodplain_point_index + 2, catchment_index) + incremental_volume
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

            skipped_outflow_timesteps = calculate_integer_julian_day(year, month, day) - &
                                       calculate_integer_julian_day(data_year, data_month, data_day)

            first_outflow_timestep = 1
            if (skipped_outflow_timesteps < 0) then
                ! Simulation begins before observations.
                first_outflow_timestep = 1 - skipped_outflow_timesteps
                skipped_outflow_timesteps = 0
            end if

            open (reservoir_input_unit, file=input_directory//'reservoir_outflow.txt')

            ! Skip observations before the simulation period.
            do timestep_index = 1, skipped_outflow_timesteps
                read (reservoir_input_unit, *)
            end do

            do timestep_index = first_outflow_timestep, timestep_count
 read (reservoir_input_unit, *) data_year, data_month, data_day, reservoir_outflow(timestep_index, &
                                                                                                  :)
            end do

            close (reservoir_input_unit)

            ! Find the first available outflow for each simulated reservoir.
            reservoir_start_timestep = 1
            do catchment_index = 1, catchment_count
                if (reservoir_index_by_catchment(catchment_index) > 0) then
                    reservoir_index = reservoir_index_by_catchment(catchment_index)
                    do timestep_index = 1, timestep_count
                        if (reservoir_outflow(timestep_index, reservoir_index) > 0) then
                            reservoir_start_timestep(catchment_index) = timestep_index
                            exit
                        end if
                    end do
                end if
            end do
        end if

    end subroutine

end module static_input_io
