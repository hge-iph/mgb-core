function(mgb_configure_fortran_target target)
    target_link_libraries(${target} PRIVATE OpenMP::OpenMP_Fortran)

    if(CMAKE_Fortran_COMPILER_ID MATCHES "IntelLLVM|Intel")
        set(mgb_fortran_diagnostics)
        if(ENABLE_FORTRAN_DIAGNOSTICS)
            if(WIN32)
                list(APPEND mgb_fortran_diagnostics
                    /warn:declarations
                    /warn:unused
                    /warn:interfaces
                )
            elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
                list(APPEND mgb_fortran_diagnostics
                    "SHELL:-warn declarations"
                    "SHELL:-warn unused"
                    "SHELL:-warn interfaces"
                )
            endif()
        endif()

        if(WIN32)
            target_compile_options(${target} PRIVATE
                $<$<COMPILE_LANGUAGE:Fortran>:/MP>
                $<$<COMPILE_LANGUAGE:Fortran>:/threads>
                $<$<COMPILE_LANGUAGE:Fortran>:/libs:dll>
                $<$<COMPILE_LANGUAGE:Fortran>:/Qmkl:parallel>
                $<$<AND:$<COMPILE_LANGUAGE:Fortran>,$<CONFIG:Release>>:/O3>
                $<$<AND:$<COMPILE_LANGUAGE:Fortran>,$<CONFIG:Release>>:/Qipo>
                $<$<COMPILE_LANGUAGE:Fortran>:${mgb_fortran_diagnostics}>
            )
        elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
            target_compile_options(${target} PRIVATE
                $<$<COMPILE_LANGUAGE:Fortran>:-threads>
                $<$<COMPILE_LANGUAGE:Fortran>:-qmkl=parallel>
                $<$<AND:$<COMPILE_LANGUAGE:Fortran>,$<CONFIG:Release>>:-O3>
                $<$<AND:$<COMPILE_LANGUAGE:Fortran>,$<CONFIG:Release>>:-ipo>
                $<$<COMPILE_LANGUAGE:Fortran>:${mgb_fortran_diagnostics}>
            )
            target_link_options(${target} PRIVATE
                $<$<LINK_LANGUAGE:Fortran>:-qmkl=parallel>
                $<$<AND:$<LINK_LANGUAGE:Fortran>,$<CONFIG:Release>>:-ipo>
            )
        else()
            message(FATAL_ERROR "Intel Fortran flags are configured only for Windows and Linux.")
        endif()
    elseif(CMAKE_Fortran_COMPILER_ID STREQUAL "GNU")
        set(mgb_fortran_diagnostics)
        if(ENABLE_FORTRAN_DIAGNOSTICS)
            list(APPEND mgb_fortran_diagnostics
                -Wall
                -Wextra
                -Wimplicit-interface
            )
        endif()

        target_compile_options(${target} PRIVATE
            $<$<COMPILE_LANGUAGE:Fortran>:-ffree-line-length-none>
            $<$<AND:$<COMPILE_LANGUAGE:Fortran>,$<CONFIG:Release>>:-O3>
            $<$<COMPILE_LANGUAGE:Fortran>:${mgb_fortran_diagnostics}>
        )
    endif()
endfunction()
