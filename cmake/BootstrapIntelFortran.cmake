function(mgb_configure_bootstrap_target target)
    if(CMAKE_Fortran_COMPILER_ID MATCHES "IntelLLVM|Intel")
        target_compile_options(${target} PRIVATE
            $<$<COMPILE_LANGUAGE:Fortran>:/MP>
            $<$<COMPILE_LANGUAGE:Fortran>:/Qopenmp>
            $<$<COMPILE_LANGUAGE:Fortran>:/threads>
            $<$<COMPILE_LANGUAGE:Fortran>:/libs:dll>
            $<$<COMPILE_LANGUAGE:Fortran>:/Qmkl:parallel>
            $<$<AND:$<COMPILE_LANGUAGE:Fortran>,$<CONFIG:Release>>:/O3>
            $<$<AND:$<COMPILE_LANGUAGE:Fortran>,$<CONFIG:Release>>:/Qipo>
        )
    endif()
endfunction()
