
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
    !    ISBN: XXXXXXXXXXX,
    !
    !---------------------------------------------------------------------------------
    ! Variables and Parameters:
    ! *Variables declarations and routines calls are all commented below.
    !---------------------------------------------------------------------------------
    !  Discussion:
    ! 
    !    This sub-routine reads the level x flooded area from PrePro (Inertial version).
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
    ! * cota_area.flp
    !
    ! reads
    !
    ! * cota_area.flp
    !
    ! creates
    !
    ! * no files are created in this routine
    !    
    ! End of header
    !---------------------------------------------------------------------------------
    
    SUBROUTINE LEFLOODPLN

    !  Variables and Parameters:
    USE VARS_MAIN
    USE VARS_INERC
    IMPLICIT NONE
    integer aux, io_status
    
       
      
    !Opening the level x flooded area file
    OPEN(FILCOTAREA,FILE=INPUT_DIRECTORY // 'cota_area.flp',STATUS='OLD',action='READ')
    
    ! Reading data:
    READ(FILCOTAREA,*)
    nPfl=0
    DO
        READ(FILCOTAREA,*,IOSTAT=io_status) IC,ZFUNDOFL(IC),ZFL(NPFL(IC)+1,IC),AFL(NPFL(IC)+1,IC)
        IF (io_status .NE. 0) EXIT
        NPFL(iC)=NPFL(IC)+1
    ENDDO
    CLOSE(FILCOTAREA)
   
    !ABRE ARQUIVO DE FACES
    if (1==0) then
    OPEN(FILFACE,FILE=INPUT_DIRECTORY // 'face.con',STATUS='OLD',action='READ')
    
    !Número da face / Minibacia 1 / Minibacia 2 / Ymin da fronteira (m) / DX entre as minibacias (m):
    aux=0
    DO
        READ(FILFACE,*,IOSTAT=io_status) aux,nFACECAT1(aux),nFACEY1(aux),nFACECAT2(aux),nFACEY2(aux),nFACEDX(aux)
        IF (io_status .NE. 0) EXIT
    ENDDO
    CLOSE(FILFACE)
    nFACE=aux
    endif

   
    RETURN
    END