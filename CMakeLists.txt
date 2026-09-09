cmake_minimum_required(VERSION 3.25)

project(MGBModel LANGUAGES Fortran)

include(CTest)
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")
include(configure_fortran)

option(ENABLE_FORTRAN_DIAGNOSTICS "Enable opt-in Fortran compiler diagnostics" OFF)

if(NOT CMAKE_Fortran_COMPILER_ID MATCHES "GNU|IntelLLVM|Intel")
    message(FATAL_ERROR
        "Supported Fortran compilers are GNU Fortran and Intel Fortran. "
        "Current compiler: ${CMAKE_Fortran_COMPILER_ID}"
    )
endif()

find_package(OpenMP REQUIRED COMPONENTS Fortran)

set(CMAKE_Fortran_FLAGS_RELEASE "" CACHE STRING "Bootstrap release flags" FORCE)

set(MGB_COMMON_SOURCES
    src/common/date_time.f90
    src/common/interpolation.f90
    src/common/runtime_support.f90
)

set(MGB_SIMULATION_SOURCES
    src/simulation/simulation_state.f90
    src/simulation/simulation_runner.f90
)

set(MGB_CATCHMENT_SOURCES
    src/catchment/catchment_state.f90
    src/catchment/meteorological_state.f90
    src/catchment/water_balance_state.f90
    src/catchment/catchment_hydrology.f90
)

set(MGB_RESERVOIR_SOURCES
    src/reservoirs/reservoir_state.f90
)

set(MGB_ROUTING_SOURCES
    src/routing/muskingum/muskingum_state.f90
    src/routing/muskingum/muskingum_routing.f90
    src/routing/inertial/inertial_state.f90
    src/routing/inertial/inertial_routing.f90
)

set(MGB_IO_SOURCES
    src/io/io_state.f90
    src/io/output_state.f90
    src/io/configuration_io.f90
    src/io/static_input_io.f90
    src/io/meteorological_io.f90
    src/io/hotstart_io.f90
    src/io/output_io.f90
)

set(MGB_APPLICATION_SOURCES
    src/application/main.f90
)

add_executable(mgb_model
    ${MGB_COMMON_SOURCES}
    ${MGB_SIMULATION_SOURCES}
    ${MGB_CATCHMENT_SOURCES}
    ${MGB_RESERVOIR_SOURCES}
    ${MGB_ROUTING_SOURCES}
    ${MGB_IO_SOURCES}
    ${MGB_APPLICATION_SOURCES}
)
set_target_properties(mgb_model PROPERTIES
    OUTPUT_NAME mgb_model
    Fortran_MODULE_DIRECTORY "${CMAKE_BINARY_DIR}/modules"
)

mgb_configure_fortran_target(mgb_model)

if(BUILD_TESTING)
    find_package(Python3 COMPONENTS Interpreter REQUIRED)

    add_test(
        NAME architecture
        COMMAND ${Python3_EXECUTABLE} ${CMAKE_SOURCE_DIR}/scripts/check_fortran_architecture.py
    )

    add_test(
        NAME regression_magdalena_inertial
        COMMAND ${Python3_EXECUTABLE}
                ${CMAKE_SOURCE_DIR}/tests/regression/run_regression.py
                --case-dir ${CMAKE_SOURCE_DIR}/tests/regression/magdalena_inertial
                --exe $<TARGET_FILE:mgb_model>
    )

    add_test(
        NAME regression_magdalena_muskingum
        COMMAND ${Python3_EXECUTABLE}
                ${CMAKE_SOURCE_DIR}/tests/regression/run_regression.py
                --case-dir ${CMAKE_SOURCE_DIR}/tests/regression/magdalena_muskingum
                --exe $<TARGET_FILE:mgb_model>
    )
endif()
