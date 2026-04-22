function(mgb_configure_bootstrap_target target)
    if(CMAKE_Fortran_COMPILER_ID MATCHES "IntelLLVM|Intel")
        if(WIN32)
            target_compile_options(${target} PRIVATE
                $<$<COMPILE_LANGUAGE:Fortran>:/MP>
                $<$<COMPILE_LANGUAGE:Fortran>:/Qopenmp>
                $<$<COMPILE_LANGUAGE:Fortran>:/threads>
                $<$<COMPILE_LANGUAGE:Fortran>:/libs:dll>
                $<$<COMPILE_LANGUAGE:Fortran>:/Qmkl:parallel>
                $<$<AND:$<COMPILE_LANGUAGE:Fortran>,$<CONFIG:Release>>:/O3>
                $<$<AND:$<COMPILE_LANGUAGE:Fortran>,$<CONFIG:Release>>:/Qipo>
            )
        elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
            target_compile_options(${target} PRIVATE
                $<$<COMPILE_LANGUAGE:Fortran>:-qopenmp>
                $<$<COMPILE_LANGUAGE:Fortran>:-threads>
                $<$<COMPILE_LANGUAGE:Fortran>:-qmkl=parallel>
                $<$<AND:$<COMPILE_LANGUAGE:Fortran>,$<CONFIG:Release>>:-O3>
                $<$<AND:$<COMPILE_LANGUAGE:Fortran>,$<CONFIG:Release>>:-ipo>
            )
            target_link_options(${target} PRIVATE
                $<$<LINK_LANGUAGE:Fortran>:-qopenmp>
                $<$<LINK_LANGUAGE:Fortran>:-qmkl=parallel>
                $<$<AND:$<LINK_LANGUAGE:Fortran>,$<CONFIG:Release>>:-ipo>
            )
        else()
            message(FATAL_ERROR "Intel Fortran bootstrap flags are configured only for Windows and Linux.")
        endif()
    endif()
endfunction()
