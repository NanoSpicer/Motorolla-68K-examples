*-----------------------------------------------------------
* Program    : Main program to test list and list_plot libraries
* Written by : A. Burguera
* Creation   : 17-October-2014
* Last update: 14-October-2015 
* Description: The program creates an empty list, plots it and
*              allows some basic user interaction with it.
*              Note that EVERYTHING must work if TST_LIST_ITEM_SIZE or
*              TST_LIST_LIST_SIZE change. 
*              The files included are:
*              + SCREEN.X68: Includes some useful macros for graphics and
*                            text display.
*              + LIST.X68: The list library. It MUST provide, at least, 
*                          the interface functions.
*              + LIST_PLOT.X68: The list plot library. It MUST provide, 
*                          at least, the interface functions.
* Important  : You can modify this file to test your code. However,
*              the final version of your code MUST contain this
*              file EXACTLY as it is provided. Absolutely NO changes
*              in this file are allowed in the final version.
*-----------------------------------------------------------
			ORG	$1000
			OPT	MEX		; Explicitly expands the macros. Useful for debugging.
************************************************************
*                        CONSTANTS                         *
************************************************************
TST_LIST_ITEM_SIZE:		EQU	10	; How many data words has a data block ;; MY COMENT = ORIGINAL VALUE = 10
TST_LIST_LIST_SIZE:		EQU	200	; The maximum number of data items ;; MY COMENT = ORIGINAL VALUE = 200
TST_LIST_WORDS_HEADER:		EQU	5	; How many header words. See comments in list.X68 about the header.
TST_LIST_WORDS_TOTAL:		EQU     TST_LIST_WORDS_HEADER+TST_LIST_LIST_SIZE*(2+TST_LIST_ITEM_SIZE) ; Total size, in words, of the list
************************************************************

************************************************************
*                   SOURCE FILE INCLUDES                   *
************************************************************
			INCLUDE "screen.x68"
			INCLUDE	"list.x68"	; List library
			INCLUDE "list_plot.x68"
************************************************************

************************************************************
*                       MAIN PROGRAM                       *
************************************************************
START:		; Prepare the parameters to init the list
		move.w	#TST_LIST_ITEM_SIZE, -(A7)
		move.w	#TST_LIST_LIST_SIZE, -(A7)
		move.l	#TST_LIST, -(A7)
		
		; Init the list using the list library function
		bsr	LS_INIT
		
		; Restore the stack
		add.l	#8, A7
			
		; Install the user interface	
		bsr LP_INSTALL 
		
		; Both LP_UPDATE_UI and LP_PLOT_UI require
		; the list pointer as a parameter. We put
		; the parameter in the stack here, outside
		; the loop, as both functions properly res-
		; tore it.
		move.l	#TST_LIST, -(A7)
		
		; Main loop. It is an infinite loop as there
		; is no need to exit the program
		
		; Interact with the user
.LOOP:		bsr LP_UPDATE_UI

		; Plot the interface
		bsr LP_PLOT_UI
		bra	.LOOP

		; This code is never reached. However, if for some
		; reason an exit condition is included in the future,
		; this is the exit point: it restores the stack.
		add.l	#4, A7
		
		; Stop the simulation (again, never reached in this case)
		move.b	#9, d0
		trap	#15
		
************************************************************
*                         VARIABLES                        *
************************************************************
TST_LIST:	ds.w	TST_LIST_WORDS_TOTAL	; The list
TST_MARKER:	ds.w	0	; No need to align here, as there
				; is no code after this line. However,
				; the label could be used to compute
				; the code size (it is TST_MARKER-$1000).
************************************************************
	END	START





















*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~8~
