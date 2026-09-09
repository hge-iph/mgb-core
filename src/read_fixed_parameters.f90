! SPDX-License-Identifier: GPL-3.0-or-later
! Copyright (C) 2019 Hidrologia de Grande Escala (HGE)

! Read fixed monthly vegetation parameters and climate regions.

        subroutine read_fixed_parameters
            ! File with monthly fixed parameters for each HRU.
            use model_state
            implicit none
            integer :: month_index, climate_region_index_loop, catchment_record_index
            integer :: ignored_catchment_id
            character(20) :: header_text
            character(5) :: month_labels(12)
            open (fixed_parameter_unit, file=input_directory//'vegetation_parameters.txt', status= &
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
            open (climate_region_unit, file=input_directory//'climate_regions.txt', status='OLD')
            read (climate_region_unit, 71) header_text
            do catchment_record_index = 1, catchment_count
                read (climate_region_unit, 74) ignored_catchment_id, &
                    climate_region(catchment_record_index)
            end do

71          format(a10)
72          format(a10, 12f5.2)
73          format(a10, 12a5)
74          format(2i6)

            return
        end
