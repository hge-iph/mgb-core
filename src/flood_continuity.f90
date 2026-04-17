   
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
    ! 2015.07.06 - 07 July 2015 (by Paulo Pontes)
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
    !    ISBN: XXXXXXXXXXX,!
    !
    !---------------------------------------------------------------------------------
    ! Variables and Parameters:
    ! *Variables declarations and routines calls are all commented below.
    !---------------------------------------------------------------------------------
    !  Discussion:
    ! 
    !    This subroutine calculates the level and depth for each catchment from Continuity equation   (Inertial version).
    !
    !
    ! Usage:
    !
    ! *
    !
    ! uses modules, functions, and subroutines
    !
    ! * USE VARS_MAIN
    ! * USE VARS_INERC (only to Inertial version)
    !
    ! opens
    !
    ! * no files are created in this routine
    !
    ! reads
    !
    ! * no files are created in this routine
    !
    ! creates
    !
    ! * no files are created in this routine
    !
    !---------------------------------------------------------------------------------
    ! End of header
    !---------------------------------------------------------------------------------

	subroutine flood_continuity


	!--------------------------------------------------------------------------------------
	! Variables and parameters:
	use VARS_INERC
	use VARS_MAIN
    use omp_lib
    
	implicit none
		
    SURFWAT=0.0 !CEAA
	!-------------------------------------------------------------------------------------
        
    !$OMP PARALLEL NUM_THREADS(thread_count)
    !$OMP DO PRIVATE(IB,Nentradas,SumQup,Areajtab,yjtab,Volume_temp)
    do iC=1,nC
    
        IB=IBAC(iC) 
		IF((IB<SUBini).OR.(IB>SUBfim))CYCLE ! Manual controls for especialized calibration
    
        
            !Number of upstream catchments of IC
            Nentradas = MINIMONT(iC,1)
            
            !Sum of downstream IC flows
            if(MINIMONT(iC,1)==0)then
                SumQup=0.0
            else
                SumQup = SUM(Q2fl(MINIMONT(iC,2:1+Nentradas)))
            endif
            
            !to use lateral connections
            Vol2(iC) = Vol1(iC)+dtflood*(SumQup+QCEL2(iC)-Q2fl(iC)+Q2viz(IC))-(E0agua(IC)+DINFILT(IC)-P(IC))*dtflood*Area2(iC)*1000000.0/(DTP*1000.)                                                                                                                                         
            Vol2(iC) = max(Vol2(iC),0.0)
            
            !! SIN_RESERV
            if (Ind_Reserv(IC)>0 .and. iTini_reserv(iC)<=iT) then
                Vol2(iC)=min(Vol2(iC),VTAB(2,IC)) ! max vol calha cheia
            endif
            !! SIN_RESERV
           
            !!Added to include evaporation of open waters from floodplain dynamics 
            EVAPTUDO(IC)=EVAPTUDO(IC)+((E0agua(IC)*dtflood*Area2(iC)*1000000.0/(DTP*1000.))/(ACEL(IC)*1000)) !em mm/DTP            
            ETOPENWAT(IC)=ETOPENWAT(IC)+((E0agua(IC)*dtflood*Area2(iC)*1000000.0/(DTP*1000.))/(ACEL(IC)*1000)) !em mm/DTP !CEAA   
            
            !Interpolates the Area and Level from Volume                   
			CALL STAGEAREA(vol2,vtab,jtab,iC,ztab,atab,npfl,NC,yjtab,Areajtab) !Passing arguments to avoid errors in parallel mode
                  
            Area2(iC) = min(Areajtab,ACEL(iC))
            
            !Updates variables:
            Yfl(iC)=max(yjtab,ZTAB(1,IC)+0.001)
            
            !Calculates depth
            Hfl(iC)=Yfl(iC)-ZTAB(1,IC)      
            
            !Updates the volume
            Vol1(iC)=Vol2(iC)                
                     
            !Writes TWS for GRACE comparison
            if (tflood/dtflood0==1) then
                
                !Update Terrestrial Water Storage at the end of inertial loop            
                TWS2(IC)=TWS2(IC)+real(Vol2(IC)/dble(ACEL(IC)*1000.0))                
                SURFWAT(IC)=SURFWAT(IC)+real(Vol2(IC)/dble(ACEL(IC)*1000.0)) !CEAA
             
            end if                      
            
    enddo
	!$OMP END DO
	!$OMP END PARALLEL
	
	endsubroutine