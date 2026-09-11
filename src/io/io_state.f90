module io_state

    use runoff_state, only: max_subbasin_count

    implicit none
    private
    save

    public :: calibrated_parameter_unit, catchment_data_unit, climate_region_unit, &
        & climatology_unit, config_unit, discharge_output_unit, et_output_unit, &
        & face_connection_unit, fixed_parameter_unit, flood_area_unit, flood_stage_unit, &
        & flooded_area_output_unit, groundwater_flux_output_unit, groundwater_storage_output_unit, &
        & hand_output_unit, header_fields, hotstart_input_directory, hotstart_list_unit, &
        & inertial_hotstart_unit, input_directory, interception_et_output_unit, &
        & interception_storage_output_unit, log_unit, open_water_et_output_unit, output_directory, &
        & potential_open_water_et_output_unit, precipitation_unit, pressure_unit, radiation_unit, &
        & relative_humidity_unit, runoff_output_unit, soil_saturation_output_unit, &
        & soil_vegetation_et_output_unit, soil_water_output_unit, stage_area_unit, &
        & substitution_flow_unit, subsurface_flux_output_unit, subsurface_storage_output_unit, &
        & surface_flux_output_unit, surface_storage_output_unit, surface_water_output_unit, &
        & temperature_unit, total_water_storage_output_unit, water_balance_hotstart_unit, &
        & water_hru_et_output_unit, water_surface_elevation_output_unit, wind_unit

    character(8) input_directory
    character(9) output_directory
    character(11) hotstart_input_directory
    integer, parameter :: config_unit = 1
    integer, parameter :: fixed_parameter_unit = 2
    integer, parameter :: calibrated_parameter_unit = 3
    integer, parameter :: catchment_data_unit = 4
    integer, parameter :: climate_region_unit = 9
    integer, parameter :: substitution_flow_unit = 10
    integer, parameter :: flood_stage_unit = 14
    integer, parameter :: flood_area_unit = 15
    integer, parameter :: climatology_unit = 16
    integer, parameter :: water_balance_hotstart_unit = 17
    integer, parameter :: inertial_hotstart_unit = 18
    integer, parameter :: log_unit = 26
    integer, parameter :: stage_area_unit = 41
    integer, parameter :: face_connection_unit = 42
    integer, parameter :: hotstart_list_unit = 46
    integer, parameter :: precipitation_unit = 50
    integer, parameter :: temperature_unit = 51
    integer, parameter :: radiation_unit = 52
    integer, parameter :: relative_humidity_unit = 53
    integer, parameter :: wind_unit = 54
    integer, parameter :: pressure_unit = 55
    integer, parameter :: discharge_output_unit = 1973
    integer, parameter :: et_output_unit = 1974
    integer, parameter :: water_surface_elevation_output_unit = 1975
    integer, parameter :: hand_output_unit = 1976
    integer, parameter :: total_water_storage_output_unit = 1977
    integer, parameter :: flooded_area_output_unit = 1978
    integer, parameter :: soil_saturation_output_unit = 1979
    integer, parameter :: interception_et_output_unit = 1980
    integer, parameter :: soil_vegetation_et_output_unit = 1981
    integer, parameter :: open_water_et_output_unit = 1982
    integer, parameter :: soil_water_output_unit = 1983
    integer, parameter :: groundwater_storage_output_unit = 1984
    integer, parameter :: subsurface_storage_output_unit = 1985
    integer, parameter :: surface_storage_output_unit = 1986
    integer, parameter :: interception_storage_output_unit = 1987
    integer, parameter :: groundwater_flux_output_unit = 1988
    integer, parameter :: subsurface_flux_output_unit = 1989
    integer, parameter :: surface_flux_output_unit = 1990
    integer, parameter :: surface_water_output_unit = 1991
    integer, parameter :: runoff_output_unit = 1992
    integer, parameter :: water_hru_et_output_unit = 1993
    integer, parameter :: potential_open_water_et_output_unit = 1994
    character(10) header_fields(max_subbasin_count)

end module io_state
