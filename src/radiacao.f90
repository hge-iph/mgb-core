
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
	!	* All variables are global!?
    !
    !---------------------------------------------------------------------------------	        
    !  Discussion:
    ! 
    !    This routine calculates net radiation based on energy equations using meterological
	!		data (i.e. air temperature, humidity, atm pressure, insolation, wind speed),
	!		soil/vegetation (i.e. canopy, surface roughness, albedo),
	!		date (e.g. julian day) and location
	!
	!	 RADIACAO is called inside subroutine CELULA.
	!
	!	 Saves global variables used for vertical water balance and evap indicators in CELULA.
	! 		RLX: net radiation (MJ/m2.dia)
	! 		STO: top-of-atmosphere radiation (MJ/m2.dia)
	! 		SSUP: incident radiation at terr. surface (MJ/m2.dia) - only insolation discounts.
	!
	!	* Cloudness correction based on Amazon Basin assumption. talk to Rodrigo.
	!
	!
    !
    !  	Usage:
    !
    !    CALL RADIACAO
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
    
	
	SUBROUTINE RADIACAO
	USE VARS_MAIN
	IMPLICIT NONE
	!REAL GLAT 				! latitude in decimal degrees (negative for south)
	!REAL SOLX,T1,T2 		! insolation (number of hours), and air temperature (celsius)
	!REAL ALBX 				! albedo
	!REAL RLX 				! net radiation (MJ/m2/dia)
	!INTEGER doy 			! julian day - integer
	!REAL RDIA 				! julian day - float
	!REAL URX
	!REAL,PARAMETER:: MESP=1000.0 ! water specific weigth (kg/m3)
	!REAL,PARAMETER:: PI=3.141592 ! pi
	!REAL,PARAMETER:: STEBOL=4.903E-9 ! stefan-boltzmann constant
	
	!internal variables
	!REAL CLATE 			!latent heat (vap.)
	!REAL SDECL,SANG 		!solar declination (angle at sunset)
	!REAL HIM 				!maximum duration of insolation (hours)
	!REAL DR 				! relative distance [earth - sun] 
	!REAL GS,STO 			! ground heat flux and top-of-atmosphere radiation
	!REAL SSUP,SN 			! heat fluxes
	!REAL ED,ES 			! air vapor pressure (real and saturation)
	!REAL SLONG 			! short-wave radiation


	! latent heat of vaporization (MJ/Kg) - ch4. Handbook of Hydrology
	CLATE=(2.501-0.002361*T2) !usa temperatura em C

	! Saturation Vapor pressure
	ES=0.6108*EXP((17.27*T2)/(237.3+T2)) !in KPa  !EVAPO ATUALIZADO
	
	! Real Vapor Pressure
	ED=ES*URX/100.0 		!in KPa
	
	! - ch4. - Handbook of Hydrology
	! Solar Declination (rad)
    RDIA=doy
	SDECL=0.4093*SIN((2*PI/365.0)*RDIA-1.405)
	
	! Sunset hour angle (rad)
	SANG=ACOS(-TAND(GLAT)*TAN(SDECL)) !intrinsic function TAND is for degree arguments
	
	! maximum insolation (hours)
	HIM=24*SANG/PI
	! - ch4. - !
	
	! Distance Earth-Sun
	DR=1.0+0.033*COS(2*PI*RDIA/365.0)
	
	! Top-of-atmosphere Radiation (mm/day)
	STO=15.392*DR*(SANG*SIND(GLAT)*SIN(SDECL)+COSD(GLAT)*COS(SDECL)*SIN(SANG))
	
	! Convert to MJ/m2.day
	STO=STO/1000.0 		! to meters/day
	STO=STO*MESP*CLATE  ! to MJ/m2.day

	!Calculates incoming radiation to terr. surface			
	IF (flag_IN_RAD == 0) then	!Options for monthly radiation data (flag rad = 0)
        
        if (CLI_INDEX==0) then !INMET
            SSUP=STO*(0.25+0.5*SOLX/HIM) 	!from insolation (eq. 4.2.6 from Handbook Hydrology)
            
        elseif (CLI_INDEX==1) then !CRU
            SSUP=STO*(0.25+0.5*(SOLX)/100.)  ! Sunshine data in % for CRU data
        
        elseif (CLI_INDEX==2) then !WorldClim v2.1
            SSUP=SOLX                        ! Sunshine data already in radiation (MJ/m².day) for WorldClim data
        endif
	ELSE    !from incident shortwave on terr surface data		
		SSUP=SOLX	
    ENDIF

    ! Discount reflection (albedo)
	SN=SSUP*(1-ALBX)
	
	! Long-wave losses
	SLONG=STEBOL*(T2+273.2)**4.0 	  ! Temperature is converted to Kelvin
	SLONG=SLONG*(0.34-0.14*(ED)**0.5) ! Emissivity correction
	
	! Cloudness
	! SLONG=SLONG*(0.9*SOLX/HIM+0.1)	
	! SOLX is in terms of solar radiation, then uses Handbook of Hydrology eq.
	! Parameters from wetlands to address Amazon basin
	SLONG=SLONG*(1.0*SSUP/STO+0.0) 	  ! Cloudness correction


	! Ground heat flux !MJ/m2.dia
	GS=0.38*(T2-T1) 				  ! eq. 4.2.18 (Handbook of Hydrology)
	
	! Net Radiation (Energy Available) (MJ/m2.dia) - discount longwave and groun heatflux	
	RLX=SN-SLONG-GS
	

	
	RETURN
	END
