
    !---------------------------------------------------------------------------------
    !  Licensing:
    !
	!Modelo de Grandes Bacias, South America version (MGB-SA). 
    !Copyright (C) 2019  Hidrologia de Grande Escala (HGE)
	!
    !This program is free software: you can redistribute it and/or modify
    !it under the terms of the GNU General Public License as published by
    !the Free Software Foundation, either version 3 of the License, or
    !any later version.
	!
    !This program is distributed in the hope that it will be useful,
    !but WITHOUT ANY WARRANTY; without even the implied warranty of
    !MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    !GNU General Public License for more details.
	!
    !You should have received a copy of the GNU General Public License
    !along with this program.  If not, see <https://www.gnu.org/licenses/>.	
	!
	!---------------------------------------------------------------------------------
    !  Version/Modified: 
    !
    ! 2015.06.21 - 21 June 2015 (By: Fernando Mainardi Fan)   
    !
    !  Authors:
    !
    !    Original fortran version by Walter Collischonn
    !    Present fortran version by:
    !    * Walter Collischonn
    !    * Rodrigo Cauduro Dias de Paiva
    !    * Diogo da Costa Buarque
    !    * Paulo Pontes Rógenes
    !    * Mino  Viana Sorribas
    !    * Fernando Mainardi Fan
    !    * Juan Martin Bravo 
    !    * Vinicius Alencar Siqueira
	!	 * Ayan Santos Fleischmann
	!	 * Sly Wongchuig Correa
    !
    !  Main Reference:
    !
    !    Walter Collischonn,
    !    Modelo de Grandes Bacias - Thesis
    !    Porto Alegre, 2001
    !    ISBN: XXXXXXXXXXX,
    !---------------------------------------------------------------------------------
    !  Variables and Parameters:
    !
    !   * Variables declarations and routines calls are all commented below.
    !
    !---------------------------------------------------------------------------------
    !  Discussion:
    ! 
    !    This routine has the main loop of the MGB-IPH, the time loop, from iT=1,nT
    !     where iT is the time interval and nT is the number of time steps.
	!
	!	 For each time interval date info is set, then rainfall and climate data are
	!	   loaded through subroutines LECHUVA and LECLIMA. Afterwards catchment flow
	!	   generation is done using subroutine CELULA. Finally, river routing is 
	!	   achieved by calling (i) REDE, for Muskingum-Cunge Method or
	!	   (ii) flood_inertial, for a 1D Hydrodynamic Model (w/ inertia and pressure)
	!	
	!
	!
	!	 * iT value should not be changed inside subroutines!
	!
	!    * AUX_MOD module from full hydrodynamic is deactivated (commented)!
	!    * Hidrodinamico2 subroutine from full hydrodynamic is deactivated (commented)!
    !
    !  Usage:
    !
    !    CALL SIMULA
    !
    !    where
    !
    !    * no arguments are passed in this subroutine
    !
    !    uses modules and functions
    !
	!	 * module     IFPORT  			from (visual studio 2008)
    !    * module     VARS_MAIN   		in    VARS_MAIN.f90
	!    * module     VARS_CALIB   		in    VARS_CALIB.f90
    !    * module     VARS_INERC  		in    VARSINERC.f90  !Quais? 
 	!	 * subroutine CONDINIC	  		in	  CONDINIC.f90
	!	 * subroutine MODELO	  		in	  MODELO.f90
	!	 * subroutine FOBJ	  			in	  FOBJ.f90	
	!
    !
    !	 opens
    !
    !
    !    reads
    !
    !    * Does not read files
    !
    !    creates
    !
    !    * Does not create files
    !    
    !end of header
    !---------------------------------------------------------------------------------    

	SUBROUTINE SIMULA	
	USE VARS_MAIN
	USE VARS_INERC
	IMPLICIT NONE
	INTEGER KB,K					!counters
	CHARACTER*10 ALFAQ(NC)			!auxiliar string
	REAL,ALLOCATABLE:: QSOR(:) 		!observed discharges (without "missing data") for sorting and exceedance probaility curve
	CHARACTER (10):: strIHIDG
	CHARACTER (50):: strARQUIVO	
	INTEGER MES,KSOR,IPOS90,IPOS95 				  !indexes and counter
	INTEGER CONTAMES(12)						  !counts number of existent data for mean calculation
	INTEGER IAUX,IPOS,IPERMA
	
    INTEGER ITini
    INTEGER:: i,j
	REAL std,Qmean
	     
    ! Call routine to open (1) output files on disk 
    call OUTPUT_FILES(1)
    
    !Check options for reservoir and substitution flows, currently only working with inertial module
    If(hdFLAG(1)==1)THEN         
        Ind_Reserv=0 !! SIN_RESERV
        if (flag_RES_SUB==1) THEN
            WRITE(*,*) 'READING SUBSTITUTION FLOW DATA' !! SIN_RESERV
            CALL LE_RESERV !! SIN_RESERV            
        endif           
    Endif
    
	! Model initial conditions 
	WRITE(FILLOG,*)'Calling initial conditions...'
	CALL CONDINIC  
    
    !Read hotstart file for water balance and hydraulic state variables (only if Inertial routing is enabled) #VAS 
    if (flag_ReadHot==1) then
        call flood_READHOT 
    end if
    
    ! Checks if there are multiple time steps to write initial conditions. Useful for hindcasting
    if (flag_WriteHot==2) then 
        !Then open file for read
         open(FILHOTLIST,FILE=INPUT_DIRECTORY // 'hotstartlist.prev',STATUS='OLD',ACTION='READ')
        
         WriteHotFile=0
         DO IT=1,NT !Check which ITs we need to write hotstart values
             READ(FILHOTLIST,*)WriteHotFile(IT)  
         ENDDO
         CLOSE(FILHOTLIST)
    endif
    
    ! Time loop for water balance and routing simulation
	WRITE(FILLOG,*)'Running main model routine...'
	CALL MODELO    

    !Write hotstart file for water balance and hydraulic state variables at the end of simulation
    !(only if Inertial routing is enabled) #VAS         
    if (flag_WriteHot==1 .OR. flag_WriteHot==3) then         
        !if flag_writeHot = 3, set to 1. It will generate also the CI 
        !for the end of MGB simulation (to allow starting the model n time step after)
        flag_WriteHot=1 
        call flood_WRITEHOT 
    end if
    
    ! Call routine to close (0) output files 
    call OUTPUT_FILES(0)
           
	RETURN

	END
