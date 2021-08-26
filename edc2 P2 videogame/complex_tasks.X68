*-----------------------------------------------------------
* Program    : Medium complexity tasks ready to be run with TaskManager
*              installed. See taskmanager.X68 for more info.
* Written by : A. Burguera
* Date       : 17-Nov-2015
* Description: When executed together with the taskmanager, this
*              set of tasks will show a bouncing ball, the mouse
*              coordinates and some flags telling whether the
*              mouse, SPACE or M are pressed or not.
*              When space is pressed, a new ball is created. When
*              M is pressed, all the ball tasks will be removed.
*              If the mouse touches a ball, the ball will be
*              selected. This means that it will be painted in
*              green and stop moving. If the mouse is pressed
*              inside a selected ball, then the ball task is
*              deleted. If the mouse is pressed inside a moving
*              ball, then the task is put to sleep.
* Task list  : + T1: Double Buffer Manager
*              + T2: Ball
*              + T3: Mouse Manager
*              + T4: Keyboard Manager
*              + T5: Spawner
* Interaction: Spawner communicates with Mouse Manager and
*              Keyboard Manager through shared memory. 
*              Spawner iterates through tasks to select 
*              the Ball tasks and then obtains their
*              coordinates and state accessing their Task Memory.
*-----------------------------------------------------------
	
************************************************************
*                     COMMON CONSTANTS                     *
************************************************************
; Screen-related constants
TK_SCREEN_WIDTH	EQU	640
TK_SCREEN_HEIGHT EQU	480

; Task groups
TK_GROUP_BALL	EQU	0
TK_GROUP_DBUFFER EQU	1
TK_GROUP_MOUSE	EQU	2
TK_GROUP_KEYBOARD EQU	3
TK_GROUP_SPAWNER EQU	4

; General-purpose TMP offsets
TK_VAR_ID	EQU	0	; Word
TK_VAR_GROUP	EQU	2	; Word

; SMP offsets
TK_VAR_MOUSE_X	EQU	0	; Word
TK_VAR_MOUSE_Y	EQU	2	; Word
TK_VAR_MOUSE_BUT EQU	4	; Byte
TK_VAR_MOUSE_CLK EQU	5	; Byte
TK_VAR_SPC_PRESS EQU	6	; Byte
TK_VAR_SPC_CLK   EQU	7	; Byte
TK_VAR_M_PRESS	EQU	8	; Byte
TK_VAR_M_CLK	EQU	9	; Byte

************************************************************
*                       COMMON MACROS                      *
************************************************************

*-----------------------------------------------------------
* Macro to set screen resolution.                          
* Parameters: \1: Width (pixels)                          
*             \2: Height (pixels)
* Modifies  : D0, D1
*-----------------------------------------------------------
TK_SET_RES 	MACRO
		move.b	#33, D0
		move.l	#\1*$10000+\2, D1
		trap	#15
		ENDM
*-----------------------------------------------------------
				
*-----------------------------------------------------------
* Macro to set windowed mode
* Modifies  : D0, D1
*-----------------------------------------------------------
TK_SET_WINDOWED	MACRO
		move.b	#33, D0
		move.l	#1, D1
		trap	#15
		ENDM
*-----------------------------------------------------------
				
*-----------------------------------------------------------
* Macro to enable double buffer
* Parameters: 
* Modifies  : D0, D1
*-----------------------------------------------------------
TK_ENABLE_DBUFFER MACRO
		move.b	#17, D1
		move.b	#92, D0
		trap	#15
		ENDM
*-----------------------------------------------------------
		
*-----------------------------------------------------------
* Macro to repaint screen (only in double buffer mode)
* Parameters: 
* Modifies  : D0, D1
*-----------------------------------------------------------
TK_REPAINT_SCREEN MACRO
		move.b	#94, D0
		trap	#15
		ENDM
*-----------------------------------------------------------

*-----------------------------------------------------------
* Macro to clear the screen
* Modifies  : D0, D1
*-----------------------------------------------------------
TK_CLEAR	MACRO
		move.b	#11, D0
		move.w	#$FF00, D1
		trap	#15
		ENDM
*-----------------------------------------------------------

*-----------------------------------------------------------
* Macro to set the pen color. 
* Parameters: \1: Color in format $00BBGGRR
* Modifies  : D0, D1
*-----------------------------------------------------------		
TK_SET_PEN	MACRO
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
TK_SET_FILL	MACRO
		move.l	\1, D1
		move.b	#81, D0
		trap	#15
		ENDM
*-----------------------------------------------------------

*-----------------------------------------------------------
* Macro to draw an ellipse
* Parameters: No parameters. Coordinates are specified using
*             D1.W(Left), D2.W(Top), D3.W(Right), D4.W(Bottom)
* Modifies  : D0
*-----------------------------------------------------------		
TK_DRAW_ELLIPSE	MACRO
		move.b	#88, D0
		trap	#15
		ENDM
*-----------------------------------------------------------	

*-----------------------------------------------------------
* Macro to locate the text cursor
* Parameters: \1: X
*             \2: Y
* Modifies  : D0, D1
*-----------------------------------------------------------
TK_LOCATE	MACRO		
		move.b	\1, D1	; Put X coordinate
		lsl.w	#8, D1
		move.b	\2, D1	; Put Y coordinate
		move.b	#11, D0
		trap	#15
		ENDM
*-----------------------------------------------------------

************************************************************
*                    INITIALIZATION ROUTINE                *
************************************************************

* ----------------------------------------------------------
TK_INIT:
* Adds the tasks in the approppriate order into the task
* manager.
* ----------------------------------------------------------
; Define minimum cycle time
		move.l	#1, D1
		TM_SYSTEM_CALL  TM_FGROUP_CONFIG, TM_DEFINE_TIME
		
; Activate time-over detection
		TM_SYSTEM_CALL  TM_FGROUP_CONFIG, TM_PREVENT_TIME_OVER

; Add double buffer task
		lea	T1_TEP, A0		; TEP
		move.w	#TK_GROUP_DBUFFER, D1	; GROUP
		TM_SYSTEM_CALL  TM_FGROUP_BASIC, TM_ADD_TASK

; Add one ball task
		lea	T2_TEP, A0		; TEP
		move.w	#TK_GROUP_BALL, D1	; GROUP
		TM_SYSTEM_CALL  TM_FGROUP_BASIC, TM_ADD_TASK
		
; Add mouse task
		lea	T3_TEP, A0		; TEP
		move.w	#TK_GROUP_MOUSE, D1	; GROUP
		TM_SYSTEM_CALL  TM_FGROUP_BASIC, TM_ADD_TASK

; Add keyboard task
		lea	T4_TEP, A0		; TEP
		move.w	#TK_GROUP_KEYBOARD, D1	; GROUP
		TM_SYSTEM_CALL  TM_FGROUP_BASIC, TM_ADD_TASK

; Add spawner task
		lea	T5_TEP, A0		; TEP
		move.w	#TK_GROUP_SPAWNER, D1	; GROUP
		TM_SYSTEM_CALL  TM_FGROUP_BASIC, TM_ADD_TASK
			
		rts
* ----------------------------------------------------------


************************************************************
*                            TASK 1                        *
* -------------------------------------------------------- *
* Name:        DOUBLE BUFFER MANAGER                       *
* Description: Initializes screen and manages double       *
*              buffer.                                     *
************************************************************

; ==========================================================
; Task 1 functions
; ==========================================================

* ----------------------------------------------------------
T1_TEP:
* Task 1 entry point.
* ----------------------------------------------------------
		; Check if status is "initializing". If so, 
		; execute the initialization code.
		cmp.w	#TM_TCB_STATUS_INIT, D3
		beq	T1_INIT
		
		; Update the task logic
		bsr	T1_UPDATE

		; If no time-over allowed, frame-drop		
		TM_SYSTEM_CALL  TM_FGROUP_EXECUTION, TM_FRAME_DROP
				
		; Do the graphical stuff
		bsr	T1_PLOT
		
		; That's it. End by switching to next task
		TM_SYSTEM_CALL  TM_FGROUP_EXECUTION, TM_RETURN_TO_TM
* ----------------------------------------------------------

* ----------------------------------------------------------
T1_INIT:														
* Task 1 initialization code
* ----------------------------------------------------------
		; Store the task ID and GROUP in TMP to
		; ease further access if necessary.
		move.w	D1, TK_VAR_ID(A0)
		move.w	D2, TK_VAR_GROUP(A0)
		
		; Set the screen resolution
		TK_SET_RES	TK_SCREEN_WIDTH, TK_SCREEN_HEIGHT
		
		; Set windowed mode
		TK_SET_WINDOWED
		
		; Enable double buffer
		TK_ENABLE_DBUFFER
				
		; End by switching to next task
		TM_SYSTEM_CALL  TM_FGROUP_EXECUTION, TM_RETURN_TO_TM
* ----------------------------------------------------------
		
* ----------------------------------------------------------
T1_UPDATE:														
* Task 2 update task logic
* ----------------------------------------------------------
		; Nothing to do right now
		rts		
* ----------------------------------------------------------

* ----------------------------------------------------------
T1_PLOT:														
* Task 2 drawing stuff
* ----------------------------------------------------------
		; Update double buffer
		TK_REPAINT_SCREEN
		
		; Clear next frame
		TK_CLEAR		
		
		; That's it!
		rts
* ----------------------------------------------------------


************************************************************
*                            TASK 2                        *
* -------------------------------------------------------- *
* Name       : BALL
* Description: Displays a ball that bounces on the screen  *
*              boundaries.                                 *
************************************************************

; ==========================================================
; Task 2 constants
; ==========================================================
; General constants
T2_BALL_RADIUS		EQU	16
T2_DEFAULT_SPEED	EQU	1
T2_STATE_UNSELECTED	EQU	0
T2_STATE_SELECTED	EQU	1

; TMP offsets
T2_VAR_X		EQU	4	; Word
T2_VAR_Y		EQU	6	; Word
T2_VAR_SX		EQU	8	; Word
T2_VAR_SY		EQU	10	; Word
T2_VAR_STATE		EQU	12	; Byte

; ==========================================================
; Task 2 functions
; ==========================================================

* ----------------------------------------------------------
T2_TEP:
* Task 2 entry point.
* ----------------------------------------------------------
		; Check if status is "initializing". If so, 
		; execute the initialization code.
		cmp.w	#TM_TCB_STATUS_INIT, D3
		beq	T2_INIT
		
		; Update the ball logic
		bsr	T2_UPDATE
		
		; If no time-over allowed, frame-drop		
		TM_SYSTEM_CALL  TM_FGROUP_EXECUTION, TM_FRAME_DROP
		
		; Paint the ball
		bsr	T2_PLOT
		
		; That's it. End by switching to next task
		TM_SYSTEM_CALL  TM_FGROUP_EXECUTION, TM_RETURN_TO_TM
* ----------------------------------------------------------

* ----------------------------------------------------------
T2_INIT:														
* Task 2 initialization code
* ----------------------------------------------------------
		; Store the task ID and GROUP in TMP to
		; ease further access if necessary.
		move.w	D1, TK_VAR_ID(A0)
		move.w	D2, TK_VAR_GROUP(A0)
		
		; Place the ball coordinates at the center of the
		; screen
		move.w	#TK_SCREEN_WIDTH/2-T2_BALL_RADIUS, T2_VAR_X(A0)
		move.w	#TK_SCREEN_HEIGHT/2-T2_BALL_RADIUS, T2_VAR_Y(A0)
		
		; Init speed vector to (T2_DEFAULT_SPEED,T2_DEFAULT_SPEED)
		move.w	#T2_DEFAULT_SPEED, T2_VAR_SX(A0)
		move.w	#T2_DEFAULT_SPEED, T2_VAR_SY(A0)
		
		; Init to unselected
		move.b	#T2_STATE_UNSELECTED, T2_VAR_STATE(A0)
		
		; End by switching to next task
		TM_SYSTEM_CALL  TM_FGROUP_EXECUTION, TM_RETURN_TO_TM
* ----------------------------------------------------------
		
* ----------------------------------------------------------
T2_UPDATE:														
* Task 2 update task logic
* ----------------------------------------------------------
		; If state is selected, don't move the ball
		cmp.b	#T2_STATE_SELECTED, T2_VAR_STATE(A0)
		beq	.END

		; Check if horizontally colliding with screen
		; boundaries.
		cmp.w	#T2_BALL_RADIUS, T2_VAR_X(A0)
		bls	.XBOUNCE
		cmp.w	#TK_SCREEN_WIDTH-T2_BALL_RADIUS, T2_VAR_X(A0)
		bhs	.XBOUNCE
		
.YCHECK:	; Check if vertically colliding with screen
		; boundaries.
		cmp.w	#T2_BALL_RADIUS, T2_VAR_Y(A0)
		bls	.YBOUNCE
		cmp.w	#TK_SCREEN_HEIGHT-T2_BALL_RADIUS, T2_VAR_Y(A0)
		bhs	.YBOUNCE
		
.KINEMATICS:	; Simple kinematic model: X=X+SX, Y=Y+SY
		move.w	T2_VAR_X(A0), D0
		move.w	T2_VAR_Y(A0), D1
		add.w	T2_VAR_SX(A0), D0
		add.w	T2_VAR_SY(A0), D1
		move.w	D0, T2_VAR_X(A0)
		move.w	D1, T2_VAR_Y(A0)
		
		; That's it!
.END:		rts		

.XBOUNCE:	; X bouncing is just changing the X speed sign.
		neg.w	T2_VAR_SX(A0)
		bra	.YCHECK
		
.YBOUNCE:	; Y bouncing is just changing the Y speed sign
		neg	T2_VAR_SY(A0)
		bra	.KINEMATICS				
* ----------------------------------------------------------

* ----------------------------------------------------------
T2_PLOT:														
* Task 2 drawing stuff
* ----------------------------------------------------------
		; Prepare colors
		TK_SET_PEN	#$00FFFFFF
		
		; If state is unselected, fin red.
		cmp.b	#T2_STATE_SELECTED, T2_VAR_STATE(A0)
		beq	.SEL
		TK_SET_FILL	#$000000FF
		bra	.CONT
		
		; If it is selected, fill in green
.SEL:		TK_SET_FILL	#$0000FF00		

		; Get the ball's center coordinates
.CONT:		move.w	T2_VAR_X(A0), D1
		move.w	T2_VAR_Y(A0), D2		
		
		; Compute bounding box using radius		
		move.w	D1, D3
		move.w	D2, D4
		sub.w	#T2_BALL_RADIUS, D1
		sub.w	#T2_BALL_RADIUS, D2
		add.w	#T2_BALL_RADIUS, D3
		add.w	#T2_BALL_RADIUS, D4
		
		; Draw it
		TK_DRAW_ELLIPSE
		
		; That's it
		rts
* ----------------------------------------------------------

************************************************************
*                            TASK 3                        *
* -------------------------------------------------------- *
* Name       : MOUSE MANAGER                               *
* Description: Polls mouse, stores its state in shared     *
*              memory and prints coordinates.              *
************************************************************

; ==========================================================
; Task 3 constants
; ==========================================================
; TMP offsets
T3_VAR_MOUSE_PRE EQU	4	; Byte

; ==========================================================
; Task 3 functions
; ==========================================================

* ----------------------------------------------------------
T3_TEP:
* Task 3 entry point.
* ----------------------------------------------------------
		; Check if status is "initializing". If so, 
		; execute the initialization code.
		cmp.w	#TM_TCB_STATUS_INIT, D3
		beq	T3_INIT
		
		; Update the task logic
		bsr	T3_UPDATE
		
		; If no time-over allowed, frame-drop		
		TM_SYSTEM_CALL  TM_FGROUP_EXECUTION, TM_FRAME_DROP
		
		; Do graphicap stuff
		bsr	T3_PLOT
		
		; That's it. End by switching to next task
		TM_SYSTEM_CALL  TM_FGROUP_EXECUTION, TM_RETURN_TO_TM
* ----------------------------------------------------------

* ----------------------------------------------------------
T3_INIT:														
* Task 3 initialization code
* ----------------------------------------------------------
		; Store the task ID and GROUP in TMP to
		; ease further access if necessary.
		move.w	D1, TK_VAR_ID(A0)
		move.w	D2, TK_VAR_GROUP(A0)
		
		; Init current mouse state to non-pressed
		clr.b TK_VAR_MOUSE_BUT(A1)
						
		; End by switching to next task
		TM_SYSTEM_CALL  TM_FGROUP_EXECUTION, TM_RETURN_TO_TM
* ----------------------------------------------------------
		
* ----------------------------------------------------------
T3_UPDATE:														
* Task 3 update task logic
* ----------------------------------------------------------
		; Store previous state
		move.b	TK_VAR_MOUSE_BUT(A1), T3_VAR_MOUSE_PRE(A0)
		
		; Query mouse
		clr.b	D1
		move.b	#61, D0
		trap	#15		
		
		; Store X coordinate
		move.w	D1, TK_VAR_MOUSE_X(A1)
		swap	D1
		
		; Store Y coordinate
		move.w	D1, TK_VAR_MOUSE_Y(A1) 
		
		; Store mouse button state
		and.b	#$01, D0	
		move.b	D0, TK_VAR_MOUSE_BUT(A1) 

		; Compute click
		move.b	T3_VAR_MOUSE_PRE(A0), D1
		not.b	D1
		and.b	D0, D1
		and.b	#$01, D1
		move.b	D1, TK_VAR_MOUSE_CLK(A1)
		
		; That's it
		rts		
* ----------------------------------------------------------

* ----------------------------------------------------------
T3_PLOT:														
* Task 3 drawing stuff
* ----------------------------------------------------------
		; Pen color is white
		TK_SET_PEN	#$00FFFFFF
		
		; Fill color is RED if mouse pressed,
		; black otherwise.
		move.b	TK_VAR_MOUSE_BUT(A1), D0
		or.b	D0, D0
		beq	.FILLBLACK
		TK_SET_FILL	#$000000FF
		bra	.CONT
.FILLBLACK:	TK_SET_FILL	#$00000000

		; Locate cursor at 0,0
.CONT:		TK_LOCATE #0, #0
		
		; Get the X and Y coordinates
		move.w	TK_VAR_MOUSE_X(A1), D2
		move.w	TK_VAR_MOUSE_Y(A1), D3
		
		; Store A1
		move.l	A1, A2

		; Print X coordinate
		clr.l	D1
		move.w	D2, D1
		move.b	#3, D0
		trap #15

		; Print the comma		
		move.l	#T3_STR_COMMA, A1
		move.b	#14, D0
		trap	#15
		
		; Print the Y coordinate
		clr.l	D1
		move.w	D3, D1
		move.b	#3, D0
		trap #15
		
		; Restore A1
		move.l	A2, A1
		
		; That's it
		rts
* ----------------------------------------------------------

; ==========================================================
; Task 3 strings
; ==========================================================
T3_STR_COMMA:	dc.b	', ',0
		ds.w	0
		
************************************************************
*                            TASK 4                        *
* -------------------------------------------------------- *
* Name       : KEYBOARD MANAGER                            *
* Description: Checks for SPACE keypress and stores it in  *
*              shared memory.
************************************************************

; ==========================================================
; Task 4 constants
; ==========================================================
; TMP offsets
T4_VAR_SPC_PRE	EQU	4	; Byte
T4_VAR_M_PRE	EQU	5	; Byte

; ==========================================================
; Task 4 functions
; ==========================================================

* ----------------------------------------------------------
T4_TEP:
* Task 4 entry point.
* ----------------------------------------------------------
		; Check if status is "initializing". If so, 
		; execute the initialization code.
		cmp.w	#TM_TCB_STATUS_INIT, D3
		beq	T4_INIT
		
		; Update the task logic
		bsr	T4_UPDATE
		
		; If no time-over allowed, frame-drop		
		TM_SYSTEM_CALL  TM_FGROUP_EXECUTION, TM_FRAME_DROP
		
		; Do graphical stuff
		bsr	T4_PLOT
		
		; That's it. End by switching to next task
		TM_SYSTEM_CALL  TM_FGROUP_EXECUTION, TM_RETURN_TO_TM
* ----------------------------------------------------------

* ----------------------------------------------------------
T4_INIT:														
* Task 4 initialization code
* ----------------------------------------------------------
		; Store the task ID and GROUP in TMP to
		; ease further access if necessary.
		move.w	D1, TK_VAR_ID(A0)
		move.w	D2, TK_VAR_GROUP(A0)
		
		; Initialize to non-pressed
		clr.l	TK_VAR_SPC_PRESS(A1)
		clr.l	TK_VAR_M_PRESS(A1)
								
		; End by switching to next task
		TM_SYSTEM_CALL  TM_FGROUP_EXECUTION, TM_RETURN_TO_TM
* ----------------------------------------------------------
		
* ----------------------------------------------------------
T4_UPDATE:														
* Task 4 update task logic
* ----------------------------------------------------------
		; Update previous
		move.b	TK_VAR_SPC_PRESS(A1), T4_VAR_SPC_PRE(A0)
		move.b	TK_VAR_M_PRESS(A1), T4_VAR_M_PRE(A0)		

		; Check space and M
		move.b	#19, D0
		move.l	#'M'<<24+'M'<<16+' '<<8+' ',D1
		trap	#15		
		move.l	D1, D2
		swap 	D2		
		
		; Store space
		move.b	D1, TK_VAR_SPC_PRESS(A1)
		
		; Compute space click
		move.b	T4_VAR_SPC_PRE(A0), D0
		not.b	D0
		and.b	D0, D1
		move.b	D1, TK_VAR_SPC_CLK(A1)
		
		; Store M
		move.b	D2, TK_VAR_M_PRESS(A1)
		
		; Compute M click
		move.b	T4_VAR_M_PRE(A0), D0
		not.b	D0
		and.b	D0, D2
		move.b	D2, TK_VAR_M_CLK(A1)		

		; That's it
.END:		rts		
* ----------------------------------------------------------

* ----------------------------------------------------------
T4_PLOT:														
* Task 4 drawing stuff
* ----------------------------------------------------------
		move.l	A1, A2
		; Check if space is pressed
		move.b	TK_VAR_SPC_PRESS(A1), D0
		or.b	D0, D0
		beq	.CONT
		
		; Print the string
		TK_SET_PEN #$00FFFFFF
		TK_SET_FILL #$00FF0000		
		TK_LOCATE #0, #1
		move.l	#T4_STR_SPACE, A1
		move.b	#14, D0
		trap	#15
		move.l	A2, A1
		
		; Check if M is pressed		
.CONT:		move.b	TK_VAR_M_PRESS(A1), D0
		or.b	D0, D0
		beq	.END

		; Print the string
		TK_SET_PEN #$00FFFFFF
		TK_SET_FILL #$0000FF00		
		TK_LOCATE #0, #2
		move.l	#T4_STR_M, A1
		move.b	#14, D0
		trap	#15	
		move.l	A2, A1	
		
		; That's it!		
.END:		rts
* ----------------------------------------------------------

; ==========================================================
; Task 4 strings
; ==========================================================
T4_STR_SPACE:	dc.b	'SPACE PRESSED',0
T4_STR_M:	dc.b	'M PRESSED',0
		ds.w	0

************************************************************
*                            TASK 5                        *
* -------------------------------------------------------- *
* Name       : SPAWNER                                     *
* Description: Creates a new ball tasks when SPACE is      *
*              clicked.
************************************************************

; ==========================================================
; Task 5 functions
; ==========================================================

* ----------------------------------------------------------
T5_TEP:
* Task 5 entry point.
* ----------------------------------------------------------
		; Check if status is "initializing". If so, 
		; execute the initialization code.
		cmp.w	#TM_TCB_STATUS_INIT, D3
		beq	T5_INIT
		
		; Update the task logic
		bsr	T5_UPDATE
		
		; If no time-over allowed, frame-drop		
		TM_SYSTEM_CALL  TM_FGROUP_EXECUTION, TM_FRAME_DROP
		
		; Do graphical stuff
		bsr	T5_PLOT
		
		; That's it. End by switching to next task
		TM_SYSTEM_CALL  TM_FGROUP_EXECUTION, TM_RETURN_TO_TM
* ----------------------------------------------------------

* ----------------------------------------------------------
T5_INIT:														
* Task 5 initialization code
* ----------------------------------------------------------
		; Store the task ID and GROUP in TMP to
		; ease further access if necessary.
		move.w	D1, TK_VAR_ID(A0)
		move.w	D2, TK_VAR_GROUP(A0)
										
		; End by switching to next task
		TM_SYSTEM_CALL  TM_FGROUP_EXECUTION, TM_RETURN_TO_TM
* ----------------------------------------------------------
		
* ----------------------------------------------------------
T5_UPDATE:														
* Task 5 update task logic
* ----------------------------------------------------------
		; Check SPACE click
		move.b	TK_VAR_SPC_CLK(A1), D0
		or.b	D0, D0
		beq	.CONT
		
		; If clicked, create new ball
		lea	T2_TEP, A0
		move.w	#TK_GROUP_BALL, D1
		TM_SYSTEM_CALL  TM_FGROUP_BASIC, TM_ADD_TASK
		
.CONT:		; Check M clicked
		move.b	TK_VAR_M_CLK(A1), D0
		or.b	D0, D0
		beq	.CONT2

		; If clicked, delete all tasks in the ball group
		move.w	#TK_GROUP_BALL, D1
		TM_SYSTEM_CALL  TM_FGROUP_BASIC, TM_REMOVE_TASK_GROUP

		
.CONT2:		; Check if mouse is inside a ball
		; First, store TMP
		move.l	A0, A3	; Current task TMP
		
		; Get first task info
		TM_SYSTEM_CALL  TM_FGROUP_INFO, TM_FIRST_TASK_INFO
		
		; Is it the last one?
.LOOP:		cmp.l	#$FFFFFFFF, A2
		beq	.END
		
		; Is it in the ball group?
		cmp.w	#TK_GROUP_BALL, D2
		bne	.NEXT
		
		; Is it running?
		cmp.w	#TM_TCB_STATUS_RUN, D3
		bne	.NEXT
		
		; This task is a running ball. Let's check coordinates		
		move.w	TK_VAR_MOUSE_X(A1), D4
		
		; Substract MouseX-BallX
		sub.w	T2_VAR_X(A0), D4		
		
		; Next, compute the absolute value of the difference
		btst	#15, D4
		beq	.POSX
		neg.w	D4
		
		; Check if the absolute value is below the radius
.POSX:		cmp.w	#T2_BALL_RADIUS, D4

		; If not, check next task
		bgt	.NEXT
		
		; If so, do the same with the Y coordinate
		move.w	TK_VAR_MOUSE_Y(A1), D4
		sub.w	T2_VAR_Y(A0), D4
		btst	#15, D4
		beq	.POSY
		neg.w	D4
.POSY:		cmp.w	#T2_BALL_RADIUS, D4
		bgt	.NEXT

		; So the ball is inside. If mouse is pressed
		move.b	TK_VAR_MOUSE_BUT(A1), D0
		or.b	D0, D0
		beq	.CONT4
		
		; And the ball is selected
		move.b	T2_VAR_STATE(A0), D0
		cmp.b	#T2_STATE_SELECTED, T2_VAR_STATE(A0)
		bne	.CONT3
		
		; Remove it
		move.w	TK_VAR_ID(A0), D1
		TM_SYSTEM_CALL  TM_FGROUP_BASIC, TM_REMOVE_TASK
		
		bra	.NEXT
				
.CONT3:		; If the mouse is pressed but the ball is not selected,
		; put it to sleep
		TM_SYSTEM_CALL  TM_FGROUP_EXECUTION, TM_SLEEP_TASK
		
		bra	.NEXT		

		; If the mouse is not pressed, select the ball
.CONT4:		move.b	#T2_STATE_SELECTED, T2_VAR_STATE(A0)		
		
		; Go to the next one
.NEXT:		TM_SYSTEM_CALL  TM_FGROUP_INFO, TM_NEXT_TASK_INFO

		bra	.LOOP		
			
		; That's it
.END:		move.l	A3, A0
		rts		
* ----------------------------------------------------------

* ----------------------------------------------------------
T5_PLOT:														
* Task 5 drawing stuff
* ----------------------------------------------------------
		; Nothing to do right now
.END:		rts
* ----------------------------------------------------------




*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~8~
