  
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
    !
    !---------------------------------------------------------------------------------
    !  Variables and Parameters:
    !
    !   *Variables declarations and routines calls are all commented below.
	!	* All variables are global!?
    !   
    !---------------------------------------------------------------------------------
    !  Discussion:
    ! 
    !    This routine reads parameters of each catchment as surface area, upstream area, river length, etc...

	!
	!	 LECELL is called inside subroutine MGB_Inercial.
	!
	!	 Saves global variables of main catchment parameters:
	!     	X = longitude of catchment centroid,Y = latitude of catchment centroid
	!       IBAC = subbasin ID code
	!       ACEL = surface area (km2)
	!       ACUR = upstream dreainage area (km2)
	!       SRIO = main river length (km)
	!       DECL = valley slope of main river
	!       LCEL = length of main river tributary
	!       HCEL - valley slope of main tributary
	! 	    CELJUS = ID code of downstream catchment
	!       OD = catchment order
	!       hdFLAG = flag for hydrodynamic flow routing
	!       PUSO = fractions of hydrological response units HRUs 
	!
	!
	!
    !
    !  	Usage:
    !
    !    * no subroutine is called in this subroutine
    !
    !    where
    !
    !    * no arguments are passed in this subroutine
    !
    !    uses modules and functions
    !
    !    * module     VARS_MAIN   in      VARS_MAIN.f90
	!    * module     VARS_INERC   in     VARS_INERC.f90
    !
    !	 opens
    !
    !    * mini.gtp input file containing catchment parameters
    !
    !    reads
    !
    !    * mini.gtp input file containing catchment parameters
    !
    !    creates
    !
    !    * Does not create files
    !    
    ! End of header
    !---------------------------------------------------------------------------------

	SUBROUTINE LECELL
	USE VARS_MAIN
	USE VARS_INERC
	IMPLICIT NONE
	! Local variables
	INTEGER ICELL(NC)
	INTEGER IBANT,I,K,KW,ICMaxArea
	integer aux !RP
	real MaxArea !VAS
    real PUSO2
    
    MaxArea=0.0 
    
	! Opens mini.gtp:
	OPEN(FILHIG,FILE=INPUT_DIRECTORY // 'mini.gtp',STATUS='OLD')
	READ(FILHIG,77) !RP
	IBANT=1
	IEXUT=-999999
	DO I=1,NC
		READ(FILHIG,*)aux,ICELL(I),X(I),Y(I),IBAC(I),ACEL(I),ACUR(I),SRIO(I),DECL(I),LCEL(I),HCEL(I),CELJUS(I),OD(I),hdFLAG(I),BRIO(I),HRIO(I),RUGMAN(I),(PUSO(I,K),K=1,NU) ! RP
       
        !HRIO(I)=HRIO(I)*10.0 !CEAA balanco
        !BRIO(I)=BRIO(I)*20.0
        
        !QREF(I)=0.333*ACUR(I) !Calculates reference initial discharge
        QREF(I)=0.333*ACUR(I)**0.7 !Calculates reference initial discharge
                          
		nMan(I)=RUGMAN(I) !Reads inertial model subroutines manning 
        
        ! WRITE(*,*)(PUSO(I,K),K=1,NU)
		! Check errors in HRU fractions:
		if (sum(PUSO(I,:))>100.01.or.sum(PUSO(I,:))<99.99.or.minval(PUSO(I,:))<0.0.or.maxval(PUSO(I,:))>100.0) then
			write(*,*) 'Error in the % of HRUs in the catchments',i
			write(*,*) 'Sum=',sum(PUSO(I,:)),'Min=',minval(PUSO(I,:)),'no HRU ',minloc(PUSO(I,:)),'Max=',maxval(PUSO(I,:)),' at HRU',maxloc(PUSO(I,:))
			read(*,*)
		endif
		! Define outlet of sub-basins:
		! Outlet equals catchment of larger ID code.
		KW=IBAC(I)
		!write(*,*)'KW,IEXUT =',KW, IEXUT
		IF(IEXUT(KW)<ICELL(I)) IEXUT(KW)=ICELL(I)
		
        !Set Outlet values for catchments in disabled subasins as constant slope #VAS 01/02/2017
        IF((IBAC(I)<SUBini).OR.(IBAC(I)>SUBfim))then
            CELJUS(I)=-1
        else
           IF(ACUR(I)>MaxArea)then 
            ICMaxArea=I !Identify The IC corresponding to Outlet in enabled subasins
            MaxArea=ACUR(I)
           End if 
        End if                        
            
    ENDDO
	
    CELJUS(ICMaxArea)=-1 !Set Outlet value for the catchment with the largest upstream area. #VAS
    
    ! IEXUT(KW+1)=NC ! Outlet of last subbasin is the catchment with larger ID code. !RP verificar
	! Sub-basins = 1
	!write(*,*)'ATENCAO: Sub-Bacias = 1'
	!IBAC=1
	write(*,*)''
	write(*,*)'Minimun reach lenght set to 2.5 km'
	! Correct length of main river. Minimum length = 2.5 km:   
	do iC=1,nC
		SRIO(iC)=max(SRIO(iC),2.5) 
	enddo
	! Change units of river slope to m/m
	write(*,*)'Reach slopes from geometry transformed to m/m'
	DECL=DECL/1000.0 !RP
	! Correct length of longest tributary:
	write(*,*)'Minimun tributarie lenght set to 0.001 km'
	do iC=1,nC
		LCEL(iC)=max(LCEL(iC),0.001)
	enddo
	write(*,*)'Radiation calculation is using sunshine'
    
    !Correct URH water area for hydrodynamic routing !CEAA
    if(flag_opt_rout==1) then    
    write(*,*)'Redistributing the area of HRU water to other uses'
    !LEUSO.F90 must be called before this
        do iC=1,nC
            IB=IBAC(IC)
            PUSO2=0.0
            !HRU loop
            do iU=1,NU
                !if HRU is water
                if(WM(IB,IU)<0.001) then
                    !if unit-catchment is only water
                    if(PUSO(IC,IU)>99.999) then
                        do i=1,NU
                            !HRUs will have the same area
                            PUSO(IC,IU)=100./DBLE(NU)
                        enddo
                    endif
                    !Eliminating HRU water
                    PUSO2=PUSO(IC,IU)
                    PUSO(IC,IU)=0.0
                endif
            enddo
            !Redistributing HRU Water to other catchments
            do iU=1,NU
                PUSO(IC,IU)=PUSO(IC,IU)+PUSO(IC,IU)*PUSO2/(100.-PUSO2)
            enddo
        enddo    
    endif
    
	write(*,*)''
	
	CLOSE (FILHIG)
77	FORMAT(I5,2F15.3,I5,2F10.1,2I5,F10.2,F10.6,I5,6F5.1)
	RETURN
	END
