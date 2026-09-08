! SPDX-License-Identifier: GPL-3.0-or-later
! Copyright (C) 2019 Hidrologia de Grande Escala (HGE)

! Declare shared hydrological, meteorological, routing, and output state.

    MODULE model_state

	IMPLICIT NONE
	SAVE

	CHARACTER(8) input_directory
	CHARACTER(9) output_directory
    CHARACTER(11) hotstart_input_directory

	! Compile-time capacity limits.
	INTEGER,PARAMETER:: max_hru_count=12
	INTEGER,PARAMETER:: max_subbasin_count=505
	INTEGER,PARAMETER:: max_muskingum_reach_count=150

	!Numbers
	INTEGER catchment_count,hru_count !minibasins, uses
	INTEGER timestep_count !time intervals
	INTEGER climate_cell_count !number of climatological stations
    INTEGER climate_region_count !number of climate regions
	INTEGER subbasin_count !number of sub-basins

	INTEGER substitution_count
	INTEGER substitution_catchment(max_subbasin_count)
	INTEGER :: reservoir_count

	!Counters
	INTEGER timestep_index !Time Interval

	!Variables with numbers of files
	!input Files
	INTEGER,PARAMETER:: config_unit=1 !File of fixed parameters
	INTEGER,PARAMETER:: fixed_parameter_unit=2 !File of calibrated parameters
	INTEGER,PARAMETER:: calibrated_parameter_unit=3 !File of parameters associated with the HRU's
	INTEGER,PARAMETER:: catchment_data_unit=4 !File of minibasins informations
    INTEGER,PARAMETER:: climate_region_unit=9 !File of climate regions
	INTEGER,PARAMETER:: substitution_flow_unit=10 !Hydrographs of file read to substitute the calculated ones

    INTEGER,PARAMETER:: flood_stage_unit=14 !Binary file of stage needed to fill stage_table
    INTEGER,PARAMETER:: flood_area_unit=15  !Binary file of flooded area needed to fill stage_table
    INTEGER,PARAMETER:: climatology_unit=16  !Binary file of climatological variables
    INTEGER,PARAMETER:: water_balance_hotstart_unit=17 !Binary file of state variables
    INTEGER,PARAMETER:: inertial_hotstart_unit=18 !Binary file of state variables

	!output Files
    INTEGER,PARAMETER:: log_unit=26 !File run log

    integer,PARAMETER:: stage_area_unit=41 !File of reservoir data for simulation
    integer,PARAMETER:: face_connection_unit=42 !File of face connections for inertial pseudo 2D routing
    INTEGER,PARAMETER:: hotstart_list_unit=46 !File of hotstart list

    ! Met forcing
    INTEGER,PARAMETER:: precipitation_unit=50 !File of rainfall data
    INTEGER,PARAMETER:: temperature_unit=51 !File of temperature data
    INTEGER,PARAMETER:: radiation_unit=52 !File of radiation data
    INTEGER,PARAMETER:: relative_humidity_unit=53 !File of relative humidity data
    INTEGER,PARAMETER:: wind_unit=54 !File of wind velocity data
    INTEGER,PARAMETER:: pressure_unit=55 !File of pressure data

    !output binaries
    INTEGER,PARAMETER:: discharge_output_unit=1973      !File containing RIVER DISCHARGE
    INTEGER,PARAMETER:: et_output_unit=1974		   !File containing EVAPOTRANSPIRATION
    INTEGER,PARAMETER:: water_surface_elevation_output_unit=1975	   !File containing WATER SURFACE ELEVATION
    INTEGER,PARAMETER:: hand_output_unit=1976	   !File containing HAND VALUES
    INTEGER,PARAMETER:: total_water_storage_output_unit=1977	   !File containing TERRESTRIAL WATER STORAGE
    INTEGER,PARAMETER:: flooded_area_output_unit=1978	   !File containing FLOODED AREA
    INTEGER,PARAMETER:: soil_saturation_output_unit=1979     !File containing SOIL SATURATION DEGREE
    INTEGER,PARAMETER:: interception_et_output_unit=1980	   !File containing evapotranspiration of INTERC. WATER
    INTEGER,PARAMETER:: soil_vegetation_et_output_unit=1981 !File containing evapotranspiration from SOIL+VEGETATION
    INTEGER,PARAMETER:: open_water_et_output_unit=1982   !File containing evapotranspiration from OPEN WATERS
    INTEGER,PARAMETER:: soil_water_output_unit=1983 !File containing SOIL WATER CONTENT
    INTEGER,PARAMETER:: groundwater_storage_output_unit=1984      !File containing GROUNDWATER RESERVOIR VOLUME
    INTEGER,PARAMETER:: subsurface_storage_output_unit=1985      !File containing SUBSURFACE RESERVOIR VOLUME
    INTEGER,PARAMETER:: surface_storage_output_unit=1986      !File containing SURFACE RESERVOIR VOLUME
    INTEGER,PARAMETER:: interception_storage_output_unit=1987   !File containing INTERCEPTED WATER RESERVOIR
    INTEGER,PARAMETER:: groundwater_flux_output_unit=1988      !File containing GROUNDWATER FLUX from SOIL
    INTEGER,PARAMETER:: subsurface_flux_output_unit=1989      !File containing SUBSURFACE FLUX from SOIL
    INTEGER,PARAMETER:: surface_flux_output_unit=1990      !File containing SURFACE FLUX from SOIL
    INTEGER,PARAMETER:: surface_water_output_unit=1991   !File containing SURFACE WATER STORAGE
    INTEGER,PARAMETER:: runoff_output_unit=1992    !File containing RUNOFF
    INTEGER,PARAMETER:: water_hru_et_output_unit=1993
    INTEGER,PARAMETER:: potential_open_water_et_output_unit=1994  !File containing POTENTIAL evapotranspiration FROM WATER SURFACES

    !Flags for input met forcing (monthly averages / time series)
    integer use_temperature_timeseries, use_radiation_timeseries
    integer use_humidity_timeseries, use_wind_timeseries, use_pressure_timeseries

    !Flags for output variables
    INTEGER write_discharge_output, write_soil_moisture_output
    INTEGER write_water_surface_elevation_output, write_hand_output
    INTEGER write_total_water_storage_output, write_runoff_output, write_surface_water_output
    INTEGER write_soil_saturation_output, write_et_output, write_interception_et_output
    INTEGER write_soil_vegetation_et_output, write_open_water_et_output, write_water_hru_et_output
    INTEGER write_groundwater_storage_output, write_subsurface_storage_output
    INTEGER write_surface_storage_output, write_interception_storage_output
    INTEGER write_flooded_area_output
    INTEGER write_groundwater_flux_output, write_subsurface_flux_output, write_surface_flux_output
    integer write_potential_open_water_et_output

	!Variables with dimensions used
    REAL(4),ALLOCATABLE:: q_river_output(:),water_surface_elevation_output(:)
	REAL(4),ALLOCATABLE:: total_water_storage_output(:),flooded_area_output(:),hand_output(:)

	REAL,ALLOCATABLE:: substituted_q(:,:) !Streamflow at some point to replace the calculated values
	INTEGER,ALLOCATABLE:: catchments_per_subbasin(:)!Nnumber of cells in each sub-basin

	INTEGER day,month,year,hour,minute !Date and day of the Julian
    integer day_of_year !Day of the year
    real(8) julian_day !Julian date (real)

    REAL,ALLOCATABLE:: specific_baseflow(:)!Especific baseflow (M3/S/KM2)

	!Albedo, Leaf Area Index, average height, and surface resistance
	REAL,ALLOCATABLE:: albedo(:,:,:),leaf_area_index(:,:,:),vegetation_height(:,:,:),surface_resistance(:,:,:)

	!Number of stretchs and time intervals used in the calculation  of muskingum-cunge
	INTEGER,ALLOCATABLE:: muskingum_reach_count(:)
	REAL,ALLOCATABLE:: muskingum_timestep(:)
	REAL,ALLOCATABLE:: wave_celerity(:),concentration_time(:)!River celerity and concentration time of the minibasin

	!Parameters related to the soil
	REAL,ALLOCATABLE:: max_soil_water_storage(:,:),arno_b(:,:),subsurface_conductivity(:,:),groundwater_conductivity(:,:)

	REAL,ALLOCATABLE:: brooks_corey_lambda(:,:),max_capillary_flux(:,:)
	REAL,ALLOCATABLE:: capillary_threshold_fraction(:,:),floodplain_infiltration_rate(:,:)
	REAL,ALLOCATABLE:: subsurface_routing_coefficient(:)
	REAL,ALLOCATABLE:: groundwater_routing_coefficient(:),surface_routing_coefficient(:)

	CHARACTER (10) hru_name(max_hru_count)!Names of the HRUs

	!Parameters related to minibasins
	INTEGER,ALLOCATABLE:: subbasin_outlet_catchment(:)!Indicates the outlet minibasins
	REAL,ALLOCATABLE:: river_width(:)!River width
	REAL current_river_width !River width (auxiliary variable)
	INTEGER,ALLOCATABLE:: catchment_subbasin(:),downstream_catchment(:)!Watershed, downstream minibasin
	REAL,ALLOCATABLE::  longest_reach_slope(:),longest_reach_length(:) ! Longest tributary slope and length
	REAL,ALLOCATABLE:: catchment_x(:),catchment_y(:)!Coordinates of the minibasin center
    INTEGER, ALLOCATABLE:: climate_region(:) !Climate region of catchment
	!Area of the minibasin, drainage area in number of minibasins, river length and slope of the river
	REAL,ALLOCATABLE:: catchment_area(:),drainage_area(:),river_length(:),river_slope(:)
	!Proportion of HRUs in the minibasins
	REAL,ALLOCATABLE:: hru_percentage(:,:)
	REAL,ALLOCATABLE:: reference_q(:) !Reference streamflow
	REAL current_reference_q !Reference streamflow (auxiliary variable)


	! temp., humidity, wind, insolation, pressure, monthly values
	REAL(4),ALLOCATABLE:: monthly_air_temperature(:,:),monthly_relative_humidity(:,:),monthly_wind_speed(:,:),monthly_air_pressure(:,:)
	REAL(4),ALLOCATABLE:: monthly_solar_input(:,:)
	REAL,ALLOCATABLE:: climate_station_coordinates(:,:)!catchment_x and catchment_y coordinates of climatological stations

	!Counters
	INTEGER catchment_index

	! Header fields retained for fixed-width legacy input formats.
	CHARACTER (10) header_fields(max_subbasin_count)

	!More variables
	REAL,ALLOCATABLE:: interception_storage(:,:) !Amount of water intercepted in the surface
	REAL current_reach_length,elevation_difference,current_area
	REAL,ALLOCATABLE:: incoming_q_previous(:),outgoing_q_previous(:)
	REAL,ALLOCATABLE:: incoming_q_current(:),outgoing_q_current(:)
	REAL,ALLOCATABLE:: catchment_q_previous(:),catchment_q_current(:) !Streamflows originated in the cell at time t and t + 1 in cell i
	REAL,ALLOCATABLE:: incoming_groundwater_fraction_current(:)
	REAL,ALLOCATABLE:: incoming_subsurface_fraction_current(:),incoming_surface_fraction_current(:)
	REAL,ALLOCATABLE:: outgoing_groundwater_fraction_current(:)
	REAL,ALLOCATABLE:: outgoing_subsurface_fraction_current(:),outgoing_surface_fraction_current(:)
	REAL,ALLOCATABLE:: groundwater_routing_volume(:),subsurface_routing_volume(:)
	REAL,ALLOCATABLE:: surface_routing_volume(:)
	REAL,ALLOCATABLE:: evapotranspiration(:,:) 	!Total evapotranspiration
	REAL,ALLOCATABLE:: capillary_flux(:,:)		!Capillary flow upward
	REAL,ALLOCATABLE:: soil_water_storage(:,:) 	!mount of of water over the soil
	REAL,ALLOCATABLE:: groundwater_q(:),subsurface_q(:),surface_q(:)		!Flows in the minibasins
	REAL,ALLOCATABLE:: groundwater_storage(:),subsurface_storage(:),surface_storage(:)		!Volumes in the minibasins
	REAL,ALLOCATABLE:: previous_air_temperature(:)		!Temperature the day before

	REAL(4),ALLOCATABLE:: precipitation(:) ! Rainfall during the current timestep
	REAL(4),ALLOCATABLE:: air_temperature(:),relative_humidity(:),wind_speed(:)
	REAL(4),ALLOCATABLE:: solar_input(:),air_pressure(:)

	REAL model_timestep_seconds !Time interval of main calculation (in seconds given in the input file)
	!Variables related to radiation
	REAL latitude_degrees !Latitude in decimal degrees (- south)
	REAL current_solar_input,previous_temperature ! Sunshine duration (hours) and temperature (degrees C)
	REAL current_albedo !ALBEDO
	REAL net_radiation ! Net radiation (MJ/m2/day)
	REAL day_of_year_real !Julian day (real)
	REAL current_relative_humidity
	REAL,PARAMETER:: water_density=1000.0 !Water specific mass (KG/M3)
	REAL,PARAMETER:: PI=3.141592 !pi
	REAL,PARAMETER:: stefan_boltzmann_constant=4.903E-9 !CONST. STEFAN BOLTZMANN
	!Internal variables of the subroutine
	REAL latent_heat_vaporization !latent heat of vaporization
	REAL solar_declination,sunset_hour_angle
	REAL max_sunshine_hours !maximum duration of sunshine (hours)
	REAL earth_sun_distance_factor ! Relative distance Earth - Sun
	REAL ground_heat_flux,top_atmosphere_radiation
	REAL incoming_shortwave_radiation,net_shortwave_radiation !Heat flux
	REAL actual_vapor_pressure,saturation_vapor_pressure !Vapor pressures (real, Saturation)
	REAL longwave_radiation !Longwave radiation

    INTEGER monthly_radiation_option
    INTEGER reservoir_substitution_enabled !Flag for reservoir Simulation
    INTEGER inertial_routing_enabled !Flag for inertial model
    INTEGER pseudo_two_d_enabled !Flag for pseudo 2D model (ipucas)

	!Variables from Subroutine update_catchment_water_balance
	!Auxiliaries
	REAL current_soil_water_storage,current_max_soil_water_storage,current_air_pressure
	REAL current_air_temperature,current_wind_speed,current_arno_b
	REAL current_subsurface_conductivity,current_groundwater_conductivity
	REAL current_leaf_area_index,current_vegetation_height,soil_vegetation_et
	REAL current_precipitation,current_interception_storage,wind_speed_2m
	REAL current_floodplain_infiltration_rate,current_brooks_corey_lambda
	REAL current_temperature,current_surface_resistance,current_capillary_flux,current_total_et
	REAL current_capillary_threshold_fraction,remaining_groundwater_storage
	REAL remaining_subsurface_storage,remaining_surface_storage,hru_area_fraction
	REAL catchment_soil_water_sum,catchment_capillary_q

	!Variables from Subroutine calculate_evapotranspiration
	REAL vapor_pressure_deficit !Vapor pressure deficit
	REAL saturation_vapor_pressure_slope ! Temperature derivative of saturation vapor pressure
	REAL psychrometric_constant !Psychrometric constant
	REAL air_density !Density of air
	REAL surface_roughness !Roughness
	REAL available_interception_storage
	REAL max_interception_storage !Maxima intercepted amount of water
	REAL potential_interception_et !Amount of water evaporated from interception (POTENTIAL)
	REAL potential_open_water_et_current !Amount of water evaporated from the water surface  (POTENTIAL)
	REAL,ALLOCATABLE:: open_water_evaporation_q(:) ! Open-water evaporation (m3/s)
	REAL actual_interception_et !Amount of water evaporated from interception  (REAL)
	REAL remaining_et_demand_fraction !Fraction of available evaporative demand
	REAL,PARAMETER:: wet_air_specific_heat=0.001013 	!Heat especific from the humid air  MJ/kg/C
	REAL aerodynamic_resistance !Aerodynamic resistance
	REAL open_water_aerodynamic_resistance !Aerodynamic resistance to potential evapotranspiration
	REAL soil_moisture_unlimited_et_threshold
	REAL wilting_point !Wilting point  (SHUTTLEWORTH)
	REAL surface_resistance_factor !Correction factor for surface resistence as a function of soil moisture deficit

	INTEGER subbasin_index,hru_index !Counter of Sub-basins and HRUs

	REAL,ALLOCATABLE:: incoming_q_boundary(:,:),outgoing_q_boundary(:,:) !Flow of boundary condition of MUSKINGUM CUNGE
	REAL,ALLOCATABLE:: initial_river_q(:,:) !Initial condition for MUSKINGUM CUNGE in the river stretch

	integer,allocatable:: catchment_order(:)

	integer,allocatable::	substitution_enabled(:)

	! Variables to calculate indicators of maximum evapotranspiration:
	real,allocatable:: potential_open_water_et(:),potential_top_radiation_et(:),potential_surface_radiation_et(:)


    REAL(4),ALLOCATABLE:: incremental_q_output(:)
    REAL(4),ALLOCATABLE:: et_output(:)
    REAL(4),ALLOCATABLE:: groundwater_q_output(:)
	REAL(4),ALLOCATABLE:: soil_saturation_output(:)
    REAL(4),ALLOCATABLE:: interception_et_output(:),soil_vegetation_et_output(:),open_water_et_output(:),water_hru_et_output(:)
    REAL(4),ALLOCATABLE:: potential_open_water_et_output(:)
    REAL(4),ALLOCATABLE:: soil_water_output(:),capillary_water_output(:),interception_storage_output(:)
    REAL(4),ALLOCATABLE:: surface_storage_depth_output(:),subsurface_storage_depth_output(:),groundwater_storage_depth_output(:)
    REAL(4),ALLOCATABLE:: surface_runoff_depth_output(:),subsurface_runoff_depth_output(:),groundwater_runoff_depth_output(:)
    REAL(4),ALLOCATABLE:: surface_water_output(:)
    REAL(4),ALLOCATABLE:: catchment_q_output(:)
    REAL,ALLOCATABLE:: total_water_storage(:)
    real,allocatable::  flow_velocity(:) !For computing flow velocities
    integer, allocatable :: hotstart_write_schedule(:)

	! Simulation-range controls.
	INTEGER first_subbasin,last_subbasin !Control especial cases of run
    integer, dimension(:), allocatable :: reservoir_index_by_catchment
	integer, dimension(:), allocatable :: routing_downstream_catchment
    integer, dimension(:), allocatable :: reservoir_start_timestep

	!MANNING
	REAL,ALLOCATABLE:: manning_n(:) !Manning coefficient

    REAL current_catchment_area

    REAL minimum_soil_storage

    ! Shared work arrays used by catchment water balance and routing.
    REAL, ALLOCATABLE :: groundwater_delay(:),subsurface_delay(:),surface_delay(:)            ! Delay and concentration times

    REAL, ALLOCATABLE :: incoming_groundwater_fraction_previous(:)
    REAL, ALLOCATABLE :: incoming_subsurface_fraction_previous(:)
    REAL, ALLOCATABLE :: incoming_surface_fraction_previous(:)
	REAL, ALLOCATABLE :: outgoing_groundwater_fraction_previous(:)
	REAL, ALLOCATABLE :: outgoing_subsurface_fraction_previous(:)
	REAL, ALLOCATABLE :: outgoing_surface_fraction_previous(:)

	END MODULE model_state
