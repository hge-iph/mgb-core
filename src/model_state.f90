! SPDX-License-Identifier: GPL-3.0-or-later
! Copyright (C) 2019 Hidrologia de Grande Escala (HGE)

! Declare shared hydrological, meteorological, routing, and output state.

module model_state

    implicit none
    save

    character(8) input_directory
    character(9) output_directory
    character(11) hotstart_input_directory

    ! Compile-time capacity limits.
    integer, parameter :: max_hru_count = 12
    integer, parameter :: max_subbasin_count = 505
    integer, parameter :: max_muskingum_reach_count = 150

    !Numbers
    integer catchment_count, hru_count
    !minibasins, uses
    integer timestep_count
    !time intervals
    integer climate_cell_count
    !number of climatological stations
    integer climate_region_count
    !number of climate regions
    integer subbasin_count
    !number of sub-basins

    integer substitution_count
    integer substitution_catchment(max_subbasin_count)
    integer :: reservoir_count

    !Counters
    integer timestep_index
    !Time Interval

    !Variables with numbers of files
    !input Files
    integer, parameter :: config_unit = 1
    !File of fixed parameters
    integer, parameter :: fixed_parameter_unit = 2
    !File of calibrated parameters
    integer, parameter :: calibrated_parameter_unit = 3
    !File of parameters associated with the HRU's
    integer, parameter :: catchment_data_unit = 4
    !File of minibasins informations
    integer, parameter :: climate_region_unit = 9
    !File of climate regions
    integer, parameter :: substitution_flow_unit = 10
    !Hydrographs of file read to substitute the calculated ones

    integer, parameter :: flood_stage_unit = 14
    !Binary file of stage needed to fill stage_table
    integer, parameter :: flood_area_unit = 15
    !Binary file of flooded area needed to fill stage_table
    integer, parameter :: climatology_unit = 16
    !Binary file of climatological variables
    integer, parameter :: water_balance_hotstart_unit = 17
    !Binary file of state variables
    integer, parameter :: inertial_hotstart_unit = 18
    !Binary file of state variables

    !output Files
    integer, parameter :: log_unit = 26
    !File run log

    integer, parameter :: stage_area_unit = 41
    !File of reservoir data for simulation
    integer, parameter :: face_connection_unit = 42
    !File of face connections for inertial pseudo 2D routing
    integer, parameter :: hotstart_list_unit = 46
    !File of hotstart list

    ! Met forcing
    integer, parameter :: precipitation_unit = 50
    !File of rainfall data
    integer, parameter :: temperature_unit = 51
    !File of temperature data
    integer, parameter :: radiation_unit = 52
    !File of radiation data
    integer, parameter :: relative_humidity_unit = 53
    !File of relative humidity data
    integer, parameter :: wind_unit = 54
    !File of wind velocity data
    integer, parameter :: pressure_unit = 55
    !File of pressure data

    !output binaries
    integer, parameter :: discharge_output_unit = 1973
    !File containing RIVER DISCHARGE
    integer, parameter :: et_output_unit = 1974
    !File containing EVAPOTRANSPIRATION
    integer, parameter :: water_surface_elevation_output_unit = 1975
    !File containing WATER SURFACE ELEVATION
    integer, parameter :: hand_output_unit = 1976
    !File containing HAND VALUES
    integer, parameter :: total_water_storage_output_unit = 1977
    !File containing TERRESTRIAL WATER STORAGE
    integer, parameter :: flooded_area_output_unit = 1978
    !File containing FLOODED AREA
    integer, parameter :: soil_saturation_output_unit = 1979
    !File containing SOIL SATURATION DEGREE
    integer, parameter :: interception_et_output_unit = 1980
    !File containing evapotranspiration of INTERC. WATER
    integer, parameter :: soil_vegetation_et_output_unit = 1981
    !File containing evapotranspiration from SOIL+VEGETATION
    integer, parameter :: open_water_et_output_unit = 1982
    !File containing evapotranspiration from OPEN WATERS
    integer, parameter :: soil_water_output_unit = 1983
    !File containing SOIL WATER CONTENT
    integer, parameter :: groundwater_storage_output_unit = 1984
    !File containing GROUNDWATER RESERVOIR VOLUME
    integer, parameter :: subsurface_storage_output_unit = 1985
    !File containing SUBSURFACE RESERVOIR VOLUME
    integer, parameter :: surface_storage_output_unit = 1986
    !File containing SURFACE RESERVOIR VOLUME
    integer, parameter :: interception_storage_output_unit = 1987
    !File containing INTERCEPTED WATER RESERVOIR
    integer, parameter :: groundwater_flux_output_unit = 1988
    !File containing GROUNDWATER FLUX from SOIL
    integer, parameter :: subsurface_flux_output_unit = 1989
    !File containing SUBSURFACE FLUX from SOIL
    integer, parameter :: surface_flux_output_unit = 1990
    !File containing SURFACE FLUX from SOIL
    integer, parameter :: surface_water_output_unit = 1991
    !File containing SURFACE WATER STORAGE
    integer, parameter :: runoff_output_unit = 1992
    !File containing RUNOFF
    integer, parameter :: water_hru_et_output_unit = 1993
    integer, parameter :: potential_open_water_et_output_unit = 1994
    !File containing POTENTIAL evapotranspiration FROM WATER SURFACES

    !Flags for input met forcing (monthly averages / time series)
    integer use_temperature_timeseries, use_radiation_timeseries
    integer use_humidity_timeseries, use_wind_timeseries, use_pressure_timeseries

    !Flags for output variables
    integer write_discharge_output, write_soil_moisture_output
    integer write_water_surface_elevation_output, write_hand_output
    integer write_total_water_storage_output, write_runoff_output, write_surface_water_output
    integer write_soil_saturation_output, write_et_output, write_interception_et_output
    integer write_soil_vegetation_et_output, write_open_water_et_output, write_water_hru_et_output
    integer write_groundwater_storage_output, write_subsurface_storage_output
    integer write_surface_storage_output, write_interception_storage_output
    integer write_flooded_area_output
    integer write_groundwater_flux_output, write_subsurface_flux_output, write_surface_flux_output
    integer write_potential_open_water_et_output

    !Variables with dimensions used
    real(4), allocatable :: q_river_output(:), water_surface_elevation_output(:)
    real(4), allocatable :: total_water_storage_output(:), flooded_area_output(:), hand_output(:)

    real, allocatable :: substituted_q(:, :)
    !Streamflow at some point to replace the calculated values
    integer, allocatable :: catchments_per_subbasin(:)
    !Nnumber of cells in each sub-basin

    integer day, month, year, hour, minute
    !Date and day of the Julian
    integer day_of_year
    !Day of the year
    real(8) julian_day
    !Julian date (real)

    real, allocatable :: specific_baseflow(:)
    !Especific baseflow (M3/S/KM2)

    !Albedo, Leaf Area Index, average height, and surface resistance
    real, allocatable :: albedo(:, :, :), leaf_area_index(:, :, :), vegetation_height(:, :, :), &
                         surface_resistance(:, :, :)

    !Number of stretchs and time intervals used in the calculation  of muskingum-cunge
    integer, allocatable :: muskingum_reach_count(:)
    real, allocatable :: muskingum_timestep(:)
    real, allocatable :: wave_celerity(:), concentration_time(:)
    !River celerity and concentration time of the minibasin

    !Parameters related to the soil
   real, allocatable :: max_soil_water_storage(:, :), arno_b(:, :), subsurface_conductivity(:, :), &
                         groundwater_conductivity(:, :)

    real, allocatable :: brooks_corey_lambda(:, :), max_capillary_flux(:, :)
    real, allocatable :: capillary_threshold_fraction(:, :), floodplain_infiltration_rate(:, :)
    real, allocatable :: subsurface_routing_coefficient(:)
    real, allocatable :: groundwater_routing_coefficient(:), surface_routing_coefficient(:)

    character(10) hru_name(max_hru_count)
    !Names of the HRUs

    !Parameters related to minibasins
    integer, allocatable :: subbasin_outlet_catchment(:)
    !Indicates the outlet minibasins
    real, allocatable :: river_width(:)
    !River width
    real current_river_width
    !River width (auxiliary variable)
    integer, allocatable :: catchment_subbasin(:), downstream_catchment(:)
    !Watershed, downstream minibasin
    real, allocatable :: longest_reach_slope(:), longest_reach_length(:)
    ! Longest tributary slope and length
    real, allocatable :: catchment_x(:), catchment_y(:)
    !Coordinates of the minibasin center
    integer, allocatable :: climate_region(:)
    !Climate region of catchment
    ! Area of the minibasin, drainage area in number of minibasins, river length and slope of the
    ! river
    real, allocatable :: catchment_area(:), drainage_area(:), river_length(:), river_slope(:)
    !Proportion of HRUs in the minibasins
    real, allocatable :: hru_percentage(:, :)
    real, allocatable :: reference_q(:)
    !Reference streamflow
    real current_reference_q
    !Reference streamflow (auxiliary variable)

    ! temp., humidity, wind, insolation, pressure, monthly values
    real(4), allocatable :: monthly_air_temperature(:, :), monthly_relative_humidity(:, :), &
                            monthly_wind_speed(:, :), monthly_air_pressure(:, :)
    real(4), allocatable :: monthly_solar_input(:, :)
    real, allocatable :: climate_station_coordinates(:, :)
    !catchment_x and catchment_y coordinates of climatological stations

    !Counters
    integer catchment_index

    ! Header fields retained for fixed-width legacy input formats.
    character(10) header_fields(max_subbasin_count)

    !More variables
    real, allocatable :: interception_storage(:, :)
    !Amount of water intercepted in the surface
    real current_reach_length, elevation_difference, current_area
    real, allocatable :: incoming_q_previous(:), outgoing_q_previous(:)
    real, allocatable :: incoming_q_current(:), outgoing_q_current(:)
    real, allocatable :: catchment_q_previous(:), catchment_q_current(:)
    !Streamflows originated in the cell at time t and t + 1 in cell i
    real, allocatable :: incoming_groundwater_fraction_current(:)
    real, allocatable :: incoming_subsurface_fraction_current(:), &
                         incoming_surface_fraction_current(:)
    real, allocatable :: outgoing_groundwater_fraction_current(:)
    real, allocatable :: outgoing_subsurface_fraction_current(:), &
                         outgoing_surface_fraction_current(:)
    real, allocatable :: groundwater_routing_volume(:), subsurface_routing_volume(:)
    real, allocatable :: surface_routing_volume(:)
    real, allocatable :: evapotranspiration(:, :)
    !Total evapotranspiration
    real, allocatable :: capillary_flux(:, :)
    !Capillary flow upward
    real, allocatable :: soil_water_storage(:, :)
    !mount of of water over the soil
    real, allocatable :: groundwater_q(:), subsurface_q(:), surface_q(:)
    !Flows in the minibasins
    real, allocatable :: groundwater_storage(:), subsurface_storage(:), surface_storage(:)
!Volumes in the minibasins
    real, allocatable :: previous_air_temperature(:)
    !Temperature the day before

    real(4), allocatable :: precipitation(:)
    ! Rainfall during the current timestep
    real(4), allocatable :: air_temperature(:), relative_humidity(:), wind_speed(:)
    real(4), allocatable :: solar_input(:), air_pressure(:)

    real model_timestep
    ! Main calculation timestep in seconds.
    !Variables related to radiation
    real latitude
    ! Latitude in decimal degrees (negative south).
    real current_solar_input, previous_temperature
    ! Sunshine duration (hours) and temperature (degrees C)
    real current_albedo
    !ALBEDO
    real net_radiation
    ! Net radiation (MJ/m2/day)
    real day_of_year_real
    !Julian day (real)
    real current_relative_humidity
    real, parameter :: water_density = 1000.0
    !Water specific mass (KG/M3)
    real, parameter :: pi = 3.141592
    !pi
    real, parameter :: stefan_boltzmann_constant = 4.903e-9
    !CONST. STEFAN BOLTZMANN
    !Internal variables of the subroutine
    real latent_heat_vaporization
    !latent heat of vaporization
    real solar_declination, sunset_hour_angle
    real max_sunshine_duration
    ! Maximum sunshine duration in hours.
    real earth_sun_distance_factor
    ! Relative distance Earth - Sun
    real ground_heat_flux, top_atmosphere_radiation
    real incoming_shortwave_radiation, net_shortwave_radiation
    !Heat flux
    real actual_vapor_pressure, saturation_vapor_pressure
    !Vapor pressures (real, Saturation)
    real longwave_radiation
    !Longwave radiation

    integer monthly_radiation_option
    integer reservoir_substitution_enabled
    !Flag for reservoir Simulation
    integer inertial_routing_enabled
    !Flag for inertial model
    integer pseudo_two_d_enabled
    !Flag for pseudo 2D model (ipucas)

    !Variables from Subroutine update_catchment_water_balance
    !Auxiliaries
    real current_soil_water_storage, current_max_soil_water_storage, current_air_pressure
    real current_air_temperature, current_wind_speed, current_arno_b
    real current_subsurface_conductivity, current_groundwater_conductivity
    real current_leaf_area_index, current_vegetation_height, soil_vegetation_et
    real current_precipitation, current_interception_storage, wind_speed_reference
    ! Wind speed reference value at 2 m, in m/s.
    real current_floodplain_infiltration_rate, current_brooks_corey_lambda
    real current_temperature, current_surface_resistance, current_capillary_flux, current_total_et
    real current_capillary_threshold_fraction, remaining_groundwater_storage
    real remaining_subsurface_storage, remaining_surface_storage, hru_area_fraction
    real catchment_soil_water_sum, catchment_capillary_q

    !Variables from Subroutine calculate_evapotranspiration
    real vapor_pressure_deficit
    !Vapor pressure deficit
    real saturation_vapor_pressure_slope
    ! Temperature derivative of saturation vapor pressure
    real psychrometric_constant
    !Psychrometric constant
    real air_density
    !Density of air
    real surface_roughness
    !Roughness
    real available_interception_storage
    real max_interception_storage
    !Maxima intercepted amount of water
    real potential_interception_et
    !Amount of water evaporated from interception (POTENTIAL)
    real potential_open_water_et_current
    !Amount of water evaporated from the water surface  (POTENTIAL)
    real, allocatable :: open_water_evaporation_q(:)
    ! Open-water evaporation (m3/s)
    real actual_interception_et
    !Amount of water evaporated from interception  (REAL)
    real remaining_et_demand_fraction
    !Fraction of available evaporative demand
    real, parameter :: wet_air_specific_heat = 0.001013
    !Heat especific from the humid air  MJ/kg/C
    real aerodynamic_resistance
    !Aerodynamic resistance
    real open_water_aerodynamic_resistance
    !Aerodynamic resistance to potential evapotranspiration
    real soil_moisture_unlimited_et_threshold
    real wilting_point
    !Wilting point  (SHUTTLEWORTH)
    real surface_resistance_factor
    !Correction factor for surface resistence as a function of soil moisture deficit

    integer subbasin_index, hru_index
    !Counter of Sub-basins and HRUs

    real, allocatable :: incoming_q_boundary(:, :), outgoing_q_boundary(:, :)
    !Flow of boundary condition of MUSKINGUM CUNGE
    real, allocatable :: initial_river_q(:, :)
    !Initial condition for MUSKINGUM CUNGE in the river stretch

    integer, allocatable :: catchment_order(:)

    integer, allocatable :: substitution_enabled(:)

    ! Variables to calculate indicators of maximum evapotranspiration:
    real, allocatable :: potential_open_water_et(:), potential_top_radiation_et(:), &
                         potential_surface_radiation_et(:)

    real(4), allocatable :: incremental_q_output(:)
    real(4), allocatable :: et_output(:)
    real(4), allocatable :: groundwater_q_output(:)
    real(4), allocatable :: soil_saturation_output(:)
    real(4), allocatable :: interception_et_output(:), soil_vegetation_et_output(:), &
                            open_water_et_output(:), water_hru_et_output(:)
    real(4), allocatable :: potential_open_water_et_output(:)
    real(4), allocatable :: soil_water_output(:), capillary_water_output(:), &
                            interception_storage_output(:)
    real(4), allocatable :: surface_storage_depth_output(:), subsurface_storage_depth_output(:), &
                            groundwater_storage_depth_output(:)
    real(4), allocatable :: surface_runoff_depth_output(:), subsurface_runoff_depth_output(:), &
                            groundwater_runoff_depth_output(:)
    real(4), allocatable :: surface_water_output(:)
    real(4), allocatable :: catchment_q_output(:)
    real, allocatable :: total_water_storage(:)
    real, allocatable :: flow_velocity(:)
    !For computing flow velocities
    integer, allocatable :: hotstart_write_schedule(:)

    ! Simulation-range controls.
    integer first_subbasin, last_subbasin
    !Control especial cases of run
    integer, dimension(:), allocatable :: reservoir_index_by_catchment
    integer, dimension(:), allocatable :: routing_downstream_catchment
    integer, dimension(:), allocatable :: reservoir_start_timestep

    !MANNING
    real, allocatable :: manning_n(:)
    !Manning coefficient

    real current_catchment_area

    real minimum_soil_storage

    ! Shared work arrays used by catchment water balance and routing.
    real, allocatable :: groundwater_delay(:), subsurface_delay(:), surface_delay(:)
    ! Delay and concentration times

    real, allocatable :: incoming_groundwater_fraction_previous(:)
    real, allocatable :: incoming_subsurface_fraction_previous(:)
    real, allocatable :: incoming_surface_fraction_previous(:)
    real, allocatable :: outgoing_groundwater_fraction_previous(:)
    real, allocatable :: outgoing_subsurface_fraction_previous(:)
    real, allocatable :: outgoing_surface_fraction_previous(:)

end module model_state
