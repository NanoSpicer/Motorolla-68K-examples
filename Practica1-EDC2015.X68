*--------------------------------------------------------------------------------*
* Title      : Practica 1                                                        *
* Written by : Miquel Àngel Román Colom                                          *
* Date       : 02/03/2015                                                        *
* Description: Contar el número de componentes que cuyo valor absoluto es mayor  *
*              o igual a T1 o menor o igual a T2                                 *
*--------------------------------------------------------------------------------*
*                           Aquí hay ochenta caracteres                          *
*--------------------------------------------------------------------------------*
    ORG    $1000
    

VEKT   DC.B    -10,120,8,70,0,-99,-106
CMPT   DC.B    0        ; CMPT =4 END OF PROGRAM OK!
TOPE1  EQU     8
TOPE2  EQU     99
REPE   EQU     7    
       

START:                  ; first instruction of program
                        
                        ; INICIALIZACIONES
                        
    CLR.B CMPT          ; IMPORTANT PERQUE QUAN FAS REWIND SE QUEDA ES VALOR 
    CLR.L D0            ; POSTERIOR!!!!
    CLR.L D1
    MOVEA.L #0,A0       ; NO SE PUEDE CLR DE UN REG DE @

    MOVE #REPE,D1
    SUBQ #1,D1          ; Conseguir N-1 repeticiones = COMPONENTES DEL VECTOR
    
    LEA.L VEKT,A0
    
LOOP:
    
    MOVE.B (A0)+,D0
    BGT COMPTOPE1
    BMI VABSOLUTO
    
VABSOLUTO:

    NEG.B D0
    BRA COMPTOPE1

COMPTOPE1:

    CMP.B #TOPE1,D0
    BHS COMPTOPE2
    DBRA D1,LOOP
    BRA FINISH
    ;BRANCH EQUALS OR HIGHER

COMPTOPE2:

    CMP.B #TOPE2,D0
    BLS SUMATOR
    DBRA D1,LOOP
    BRA FINISH
    ;BRANCH EQUALS OR LOWER
    
SUMATOR:

    ADD.B #1,CMPT
    BRA ELEMENTSLEFT

ELEMENTSLEFT:
    
    DBRA D1,LOOP
    BRA FINISH
    
FINISH:

    SIMHALT             ; halt simulator
    END    START        ; last line of source





*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
