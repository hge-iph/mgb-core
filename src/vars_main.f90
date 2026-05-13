
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
    ! 2015.06.21 - 21 June 2015
    ! By: Fernando Mainardi Fan
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
    ! Variables and Parameters:
    ! *Variables declarations and routines calls are all commented below.
    !---------------------------------------------------------------------------------
    ! Discussion:
    !
    ! This module contains the variables of MGB-IPH model used in the hydrodynamic routing
    !
    ! Usage:
    !
    ! USE VARS_INERC
    !
    ! uses modules, functions, and subroutines
    !
    ! * no modules, functions, or subroutines are used in this module
    !
    ! opens
    !
    ! * no files are opened in this routine
    !
    ! reads
    !
    ! * no files are read in this routine
    !
    ! creates
    !
    ! * no files are created in this routine
    !
    !---------------------------------------------------------------------------------    
    ! End of header
    !---------------------------------------------------------------------------------
	
    MODULE VARS_MAIN	
	!Variables declaration

	IMPLICIT NONE
	SAVE
	
	CHARACTER(8) INPUT_DIRECTORY !('.\INPUT\')
	CHARACTER(9) OUTPUT_DIRECTORY !('.\OUTPUT\')
    CHARACTER(11) INPUT_DIRECTORY_HOTSTART !('./hotstart/')
	
	!Minibasins and muskingum-cunge routing
	INTEGER,PARAMETER:: NUP=12 !MAXIMUM NUMBER OF HRUs
	INTEGER,PARAMETER:: NBP=505 !@ (DCB 2013_01_25 NBP=300) !MAXIMUM NUMBER OF SUB-BASINS
	INTEGER,PARAMETER:: NUMUSK=150 !Maximum number of stretchs for MUSKINGUM CUNGE routing
	
	!Numbers
	INTEGER NC,NU !minibasins, uses
	INTEGER NT !time intervals
	INTEGER NCLI !number of climatological stations
    INTEGER NREG !number of climate regions
	INTEGER NB !number of sub-basins

	INTEGER NUMSUBST,ISUBST(NBP) !Number of minibasins where streamflow calculated will be replaced by the information read from a file
	INTEGER :: nSIN  ! MUDEI ! numero de reservatorios, SIN=162 + 3 postos subs da Amazonia

	!Counters
	INTEGER IT !Time Interval

	!Variables with numbers of files
	!input Files
	INTEGER,PARAMETER:: FILFIX=1 !File of fixed parameters
	INTEGER,PARAMETER:: FILVAR=2 !File of calibrated parameters
	INTEGER,PARAMETER:: FILUSO=3 !File of parameters associated with the HRU's
	INTEGER,PARAMETER:: FILHIG=4 !File of minibasins informations	
    INTEGER,PARAMETER:: FILCLIREG=9 !File of climate regions
	INTEGER,PARAMETER:: FILSUBS=10 !Hydrographs of file read to substitute the calculated ones
    
    INTEGER,PARAMETER:: FILSTAGE=14 !Binary file of stage needed to fill ZTAB
    INTEGER,PARAMETER:: FILAREA=15  !Binary file of flooded area needed to fill ZTAB
    INTEGER,PARAMETER:: FILCLIMATEbin=16  !Binary file of climatological variables
    INTEGER,PARAMETER:: FILHOTSTART_WB=17 !Binary file of state variables
    INTEGER,PARAMETER:: FILHOTSTART_Inert=18 !Binary file of state variables
	    
	!output Files
    INTEGER,PARAMETER:: FILLOG=26 !File run log

    integer,PARAMETER:: FILCOTAREA=41 !File of reservoir data for simulation
    integer,PARAMETER:: FILFACE=42 !File of face connections for inertial pseudo 2D routing
    INTEGER,PARAMETER:: FILHOTLIST=46 !File of hotstart list
    
    ! Met forcing
    INTEGER,PARAMETER:: FILPLU=50 !File of rainfall data
    INTEGER,PARAMETER:: FILTEMP=51 !File of temperature data
    INTEGER,PARAMETER:: FILRAD=52 !File of radiation data
    INTEGER,PARAMETER:: FILRELH=53 !File of relative humidity data
    INTEGER,PARAMETER:: FILWIND=54 !File of wind velocity data
    INTEGER,PARAMETER:: FILPRES=55 !File of pressure data
    
    !output binaries
    INTEGER,PARAMETER:: FIL_FLOW=1973      !File containing RIVER DISCHARGE
    INTEGER,PARAMETER:: FIL_ET=1974		   !File containing EVAPOTRANSPIRATION
    INTEGER,PARAMETER:: FIL_WSE=1975	   !File containing WATER SURFACE ELEVATION
    INTEGER,PARAMETER:: FIL_HAND=1976	   !File containing HAND VALUES
    INTEGER,PARAMETER:: FIL_TWS=1977	   !File containing TERRESTRIAL WATER STORAGE
    INTEGER,PARAMETER:: FIL_FLOOD=1978	   !File containing FLOODED AREA
    INTEGER,PARAMETER:: FIL_SSATD=1979     !File containing SOIL SATURATION DEGREE
    INTEGER,PARAMETER:: FIL_ETINT=1980	   !File containing ET of INTERC. WATER
    INTEGER,PARAMETER:: FIL_ETSOILVEG=1981 !File containing ET from SOIL+VEGETATION
    INTEGER,PARAMETER:: FIL_ETOPENW=1982   !File containing ET from OPEN WATERS
    INTEGER,PARAMETER:: FIL_SOILWATER=1983 !File containing SOIL WATER CONTENT
    INTEGER,PARAMETER:: FIL_VBAS=1984      !File containing GROUNDWATER RESERVOIR VOLUME
    INTEGER,PARAMETER:: FIL_VINT=1985      !File containing SUBSURFACE RESERVOIR VOLUME
    INTEGER,PARAMETER:: FIL_VSUP=1986      !File containing SURFACE RESERVOIR VOLUME
    INTEGER,PARAMETER:: FIL_VINTERC=1987   !File containing INTERCEPTED WATER RESERVOIR 
    INTEGER,PARAMETER:: FIL_DBAS=1988      !File containing GROUNDWATER FLUX from SOIL
    INTEGER,PARAMETER:: FIL_DINT=1989      !File containing SUBSURFACE FLUX from SOIL
    INTEGER,PARAMETER:: FIL_DSUP=1990      !File containing SURFACE FLUX from SOIL
    INTEGER,PARAMETER:: FIL_SURFWAT=1991   !File containing SURFACE WATER STORAGE
    INTEGER,PARAMETER:: FIL_RUNOFF=1992    !File containing RUNOFF
    INTEGER,PARAMETER:: FIL_ETURHWAT=1993  !File containing ET FROM URH WATER
    
    !Flags for input met forcing (monthly averages / time series)
    integer flag_IN_TEMP, flag_IN_RAD, flag_IN_RH, flag_IN_WIND, flag_IN_PRES
    
    !Flags for output variables
    INTEGER flag_OUT_FLOW, flag_OUT_SM, flag_OUT_WSE, flag_OUT_HAND, flag_OUT_TWS, flag_OUT_RUNOFF, flag_OUT_SURFWAT
    INTEGER flag_OUT_SSATD, flag_OUT_ET, flag_OUT_ETINT, flag_OUT_ETSOILVEG, flag_OUT_ETOPENWAT, flag_OUT_ETURHWAT
    INTEGER flag_OUT_VBAS, flag_OUT_VINT, flag_OUT_VSUP, flag_OUT_VINTERC, flag_OUT_FLAREA
    INTEGER flag_OUT_DBAS, flag_OUT_DINT, flag_OUT_DSUP
    
	!Variables with dimensions used
    REAL(4),ALLOCATABLE:: QTUDO(:),YTUDO(:) !Minibasins streamflow at all locations in all time steps #Results are written for each timestep    
	REAL(4),ALLOCATABLE:: TWSTUDO(:),ALAGTUDO(:),HANDTUDO(:)                 !! Sly + Vinicius
    
	REAL,ALLOCATABLE:: QLIDO(:,:) !Streamflow at some point to replace the calculated values
	INTEGER,ALLOCATABLE:: KCB(:)!Nnumber of cells in each sub-basin
	
	INTEGER iday,imonth,iyear,ihour,iminute !Date and day of the Julian 
    integer doy !Day of the year
    real(8) jday !Julian date (real)
    
    REAL,ALLOCATABLE:: QESP(:)!Especific baseflow (M3/S/KM2)
	
	!Albedo, Leaf Area Index, average height, and surface resistance
	REAL,ALLOCATABLE:: ALB(:,:,:),RIAF(:,:,:),Z(:,:,:),RS(:,:,:)
	
	!Number of stretchs and time intervals used in the calculation  of muskingum-cunge
	INTEGER,ALLOCATABLE:: NSUBT(:)
	REAL,ALLOCATABLE:: DT(:)
	REAL,ALLOCATABLE:: CEL(:),TIND(:)!River celerity and concentration time of the minibasin
		
	!Parameters related to the soil
	REAL,ALLOCATABLE:: WM(:,:),B(:,:),KINS(:,:),KBAS(:,:)

	REAL,ALLOCATABLE:: PLAM(:,:),CAP(:,:),WC(:,:),KINF(:,:)
	REAL,ALLOCATABLE:: CI(:),CB(:),CS(:)!Propagation parameters of the minibasin

	CHARACTER (10) AUSO(NUP)!Names of the HRUs
	
	!Parameters related to minibasins
	INTEGER,ALLOCATABLE:: IEXUT(:)!Indicates the outlet minibasins
	REAL,ALLOCATABLE:: BRIO(:)!River width
	REAL BRX !River width (auxiliary variable)
	INTEGER,ALLOCATABLE:: IBAC(:),CELJUS(:)!Watershed, downstream minibasin
	REAL,ALLOCATABLE::  HCEL(:),LCEL(:) ! Declividade e comprimento do rio mais longo
	REAL,ALLOCATABLE:: X(:),Y(:)!Coordinates of the minibasin center
    INTEGER, ALLOCATABLE:: REGCLI(:) !Climate region of catchment
	!Area of the minibasin, drainage area in number of minibasins, river length and slope of the river
	REAL,ALLOCATABLE:: ACEL(:),ACUR(:),SRIO(:),DECL(:)
	!Proportion of HRUs in the minibasins
	REAL,ALLOCATABLE:: PUSO(:,:)
	REAL,ALLOCATABLE:: QREF(:) !Reference streamflow
	REAL QRX !Reference streamflow (auxiliary variable)


	! temp., humidity, wind, insolation, pressure, monthly values
	REAL(4),ALLOCATABLE:: TAMM(:,:),URMM(:,:),VVMM(:,:),PAMM(:,:)
	REAL(4),ALLOCATABLE:: SOLMM(:,:)
	REAL,ALLOCATABLE:: XYC(:,:)!x and y coordinates of climatological stations

	!Counters
	INTEGER IC
	
	!CHeaders without relevance
	CHARACTER (10) CABE(NBP)

	!More variables
	REAL,ALLOCATABLE:: SI(:,:) !Amount of water intercepted in the surface
	REAL XLADO,DH,ARX !Length of the minibasin side, difference in altitude, area (auxiliary variable)
	REAL,ALLOCATABLE:: QM1(:),QJ1(:),QM2(:),QJ2(:) !Streamflows upstream and downstream in the cell i at times 1 and 2
	REAL,ALLOCATABLE:: QCEL1(:),QCEL2(:) !Streamflows originated in the cell at time t and t + 1 in cell i
	REAL,ALLOCATABLE:: PMB2(:),PMI2(:),PMS2(:),PJB2(:),PJI2(:),PJS2(:) !Proportions of origin of the flows in   the river
	REAL,ALLOCATABLE:: VRB(:),VRI(:),VRS(:) !Volumes of proportions in the stretch
	REAL,ALLOCATABLE:: ET(:,:) 	!Total evapotraspiration
	REAL,ALLOCATABLE:: CAF(:,:)		!Capillary flow upward
	REAL,ALLOCATABLE:: W(:,:) 	!mount of of water over the soil
	REAL,ALLOCATABLE:: QBAS(:),QINT(:),QSUP(:)		!Flows in the minibasins
	REAL,ALLOCATABLE:: VBAS(:),VINT(:),VSUP(:)		!Volumes in the minibasins
	REAL,ALLOCATABLE:: TONTEM(:)		!Temperature the day before
	
	REAL(4),ALLOCATABLE:: P(:) !Rainfall at the interval in the cell         !! Sly + Viniciu    
	REAL(4),ALLOCATABLE:: TA(:),UR(:),VV(:),SOL(:),PA(:)	!Temperature, humidity, wind, insolation, pressure    
    
	REAL DTP !Time interval of main calculation (in seconds given in the input file)
	!Variables related to radiation
	REAL GLAT !Latitude in decimal degrees (- south)
	REAL SOLX,T1 !Insolation (hours of sun) and temperature (°c)
	REAL ALBX !ALBEDO
	REAL RLX !Resulting net radiation  (MJ/m2/dia)
	REAL RDIA !Julian day (real)
	REAL URX
	REAL,PARAMETER:: MESP=1000.0 !Water specific mass (KG/M3)
	REAL,PARAMETER:: PI=3.141592 !pi
	REAL,PARAMETER:: STEBOL=4.903E-9 !CONST. STEFAN BOLTZMANN
	!Internal variables of the subroutine
	REAL CLATE !latent heat of vaporization
	REAL SDECL,SANG !solar declination, angle of birth
	REAL HIM !maximum duration of sunshine (hours)
	REAL DR ! Relative distance Earth - Sun
	REAL GS,STO !Heat flux to the soil, Rariadion in the top of the atmosphere
	REAL SSUP,SN !Heat flux
	REAL ED,ES !Vapor pressures (real, Saturation)
	REAL SLONG !Longwave radiation

    INTEGER CLI_INDEX !Indicates whether the climatological averages (radiation) come from CRU, INMET, or WorldClim data format    
    INTEGER flag_RES_SUB !Flag for reservoir Simulation
    INTEGER flag_opt_rout !Flag for inertial model
    INTEGER flag_pseudo_two_d !Flag for pseudo 2D model (ipucas)
    
	!Variables from Subroutine CELULA
	!Auxiliaries
	REAL WX,WMX,PAX,TAX,VVX,BX,KIX,KBX,RIAFX,ZX,EX,PX,SIX,VVX2,KINFX
	REAL XL,T2,RSX,CAPX,ETX,WCX,VBX,VIX,VSX,PPU,WXB,DCAP

	!Variables from Subroutine EVAPO
	REAL D !Vapor pressure deficit
	REAL DEL !Derivative of the function ES x T
	REAL GAMA !Psychrometric constant
	REAL MSPA !Density of air
	REAL RUG !Roughness
	REAL SF !IDEM
	REAL SIL !Maxima intercepted amount of water
	REAL EIX !Amount of water evaporated from interception (POTENTIAL)
	REAL EIXP !Amount of water evaporated from the water surface  (POTENTIAL)
	REAL,ALLOCATABLE:: EVQ(:) !Direct evaporation from liquid surfaces (Water URH) from the minibasin in M3/S
	REAL REIX !Amount of water evaporated from interception  (REAL)
	REAL FDE !Fraction of available evaporative demand
	REAL,PARAMETER:: CSPA=0.001013 	!Heat especific from the humid air  MJ/kg/C
	REAL RA !Aerodynamic resistance
	REAL RAEP !Aerodynamic resistance to potential evapotranspiration
	REAL WL !Limit soil moisture above which no soil moisture restricts evapotranspiration (Shuttleworth)
	REAL WPM !Wilting point  (SHUTTLEWORTH)
	REAL F4 !Correction factor for surface resistence as a function of soil moisture deficit

	INTEGER IB,IU !Counter of Sub-basins and HRUs
	
	REAL,ALLOCATABLE:: QCONTORM(:,:),QCONTORJ(:,:) !Flow of boundary condition of MUSKINGUM CUNGE
	REAL,ALLOCATABLE:: QRIOINI(:,:) !Initial condition for MUSKINGUM CUNGE in the river stretch

	integer,allocatable:: OD(:) !RP

	integer,allocatable::	sbtFLAG(:)	! RP

	! Variables to calculate indicators of maximum evapotranspiration:
	real,allocatable:: E0agua(:),E0TOPO(:),E0SUP(:)	
  
	    
    REAL(4),ALLOCATABLE:: QITUDO(:) !Incremental discharges only everywhere #Vinicius Siqueira
    REAL(4),ALLOCATABLE:: EVAPTUDO(:) !Evapotranspiration only everywhere #Vinicius Siqueira
    REAL(4),ALLOCATABLE:: QBASTUDO(:) !catchment baseflow only everywhere #Vinicius Siqueira
	REAL(4),ALLOCATABLE:: WSATDEGREE(:) !soil moisture volume only everywhere #Vinicius Siqueira    
    REAL(4),ALLOCATABLE:: ETINTERC(:),ETSOILPLANT(:),ETOPENWAT(:),EVAPURHAGUA(:) !CEAA
    REAL(4),ALLOCATABLE:: SOILWATER(:),CAPWATER(:),VINTERC(:) !CEAA
    REAL(4),ALLOCATABLE:: VSUPMMDIA(:),VINTMMDIA(:),VBASMMDIA(:) !CEAA
    REAL(4),ALLOCATABLE:: DSUPMMDIA(:),DINTMMDIA(:),DBASMMDIA(:) !CEAA
    REAL(4),ALLOCATABLE:: SURFWAT(:) !CEAA
    REAL(4),ALLOCATABLE:: QCELTUDO(:) !CEAA
    REAL,ALLOCATABLE:: TWS2(:)
    real,allocatable::  vflow(:) !For computing flow velocities
    integer, allocatable :: WriteHotFile(:)
    
	!CONTROL VARIABLES
	INTEGER SUBini,SUBfim !Control especial cases of run
    integer, dimension(:), allocatable :: Ind_Reserv ! Indice para minibacias do barramento ! SIN_RESERV
	integer, dimension(:), allocatable :: CELJUS2 ! Indice para minibacias do barramento ! SIN_RESERV
    integer, dimension(:), allocatable :: iTini_Reserv ! Indice para comecar a simular defluencias! SIN_RESERV
	
	!MANNING !FMF 09/09/2015 
	REAL,ALLOCATABLE:: RUGMAN(:) !Manning coefficient
    
    REAL ACELX
    
    REAL WMMINI
         
    !****************************************************************************************************
    !VINICIUS SIQUEIRA IN 07-11-2016 (English Date format)
    !MGB-IPH for SOUTH AMERICA modifications
    !Arrays declarations inside subroutines have been taken to this module
    !****************************************************************************************************
    
    !****SUBROUTINE CELULA vars****
    REAL, ALLOCATABLE :: TKB(:),TKI(:),TKS(:)            ! Delay and concentration times	
    
    !****SUBROUTINE REDE vars****
    REAL, ALLOCATABLE :: PMB1(:),PMI1(:),PMS1(:)           !PROPORÇÕES DE ORIGEM
	REAL, ALLOCATABLE :: PJB1(:),PJI1(:),PJS1(:)
    
	END MODULE
