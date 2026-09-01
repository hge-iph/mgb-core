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
    !    2026.03.23 - 23 March 2026 (By: Vinicius Siqueira)    
    !
    !  Authors:
    !
    !    Original fortran version by Walter Collischonn
    !    Present fortran version by:
    !    * Walter Collischonn
    !    * Rodrigo Cauduro Dias de Paiva
    !    * Diogo da Costa Buarque
    !    * Paulo Pontes Rógenes
    !    * Mino Viana Sorribas
    !    * Fernando Mainardi Fan
    !    * Juan Martin Bravo 
    !    * Vinicius Alencar Siqueira
	!	 * Ayan Santos Fleischmann
	!	 * Sly Wongchuig Correa
    !	 * João Paulo Lyra Fialho Breda
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
    !    This sub-routine reads the forecast information file.
    !
	!
    !---------------------------------------------------------------------------------
    !  Variables and Parameters:
    !
    !   *Variables declarations and routines calls are all commented below.
	!	* All variables are global!?
    !
    !---------------------------------------------------------------------------------		
     
    SUBROUTINE READ_INFOMGB
	    
    USE VARS_MAIN
    USE VARS_INERC
    use utils_time, only: julday_rl, caldat_rl, time_diff
    use utils_date, only: date_parser
    
	IMPLICIT NONE
  
    !*************************************************************************************************
    !Variables for mgb_config_global    
      
   ! INTEGER JULDAY
    INTEGER N_UNIT_CATCHM, N_HRUS 
    INTEGER N_SUBASINS, N_CLI_REGIONS
    INTEGER HOTSTART_READ, HOTSTART_WRITE, SUBASIN_START, SUBASIN_END  
    REAL(4) SIM_TIMESTEP
    INTEGER OPT_RES_SUB, N_RES_SUB
    character(len=40) :: SIM_START_DATE, SIM_END_DATE
    
    integer i_yr_end, i_mo_end, i_day_end, i_hr_end, i_min_end
    real(8) jday_end
    
    !Variables for mgb_forcing
    INTEGER TS_TEMP, TS_RAD, TS_RH, TS_WIND, TS_PRES
    INTEGER OPT_MONTH_RAD
    
    !Variables for mgb_routing 
    INTEGER OPT_ROUTING, N_THREADS  
    REAL IN_COURANT_ALPHA, IN_DOWN_SLOPE
    
    !Variables for writing output files
    INTEGER OUT_FLOW, OUT_SM, OUT_WSE, OUT_HAND, OUT_TWS, OUT_RUNOFF, OUT_SURFWAT
    INTEGER OUT_ET, OUT_ETINT, OUT_ETSOILVEG, OUT_ETOPENWAT, OUT_ETURHWAT, OUT_SSAT
    INTEGER OUT_VBAS, OUT_VINT, OUT_VSUP, OUT_VINTERC, OUT_FLAREA
    INTEGER OUT_DBAS, OUT_DINT, OUT_DSUP
    integer OUT_POTETWAT
    
    !*************************************************************************************************     
   
    !Namelist definition - (MGB GENERAL CONFIG)
    namelist /mgb_config_global/     &
        
        & SIM_START_DATE,     &
        & SIM_END_DATE,       &  
        & SIM_TIMESTEP,       &
        & HOTSTART_READ,      &
        & HOTSTART_WRITE,     &
        & SUBASIN_START,      &
        & SUBASIN_END,        &   
        & N_UNIT_CATCHM,      &
        & N_HRUS,             &
        & N_SUBASINS,         &   
        & N_CLI_REGIONS,      &                   
        & OPT_RES_SUB,        &  
        & N_RES_SUB                   
          
                 
    ! Opens input file contaning simulation setup parameters
	OPEN(FILFIX,FILE=INPUT_DIRECTORY // 'infomgb.sim',STATUS='OLD',ACTION='READ')
    READ(FILFIX, nml = mgb_config_global)
     	
    DTP             = SIM_TIMESTEP
    NC              = N_UNIT_CATCHM
    NCLI            = NC ! Temporary, all NCLI must be changed to NC
    NU              = N_HRUS
    NB              = N_SUBASINS
    NREG            = N_CLI_REGIONS
    flag_RES_SUB    = OPT_RES_SUB
    flag_ReadHot    = HOTSTART_READ
    flag_WriteHot   = HOTSTART_WRITE                            
    nSIN            = N_RES_SUB
    SUBini          = SUBASIN_START
    SUBfim          = SUBASIN_END 
    
     ! Parse start and end simulation dates from strings
    CALL date_parser(SIM_START_DATE,iyear,imonth,iday,ihour,iminute)
    CALL date_parser(SIM_END_DATE,i_yr_end,i_mo_end,i_day_end,i_hr_end,i_min_end)
        
    ! Compute number of time steps using start/end julian day and hour
    jday     = julday_rl(iyear,imonth,iday,ihour,iminute)
    jday_end = julday_rl(i_yr_end, i_mo_end, i_day_end, i_hr_end, i_min_end) 
    NT =       time_diff(jday_end, jday, real(DTP,8)) + 1
        
    !Namelist definition - (MGB met CONFIG)
    namelist /mgb_config_forcing/     &
    
        & TS_TEMP,          &
        & TS_RAD,           & 
        & TS_RH,            & 
        & TS_WIND,          &
        & TS_PRES,          &
        & OPT_MONTH_RAD       
    
    ! Reads input file contaning simulation setup parameters
    READ(FILFIX, nml = mgb_config_forcing)
    
    flag_IN_TEMP    = TS_TEMP
    flag_IN_RAD     = TS_RAD
    flag_IN_RH      = TS_RH
    flag_IN_WIND    = TS_WIND 
    flag_IN_PRES    = TS_PRES
    CLI_INDEX       = OPT_MONTH_RAD
    
    !Namelist definition - (ROUTING)
    namelist /mgb_config_routing/   &
        
        & OPT_ROUTING,           &        
        & IN_DOWN_SLOPE,         &
        & IN_COURANT_ALPHA,      &              
        & N_THREADS
   
    !Manual setup for disabled options (Pseudo2D configuration)
    flag_pseudo_two_d = 0
    bflow_overland    = 10.0
    xMan_overland     = 0.1
    
    ! Reads input file contaning simulation setup parameters
    READ(FILFIX, nml = mgb_config_routing)
    
    !Reads routing parameters
    alpha           = IN_COURANT_ALPHA
    flag_opt_rout   = OPT_ROUTING    
    thread_count    = N_THREADS
    WSslope         = IN_DOWN_SLOPE
    WSslope         = WSslope*0.001 !converting from m/km to m/m
    
    
    !*************************************************************************************************
    !Namelist definition - (output variables)
    namelist /mgb_config_output/     & 
    
        & OUT_FLOW,        &
        & OUT_WSE,         &
        & OUT_HAND,        &
        & OUT_RUNOFF,      &
        & OUT_SM,          &
        & OUT_SSAT,        &
        & OUT_TWS,         &
        & OUT_SURFWAT,     &
        & OUT_ET,          &
        & OUT_ETINT,       &
        & OUT_ETSOILVEG,   &
        & OUT_ETOPENWAT,   &
        & OUT_ETURHWAT,    &
        & OUT_POTETWAT,    &
        & OUT_VBAS,        &
        & OUT_VINT,        &
        & OUT_VSUP,        &
        & OUT_DBAS,        &
        & OUT_DINT,        &
        & OUT_DSUP,        &
        & OUT_VINTERC,     &
        & OUT_FLAREA            
    
    ! Reads input file contaning output variables parameters
    READ(FILFIX, nml = mgb_config_output)
    
    flag_OUT_FLOW       = OUT_FLOW
    flag_OUT_WSE        = OUT_WSE 
    flag_OUT_HAND       = OUT_HAND 
    flag_OUT_RUNOFF     = OUT_RUNOFF
    flag_OUT_SM         = OUT_SM
    flag_OUT_SSATD      = OUT_SSAT
    flag_OUT_TWS        = OUT_TWS
    flag_OUT_SURFWAT    = OUT_SURFWAT
    flag_OUT_ET         = OUT_ET 
    flag_OUT_ETINT      = OUT_ETINT
    flag_OUT_ETSOILVEG  = OUT_ETSOILVEG
    flag_OUT_ETOPENWAT  = OUT_ETOPENWAT
    flag_OUT_ETURHWAT   = OUT_ETURHWAT
    flag_OUT_POTETWAT   = OUT_POTETWAT
    flag_OUT_VBAS       = OUT_VBAS
    flag_OUT_VINT       = OUT_VINT
    flag_OUT_VSUP       = OUT_VSUP
    flag_OUT_VINTERC    = OUT_VINTERC
    flag_OUT_DBAS       = OUT_DBAS
    flag_OUT_DINT       = OUT_DINT
    flag_OUT_DSUP       = OUT_DSUP
    flag_OUT_FLAREA     = OUT_FLAREA
     
	CLOSE (FILFIX)

	RETURN
	END
