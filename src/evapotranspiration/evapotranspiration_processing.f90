module evapotranspiration_processing

    implicit none
    private
    public :: calculate_evapotranspiration

contains

    subroutine calculate_evapotranspiration(p, w, wm, pa, ta, wind, rh, solar, t_prev, lai, &
        & alb, z_veg, rs, si, lat, et_soil, et_int, et_total, et_int_pot, et_water_pot, &
        & lambda_e, r_top, r_short)
        use simulation_state, only: model_timestep

        implicit none

        ! Symbols:
        ! p, w, wm       precipitation and soil storage [mm per step, mm, mm]
        ! pa, ta, wind   air pressure, temperature, and 10 m wind [kPa, deg C, m/s]
        ! rh             relative humidity [percent]
        ! t_prev         previous air temperature [deg C]
        ! solar          solar forcing [hours, percent, or MJ/m2/day by option]
        ! lai, alb       leaf-area index and albedo [1, 1]
        ! z_veg, rs      vegetation height and surface resistance [m, s/m]
        ! si             interception storage [mm]
        ! lat            catchment latitude [degrees]
        ! et_soil, et_int, et_total, et_int_pot, et_water_pot evapotranspiration depths
        ! [mm per step]
        ! lambda_e       latent heat of vaporization [MJ/kg]
        ! r_net          net radiation after conversion to seconds [MJ/m2/s]
        ! r_top, r_short top-of-atmosphere and surface radiation [MJ/m2/day]
        ! e_a, e_s, e_d actual, saturation, and deficit vapor pressure [kPa]
        ! s_e, gamma     saturation-pressure slope and psychrometric constant [kPa/deg C]
        ! rho_a, rho_w   air and water density [kg/m3]
        ! c_p            air specific heat [MJ/kg/deg C]
        ! z0, z, u10, u2 roughness, capped height, adjusted winds [m, m, m/s, m/s]
        ! r_a, r_aw      vegetation and open-water aerodynamic resistance [s/m]
        ! w_u, w_w       unlimited and wilting soil-water thresholds [mm]
        ! f_rs, si_a, si_m, f_et resistance, available/max interception, and demand fraction
        ! [1, mm, mm, 1]

        real, intent(inout) :: p, si, rs
        real, intent(in) :: w, wm, pa, ta, wind, rh, solar, t_prev
        real, intent(in) :: lai, alb, z_veg, lat
        real, intent(out) :: et_soil, et_int, et_total, et_int_pot, et_water_pot, lambda_e
        real, intent(out) :: r_top, r_short

        real, parameter :: rho_w = 1000.0
        real, parameter :: c_p = 0.001013
        real, volatile :: r_net
        real, volatile :: e_a, e_s, e_d, s_e, gamma
        real, volatile :: rho_a, z0, z, u10, u2
        real, volatile :: r_a, r_aw
        real, volatile :: w_u, w_w
        ! The dry-soil branch intentionally preserves this legacy factor between calls.
        real, save :: f_rs = 0.0
        real, volatile :: si_a, si_m, f_et

        call calculate_net_radiation(solar, ta, t_prev, rh, alb, lat, lambda_e, r_net, r_top, &
            & r_short, e_a, e_s)

        e_d = e_s - e_a
        gamma = 0.0016286*pa/lambda_e
        s_e = (4098.0*e_s)/((237.3 + ta)**2.)
        rho_a = 3.486*(pa/(275.0 + ta))

        r_net = r_net/(3600.0*24.0)

        z0 = 0.1*z_veg
        u10 = wind + 0.1
        u2 = u10/((log(10.0/z0))/log(2.0/z0))

        z = min(z_veg, 12.5)
        r_a = ((log((10.-z*0.67)/(z*0.123)))*(log((10.-z*0.67)/(z*0.0123))))/(0.41*0.41*u10)
        r_aw = (4.72*(log(2./0.00137))**2.)/(1.+0.536*u2)

        w_u = 0.8*wm
        w_w = 0.1*wm
        if (wm < 0.1) then
            rs = 0.0
        else
            if (w .le. w_w) then
                rs = 999999999.0
            elseif (w .lt. w_u) then
                f_rs = (w - w_w)/(w_u - w_w)
                f_rs = 1./f_rs
            else
                f_rs = 1.0
            end if
            rs = f_rs*rs
        end if

        si_m = 0.4*lai*(model_timestep/86400.)
        si_a = min(si + p, si_m)
        p = p - (si_a - si)

        et_int_pot = ((s_e*r_net + rho_a*c_p*e_d/r_a)/ &
            & (s_e + gamma*(1.0 + 0.0/r_a)))*((1000.0*model_timestep)/(lambda_e*rho_w))
        et_water_pot = ((s_e*r_net + rho_a*c_p*e_d/r_aw)/ &
            & (s_e + gamma*(1.0 + 0.0/r_aw)))*((1000.0*model_timestep)/(lambda_e*rho_w))

        et_int = min(et_int_pot, si_a)
        si = si_a - et_int
        f_et = (et_int_pot - et_int)/et_int_pot

        et_soil = ((s_e*r_net + rho_a*c_p*e_d/r_a)/ &
            & (s_e + gamma*(1.0 + rs/r_a)))*((1000.0*model_timestep)/(lambda_e*rho_w))
        et_soil = f_et*et_soil
        et_total = et_soil + et_int
        et_soil = et_soil*1.0
    end subroutine calculate_evapotranspiration

    subroutine calculate_net_radiation(solar, ta, t_prev, rh, alb, lat, lambda_e, r_net, r_top, &
        & r_short, e_a, e_s)
        use simulation_state, only: day_of_year
        use evapotranspiration_state, only: monthly_radiation_option, use_radiation_timeseries

        implicit none

        ! Symbols:
        ! solar          solar forcing [hours, percent, or MJ/m2/day by option]
        ! ta, rh         air temperature and relative humidity [deg C, percent]
        ! lat             catchment latitude [degrees]
        ! lambda_e        latent heat of vaporization [MJ/kg]
        ! t_prev, alb     previous temperature and albedo [deg C, 1]
        ! r_net, r_top, r_short net, top-of-atmosphere, and surface radiation [MJ/m2/day]
        ! e_a, e_s        actual and saturation vapor pressures [kPa]
        ! d, delta, omega, n_sun, d_r day, declination, sunset angle, sunshine duration,
        !                 and Earth-Sun distance factor [day, rad, rad, h, 1]
        ! pi, sigma, rho_w radiation constants [1, MJ/m2/day/K4, kg/m3]
        ! r_sn, r_l, g   net shortwave, longwave, and ground-heat terms [MJ/m2/day]

        real, intent(in) :: solar, ta, t_prev, rh, alb, lat
        real, intent(out) :: lambda_e, r_net, r_top, r_short, e_a, e_s

        real, parameter :: pi = 3.141592
        real, parameter :: rho_w = 1000.0
        real, parameter :: sigma = 4.903e-9
        real, volatile :: d, delta, omega, n_sun, d_r
        real, volatile :: r_sn, r_l, g

        lambda_e = 2.501 - 0.002361*ta
        e_s = 0.6108*exp((17.27*ta)/(237.3 + ta))
        e_a = e_s*rh/100.0

        d = day_of_year
        delta = 0.4093*sin((2*pi/365.0)*d - 1.405)
        omega = acos(-tand(lat)*tan(delta))
        n_sun = 24*omega/pi
        d_r = 1.0 + 0.033*cos(2*pi*d/365.0)

        r_top = 15.392*d_r*(omega*sind(lat)*sin(delta) + cosd(lat)*cos(delta)*sin(omega))
        r_top = r_top/1000.0
        r_top = r_top*rho_w*lambda_e

        if (use_radiation_timeseries == 0) then
            if (monthly_radiation_option == 0) then
                r_short = r_top*(0.25 + 0.5*solar/n_sun)
            elseif (monthly_radiation_option == 1) then
                r_short = r_top*(0.25 + 0.5*solar/100.)
            elseif (monthly_radiation_option == 2) then
                r_short = solar
            end if
        else
            r_short = solar
        end if

        r_sn = r_short*(1 - alb)
        r_l = sigma*(ta + 273.2)**4.0
        r_l = r_l*(0.34 - 0.14*(e_a)**0.5)
        r_l = r_l*(1.0*r_short/r_top + 0.0)
        g = 0.38*(ta - t_prev)
        r_net = r_sn - r_l - g
    end subroutine calculate_net_radiation

end module evapotranspiration_processing
