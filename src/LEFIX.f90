
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
    !    2015.21.06 - 21 June 2015 (By: Fernando Mainardi Fan)    
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
    !    This routine reads simulation setup patameters
	!
	!	 LECLIMED is called inside subroutine MGB_Inercial.
	!
	!	 Saves global variable: 
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
    !
    !	 opens
    !
    !    * Opens infoMGB.sim file  containing simulation setup parameters.
    !
    !    reads
    !
    !    * Reads infoMGB.sim file  containing simulation setup parameters.
    !
    !    creates
    !
    !    * Does not create files
    !    
    ! end of header
    !---------------------------------------------------------------------------------		


	SUBROUTINE LEFIX
	USE VARS_MAIN
    USE VARS_INERC
    
	IMPLICIT NONE
	INTEGER K
	
	! Opens input file contaning simulation setup parameters
	OPEN(FILFIX,FILE=INPUT_DIRECTORY // 'infoMGB.sim',STATUS='OLD',ACTION='READ')
	READ(FILFIX,75)TITULO ! Reads text comments
	!WRITE(*,*)TITULO
	READ(FILFIX,75)TITULO ! Reads blanc line
	!WRITE(*,*)TITULO
	READ(FILFIX,75)TITULO ! Reads text comments
	!WRITE(*,*)TITULO !ENABLE TO SHOW IN THE SCREEN
	READ(FILFIX,*)TITULO ! Reads blanc line
	!WRITE(*,*)TITULO !ENABLE TO SHOW IN THE SCREEN
	!READ(*,*)
	READ(FILFIX,72)(CABE(K),K=1,4)
	!WRITE(*,72)(CABE(K),K=1,4) !ENABLE TO SHOW IN THE SCREEN
	READ(FILFIX,71)IDIA,IMES,IANO,HORAINI ! Reads initial time of simulation: day, mounth, year, and hour
	!WRITE(*,71)IDIA,IMES,IANO,HORAINI !ENABLE TO SHOW IN THE SCREEN
	!READ(*,*)
	READ(FILFIX,*) ! Blank line
	READ(FILFIX,72)(CABE(K),K=1,2)
	!WRITE(*,72)(CABE(K),K=1,2) !ENABLE TO SHOW IN THE SCREEN
	READ(FILFIX,76)NT,DTP,alpha ! Reads number of time steps and size of time step (sec)
	!WRITE(*,76)NT,DTP !ENABLE TO SHOW IN THE SCREEN
	READ(FILFIX,*) ! Blanc line
	READ(FILFIX,72)(CABE(K),K=1,4)
	!WRITE(*,72)(CABE(K),K=1,4) !ENABLE TO SHOW IN THE SCREEN
	!READ(FILFIX,71)NC,NU,NB,NCLI ! Reads number of catchments, HRUs, sub-basins and climate stations
    READ(FILFIX,71)NC,NU,NB,NREG,NCLI,CRU_INDEX,RESERV_INDEX,INERTIAL_INDEX,PSEUDO_TwoD_INDEX ! Reads number of catchments, HRUs, sub-basins, climate regions and climate stations
    READ(FILFIX,*) ! Blanc line.
	READ(FILFIX,72)(CABE(K),K=1,1)
    READ(FILFIX,73)WSslope,bflow_overland,xMan_overland !Reads (Downstream Water surface slope; width for lateral connections; manning for lateral connections)
    WSslope=WSslope*0.001 !converting from m/km to m/m
        
	READ(FILFIX,*) ! Blanc line.
	READ(FILFIX,72)(CABE(K),K=1,1)
	!WRITE(*,72)(CABE(K),K=1,1) !ENABLE TO SHOW IN THE SCREEN
	READ(FILFIX,71)ICALIB
	!WRITE(*,71)ICALIB !ENABLE TO SHOW IN THE SCREEN
	READ(FILFIX,*) ! Blanc line
	READ(FILFIX,75)TITULO !Text comments
	!WRITE(*,*)TITULO !ENABLE TO SHOW IN THE SCREEN				
	!Flags for inertial and Write 
    READ(FILFIX,71)flag_ReadHot,flag_WriteHot
    
    READ(FILFIX,*) ! Blanc line
    READ(FILFIX,75)TITULO !Text comments
    
    if(NCLI<=0)then ! Control type of meteorological data.
	      !arquivo do CRU
	      NCLI=-NCLI
	      flagaclimed=1	! Use CRU data.
	    else
	      flagaclimed=0
	      DO K=1,NCLI
	          READ(FILFIX,77)ARQCLI(K)
	          !WRITE(*,77)ARQCLI(K) !ENABLE TO SHOW IN THE SCREEN
	      ENDDO
    endif
    
	READ(FILFIX,*) ! Blanc line
	READ(FILFIX,75)TITULO ! Text comments
	!WRITE(*,*)TITULO !ENABLE TO SHOW IN THE SCREEN
	READ(FILFIX,*)ACLIMED
	!WRITE(*,*)ACLIMED !ENABLE TO SHOW IN THE SCREEN
	!READ(*,*)
	READ(FILFIX,*) ! Blanc line
	READ(FILFIX,75)TITULO ! Text comments
	!WRITE(*,*)TITULO !ENABLE TO SHOW IN THE SCREEN
	READ(FILFIX,*)NOBS,ARQOBS !Reads number of stream flow gauging stations and name of file with discharge data. 
	!WRITE(*,*)NOBS,ARQOBS !ENABLE TO SHOW IN THE SCREEN
	!READ(*,*)
	READ(FILFIX,*) ! Blanc line
	READ(FILFIX,75)TITULO ! Text comments
	!WRITE(*,*)TITULO !ENABLE TO SHOW IN THE SCREEN
	READ(FILFIX,*)(IQOBS(K),K=1,NOBS) ! ID codes of catchments for each gauge
	!WRITE(*,*)(IQOBS(K),K=1,NOBS) !ENABLE TO SHOW IN THE SCREEN
	!READ(*,*)
	READ(FILFIX,*) ! Blanc line
	READ(FILFIX,75)TITULO ! Text comments. 
	!WRITE(*,*)TITULO !ENABLE TO SHOW IN THE SCREEN
	READ(FILFIX,*)NUMHIDG ! Number of catchments to write discharge time series. 
	!WRITE(*,*)NUMHIDG !ENABLE TO SHOW IN THE SCREEN
	!READ(*,*)
	READ(FILFIX,*) ! Blanc line
	READ(FILFIX,75)TITULO ! Text comments
	!WRITE(*,*)TITULO !ENABLE TO SHOW IN THE SCREEN
	!READ(*,*)
	DO K=1,NUMHIDG
	    READ(FILFIX,*)IHIDG(K)!,ARQHID(K) ! ID codes of catchments where discharge time series will be saved. 
	    !WRITE(*,*)IHIDG(K)!,ARQHID(K) !ENABLE TO SHOW IN THE SCREEN
	    ! pause
	ENDDO
	!WRITE(*,*) (IHIDG(K),K=1,NUMHIDG)
	!READ(*,*)
	READ(FILFIX,*)
	READ(FILFIX,75)TITULO !LE TEXTO
	!WRITE(*,*)TITULO !ENABLE TO SHOW IN THE SCREEN
	READ(FILFIX,*)nSIN,ARQSUBST ! Number of catchments for discharge substitution. (Discharge is read from input file) and name of file with discharge data. 
	!WRITE(*,*)nSIN,ARQSUBST !ENABLE TO SHOW IN THE SCREEN
	!READ(*,*)
	READ(FILFIX,*)
	READ(FILFIX,75)TITULO
	!WRITE(*,*)TITULO !ENABLE TO SHOW IN THE SCREEN
	!READ(*,*)
	DO K=1,NUMSUBST
	    READ(FILFIX,*)ISUBST(K) ! ID codes of catchments where discharge substitution is performed
	    !WRITE(*,*)ISUBST(K) !ENABLE TO SHOW IN THE SCREEN
    ENDDO
	!READ(*,*)    
    READ(FILFIX,*)
	READ(FILFIX,75)TITULO !LE TEXTO    
    READ(FILFIX,*)SUBini,SUBfim !Interval of subasins for which simulation will occur
    
	CLOSE (FILFIX)
	71	FORMAT(9I10)
	72	FORMAT(5A10)
	73	FORMAT(3F10.2)
	74	FORMAT(A10)
	75	FORMAT(A20)
	76	FORMAT(I10,F10.1,F10.2)
	77	FORMAT(A20)
	RETURN
	END
