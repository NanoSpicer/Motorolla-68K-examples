*-----------------------------------------------------------
* Program    : List library.
* Written by : A. Burguera
* Creation   : 17-October-2014
* Last update: 14-October-2015 
* Description: This library provides some basic functions to
*              create, read, access and modify a linked list.
*              Below these comments, the list format is
*              described.
* Important  : You can (and have to) code the functions which
*              are not coded. However, you MUST NOT, UNDER
*              ANY CIRCUMSTANCE, modify the existing code.
*              The functions which are already implemented
*              MUST NOT be modified. 
*-----------------------------------------------------------

************************************************************
*                 LIST FORMAT DESCRIPTION                  *
*==========================================================*
*                                                          *
* A list is composed of:                                   *
* - Header                                                 *
*   + (0-1) N -> 1 WORD : Item size expressed in Words     *
*   + (2-5) OCCUPIED -> 1 LONG : Pointer to the first      *
*                         occupied data block              *
*   + (6-9) FREE -> 1 LONG : Pointer to the first empty    *
*                      data block                          *
* - The DATA BLOCKS, each one composed of:                 *
*   + NEXT -> 1 LONG : Pointer to the (logical) next data  *
*                      block or NULL if none.              *
*   + DATA -> N WORDs : The data.                          *
*                                                          *
* Note: The total number of data blocks is defined when    *
*       the list is created, but not stored anywhere.      *
*       To detect if the last data block is reached, a     *
*       NULL check has to be performed over the NEXT field *
*                                                          *
* Note: NULL means long 0                                  *
*                                                          *
************************************************************

*-----------------------------------------------------------
LS_INIT:
* Description : Inits a list as follows:                   
*               1.- Inits N to the specified value         
*               2.- Inits OCCUPIED to NULL
*               3.- Inits FREE to a pointer to the first data block
*               4.- Inits the NEXT field in all the data blocks to
*                   point to the "physically" next block, except
*                   for the last one which is initialized to NULL.
* Pre         : Stack. Specified stack offsets correspond to
*               the stack state at the beginning of the sub-
*               routine.
*               Stack offsets from 0 to 3 contain the return 
*               address.
*		  - Offset 4: LONG: Pointer to the RAM area to 
*                   store the list.
*                 - Offset 8: WORD: List size. That is, the number of
*                   data blocks (M).
*                 - Offset 10: WORD: Data size expressed in 
*                   WORDs (N)
* Post        : All registers are restored to their initial 
*               values.
* Note        : The number of data blocks (M) is passed as parameter
*               to allow this routine to init all the data blocks,
*               but it is not stored anywhere
* Note        : When calling this subroutine, the first
*               parameter (the pointer) must point to a RAM 
*               area with enough space to store the list. 
*-----------------------------------------------------------
		; PUSH registers that are going to be modified: A0, A1, D0.W, D1.L
		; Note that we are pushing D0.L instead of D0.W. From the stack
		; point of view, it would be better to push D0.W. However, this would
		; require the use of a second PUSH instruction. In this case, we
		; decided that pushing a LONG to avoid a second push is better for
		; performance.
		movem.l	D0-D1/A0-A1, -(A7)
		; Pushing 4 LONG means pushing 16 bytes. Thus, 16 has to be added in
		; subsequent stack accesses.

		; Access to the stack parameters		
		clr.l D1		; Clears all the bits in D1. Required as it 
					; is going to be added to an address		
		move.l 20(A7), A0	; The list pointer
		move.w 24(A7), D0	; The list size (M)
		move.w 26(A7), D1	; The data size (N)
		
		; 1.- Init N to the specified value
		move.w	D1, (A0)
		
		; 2.- Init OCCUPIED to NULL
		move.l #0, 2(A0)
		
		; 3.- Init FREE to a pointer to the first data block
		move.l	A0, A1
		add.l	#10, A1		; Compute the first data block address
		move.l	A1, 6(A0)	; Move the computed value to FREE 

		; 4.- Inits the NEXT field in all the data blocks to point to the "physically" 
		; next block, except for the last one which is initialized to NULL.
				
		move.l	A1, A0		; Now A0 points to the first data block
		asl.l	#1, D1		; Now D1 holds the data size in bytes
		addq.l	#4, D1		; Now D1 holds the whole data block size (data size+4)
		subq.w	#2, D0		; Prepare D0 for the following DBRA
		
.LOOP:		
		add.l	D1, A1		; Now A1 points to the "physical" next item		
		move.l	A1, (A0)	; Pointer to the next item
		move.l	A1, A0		; Let A0 be the next item
		dbra	D0, .LOOP
		
		move.l	#0, (A0)	; Put the null pointer on the last item.
		
		; Restore the registers
		movem.l	(A7)+, D0-D1/A0-A1
		rts
*-----------------------------------------------------------
		

*-----------------------------------------------------------
LS_PUT:
* Description : Puts the specified item in the first free 
*               position, if any, as follows:
*		FIRSTBLOCK <- FREE
*		FREE <- (FIRSTBLOCK).NEXT
*		(FIRSTBLOCK).NEXT <- OCCUPIED
*		OCCUPIED <- FIRSTBLOCK
* Pre         : Stack. Specified stack offsets correspond to
*               the stack state at the beginning of the sub-
*               routine.
*               Stack offsets from 0 to 3 contain the return 
*               address.
*		  - Offset 4: LONG: List pointer
*                 - Offset 8: N Words: Data to put in the list
* Post        : All registers are restored to their initial 
*               values.
*               Stack. The stack offsets specified now are
*               based on the same reference that the input ones.
*                 - Offset 4: LONG: Item pointer or $FFFFFFFF
*                   if item could not be included in the list.
*                   The pointer points to the data block. That
*                   is, to the NEXT field of the data block.
* Note        : When calling this subroutine, the list is supposed
*               to be properly initialized.  
*-----------------------------------------------------------
		; PUSH the registers that are going to be modified: A0, A1, A2, D0.L
		; 4 LONG = 16 BYTE. Thus, add 16 to subsequent stack accesses
		movem.l	A0-A2/D0, -(A7)
		
		; Access the stack parameters
		move.l	20(A7), A0	; List pointer
		move.l	A7, A1
		add.l	#24, A1		; Pointer to the data
		
		; FIRSTBLOCK <- FREE
		move.l	6(A0), D0
		or.l	D0,D0
		beq	.LIST_FULL	; If the FREE pointer is NULL, full list
		move.l	D0, A2		; A2: First free data block (FIRSTBLOCK)
		
		; FREE <- (FIRSTBLOCK).NEXT
		move.l	(A2), 6(A0)	; FREE points to the NEXT field
		
		; (FIRSTBLOCK).NEXT <- OCCUPIED
		move.l	2(A0), (A2)
		
		; OCCUPIED <- FIRSTBLOCK
		move.l	A2, 2(A0)
		
		; Prepare the output parameter
		move.l	A2, 20(A7)
		
		; Copy the data
		add.l	#4, A2		; Point to the data itself
		move.w	(A0), D0	; Item size
		subq.w	#1, D0		; Prepare for DBRA						
.LOOP:		move.w	(A1)+, (A2)+
		dbra	D0, .LOOP
		bra	.END
		
		; If the list is full, return $FFFFFFFF
.LIST_FULL:	move.l	#$FFFFFFFF, 20(A7)

		; POP registers
.END:		movem.l	(A7)+, A0-A2/D0
		rts		
*-----------------------------------------------------------
				
*-----------------------------------------------------------
LS_REMOVE:
* Description : Removes the specified data block as follows:
*		        PREV = &OCCUPIED		
*       		If (PREV).NEXT==NULL GOTO .NOTFOUND
* 		.LOOP: 	If (PREV).NEXT==ITEM GOTO .FOUND
*        		PREV = (PREV).NEXT
*        		GOTO .LOOP
* 		.FOUND:	(PREV).NEXT = (ITEM).NEXT
*		        (ITEM).NEXT = FREE
*			FREE = ITEM
*               .NOTFOUND: EXIT
* Pre         : Stack. Specified stack offsets correspond to
*               the stack state at the beginning of the sub-
*               routine.
*               Stack offsets from 0 to 3 contain the return 
*               address.
*                 - Offset 4: LONG: Pointer to the list
*		  - Offset 8: LONG: Pointer to the data block to remove.
* Post        : All registers are restored to their initial 
*               values.
* Note        : When calling this subroutine, the pointer is
*               supposed to point to an item.
*-----------------------------------------------------------
	
	MOVEM.L A0-A3,-(A7)
	
	MOVE.L 24(A7),A0 ;A0 = @ ELEMENT
	MOVE.L 20(A7),A1 ;A1 = @ LIST
	
	MOVE.L A0,-(A7)
	MOVE.L A1,-(A7)
        BSR LS_PREVIOUS
        ADDQ.L #4,A7    ; RESET
        MOVE.L (A7)+,A2 ;A2 = @ PREVIOUS
        
        
        CMP.L #$FFFFFFFF,A2
        BEQ .noTePrevi
        .tePrevi:
                MOVE.L A0,-(A7)
                MOVE.L A1,-(A7)
                BSR LS_NEXT
                ADDQ.L #4,A7 ; RESET
                MOVE.L (A7)+,A3 ; A3 = @ NEXT
                
                CMP.L #$FFFFFFFF,A3
                BNE .teNextP
                MOVE.L #$0,A3
                .teNextP:
                MOVE.L A3,(A2)      ; 1º LONG OF BLOCK = @ NEXT
                
                BRA .afegirALliures
        .noTePrevi:
                MOVE.L A0,-(A7)
                MOVE.L A1,-(A7)
                BSR LS_NEXT
                ADDQ.L #4,A7 ; RESET
                MOVE.L (A7)+,A3 ; A3 = @ NEXT
                
                CMP.L #$FFFFFFFF,A3
                BNE .teNextNP
                MOVE.L #$0,A3
                .teNextNP:
                MOVE.L A3,2(A1)       ; OCCUPIED = @NEXT
                
                BRA .afegirALliures

	.afegirALliures:
	        
	        MOVE.L 6(A1),A3
	        MOVE.L A0,6(A1)
	        MOVE.L A3,(A0)
	        
	        MOVEM.L (A7)+,A0-A3
	rts
*-----------------------------------------------------------

*-----------------------------------------------------------
LS_FIRST:
* Description : Outputs a pointer to the first occupied item
*               or $FFFFFFFF if empty list.
* Pre         : Stack. Specified stack offsets correspond to
*               the stack state at the beginning of the sub-
*               routine.
*               Stack offsets from 0 to 3 contain the return 
*               address.
*		  - Offset 4: LONG: List pointer.
* Post        : All registers are restored to their initial 
*               values.
*               Stack. The stack offsets specified now are
*               based on the same reference that the input ones.
*                 - Offset 4: LONG: Item pointer or $FFFFFFFF
*                   if empty list.
*                   The pointer points to the data block. That
*                   is, to the NEXT field of the data block.
* Note        : When calling this subroutine, the pointer is
*               supposed to point to a properly initialized list.
*-----------------------------------------------------------
	; PUSH: A0,A1. 2 LONG=8Byte. Add 8 to all stack references
	movem.l	A0-A1, -(A7)

	; Get the list pointer
	move.l	12(A7), A0
	
	; Get the pointer to the first occupied
	move.l	2(A0), A1
	
	; Is it null?
	cmp.l	#0, A1
	beq	.ISNULL
	
	; Output pointer
	move.l	A1, 12(A7)
	bra	.END
	
	; If NULL, output #$FFFFFFFF
.ISNULL: move.l	#$FFFFFFFF, 12(A7)
.END:	; POP registers
	movem.l	(A7)+, A0-A1
	rts	
*-----------------------------------------------------------

*-----------------------------------------------------------
LS_NEXT:
* Description : Given an item, outputs a pointer to the next 
*               occupied item or $FFFFFFFF if no next item.
* Pre         : Stack. Specified stack offsets correspond to
*               the stack state at the beginning of the sub-
*               routine.
*               Stack offsets from 0 to 3 contain the return 
*               address.
*		  - Offset 4: LONG: List pointer.
*                 - Offset 8: LONG: Current item pointer
* Post        : All registers are restored to their initial 
*               values.
*               Stack. The stack offsets specified now are
*               based on the same reference that the input ones.
*                 - Offset 8: LONG: Next item pointer or $FFFFFFFF
*                   if no next item.
*                   The pointer points to the data block. That
*                   is, to the NEXT field of the data block.
* Note        : When calling this subroutine, the list pointer is
*               supposed to point to a properly initialized list.
* Note        : When calling this subroutine, the current item pointer
*               is supposed to point to an actual item. The subroutine
*               does not check whether it is or not.
*-----------------------------------------------------------
		MOVEM.L A0/D0,-(A7)
		
		MOVE.L 16(A7),A0 ; @ of the given element
		MOVE.L (A0),D0
                MOVE.L D0,A0   ; @ of the next element from the given one
		
                CMP.L #$0,A0
                BEQ .isNULL
                
                BRA .endOSR
                
                .isNULL:
                MOVE.L #$FFFFFFFF,A0
		.endOSR:
		MOVE.L A0,16(A7)
		
		MOVEM.L (A7)+,A0/D0
		rts		
*-----------------------------------------------------------

*-----------------------------------------------------------
LS_PREVIOUS:
* Description : Given an item, outputs a pointer to the previous 
*               occupied item or $FFFFFFFF if no previous item.
* Pre         : Stack. Specified stack offsets correspond to
*               the stack state at the beginning of the sub-
*               routine.
*               Stack offsets from 0 to 3 contain the return 
*               address.
*		  - Offset 4: LONG: List pointer.
*                 - Offset 8: LONG: Current item pointer
* Post        : All registers are restored to their initial 
*               values.
*               Stack. The stack offsets specified now are
*               based on the same reference that the input ones.
*                 - Offset 8: LONG: Previous item pointer or $FFFFFFFF
*                   if no next item.
*                   The pointer points to the data block. That
*                   is, to the NEXT field of the data block.
* Note        : When calling this subroutine, the list pointer is
*               supposed to point to a properly initialized list.
* Note        : When calling this subroutine, the current item pointer
*               is supposed to point to an actual item. The subroutine
*               does not check whether it is or not.
*-----------------------------------------------------------
		MOVEM.L A0-A2/D0,-(A7)
		
	        MOVE.L 20(A7),A0 ; A0 HOLDS @ OF LIST
	        ADDQ   #2,A0       ; A0 POINTS TO THE @ OF FIRST BLOCK
	        MOVE.L (A0),D0   ; D0 HAS THE @ OF THE FIRST BLOCK.
	        MOVE.L D0,A0     ; A0 HOLDS THE @ OF THE FIRST BLOCK
	        
	        MOVE.L 24(A7),A2 ; A1 HOLDS @ OF THE ELEMENT THAT WE NEED
	                         ; TO GET THE PREVIOUS ONE
	                         
	        CMP.L A0,A2
	        BEQ .hasNOPrevious
	        
		
		.LOOP:
		MOVE.L (A0),D0
		MOVE.L D0,A1
		CMP.L A1,A2
		BEQ .FINISH
		MOVE.L A1,A0
		BRA .LOOP
		
	        .FINISH:
	        MOVE.L A0,24(A7)
	        BRA .endOSR
	        .hasNOPrevious:
	        MOVE.L #$FFFFFFFF,24(A7)
	        .endOSR:
	        MOVEM.L (A7)+,A0-A2/D0
		rts		
*-----------------------------------------------------------

*-----------------------------------------------------------
LS_COUNT:
* Description : Outputs the number of items in the list
* Pre         : Stack. Specified stack offsets correspond to
*               the stack state at the beginning of the sub-
*               routine.
*               Stack offsets from 0 to 3 contain the return 
*               address.
*		  - Offset 4: LONG: List pointer.
* Post        : All registers are restored to their initial 
*               values.
*               Stack. The stack offsets specified now are
*               based on the same reference that the input ones.
*                 - Offset 4: WORD: Number of items
* Note        : When calling this subroutine, the list pointer is
*               supposed to point to a properly initialized list.
*-----------------------------------------------------------
		; PUSH registers A0, A1, D0.W. 10 bytes. Add 10
		; to stack references
		movem.l	A0-A1, -(A7)
		move.w	D0, -(A7)
		
		; Get some parameters
		move.l	14(A7), A0	; List pointer
		move.l	A0, A1
		add.l	#2, A1		; Pointer to the first item pointer
		
		; Init the counter
		move.w	#0, D0
		
		; Do the count
.LOOP:		cmp.l	#0, (A1)
		beq	.END
		addq.w	#1, D0
		move.l	(A1), A1
		bra	.LOOP
		
		; Output the result
.END:		move.w	D0, 14(A7)

		; POP registers
		move.w	(A7)+, D0
		movem.l	(A7)+, A0-A1
		rts		
*-----------------------------------------------------------

*-----------------------------------------------------------
LS_GET_ITEM:
* Description : Given the logical position of an item in the 
*               list, outputs the item pointer or $FFFFFFFF
*               if the item does not exist.
* Pre         : Stack. Specified stack offsets correspond to
*               the stack state at the beginning of the sub-
*               routine.
*               Stack offsets from 0 to 3 contain the return 
*               address.
*		  - Offset 4: LONG: List pointer.
*                 - Offset 8: LONG: Item position
* Post        : All registers are restored to their initial 
*               values.
*               Stack. The stack offsets specified now are
*               based on the same reference that the input ones.
*                 - Offset 8: LONG: Item pointer
*                   The pointer points to the data block. That
*                   is, to the NEXT field of the data block.
* Note        : When calling this subroutine, the list pointer is
*               supposed to point to a properly initialized list.
*-----------------------------------------------------------
		; regs
		MOVEM.L D0-D2/A0,-(A7)
		
		
		MOVE.L 24(A7),D0 ; index
		MOVE.L 20(A7),A0 ; @LIST
		ADDQ.L #2,A0     ; A0 POINTS @ 1º BLOCK
		
		
		CLR.L D1         ; use d1 as a counter
		
		.loop:
		
		        MOVE.L (A0),D2
		        MOVE.L D2,A0
		        
                        CMP D1,D0
		        BEQ .return
		        
		        CMP.L #0,(A0)
		        BEQ .returnNULL
		                .incrementAndLoop:
        		                ADDQ #1,D1
	            	                BRA .loop
		        BRA .return
		.returnNULL:
                        MOVE.L #$FFFFFFFF,A0
		.return:
		        MOVE.L A0,24(A7)
		        
		MOVEM.L (A7)+,D0-D2/A0
		rts
*-----------------------------------------------------------












*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~8~
