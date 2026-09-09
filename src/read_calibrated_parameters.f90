! SPDX-License-Identifier: GPL-3.0-or-later
! Copyright (C) 2019 Hidrologia de Grande Escala (HGE)

! Read calibrated HRU and routing parameters from soil_parameters.txt.

        subroutine read_calibrated_parameters
            ! Reads soil and routing calibration parameters.
            use model_state
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
            open (calibrated_parameter_unit, file=input_directory//'soil_parameters.txt', status= &
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
71          format(a10, 8f8.3)
72          format(7a10)
73          format(a10, f8.1)
74          format(a10, f8.6)
            return
        end
