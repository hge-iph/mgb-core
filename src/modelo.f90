
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
    !    2026.03.11 - 11 March 2026 (By: Vinicius Siqueira)    
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
    !    CALL MODELO
    !
    !    where
    !
    !    * no arguments are passed in this subroutine
    !
    !    uses modules and functions
    !
	!	 * function CALDAT	      		in	  caldat.f90
    !    * module     VARS_MAIN   		in    VARS_MAIN.f90
    !    * module     VARS_INERC  		in    VARSINERC.f90   
 	!	 * subroutine LECHUVA	  		in	  LECHUVA.f90
	!	 * subroutine LECLIMA	  		in	  LECLIMA.f90
	!	 * subroutine CELULA	  		in	  CELULA.f90
	!	 * subroutine REDE	      		in	  REDE.f90	
	!	 * subroutine flood_inercial	in	  flood_inercial.f90
	!
	!    Deactivated:	
	!	 * module	  AUX_MOD        	in	  HD_AUX_MOD.f90
	!	 * subroutine Hidrodinamico2	in	  Hidrodinamico2.f90
    !
    !	 opens
    !
    !    * Does not open files
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
    
	SUBROUTINE MODELO

	USE VARS_MAIN
	USE VARS_INERC
    use utils_time, only: julday_rl, caldat_rl
    
	IMPLICIT NONE
    
    integer, parameter :: wp=8
    real stats_max_q, stats_perc_comp ! Current statistics
    
    ! Write header for simulation statistics
    Write(*,*)' IT         Date       Max flow (m3/s)   % Complete' 

    ! Initialize model time step
	IT=0 
    
    DO WHILE (IT<NT)
		
        ! Advance time
		IT=IT+1
		        		       
        ! Write hotstart file for water balance and hydraulic state variables (only if Inertial routing is enabled) #VAS 
        if (flag_WriteHot == 2 .OR. flag_WriteHot == 3) then
           call flood_WRITEHOT              
        end if
        
        ! compute calendar date
        call caldat_rl(jday,IANO,IMES,IDIA,IHORA,IMINUTO)
        
        ! Write simulation details on screen
        ! Get simulation statistics
        stats_max_q = maxval(QJ2)  ! Maximum flow for the entire model domain 
        stats_perc_comp = (100. * real(it)/real(NT)) !% of simulation completion
        WRITE(*,71) IT,IANO,IMES,IDIA,IHORA,IMINUTO,stats_max_q,stats_perc_comp
                 	    	
		! Reads climate data
		TONTEM=TA
        CALL READ_MET(IMES,IT) ! Read rainfall and other met variables 
	    
        ! Perform vertical water balance
		CALL CELULA		
       
	    ! Call main river routing routine using Muskingum-Cunge Method
		if (hdFLAG(1)==0) then									
		    CALL REDE
		endif     

		! Calculates lateral inflow 
        do ic=1,nc
		    QCEL2(IC) = QBAS(IC) + QINT(IC) + QSUP(IC) !sums surface, subsurface and           
        enddo
        
        ! Calls river routing routine using Inertial Method
        if (hdFLAG0>0) then
            CALL flood_inercial
        endif        
            
        !Modified in order to write results in disk for each IT #Vinicius Siqueira 21/12/2016
        !! Sly + Vinicius  !! Alocar 4 bytes before         
        !=====================================================================                           
        DO IC=1,NC                            
            QTUDO(IC)=Q2fl(IC)                                                                      
            YTUDO(IC)=Yfl(IC)
            TWSTUDO(IC) =TWS2(IC)
            ALAGTUDO(IC)=Area2(IC)
            QCELTUDO(IC)=QCEL2(IC) 
            HANDTUDO(IC) = Yfl(IC) - REAL(ZTAB(1,IC)) - REAL(HRIO(IC))
        ENDDO  
        
        ! Calls routine to write results on disk
        CALL WRITE_OUTPUT
   
        ! Advance Julian date for next time step
        jday = julday_rl(IANO,IMES,IDIA,IHORA,IMINUTO) &
                      + (real(DTP,wp) / 86400.0_wp)  
    
    ENDDO !End time loop
	    
71  FORMAT(I5,"    ",I4,"-",I2.2,"-",I2.2," ",I2.2,":",I2.2,"  ",f10.1,"      ",f5.1," %")
75	FORMAT(I6,13F10.4)
66	FORMAT(<nC>F10.4)

     
	RETURN
	END
