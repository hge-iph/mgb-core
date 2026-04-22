
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
    !    2014.09.001 - 09 September 2014
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
    ! Variables and Parameters:
    ! *Variables declarations and routines calls are all commented below.
    !---------------------------------------------------------------------------------
    !  Discussion:
    ! 
    !    This subroutine uses the computer clock to generate the seed (random process)
    !
    ! Usage:
    !
    !   * no modules, functions, or subroutines are used in this funcation
    !
    !    uses modules and functions
    !
    !    * module PORTLIB
    !
    ! opens
    !
    !   * no files are opened in this routine
    !
    ! reads
    !
    !   * no files are read in this routine
    !
    ! creates
    !
    !   * no files are created in this routine
    !---------------------------------------------------------------------------------
    ! End of header
    !---------------------------------------------------------------------------------
    
	SUBROUTINE SEMENTE(ISEED)

    ! Variables and parameters
    IMPLICIT NONE
    INTEGER ISEED
    INTEGER ITIME1
    CALL SYSTEM_CLOCK(COUNT=ITIME1)
    ISEED=ITIME1
    RETURN
    END
