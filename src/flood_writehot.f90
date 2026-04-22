     
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
    !    2019.02.07 - 02 July 2019 (By: Vinicius Siqueira)    
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
    !  Discussion:
    ! 
    !    This sub-routine reads the hotstart file.
    !
    !
    !---------------------------------------------------------------------------------
    ! Variables and Parameters:
    ! *Variables declarations and routines calls are all commented below.
    !---------------------------------------------------------------------------------
    ! End of header
    !---------------------------------------------------------------------------------
    
    SUBROUTINE flood_WRITEHOT
	!Esta subrotina escreve o arquivo de condições iniciais completo
    ! Modificado por Rodrigo Paiva 18/10/2012 ! RP
    ! Modificado por Vinícius Siqueira em 23/01/2017

    !DECLARAÇÃO DE VARIÁVEIS
	USE VARS_MAIN
    USE VARS_INERC
	
  	!DEFINE QUE NÃO PODEMOS TER VARIÁVEIS IMPLÍCITAS
	IMPLICIT NONE
    integer i,nStatVar,j, i_julian
    real(4),allocatable:: WB_stateVec(:)	 
    real*8,allocatable:: h_stateVec(:)	 
	character(8) strIT 
    character(len=8) :: hotFilename
    
	nStatVar=(nC*nU)+(6*nC)+(nC*nU)+(sum(NSUBT)+nC)+nC !
	
    !For option 1, model state variables are saved only at the end of simulation (i.e. They will allow starting the MGB one timestep after the end date)
    if (flag_WriteHot == 1) then
    
        !Get Julian day and corresponding calendar year, month and day
        i_julian=IDINI+INT((IT+HORAINI)/(86400./DTP))     
              
    !For option 2, check if the current IT is flagged to save MGB initial conditions for the beggining of each time step. 
    !For option 3, model state variables will be saved for the beggining of each time step, and also for the end of simulation. flag_WriteHot will be automatically set to 1 at the end of simulation     
    elseif ((flag_WriteHot == 2 .AND. WriteHotFile(IT)==1) .OR. (flag_WriteHot == 3)) then
                                             
       !Get Julian day and corresponding calendar year, month and day, but subtracting 1 since in this case ICs are saved at the beggining of the time step
       i_julian=IDINI+INT((IT+HORAINI-1)/(86400./DTP))  
         
    else
       return !Exit subroutine  
       
    endif             
    
    !Get the current date
    call DateString(i_julian,IANO,IMES,IDIA,hotFilename)  
    
    open(FILHOTSTART_WB,FILE=INPUT_DIRECTORY_HOTSTART // 'statevars_wb_'// trim(hotFilename) // '.hot',STATUS='unknown',RECL=nStatVar,FORM='UNFORMATTED',ACCESS='DIRECT')
        
    write(*,*)'Writing Water Balance State Variables for: ',hotFilename
    
    allocate(WB_stateVec(nStatVar))
    !******************************************************************************
	! Writing state variables:
	i=0
	do iC=1,nC
		do iU=1,nU
			i=i+1
			WB_StateVec(i)=W(iC,iU) !Soil Water for each HRU
		enddo
	enddo
	do iC=1,nC
			i=i+1
			WB_StateVec(i)=VBAS(iC) !Reservoir Volume for baseflow
	enddo
	do iC=1,nC
			i=i+1
			WB_StateVec(i)=VINT(iC) !Reservoir Volume for subsurface flow
	enddo
	do iC=1,nC
			i=i+1
			WB_StateVec(i)=VSUP(iC) !Reservoir Volume for surface flow
	enddo
	do iC=1,nC
			i=i+1
			WB_StateVec(i)=TA(iC) !Temperature in previous time step
	enddo
	do iC=1,nC
			i=i+1
			WB_StateVec(i)=QM2(iC) !Streamflow at upstream of catchments
	enddo
	do iC=1,nC
			i=i+1
			WB_StateVec(i)=QJ2(iC) !Streamflow at downstream of catchments
	enddo
	do iC=1,nC
		do iU=1,NU
			i=i+1
			WB_StateVec(i)=SI(iC,iU) !Intercepted water stored on canopy reservoir
		enddo
	enddo
	do iC=1,nC
		do j=1,NSUBT(IC)+1
			i=i+1
			WB_StateVec(i)=QRIOINI(iC,j)
		enddo
	enddo
	do iC=1,nC
			i=i+1
			WB_StateVec(i)=QCEL2(iC) !Runoff generated at catchment
	enddo
		
	write(FILHOTSTART_WB,REC=1) (WB_StateVec(i),i=1,nStatVar)
    deallocate(WB_stateVec)	
    
	close(FILHOTSTART_WB)
	!************************************************************
	    
    nStatVar=(9*nC)! Variables from inertial routing
    
    write(*,*)'Writing Hydraulic State Variables for: ',hotFilename
    !All variables below are in double precision (Real*8)
       
    open(FILHOTSTART_Inert,FILE=INPUT_DIRECTORY_HOTSTART // 'statevars_inertial_' // trim(hotFilename) // '.hot',STATUS='unknown',RECL=(nStatVar*2),FORM='UNFORMATTED',ACCESS='DIRECT')   
      
    allocate(H_stateVec(nStatVar))
    
    i=0
    do iC=1,nC
			i=i+1
			H_StateVec(i)=Q2fl(iC) !Streamflow at catchment (iC)
    enddo    
            
    do iC=1,nC
			i=i+1
			H_StateVec(i)=Hfl(iC) !Water depth at catchment (iC)
	enddo    
    
    do iC=1,nC
			i=i+1
			H_StateVec(i)=Yfl(iC) !Water elevation at catchment (iC)
    enddo        
    
    do iC=1,nC
			i=i+1
			H_StateVec(i)=Vol1(iC) !Previous Water storage at catchment (iC)
    enddo
    
    do iC=1,nC
			i=i+1
			H_StateVec(i)=Vol2(iC) !Actual Water storage at catchment (iC)
    enddo
    
    do iC=1,nC
			i=i+1
			H_StateVec(i)=Area2(iC) !Flooded Area at catchment (iC)
    enddo
    
    do iC=1,nC
			i=i+1
			H_StateVec(i)=dble(jtab(iC)) !index of Volume level at catchment (iC)
    enddo
    
    do iC=1,nC
			i=i+1
			H_StateVec(i)=Q2face(iC) !Streamflow coming (or leaving) the catchment through connections 
    enddo
    
    do iC=1,nC
			i=i+1
			H_StateVec(i)=Q2viz(iC) !Updated flow for interconnections (signal can be positive or negative)
    enddo
    
    write(FILHOTSTART_Inert,REC=1) (H_StateVec(i),i=1,nStatVar)
    
    deallocate(H_stateVec)	
    close(FILHOTSTART_Inert)
    
	RETURN
	END