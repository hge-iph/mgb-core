   
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
    ! Version/Modified:
    !
    ! 2015.06.21 - 21 June 2016
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
    ! Discussion:
    !
    ! This routine allocate or deallocate the MGB-IPH memory for the main variables
    !
    ! Usage:
    !
    ! CALL ALLOCA_VARS(IOP)
    !
    ! uses modules, functions, and subroutines
    !
    ! *Module VARS_MAIN !module with the model main variables
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
    ! Variables and Parameters:
    ! *Variables declarations and routines calls are all commented below.
    !---------------------------------------------------------------------------------
    ! End of header
    !---------------------------------------------------------------------------------

SUBROUTINE ALLOCA_VARS(IOP)
    
! Variables and Modules

	USE VARS_MAIN
	IMPLICIT NONE	
	
    INTEGER IOP
    SAVE

! Select the case how the subroutine is working: for allocation, or for deallocation.

	ALLOCV_CASE: SELECT CASE (IOP) !Checks for allocation or deallocation. IOP=0 means allocation, and IOP=1 means deallocation.
    CASE (0) ! Allocation          
        ALLOCATE (QTUDO(NC),YTUDO(NC)) !Streamflow at all catchments #Vinicius Siqueira
        ALLOCATE (ALAGTUDO(NC),TWSTUDO(NC))                       !! Sly + Vinicius
        ALLOCATE (HANDTUDO(NC))
		ALLOCATE (EVQ(NC)) !Direct evaporation of the liquid surface of the cell in m3 / s
		ALLOCATE (QRIOINI(NC,NUMUSK+1)) !Initial condition of muskingum Cunge rounting
		ALLOCATE (QCONTORM(NC+1,25),QCONTORJ(NC+1,25)) !Streamflow boundary condition for Muskingum Cunge
		ALLOCATE (SI(NC,NU)) !Water interception 
		ALLOCATE (XYC(NCLI,2))!x and y coordinates of climatological stations
		ALLOCATE (TAMM(NCLI,12),URMM(NCLI,12),VVMM(NCLI,12)) !Climatological means (Temperature, Relative humidity, Wind velocity)
		ALLOCATE (PAMM(NCLI,12),SOLMM(NCLI,12)) !Climatological means (pressure and insolation)
		
		ALLOCATE (QREF(NC)) !Reference flow
	 	ALLOCATE (PUSO(NC,NU))!Proportion of uses in minibasin
	 	ALLOCATE (ACEL(NC),ACUR(NC),SRIO(NC),DECL(NC))
		ALLOCATE (X(NC),Y(NC))!Coordinates of the cell center
        ALLOCATE (REGCLI(NC)) !Climate regions
		ALLOCATE (IBAC(NC),HCEL(NC),LCEL(NC),CELJUS(NC),CELJUS2(NC))!SubBasin,HMAX,HMIN,Downstream minibasin ! SIN_RESERV celjus2
		ALLOCATE (BRIO(NC))!River width
		ALLOCATE (IEXUT(NB)) !Indicate the outlets of the basin
		ALLOCATE (CI(NB),CB(NB),CS(NB)) !Pparameters of propagation in cell
		ALLOCATE (PLAM(NB,NU),CAP(NB,NU),WC(NB,NU))

		ALLOCATE (WM(NB,NU),B(NB,NU),KINS(NB,NU),KBAS(NB,NU),KINF(NB,NU))
		ALLOCATE (NSUBT(NC)) !Number of stretchs for MUSKINGUM CUNGE routing (diferent at each minibasin)
		ALLOCATE (DT(NC)) !Time steps for MUSKINGUM CUNGE (diferent at each minibasin)
		ALLOCATE (CEL(NC),TIND(NC))
		ALLOCATE (ALB(NU,12,NREG),RIAF(NU,12,NREG),Z(NU,12,NREG),RS(NU,12,NREG)) !Allocation for specific climate regions
		ALLOCATE (QESP(NB))	 !Specific baseflow (M3/S/KM2)
		ALLOCATE (KCB(NB)) !Number of minibasins inside each subbasin
		ALLOCATE (QLIDO(NUMSUBST,NT)) !Flow that is read to replace calculated
		
		ALLOCATE (QM1(NC+1),QJ1(NC),QM2(NC+1),QJ2(NC)) !Streamflows upstream and downstream in i
		ALLOCATE (QCEL1(NC),QCEL2(NC)) !Original streamflows at minibasins at the instants t E t+1 at minibasin i
		ALLOCATE (PMB2(NC+1),PMI2(NC+1),PMS2(NC+1),PJB2(NC+1),PJI2(NC+1),PJS2(NC+1)) !Proportions source of streamflow to the river
		ALLOCATE (VRB(NC),VRI(NC),VRS(NC)) !Volumes of proportions source of streamflow to the river
		ALLOCATE (ET(NC,NU)) 	!Total evapotranspiration
		ALLOCATE (CAF(NC,NU))		!Upward capillary flow
		ALLOCATE (W(NC,NU)) 	!Amount of water in the soil
		ALLOCATE (QBAS(NC),QINT(NC),QSUP(NC))		!Flows at the minibasins
		ALLOCATE (VBAS(NC),VINT(NC),VSUP(NC))		!Volume at the minibasin
		ALLOCATE (TONTEM(NC))		!Previous day temperature
		ALLOCATE (P(NC)) !Rainfall at the interval in the cell
		ALLOCATE (TA(NC),UR(NC),VV(NC),SOL(NC),PA(NC))	!Temperature, Umidity, Wind, Insolation, Pressure
	
		allocate (OD(NC)) !Inertial modification
 
	
		allocate (sbtFLAG(nC))
		
		! Variables to calculate indicators of maximum evapotranspiration:
		allocate (E0agua(nC),E0TOPO(nC),E0SUP(nC))

       
        ALLOCATE (QITUDO(NC)) !incremental discharges everytime and everywhere
	    ALLOCATE (EVAPTUDO(NC)) !ET
        ALLOCATE (ETINTERC(NC)) !CEAA
        ALLOCATE (EVAPURHAGUA(nc)) !CEAA
        ALLOCATE (ETSOILPLANT(NC)) !CEAA
        ALLOCATE (ETOPENWAT(NC)) !CEAA
        ALLOCATE (SOILWATER(NC)) !CEAA
        ALLOCATE (VINTERC(NC)) !CEAA
        ALLOCATE (CAPWATER(NC)) !CEAA
        ALLOCATE (VBASMMDIA(NC)) !CEAA
        ALLOCATE (VSUPMMDIA(NC)) !CEAA
        ALLOCATE (VINTMMDIA(NC)) !CEAA
        ALLOCATE (DBASMMDIA(NC)) !CEAA
        ALLOCATE (DSUPMMDIA(NC)) !CEAA
        ALLOCATE (DINTMMDIA(NC)) !CEAA
        allocate (qceltudo(nc)) !ceaa
        ALLOCATE (SURFWAT(NC)) !CEAA
        ALLOCATE (QBASTUDO(NC)) !catchment baseflows 
		ALLOCATE (WSATDEGREE(NC)) !soil moisture volume       
		ALLOCATE (TWS2(NC)) !Total Water Storage
        ALLOCATE (vflow(NC)) ! Flow velocities
        ALLOCATE (WriteHotFile(NT))
		!FMF 09/09/2015 
		ALLOCATE (RUGMAN(NC)) !Manning
        allocate (Ind_Reserv(nC), iTini_Reserv(nC)) ! SIN_RESERV

    !****************************************************************************************************
    !VINICIUS SIQUEIRA IN 07-11-2016 
    !MGB for SOUTH AMERICA modifications
    !Arrays declarations inside subroutines have been taken to this module
    !****************************************************************************************************
        
        ALLOCATE (TKB(NC),TKI(NC),TKS(NC))       
        ALLOCATE (PMB1(NC+1),PMI1(NC+1),PMS1(NC+1))           
	    ALLOCATE (PJB1(NC),PJI1(NC),PJS1(NC))
        
        
    CASE (1) ! Deallocation
	    DEALLOCATE (QTUDO) !Streamflow at all minibasins flow at all time steps
		DEALLOCATE (EVQ) !Direct evaporation of the liquid surface of the cell in m3/s
		DEALLOCATE (QCONTORM,QCONTORJ) !Boundary condition of muskingum Cunge rounting

		DEALLOCATE (XYC)!x and y coordinates of climatological stations
		DEALLOCATE (TAMM,URMM,VVMM)
		DEALLOCATE (PAMM,SOLMM)
				
		DEALLOCATE (QREF) !Reference flow
	 	DEALLOCATE (PUSO)!Proportion of uses in minibasin
	 	DEALLOCATE (ACEL,ACUR,SRIO,DECL)
		DEALLOCATE (X,Y)!Coordinates of the cell center
        DEALLOCATE (REGCLI) !Climate regions
		DEALLOCATE (IBAC,HCEL,LCEL,CELJUS)!SubBasin,HMAX,HMIN,Downstream minibasin
		DEALLOCATE (BRIO)!River width
		DEALLOCATE (IEXUT) !Indicate the outlets of the basin
		DEALLOCATE (CI,CB,CS) !Parameters of propagation in cell
		DEALLOCATE (PLAM,CAP,WC)
		DEALLOCATE (WM,B,KINS,KBAS,KINF)
		DEALLOCATE (NSUBT,DT)
		DEALLOCATE (CEL,TIND)
		DEALLOCATE (ALB,RIAF,Z,RS)
		DEALLOCATE (QESP)	 !Specific baseflow (M3/S/KM2)
		DEALLOCATE (KCB) !Number of minibasins inside each subbasin
		DEALLOCATE (SI)
		DEALLOCATE (QM1,QJ1,QM2,QJ2) !Streamflows upstream and downstream in i
		DEALLOCATE (PMB2,PMI2,PMS2,PJB2,PJI2,PJS2) !Proportions source of streamflow to the river
		DEALLOCATE (VRB,VRI,VRS) !Volumes of proportions source of streamflow to the riverO
		DEALLOCATE (ET) 	!Total evapotranspiration
		DEALLOCATE (CAF)		!Upward capillary flow
		DEALLOCATE (W) 	!Amount of water in the soil
		DEALLOCATE (QBAS,QINT,QSUP)		!Flows at the minibasin
		DEALLOCATE (VBAS,VINT,VSUP)		!Volume at the minibasin
		DEALLOCATE (TONTEM)		!Previous day temperature
		DEALLOCATE (P) !Rainfall at the interval in the cell
		DEALLOCATE (TA,UR,VV,SOL,PA)	!Temperature, Umidity, Wind, Insolation, Pressure
		DEALLOCATE (QCEL1,QCEL2) !Originated streamflows at minibasins at the instants t E t+1 at minibasin i
		DEALLOCATE (QLIDO) !Calculated streamflow for substitution
	
		deallocate (OD) !RP
		
        DEALLOCATE (QITUDO) !incremental discharges everytime and everywhere
	    DEALLOCATE (EVAPTUDO) !et everytime and everywhere
        DEALLOCATE (ETINTERC) !CEAA
        DEALLOCATE (EVAPURHAGUA) !CEAA
        DEALLOCATE (ETSOILPLANT) !CEAA
        DEALLOCATE (ETOPENWAT) !CEAA
        DEALLOCATE (SOILWATER) !CEAA
        DEALLOCATE (VINTERC) !CEAA
        DEALLOCATE (CAPWATER) !CEAA
        DEALLOCATE (VSUPMMDIA) !CEAA
        DEALLOCATE (VINTMMDIA) !CEAA
        DEALLOCATE (VBASMMDIA) !CEAA
        DEALLOCATE (DSUPMMDIA) !CEAA
        DEALLOCATE (DINTMMDIA) !CEAA
        DEALLOCATE (DBASMMDIA) !CEAA
        deallocate (surfwat) !ceaa
        deallocate (Qceltudo) !ceaa
	    DEALLOCATE (QBASTUDO) !catchment baseflows everytime and everywhere
		DEALLOCATE (WSATDEGREE) !soil moisture volme everytime and everywhere        
        deallocate (TWS2) ! Storage anomaly GRACE
        deallocate (vflow) ! Flow velocities
		DEALLOCATE (WriteHotFile)
        DEALLOCATE (YTUDO)      !! Sly + Vinicius
        DEALLOCATE (ALAGTUDO)
        DEALLOCATE (TWSTUDO)
        DEALLOCATE (HANDTUDO)
        
		!FMF 09/09/2015 
		DEALLOCATE (RUGMAN) !Manning
		
		!****************************************************************************************************
    !VINICIUS SIQUEIRA IN 07-11-2016
    !MGB for SOUTH AMERICA modifications
    !Arrays declarations inside subroutines have been taken to this module
    !****************************************************************************************************
		
		DEALLOCATE (TKB,TKI,TKS)
		DEALLOCATE (PMB1,PMI1,PMS1)           
	    DEALLOCATE (PJB1,PJI1,PJS1)
		
	CASE DEFAULT
		STOP ' ERROR: IOP UNKNOWN AT ROUTINE ALLOCA_CALIB!!!'
	END SELECT ALLOCV_CASE

	! End of the routine.
	END
