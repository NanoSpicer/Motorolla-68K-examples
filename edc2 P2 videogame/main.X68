*-----------------------------------------------------------
* Program    : Main file to test taskmanager
* Written by : Antoni Burguera
* Date       : 17-November-2015
* Description: Main file to execute a "tasks" file. No changes
*              should be done to this file.
*-----------------------------------------------------------

************************************************************
*                   ASSEMBLER DIRECTIVES                   *
************************************************************
	OPT	MEX		; Explicitly expand macros
	ORG	$1000		; Start code at address $1000
	
************************************************************
*                         INCLUDES                         *
************************************************************
	INCLUDE "list.X68"	; The list library
	INCLUDE "taskmanager.X68" ; The task manager
	INCLUDE "idpool.X68"	; Task ID manager
	INCLUDE "dmm.X68"	; Task Memory manager
	INCLUDE	"tasks.X68" ; The tasks file
	
************************************************************
*                       MAIN PROGRAM                       *
************************************************************
START:				
	; Install the Task Manager
	jsr	TM_INSTALL
	
	; Init the task set
	jsr	TK_INIT
	
	; Start execution
	TM_SYSTEM_CALL  TM_FGROUP_EXECUTION, TM_START

	; If everything is OK, this point will never be reached.
	; However, for the sake of completeness, let's stop
	; the simulator here.
	MOVE.B	#9,D0
	TRAP	#15		

	END	START






















*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~8~
