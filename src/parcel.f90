
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
    !    2014.25.11 - 25 November 2014 (By: Mino V. Sorribas)    
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
    !   *Variables declarations and routines calls are all commented below.
    !
    !---------------------------------------------------------------------------------	
    !  Discussion:
    ! 
    !    This routine sets catchment additional parameters, mainly width and depth given by
	!		geomorphological relations. Also reference discharge for Muskingum-Cunge method
	!		and concentration time for catchment routing are calculated.
	!
	!	 PARCEL is called in MGB-IPH Main routine.
	!	
    !	 It calls subroutine INTECLIM to assing nearest climate station for each catchment
	!	 	also it calls subroutine REGION to get hydraulic parameters.
	!
    !
    !  	Usage:
    !
    !    CALL PARCEL
    !
    !    where
    !
    !    * no arguments are passed in this subroutine
    !
    !    uses modules and functions
    !
    !    * module     VARS_MAIN   in      VARS_MAIN.f90
    !    * module     VARS_INERC  in      VARS_INERC.f90  
	!    * subroutine INTECLIM    in      INTECLIM.f90 
	!    * subroutine REGION      in      REGION.f90 
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
    
	SUBROUTINE PARCEL

	USE VARS_MAIN
	USE VARS_INERC
	IMPLICIT NONE
	INTEGER IW
	INTEGER AUXRG

	! Calculates Time of Concentration (i.e. time of travel) for Catchment
	DO IW=1,NC
		!XLADO=ACEL(IW)**0.5 	! catchment length estimative (old)
		XLADO=LCEL(IW) 			! main river length in catchment (in km) !RP
		!DH=HCEL(IW)-LCEL(IW)
		DH=HCEL(IW)*LCEL(IW) 	! altitude variation in main river (in meters) !RP

		TIND(IW)=3600.*((0.868*XLADO**3.0)/DH)**0.385	!Concentration Time by Kirpich eq. (ni seconds)
	ENDDO
           
	!--------------------------------------------------------------------------------------- !PR 15SET14
	! Code for river width and depth based on Geomorphological relations assigned in REGION subroutine	
	if(1==0)then
	    ! Calculates width, depth and reference discharge for MC-Method
	    DO IC=1,NC
	    	ARX=ACUR(IC)  	! Cumulative Drainage Area
	    	CALL REGION		! Subroutine calculates river width and full bank depth
	    	BRIO(IC)=BRX	 ! store river width
	    	HRIO(IC)=HRX !	 ! store full bank depth
	    	QREF(IC)=QRX 	 ! store reference discharge for Muskingum-Cunge calcs.
	    END DO	
	endif
	
	RETURN
	END
