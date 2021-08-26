*-----------------------------------------------------------
* Program    : List plot library. 
* Written by : A. Burguera
* Creation   : 17-October-2014
* Last update: 14-October-2015 
* Description: Provides basic user interface 
*              (UI) to interact with lists that follow the
*              list.X68 specs.
* Important  : You can (and have to) code the functions which
*              are not coded. However, you MUST NOT, UNDER
*              ANY CIRCUMSTANCE, modify the existing code.
*              The functions which are already implemented
*              MUST NOT be modified. 
* Important  : The code MUST use the constants below. No
*              hard-coded values are allowed instead of these
*              constants. The program must work for arbitrary
*              values of these constants, except:
*              * Screen width and height must be 640x480
*              * (LP_SCREEN_WIDTH/LP_ITEM_WIDTH) must be an integer
*                value.
*              You are allowed (and advised to)
*              change these values to test your code. However,
*              the final version MUST have exactly the
*              provided values. 
*-----------------------------------------------------------

************************************************************
*                        CONSTANTS                         *
************************************************************
LP_INITIAL_Y		EQU	200	; Initial Y coordinate to plot the list.
LP_NEW_X		EQU	20	; NEW ITEM button left coordinate.
LP_NEW_Y		EQU	20	; NEW ITEM button right coordinate.
LP_NEW_WIDTH		EQU	64	; NEW ITEM button width.
LP_NEW_HEIGHT		EQU	32	; NEW ITEM button height
LP_ITEM_WIDTH		EQU	32	; Item rectangle width
LP_ITEM_HEIGHT		EQU	32	; Item rectangle height
LP_SCREEN_WIDTH		EQU	640	; Screen width
LP_SCREEN_HEIGHT	EQU	480	; Screen height
************************************************************

*-----------------------------------------------------------
LP_INSTALL:
* Description : Installs the mouse interrupt at ISR 1
*               Prepares screen (640x480, windowed, double buffer)
*               Initializes (LP_LAST) to zero. This value is
*               used in other functions to allow the automatic
*               creation of new different items.
* Pre         : 
* Post        : All registers are restored to their initial 
*               values.
*-----------------------------------------------------------
		movem.w	D0-D1, -(A7)

		; Install mouse		
		move.l	#LP_ISR_MOUSE_MOVE, ($64) ; Associate ISR to level 1 interrupt. This is crucial: first put
						; the ISR in the exceptions vector, then enable mouse interrupt. 
						; Otherwise, an error may happen if mouse moves before the ISR
						; has been defined.
	
		move.w	#$0107, D1		; Interrupt 1 when mouse moves or a button is pressed
		move.b	#60, D0
		trap	#15			; Enable interrupt
		
		; Prepare output window
		SC_SET_RES LP_SCREEN_WIDTH, LP_SCREEN_HEIGHT	; Set screen resolution
		SC_SET_WINDOWED			; Set windowed mode
		SC_ENABLE_DBUFFER		; Enable double buffer
		
		; Initialize the variable used to generate sequential numbers when creating new items
		move.w	#0, (LP_ITEM_LAST)
				
		movem.w	(A7)+, D0-D1
		rts
*-----------------------------------------------------------

*-----------------------------------------------------------
LP_PLOT_UI:
* Description : * Plots the list items, each as a 
*                 LP_ITEM_WIDTHxLP_ITEM_HEIGHT rectangle.
*                 The initial X coordinate is 0. The initial
*                 Y coordinate is LP_INITIAL_Y. Items are 
*                 drawn from left to right. When the right
*                 screen boundary is reached, a new line
*                 of items is started. Do not care about the
*                 bottom boundary being reached.
*               * Plots the NEW ITEM button as a white rectan-
*                 gle filled in red. LP_NEW_X, LP_NEW_Y, 
*                 LP_NEW_WIDTH and LP_NEW_HEIGHT define the
*                 position and size of the button.
*               * Prints the string "ITEM COUNT: X" at the
*                 top-left corner of the screen, where "X"
*                 is the current number of list items, written
*                 in base 10 using as many chars as necessary.
*               * Prints the values of the list item pointed by
*                 (LP_ITEM_SEL). These values are printed
*                 horizontally centered, starting at the top
*                 row and only one value per row. Each item
*                 must be printed using 6 chars.
*                 If (LP_ITEM_SEL) is $FFFFFFFF, then nothing
*                 has to be printed.
*               * Before drawing/printing anything, the function
*                 clears the drawing area. After drawing/painting
*                 everything, the function updates the double buffer.
* Pre         : Stack. Specified stack offsets correspond to
*               the stack state at the beginning of the sub-
*               routine.
*               Stack offsets from 0 to 3 contain the return 
*               address.
*		  - Offset 4: LONG: List pointer
* Post        : All registers are restored to their initial 
*               values.
* Note        : When calling this subroutine, the list pointer 
*               must point to a list following the LIST.X68
*               data structure.
* Important   : Whenever it is possible (which is practically
*               always) do not perform any assumption about
*               the list structure, and use the LIST.X68
*               library functions to access the list.
*-----------------------------------------------------------
                
                ; SAVE REGISTERS
                MOVEM.L	D0-D7/A0-A1, -(A7)
                ; UNDRAW THE SCREEN
                *** this will use registers D0 and D1 ***
                                
                                
                                SC_REPAINT_SCREEN
                                
                ;1º DRAW RECTANGLE AT THE TOP LEFT PART (white and red)
		        SC_SET_PEN #$00FFFFFF
		        SC_SET_FILL #$000000FF
		        SC_DRAW_RECT #LP_NEW_X,#LP_NEW_Y,#LP_NEW_WIDTH,#LP_NEW_HEIGHT
		; END OF PART 1
		;2º DRAW AS MANY BOXES AS ITEMS THE LIST HAS
		        
		        SC_SET_PEN #$00000000
		        SC_SET_FILL #$00000000
                        SC_DRAW_RECT #0,#LP_INITIAL_Y,#LP_SCREEN_WIDTH,#LP_SCREEN_WIDTH  ; ERASE OLD BLOCKS :>
		        
		        
		        ; we need to know how many elements we're going to draw:
		        
                        MOVE.L 44(A7),-(A7)
		        
		        BSR LS_COUNT    ; we count the amount of elements that the list
		                        ; is holding
		        
		        MOVE.W (A7)+,D5 ; D5 holds the amount of items that are figure
		                        ; in. 
		        ADDQ #2,A7      ; we pick a word, but a long is occupied, so +2 to restore A7
		        
                                        ; i do move out LONG so SP points at the last
		                        ; pushed element, because the subroutine
		                        ; requires of a long word with @ of the list
		                        ; to count of
		        
                        CMP #0,D5
                        
                        BEQ .dontDraw   ; if there are no elements in the list
                                        ; we don't have to draw anything
                                        
                        
                        SUBQ.L #1,D5    ; we prepare D5 for the drawing
                                        ; iteration.
            
                                MOVE.W #0,-(A7) ; booking space
                                BSR LP_ITEMS_PER_LINE
                                MOVE.W (A7)+,D7 ; D7 holds the amount of elements that a line can hold
		                
		        ; drawing elements part
		                SC_SET_PEN #$00FFFFFF
		                SC_SET_FILL #$00FF0000
		                CLR.L D0 ; will be used to draw rectangles
		                CLR.L D1
		                CLR.L D2
		                CLR.L D3 ; I'll use D3 as a counter
		                CLR.L D4
		                MOVE.W #LP_INITIAL_Y,D2 ; Y coordenate to draw rectangles
		        .drawElements:
		                SC_DRAW_RECT D0, D2, #LP_ITEM_WIDTH, #LP_ITEM_HEIGHT
		                ADDQ #1,D6
		                CLR D0
		                ADD #LP_ITEM_WIDTH,D0 ; adding and multiplying to 
                                MULU.W D6,D0          ; get the following X point
       
		                CMP D7,D6             ; compare the amount of drawed
                                                      ; elements with amount of elements
                                                      ; per line
                                                      
		                BNE .dontChangeLine   
                                                      ; if we haven't reached the top
		                                      ; amount per elements per line,
		                                      ; we must not change the line
		                                      ; where we're about to draw
		                                      
		                                      ; Otherwise we reset the X draw
		                                      ; point and we update the Y draw
		                                      ; point as below
		                ADD  #LP_ITEM_HEIGHT,D2
		                MOVE #0,D0
		                MOVE #0,D6
		                .dontChangeLine:
		        DBRA D5,.drawElements
		        
		        CLR.L D5
		        .dontDraw:
		        ; end of drawing elements part 
		;END OF PART 2
		        
		
		
		;3º PRINTS THE STRING ITEM_COUNT: X
		        
		        SC_SET_PEN #$00000000
		        SC_SET_FILL #$00000000
                        SC_DRAW_RECT #0,#0,#LP_SCREEN_WIDTH,#LP_NEW_Y-1
		        
		        SC_LOCATE #0,#0
		        SC_SET_FILL #00000000
		        CLR.L D6
		        MOVE.L 44(A7),-(A7)
		        BSR LS_COUNT
		        MOVE.W (A7)+,D6
		        ADDQ #2,A7
		        
                        SC_DISP_STRNUM STRING,D6
                                                
		        ;END OF PART 3
		
		;4º PRINTS THE VALUES OF THE DATABLOCK POINTER BY LP_ITEM_SEL
		        
		        
		        SC_SET_PEN #$00000000
		        SC_SET_FILL #$00000000
                        SC_DRAW_RECT #320,#0,#320,#LP_INITIAL_Y-1  ; ERASE RESTOS
                        
                        MOVE.L (LP_ITEM_SEL),D0 ;because we cant move the content of an adress directly to an adress register
		        
		        CMP.L #$FFFFFFFF,D0
		        
		        BEQ .noItemSelected
		        .ItemSelected:
		        
                        MOVE.L D0,A0
		        ADDA.L #4,A0    ; A0 POINTS TO THE FIRST DATA word
                                        
                                          
                                        
                        MOVE.L 44(A7),A1 ; A1 = @LIST
                        MOVE.W (A1),D4   ; D4 = AMOUNT OF WORDS OF DATA.
                                         ; prepare d0 for the dbra
                                        
                        SUBQ #1,D4
                        
                        CLR.L D0
                        CLR.L D1
                        CLR.L D2
                        CLR.L D3
                        .loop:
                                SC_LOCATE #45,D3
                                ADDQ.B #1,D3
                                MOVE.W (A0)+,D2
                                SC_DISPLAY_NUM D2     
                        DBRA D4,.loop
                        BRA .endOSR
                        .noItemSelected:

		; END OF PART 4
		.endOSR:
		; RESTORE REGISTERS
		MOVEM.L (A7)+,D0-D7/A0-A1
		rts
*-----------------------------------------------------------
		
*-----------------------------------------------------------
LP_UPDATE_UI:
* Description : Performs the user interaction. At least the
*               following tasks are performed here:
*               * Checks if the mouse has been clicked. 
*                 To this end, it uses (LP_MOUSE_BUT) to know
*                 if t he mouse button is pressed and also
*                 uses/updates (LP_MOUSE_PRE) to detect
*                 the click. Note that a click is a change from
*                 not-pressed to pressed. Note also that 
*                 this function MUST NOT modify (LP_MOUSE_BUT).
*               * If the mouse is clicked inside the NEW ITEM
*                 button, a new item is created. The new item
*                 data is a set of consecutive numbers, starting
*                 from the last number +1 included in a previous
*                 item or 0 if the first. The variable (LP_ITEM_LAST)
*                 has to be used to this end.
*               * If the mouse is clicked inside one of the items,
*                 the item is deleted.
*               * If the mouse is inside an item, the pointer
*                 to this item is placed in (LP_ITEM_SEL). If
*                 the mouse is not inside an item, the value
*                 #$FFFFFFFF is placed in (LP_ITEM_SEL). This
*                 task is performed either if the mouse button
*                 is clicked or not.
* Pre         : Stack. Specified stack offsets correspond to
*               the stack state at the beginning of the sub-
*               routine.
*               Stack offsets from 0 to 3 contain the return 
*               address.
*		  - Offset 4: LONG: List pointer
* Post        : All registers are restored to their initial 
*               values.
* Note        : When calling this subroutine, the list pointer 
*               must point to a list following the LIST.X68
*               data structure.
* Important   : Whenever it is possible (which is practically
*               always) do not perform any assumption about
*               the list structure, and use the LIST.X68
*               library functions to access the list.
*-----------------------------------------------------------
		MOVEM.L D0-D3/A0,-(A7)
		
		; click?
		MOVE.B (LP_MOUSE_PRE),D0
		NOT.B   D0
		MOVE.B (LP_MOUSE_BUT),D1
		AND.B D0,D1
		BEQ .NOmouseCLICK
		.mouseCLICK:
		        MOVE.W (LP_MOUSE_CX),D0
		        MOVE.W (LP_MOUSE_CY),D3
		        CMP #LP_INITIAL_Y,D3    
		        BGE .borrar
		        .afegir:
		                ; CHECKING BOUNDS
		                MOVE.W #LP_NEW_X,D1
		                MOVE.W D1,D2
		                ADD.W #LP_NEW_WIDTH,D2
		                
		                CMP D1,D0
		                BMI .endOSR
		                CMP D0,D2
		                BMI .endOSR
		                ; if program reaches this point all is OK by now
		                
		                MOVE.W #LP_NEW_Y,D1
		                MOVE.W D1,D2
		                ADD.W #LP_NEW_HEIGHT,D2
		                
		                CMP D1,D3
		                BMI .endOSR
		                CMP D3,D2
		                BMI .endOSR
		                ; END OF CHECKING BOUNDS
		                
		                ; if program reaches this point, the click
		                ; has been done into the new item "button".
		                
		                ; ADD ELEMENT
		                        ; push data. loop.
		                        MOVE.L 24(A7),A0
		                        MOVE.W (A0),D0 ; D0 HOLDS THE AMOUNT OF WORDS TO BE PUSHED IN
		                        MOVE.W D0,D1
		                        
		                        SUBQ #1,D0 ; prepare D0 for DBRA
		                        .loop:
		                                MOVE.W (INPUT),D2
		                                MOVE.W D2,-(A7)
		                                ADD.W #1,D2
		                                MOVE.W D2,(INPUT)
		                                
		                        DBRA D0,.loop
		                        MOVE.L A0,-(A7)
		                        BSR LS_PUT
		                        MOVE.W (A7)+,(LP_ITEM_LAST)
		                        ADDQ #2,A7 ;RESTORE THE FUCKING STACK
		                        MULU.W #2,D1 ; restore bytes x2 = W
		                        ADD.L D1,A7  ; RESTORE A7
		                       
		                        
		                ; END OF ADD ELEMENT
		                
		                BRA .endOSR
		        .borrar:
		        
		                MOVE.W (LP_MOUSE_CX),D0
		                MOVE.W (LP_MOUSE_CY),D1
		                CMP #LP_INITIAL_Y,D1
                                BMI .doesntExist
		        
		                
		                DIVU #LP_ITEM_WIDTH,D0
                                AND.L #$0000FFFF,D0
                                ADDQ.B #1,D0
                                
                                SUB #LP_INITIAL_Y,D1
                                DIVU #LP_ITEM_HEIGHT,D1
                                AND.L #$0000FFFF,D1
                                ADDQ.B #1,D1
                                
                                
		        
		                        ;ERASE
		                MOVE.L 24(A7),A0
		                MOVE.L (LP_ITEM_SEL),D0
		                CMP.L #$FFFFFFFF,D0
		                BEQ .doesntExist
                                MOVE.L D0,-(A7)   
		                MOVE.L A0,-(A7)               ;@ LIST
		                BSR LS_REMOVE
		                ADD.L #8,A7 ; RESTORE STACK
		                BRA .doesntExist
		.NOmouseCLICK:
		        MOVE.W (LP_MOUSE_CX),D0
		        MOVE.W (LP_MOUSE_CY),D1
		        CMP #LP_INITIAL_Y,D1
                        BMI .doesntExist
                        
                        .readELEMENT:
                        ; we calculate the element that cursor is pointing at

                                
                                
                                DIVU #LP_ITEM_WIDTH,D0
                                AND.L #$0000FFFF,D0
                                ADDQ.B #1,D0
                                
                                SUB #LP_INITIAL_Y,D1
                                DIVU #LP_ITEM_HEIGHT,D1
                                AND.L #$0000FFFF,D1
                                ADDQ.B #1,D1
                                                ;  l'item seleccionat serà :
                                                ; (#fila-1)*#elementsPerFila + (#columna) elements
                                                ; (#fila-1)*#elementsPerFila + (#columna-1) posicio
                                
                                MOVE.L 24(A7),-(A7)	; pointer to the list
     
		                BSR LS_COUNT            ; we count the amount of elements that the list
		                                        ; is holding
		                MOVE.W (A7)+,D2         ; D2 holds the amount of items that figure
		                                        ; in.
		                                        
		                ADDQ #2,A7              ; restore A7 as far as we have extracter the WORD when we've inputted a LONG
		                                        
		                MOVE.W #0,-(A7)
		                BSR LP_ITEMS_PER_LINE
		                MOVE.W (A7)+,D3         ; D3 holds the amount of items that a line
		                                        ; can hold.
		                
		                SUBQ.B #1,D1
		                
		                MULU.W D1,D3            
		                ADD.W  D0,D3            ; D3 indicates the position of the element that is being pointed
		                                        ; without an array convention.
		                
		                CMP D2,D3
		                BGT .doesntExist
                                .exists:
                                        
                                        SUBQ.B #1,D3            ; D3 now has the position of the element with an array convention
                                        MOVE.L D3,-(A7)         ; position of the element
                                        MOVE.L 28(A7),-(A7)	; pointer to the list
                                        BSR LS_GET_ITEM
                                        
                                        ADDQ.L #4,A7            ; restaurar SP
                                        MOVEA.L #0,A0
                                        MOVE.L (A7)+,A0
                                        MOVE.L A0,(LP_ITEM_SEL) ; update LP_ITEM_SEL

                                        BRA .endOSR
                                .doesntExist:
                                        MOVE.L #$FFFFFFFF,(LP_ITEM_SEL)
                                        
		.endOSR:
		
		MOVE.B (LP_MOUSE_BUT),(LP_MOUSE_PRE)
		MOVEM.L (A7)+,D0-D3/A0
		rts
*-----------------------------------------------------------
		
		
************************************************************
*                               ISRs                       *
************************************************************
*-----------------------------------------------------------
LP_ISR_MOUSE_MOVE:
* This ISR is called when a MOUSE MOVE event is produced.
* Pre: 
* Post: (LP_MOUSE_CX).W: X coordinate
*       (LP_MOUSE_CY).W: Y coordinate
*       (LP_MOUSE_BUT).B: 01 if left button pressed, 00 if not
* Modifies: Nothing
*-----------------------------------------------------------
		; SAVE REGISTERS
                MOVEM.L D0-D1,-(A7)
		;
                CLR.L D1
                MOVE.W  #61,D0
		TRAP    #15
		; GETS THE COODRINATES
		MOVE.W D1,(LP_MOUSE_CX) 
		SWAP D1
		MOVE.W D1,(LP_MOUSE_CY)
		
		AND.W #1,D0
		MOVE.B D0, (LP_MOUSE_BUT)
		
		
		; RESTORE REGISTERS
		MOVEM.L (A7)+,D0-D1
		rte		
*-----------------------------------------------------------	

************************************************************
*                         VARIABLES                        *
************************************************************
LP_MOUSE_CX:	ds.w	1
LP_MOUSE_CY:	ds.w	1
LP_MOUSE_BUT:	ds.b	1
LP_MOUSE_PRE:	ds.b	1
LP_ITEM_LAST:	ds.w	1
LP_ITEM_SEL:	ds.l	1
		ds.w	0		; Memory alignment
************************************************************	

************************************************************
*                      MY VARIABLES                        *
************************************************************
STRING DC.B 'ITEM COUNT: ',0
INPUT  DC.W     0
		ds.w	0		; Memory alignment
************************************************************


************************************************************
*                      MY SUBROUTINES                      *
************************************************************

*-----------------------------------------------------------
LP_ITEMS_PER_LINE:

        * Description:
                ; Given a width of an element this USR just 
                ; calculates the number of elements that fit
                ; into a line.
        * MODIFIES: D0,D1,D2
        * INPUT: NONE ( user must book a word for the output data )!
        * OUTPUT: # ELEMENTS PER LINE
*-----------------------------------------------------------

        MOVEM.L D0-D2,-(A7)     ; save registers
        
                        ; WE GET THE RESOLUTION
        SC_GET_RES      
        SWAP D1
        AND.L #$0000FFFF,D1     ; D1 holds the number of Xpixels
	MOVE.L D1,D0            ; COPY THAT TO D0

        DIVU #LP_ITEM_WIDTH,D1  ; D1 holds the SUPPOSED
                                ; amount of boxes that 
                                ; the screen can handle
		                
	MOVE.W D1,D2            ; copy that to d2
		                
	MULU #LP_ITEM_WIDTH,D1  ; if we multiplicate this
		                ; theorically we're going to
		                ; get back those Xpixels of
		                ; the begining
		                
		                
	CMP D0,D1               ; compare the obtained value
		                ; with the initial Xpixels
		                ; that we've obtained
		                                        
	BEQ .noRestar           ; if they're equal, that means
		                ; that the amount of boxes that 
		                ; fit in a line is an integer
		                ; and  we're ready to continue
		                                        
	SUBQ #1,D2              ; else, we must substract 1
	                        ; element from the amount of
		                ; elements per line
        .noRestar:
        
        MOVE.W   D2,16(A7)      ; output value
        
        
        MOVEM.L (A7)+,D0-D2     ; restore registers
        RTS
*------------END OF USR-------------------------------------


















*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~8~
