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
    src/fint.f90
    src/tempo.f90
    src/stagearea.f90
    src/semente.f90
    src/utils_date.f90
    src/vars_inerc.f90
    src/vars_main.f90
    src/utils_time.f90
    src/simula.f90
    src/condinic.f90
    src/1main.f90
    src/solo.f90
    src/read_clim_avg.f90
    src/flood_topo.f90
    src/flood_discharge.f90
    src/radiacao.f90
    src/flood_tab.f90
    src/flood_inercial.f90
    src/leuso.f90
    src/le_reserv.f90
    src/met_input_files.f90
    src/flood_readfp.f90
    src/musk.f90
    src/rede.f90
    src/parcunge.f90
    src/alloca_varsinerc.f90
    src/alloca_vars.f90
    src/write_output.f90
    src/evapo.f90
    src/read_met.f90
    src/flood_timestep.f90
    src/flood_continuity.f90
    src/flood_writehot.f90
    src/flood_ini.f90
    src/parcel.f90
    src/lecell.f90
    src/celula.f90
    src/levar.f90
    src/lefloodpln.f90
    src/lesubst.f90
    src/flood_readhot.f90
    src/modelo.f90
    src/read_infomgb.f90
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

