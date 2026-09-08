! SPDX-License-Identifier: GPL-3.0-or-later
! Copyright (C) 2019 Hidrologia de Grande Escala (HGE)

! Read discharge series that replace simulated flow at selected catchments.

	SUBROUTINE read_substitution_flows
	USE model_state
	IMPLICIT NONE
	INTEGER :: input_year, input_month, substitution_index, input_day
	OPEN(substitution_flow_unit,FILE=input_directory // 'qsubst.qsb',STATUS='OLD')
	READ(substitution_flow_unit,701)(header_fields(substitution_index),substitution_index=1,substitution_count)
	DO timestep_index=1,timestep_count
	READ(substitution_flow_unit,*)input_year,input_month,input_day,(substituted_q(substitution_index,timestep_index),substitution_index=1,substitution_count)
	ENDDO
	CLOSE (substitution_flow_unit)
701	FORMAT(20A10)
	RETURN
	END SUBROUTINE read_substitution_flows
