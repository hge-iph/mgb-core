cmake_minimum_required(VERSION 3.25)

project(MGBModel LANGUAGES Fortran)

include(CTest)
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")
include(bootstrap_intel_fortran)

option(ENABLE_FORTRAN_DIAGNOSTICS "Enable opt-in Intel Fortran diagnostics" OFF)

if(NOT CMAKE_Fortran_COMPILER_ID MATCHES "IntelLLVM|Intel")
    message(FATAL_ERROR "The bootstrap build currently supports Intel Fortran only. Current compiler: ${CMAKE_Fortran_COMPILER_ID}")
endif()

set(CMAKE_Fortran_FLAGS_RELEASE "" CACHE STRING "Bootstrap release flags" FORCE)

set(MGB_MODEL_SOURCES
    src/linear_interpolate.f90
    src/update_legacy_timer.f90
    src/interpolate_stage_area.f90
    src/initialize_random_seed.f90
    src/utils_date.f90
    src/inertial_state.f90
    src/model_state.f90
    src/utils_time.f90
    src/run_simulation.f90
    src/initialize_model_state.f90
    src/main.f90
    src/update_soil_water_balance.f90
    src/read_climatology.f90
    src/build_flood_topology.f90
    src/calculate_inertial_discharge.f90
    src/calculate_net_radiation.f90
    src/build_floodplain_tables.f90
    src/route_inertial_flow.f90
    src/read_calibrated_parameters.f90
    src/read_reservoir_data.f90
    src/manage_meteorological_input_files.f90
    src/read_floodplain_binary_data.f90
    src/route_muskingum_cunge.f90
    src/route_muskingum_cunge_network.f90
    src/calculate_muskingum_cunge_parameters.f90
    src/allocate_inertial_state.f90
    src/allocate_model_state.f90
    src/write_model_outputs.f90
    src/calculate_evapotranspiration.f90
    src/read_meteorological_forcing.f90
    src/calculate_inertial_timestep.f90
    src/update_inertial_continuity.f90
    src/write_hotstart.f90
    src/initialize_inertial_routing.f90
    src/calculate_catchment_parameters.f90
    src/read_catchment_data.f90
    src/update_catchment_water_balance.f90
    src/read_fixed_parameters.f90
    src/read_floodplain_text_data.f90
    src/read_substitution_flows.f90
    src/read_hotstart.f90
    src/run_model.f90
    src/read_model_configuration.f90
)

add_executable(mgb_model ${MGB_MODEL_SOURCES})
set_target_properties(mgb_model PROPERTIES
    OUTPUT_NAME mgb_model
    Fortran_MODULE_DIRECTORY "${CMAKE_BINARY_DIR}/modules"
)

mgb_configure_bootstrap_target(mgb_model)

if(BUILD_TESTING)
    find_package(Python3 COMPONENTS Interpreter REQUIRED)

    add_test(
        NAME regression_magdalena
        COMMAND ${Python3_EXECUTABLE}
                ${CMAKE_SOURCE_DIR}/tests/regression/run_regression.py
                --case-dir ${CMAKE_SOURCE_DIR}/tests/regression/magdalena
                --exe $<TARGET_FILE:mgb_model>
    )
endif()

