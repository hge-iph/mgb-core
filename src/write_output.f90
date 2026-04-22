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
    !    2026.03.10 - 10 March 2026 (By: Vinicius Siqueira)    
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
    !    This sub-routine write the selected variables on disk.
    !
    !
    !---------------------------------------------------------------------------------
    ! Variables and Parameters:
    ! *Variables declarations and routines calls are all commented below.
    !---------------------------------------------------------------------------------
    ! End of header
    !---------------------------------------------------------------------------------
    
    SUBROUTINE WRITE_OUTPUT
    
    USE VARS_MAIN
    
	IMPLICIT NONE
    
    !Writing outputs for selected variables in configuration file 
    if (flag_OUT_FLOW==1)       WRITE(FIL_FLOW,REC=IT)(QTUDO(IC),IC=1,NC)    
    if (flag_OUT_WSE==1)        WRITE(FIL_WSE,REC=IT)(YTUDO(IC),IC=1,NC)    
    if (flag_OUT_RUNOFF==1)     WRITE(FIL_RUNOFF,REC=IT)(QCELTUDO(IC),IC=1,NC)     
    if (flag_OUT_SM==1)         WRITE(FIL_SOILWATER,REC=IT)(SOILWATER(IC),IC=1,NC)
    if (flag_OUT_SSATD==1)      WRITE(FIL_SSATD,REC=IT)(WSATDEGREE(IC),IC=1,NC)
    if (flag_OUT_TWS==1)        WRITE(FIL_TWS,REC=IT)(TWSTUDO(IC),IC=1,NC)           
	if (flag_OUT_HAND==1)       WRITE(FIL_HAND,REC=IT)(HANDTUDO(IC),IC=1,NC)
	if (flag_OUT_ET==1)         WRITE(FIL_ET,REC=IT)(EVAPTUDO(IC),IC=1,NC) 
	if (flag_OUT_ETINT==1)      WRITE(FIL_ETINT,REC=IT)(ETINTERC(IC),IC=1,NC)
	if (flag_OUT_ETSOILVEG==1)  WRITE(FIL_ETSOILVEG,REC=IT)(ETSOILPLANT(IC),IC=1,NC)
	if (flag_OUT_ETOPENWAT==1)  WRITE(FIL_ETOPENW,REC=IT)(ETOPENWAT(IC),IC=1,NC)
	if (flag_OUT_ETURHWAT==1)   WRITE(FIL_ETURHWAT,REC=IT)(EVAPURHAGUA(IC),IC=1,NC)
	if (flag_OUT_SURFWAT==1)    WRITE(FIL_SURFWAT,REC=IT)(SURFWAT(IC),IC=1,NC)
	if (flag_OUT_VBAS==1)       WRITE(FIL_VBAS,REC=IT)(VBASMMDIA(IC),IC=1,NC)
	if (flag_OUT_VINT==1)       WRITE(FIL_VINT,REC=IT)(VINTMMDIA(IC),IC=1,NC)
	if (flag_OUT_VSUP==1)       WRITE(FIL_VSUP,REC=IT)(VSUPMMDIA(IC),IC=1,NC)
	if (flag_OUT_VINTERC==1)    WRITE(FIL_VINTERC,REC=IT)(VINTERC(IC),IC=1,NC)
   	if (flag_OUT_DBAS==1)       WRITE(FIL_DBAS,REC=IT)(DBASMMDIA(IC),IC=1,NC)
	if (flag_OUT_DINT==1)       WRITE(FIL_DINT,REC=IT)(DINTMMDIA(IC),IC=1,NC)
	if (flag_OUT_DSUP==1)       WRITE(FIL_DSUP,REC=IT)(DSUPMMDIA(IC),IC=1,NC)
	if (flag_OUT_FLAREA==1)     WRITE(FIL_FLOOD,REC=IT)(ALAGTUDO(IC),IC=1,NC)
         
    END SUBROUTINE

   !---------------------------------------------------------------------------------
    !  Discussion:
    ! 
    !    This sub-routine opens/closes the output files on disk.
    !
    !
    !---------------------------------------------------------------------------------
    ! Variables and Parameters:
    ! *Variables declarations and routines calls are all commented below.
    !
    !---------------------------------------------------------------------------------
    ! End of header
    !---------------------------------------------------------------------------------
    SUBROUTINE OUTPUT_FILES(file_opt)
    
    USE VARS_MAIN
    implicit none
    integer, intent(in) :: file_opt ! Flag to 
    
    !Outputs
    !Opening files before MODELO subroutine #Vinicius Siqueira
    if (file_opt == 1) then
        if (flag_OUT_FLOW==1)       OPEN(FIL_FLOW,FILE=OUTPUT_DIRECTORY // 'qtudo.mgb', & 
                                        STATUS='REPLACE',RECL=NC,FORM='UNFORMATTED',ACCESS='DIRECT')
                     
        if (flag_OUT_WSE==1)        OPEN(FIL_WSE,FILE=OUTPUT_DIRECTORY // 'ytudo.mgb', &
                                        STATUS='REPLACE',RECL=NC,FORM='UNFORMATTED',ACCESS='DIRECT') 
 
        if (flag_OUT_RUNOFF==1)     OPEN(FIL_RUNOFF,FILE=OUTPUT_DIRECTORY // 'qceltudo.mgb', &
                                        STATUS='REPLACE',RECL=NC,FORM='UNFORMATTED',ACCESS='DIRECT')  
        
        if (flag_OUT_SM==1)         OPEN(FIL_SOILWATER,FILE=OUTPUT_DIRECTORY // 'soilwater.mgb', &
                                        STATUS='REPLACE',RECL=NC,FORM='UNFORMATTED',ACCESS='DIRECT')
        
        if (flag_OUT_SSATD==1)      OPEN(FIL_SSATD,FILE=OUTPUT_DIRECTORY // 'wsatdegree.mgb', &
                                        STATUS='REPLACE',RECL=NC,FORM='UNFORMATTED',ACCESS='DIRECT')
        
        if (flag_OUT_TWS==1)        OPEN(FIL_TWS,FILE=OUTPUT_DIRECTORY // 'twstudo.mgb', &
                                        STATUS='REPLACE',RECL=NC,FORM='UNFORMATTED',ACCESS='DIRECT')

        if (flag_OUT_HAND==1)       OPEN(FIL_HAND,FILE=OUTPUT_DIRECTORY // 'handtudo.mgb', &
                                        STATUS='REPLACE',RECL=NC,FORM='UNFORMATTED',ACCESS='DIRECT') 
              
        if (flag_OUT_ET==1)         OPEN(FIL_ET,FILE=OUTPUT_DIRECTORY // 'evaptudo.mgb', &
                                        STATUS='REPLACE',RECL=NC,FORM='UNFORMATTED',ACCESS='DIRECT')        
       
        if (flag_OUT_ETINT==1)      OPEN(FIL_ETINT,FILE=OUTPUT_DIRECTORY // 'evapinterc.mgb', &
                                        STATUS='REPLACE',RECL=NC,FORM='UNFORMATTED',ACCESS='DIRECT')     
        
        if (flag_OUT_ETSOILVEG==1)  OPEN(FIL_ETSOILVEG,FILE=OUTPUT_DIRECTORY // 'evapsoilplant.mgb', &
                                        STATUS='REPLACE',RECL=NC,FORM='UNFORMATTED',ACCESS='DIRECT') 
        
        if (flag_OUT_ETOPENWAT==1)  OPEN(FIL_ETOPENW,FILE=OUTPUT_DIRECTORY // 'evapopenwater.mgb', &
                                        STATUS='REPLACE',RECL=NC,FORM='UNFORMATTED',ACCESS='DIRECT')  
          
        if (flag_OUT_ETURHWAT==1)   OPEN(FIL_ETURHWAT,FILE=OUTPUT_DIRECTORY // 'evapurhagua.mgb',&
                                        STATUS='REPLACE', RECL=NC,FORM='UNFORMATTED',ACCESS='DIRECT')   
        
        if (flag_OUT_SURFWAT==1)    OPEN(FIL_SURFWAT,FILE=OUTPUT_DIRECTORY // 'surfwater.mgb', &
                                        STATUS='REPLACE',RECL=NC,FORM='UNFORMATTED',ACCESS='DIRECT')    
          
        if (flag_OUT_VBAS==1)       OPEN(FIL_VBAS,FILE=OUTPUT_DIRECTORY // 'vbas.mgb', &
                                        STATUS='REPLACE',RECL=NC,FORM='UNFORMATTED',ACCESS='DIRECT')      
           
        if (flag_OUT_VINT==1)       OPEN(FIL_VINT,FILE=OUTPUT_DIRECTORY // 'vint.mgb', &
                                        STATUS='REPLACE',RECL=NC,FORM='UNFORMATTED',ACCESS='DIRECT')
     
        if (flag_OUT_VSUP==1)       OPEN(FIL_VSUP,FILE=OUTPUT_DIRECTORY // 'vsup.mgb', &
                                        STATUS='REPLACE',RECL=NC,FORM='UNFORMATTED',ACCESS='DIRECT')
        
        if (flag_OUT_VINTERC==1)    OPEN(FIL_VINTERC,FILE=OUTPUT_DIRECTORY // 'vinterc.mgb', &
                                        STATUS='REPLACE',RECL=NC,FORM='UNFORMATTED',ACCESS='DIRECT') 
         
        if (flag_OUT_DBAS==1)       OPEN(FIL_DBAS,FILE=OUTPUT_DIRECTORY // 'dbas.mgb', &
                                        STATUS='REPLACE',RECL=NC,FORM='UNFORMATTED',ACCESS='DIRECT') 
        
        if (flag_OUT_DINT==1)       OPEN(FIL_DINT,FILE=OUTPUT_DIRECTORY // 'dint.mgb', &
                                        STATUS='REPLACE',RECL=NC,FORM='UNFORMATTED',ACCESS='DIRECT') 
        
        if (flag_OUT_DSUP==1)       OPEN(FIL_DSUP,FILE=OUTPUT_DIRECTORY // 'dsup.mgb', &
                                        STATUS='REPLACE',RECL=NC,FORM='UNFORMATTED',ACCESS='DIRECT') 
          
        if (flag_OUT_FLAREA==1)     OPEN(FIL_FLOOD,FILE=OUTPUT_DIRECTORY // 'floodtudo.mgb', &
                                        STATUS='REPLACE',RECL=NC,FORM='UNFORMATTED',ACCESS='DIRECT') 
       
    else 
        ! output files are being closed
        close(FIL_FLOW)        
        close(FIL_WSE)
        close(FIL_RUNOFF)
        close(FIL_SOILWATER)
        close(FIL_SSATD)
        close(FIL_TWS)
        close(FIL_HAND)
        close(FIL_ET)
        close(FIL_ETINT)
        close(FIL_ETSOILVEG)
        close(FIL_ETOPENW)
        close(FIL_ETURHWAT)
        close(FIL_SURFWAT)
        close(FIL_VBAS)
        close(FIL_VINT)
        close(FIL_VSUP)
        close(FIL_VINTERC)
        close(FIL_DBAS)
        close(FIL_DINT)
        close(FIL_DSUP)        
        close(FIL_FLOOD)
            
    end if
    
    END SUBROUTINE
