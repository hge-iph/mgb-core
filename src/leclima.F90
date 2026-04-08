   
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
    !    2019.02.07 - 02 July 2019 (By: Vinicius Siqueira)    
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
    
    SUBROUTINE LECLIMA
	!esta subrotina prepara os dados climatologicos
	USE VARS_MAIN
	IMPLICIT NONE
	INTEGER KLI,MM,IYYY,ID

	!	VERIFICA EM QUE MES ESTAMOS
	CALL caldat(JDIA,MM,id,iyyy)

	DO IC=1,NC
		KLI=ICBOM(IC)
        IF(flagaclimed==1) THEN
            TA(IC)=TAMM(KLI,MM)
            UR(IC)=URMM(KLI,MM)
            VV(IC)=VVMM(KLI,MM)
            SOL(IC)=SOLMM(KLI,MM)
            PA(IC)=PAMM(KLI,MM)
            cycle
        ENDIF
        
		!TEMPERATURA DO AR
		IF(TD(KLI,IT).LT.-200.0.OR.flagaclimed==1)THEN !TESTA FALHA (FALHA=-300.0)
			TA(IC)=TAMM(KLI,MM)	!USA MEDIA MENSAL DO POSTO
		ELSE
			TA(IC)=TD(KLI,IT) !USA DADO REAL
		ENDIF
		
		!UMIDADE RELATIVA
		IF(UD(KLI,IT).LT.0.0.OR.flagaclimed==1)THEN !TESTA FALHA (FALHA=-1.0)
			UR(IC)=URMM(KLI,MM)	!USA MEDIA MENSAL DO POSTO
		ELSE
			UR(IC)=UD(KLI,IT) !USA DADO REAL
		ENDIF

		!VELOCIDADE DO VENTO
		IF(VD(KLI,IT).LT.0.0.OR.flagaclimed==1)THEN !TESTA FALHA (FALHA=-1.0)
			VV(IC)=VVMM(KLI,MM) ! EM M/S
		ELSE
			VV(IC)=VD(KLI,IT) !USA DADO REAL
		ENDIF	        

		!HORAS DE SOL									
		IF(SOLD(KLI,IT).LT.0.0.OR.flagaclimed==1)THEN
			SOL(IC)=SOLMM(KLI,MM) !EM HORAS/DIA
		ELSE
			SOL(IC)=SOLD(KLI,IT) !USA DADO REAL
		ENDIF

		!PRESSAO ATMOSFERICA 
		IF(PAD(KLI,IT).LT.0.0.OR.flagaclimed==1)THEN
			PA(IC)=PAMM(KLI,MM) 
		ELSE
			PA(IC)=PAD(KLI,IT) !USA DADO REAL
		ENDIF
	ENDDO

734	FORMAT(5F10.2)
	RETURN
	END