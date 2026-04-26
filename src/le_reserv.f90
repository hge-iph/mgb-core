subroutine LE_RESERV
    
! This subroutine reads information about hydropower reservoirs
! It reads reservoir outflow series and the unit-catchment related to the dam and reservoir lake
!
! FILES: sin_dados_defluencia.txt
!        sin_minibacias_lago.txt
!    
! routine from august 2020 - IPH/UFRGS ! SIN_RESERV  

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! Declaracao de Variaveis
use VARS_MAIN
use VARS_INERC

implicit none

integer :: nlagos, nlagos_tudo      ! numero de minibacias do lago
integer :: lixo1, i, j, k, iTini    ! variavel auxiliar para leitura
integer :: flag_Simu, flag_lago     ! flags se ocorre simulação e se o lago é desconsiderado no flood_tab
integer :: Substitui_res            ! flag geral que indica se vai ou não ter substituição
integer :: mm,dd,aa, nT2, julday    ! variaveis de tempo
integer, dimension(nC) :: lagos_minibacia ! minibacias que fazem parte dos lagos dos reservatorios
real    :: VOLINCR                  ! volume incremental
character(len=15)   :: lixo_char    ! leitura do nome dos reservatorios


allocate(Qdefl(nT,nSIN))

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! Abrindo e lendo o arquivo das minibacias do lago indicando qual minibacia vai ter subs por defluencia
! indicando quais minibacias fazem parte do lago e vao ter as planicies desligadas
! substituindo a condicao de jusante das minibacias a montante do barramento

open(159,FILE='input/sin_minibacias_lago.txt')

nlagos_tudo=0
lagos_minibacia=0
Substitui_res = 0

do i=1,nSIN
    ! nome_uhe, codigo_sar, flag_simulacao, flag_lago, numero_de_minibacias_no_lago, minibacias_do_lago
    read(159,*) lixo_char, lixo1, flag_Simu, flag_lago, nlagos, lagos_minibacia((nlagos_tudo+1):(nlagos+nlagos_tudo))
    !print*, lixo_char, lixo1, flag_Simu, flag_lago, nlagos, lagos_minibacia((nlagos_tudo+1):(nlagos+nlagos_tudo))

    
    ! se nao tem minibacia para esse reservatorio, nem 
    if (nlagos==0) then
        flag_lago=0
        flag_simu=0
    endif   
    
    ! minibacia do barramento, a minibacia mais de jusante eh a primeira lida no arquivo
    iC=lagos_minibacia(nlagos_tudo+1)
    
    ! se flag de simulacao tiver ligado, o indice na posicao da minibacia mais de jusante recebe a numeracao do SIN (1,2,3 .., 162)
    if (flag_simu>0) then
        Ind_Reserv(iC)=i
        Substitui_res = 1
        
        ! mudando a condicao de jusante das minis a montante do barramento
        !Number of upstream catchments of IC
        Nentradas = MINIMONT(iC,1)            
        if(Nentradas>0)then
            do j=1,Nentradas
                CELJUS2(MINIMONT(iC,1+j))=-2
            enddo            
        endif
        CELJUS2(iC)=-2
    endif
    
    ! se o flag de simulacao estiver ligado, contabiliza as minibacias, se nao, recebem o valor de 0
    ! print*, iC, Ind_Reserv(iC)
    if (flag_lago>0) then
        nlagos_tudo=nlagos_tudo+nlagos
    else
        lagos_minibacia((nlagos_tudo+1):(nlagos+nlagos_tudo))=0
    endif     
enddo
close(159)

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! Mudando a curva cota-volume para as minibacias dos lagos (lagos_minibacia)

j=1
do while (lagos_minibacia(j)>0)

    IC=lagos_minibacia(j)
    !print*,(iC), j, lagos_minibacia(j)    
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    !! modified from flood_TAB 
    ATAB(3,IC)=ATAB(2,IC) !CEAA        
    VTAB(3,IC)=VTAB(2,IC)+ATAB(3,IC)*(ZTAB(3,IC)-ZTAB(2,IC))*1000000.0 !CEAA
    !VTAB(3,IC)=VTAB(2,IC)+0.5*(ATAB(3,IC)+ATAB(2,IC))*(ZTAB(3,IC)-ZTAB(2,IC))*1000000.0 !CEAA !This must be turned on in the MGB 2.0 version        
        
    !From next points the volume are calculated using area and level from trapezium approach
    DO K=1,NPFL(IC)-1
        ATAB(K+3,IC)=ATAB(2,IC) !CEAA
        !ATAB(K+3,IC)=MAX(AFL(K+1,IC),ATAB(3,IC)) !CEAA !This must be turned on in the MGB 2.0 version
        VOLINCR=(ZFL(K+1,IC)-ZFL(K,IC))*1000000.0*ATAB(2,IC) !CEAA 
        !VOLINCR=(ZFL(K+1,IC)-ZFL(K,IC))*1000000.0*(ATAB(K+3,IC)+(ATAB(K+2,IC))*0.5) !CEAA !This must be turned on in the MGB 2.0 version
        VTAB(K+3,IC)=VTAB(K+2,IC)+VOLINCR            
    ENDDO
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    
    j=j+1

enddo
Qdefl=-1 ! Defluencia inicial é noData
 
if (Substitui_res>0)then

    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    ! Abrindo e lendo o arquivo de defluencias

    ! Abrindo uma primeira vez apenas pra saber o dia que comeca a medicao dos dados
    open(159,FILE='input/sin_dados_defluencia.txt')
    ! lendo o dias, mes e ano da primeira medicao
    read(159,*) aa, mm, dd
    close(159)

    ! nt2 corresponde ao dia inicial da simulacao menos o dia que comecam as observacoes
    nT2=IDINI-julday(mm,dd,aa)

    iTini=1
    if (nT2<0) then ! se a simulacao ocorre antes
        iTini=1-nT2
        nT2=0
    endif


    ! abrindo uma segunda vez para a leitura de fato
    open(159,FILE='input/sin_dados_defluencia.txt')

    ! leitura desconsiderada ateh a linha nT2 pq nao vai ser simulado esse periodo
    do iT=1,nT2
        read(159,*)
    enddo

   
    ! leitura de fato
    do iT=iTini,nT
        read(159,*) aa, mm, dd, Qdefl(iT,:)
    enddo

    close(159)


    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    ! Verificando dia do comeco da defluencia

    iTini_reserv=1
    do iC=1,nC                          ! loop minibacias
        if (Ind_Reserv(iC)>0) then      ! se tem reservatorio
            i=Ind_Reserv(iC)            ! verifica qual reservatorio
            do iT=1,nT                  ! loop do tempo
                if (Qdefl(iT,i)>0) then ! se tiver defluencia nesse dia especifico
                    iTini_reserv(iC)=iT ! comeca a substituir ali
                    exit                ! sai do loop do tempo
                endif                   ! end
            enddo                       ! end
        endif                           ! end
    enddo                               ! end
endif

end subroutine
    
