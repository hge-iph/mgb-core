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
    !    2026.03.02 - 02 March 2026 (By: Vinicius Siqueira)    
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
    !    This sub-routine reads the climate data from internal database.
    !
    !
    !---------------------------------------------------------------------------------
    ! Variables and Parameters:
    ! *Variables declarations and routines calls are all commented below.
    !---------------------------------------------------------------------------------
    ! End of header
    !---------------------------------------------------------------------------------
    
    SUBROUTINE READ_MET(mm, it_read)
    
	USE VARS_MAIN
	IMPLICIT NONE
	
    INTEGER, INTENT(IN) :: mm ! Calendar month
    INTEGER, INTENT(IN) :: it_read ! timestep for reading binaries
    INTEGER KC
    
    ! Using vectorized read for monthly data   
    if (flag_IN_TEMP==0) TA(:) = TAMM(:,mm)
    if (flag_IN_RAD==0)  SOL(:) = SOLMM(:,mm)
    if (flag_IN_RH==0)   UR(:) = URMM(:,mm)
    if (flag_IN_WIND==0) VV(:) = VVMM(:,mm)
    if (flag_IN_PRES==0) PA(:) = PAMM(:,mm)                            

    ! Reads precipitation data
    READ(FILPLU,REC=it_read)(P(KC),KC=1,NC) 
    
    ! Reads meteorological data at the same time interval of precipitation
	if (flag_IN_TEMP==1) READ(FILTEMP,REC=it_read)(TA(KC),KC=1,NC)    
    if (flag_IN_RAD==1)  READ(FILRAD,REC=it_read)(UR(KC),KC=1,NC) 
    if (flag_IN_RH==1)   READ(FILRELH,REC=it_read)(SOL(KC),KC=1,NC) 
    if (flag_IN_WIND==1) READ(FILWIND,REC=it_read)(VV(KC),KC=1,NC) 
    if (flag_IN_PRES==1) READ(FILPRES,REC=it_read)(PA(KC),KC=1,NC) 

end SUBROUTINE