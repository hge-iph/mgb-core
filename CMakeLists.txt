cmake_minimum_required(VERSION 3.25)

project(MGBModel LANGUAGES Fortran)

include(CTest)
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")
include(BootstrapIntelFortran)

if(NOT CMAKE_Fortran_COMPILER_ID MATCHES "IntelLLVM|Intel")
    message(FATAL_ERROR "The bootstrap build currently supports Intel Fortran only. Current compiler: ${CMAKE_Fortran_COMPILER_ID}")
endif()

set(CMAKE_Fortran_FLAGS_RELEASE "" CACHE STRING "Bootstrap release flags" FORCE)

set(MGB_MODEL_SOURCES
    src/julday.f90
    src/Date_parser.F90
    src/STAGEAREA.f90
    src/FINT.f90
    src/caldat.f90
    src/VARS_INERC.f90
    src/VARS_MAIN.f90
    src/LEUSO.f90
    src/MUSK.f90
    src/MET_INPUT_FILES.F90
    src/LECELL.f90
    src/TEMPO.f90
    src/flood_timestep.f90
    src/EVAPO.f90
    src/SOLO.f90
    src/flood_discharge.f90
    src/SEMENTE.f90
    src/READ_CLIM_AVG.f90
    src/ALLOCA_VARSINERC.f90
    src/REGION.f90
    src/flood_inercial.f90
    src/SIMULA.f90
    src/flood_ini.f90
    src/RADIACAO.f90
    src/CondInic.f90
    src/ALLOCA_VARS.f90
    src/MODELO.f90
    src/LEVAR.f90
    src/LE_RESERV.f90
    src/READ_MET.F90
    src/READ_INFOMGB.f90
    src/flood_READHOT.f90
    src/flood_readFP.f90
    src/DateString.f90
    src/WRITE_OUTPUT.F90
    src/flood_continuity.f90
    src/REDE.f90
    src/flood_TOPO.f90
    src/PARCUNGE.f90
    src/PARCEL.f90
    src/LESUBST.f90
    src/LEFLOODPLN.f90
    src/flood_WRITEHOT.f90
    src/flood_TAB.f90
    src/1main.f90
    src/CELULA.f90
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


