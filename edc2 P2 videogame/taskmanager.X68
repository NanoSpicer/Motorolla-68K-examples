*-----------------------------------------------------------
* Program    : Task Manager
* Written by : A. Burguera and Miquel Àngel Román Coolom
*                               43235792R
* Date       : 17 - November - 2015
* Description: YASTM: Yet Another Simple Task Manager 
*-----------------------------------------------------------

************************************************************
*           Task Control Block (TCB) Structure             *
************************************************************
* + 0: ID (1 WORD): Task Identifier. Unique among TCBs.    *
* + 2: GROUP (1 WORD): Task Group identifier. Unique among *
*                      groups, not necessarily unique among*
*                      TCBs.                               *
* + 4: STATUS (1 WORD): Task status. Possible values:      *
*                     0: Initializing                      *
*                     1: Running                           *
*                     2: Sleeping                          *
*                     3: Removable                         *
* + 6: TEP (1 LONG): Task Entry Point. Pointer to the task *
*                    code.                                 *
* +10: TMP (1 LONG): Task Memory Pointer. Pointer to the   *
*                    task memory.                          *
************************************************************

************************************************************
*                        CONSTANTS                         *
************************************************************
TM_MAX_TASKS:			EQU	100     ; Maximum number of tasks
TM_SHARED_MEMORY_SIZE:		EQU	200	; Shared memory size (in words)
TM_TASK_MEMORY_SIZE:		EQU	200	; Each task memory size (in words)
TM_TCB_SIZE:			EQU	1+1+1+2+2 ; Size of the TCB in WORDS. Not a parameter, it 
						; MUST NOT be modified. See the TCB description.
TM_TCB_LIST_SIZE:		EQU	1+2+2+TM_MAX_TASKS*(2+TM_TCB_SIZE) ; Size of the TCB List. Not a
						; parameter. It MUST NOT be modified.
TM_TCB_ID_W:			EQU	0	; Offset to TCB ID
TM_TCB_GROUP_W:			EQU	2	; Offset to TCB Group
TM_TCB_STATUS_W:		EQU	4	; Offset to TCB Status
TM_TCB_TEP_L:			EQU	6	; Offset to TCB TEP
TM_TCB_TMP_L:			EQU	10	; Offset to TCB TMP
TM_TCB_STATUS_INIT:		EQU	0	; TCB Status Init
TM_TCB_STATUS_RUN:		EQU	1	; TCB Status Run
TM_TCB_STATUS_SLEEP:		EQU	2	; TCB Status Sleep
TM_TCB_STATUS_REMOVE:		EQU	3	; TCB Status Remove

; ----------------------------------------------------------
;              FUNCTION NUMBERS AND GROUPS
; ----------------------------------------------------------
TM_FGROUP_BASIC:                EQU     0
TM_ADD_TASK:                    EQU     0
TM_REMOVE_TASK:                 EQU     1
TM_REMOVE_TASK_GROUP:           EQU     2

TM_FGROUP_EXECUTION:            EQU     1
TM_START:                       EQU     0
TM_RETURN_TO_TM:                EQU     1
TM_FRAME_DROP:                  EQU     2
TM_SLEEP_TASK:                  EQU     3
TM_WAKE_UP_TASK:                EQU     4
TM_RESTART_TASK:                EQU     5

TM_FGROUP_INFO:                 EQU     2
TM_CURRENT_TASK_INFO:           EQU     0
TM_FIRST_TASK_INFO:             EQU     1
TM_NEXT_TASK_INFO:              EQU     2

TM_FGROUP_CONFIG:               EQU     3
TM_DEFINE_TIME:                 EQU     0
TM_NEGLECT_TIME_OVER:           EQU     1
TM_PREVENT_TIME_OVER:           EQU     2
************************************************************

************************************************************
*                         MACROS                           *
************************************************************
*-----------------------------------------------------------
* Helper macro to ease system calls
* Parameters: \1 FUNCTIONALITY GROUP
*             \2 FUNCTION NUMBER (BYTE)
* Modifies  : D0
*-----------------------------------------------------------		
TM_SYSTEM_CALL	MACRO
		move.b	#\2, D0
		trap	#\1
		ENDM
*-----------------------------------------------------------	


************************************************************
*                      MAIN SUBROUTINES                    *
************************************************************

*-----------------------------------------------------------
TM_INSTALL:
* Description : Installs the task manager by doing:
*		1.- Initializing to zero the minimum cycle time, just
*                   to have a default value. 
*               2.- Initializing Dynamic Memory Manager
*               2.- Initializing ID Pool
*               3.- Initializing TCB List
*               4.- Installing the TRAP #0 dispatcher
*               5.- Switching to user mode
* Pre         : --
* Post        : Everything initialized and installed
* Modified    : A0, Stack (switched to user stack)
* Note        : When calling this subroutine, the required constants
*               are assumed to have the correct values.
*-----------------------------------------------------------
		; Initialize to zero minimum cycle time
		clr.l 	(TM_MIN_CYCLE_TIME)
		
		; Initialize the time over flag
		clr.b   (TM_TIME_OVER)
		
		; Initialize the allow time over flag
		move.b  #$FF, (TM_ALLOW_TIME_OVER)
				
		; Init Dynamic Memory Manager and ID Pool.
		bsr	DMM_INIT
		bsr	IDP_INIT
	
		; Init the Task Control Block list
		move.w	#TM_TCB_SIZE, -(A7)
		move.w	#TM_MAX_TASKS, -(A7)
		move.l	#TM_TCB_LIST, -(A7)
		bsr	LS_INIT
		add.l	#8, A7
	
		; Install TRAP #0
		move.l	#TM_TRAP0_DISPATCHER, ($80)
		
		; Install TRAP #1
		move.l	#TM_TRAP1_DISPATCHER, ($84)
		
		; Install TRAP #2
		move.l	#TM_TRAP2_DISPATCHER, ($88)
		
		; Install TRAP #3
		move.l	#TM_TRAP3_DISPATCHER, ($8C)
		
	
		; Switch to user mode
		move.l	(A7)+, A0		; Get return address
		and.w	#%1101111111111111, SR	; Change SR bit
		move.l	A0, -(A7)		; Restore return address
		rts
*-----------------------------------------------------------

*-----------------------------------------------------------
TM_TRAP0_DISPATCHER:	
* Description : Exception Service Routine for TRAP #0. Executes
*               the desired functionality according to D0.B
* Pre         : D0.B: Desired functionality.
*               Other parameters: Depends on functionality. Check
*               assignment specs.
* Post        : Depends on the functionality. Check assignment specs.
* Modified    : Nothing except output.
* Note        : Nice strategy to provide output parameters in registers
*               while keeping the other registers unchanged (restoring
*               them) without having to track them all the time:
*               - Stack all (used) registers initially
*               - Do whatever you must without taking care of used registers
*               - Modify the stack area corresponding to the register you want
*                 to output
*               - Restore registers at the end.
*               In this implementation, all the registers are saved. The list
*               below shows the position with respect to A7 of the stored
*               values of the registers just after the first movem instruction.
*               For example, register D4.L is stored in 16(A7). Accessing to
*               the copy in stack of D4.W means accessing to 18(A7) and 
*               accessing to the copy of D4.B means accessing to 19(A7).
* Note 2      : 60(A7) contains the copy of the status register, as performed by
*               the 68000 after an exception. 62(A7) contains the return address
*               used when the RTE instruction is reached. 62(A7) is especially
*               useful. Modifying it will make the 68000 to jump wherever you
*               want when RTE is reached.             
*
* Registers in stack after movem.l D0-D7/A0-A6, -(A7)	
* D0.L: 0-3
* D1.L: 4-7
* D2.L: 8-11
* D3.L: 12-15
* D4.L: 16-19
* D5.L: 20-23
* D6.L: 24-27
* D7.L: 28-31
* A0.L: 32-35
* A1.L: 36-39
* A2.L: 40-43
* A3.L: 44-47
* A4.L: 48-51
* A5.L: 52-55
* A6.L: 56-59
* SR.W: 60-61
* PC.L: 62-65
*-----------------------------------------------------------
		; Push registers. Output will be provided by modifying the stack
		; so that the output values will be set when restoring registers 
		; from stack.	
		movem.l	D0-D7/A0-A6, -(A7)	
	
		; Branch to the desired functionality according to D0.B value.
		; Note that OR.B D0, D0 does not modify D0 but modifies flags.
		; Also, note that each SUBQ.B #1, D0 decreases D0 and modifies
		; flags according to the result. For example, if initially D0=4,
		; the zero flag will be set only after 4 SUBQs. This approach
		; avoids the use of CMP operations, which are slower than SUBQ.
		or.b	D0, D0
		beq	.F0
		subq.b	#1, D0
		beq	.F1
		subq.b	#1, D0
		beq	.F2	
		bra	.END
	
		; Function 0: Add new task
		; Input:  A0   TEP
		;         D1.W GROUP 
		; Output: D1.W Assigned ID
.F0:		move.l	32(A7), A1	; Move input A0 to A1
		move.w	6(A7), D1	; Move input D1.W to D1.W
		bsr	TM_ADD_NEW_TASK
		move.w	D0, 6(A7)	; Move D0.W to output D1.W
		bra	.END
.F1:		; Function 1: Remove task by ID	
		; Input     : D1.W Task identifier
		move.w	6(A7), D1
		bsr	TM_REMOVE_TASK_BY_ID
		bra	.END
.F2:		; Function 2: Remove tasks by Group
		; Input     : D1.W Task group		
		
		;  ---------------------------------------		
		;  | DONE. CHECK SUBROUTINE FOR COMMENTS |
		;  ---------------------------------------

		BSR TM_REMOVE_TASKS_BY_GROUP
		bra	.END
		
.END:		movem.l	(A7)+, D0-D7/A0-A6
		rte
*-----------------------------------------------------------

*-----------------------------------------------------------
TM_TRAP1_DISPATCHER:	
* Description : Exception Service Routine for TRAP #1. Executes
*               the desired functionality according to D0.B
* Pre         : D0.B: Desired functionality.
*               Other parameters: Depends on functionality. Check
*               assignment specs.
* Post        : Depends on the functionality. Check assignment specs.
* Modified    : Nothing except output.
* Note        : Nice strategy to provide output parameters in registers
*               while keeping the other registers unchanged (restoring
*               them) without having to track them all the time:
*               - Stack all (used) registers initially
*               - Do whatever you must without taking care of used registers
*               - Modify the stack area corresponding to the register you want
*                 to output
*               - Restore registers at the end.
*               In this implementation, all the registers are saved. The list
*               below shows the position with respect to A7 of the stored
*               values of the registers just after the first movem instruction.
*               For example, register D4.L is stored in 16(A7). Accessing to
*               the copy in stack of D4.W means accessing to 18(A7) and 
*               accessing to the copy of D4.B means accessing to 19(A7).
* Note 2      : 60(A7) contains the copy of the status register, as performed by
*               the 68000 after an exception. 62(A7) contains the return address
*               used when the RTE instruction is reached. 62(A7) is especially
*               useful. Modifying it will make the 68000 to jump wherever you
*               want when RTE is reached.             
*
* Registers in stack after movem.l D0-D7/A0-A6, -(A7)	
* D0.L: 0-3
* D1.L: 4-7
* D2.L: 8-11
* D3.L: 12-15
* D4.L: 16-19
* D5.L: 20-23
* D6.L: 24-27
* D7.L: 28-31
* A0.L: 32-35
* A1.L: 36-39
* A2.L: 40-43
* A3.L: 44-47
* A4.L: 48-51
* A5.L: 52-55
* A6.L: 56-59
* SR.W: 60-61
* PC.L: 62-65
*-----------------------------------------------------------
		; Push registers. Output will be provided by modifying the stack
		; so that the output values will be set when restoring registers 
		; from stack.	
		movem.l	D0-D7/A0-A6, -(A7)	
	
		; Branch to the desired functionality according to D0.B value.
		; Note that OR.B D0, D0 does not modify D0 but modifies flags.
		; Also, note that each SUBQ.B #1, D0 decreases D0 and modifies
		; flags according to the result. For example, if initially D0=4,
		; the zero flag will be set only after 4 SUBQs. This approach
		; avoids the use of CMP operations, which are slower than SUBQ.
		or.b	D0, D0
		beq	.F0	
		subq.b	#1, D0
		beq	.F1
		subq.b	#1, D0
		beq	.F2
		subq.b	#1, D0
		beq	.F3
		subq.b	#1, D0
		beq	.F4
		subq.b	#1, D0
		beq	.F5		
		bra	.END
	
.F0:		; Function 0: Start tasks execution
		; Input     : ---		
		; Output    : D1.W Task ID
		;           : D2.W Task Group
		;           : D3.W Status
		;           : A0   TMP
		;           : A1   SMP (Shared Memory Pointer)
		
		; Get the current time and store it
		move.b	#8, D0
		trap	#15
		move.l	D1, (TM_PREVIOUS_TIME)
		
		; Get the first executable TCB pointer
		bsr	TM_GET_FIRST_EXECUTABLE_TCB
		move.l	A0, (TM_CURRENT_TASK)
		cmp.l	#$FFFFFFFF, A0
		beq	.END
		
		; Get the TCB data
		bsr	TM_PREPARE_TASK_EXECUTION
		
		; Prepare the output 
		move.w	D1, 6(A7)	; ID
		move.w	D2, 10(A7)	; GROUP
		move.w	D3, 14(A7)	; Status
		move.l	A1, 32(A7)	; TMP
		move.l	#TM_SHARED_MEMORY, 36(A7) ; SMP
		move.l	A2, 62(A7)	; TEP
		bra	.END
		
.F1:		; Function 1: Go to next task		
		; Input     : ---		
		; Output    : D1.W Task ID
		;           : D2.W Task Group
		;           : D3.W Status
		;           : A0   TMP
		;           : A1   SMP (Shared Memory Pointer)				

		; --------
		; | DONE |
		; --------
		; WE GET THE CURRENT EXECUTING TASK
		MOVE.L (TM_CURRENT_TASK), A0
		; SINCE WE HAVE TO GO TO THE NEXT TASK
		; WE GET THE NEXT EXECUTABLE TASK CONTROL BLOCK
		BSR TM_GET_NEXT_EXECUTABLE_TCB
		; NOW A0 HOLDS THE CURRENT TASK'S TASK HANDLER
		
                ; WE PUT "TO WORK" THE TASK THAT WE'VE FOUND
		MOVE.L A0,(TM_CURRENT_TASK)
		; IF THERE ARE NO TASKS AVAILABLE
                CMP.L #$FFFFFFFF,A0
                ; WE RESTART A NEW TM CYCLE
		BEQ .newPhase
		
		; IF TCB LIST IS NOT OVER,
		; WE MUST PREPARE THE EXECUTION
		; OF THE OBTAINED TCB
		BSR TM_PREPARE_TASK_EXECUTION
		
		; Prepare the output -- COPIED FROM .F0
		MOVE.W	D1, 6(A7)	; ID
		MOVE.W	D2, 10(A7)	; GROUP
		MOVE.W	D3, 14(A7)	; Status
		MOVE.L	A1, 32(A7)	; TMP
		MOVE.L	#TM_SHARED_MEMORY, 36(A7) ; SMP
		MOVE.L	A2, 62(A7)	; TEP
		
		BRA .END ; END
		.newPhase:
		        ; BEFORE STARTING A NEW CYCLE
		        ; WE MUST REMOVE THE TCB'S THAT
		        ; WERE MARKED AS REMOVABLE
		        BSR TM_ERASE_REMOVABLE_TASKS
		        ; IF THE TASK WAS "TOO FAST"
		        ; WE GOTTA GET IT DELAYED.
		        ; THAT ALLOWS US TO HAVE A 
		        ; "CONSTANT" FRAME RATE
		        BSR TM_DELAY_FASTER_TASKS
		        ; FINALLY, WE START A NEW TASK MANAGER
		        ; CYCLE BY REUSING THIS FUNCTION
		        BRA .F0
		bra	.END		

.F2:            ; Function 2: Continue only if time-over=00 OR allow-time-over==FF
		; --------		
		; | DONE |
		; --------
		; CHECKING IF THE FLAG IS ON
		CMP.B #0,(TM_TIME_OVER)
		; IF NOT, MOVE ON
		BEQ .END
		; IF IT IS ON, WE MUST CHECK 
		; THE ALLOWING TIME OVER FLAG
		CMP.B #$FF,(TM_ALLOW_TIME_OVER)
		; IF IT IS ALLOWED, MOVE ON
		BEQ .END
		; IF NOT, LETS JUMP ON THE NEXT TASK
		BRA .F1
		bra	.END		
                
.F3:		; Function 3: Sleep task
		; Input     : A2  Task handler
		; Output    : ---
		; Note      : Task handler must be valid
		move.l	40(A7), A0
		move.w	#TM_TCB_STATUS_SLEEP, TM_TCB_STATUS_W(A0)
		bra	.END
		
.F4:		; Function 4: Wake up task
		; Input     : A2  Task handler
		; Output    : ---
		; Note      : Task handler must be valid
		; ------------------------------
		; | DONE. NOTHING MUCH TO TELL |
		; ------------------------------
		MOVE.L 40(A7),A0
		MOVE.W #TM_TCB_STATUS_RUN, TM_TCB_STATUS_W(A0)
		bra	.END
		
.F5:		; Function 5: Re-init task		
		; Input     : A2  Task handler
		; Output    : ---
		; Note      : Task handler must be valid
		; ------------------------------
		; | DONE. NOTHING MUCH TO TELL |
		; ------------------------------
                MOVE.L 40(A7),A0
		MOVE.W #TM_TCB_STATUS_INIT, TM_TCB_STATUS_W(A0)	
		bra	.END
                
                                
.END:		movem.l	(A7)+, D0-D7/A0-A6
		rte
*-----------------------------------------------------------

*-----------------------------------------------------------
TM_TRAP2_DISPATCHER:	
* Description : Exception Service Routine for TRAP #2. Executes
*               the desired functionality according to D0.B
* Pre         : D0.B: Desired functionality.
*               Other parameters: Depends on functionality. Check
*               assignment specs.
* Post        : Depends on the functionality. Check assignment specs.
* Modified    : Nothing except output.
* Note        : Nice strategy to provide output parameters in registers
*               while keeping the other registers unchanged (restoring
*               them) without having to track them all the time:
*               - Stack all (used) registers initially
*               - Do whatever you must without taking care of used registers
*               - Modify the stack area corresponding to the register you want
*                 to output
*               - Restore registers at the end.
*               In this implementation, all the registers are saved. The list
*               below shows the position with respect to A7 of the stored
*               values of the registers just after the first movem instruction.
*               For example, register D4.L is stored in 16(A7). Accessing to
*               the copy in stack of D4.W means accessing to 18(A7) and 
*               accessing to the copy of D4.B means accessing to 19(A7).
* Note 2      : 60(A7) contains the copy of the status register, as performed by
*               the 68000 after an exception. 62(A7) contains the return address
*               used when the RTE instruction is reached. 62(A7) is especially
*               useful. Modifying it will make the 68000 to jump wherever you
*               want when RTE is reached.             
*
* Registers in stack after movem.l D0-D7/A0-A6, -(A7)	
* D0.L: 0-3
* D1.L: 4-7
* D2.L: 8-11
* D3.L: 12-15
* D4.L: 16-19
* D5.L: 20-23
* D6.L: 24-27
* D7.L: 28-31
* A0.L: 32-35
* A1.L: 36-39
* A2.L: 40-43
* A3.L: 44-47
* A4.L: 48-51
* A5.L: 52-55
* A6.L: 56-59
* SR.W: 60-61
* PC.L: 62-65
*-----------------------------------------------------------
		; Push registers. Output will be provided by modifying the stack
		; so that the output values will be set when restoring registers 
		; from stack.	
		movem.l	D0-D7/A0-A6, -(A7)	
	
		; Branch to the desired functionality according to D0.B value.
		; Note that OR.B D0, D0 does not modify D0 but modifies flags.
		; Also, note that each SUBQ.B #1, D0 decreases D0 and modifies
		; flags according to the result. For example, if initially D0=4,
		; the zero flag will be set only after 4 SUBQs. This approach
		; avoids the use of CMP operations, which are slower than SUBQ.
		or.b	D0, D0
		beq	.F0
		subq.b	#1, D0
		beq	.F1		
		subq.b	#1, D0
		beq	.F2				
		bra	.END
	
.F0:		; Function 0: Get current task info
		; Input     : ---		
		; Output    : D1.W Task ID
		;           : D2.W Task Group
		;           : D3.W Status
		;           : A0   TMP
		;           : A1   SMP (Shared Memory Pointer)	
		;	    : A2   Handler			
		move.l	(TM_CURRENT_TASK), A0
.OUTINFO:	move.l	A0, 40(A7)
		cmp.l	#$FFFFFFFF, A0
		beq	.END
		move.w	TM_TCB_ID_W(A0), 6(A7)
		move.w	TM_TCB_GROUP_W(A0), 10(A7)
		move.l	TM_TCB_TMP_L(A0), 32(A7)
		move.l	#TM_SHARED_MEMORY, 36(A7)
		move.w	TM_TCB_STATUS_W(A0), 14(A7)
		bra	.END		

.F1:		; Function 1: Get first task info
		; Input     : ---
		; Output    : D1.W Task ID
		;           : D2.W Task Group
		;           : D3.W Status
		;           : A0   TMP
		;           : A1   SMP (Shared Memory Pointer)
		;           : A2   Task handler or #$FFFFFFFF if no tasks
		
		; -------------------------------
		; | NOTHING MUCH TO TELL EITHER |
		; -------------------------------
		BSR TM_GET_FIRST_TCB
		BRA .OUTINFO
		bra     .END
		
		
.F2:		; Function 2: Get next task info
		; Input     : A2   Current task handler
		; Output    : D1.W Task ID
		;           : D2.W Task Group
		;           : D3.W Status
		;           : A0   TMP
		;           : A1   SMP (Shared Memory Pointer)
		;           : A2   Task handler or #$FFFFFFFF if no tasks		
		; Note      : A valid task handler is expected as input
		move.l	40(A7), A0
		bsr	TM_GET_NEXT_TCB
		bra	.OUTINFO
		                

.END:		movem.l	(A7)+, D0-D7/A0-A6
		rte
*-----------------------------------------------------------

*-----------------------------------------------------------
TM_TRAP3_DISPATCHER:	
* Description : Exception Service Routine for TRAP #3. Executes
*               the desired functionality according to D0.B
* Pre         : D0.B: Desired functionality.
*               Other parameters: Depends on functionality. Check
*               assignment specs.
* Post        : Depends on the functionality. Check assignment specs.
* Modified    : Nothing except output.
* Note        : Nice strategy to provide output parameters in registers
*               while keeping the other registers unchanged (restoring
*               them) without having to track them all the time:
*               - Stack all (used) registers initially
*               - Do whatever you must without taking care of used registers
*               - Modify the stack area corresponding to the register you want
*                 to output
*               - Restore registers at the end.
*               In this implementation, all the registers are saved. The list
*               below shows the position with respect to A7 of the stored
*               values of the registers just after the first movem instruction.
*               For example, register D4.L is stored in 16(A7). Accessing to
*               the copy in stack of D4.W means accessing to 18(A7) and 
*               accessing to the copy of D4.B means accessing to 19(A7).
* Note 2      : 60(A7) contains the copy of the status register, as performed by
*               the 68000 after an exception. 62(A7) contains the return address
*               used when the RTE instruction is reached. 62(A7) is especially
*               useful. Modifying it will make the 68000 to jump wherever you
*               want when RTE is reached.             
*
* Registers in stack after movem.l D0-D7/A0-A6, -(A7)	
* D0.L: 0-3
* D1.L: 4-7
* D2.L: 8-11
* D3.L: 12-15
* D4.L: 16-19
* D5.L: 20-23
* D6.L: 24-27
* D7.L: 28-31
* A0.L: 32-35
* A1.L: 36-39
* A2.L: 40-43
* A3.L: 44-47
* A4.L: 48-51
* A5.L: 52-55
* A6.L: 56-59
* SR.W: 60-61
* PC.L: 62-65
*-----------------------------------------------------------
		; Push registers. Output will be provided by modifying the stack
		; so that the output values will be set when restoring registers 
		; from stack.	
		movem.l	D0-D7/A0-A6, -(A7)	
	
		; Branch to the desired functionality according to D0.B value.
		; Note that OR.B D0, D0 does not modify D0 but modifies flags.
		; Also, note that each SUBQ.B #1, D0 decreases D0 and modifies
		; flags according to the result. For example, if initially D0=4,
		; the zero flag will be set only after 4 SUBQs. This approach
		; avoids the use of CMP operations, which are slower than SUBQ.
		or.b	D0, D0
		beq	.F0		
		subq.b	#1, D0
		beq	.F1				
		subq.b	#1, D0
		beq	.F2				
		bra	.END		
		
.F0:		; Function 3: Define min cycle time
		; Input      : D1.L Min cycle time, hundreths of second
		; Output     : ---
		move.l	4(A7), (TM_MIN_CYCLE_TIME)		
		bra	.END
		                
.F1:           ; Function 4: Allow time-over
                move.b  #$FF, (TM_ALLOW_TIME_OVER)
                bra     .END

.F2:           ; Function 5: Detect time-overs
                clr.b   (TM_ALLOW_TIME_OVER)
                bra     .END
                

.END:		movem.l	(A7)+, D0-D7/A0-A6
		rte
*-----------------------------------------------------------


*-----------------------------------------------------------
TM_GET_FIRST_TCB:
* Description : Puts into A0 the TCB address of the first task
* Pre         : ---
* Post        : A0 contains the first task's
*               TCB of #$FFFFFFFF if no tasks available.
* Modifies    : Nothing, except the output.
*-----------------------------------------------------------
		move.l	#TM_TCB_LIST, -(A7)
		bsr	LS_FIRST
		move.l	(A7)+, A0
		cmp.l	#$FFFFFFFF, A0
		beq	.END
		add.l	#4, A0
.END:		rts
*-----------------------------------------------------------

*-----------------------------------------------------------
TM_GET_NEXT_TCB:
* Description : Puts into A0 the TCB address of the one
*               following A0
* Pre         : ---
* Post        : A0 contains the next
*               TCB of #$FFFFFFFF if no more tasks available.
* Modifies    : Nothing, except the output.
*-----------------------------------------------------------
		sub.l	#4, A0
		move.l	A0, -(A7)
		move.l	#TM_TCB_LIST, -(A7)
		bsr	LS_NEXT
		add.l	#4, A7
		move.l	(A7)+, A0
		cmp.l	#$FFFFFFFF, A0
		beq	.END
		add.l	#4, A0
.END:		rts
*-----------------------------------------------------------

*-----------------------------------------------------------
TM_GET_FIRST_EXECUTABLE_TCB:
* Description : Puts into A0 the TCB address of the first 
*               executable task (initializable or runnable)
* Pre         : ---
* Post        : A0 contains the first executable task's
*               TCB of #$FFFFFFFF if none available.
* Modifies    : Nothing, except the output.
*-----------------------------------------------------------
		; Get the first TCB
		bsr	TM_GET_FIRST_TCB
		; If none, exit
.LOOP:		cmp.l	#$FFFFFFFF, A0
		beq	.END
		; If the TCB is initializable, it is executable
		cmp.w	#TM_TCB_STATUS_INIT, TM_TCB_STATUS_W(A0)
		beq	.END
		; If the TCB is runnable, it is executable
		cmp.w	#TM_TCB_STATUS_RUN, TM_TCB_STATUS_W(A0)
		beq	.END
		; Go to the next TCB
		bsr	TM_GET_NEXT_TCB
		bra	.LOOP
.END:		rts	
*-----------------------------------------------------------		

*-----------------------------------------------------------
TM_GET_NEXT_EXECUTABLE_TCB:
* Description : Puts into A0 the TCB address of the first 
*               executable task (initializable or runnable)
*               following the one pointed by A0
* Pre         : A0 current task
* Post        : A0 contains the first executable task's
*               TCB following A0 or #$FFFFFFFF if none available.
* Modifies    : Nothing, except the output.
*-----------------------------------------------------------
.LOOP:		bsr	TM_GET_NEXT_TCB
		; If none, exit
		cmp.l	#$FFFFFFFF, A0
		beq	.END
		; If the TCB is initializable, it is executable
		cmp.w	#TM_TCB_STATUS_INIT, TM_TCB_STATUS_W(A0)
		beq	.END
		; If the TCB is runnable, it is executable
		cmp.w	#TM_TCB_STATUS_RUN, TM_TCB_STATUS_W(A0)
		beq	.END
		bra	.LOOP		
.END:		rts	
*-----------------------------------------------------------		
			
*-----------------------------------------------------------
TM_ADD_NEW_TASK:
* Description : Adds a new task by:
*               1.- Getting a new ID
*               2.- Getting task memory
*               3.- Preparing the TCB
*               4.- Putting the TCB into the TCB list
*               The task status is set to Initializing
* Pre         : A1   : TEP
*               D1.W : Group
* Post        : D0.W: Assigned ID or $FFFF if no place for more tasks
* Modifies    : A0
* Note        : The task manager must have been installed prior to
*               this function call.
*-----------------------------------------------------------
		; First, get an identifier to assign to the new task
		bsr	IDP_GET_ID
		cmp.w	#$FFFF, D0
		beq	.END		; If no ID, just exit
		
		; Next, get the task memory
		bsr	DMM_ALLOCATE
		cmp.l	#$FFFFFFFF, A0
		beq	.END2		; If no memory, release ID and exit
						
		; Put the TCB data into te stack. They are placed in the reverse order
		; so that the TCB is stored in the order specified in the TCB description.
		move.l	A0, -(A7)			; TMP
		move.l	A1, -(A7)			; TEP
		move.w	#TM_TCB_STATUS_INIT, -(A7)	; STATUS=Initializing
		move.w	D1, -(A7)			; GROUP
		move.w	D0, -(A7)			; ID
		
		; Put the list pointer into the stack
		move.l	#TM_TCB_LIST, -(A7)
		
		; Insert the new TCB
		bsr 	LS_PUT
		
		; Restore stack
		add.l	#18, A7
		
		; Exit
.END:		rts	
		
		; At this point, the ID has been reserved, but no memory available. So, prior to
		; exit, release the ID. Note that this point should never be reached.
.END2:		bsr	IDP_RELEASE_ID
		move.w	#$FFFF, D0
		rts
*-----------------------------------------------------------

*-----------------------------------------------------------
TM_REMOVE_TASK_BY_ID:
* Description : Changes the status of the task specified by 
*               its ID to Removable. If the ID is not found,
*               nothing is done.
* Pre         : D1.W : The ID to remove.
* Post        : Task status changed to Removable.
* Modifies    : A0
* Note        : The task manager must have been installed prior to
*               this function call.
*-----------------------------------------------------------
		; Get the first TCB
		bsr	TM_GET_FIRST_TCB
		; If not available, do nothing
.LOOP:		cmp.l	#$FFFFFFFF, A0
		beq	.NOTFOUND
		; If this TCB is the one we are looking for, 
		; mark as removable
		cmp.w	TM_TCB_ID_W(A0), D1
		beq	.REMOVE_THIS
		; If not, loop for the remaining TCBs
		bsr	TM_GET_NEXT_TCB
		bra	.LOOP
		; Once marked as removable, exit. IDs are unique.
.REMOVE_THIS:	move.w	#TM_TCB_STATUS_REMOVE, TM_TCB_STATUS_W(A0)		
.NOTFOUND:	rts		
*-----------------------------------------------------------

*-----------------------------------------------------------
TM_PREPARE_TASK_EXECUTION:
* Description : Outputs the values needed for the TM to execute
*               the task specified by the TCB pointed by 
*		(TM_CURRENT_TASK).
* Pre         : (TM_CURRENT_TASK): Pointer to the TCB of the task to execute
* Post        : D1.W: ID
*               D2.W: Group
*               D3.W: Status
*               A1  : TMP
*               A2  : TEP
* Modifies    : A0 and the output parameters
* Note        : The task manager must have been installed prior to
*               this function call.
*-----------------------------------------------------------
		; Get the current TCB pointer
		move.l	(TM_CURRENT_TASK), A0		
		; Output the task ID
		move.w	TM_TCB_ID_W(A0), D1
		; Output the task Group
		move.w	TM_TCB_GROUP_W(A0), D2
		; Output the task memory pointer
		move.l	TM_TCB_TMP_L(A0), A1
		; Output the task entry point
		move.l	TM_TCB_TEP_L(A0), A2
		; Output the status
		move.w	TM_TCB_STATUS_W(A0), D3
		; Also, if status is init, switch to running
		cmp.w	#TM_TCB_STATUS_INIT, D3
		bne	.END
		move.w	#TM_TCB_STATUS_RUN, TM_TCB_STATUS_W(A0)
.END:		rts
*-----------------------------------------------------------
	
	
	
	
************************************************************
*                      MY SUBROUTINES                      *
************************************************************

*-----------------------------------------------------------
TM_REMOVE_TASKS_BY_GROUP:
* Description : Removes all tasks with the same group identifier.
* Pre         : D1.W = TASK'S GROUP
* Post        : Tasks which group is as D1.W are marked as removables.
* Modifies    : Nothing
* Note        : The task manager must have been installed prior to
*               this function call.
*-----------------------------------------------------------
		MOVEM.L A0/D1,-(A7)
		
		BSR TM_GET_FIRST_TCB    ; 1º TCB IS ON A0.L
		
		.itsOVER:
                        CMP.L #$FFFFFFFF,A0  ; COMPARING IF THE LIST IS OVER
		        BEQ .finish          ; IT IS EMPTY WE END
		.compare:
		        CMP.W TM_TCB_GROUP_W(A0),D1     ; IF NOT EMPTY, WE CHECK
		                                        ; IF BELONGS TO THE
		                                        ; GROUP THAT IS ON D1.W
		        BEQ .remove                     ; IF IT BELONGS, WE MARK IT
		                                        ; AS REMOVABLE
		                                        
		        BRA .follow   ; ELSE WE GET THE FOLLOWING ONE
		.remove:
		        MOVE.W #TM_TCB_STATUS_REMOVE, TM_TCB_STATUS_W(A0)
		.follow:
		        BSR TM_GET_NEXT_TCB             ; PRETTY SELF-EXPLANATORY
		        BRA .itsOVER                    ; ISN'T IT?
		.finish:
		
		MOVEM.L (A7)+,A0/D1
		RTS
*-----------------------------------------------------------


*-----------------------------------------------------------
TM_ERASE_REMOVABLE_TASKS:
* Description : Analyzes all the list and removes all the tasks which
*               status is set as REMOVABLE.
* Pre         : None
* Post        : Removable tasks are removed.
* Modifies    : Nothing
* Note        : The task manager must have been installed prior to
*               this function call.
*-----------------------------------------------------------
		
		MOVEM.L A0-A2/D0,-(A7)

		BSR TM_GET_FIRST_TCB    ; 1º TCB IS ON A0.L
		
		.itsOVER:
                        CMP.L #$FFFFFFFF,A0
		        BEQ .finish
		.compare:
		        CMP.W #TM_TCB_STATUS_REMOVE, TM_TCB_STATUS_W(A0)
		        BEQ .remove
		        BRA .follow     ; goes to the following one
		.remove:
		        ; RELEASING THE DMM BLOCK
		        MOVE.L A0,A2
		        MOVE.L TM_TCB_TMP_L(A0),A1
		        MOVE.L A1,A0
		        BSR DMM_RELEASE

		        MOVE.L A2,A0
		        ; RELEASING THE ID
		        MOVE.W TM_TCB_ID_W(A0),D0
		        BSR IDP_RELEASE_ID
		        
		        
		        SUBQ.L #4,A0
		        ; WE'LL NEED THIS FOR 
		        ; PROCEEDING TO REMOVE
		        ; ALL FOLLOWING REMOVABLE
		        ; TASKS
		        MOVE.L (A0),A1
		        MOVE.L A0,-(A7)
		        MOVE.L #TM_TCB_LIST,-(A7)
		        BSR LS_REMOVE
		        ADD.L #8,A7
		        
		        
                        MOVE.L A1,A0
                        ADDQ.L #4,A0
		.follow:
		        BSR TM_GET_NEXT_TCB
		        BRA .itsOVER
		.finish:
		
		MOVEM.L (A7)+,A0-A2/D0
		
		RTS
*-----------------------------------------------------------

*-----------------------------------------------------------
TM_DELAY_FASTER_TASKS:
* Description : Delays tasks which finished faster than (TM_MIN_CYCLE_TIME)
*               and sets the flag TM_TIME_OVER if theses tasks are too slow.
* Pre         : None
* Post        : Activates flag TM_TIME_OVER if necessary.
*               Delays tasks if necessary.
* Modifies    : Nothing
* Note        : The task manager must have been installed prior to
*               this function call.
*-----------------------------------------------------------
		MOVEM.L D0-D2,-(A7)
		
		MOVE.W #8,D0
		TRAP #15        ; WE GET THE TIME IN D1
		
		SUB.L (TM_PREVIOUS_TIME),D1 ; WITH THIS WE GET
		                            ; THE TIME THAT BEEN 
		                            ; TAKEN TO REACH THIS POINT
		
		MOVE.L (TM_MIN_CYCLE_TIME),D2
		SUB.L D1,D2     ; COMPARING WITH THE MIN CYCLE TIME
		BPL .delay
		BEQ .delay
		MOVE.B #$FF,(TM_TIME_OVER) ; IF THE TIME TAKEN WAS TOO BIG
		BRA .finish                ; WE TURN ON THE TIME OVER FLAG
		.delay:
		       MOVE.B #0,(TM_TIME_OVER) ; DELAY
		       MOVE.L D2,D1
                       MOVE.W #23,D0
                       TRAP #15 
		.finish:
		
		MOVEM.L (A7)+,D0-D2
		RTS
*-----------------------------------------------------------


************************************************************

************************************************************
*                         VARIABLES                        *
************************************************************
TM_SHARED_MEMORY:	ds.w	TM_SHARED_MEMORY_SIZE	 	; Shared memory
TM_TCB_LIST:		ds.w	1+2+2+TM_MAX_TASKS*(TM_TCB_SIZE+2) 	; TCB List
TM_CURRENT_TASK:	ds.l	1				; Pointer to the current TCB
TM_MIN_CYCLE_TIME:	ds.l	1				; Minimum cycle time (units: 1/100 of second)
TM_PREVIOUS_TIME:	ds.l	1				; Last time stamp used to measure cycle time
TM_TIME_OVER:           ds.b    1                               ; Time-over flag
TM_ALLOW_TIME_OVER:     ds.b    1                               ; Time-over allowed flag
                        ds.w    1
************************************************************































*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~8~
