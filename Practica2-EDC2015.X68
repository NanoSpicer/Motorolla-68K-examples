*--------------------------------------------------------------------------------*
* Title      : Practica 2                                                        *
* Written by : Miquel Àngel Román Colom                                          *
* Date       : 07/03/2015                                                        *
* Description: Reordenar un vector invirtiendo signo y posición de elemento      *
*--------------------------------------------------------------------------------*
*                           Aquí hay ochenta caracteres                          *
*--------------------------------------------------------------------------------*
    ORG    $1000
    
N   EQU     5
V1  DC.W    10,-15,-100,89,-1
V2  DS.W    N
 
       

START:                  ; first instruction of program

    CLR.L D0            ; INIT
    CLR.L D1            
    MOVEA.L #0,A0
    MOVEA.L #0,A1
    
    
    LEA V2,A0           ; Así con el m.d. predecremento obtendre la última pos.
    MOVE.B #N,D1
    SUBQ.B #1,D1        ; N ITERACIONES EN EL DBRA
    
    
LOOP:

    MOVE -(A0),D0
    BRA INVERSOR

INVERSOR:
    
    MULS #-1,D0         ; CAMBIO DE SIGNO
    
    
    MOVE D0,V2(A1)      ; INDEXADO BASICO: CONSISTE EN TENER EL INDICE (V2) 
    ADDQ.L #$2,A1       ; APUNTANDO A UNA DIRECCION FIJA DE MEMORIA Y MEDIANTE
                        ; LA SUMA DE UN VALOR CONSTANTE EN A1 IR AUGMENTANDO LA 
                        ; DIR. DEL PC.

    DBRA D1,LOOP
    BRA FINISH          ; NO QUEDAN ELEMENTOS, ACABAR EL PROGRAMA
    
FINISH:

    SIMHALT             ; halt simulator
    END    START        ; last line of source









*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
