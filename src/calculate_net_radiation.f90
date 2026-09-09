! SPDX-License-Identifier: GPL-3.0-or-later
! Copyright (C) 2019 Hidrologia de Grande Escala (HGE)

! Calculate net radiation for the vertical water balance.

        subroutine calculate_net_radiation
            use model_state
            implicit none

            !internal variables

            ! latent heat of vaporization (MJ/Kg) - ch4. Handbook of Hydrology
            latent_heat_vaporization = (2.501 - 0.002361*current_temperature)
            ! Temperature is in degrees C.

            ! Saturation Vapor pressure
            saturation_vapor_pressure = 0.6108*exp((17.27*current_temperature)/(237.3 + &
                                                                               current_temperature))
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
            top_atmosphere_radiation = 15.392*earth_sun_distance_factor*(sunset_hour_angle* &
                                           sind(latitude)*sin(solar_declination) + cosd(latitude)* &
                                                                         cos(solar_declination)* &
                                                                         sin(sunset_hour_angle))

            ! Convert to MJ/m2.day
            top_atmosphere_radiation = top_atmosphere_radiation/1000.0
            ! to meters/day
            top_atmosphere_radiation = top_atmosphere_radiation*water_density* &
                                       latent_heat_vaporization
! to MJ/m2.day

            !Calculates incoming radiation to terr. surface
            if (use_radiation_timeseries == 0) then
                !Options for monthly radiation data (flag rad = 0)

                if (monthly_radiation_option == 0) then
                    !INMET
          incoming_shortwave_radiation = top_atmosphere_radiation*(0.25 + 0.5*current_solar_input/ &
                                                                             max_sunshine_duration)
                    !from insolation (eq. 4.2.6 from Handbook Hydrology)

                elseif (monthly_radiation_option == 1) then
                    !CRU
        incoming_shortwave_radiation = top_atmosphere_radiation*(0.25 + 0.5*(current_solar_input)/ &
                                                                             100.)
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
            longwave_radiation = longwave_radiation*(1.0*incoming_shortwave_radiation/ &
                                                     top_atmosphere_radiation + 0.0)
            ! Cloudness correction

            ! Ground heat flux !MJ/m2.dia
            ground_heat_flux = 0.38*(current_temperature - previous_temperature)
! eq. 4.2.18 (Handbook of Hydrology)

            ! Net Radiation (Energy Available) (MJ/m2.dia) - discount longwave and groun heatflux
            net_radiation = net_shortwave_radiation - longwave_radiation - ground_heat_flux

            return
        end
