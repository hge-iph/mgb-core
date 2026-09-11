module evapotranspiration_processing

    implicit none
    private
    public :: calculate_evapotranspiration

contains

    subroutine calculate_evapotranspiration
        use simulation_state, only: model_timestep
        use runoff_state, only: current_max_soil_water_storage, current_precipitation, &
            & current_soil_water_storage
        use evapotranspiration_state, only: actual_interception_et, actual_vapor_pressure, &
            & aerodynamic_resistance, air_density, available_interception_storage, &
            & current_air_pressure, current_air_temperature, current_interception_storage, &
            & current_leaf_area_index, current_surface_resistance, current_total_et, &
            & current_vegetation_height, current_wind_speed, latent_heat_vaporization, &
            & max_interception_storage, net_radiation, open_water_aerodynamic_resistance, &
            & potential_interception_et, potential_open_water_et_current, psychrometric_constant, &
            & remaining_et_demand_fraction, saturation_vapor_pressure, &
            & saturation_vapor_pressure_slope, soil_moisture_unlimited_et_threshold, &
            & soil_vegetation_et, surface_resistance_factor, surface_roughness, &
            & vapor_pressure_deficit, water_density, wet_air_specific_heat, wilting_point, &
            & wind_speed_reference

        implicit none

        call calculate_net_radiation

        vapor_pressure_deficit = saturation_vapor_pressure - actual_vapor_pressure
        ! Vapor pressure deficit in KPa
        psychrometric_constant = 0.0016286*current_air_pressure/latent_heat_vaporization
        ! KPa/C (EQ. 4.2.28)
        saturation_vapor_pressure_slope = (4098.0*saturation_vapor_pressure)/ &
            & ((237.3 + current_air_temperature)**2.)
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
        wind_speed_reference = current_wind_speed/((log(10.0/surface_roughness))/ &
            & log(2.0/surface_roughness))
        !wind speed at 2m for calculation of aerodynamic_resistance and potential evapotranspiration

        ! Aerodynamic resistance according to Shuttleworth
        current_vegetation_height = min(current_vegetation_height, 12.5)
        !limits vegetation height to avoid problems
        aerodynamic_resistance = ((log((10.-current_vegetation_height* &
            & 0.67)/(current_vegetation_height*0.123)))*(log((10.-current_vegetation_height* &
            & 0.67)/(current_vegetation_height*0.0123))))/(0.41*0.41*current_wind_speed)
        open_water_aerodynamic_resistance = (4.72*(log(2./0.00137))**2.)/(1.+ &
            & 0.536*wind_speed_reference)
        !aerodynamic_resistance for open water evaporation ! (EQ.4.2.29) from Shuttleworth

        ! Calculate Surface Resistance (current_surface_resistance) for soil moisture
        ! conditions
        soil_moisture_unlimited_et_threshold = 0.8*current_max_soil_water_storage
        ! Limit from which soil moisture dont limit evapotranspiration !calculate_evapotranspiration
        ! 0.8
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
                    & (soil_moisture_unlimited_et_threshold - wilting_point)
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
        max_interception_storage = 0.4*current_leaf_area_index*(model_timestep/86400.)
        ! max_interception_storage=0.2*current_leaf_area_index !According to Wigmosta
        ! evapotranspiration
        ! al.
        ! 1994, also used by Bremicker

        ! Adds Rainfall to water that can be evaporated.
        available_interception_storage = min(current_interception_storage + current_precipitation, &
            & max_interception_storage)
        ! Updates Rainfall
        current_precipitation = &
            & current_precipitation - (available_interception_storage - &
            & current_interception_storage)

        ! Potential Evaporation from interception (note: current_surface_resistance = 0.0)
        potential_interception_et = ((saturation_vapor_pressure_slope* &
            & net_radiation + air_density*wet_air_specific_heat*vapor_pressure_deficit/ &
            & aerodynamic_resistance)/(saturation_vapor_pressure_slope + psychrometric_constant* &
            & (1.0 + 0.0/aerodynamic_resistance)))*((1000.0*model_timestep)/ &
            & (latent_heat_vaporization*water_density))
        ! mm per model timestep.
        potential_open_water_et_current = ((saturation_vapor_pressure_slope* &
            & net_radiation + air_density*wet_air_specific_heat* &
            & vapor_pressure_deficit/open_water_aerodynamic_resistance)/ &
            & (saturation_vapor_pressure_slope + psychrometric_constant*(1.0 + 0.0/ &
            & open_water_aerodynamic_resistance)))*((1000.0* &
            & model_timestep)/(latent_heat_vaporization*water_density))
        ! mm per model timestep for open water (Shuttleworth).

        actual_interception_et = min(potential_interception_et, available_interception_storage)
        ! evaporation of intercepted water
        ! Takes from interception reservoir
        current_interception_storage = available_interception_storage - actual_interception_et

        ! Calculates evaporative demand fraction after evaporation
        remaining_et_demand_fraction = &
            & (potential_interception_et - actual_interception_et)/potential_interception_et

        ! Calculates Penman in mm per model timestep.
        soil_vegetation_et = ((saturation_vapor_pressure_slope* &
            & net_radiation + air_density*wet_air_specific_heat*vapor_pressure_deficit/ &
            & aerodynamic_resistance)/(saturation_vapor_pressure_slope + psychrometric_constant* &
            & (1.0 + current_surface_resistance/aerodynamic_resistance)))*((1000.0* &
            & model_timestep)/(latent_heat_vaporization*water_density))
        ! mm per model timestep.
        soil_vegetation_et = remaining_et_demand_fraction*soil_vegetation_et
        ! evaporation through soil+plant
        current_total_et = soil_vegetation_et + actual_interception_et
        ! total evaporation (interception+ soil/plant)

        soil_vegetation_et = soil_vegetation_et*1.0

        return
    end

    subroutine calculate_net_radiation
        use simulation_state, only: day, day_of_year, hour
        use evapotranspiration_state, only: actual_vapor_pressure, current_albedo, &
            & current_relative_humidity, current_solar_input, current_temperature, &
            & day_of_year_real, earth_sun_distance_factor, ground_heat_flux, &
            & incoming_shortwave_radiation, latent_heat_vaporization, latitude, &
            & longwave_radiation, &
            & max_sunshine_duration, monthly_radiation_option, net_radiation, &
            & net_shortwave_radiation, pi, previous_temperature, saturation_vapor_pressure, &
            & solar_declination, stefan_boltzmann_constant, sunset_hour_angle, &
            & top_atmosphere_radiation, use_radiation_timeseries, water_density

        implicit none

        !internal variables

        ! latent heat of vaporization (MJ/Kg) - ch4. Handbook of Hydrology
        latent_heat_vaporization = (2.501 - 0.002361*current_temperature)
        ! Temperature is in degrees C.

        ! Saturation Vapor pressure
        saturation_vapor_pressure = 0.6108*exp((17.27*current_temperature)/ &
            & (237.3 + current_temperature))
        !in KPa  !calculate_evapotranspiration ATUALIZADO

        actual_vapor_pressure = saturation_vapor_pressure*current_relative_humidity/100.0
        !in KPa

        ! - ch4. - Handbook of Hydrology
        ! Solar Declination (rad)
        day_of_year_real = day_of_year
        solar_declination = 0.4093*sin((2*pi/365.0)*day_of_year_real - 1.405)

        ! Sunset hour angle (rad)
        sunset_hour_angle = acos(-tand(latitude)*tan(solar_declination))
        !intrinsic function TAND is for degree arguments

        ! maximum insolation (hours)
        max_sunshine_duration = 24*sunset_hour_angle/pi
        ! - ch4. - !

        ! Distance Earth-Sun
        earth_sun_distance_factor = 1.0 + 0.033*cos(2*pi*day_of_year_real/365.0)

        ! Top-of-atmosphere Radiation (mm/day)
        top_atmosphere_radiation = 15.392*earth_sun_distance_factor* &
            & (sunset_hour_angle*sind(latitude)* &
            & sin(solar_declination) + cosd(latitude)*cos(solar_declination)* &
            & sin(sunset_hour_angle))

        ! Convert to MJ/m2.day
        top_atmosphere_radiation = top_atmosphere_radiation/1000.0
        ! to meters/day
        top_atmosphere_radiation = top_atmosphere_radiation*water_density*latent_heat_vaporization
        ! to MJ/m2.day

        !Calculates incoming radiation to terr. surface
        if (use_radiation_timeseries == 0) then
            !Options for monthly radiation data (flag rad = 0)

            if (monthly_radiation_option == 0) then
                !INMET
                incoming_shortwave_radiation = top_atmosphere_radiation*(0.25 + 0.5* &
                    & current_solar_input/max_sunshine_duration)
                !from insolation (eq. 4.2.6 from Handbook Hydrology)

            elseif (monthly_radiation_option == 1) then
                !CRU
                incoming_shortwave_radiation = top_atmosphere_radiation*(0.25 + 0.5* &
                    & (current_solar_input)/100.)
                ! Sunshine data in % for CRU data

            elseif (monthly_radiation_option == 2) then
                !WorldClim v2.1
                incoming_shortwave_radiation = current_solar_input
                ! Sunshine data already in radiation (MJ/m².day) for WorldClim data
            end if
        else
            !from incident shortwave on terr surface data
            incoming_shortwave_radiation = current_solar_input
        end if

        ! Discount reflection (albedo)
        net_shortwave_radiation = incoming_shortwave_radiation*(1 - current_albedo)

        ! Long-wave losses
        longwave_radiation = stefan_boltzmann_constant*(current_temperature + 273.2)**4.0
        ! Temperature is converted to Kelvin
        longwave_radiation = longwave_radiation*(0.34 - 0.14*(actual_vapor_pressure)**0.5)
        ! Emissivity correction

        ! Cloudness
        ! current_solar_input is in terms of solar radiation, then uses Handbook of Hydrology
        ! eq.
        ! Parameters from wetlands to address Amazon basin
        longwave_radiation = longwave_radiation*(1.0* &
            & incoming_shortwave_radiation/top_atmosphere_radiation + 0.0)
        ! Cloudness correction

        ! Ground heat flux !MJ/m2.dia
        ground_heat_flux = 0.38*(current_temperature - previous_temperature)
        ! eq. 4.2.18 (Handbook of Hydrology)

        ! Net Radiation (Energy Available) (MJ/m2.dia) - discount longwave and groun heatflux
        net_radiation = net_shortwave_radiation - longwave_radiation - ground_heat_flux

        return
    end

end module evapotranspiration_processing
