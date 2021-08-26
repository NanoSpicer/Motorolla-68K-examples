************************************************************
*                           ID POOL                        *
*==========================================================*
* User subroutines providing the following functionalities:*
* 1.- IDP_INIT  : Inits the ID Pool by putting consecutive IDs.
* 2.- IDP_GET_ID: Outputs the first available ID and removes it
*                 from the ID list
* 3.- IDP_RELEASE_ID: Puts the specified ID into the list of
*                     available IDs.
* Note:
*  + The list library MUST be available (previously included).
*  + The constant TM_MAX_TASKS (maximum number of tasks) must
*    be defined.
************************************************************

*-----------------------------------------------------------
IDP_INIT:
* Description : Inits the ID Pool by doing:
*               1.- Preparing IDP_IDLIST using LS_INIT
*               2.- Putting consecutive numbers as initially available IDs
* Pre         : Nothing.
* Post        : ID Pool initialized. 
* Modified    : Nothing: all registers are restored.
* Note        : When calling this subroutine, the required constants
*               are assumed to have the correct values.
*-----------------------------------------------------------
		move.w	D0, -(A7)
		; Init the list
		move.w	#1, -(A7)
		move.w	#TM_MAX_TASKS, -(A7)
		move.l	#IDP_LIST, -(A7)
		bsr	LS_INIT
		add.l	#8, A7
		; Prepare loop counter		
		move.w	#TM_MAX_TASKS-1, D0
		; Prepare initial parameters
		move.w	#0, -(A7)
		move.l	#IDP_LIST, -(A7)
.LOOP:		bsr	LS_PUT
		; Next value
		move.l	#IDP_LIST, (A7)
		; Restore list pointer
		add.w	#1, 4(A7)
		dbra	D0, .LOOP
		; Restore stack
		add.l	#6, A7
		move.w	(A7)+, D0
		rts
*-----------------------------------------------------------
		
*-----------------------------------------------------------	
IDP_GET_ID:
* Description : Provides an available ID. Selects the first item
*               from the list of available IDs.
* Pre         : Nothing.
* Post        : D0.W: The ID or $FFFF if no ID available
* Modified    : Nothing: all registers are restored.
* Note        : When calling this subroutine, the required constants
*               are assumed to have the correct values.
*-----------------------------------------------------------
                MOVE.L A0,-(A7)
                
                MOVE.L #0,-(A7)
                MOVE.L #IDP_LIST,-(A7)
                BSR LS_GET_ITEM
                ADDQ.L #4,A7
                MOVE.L (A7)+,A0
                
                MOVE.W 4(A0),D0
                
                MOVE.L A0,-(A7)
                MOVE.L #IDP_LIST,-(A7)
                BSR LS_REMOVE
                ADD.L #8,A7
                
                
                MOVE.L (A7)+,A0
		rts	
*-----------------------------------------------------------
		
*-----------------------------------------------------------
IDP_RELEASE_ID:
* Description : Returns the specified ID to the list of available
*               IDs so that they will be available in future calls to
*               IDP_GET_ID
* Pre         : D0.W: ID to release
* Post        : ID released
* Modified    : Nothing: all registers are restored.
* Note        : When calling this subroutine, the required constants
*               are assumed to have the correct values.
*-----------------------------------------------------------

                MOVE.W D0,-(A7)
                MOVE.L #IDP_LIST,-(A7)
                BSR LS_PUT
                ADD.L #6,A7
                
		rts
*-----------------------------------------------------------
			
************************************************************
*                         VARIABLES                        *
************************************************************
IDP_LIST:		ds.w	1+2+2+TM_MAX_TASKS*(2+1)	; ID List
************************************************************







*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~8~
