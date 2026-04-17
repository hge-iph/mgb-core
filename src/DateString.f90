  
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
    !    2022.06.04 - 04 June 2022 (By: Vinicius Siqueira)    
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
    !    This sub-routine creates string dates from integer numbers.
    !
    !
    !---------------------------------------------------------------------------------
    ! Variables and Parameters:
    ! *Variables declarations and routines calls are all commented below.
    !---------------------------------------------------------------------------------
    ! End of header
    !---------------------------------------------------------------------------------
SUBROUTINE DateString(i_julian,i_year,i_month,i_day,strDate)
    
   USE VARS_MAIN

   implicit none
   integer, intent(in)  :: i_day, i_month, i_year, i_julian
   character(8), intent(out) :: strDate
             
   call caldat(i_julian,i_month,i_day,i_year)
      
   !Adjust number formats
   if ((i_day < 10).AND.(i_month < 10)) then                     
        write (strDate,"(I4,A1,I1,A1,I1)")i_year,'0',i_month,'0',i_day
        
   elseif ((i_day < 10).AND.(i_month >= 10)) then        
        write (strDate,"(I4,I2,A1,I1)")i_year,i_month,'0',i_day
        
   elseif ((i_day >= 10).AND.(i_month < 10)) then     
        write (strDate,"(I4,A1,I1,I2)")i_year,'0',i_month,i_day
                
   else     
        write (strDate,"(I4,I2,I2)")i_year,i_month,i_day
        
   endif
    
    END SUBROUTINE
    
    
