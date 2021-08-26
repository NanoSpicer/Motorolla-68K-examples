************************************************************
*                  DINAMIC MEMORY MANAGER                  *
*==========================================================*
* User subroutines providing the following functionalities:*
* 1.- DMM_INIT    : Inits the Dinamic Memory Manager.
* 2.- DMM_ALLOCATE: Reserves a chunk of memory and outputs
*                   a pointer to it.
* 3.- DMM_RELEASE : Releases a chunk of memory
*                   and makes it useable in future calls of
*                   DMM_ALLOCATE
* Notes:
*  + The list library MUST be available (previously included).
*  + The constants TM_MAX_TASKS (maximum number of tasks) and
*    TM_TASK_MEMORY_SIZE (memory assigned to each task size in bytes)
*    must be available.
*  + A "chunk" of memory is a set of TM_TASK_MEMORY_SIZE words.
*  + This library depends on external constants and, as it has 
*    global variables is NOT stateless. 
************************************************************

*-----------------------------------------------------------
DMM_INIT:
* Description : Inits the Dynamic Memory Manager by initializing
*               the underlying memory list (DMM_MEMLIST).
* Pre         : Nothing.
* Post        : DMM initialized. 
* Modified    : Nothing: all registers are restored.
* Note        : When calling this subroutine, the required constants
*               TM_TASK_MEMORY_SIZE, TM_MAX_TASKS and DMM_MEMLIST 
*		are assumed to have the correct values.
*-----------------------------------------------------------
		move.w	#TM_TASK_MEMORY_SIZE, -(A7)
		move.w	#TM_MAX_TASKS, -(A7)
		move.l	#DMM_MEMLIST, -(A7)
		bsr	LS_INIT
		add.l	#8, A7
		rts
*-----------------------------------------------------------
		
*-----------------------------------------------------------
DMM_ALLOCATE:
* Description : Outputs a pointer to the first available memory chunk.
* Pre         : Nothing.
* Post        : A0: Pointer to the chunk or $FFFFFFFF if no memory available
* Modifies    : Nothing, except A0 which is the output.
* Note        : When calling this subroutine, the required constants
*               are assumed to have the correct values.
* Note        : The output pointer points to the data itself. That is,
*               it points to the NEXT field in the underlying list +4.
*-----------------------------------------------------------
		; We have no data to put in the block. So, we just move
		; the stack pointer to simulate the data input parameter
		sub.l	#TM_TASK_MEMORY_SIZE*2, A7
		; Now put the list parameter
		move.l	#DMM_MEMLIST, -(A7)
		; Put the item in the list
		bsr	LS_PUT
		; Get the item pointer
		move.l	(A7)+, A0
		; Restore stack
		add.l	#TM_TASK_MEMORY_SIZE*2, A7
		; If #$FFFFFFFF, output this value
		cmp.l	#$FFFFFFFF, A0
		beq	.END
		; Otherwise, add 4 to point to the data block
		add.l	#4, A0
.END		rts		
*-----------------------------------------------------------

*-----------------------------------------------------------
DMM_RELEASE:
* Description : Releases the specified memory chunk.
* Pre         : A0: Pointer to the memory chunk to release. Note that
*                   A0 points to the data, not to the NEXT field
* Post        : Memory chunk released.
* Modifies    : Nothing
* Note        : When calling this subroutine, the required constants
*               are assumed to have the correct values.
*-----------------------------------------------------------

                MOVE.L A0,-(A7)
                
                SUBQ.L #4,A0
                MOVE.L A0,-(A7)
                MOVE.L #DMM_MEMLIST,-(A7)
                BSR LS_REMOVE
                ADD.L #8,A7
                
                MOVE.L (A7)+,A0
		rts
*-----------------------------------------------------------
			
************************************************************
*                         VARIABLES                        *
************************************************************
; The Dinamic Memory Manager manages a list of TM_MAX_TASKS items.
; Each item holds TM_TASK_MEMORY_SIZE words of data. Thus, each item
; stores one memory chunk and there is the same number of memory 
; chunks and tasks.
DMM_MEMLIST:		ds.w	1+2+2+TM_MAX_TASKS*(2+TM_TASK_MEMORY_SIZE)
************************************************************









*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~8~
