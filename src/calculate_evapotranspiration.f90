! SPDX-License-Identifier: GPL-3.0-or-later
! Copyright (C) 2019 Hidrologia de Grande Escala (HGE)

! Calculate interception, soil, vegetation, and open-water evapotranspiration.

        subroutine calculate_evapotranspiration
            use model_state
            implicit none

            vapor_pressure_deficit = saturation_vapor_pressure - actual_vapor_pressure
            ! Vapor pressure deficit in KPa
            psychrometric_constant = 0.0016286*current_air_pressure/latent_heat_vaporization
            ! KPa/C (EQ. 4.2.28)
            saturation_vapor_pressure_slope = (4098.0*saturation_vapor_pressure)/((237.3 + &
                                                                       current_air_temperature)**2.)
            ! (EQ. 4.2.3)
            air_density = 3.486*(current_air_pressure/(275.0 + current_air_temperature))
! KG/M3 (EQ. 4.2.4)

            net_radiation = net_radiation/(3600.0*24.0)
            ! Net Radiation in MJ/m2/s

            ! Aerodynamic roughness of vegetation
            surface_roughness = 0.1*current_vegetation_height

            ! Aerodynamic resistance is based on Bremicker work
            ! Fix wind speed at 2m to 10m above the ground
            ! Considering current_wind_speed input as wind at 10m
            current_wind_speed = current_wind_speed + 0.1
            !        Avoid zero value issues
            wind_speed_2m = current_wind_speed/((log(10.0/surface_roughness))/log(2.0/ &
                                                                                 surface_roughness))
!wind speed at 2m for calculation of aerodynamic_resistance and potential evapotranspiration

            ! Aerodynamic resistance according to Shuttleworth
            current_vegetation_height = min(current_vegetation_height, 12.5)
            !limits vegetation height to avoid problems
            aerodynamic_resistance = ((log((10.-current_vegetation_height*0.67)/ &
                    (current_vegetation_height*0.123)))*(log((10.-current_vegetation_height*0.67)/ &
                                                 (current_vegetation_height*0.0123))))/(0.41*0.41* &
                                                                                 current_wind_speed)
            open_water_aerodynamic_resistance = (4.72*(log(2./0.00137))**2.)/(1.+0.536* &
                                                                              wind_speed_2m)
!aerodynamic_resistance for open water evaporation ! (EQ.4.2.29) from Shuttleworth

            ! Calculate Surface Resistance (current_surface_resistance) for soil moisture
            ! conditions
            soil_moisture_unlimited_et_threshold = 0.8*current_max_soil_water_storage
! Limit from which soil moisture dont limit evapotranspiration !calculate_evapotranspiration 0.8
! ATUALIZADO
            wilting_point = 0.1*current_max_soil_water_storage
            ! Wilting Point

            ! Surface Resistance Variation with Soil moisture (Wigmosta evapotranspiration al. 1994
            ! - eq. 16)
            if (current_max_soil_water_storage < 0.1) then
                ! Open water has no surface resistance
                current_surface_resistance = 0.0
            else
                if (current_soil_water_storage .le. wilting_point) then
                    current_surface_resistance = 999999999.0
                    ! Dry soil, assume superhigh surface resistance
                elseif (current_soil_water_storage .lt. soil_moisture_unlimited_et_threshold) then
                    surface_resistance_factor = (current_soil_water_storage - wilting_point)/ &
                                                (soil_moisture_unlimited_et_threshold - &
                                                 wilting_point)
                    surface_resistance_factor = 1./surface_resistance_factor
                    ! Moisture deficit
                else
                    surface_resistance_factor = 1.0
                end if
                current_surface_resistance = surface_resistance_factor*current_surface_resistance
                !if surface_resistance_factor>1 increases surface resistance
            end if

            ! Calculates evaporation from intercepted water
            ! Maximum Interception
            ! Maximum interception storage varies with leaf area and timestep length.
            max_interception_storage = 0.4*current_leaf_area_index*(model_timestep_seconds/86400.)
! max_interception_storage=0.2*current_leaf_area_index !According to Wigmosta evapotranspiration
! al.
! 1994, also used by Bremicker

            ! Adds Rainfall to water that can be evaporated.
        available_interception_storage = min(current_interception_storage + current_precipitation, &
                                                 max_interception_storage)
            ! Updates Rainfall
            current_precipitation = current_precipitation - &
                                    (available_interception_storage - current_interception_storage)

            ! Potential Evaporation from interception (note: current_surface_resistance = 0.0)
        potential_interception_et = ((saturation_vapor_pressure_slope*net_radiation + air_density* &
                             wet_air_specific_heat*vapor_pressure_deficit/aerodynamic_resistance)/ &
   (saturation_vapor_pressure_slope + psychrometric_constant*(1.0 + 0.0/aerodynamic_resistance)))* &
                                       ((1000.0*model_timestep_seconds)/(latent_heat_vaporization* &
                                                                          water_density))
            !mm/model_timestep_seconds
            potential_open_water_et_current = ((saturation_vapor_pressure_slope*net_radiation + &
                                         air_density*wet_air_specific_heat*vapor_pressure_deficit/ &
     open_water_aerodynamic_resistance)/(saturation_vapor_pressure_slope + psychrometric_constant* &
                 (1.0 + 0.0/open_water_aerodynamic_resistance)))*((1000.0*model_timestep_seconds)/ &
                                                                        (latent_heat_vaporization* &
                                                                                     water_density))
            !mm/model_timestep_seconds !open water (Shuttleworth)

            actual_interception_et = min(potential_interception_et, available_interception_storage)
            ! evaporation of intercepted water
            ! Takes from interception reservoir
            current_interception_storage = available_interception_storage - actual_interception_et

            ! Calculates evaporative demand fraction after evaporation
            remaining_et_demand_fraction = (potential_interception_et - actual_interception_et)/ &
                                           potential_interception_et

            ! Calculates Penman in mm/model_timestep_seconds
            soil_vegetation_et = ((saturation_vapor_pressure_slope*net_radiation + air_density* &
                             wet_air_specific_heat*vapor_pressure_deficit/aerodynamic_resistance)/ &
      (saturation_vapor_pressure_slope + psychrometric_constant*(1.0 + current_surface_resistance/ &
             aerodynamic_resistance)))*((1000.0*model_timestep_seconds)/(latent_heat_vaporization* &
                                                                                     water_density))
            !mm/model_timestep_seconds
            soil_vegetation_et = remaining_et_demand_fraction*soil_vegetation_et
            ! evaporation through soil+plant
            current_total_et = soil_vegetation_et + actual_interception_et
            ! total evaporation (interception+ soil/plant)

            soil_vegetation_et = soil_vegetation_et*1.0

            return
        end
