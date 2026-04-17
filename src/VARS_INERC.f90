
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
    ! 2014.11.12 - 12 November 2014
    ! By: Paulo Pontes
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
    
    MODULE VARS_INERC
	!DECLARAÇÃO DE VARIÁVEIS RELACIONADAS AO MODELO DE PROPAGAÇÃO INERCIAL
	IMPLICIT NONE
	SAVE

    REAL*8 alpha                               !Coeficiente alpha, moved to infoMGB.sim #VAS
    REAL*8,PARAMETER:: g=9.81                 !Coeficiente alpha utilizado para calculo do dt ideal do modelo Inercial
    REAL*8,PARAMETER:: dxart=5.               !dx artificial caso o comprimento do rio de uma minibacia seja muito pequeno Ver flood_timestep
    
    REAL*8,ALLOCATABLE:: nMan(:)            !Rugosidade considerada no modelo Inercial !FMF 09/09/2015 
    
    INTEGER thread_count                        !Number of processor threads to be used in OMP parallelization
    INTEGER,ALLOCATABLE:: HDFLAG(:)             !Código do modelo hidrodinâmico ou inercial
    INTEGER hdFLAG0                             !Flag do modelo hidrinâmico ou inercial
    INTEGER,ALLOCATABLE:: MINIMONT(:,:)         !MATRIZ COM RELAÇÕES TOPOLÓGICAS DE CADA MINI-BACIA
    INTEGER,ALLOCATABLE:: NPFL(:)               !NUMERO DE PONTOS DA TABELA COTA-AREA EM CADA MINI-BACIA
    INTEGER,ALLOCATABLE:: ZFUNDOFL(:)           !COTA DO FUNDO DA PLANICIE DA TABELA COTA-ÁREA
    INTEGER,ALLOCATABLE:: ZFL(:,:)              !COTA DA PLANICIE PARA TABELA COTA-AREA
    REAL*8,ALLOCATABLE:: AFL(:,:)                 !ÁREA DA PLANICIE PARA TABELA COTA-AREA
    REAL*8,ALLOCATABLE:: HRIO(:)                  !PROFUNDIDADE DE CALHA CHEIA DO RIO
    REAL*8 HRX                                    !PROFUNDIDADE DE CALHA CHEIA DO RIO (VARIÁVEL AUXILIAR) 
    REAL*8,ALLOCATABLE:: ZTAB(:,:)                !COTA PARA TABELA COTA-VOLUME DE CADA MINI-BACIA
    REAL*8,ALLOCATABLE:: VTAB(:,:)                !VOLUME PARA TABELA COTA-VOLUME DE CADA MINI-BACIA
    REAL*8,ALLOCATABLE:: ATAB(:,:)
    REAL*8 dtfloodmax,dtflood,dtflood0,tflood     !Variáveis relacionadas ao intervalo de tempo do modelo inercial
    REAL*8,ALLOCATABLE:: dtfloodIC(:)
    REAL*8 hmaxfl                                 !Variável que recebe a profundidade máxima do vetor Hfl
    REAL*8,ALLOCATABLE:: Q2fl(:),Vel2fl(:)        !Vazão e velocidade calculada pelo modelo inercial em cada minibacia
    REAL*8,ALLOCATABLE:: Qmont(:),Vol2(:),Vol1(:) !Vazão a montante e Volumes no tempo t e t+1 em uma determinada minibacia
    REAL*8:: SumQup
    REAL*8,ALLOCATABLE:: Area2(:)
    REAL*8,ALLOCATABLE:: Hfl(:),Yfl(:)    !Profundidade e Nível de água em cada minibacia
    REAL*8 nfroude                                !Numero de Froude para testes de regime supercritico
    REAL,ALLOCATABLE:: YRG(:,:)	 !ARMAZENA HIDROGRAMAS ONDE SE DESEJA GRAVAR
    REAL,ALLOCATABLE:: HRG(:,:)	 !ARMAZENA HIDROGRAMAS ONDE SE DESEJA GRAVAR
    REAL,ALLOCATABLE:: AFLRG(:,:)!ARMAZENA HIDROGRAMAS ONDE SE DESEJA GRAVAR
    REAL,ALLOCATABLE:: AFLTUDO(:,:) !ÁREA ALAGADA EM TODAS AS MINIBACIAS EM TODOS OS INTERVALOS DE TEMPO !UTILIZADA AQUI PARA FAZER A MEDIA DE INUNDAÇÃO NA SUB-BACIA DO INLAND DELTA
    REAL,ALLOCATABLE:: wwm_mean(:) !average soil moisture saturation in the InlandDelta
    REAL,ALLOCATABLE:: HAND(:)
                                                
    
    INTEGER YFLOOD_RECORD(10) !TIME INTERVALS TO SAVE WATER LEVELS (YFLOOD) FILES. MAXIMUM NUMBER OF 5 ITs 
    INTEGER TIMEINT_YFLOOD  !NUMBER OF TIME INTERVALS TO SAVE WATER LEVELS (YFLOOD) FILES
    
    !Variáveis da rotina discharge
    real*8 z1,y1,z2,y2,Sflow,hflow
	real*8 dxflow,bflow,q0,q, xMan
    real*8 bflow_overland,xMan_overland         !Parameters for lateral connections, considering overland flow
    real*8 WSslope
	integer iCJus
    
    !Variáveis da rotina continuity
    integer Nentradas, Kent, Jent,itab1,itab2,imeio
    real*8 y2_fl 
    
    INTEGER :: nFACE,iFACE,KCAT,KCAT2                             !NUMERO DE PONTOS DA TABELA DE FACES
    REAL*8,ALLOCATABLE:: nFACECAT1(:),nFACECAT2(:),Q2face(:),nFACEY1(:),nFACEY2(:),nFACEDX(:),Q2viz(:)                     !Vazão nas faces
    integer,allocatable:: jtab(:)
    REAL,ALLOCATABLE:: QRG_viz(:,:)	!Stores connection flows where you want to record them
    
    REAL,ALLOCATABLE:: DINFILT(:) !INFILTRATION FROM FLOODPLAIN TO SOIL
    REAL DINFILTX !INFILTRATION FROM FLOODPLAIN TO SOIL
    
    real*8 areajtab, yjtab !Para cálculo na curva cota-Area
    real*8 volume_temp !Para cálculo na curva cota área
    real*8,allocatable::  TWS(:) !For comparison to GRACE data
        
    integer flag_WriteHot, flag_ReadHot !Flag for writing or reading hotstart values
    
    real(kind=8), dimension(:,:), allocatable  :: Qdefl ! vazao defluente dos reservatorios ! SIN_RESERV
    
    END MODULE
