*-----------------------------------------------------------
* Program    : Screen-related macros
* Written by : A. Burguera
* Creation   : 17-October-2014
* Last update: 14-October-2015
* Description: Utility macros to manage graphics and text.
*              Their aim is just to provide a clean interface
*              to some of the Easy68K trap #15 functions. Not
*              all the trap #15 functions are here.
*              Note that there is no need to use them always
*              in your code. In some cases, it is preferrable
*              to directly code the trap #15 calls instead
*              of using the macros. That's the magic of
*              programming.
* Important  : DO NOT, UNDER ANY CIRCUMSTANCE, MODIFY THE
*              CODE IN THIS FILE. You can add new macros
*              at the end of the file if needed, but do not
*              modify a single line of the existing code.
*-----------------------------------------------------------

*-----------------------------------------------------------
* Macro to set screen resolution.                          
* Parameters: \1: Width (pixels)                          
*             \2: Height (pixels)
* Modifies  : D0, D1
*-----------------------------------------------------------
SC_SET_RES 	MACRO
		move.b	#33, D0
		move.l	#\1*$10000+\2, D1
		trap	#15
		ENDM
		
*-----------------------------------------------------------
* Macro to set windowed mode
* Modifies  : D0, D1
*-----------------------------------------------------------
SC_SET_WINDOWED	MACRO
		move.b	#33, D0
		move.l	#1, D1
		trap	#15
		ENDM
		
*-----------------------------------------------------------
* Macro to set fullscreen mode
* Modifies  : D0, D1
*-----------------------------------------------------------
SC_SET_FULLSCREEN MACRO
		move.b	#33, D0
		move.l	#2, D1
		trap	#15
		ENDM
		
*-----------------------------------------------------------
* Macro to locate the text cursor
* Parameters: \1: X
*             \2: Y
* Modifies  : D0, D1
*-----------------------------------------------------------
SC_LOCATE	MACRO		
		move.b	\1, D1	; Put X coordinate
		lsl.w	#8, D1
		move.b	\2, D1	; Put Y coordinate
		move.b	#11, D0
		trap	#15
		ENDM

*-----------------------------------------------------------
* Macro to set the pen color. 
* Parameters: \1: Color in format $00BBGGRR
* Modifies  : D0, D1
*-----------------------------------------------------------		
SC_SET_PEN	MACRO
		move.l	\1, D1
		move.b	#80, D0
		trap	#15
		ENDM
*-----------------------------------------------------------		

*-----------------------------------------------------------
* Macro to set the fill color. 
* Parameters: \1: Color in format $00BBGGRR
* Modifies  : D0, D1
*-----------------------------------------------------------		
SC_SET_FILL	MACRO
		move.l	\1, D1
		move.b	#81, D0
		trap	#15
		ENDM
*-----------------------------------------------------------
*-----------------------------------------------------------
* Macro to clear the screen
* Modifies  : D0, D1
*-----------------------------------------------------------
SC_CLEAR	MACRO
		move.b	#11, D0
		move.w	#$FF00, D1
		trap	#15
		ENDM
	
*-----------------------------------------------------------
* Macro to print a string
* Parameters: \1: String address
* Modifies  : D0, A1
*-----------------------------------------------------------
SC_PRINT_STR	MACRO
		lea	\1, A1
		move.b	#14, D0
		trap	#15
		ENDM
		
*-----------------------------------------------------------
*-----------------------------------------------------------
* Macro to enable double buffer
* Parameters: 
* Modifies  : D0, D1
*-----------------------------------------------------------
SC_ENABLE_DBUFFER MACRO
		move.b	#17, D1
		move.b	#92, D0
		trap	#15
		ENDM

*-----------------------------------------------------------
* Macro to disable double buffer
* Parameters: 
* Modifies  : D0, D1
*-----------------------------------------------------------
SC_DISABLE_DBUFFER MACRO
		move.b	#16, D1
		move.b	#92, D0
		trap	#15
		ENDM
		
*-----------------------------------------------------------
* Macro to repaint screen (only in double buffer mode)
* Parameters: 
* Modifies  : D0, D1
*-----------------------------------------------------------
SC_REPAINT_SCREEN MACRO
		move.b	#94, D0
		trap	#15
		ENDM
*-----------------------------------------------------------


*-----------------------------------------------------------
*                       MY NEW MACROS!!!!
*-----------------------------------------------------------


*-----------------------------------------------------------
* Macro to print a number
* Parameters: \1: @STRING 2: the number
* Modifies  : D0, A1
*-----------------------------------------------------------
SC_DISP_STRNUM	MACRO
		LEA	\1, A1
		MOVE.L  \2,D1
		MOVE.B	#17, D0
		TRAP	#15
		ENDM
*--------------END OF MACRO----------------------------------

*-----------------------------------------------------------
* Macro to draw a rectangle 
* Parameters: 1 = OX | 2 = OY | 3 = X offset | 4 = Y offset
* Modifies  : D0, D1, D2, D3, D4
*-----------------------------------------------------------		
SC_DRAW_RECT	MACRO
		MOVE.W \1,D1 ;ox
		MOVE.W \2,D2 ;oy
		
		MOVE.W D1,D3
		MOVE.W D2,D4
		
		ADD.W \3,D3 ;fx
		ADD.W \4,D4 ;fy
		
		MOVE.B	#87, D0
		TRAP	#15
		ENDM
*---------------END OF MACRO---------------------------------

*-----------------------------------------------------------
* Macro to get the resolution of the screen
* Parameters: none
* Modifies  : D0, D1
*-----------------------------------------------------------		
SC_GET_RES	MACRO
		MOVE    #0,D1
		MOVE.B	#33, D0
		TRAP	#15
		ENDM
*---------------END OF MACRO---------------------------------	

*-----------------------------------------------------------
* Macro to display an unsigned number
* Parameters: number to be displayed
* Modifies  : D0, D1
*-----------------------------------------------------------		
SC_DISPLAY_NUM	MACRO
		MOVE    \1,D1
		MOVE.B	#3, D0
		TRAP	#15
		ENDM
*---------------END OF MACRO---------------------------------

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~8~
