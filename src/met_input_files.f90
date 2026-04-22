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
    !    * Mino Viana Sorribas
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
    !---------------------------------------------------------------------------------
    ! Variables and Parameters:
    ! *Variables declarations and routines calls are all commented below.
    !---------------------------------------------------------------------------------
    ! End of header
    !---------------------------------------------------------------------------------
	
	SUBROUTINE MET_INPUT_FILES(file_opt)
    
    
    USE VARS_MAIN
    implicit none
    integer, intent(in) :: file_opt 
    
    !input met files
    !Opening files before MODELO subroutine #Vinicius Siqueira
    if (file_opt == 1) then
       		
		!input binary file with interpolated rainfall data
		OPEN(FILPLU,FILE=INPUT_DIRECTORY // 'chuvabin.pbi', STATUS='old',RECL=NC,FORM='UNFORMATTED',ACCESS='DIRECT')
										 
        if (flag_IN_TEMP==1)   OPEN(FILTEMP,FILE=INPUT_DIRECTORY // 'met_temp.pbi', &
                                    STATUS='old',RECL=NC,FORM='UNFORMATTED',ACCESS='DIRECT')
        
		if (flag_IN_RAD==1)    OPEN(FILRAD,FILE=INPUT_DIRECTORY // 'met_radiation.pbi', &
                                    STATUS='old',RECL=NC,FORM='UNFORMATTED',ACCESS='DIRECT')										
									
		if (flag_IN_RH==1)     OPEN(FILRELH,FILE=INPUT_DIRECTORY // 'met_relh.pbi', &
                                    STATUS='old',RECL=NC,FORM='UNFORMATTED',ACCESS='DIRECT')
        
        if (flag_IN_WIND==1)   OPEN(FILWIND,FILE=INPUT_DIRECTORY // 'met_wind.pbi', &
                                    STATUS='old',RECL=NC,FORM='UNFORMATTED',ACCESS='DIRECT')
        
        if (flag_IN_PRES==1)   OPEN(FILPRES,FILE=INPUT_DIRECTORY // 'met_wind.pbi', &
                                    STATUS='old',RECL=NC,FORM='UNFORMATTED',ACCESS='DIRECT') 

	else
		! Closing met files
		close(FILPLU)
		close(FILTEMP)
		close(FILRAD)
		close(FILRELH)
		close(FILWIND)
		close(FILPRES)
		
    end if
    
    end subroutine
                      