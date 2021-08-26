*-----------------------------------------------------------
* Title      : CALCULO DEL VALOR ABSOLUTO DE UN NUMERO N
* Written by : NanoSpicer
* Date       : 28/02/2015
* Description: Calculo del valor absoluto a partir de 0-N
*-----------------------------------------------------------
    ORG    $1000
N   EQU     -1

START:                  ; first instruction of program

    CLR D0
    SUB.B #N,D0
    BMI POSITIVE
    BRA FINISH
    

POSITIVE:
    FINISH:


FINISH:
    SIMHALT             ; halt simulator

    END    START        ; last line of source

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
