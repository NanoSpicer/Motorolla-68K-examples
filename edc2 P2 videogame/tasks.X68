*-----------------------------------------------------------
* Program    : Medium complexity tasks ready to be run with TaskManager
*              installed. See taskmanager.X68 for more info.
* Written by : Miquel Àngel Román Colom. pr2_gr01
* Date       : 12-Gen-2016
* Description: Videogame. Snake.
* Task list  : 
*                -> T0_START SCREEN
*                -> T1_DOUBLE BUFFER
*                -> T2_KEYBOARD
*                -> T3_COIN/TOKEN/FRUIT
*                -> T4_SCORE
*                -> T5_SNAKEY
*                -> T6_LOSS MENU
*                -> T7_WINNING MENU
*
* Interaction: Snake interacts with a coin/token which is 
*              like the apple or whatever from the original
*              game. 
*              The objective is to get as many "tokens" as
*              possible. If you get 15 you beat
*              the game.
*              
*              While you're getting those tokens snakey grows
*
*-----------------------------------------------------------
	
************************************************************
*                     COMMON CONSTANTS                     *
************************************************************

; OTHER

TK_SNAKE_BDY_RAD        EQU 20
TK_WIN                  EQU 20
; Screen-related constants
TK_SCREEN_WIDTH	EQU	640
TK_SCREEN_HEIGHT EQU	480

; Task groups
TK_GROUP_MENU	        EQU	0
TK_GROUP_DOUBLEBUFFER   EQU	1
TK_GROUP_KEYBOARD       EQU	2
TK_GROUP_SNAKE          EQU     3
TK_GROUP_TOKEN          EQU     4
TK_GROUP_SCORE          EQU     5

; General-purpose TMP offsets
TK_ID_W                EQU	0	; Word
TK_GROUP_W             EQU	2	; Word

; SMP offsets
TK_COIN_X      EQU 0   ; WORD
TK_COIN_Y      EQU 2   ; WORD

TK_SNAKE_X      EQU 4  ; WORD
TK_SNAKE_Y      EQU 6  ; WORD

TK_LEFT_BUT     EQU 8   ; BYTE
TK_UP_BUT       EQU 9   ; BYTE
TK_RIGHT_BUT    EQU 10  ; BYTE
TK_DOWN_BUT     EQU 11  ; BYTE

TK_SNAKE_BDY_TMP        EQU 20 ; LONG 

TK_P_BUT                EQU 12  ; BYTE
TK_GAME_STATE           EQU 13  ; BYTE
TK_GAME_PRESTATE        EQU 14  ; BYTE
TK_COIN_INDEX           EQU 15  ; BYTE
TK_SCORE                EQU 16  ; WORD

TK_LAST_SCORE           EQU 18  ; WORD

*************************************************************
*                    Coin spawn points                      *
*************************************************************

* Random coordinates to spawn the coin/token/apple on.
TK_COIN_COORD_X DC.W 500, 140, 420, 260, 260, 460, 420, 20, 580, 220
                DC.W 580, 140, 180, 60, 340, 260, 500, 420, 500, 100
                DC.W 60, 340, 500, 180, 460, 620, 580, 540, 620, 540
                DC.W 460, 540, 580, 20, 540, 180, 20, 340, 60, 180, 60
                DC.W 420, 500, 180, 420, 540, 380, 620, 420, 220, 60, 460
                DC.W 420, 100, 380, 620, 460, 380, 260, 100, 580, 460, 340
                DC.W 260, 380, 300, 620, 260, 340, 140, 180, 420, 60, 220, 580
                DC.W 100, 620, 260, 220, 220, 260, 220, 220, 540, 20, 180, 540
                DC.W 220, 220, 340, 260, 20, 300, 20, 100, 300, 180, 220, 140, 300
                DC.W 500, 140, 340, 540, 420, 140, 580, 620, 380, 500, 300, 60, 580
                DC.W 620, 140, 620, 380, 140, 340, 540, 60, 140, 260, 300, 620, 380
                DC.W 100, 420, 580, 460, 540, 260, 580, 380, 380, 100, 100, 20, 460
                DC.W 20, 180, 380, 100, 420, 300, 60, 580, 180, 300, 100, 540, 380
                DC.W 220, 20, 100, 620, 500, 300, 500, 340, 20, 500, 500, 180, 140
                DC.W 60, 340, 60, 460, 20, 460, 100, 300, 460, 340, 300, 60, 140, 20
                DC.W 300, 460, 140, 500, 540, 580, 380, 260, 620, 220, 340, 420, 180
                
TK_COIN_COORD_Y DC.W 380, 420, 140, 340, 60, 300, 60, 20, 100, 340, 420, 460, 460, 380
                DC.W 460, 260, 140, 180, 20, 60, 260, 100, 260, 340, 140, 340, 300, 180
                DC.W 300, 220, 260, 260, 140, 380, 140, 100, 100, 260, 340, 220, 460, 220
                DC.W 340, 420, 380, 340, 20, 260, 260, 180, 180, 180, 340, 380, 140, 60, 380
                DC.W 100, 140, 420, 460, 20, 380, 460, 220, 100, 20, 220, 20, 380, 380, 300, 300
                DC.W 20, 380, 460, 220, 20, 420, 260, 180, 300, 460, 380, 460, 180, 100, 100, 220
                DC.W 220, 300, 260, 300, 300, 140, 460, 20, 60, 100, 420, 60, 220, 60, 420, 20, 300
                DC.W 220, 100, 300, 300, 140, 60, 340, 140, 140, 420, 460, 180, 300, 300, 20, 340, 380
                DC.W 180, 460, 260, 300, 420, 20, 60, 60, 100, 180, 60, 180, 180, 20, 220, 220, 60, 60, 420
                DC.W 100, 100, 380, 220, 60, 260, 60, 220, 20, 380, 380, 420, 340, 380, 460, 220, 100, 340, 180
                DC.W 220, 420, 140, 20, 100, 140, 140, 100, 340, 460, 260, 20, 420, 420, 260, 420, 60, 140, 340
                DC.W 340, 260, 180, 460, 260, 340, 420, 180, 140, 180, 460, 300

*************************************************************

************************************************************
*                GENERAL PURPOSE SUBROUTINES               *
************************************************************

*-----------------------------------------------------------
* Subroutine to get a TCB that has the same group as the 
* passed parameter                       
* Parameters: D4.W: TASK'S GROUP    

* RETURNS  : A2 = TASK'S TH.
*-----------------------------------------------------------
TK_LOOK_FOR_TK_GROUP:
                MOVEM.L D0-D4/A0-A1,-(A7)
                TM_SYSTEM_CALL TM_FGROUP_INFO, TM_FIRST_TASK_INFO
                
                .loop:
                CMP.L #$FFFFFFFF, A2
                BEQ .notFound
		
		CMP.W D2,D4
		BEQ .found
		TM_SYSTEM_CALL TM_FGROUP_INFO, TM_NEXT_TASK_INFO
		BRA .loop
		
		.found:
		.notFound:
		
		MOVEM.L (A7)+, D0-D4/A0-A1
		RTS
*-----------------------------------------------------------

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
TK_ENABLE_DOUBLEBUFFER MACRO
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
* Macro to set font 
* Parameters: \1: Color in format $00BBGGRR
*             \2: Font type. Bold, italic, etc.
* Modifies  : D0, D1
*-----------------------------------------------------------		
TK_SET_FONT	MACRO
		MOVE.L	\1, D1
		MOVE.L  \2,D2
		MOVE.B	#21, D0
		TRAP	#15
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
* Macro to print string at @\1
* Parameters: \1: @string
* Modifies  : D0, D1
*-----------------------------------------------------------
TK_PRINT_STRING	MACRO		
		MOVE.B #14,D0
		MOVE.L \1,A1
		TRAP #15
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

*-----------------------------------------------------------
* Macro print a string and a number
* Parameters: \1: String, \2 number
* 
* Modifies  : D0, D1, A1
*-----------------------------------------------------------
TK_STR_NUM	MACRO
                MOVE.L \1,A1
                MOVE.L \2,D1	
		MOVE.W #17,D0
		TRAP #15
		ENDM
*-----------------------------------------------------------


*-----------------------------------------------------------
* Macro print a string and a number
* Parameters: \1: LX, \2 RX, \3 UY, \4LY
* 
* Modifies  : D0, D1, D2, D3, D4
*-----------------------------------------------------------
TK_DRAW_RECT	MACRO
                
                MOVE.W \1,D1
                MOVE.W \2,D3
                MOVE.W \3,D2
                MOVE.W \4,D4
                MOVE.B #87,D0
                TRAP #15
                
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
		MOVE.L #1,D1
		TM_SYSTEM_CALL  TM_FGROUP_CONFIG, TM_DEFINE_TIME
		
; Activate time-over detection
		TM_SYSTEM_CALL  TM_FGROUP_CONFIG, TM_PREVENT_TIME_OVER
		
; Add menu task
                LEA.L T0_TEP,A0
                MOVE.W #TK_GROUP_MENU, D1 ; the visual menu start
                TM_SYSTEM_CALL TM_FGROUP_BASIC, TM_ADD_TASK

; ADD menu_SNAKE TASK
                LEA.L T5_TEP,A0
                MOVE.W #TK_GROUP_MENU,D1        ; MENU snake. It just moves.
                TM_SYSTEM_CALL TM_FGROUP_BASIC, TM_ADD_TASK
; Add keyboard task
                LEA.L T2_TEP,A0
                MOVE.W #TK_GROUP_KEYBOARD, D1
		TM_SYSTEM_CALL TM_FGROUP_BASIC, TM_ADD_TASK
; Add double buffer task
		LEA.L	T1_TEP, A0		         ; TEP
		MOVE.W	#TK_GROUP_DOUBLEBUFFER, D1	 ; GROUP
		TM_SYSTEM_CALL  TM_FGROUP_BASIC, TM_ADD_TASK
; Add score task and put it to sleep
                
                LEA.L T4_TEP,A0
                MOVE.W #TK_GROUP_SCORE, D1
                TM_SYSTEM_CALL  TM_FGROUP_BASIC, TM_ADD_TASK
                
                MOVE.W #TK_GROUP_SCORE,D4
                BSR TK_LOOK_FOR_TK_GROUP
                TM_SYSTEM_CALL TM_FGROUP_EXECUTION, TM_SLEEP_TASK

		rts
* ----------------------------------------------------------



* ---------------------------------------------------------------
*                           Task 0.                             *
* ---------------------------------------------------------------
* Description: Start screen. Expect [enter] button to start the 
*              Game
* -------------------  TASK 0 VARIABLES  -------------------
* TASK 0 STRINGS. START SCREEN "MENU".
T0_STRING_E DC.B '¡Press [ENTER] to start the SNAKEY the snake game!',0
T0_STRING_P DC.B '¡Eat as much as you can! :>',0
T0_STRING_0 DC.B ' ________   ___   _       ____       __    ___  _______  ___   ___',0
T0_STRING_1 DC.B '/  _____/  |   \ | |     / __ \     |  |  /  / |  ____/  \  \ /  /',0
T0_STRING_2 DC.B '\  \____   | |\ \| |    / /__\ \    |  |_/  /  | |__      \  V  / ',0
T0_STRING_3 DC.B ' \____  \  | | \   |   /  ____  \   |   _  \   |  __|      \   /  ',0
T0_STRING_4 DC.B '_____/  /  | |  \  |  /  /    \  \  |  | \  \  | |____     |   |  ',0
T0_STRING_5 DC.B '\______/   |_|   \_| /__/      \__\ |__|  \__\ |______\    |___|  ',0
            DS.W 0
            
* ----------------------------------------------------------
T0_TEP:
		CMP.W #TM_TCB_STATUS_INIT,D3
		BEQ T0_INIT
		
		; NOTHING TO UPDATE
		; JUST A VISUAL MENU
		TM_SYSTEM_CALL  TM_FGROUP_EXECUTION, TM_FRAME_DROP
		
		BSR T0_PRINT
		
		
		TM_SYSTEM_CALL TM_FGROUP_EXECUTION, TM_RETURN_TO_TM

* ----------------------------------------------------------

* ----------------------------------------------------------
T0_INIT:
*       TASK0_INITIALIZER: INITS THE TASK.
* ----------------------------------------------------------
        
        MOVE.W D1,TK_ID_W(A0)
        MOVE.W D2,TK_GROUP_W(A0)
                
        TM_SYSTEM_CALL TM_FGROUP_EXECUTION, TM_RETURN_TO_TM
        
* ----------------------------------------------------------

* ----------------------------------------------------------
T0_PRINT:
*       TASK0_PRINT. PRINTS START MENU
* ----------------------------------------------------------
        
        MOVEM.L D0-D7/A0-A6,-(A7)

        
        TK_SET_FONT #$0000FF00, #0
        TK_SET_FILL #$00000000
        
        
        TK_LOCATE #7, #8
        TK_PRINT_STRING #T0_STRING_0
        
        TK_LOCATE #7, #9
        TK_PRINT_STRING #T0_STRING_1
        
        TK_LOCATE #7, #10
        TK_PRINT_STRING #T0_STRING_2
        
        TK_LOCATE #7, #11
        TK_PRINT_STRING #T0_STRING_3
        
        TK_LOCATE #7, #12
        TK_PRINT_STRING #T0_STRING_4
        
        TK_LOCATE #7, #13
        TK_PRINT_STRING #T0_STRING_5
        
        TK_SET_FONT #$000FFFF0, #0
        
        TK_LOCATE #16, #20
        TK_PRINT_STRING #T0_STRING_E
        
        TK_LOCATE #28, #22
        TK_PRINT_STRING #T0_STRING_P
        

        MOVEM.L (A7)+, D0-D7/A0-A6
        RTS
* ----------------------------------------------------------


* ----------------------------------------------------------
*                          Task 1. 
* ----------------------------------------------------------
* Description: Double buffer manager and screen resolution
*              initialization.
* -------------------  TASK 1 VARIABLES  -------------------
* 
            
* ----------------------------------------------------------
T1_TEP:
		CMP.W #TM_TCB_STATUS_INIT,D3
		BEQ T1_INIT
		
		TM_SYSTEM_CALL  TM_FGROUP_EXECUTION, TM_FRAME_DROP
		
		BSR T1_REPAINT
		
		TM_SYSTEM_CALL TM_FGROUP_EXECUTION, TM_RETURN_TO_TM

* ----------------------------------------------------------

* ----------------------------------------------------------
T1_INIT:
*       TASK1_INITIALIZER: INITS THE TASK.
* ----------------------------------------------------------
        
        MOVE.W D1, TM_TCB_ID_W(A0)
        MOVE.W D2, TM_TCB_GROUP_W(A0)
        
        TK_SET_RES      TK_SCREEN_WIDTH, TK_SCREEN_HEIGHT
        TK_SET_WINDOWED
        TK_ENABLE_DOUBLEBUFFER
        
        TM_SYSTEM_CALL TM_FGROUP_EXECUTION, TM_RETURN_TO_TM
        
        
* ----------------------------------------------------------

* ----------------------------------------------------------
T1_REPAINT:
*       REPAINTS THE SCREEN
* ----------------------------------------------------------
        MOVEM.L D0-D1,-(A7)
        
        TK_REPAINT_SCREEN
        TK_CLEAR
        
        MOVEM.L (A7)+,D0-D1
        RTS
* ----------------------------------------------------------


* ----------------------------------------------------------
*                          Task 2. 
* ----------------------------------------------------------
* Description: KEYBOARD
* -------------------  TASK 2 VARIABLES  -------------------
* 
T2_ENTER_B      EQU     4  ; WORD
* ----------------------------------------------------------
T2_TEP:
		CMP.W #TM_TCB_STATUS_INIT,D3
		BEQ T2_INIT
		
		
		BSR T2_UPDATE
		
		; useless?
		TM_SYSTEM_CALL  TM_FGROUP_EXECUTION, TM_FRAME_DROP 
		    ; NOTHING TO PLOT HERE, REALLY....
		
		TM_SYSTEM_CALL TM_FGROUP_EXECUTION, TM_RETURN_TO_TM

* ---------------------------------------------------------- 

* ----------------------------------------------------------
T2_INIT:
*       REPAINTS THE SCREEN
* ----------------------------------------------------------
        MOVE.W D1,TK_ID_W(A0)
        MOVE.W D1,TK_GROUP_W(A0)
        
        MOVE.B #0,T2_ENTER_B(A0)
        
        MOVE.B #0,TK_LEFT_BUT(A1)
        MOVE.B #0,TK_UP_BUT(A1)
        MOVE.B #0,TK_RIGHT_BUT(A1)
        MOVE.B #0,TK_DOWN_BUT(A1)
        MOVE.B #0,TK_GAME_STATE(A1)
        MOVE.B #0,TK_GAME_PRESTATE(A1)
        MOVE.B #0,TK_COIN_INDEX(A1)
        
        MOVE.W #0,TK_SCORE(A1)
        MOVE.W #6,TK_LAST_SCORE(A1) ; in order to force the player 
                                    ; to beat some record
        
        MOVE.B #0,TK_P_BUT(A1)
        TM_SYSTEM_CALL TM_FGROUP_EXECUTION, TM_RETURN_TO_TM
* ----------------------------------------------------------

* ----------------------------------------------------------
T2_UPDATE

*      Description: Updates the enter flag. 
*                  If enter is pressed sleeps all MENU tasks
* ----------------------------------------------------------
        MOVEM.L D0-D7/A0-A6,-(A7)
        
        MOVE.L A0, A3
        CMP.B #$00, TK_GAME_STATE(A1)
        BEQ .MENU
        .arrowsAndP:
                MOVE.W #19,D0
                MOVE.L #$25<<24+$26<<16+$27<<8+$28,D1      ; CHECK ARROWS
                ; LEFT, UP, RIGHT, DOWN
                TRAP #15
                
                MOVE.L D1,TK_LEFT_BUT(A1) ; UP, RIGHT AND DOWN WILL
                                          ; BE UPDATED ASWELL WITH THIS.
                
                MOVE.L #0,D2
                BRA .FINISH     ; if we look at the arrows we don't look at
                                ; the [ENTER] BUTTON
                
        .MENU:
                MOVE.W #19,D0
                MOVE.L #$0D,D1  ; check for carriage return
                TRAP #15
        
                MOVE.B D1,D2 ; COPY
        
                MOVE.B T2_ENTER_B(A0),D0
                NOT.B D0
                AND.B D0,D1
                BEQ .FINISH
        
                        ; PUT TO SLEEP ALL MENU TASKS
                                MOVE.B #$FF, TK_GAME_STATE(A1)
                                
                MOVE.W #TK_GROUP_MENU, D1
                TM_SYSTEM_CALL TM_FGROUP_BASIC, TM_REMOVE_TASK_GROUP
; ADD Counter TASK
*                LEA.L T4_TEP,A0
                MOVE.W #TK_GROUP_SCORE,D4
                BSR TK_LOOK_FOR_TK_GROUP
                TM_SYSTEM_CALL TM_FGROUP_EXECUTION, TM_RESTART_TASK
; ADD COIN TASK
                LEA.L T3_TEP,A0
                MOVE.W #TK_GROUP_TOKEN,D1
                TM_SYSTEM_CALL TM_FGROUP_BASIC, TM_ADD_TASK
; ADD SNAKE TASK

                LEA.L T5_TEP,A0
                MOVE.W #TK_GROUP_SNAKE,D1
                TM_SYSTEM_CALL TM_FGROUP_BASIC, TM_ADD_TASK
                
                        
                        
                        
                .FINISH:
        
                        MOVE.B D2,T2_ENTER_B(A3) ; UPDATE PREVIOUS ENTER STATE
                
                
.END                
                MOVEM.L (A7)+, D0-D7/A0-A6
                        RTS
* ----------------------------------------------------------



* ----------------------------------------------------------
*                          Task 3. 
* ----------------------------------------------------------
* Description: Coin task.
* -------------------  TASK 3 CONSTANTS  -------------------
* 

T3_CRUNCH_PATH  DC.B 'CRUNCH.wav',0
                DS.W 0
T3_COIN_RADIUS  EQU 10  ; COIN RADIUS
* ----------------------------------------------------------
T3_TEP:
		CMP.W #TM_TCB_STATUS_INIT,D3
		BEQ T3_INIT
		
		BSR T3_UPDATE
		
		TM_SYSTEM_CALL  TM_FGROUP_EXECUTION, TM_FRAME_DROP
		
		BSR T3_PLOT     
		
		TM_SYSTEM_CALL TM_FGROUP_EXECUTION, TM_RETURN_TO_TM

* ----------------------------------------------------------

T3_INIT:
*       Description: Inits the task. Assigns the first coordinate to spawn on
* ----------------------------------------------------------

                MOVE.W D1,TK_ID_W(A0)
                MOVE.W D2,TK_GROUP_W(A0)
                
                CLR.W D0
                MOVE.B TK_COIN_INDEX(A1),D0
                MULU.W #2,D0
                
                LEA.L TK_COIN_COORD_X,A2
                ADD.L D0,A2
                
                MOVE.W (A2),D1
                MOVE.W D1, TK_COIN_X(A1)

                
                LEA.L TK_COIN_COORD_Y,A2
                ADD.L D0,A2
                
                MOVE.W (A2),D1
                MOVE.W D1, TK_COIN_Y(A1)
                
                ADDQ.B #1, TK_COIN_INDEX(A1)
                
                TM_SYSTEM_CALL TM_FGROUP_EXECUTION, TM_RETURN_TO_TM
* ----------------------------------------------------------
T3_UPDATE:
*       Description: CHECKS SNAKE'S HEAD COLLISION
* ----------------------------------------------------------

                MOVEM.L D0-D7/A0-A6, -(A7)
                
                MOVE.W TK_COIN_X(A1),D0
                MOVE.W TK_COIN_Y(A1),D1
                
                CMP.W TK_SNAKE_X(A1), D0
                BNE .noCollision
                CMP.W TK_SNAKE_Y(A1), D1
                BNE .noCollision
                
                .collision:
                                
                                
                        ADDQ.W #1, TK_SCORE(A1)
                        
                        CMP.W #TK_WIN,TK_SCORE(A1)
                        BEQ .WIN
                        
                                MOVE.L A1,A2
                                MOVE.W #70,D0
                                LEA.L T3_CRUNCH_PATH,A1
                                TRAP #15
                                MOVE.L A2,A1
  
                        ; INCREASE SNAKE'S BODY.
                                MOVE.L TK_SNAKE_BDY_TMP(A1), A2
                                .sniki:
                                MOVE.W T5_BODY_X(A2), D5
                                
                                CMP.W #$FFFF, D5
                                BEQ .add
                                ADD.L #T5_BODY_OFFSET, A2
                                BRA .sniki
                                
                                .add:
                                MOVE.W #0,T5_BODY_X(A2)
                                MOVE.W #0,T5_BODY_Y(A2)
                                ADD.L #T5_BODY_OFFSET, A2
                                MOVE.W #0,T5_BODY_X(A2)
                                MOVE.W #0,T5_BODY_Y(A2)
                        ;
                        

                        
                        BSR T3_SPAWN   ; checks if the coin can spawn
                        
                        MOVE.W #TK_GROUP_TOKEN, D1
                        TM_SYSTEM_CALL TM_FGROUP_BASIC, TM_REMOVE_TASK_GROUP
                        
                        
                        LEA.L T3_TEP, A0
                        MOVE.W #TK_GROUP_TOKEN, D1
                        TM_SYSTEM_CALL TM_FGROUP_BASIC, TM_ADD_TASK
                        BRA .noCollision
                        .WIN:
                                MOVE.W TK_SCORE(A1),TK_LAST_SCORE(A1)
                                
                                MOVE.W #TK_GROUP_TOKEN, D1
                                TM_SYSTEM_CALL TM_FGROUP_BASIC, TM_REMOVE_TASK_GROUP
                                
*                                MOVE.W #TK_GROUP_SCORE, D1
*                                TM_SYSTEM_CALL TM_FGROUP_BASIC, TM_REMOVE_TASK_GROUP
                                ; sleep score task
                                MOVE.W #TK_GROUP_SCORE,D4
                                BSR TK_LOOK_FOR_TK_GROUP
                                TM_SYSTEM_CALL TM_FGROUP_EXECUTION, TM_SLEEP_TASK
                                
                                MOVE.W #TK_GROUP_SNAKE, D1
                                TM_SYSTEM_CALL TM_FGROUP_BASIC, TM_REMOVE_TASK_GROUP
                                
                                LEA.L T7_TEP, A0
                                MOVE.W #TK_GROUP_MENU, D1
                                TM_SYSTEM_CALL TM_FGROUP_BASIC, TM_ADD_TASK
                                
                                LEA.L T5_TEP, A0
                                MOVE.W #TK_GROUP_MENU, D1
                                TM_SYSTEM_CALL TM_FGROUP_BASIC, TM_ADD_TASK
                                
                                MOVE.B #$00, TK_GAME_STATE(A1)
                                MOVE.B #0, TK_COIN_INDEX(A1)
                .noCollision:
                
                ; COIN BOUNDS UPDATED
                MOVEM.L (A7)+, D0-D7/A0-A6
                RTS
* ----------------------------------------------------------
T3_SPAWN:
*       Description: Ensures an spawn point.
*       moves the index to a position that finds a coordinate
*       that does not belong to the snake head/body
* ----------------------------------------------------------
        MOVEM.L D0-D7/A0-A6,-(A7)

        CLR.L D0
        MOVE.B TK_COIN_INDEX(A1), D0
        CMP.W #192, D0
        BLT .iniStart
        MOVE.B #0, TK_COIN_INDEX(A1)
        MOVE.B #0, D0
                .iniStart:
                MOVE.L TK_SNAKE_BDY_TMP(A1), A4
                
                        ; can I spawn? D7.W as a flag
                .start:
                        CLR.W D7
                        CMP.W #192,D0
                        BNE .moveOn
                        CLR.W D0
                        .moveOn:
                        MULU.W #2, D0
                        LEA.L TK_COIN_COORD_X, A2
                        LEA.L TK_COIN_COORD_Y, A3
                        ADD.L D0, A2
                        ADD.L D0, A3
                        
                        MOVE.W (A2), D2         ; X SPAWN
                        MOVE.W (A3), D3         ; Y SPAWN
                        
                        MOVE.W T5_BODY_X(A4), D4 ; X SNAKE
                        MOVE.W T5_BODY_Y(A4), D5 ; Y SNAKE
                        
                        CMP.W #$FFFF,D4
                        BEQ .finish
                        
                        CMP.W D2,D4
                        BEQ .putFlag
                        AND.B #$00,D7
                        .continue:
                                CMP.W D3,D5
                                BEQ .putFlag2
                                AND.W #$00FF,D7
                        .continue2:
                                CMP.W #$FFFF,D7
                                BEQ .addIndex
                                ADD.L #T5_BODY_OFFSET,A4
                                DIVU.W #2,D0
                                BRA .moveOn
                        .addIndex:
                        CLR.W D7
                        DIVU.W #2,D0
                        ADDQ.B #1,D0
                        MOVE.L TK_SNAKE_BDY_TMP(A1), A4
                        BRA .start
                        .putFlag:
                        OR.B #$FF,D7
                        BRA .continue
                        .putFlag2:
                        OR.W #$FF00,D7
                        BRA .continue2
                .finish:
                DIVU.W #2,D0
                MOVE.B D0,TK_COIN_INDEX(A1)
                
                MOVEM.L (A7)+,D0-D7/A0-A6
                RTS
* ----------------------------------------------------------

T3_PLOT:
*       Description: Inits the task. Assigns a Coordinate
* ----------------------------------------------------------
                MOVEM.L D0-D7/A0-A6,-(A7)
                
                TK_SET_PEN #$00FFFF00
                TK_SET_FILL #$00CC3200
                
                ; D1.W LEFT D2.W TOP D3.W RIGHT D4.W BOTTOM
                MOVE.W TK_COIN_X(A1),D1
                
                CMP.W #$FFFF,D1
                BEQ .nothing
                
                MOVE.W D1,D3
                
                SUB.W #T3_COIN_RADIUS,D1
                ADD.W #T3_COIN_RADIUS,D3
                
                MOVE.W TK_COIN_Y(A1),D2
                
                CMP.W #$FFFF,D2
                BEQ .nothing
                
                MOVE.W D2,D4
                
                SUB.W #T3_COIN_RADIUS,D4
                ADD.W #T3_COIN_RADIUS,D2
                TK_DRAW_ELLIPSE
                
.nothing                
                MOVEM.L (A7)+, D0-D7/A0-A6
                RTS
* ----------------------------------------------------------


* ----------------------------------------------------------
*                          Task 4. 
* ----------------------------------------------------------
* Description: Counter task.
* -------------------  TASK 4 CONSTANTS  -------------------
* 
; OFFSET
T4_STRING       DC.B 'Score: ', 0
* ----------------------------------------------------------
T4_TEP:
		CMP.W #TM_TCB_STATUS_INIT,D3
		BEQ T4_INIT
		
		BSR T4_UPDATE
		
		TM_SYSTEM_CALL  TM_FGROUP_EXECUTION, TM_FRAME_DROP
		
		BSR T4_PLOT     ; NOTHING TO PLOT HERE

		TM_SYSTEM_CALL TM_FGROUP_EXECUTION, TM_RETURN_TO_TM

* ----------------------------------------------------------

T4_INIT:
*       Description: Should init the task to sleeping.
*               It wakes up when enter is pressed in previous
*               tasks
* ----------------------------------------------------------
                MOVE.W D1,TK_ID_W(A0)
                MOVE.W D2,TK_GROUP_W(A0)


                MOVE.W #0, TK_SCORE(A1)
                
                TM_SYSTEM_CALL TM_FGROUP_EXECUTION, TM_RETURN_TO_TM
                
* ----------------------------------------------------------


T4_UPDATE:
*       Description: The counter. Updates from SMP
* ----------------------------------------------------------
                
                ; CHECK GAME STATE
                
                
                RTS
* ----------------------------------------------------------

T4_PLOT:
*       Description: Displays the string and the counter
*                       value.
* ----------------------------------------------------------
                MOVEM.L D0-D7/A0-A6,-(A7)
                
                TK_SET_FONT #$0000FFFF, #0
                TK_SET_FILL #$00000000
                TK_LOCATE #0,#0
                
                MOVE.W TK_SCORE(A1),D0
                TK_STR_NUM #T4_STRING, D0
                
                MOVEM.L (A7)+,D0-D7/A0-A6
                RTS
* ----------------------------------------------------------

* ----------------------------------------------------------
*                          Task 5. 
* ----------------------------------------------------------
* Description: SNAKE TASK.
* -------------------  TASK 5 CONSTANTS  -------------------
* 
; OFFSET
T5_DIRECTION    EQU 4    ; BYTE 
T5_SNAKE_SPEED  EQU 6    ; W

T5_BODY_LIST    EQU 10    ; FIRST THE HEAD, ETC. ETC.
                         ; XCOORD, YCOORD 1 WORD EACHONE
T5_BODY_X       EQU 0
T5_BODY_Y       EQU 2

T5_BODY_OFFSET  EQU 4

T5_SNK_IX       EQU 100
T5_SNK_IY       EQU 460 ; INITIAL POSITIONS

T5_SNK_pX       EQU 180
T5_SNK_pY       EQU 380 ; INITIAL POSITIONS

T5_SNK_EYE_RAD  EQU 3

T5_SNAKE_LEFT   EQU 0
T5_SNAKE_UP     EQU 1
T5_SNAKE_RIGHT  EQU 2
T5_SNAKE_DOWN   EQU 3
T5_SNAKE_VEL    EQU 13 
T5_SNAKE_BDY_RAD     EQU      TK_SNAKE_BDY_RAD ; 15

T5_PUNCH_PATH DC.B 'HIT.wav',0
                DS.W 0
* ----------------------------------------------------------
T5_TEP:
		CMP.W #TM_TCB_STATUS_INIT,D3
		BEQ T5_INIT
		
		CMP.W #TK_GROUP_MENU, TK_GROUP_W(A0)
		BNE .regular
		; menu
		BSR T5_MENU
		BRA .ploty
		.regular:
		BSR T5_UPDATE
		.ploty:
		;TM_SYSTEM_CALL  TM_FGROUP_EXECUTION, TM_FRAME_DROP
		BSR T5_PLOT     ; NOTHING TO PLOT HERE
		
		TM_SYSTEM_CALL TM_FGROUP_EXECUTION, TM_RETURN_TO_TM

* ----------------------------------------------------------


T5_INIT:
*       Description: INITS THE SNAKE
* ----------------------------------------------------------
                MOVE.L A0,-(A7)
                
                MOVE.W D1,TK_ID_W(A0)
                MOVE.W D2,TK_GROUP_W(A0)
                
                MOVE.L #T5_SNAKE_VEL, T5_SNAKE_SPEED(A0) ; SNAKE'S SPEED
                
                MOVE.B #T5_SNAKE_RIGHT, T5_DIRECTION(A0) ; right
                
                MOVE.L A0,A2 ; SAVE
                ; HEAD IX,IY
                ADD.L #T5_BODY_LIST, A0
                
                MOVE.W #T5_SNK_IX, D5
                MOVE.W #T5_SNK_IY, D6
                CMP.W #TK_GROUP_MENU, D2
                BNE .begin
                MOVE.W #T5_SNK_pX, D5
                MOVE.W #T5_SNK_pY, D6
                .begin:
                MOVE.W D5, T5_BODY_X(A0)
                MOVE.W D6, T5_BODY_Y(A0)
                
                MOVE.W D5, TK_SNAKE_X(A1)       ; SMP INIT
                MOVE.W D6, TK_SNAKE_Y(A1)       ; SMP INIT
                
                ; SNAKE = 3 CUBES -> 1HEAD + 2 BODY BLOCKS
                
                ; 1º BODY CUBE
                MOVE.L A0,A2
                ADD.L #T5_BODY_OFFSET,A0
                
                MOVE.W D5,D1
                MOVE.W #T5_SNAKE_BDY_RAD*2,D2
                SUB.W D2,D1
                
                MOVE.W D1,T5_BODY_X(A0)
                MOVE.W T5_BODY_Y(A2), T5_BODY_Y(A0)
                
                ; 2º BODY CUBE
                ADD.L #T5_BODY_OFFSET,A0
                SUB.W D2,D1
                MOVE.W D1,T5_BODY_X(A0)
                MOVE.W T5_BODY_Y(A2), T5_BODY_Y(A0)
                
                ; 3º ENSURE INITIALIZATION.
                ADD.L #T5_BODY_OFFSET,A0
                MOVE.W #$FFFF,T5_BODY_X(A0)
                MOVE.W #$FFFF,T5_BODY_Y(A0)
                
                MOVE.L A2,A0 ; RESTORE 
                
                MOVE.L (A7)+,A0
                MOVE.L A0, TK_SNAKE_BDY_TMP(A1)
                ADD.L #T5_BODY_LIST, TK_SNAKE_BDY_TMP(A1)

                
                TM_SYSTEM_CALL TM_FGROUP_EXECUTION, TM_RETURN_TO_TM
                
* ----------------------------------------------------------

T5_UPDATE:
*       Description: INITS THE SNAKE
* ----------------------------------------------------------
                MOVEM.L D0-D7/A0-A6,-(A7)
                MOVE.L A1,A3
                .delay:
                SUBQ.L #1, T5_SNAKE_SPEED(A0)
                BNE .noDeath
                MOVE.L #T5_SNAKE_VEL, T5_SNAKE_SPEED(A0)
                

                
                ; UPDATE DIRECCIO
                MOVE.B T5_DIRECTION(A0),D0
                
                CMP.B #T5_SNAKE_LEFT,D0
                BEQ .leftRight
                CMP.B #T5_SNAKE_UP,D0
                BEQ .upDown
                CMP.B #T5_SNAKE_RIGHT,D0
                BEQ .leftRight
                CMP.B #T5_SNAKE_DOWN,D0
                BEQ .upDown
                
                .leftRight: ; ignore right and left keys
                        CMP.B #$FF, TK_UP_BUT(A1)
                        BNE .dwn
                        MOVE.B #T5_SNAKE_UP, T5_DIRECTION(A0)
                        BRA .end1
                        .dwn:
                        CMP.B #$FF, TK_DOWN_BUT(A1)
                        BNE .end1
                        MOVE.B #T5_SNAKE_DOWN, T5_DIRECTION(A0)
                        BRA .end1
                .upDown: ; ignore up and down keys
                        CMP.B #$FF, TK_RIGHT_BUT(A1)
                        BNE .lft
                        MOVE.B #T5_SNAKE_RIGHT, T5_DIRECTION(A0)
                        BRA .end1
                        .lft:
                        CMP.B #$FF, TK_LEFT_BUT(A1)
                        BNE .end1
                        MOVE.B #T5_SNAKE_LEFT, T5_DIRECTION(A0)
                        BRA .end1
                .end1:

                ; avança snake
                        CLR.W D0
                        MOVE.B T5_DIRECTION(A0),D0
                        
                        ; EXPECTS A0 TO HAVE TMP
                        ; AND D0 TO HAVE THE DIRECTION
                        BSR T5_MOVE
                

        
                ; colisió snake
                
                ; WHERE IS THE SNAKE POINTING¿?
                ; CHECK IF its eating itself
                
                MOVE.L A0,A2
                ADD.L #T5_BODY_LIST, A2
                        ; GETTING THE HEAD COORD
                        MOVE.W T5_BODY_X(A2), D1
                        MOVE.W T5_BODY_Y(A2), D2
                        
                
                
                .eat:
                        ADD.L #T5_BODY_OFFSET, A2
                        MOVE.W T5_BODY_X(A2), D3
                        CMP.W #$FFFF, D3
                        BEQ .endEat
                        CMP.W D1, D3
                        BNE .eat
                        ; check y point
                        MOVE.W T5_BODY_Y(A2), D4
                        CMP.W D2, D4
                        BEQ .death
                        BRA .eat
                ; bucle 
                .endEat:
                ; PREPARE BORDES
                MOVE.L A0,A2
                ADD.L #T5_BODY_LIST, A2
                        ; GETTING THE HEAD COORD
                        MOVE.W T5_BODY_X(A2), D0
                        MOVE.W T5_BODY_Y(A2), D1
                        
                        MOVE.W D0,D2    ; WE USE A COPY
                        MOVE.W D1,D3    ; IN ORDER TO
                                        ; RESTORE OG
                                        ; VALUES
                ; colisió bordes D0.W = X D1.W = Y
                ;                D2.W = X D3.W = Y

                .checkRight:
                        CMP.W #TK_SCREEN_WIDTH, D2
                        BGT .death
                .checkLeft:
                        CMP.W #0, D2
                        BLT .death
                .checkUp:
                        CMP.W #0, D3
                        BLT .death
                .checkDown:
                        CMP.W #TK_SCREEN_HEIGHT, D3
                        BGT .death
                        BRA .noDeath
                        .death:
                        ; REINIT GAME TASKS
                        
                                MOVE.W #70, D0
                                LEA.L T5_PUNCH_PATH, A1
                                TRAP #15
                                MOVE.W TK_SCORE(A3),D0
                                MOVE.W TK_LAST_SCORE(A3),D1
                                CMP.W D0, D1
                                BGT .noUpdate
                                MOVE.W TK_SCORE(A3),TK_LAST_SCORE(A3)
                                .noUpdate:
                                MOVE.W #TK_GROUP_SNAKE, D1
                                TM_SYSTEM_CALL TM_FGROUP_BASIC, TM_REMOVE_TASK_GROUP
                                MOVE.W #TK_GROUP_TOKEN, D1
                                TM_SYSTEM_CALL TM_FGROUP_BASIC, TM_REMOVE_TASK_GROUP
                                MOVE.W #TK_GROUP_SCORE, D4
                                BSR TK_LOOK_FOR_TK_GROUP
                                TM_SYSTEM_CALL TM_FGROUP_EXECUTION, TM_SLEEP_TASK
                                
                                MOVE.B #$00, TK_GAME_STATE(A3)
                                
                                LEA.L T6_TEP,A0
                                MOVE.W #TK_GROUP_MENU, D1
                                TM_SYSTEM_CALL TM_FGROUP_BASIC, TM_ADD_TASK
                                
                                LEA.L T5_TEP,A0
                                MOVE.W #TK_GROUP_MENU, D1
                                TM_SYSTEM_CALL TM_FGROUP_BASIC, TM_ADD_TASK
                                MOVE.B #$0, TK_COIN_INDEX(A3)
                        .noDeath:
                        ; MOVE ON
                
                MOVEM.L (A7)+, D0-D7/A0-A6
                RTS
* ----------------------------------------------------------
T5_PLOT:
*       Description: DRAWS THE SNAKE
* ----------------------------------------------------------
                MOVEM.L D0-D7/A0-A6,-(A7)
                ; DRAW SNAKE'S HEAD
                MOVE.L A0,D5 ; WE COPY THIS IN ORDER TO USE IT LATER
                
                ADD.L #T5_BODY_LIST,A0
                
                MOVE.W T5_BODY_X(A0),A2
                MOVE.W A2,A3
                
                SUB.L #T5_SNAKE_BDY_RAD,A2
                ADD.L #T5_SNAKE_BDY_RAD,A3
                
                MOVE.W T5_BODY_Y(A0),A4
                MOVE.W A4,A5
                
                SUB.L #T5_SNAKE_BDY_RAD,A4
                ADD.L #T5_SNAKE_BDY_RAD,A5
                
                TK_SET_PEN #$004DFFA6
                TK_SET_FILL #$0000B300
                TK_DRAW_RECT A2, A3, A4, A5
                
                .face:          ; drawing snake's face.
                
                ; BASICALLY EYES
                TK_SET_PEN #$00006600   
                TK_SET_FILL #$00CC6633
                
                MOVE.L D5,A0 ; RESTORING TMP
                
                MOVE.B T5_DIRECTION(A0),D0
                
                ADD.L #T5_BODY_LIST,A0
                
                CMP.B #T5_SNAKE_LEFT,D0
                BEQ .left
                CMP.B #T5_SNAKE_UP,D0
                BEQ .up
                CMP.B #T5_SNAKE_RIGHT,D0
                BEQ .right
                CMP.B #T5_SNAKE_DOWN,D0
                BEQ .down
                
                .left:
                        MOVE.W T5_BODY_X(A0),D1
                        SUBQ #5,D1
                        MOVE.W D1,D3
                        SUB.W #T5_SNK_EYE_RAD*2,D1
                        
                        MOVE.W T5_BODY_Y(A0),D2
                        ADDQ #3,D2
                        MOVE.W D2,D4
                        ADD.W #T5_SNK_EYE_RAD*2,D2
                        
                        ; D1LEFT D2 TOP D3 RIGHT D4 BOTTOM
                        TK_DRAW_ELLIPSE
                        
                        MOVE.W T5_BODY_Y(A0),D2
                        SUBQ #3,D2
                        MOVE.W D2,D4
                        SUB.W #T5_SNK_EYE_RAD*2,D4
                        
                        ; D1LEFT D2 TOP D3 RIGHT D4 BOTTOM
                        TK_DRAW_ELLIPSE
                        BRA .drawRest
                        
                        
                .up:
                        MOVE.W T5_BODY_Y(A0),D2
                        SUBQ #5,D2
                        MOVE.W D2,D4
                        SUB.W #T5_SNK_EYE_RAD*2,D2
                        
                        MOVE.W T5_BODY_X(A0),D1
                        ADDQ #3,D1
                        MOVE.W D1,D3
                        ADD.W #T5_SNK_EYE_RAD*2,D3
                        
                        ; D1LEFT D2 TOP D3 RIGHT D4 BOTTOM  ; RIGHT EYE
                        TK_DRAW_ELLIPSE         
                        
                        MOVE.W T5_BODY_X(A0),D1
                        SUBQ #3,D1
                        MOVE.W D1,D3
                        SUB.W #T5_SNK_EYE_RAD*2,D1
                        
                        ; D1LEFT D2 TOP D3 RIGHT D4 BOTTOM  ; LEFT EYE
                        TK_DRAW_ELLIPSE  
                        BRA .drawRest
                .right:
                        MOVE.W T5_BODY_X(A0),D1
                        ADDQ #5,D1
                        MOVE.W D1,D3
                        ADD.W #T5_SNK_EYE_RAD*2,D3
                        
                        MOVE.W T5_BODY_Y(A0),D2
                        ADDQ #3,D2
                        MOVE.W D2,D4
                        ADD.W #T5_SNK_EYE_RAD*2,D2
                        
                        ; D1LEFT D2 TOP D3 RIGHT D4 BOTTOM
                        TK_DRAW_ELLIPSE
                        
                        MOVE.W T5_BODY_Y(A0),D2
                        SUBQ #3,D2
                        MOVE.W D2,D4
                        SUB.W #T5_SNK_EYE_RAD*2,D4
                        
                        ; D1LEFT D2 TOP D3 RIGHT D4 BOTTOM
                        TK_DRAW_ELLIPSE
                        BRA .drawRest
                .down: 
                        MOVE.W T5_BODY_Y(A0),D2
                        ADDQ #5,D2
                        MOVE.W D2,D4
                        ADD.W #T5_SNK_EYE_RAD*2,D2
                        
                        MOVE.W T5_BODY_X(A0),D1
                        ADDQ #3,D1
                        MOVE.W D1,D3
                        ADD.W #T5_SNK_EYE_RAD*2,D3
                        
                        ; D1LEFT D2 TOP D3 RIGHT D4 BOTTOM  ; RIGHT EYE
                        TK_DRAW_ELLIPSE         
                        
                        MOVE.W T5_BODY_X(A0),D1
                        SUBQ #3,D1
                        MOVE.W D1,D3
                        SUB.W #T5_SNK_EYE_RAD*2,D1
                        
                        ; D1LEFT D2 TOP D3 RIGHT D4 BOTTOM  ; LEFT EYE
                        TK_DRAW_ELLIPSE 

                        BRA .drawRest
                
                .drawRest:
                
                MOVE.L D5,A0 ; RESTORING TMP
                
                ADD.L #T5_BODY_LIST, A0
                ADD.L #T5_BODY_OFFSET, A0
                
                .LOOP:
                        MOVE.W T5_BODY_X(A0),A2
                        CMP.W #$FFFF,A2
                        BEQ .END
                        CMP.W #$0,A2
                        BEQ .END
                        MOVE.W T5_BODY_X(A0),A2
                        MOVE.W A2,A3
                
                        SUB.L #T5_SNAKE_BDY_RAD,A2
                        ADD.L #T5_SNAKE_BDY_RAD,A3
                
                        MOVE.W T5_BODY_Y(A0),A4
                        MOVE.W A4,A5
                
                        SUB.L #T5_SNAKE_BDY_RAD,A4
                        ADD.L #T5_SNAKE_BDY_RAD,A5
                
                        TK_SET_PEN #$004DFFA6
                        TK_SET_FILL #$0000B300
                        TK_DRAW_RECT A2, A3, A4, A5
                        
                        ADD.L #T5_BODY_OFFSET, A0
                        BRA .LOOP
                        
.END                
                        MOVEM.L (A7)+,D0-D7/A0-A6
                        RTS
* ----------------------------------------------------------

T5_MOVE:
*       Pre: D0 holds the direction the snake is going
*       Post: A0 holds the TMP 
*       Modifies: Nothing. All values are restored
*
*       Description: Makes the snake move.
* ----------------------------------------------------------
        MOVEM.L D0-D7/A0-A6,-(A7)
        
        ADD.L #T5_BODY_LIST, A0
        
        MOVE.L A0, A3 ; I'LL NEED THAT VALUE LATER
        
        MOVE.W T5_BODY_X(A0), D1        ; HEAD X
        MOVE.W T5_BODY_Y(A0), D2        ; HEAD Y
        
        .LOOPY:
                ADD.L #T5_BODY_OFFSET, A0
                
                MOVE.W T5_BODY_X(A0), D3
                CMP.W #$FFFF,D3
                BEQ .finish
                MOVE.W T5_BODY_Y(A0), D4
                CMP.W #$FFFF,D4
                BEQ .finish
                MOVE.W D1, T5_BODY_X(A0)
                MOVE.W D2, T5_BODY_Y(A0)
                
                MOVE.W D3,D1
                MOVE.W D4,D2
                
                BRA .LOOPY
        .finish:
                MOVE.W #$FFFF, T5_BODY_Y(A0)
                MOVE.W #$FFFF, T5_BODY_Y(A0)
                ; in order to mark the final of the snake
                
        ; FINALLY... MOVE SNAKES HEAD
        
        MOVE.L A3, A0
        
        CMP.B #T5_SNAKE_LEFT,D0
        BEQ .lefty
        CMP.B #T5_SNAKE_UP,D0
        BEQ .upy
        CMP.B #T5_SNAKE_RIGHT,D0
        BEQ .righty
        CMP.B #T5_SNAKE_DOWN,D0
        BEQ .downy
        
        .lefty:
                SUB.W #T5_SNAKE_BDY_RAD*2, T5_BODY_X(A0)
                BRA .end2
        .upy:
                SUB.W #T5_SNAKE_BDY_RAD*2, T5_BODY_Y(A0)
                BRA .end2
        .righty:
                ADD.W #T5_SNAKE_BDY_RAD*2, T5_BODY_X(A0)
                BRA .end2
        .downy:
                ADD.W #T5_SNAKE_BDY_RAD*2, T5_BODY_Y(A0)
                BRA .end2
         
         
         .end2:
         
        MOVE.W T5_BODY_X(A0), TK_SNAKE_X(A1)
        MOVE.W T5_BODY_Y(A0), TK_SNAKE_Y(A1)
        
        MOVEM.L (A7)+,D0-D7/A0-A6      
                RTS
* ----------------------------------------------------------


* ----------------------------------------------------------

T5_MENU:
*       Description: INITS THE SNAKE
* ----------------------------------------------------------
                MOVEM.L D0-D7/A0-A6,-(A7)
                
                MOVE.L A0,A2
                
                SUBQ.L #1, T5_SNAKE_SPEED(A0)
                BNE .delay
                MOVE.L #T5_SNAKE_VEL, T5_SNAKE_SPEED(A0)
                
                ; update direccio
                MOVE.B T5_DIRECTION(A0),D0
                
                ADD.L #T5_BODY_LIST, A2
                MOVE.W T5_BODY_X(A2), D1
                MOVE.W T5_BODY_Y(A2), D2
                
                CMP.B #T5_SNAKE_LEFT,D0
                BEQ .LEFT1
                CMP.B #T5_SNAKE_UP,D0
                BEQ .UP1
                CMP.B #T5_SNAKE_RIGHT,D0
                BEQ .RIGHT1
                CMP.B #T5_SNAKE_DOWN,D0
                BEQ .DOWN1
                
                .LEFT1:
                        CMP.W #60, D1
                        BNE .end1
                        MOVE.B #T5_SNAKE_DOWN, T5_DIRECTION(A0)
                        BRA .end1
                .UP1:
                        CMP.W #260, D2
                        BNE .end1
                        MOVE.B #T5_SNAKE_LEFT, T5_DIRECTION(A0)
                        BRA .end1
                .RIGHT1:
                        CMP.W #580, D1
                        BNE .end1
                        MOVE.B #T5_SNAKE_UP, T5_DIRECTION(A0)
                        BRA .end1
                .DOWN1:
                        CMP.W #T5_SNK_pY, D2
                        BNE .end1
                        MOVE.B #T5_SNAKE_RIGHT, T5_DIRECTION(A0)
                        BRA .end1
                .end1:
                
                ; avança snake
                        CLR.W D0
                        MOVE.B T5_DIRECTION(A0),D0
                        
                        ; EXPECTS A0 TO HAVE TMP
                        ; AND D0 TO HAVE THE DIRECTION
                        BSR T5_MOVE
                
                        .delay:                
        MOVEM.L (A7)+,D0-D7/A0-A6   
                RTS
* ----------------------------------------------------------

* ---------------------------------------------------------------
*                           Task 6.                             *
* ---------------------------------------------------------------
* Description: Lose screen. Expect [enter] button to restart the 
*              Game
* -------------------  TASK 6 VARIABLES  -------------------
* TASK 6 STRINGS. START SCREEN "MENU".
T6_STRING_E DC.B '¡Press [ENTER] to RETRY! (NO CHARGE HEHE)',0
T6_STRING_P DC.B 'PFFFT! Improve this: ',0
T6_STRING_0 DC.B ' ________   ___   _       ____       __    ___  _______  ___   ___',0
T6_STRING_1 DC.B '/  _____/  |   \ | |     / __ \     |  |  /  / |  ____/  \  \ /  /',0
T6_STRING_2 DC.B '\  \____   | |\ \| |    / /__\ \    |  |_/  /  | |__      \  V  / ',0
T6_STRING_3 DC.B ' \____  \  | | \   |   /  ____  \   |   _  \   |  __|      \   /  ',0
T6_STRING_4 DC.B '_____/  /  | |  \  |  /  /    \  \  |  | \  \  | |____     |   |  ',0
T6_STRING_5 DC.B '\______/   |_|   \_| /__/      \__\ |__|  \__\ |______\    |___|  ',0

T6_LOSE_0 DC.B '    _    __    ____  _____ __________     __',0
T6_LOSE_1 DC.B '   (_)  / /   / __ \/ ___// ____/ __ \   / /',0
T6_LOSE_2 DC.B '  / /  / /   / / / /\__ \/ __/ / /_/ /  / / ',0
T6_LOSE_3 DC.B ' / /  / /___/ /_/ /___/ / /___/ _,  /  /_/',0
T6_LOSE_4 DC.B '/_/  /_____/\____/_____/_____/_/  \_\  (_)',0

T6_SONG_PATH DC.B 'loss.wav',0
            DS.W 0
            

            
* ----------------------------------------------------------
T6_TEP:
		CMP.W #TM_TCB_STATUS_INIT,D3
		BEQ T6_INIT
		
		; NOTHING TO UPDATE
		; JUST A VISUAL MENU
		TM_SYSTEM_CALL  TM_FGROUP_EXECUTION, TM_FRAME_DROP
		BSR T6_PRINT
		
		
		TM_SYSTEM_CALL TM_FGROUP_EXECUTION, TM_RETURN_TO_TM

* ----------------------------------------------------------

* ----------------------------------------------------------
T6_INIT:
*       TASK0_INITIALIZER: INITS THE TASK.
* ----------------------------------------------------------
        
        MOVE.W D1,TK_ID_W(A0)
        MOVE.W D2,TK_GROUP_W(A0)
        
        
        MOVE.L A1, -(A7)
        
        MOVE.W #70,D0
        LEA.L T6_SONG_PATH, A1
        TRAP #15
        
        MOVE.L (A7)+,A1
                
        TM_SYSTEM_CALL TM_FGROUP_EXECUTION, TM_RETURN_TO_TM
        
* ----------------------------------------------------------

* ----------------------------------------------------------
T6_PRINT:
*       TASK0_PRINT. PRINTS START MENU
* ----------------------------------------------------------
        MOVEM.L D0-D7/A0-A6,-(A7)
        MOVE.L A1, A2
        
        
        ; PRINT LOSE
        TK_SET_FONT #$00FF0000, #0
        TK_SET_FILL #$00000000
        
        TK_LOCATE #18, #2
        TK_PRINT_STRING #T6_LOSE_0
        
        TK_LOCATE #18, #3
        TK_PRINT_STRING #T6_LOSE_1
        
        TK_LOCATE #18, #4
        TK_PRINT_STRING #T6_LOSE_2
        
        TK_LOCATE #18, #5
        TK_PRINT_STRING #T6_LOSE_3
        
        TK_LOCATE #18, #6
        TK_PRINT_STRING #T6_LOSE_4

        
        
        TK_SET_FONT #$0000FF00, #0
        TK_SET_FILL #$00000000
        TK_LOCATE #7, #9
        TK_PRINT_STRING #T6_STRING_0
        
        TK_LOCATE #7, #10
        TK_PRINT_STRING #T6_STRING_1
        
        TK_LOCATE #7, #11
        TK_PRINT_STRING #T6_STRING_2
        
        TK_LOCATE #7, #12
        TK_PRINT_STRING #T6_STRING_3
        
        TK_LOCATE #7, #13
        TK_PRINT_STRING #T6_STRING_4
        
        TK_LOCATE #7, #14
        TK_PRINT_STRING #T6_STRING_5
        
        
        TK_SET_FONT #$000FFFF0, #0
        
        TK_LOCATE #28, #20
        MOVE.W TK_LAST_SCORE(A2), D5
        TK_STR_NUM #T6_STRING_P, D5
        
        TK_LOCATE #21, #22
        TK_PRINT_STRING #T6_STRING_E
        
        
        MOVEM.L (A7)+,D0-D7/A0-A6
        
        RTS
* ----------------------------------------------------------






* ---------------------------------------------------------------
*                           Task 7.                             *
* ---------------------------------------------------------------
* Description: Winning screen. Expect [enter] button to restart the 
*              Game
* -------------------  TASK 6 VARIABLES  -------------------
* TASK 6 STRINGS. START SCREEN "MENU".
T7_STRING_E DC.B '¡Press [ENTER] to RETRY! (YOU OWE ME A PENNY)',0
T7_STRING_P DC.B 'Good job, bobby! You have reached the top: ',0
T7_STRING_0 DC.B ' ________   ___   _       ____       __    ___  _______  ___   ___',0
T7_STRING_1 DC.B '/  _____/  |   \ | |     / __ \     |  |  /  / |  ____/  \  \ /  /',0
T7_STRING_2 DC.B '\  \____   | |\ \| |    / /__\ \    |  |_/  /  | |__      \  V  / ',0
T7_STRING_3 DC.B ' \____  \  | | \   |   /  ____  \   |   _  \   |  __|      \   /  ',0
T7_STRING_4 DC.B '_____/  /  | |  \  |  /  /    \  \  |  | \  \  | |____     |   |  ',0
T7_STRING_5 DC.B '\______/   |_|   \_| /__/      \__\ |__|  \__\ |______\    |___|  ',0

T7_WIN_0 DC.B '    _  __  ______  __  __   _       _______   __  __',0
T7_WIN_1 DC.B '   (_) \ \/ / __ \/ / / /  | |     / /  _/ | / / / /',0
T7_WIN_2 DC.B '  / /   \  / / / / / / /   | | /| / // //  |/ / / / ',0
T7_WIN_3 DC.B ' / /    / / /_/ / /_/ /    | |/ |/ // // /|  / /_/  ',0
T7_WIN_4 DC.B '/_/    /_/\____/\____/     |__/|__/___/_/ |_/  (_)   ',0

T7_SONG_PATH DC.B 'winning.wav',0

            DS.W 0
            

            
* ----------------------------------------------------------
T7_TEP:
		CMP.W #TM_TCB_STATUS_INIT,D3
		BEQ T7_INIT
		
		BSR T7_UPDATE
		TM_SYSTEM_CALL  TM_FGROUP_EXECUTION, TM_FRAME_DROP
		BSR T7_PRINT
		
		
		TM_SYSTEM_CALL TM_FGROUP_EXECUTION, TM_RETURN_TO_TM

* ----------------------------------------------------------

* ----------------------------------------------------------
T7_INIT:
*       TASK0_INITIALIZER: INITS THE TASK.
* ----------------------------------------------------------
        
        MOVE.W D1,TK_ID_W(A0)
        MOVE.W D2,TK_GROUP_W(A0)
        
                
        MOVE.L A1, -(A7)
        
        MOVE.W #70,D0
        LEA.L T7_SONG_PATH, A1
        TRAP #15
        
        MOVE.L (A7)+,A1
        
        TM_SYSTEM_CALL TM_FGROUP_EXECUTION, TM_RETURN_TO_TM
        
* ----------------------------------------------------------

* ----------------------------------------------------------
T7_UPDATE:
*       NOTHING TO UPDATE
* ----------------------------------------------------------
                RTS
* ----------------------------------------------------------

* ----------------------------------------------------------
T7_PRINT:
*       TASK7_PRINT. PRINTS THE WIN MENU
* ----------------------------------------------------------
        MOVEM.L D0-D7/A0-A6,-(A7)
        
        MOVE.L A1, A2
        
        
        ; PRINT WIN
        TK_SET_FONT #$00751AFF, #0
        TK_SET_FILL #$00000000
        
        TK_LOCATE #14, #2
        TK_PRINT_STRING #T7_WIN_0
        
        TK_LOCATE #14, #3
        TK_PRINT_STRING #T7_WIN_1
        
        TK_LOCATE #14, #4
        TK_PRINT_STRING #T7_WIN_2
        
        TK_LOCATE #14, #5
        TK_PRINT_STRING #T7_WIN_3
        
        TK_LOCATE #14, #6
        TK_PRINT_STRING #T7_WIN_4

        
        
        TK_SET_FONT #$0000FF00, #0
        TK_SET_FILL #$00000000
        TK_LOCATE #7, #9
        TK_PRINT_STRING #T7_STRING_0
        
        TK_LOCATE #7, #10
        TK_PRINT_STRING #T7_STRING_1
        
        TK_LOCATE #7, #11
        TK_PRINT_STRING #T7_STRING_2
        
        TK_LOCATE #7, #12
        TK_PRINT_STRING #T7_STRING_3
        
        TK_LOCATE #7, #13
        TK_PRINT_STRING #T7_STRING_4
        
        TK_LOCATE #7, #14
        TK_PRINT_STRING #T7_STRING_5
        
        
        TK_SET_FONT #$000FFFF0, #0
        
        TK_LOCATE #19, #20
        MOVE.W TK_LAST_SCORE(A2), D5
        TK_STR_NUM #T7_STRING_P, D5
        
        TK_LOCATE #18, #22
        TK_PRINT_STRING #T7_STRING_E
        
        
        MOVEM.L (A7)+, D0-D7/A0-A6
        RTS
* ----------------------------------------------------------









































*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~8~
