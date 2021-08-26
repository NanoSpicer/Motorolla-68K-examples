*-----------------------------------------------------------
* Program    : Simple tasks ready to be run with TaskManager
*              installed. See taskmanager.X68 for
*              more info.
* Written by : A. Burguera
* Date       : 17-Nov-2015
* Description: Simple tasks that print their ID, group, and
*              also whether they are initializing or not.
*-----------------------------------------------------------
	
************************************************************
*                     COMMON CONSTANTS                     *
************************************************************
; Task groups
TK_GROUP0			EQU	0
TK_GROUP1			EQU	1

************************************************************
*                    INITIALIZATION ROUTINE                *
************************************************************

* ----------------------------------------------------------
TK_INIT:
* Adds the tasks in the approppriate order into the task
* manager.
* ----------------------------------------------------------
; Define minimum cycle time
		move.l	#500, D1
		TM_SYSTEM_CALL  TM_FGROUP_CONFIG, TM_DEFINE_TIME
		
; Deactivate time-over detection
		TM_SYSTEM_CALL  TM_FGROUP_CONFIG, TM_NEGLECT_TIME_OVER		
; Add task 1
		lea	T1_TEP, A0	; TEP
		move.w	#TK_GROUP0, D1	; GROUP
		TM_SYSTEM_CALL  TM_FGROUP_BASIC, TM_ADD_TASK
; Add task 1
		lea	T1_TEP, A0
		move.w	#TK_GROUP0, D1
		TM_SYSTEM_CALL  TM_FGROUP_BASIC, TM_ADD_TASK
; Add task 1
		lea	T1_TEP, A0
		move.w	#TK_GROUP0, D1
		TM_SYSTEM_CALL  TM_FGROUP_BASIC, TM_ADD_TASK
; Add task 1
		lea	T1_TEP, A0
		move.w	#TK_GROUP0, D1		
		TM_SYSTEM_CALL  TM_FGROUP_BASIC, TM_ADD_TASK
; Add task 2
		lea	T2_TEP, A0
		move.w	#TK_GROUP1, D1
		TM_SYSTEM_CALL  TM_FGROUP_BASIC, TM_ADD_TASK
; Add task 2
		lea	T2_TEP, A0
		move.w	#TK_GROUP1, D1
		TM_SYSTEM_CALL  TM_FGROUP_BASIC, TM_ADD_TASK
; Add task 2
		lea	T2_TEP, A0
		move.w	#TK_GROUP1, D1			
		TM_SYSTEM_CALL  TM_FGROUP_BASIC, TM_ADD_TASK
; Add task 2
		lea	T2_TEP, A0
		move.w	#TK_GROUP1, D1			
		TM_SYSTEM_CALL  TM_FGROUP_BASIC, TM_ADD_TASK
			
		rts
* ----------------------------------------------------------


************************************************************
*                            TASK 1                        *
************************************************************

; ==========================================================
; Task 1 functions
; ==========================================================

* ----------------------------------------------------------
T1_TEP:
* Task 1 entry point.
* Displays a text showing task group and ID
* ----------------------------------------------------------
; Check if status is initializing. If so, execute the initia-
; lization code.
		cmp.w	#TM_TCB_STATUS_INIT, D3
		beq	T1_INIT
		
; Copy ID and Group to 		
		move.w	D1, D4
		move.w	D2, D5
		
; Display string, group and ID
		move.l	#T1_STR1, A1
		move.b	#14, D0
		trap	#15
		
		clr.l	D1
		move.w	D5, D1
		move.b	#3, D0
		trap	#15
		
		move.l	#T1_STR2, A1
		move.b	#14, D0
		trap	#15
		
		clr.l	D1
		move.w	D4, D1
		move.b	#3, D0
		trap	#15
		
		move.l	#T1_STR3, A1
		move.b	#13, D0
		trap	#15
		
; End by switching to next task
		TM_SYSTEM_CALL  TM_FGROUP_EXECUTION, TM_RETURN_TO_TM

* ----------------------------------------------------------
T1_INIT:														
* Task 1 initialization code
* Displays a string telling it is initializing.
* ----------------------------------------------------------
		move.l	#T1_STR4, A1
		move.b	#13, D0
		trap	#15

; End by switching to next task
		TM_SYSTEM_CALL  TM_FGROUP_EXECUTION, TM_RETURN_TO_TM
		
; ==========================================================
; Task 1 strings
; ==========================================================
T1_STR1:	dc.b	'I am T1. My GROUP is ',0
T1_STR2:	dc.b	' and my ID is ',0
T1_STR3:	dc.b	$0D, $0A, 0
T1_STR4:	dc.b	'I am T1 and I am initializing myself.',0
		ds.w	0

************************************************************
*                            TASK 2                        *
************************************************************

; ==========================================================
; Task 2 functions
; ==========================================================

* ----------------------------------------------------------
T2_TEP:
* Task 2 entry point.
* Displays a text showing task group and ID
* ----------------------------------------------------------
; Check if status is initializing. If so, execute the initia-
; lization code.
		cmp.w	#TM_TCB_STATUS_INIT, D3
		beq	T2_INIT
		
; Copy ID and Group to 		
		move.w	D1, D4
		move.w	D2, D5
		
; Display string, group and ID
		move.l	#T2_STR1, A1
		move.b	#14, D0
		trap	#15
		
		clr.l	D1
		move.w	D5, D1
		move.b	#3, D0
		trap	#15
		
		move.l	#T2_STR2, A1
		move.b	#14, D0
		trap	#15
		
		clr.l	D1
		move.w	D4, D1
		move.b	#3, D0
		trap	#15
		
		move.l	#T2_STR3, A1
		move.b	#13, D0
		trap	#15
		
; End by switching to next task
		TM_SYSTEM_CALL  TM_FGROUP_EXECUTION, TM_RETURN_TO_TM

* ----------------------------------------------------------
T2_INIT:														
* Task 2 initialization code
* Displays a string telling it is initializing.
* ----------------------------------------------------------
		move.l	#T2_STR4, A1
		move.b	#13, D0
		trap	#15

; End by switching to next task
		TM_SYSTEM_CALL  TM_FGROUP_EXECUTION, TM_RETURN_TO_TM
		
; ==========================================================
; Task 1 strings
; ==========================================================
T2_STR1:	dc.b	'I am T2. My GROUP is ',0
T2_STR2:	dc.b	' and my ID is ',0
T2_STR3:	dc.b	$0D, $0A, 0
T2_STR4:	dc.b	'I am T2 and I am initializing myself.',0
		ds.w	0
*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~8~
