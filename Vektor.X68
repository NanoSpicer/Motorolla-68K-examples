*-------------------------------------------------------------------
* Title      : Contar componentes positivas y negativas de un Vector
* Written by : NanoSpicer
* Date       : 28/02/2015
* Description: Eso.
*-------------------------------------------------------------------
    ORG    $1000
    
V       DC.B    4, -2, -3, 3, 0    
NEGA    DC.W    0
POS     DC.W    0  
        DS.W    0  

START:                  ; first instruction of program
    
    
    LEA.L V,A0
    MOVE.B (A0),D0
    CMP #0,D0

LOOP:
    
    MOVE.B (A0)+,D0
    *CMP #0,D0
    BEQ FINISH
    *CMP #0,D0
    BGT POSITIVE
    *CMP #0,D0 ni flys de perque amb es compare no s'actualitza es flag N
    BRA NEGATIVE
    
POSITIVE:

    ADD #1,POS
    BRA LOOP
    
NEGATIVE:

    ADD #1,NEGA   
    BRA LOOP
    
FINISH:

    SIMHALT             ; halt simulator

    END    START        ; last line of source



*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
