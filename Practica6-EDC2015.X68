*------------------------------------------------------------------------------*
* Title      : Practica 6                                                      *
* Written by : Miquel Àngel Román Colom                                        *
* Date       : 20/04/2015                                                      *
* Description: Implementación de fase de ejecucion en el eprograma de la P4,P5 *
*------------------------------------------------------------------------------*
    ORG    $1000

EPROG   DC.W $060A, $0818, $060B, $0814, $0207, $040C, $0C00
        DC.W $0820, $040C, $0C00, $0001, $0002, $0000
        
EIR     DC.W 0 ;eregistre d'instruccio

EPC     DC.W 0 ;ecomptador de programa

ER0     DC.W 0 ;eregistre R0 (acumulador)

ER1     DC.W 0 ;eregistre R1 (buffer de memoria)

ESR     DC.W 0 ;eregistre de flags (00000000 00000ZNC)

*------------------------------------------------------------------------------*


jlsMASK DC.W $00FF ; in order to get the adress from JMPs code.

ITER    EQU  10


START:                  ; first instruction of program
    
    MOVE.B #ITER,D7
 
    SUBQ.B #1,D7
    
    LEA.L EPROG,A3      ; A3= index del vector EPROGRAMA
   

FETCHING: ; usar indexado basico para EPROG sobre EPC. Necesidad de multiplicar x2
    CLR     D0
    MOVEA.L #0,A1
    
    MOVE.W  EPC,D0
    MULU.W #2,D0
    MOVE.W D0,A1
    MOVE.W  EPROG(A1),EIR
    ADDQ.W #1,EPC
    
    ; endO'fetch
    
*----Operaciones de push y de reserva de espacio.----*
    
    SUBQ.L #$2,A7    +sdxw2s; RESERVAM UN W PER A GUARDAR-HI POSTERIORMENT EL RESULTAT
    MOVE.W EIR,-(A7) ; INTRODUIM LA eINSTRUCCIO A DESCODIFICAR EN LA PILA



    
    ; Descodificación
    JSR DESCO
    
    ; SACAMOS TODA LA BASURA QUE HEMOS METIDO
    ADDQ.L #$2,A7
    ; Obtencion del resultado despues de la SR
    MOVE.W (A7)+,D3
    
    ; Calculo del desplazamiento para ejecutar la instruccion adecuada.
    MULU.W #6,D3
    MOVE.W D3,A1
    JMP JMPLIST(A1)
    
    ; INDEXAR AL JUMP DE LA EJECUCION
    
    BRA FINISH
    

JMPLIST:
    JMP EJMI
    JMP EJMZ
    JMP EJMN
    JMP ESTR
    JMP ELDM
    JMP ECMP
    JMP EADD
    JMP ESUB
    JMP ER1R0
    JMP ER0R1
    JMP EHALT

EJMI:
    CLR D1
    MOVE.W EIR,D1
    AND.W  jlsMASK,D1
    ADD.L A3,D1
    MOVE.W D1,EPC
    BRA goFETCH
EJMZ:
    CLR D1
    MOVE.W EIR,D1
    BTST #2,D1
    BEQ EJMI
    BRA goFETCH
EJMN:
    CLR D1
    MOVE.W EIR,D1
    BTST #1,D1
    BMI JMI
    BRA goFETCH
ESTR:
    CLR D1
    MOVE.L #0,A4
    
    MOVE.W EIR,D1
    AND.W jlsMASK,D1
    ADD.L A3,D1
    MOVE.L D1,A4
    MOVE.W ER1,(A4)
    BRA goFETCH
ELDM:
    CLR D1
    MOVEA.L #0,A4
    
    MOVE.W EIR,D1
    AND.W jlsMASK,D1
    ADD.L A3,D1
    MOVE.L D1,A4
    MOVE.W (A4),ER1
    BRA goFETCH
ECMP:
    
EADD:
    
ESUB:
    
ER1R0:
    MOVE.W ER1,ER0
    BRA goFETCH
ER0R1:
    MOVE.W ER0,ER1
    BRA goFETCH
EHALT:

    JMP FINISH
    
    goFETCH:
        DBRA D7,FETCHING
        TRAP #15 ; STOPS SIMULATOR IN CASE OF ERROR

FINISH:
    
    SIMHALT             ; halt simulator    

DESCO:
    ;SAVE ALL REGISTERS THAT ARE ABOUT TO BE USED
    MOVE.W D0,-(A7)
    MOVE.W 6(A7),D0
    ;EXECUTE SUBROUTINE
    JMI:
        AND.W #$0F00,D0
        SUB.W #$0000,D0
        BEQ esJMI
        MOVE.W 6(A7),D0
    JMZ:
        AND.W #$0F00,D0
        SUB.W #$0100,D0
        BEQ esJMZ
        MOVE.W 6(A7),D0
    JMN:
        AND.W #$0F00,D0
        SUB.W #$0200,D0
        BEQ esJMN
        MOVE.W 6(A7),D0
    STM:
        AND.W #$0F00,D0
        SUB.W #$0400,D0
        BEQ esSTM
        MOVE.W 6(A7),D0
    LDM:
        AND.W #$0F00,D0
        SUB.W #$0600,D0
        BEQ esLDM
        MOVE.W 6(A7),D0
    CMP:
        AND.W #$0FFF,D0
        SUB.W #$0804,D0
        BEQ esCMP
        MOVE.W 6(A7),D0
    ADD:
        AND.W #$0FFF,D0
        SUB.W #$0810,D0
        BEQ esADD
        MOVE.W 6(A7),D0
    SUB:
        AND.W #$0FFF,D0
        SUB.W #$0814,D0
        BEQ esSUB
        MOVE.W 6(A7),D0
    R1R0:
        AND.W #$0FFF,D0
        SUB.W #$0818,D0
        BEQ esR1R0
        MOVE.W 6(A7),D0
    R0R1:
        AND.W #$0FFF,D0
        SUB.W #$0820,D0
        BEQ esR0R1
        MOVE.W 6(A7),D0
    HALT:
        AND.W #$0FFF,D0
        SUB.W #$0C00,D0
        BEQ esHALT
        MOVE.W 6(A7),D0
    
    
        esJMI:
            MOVE.W #0,8(A7)
            BRA endOSR
        esJMZ:
            MOVE.W #1,8(A7)
            BRA endOSR
        esJMN:
            MOVE.W #2,8(A7)
            BRA endOSR
        esSTM:
            MOVE.W #3,8(A7)
            BRA endOSR
        esLDM:
            MOVE.W #4,8(A7)
            BRA endOSR
        esCMP:
            MOVE.W #5,8(A7)
            BRA endOSR
        esADD:
            MOVE.W #6,8(A7)
            BRA endOSR
        esSUB:
            MOVE.W #7,8(A7)
            BRA endOSR
        esR1R0:
            MOVE.W #8,8(A7)
            BRA endOSR
        esR0R1:
            MOVE.W #9,8(A7)
            BRA endOSR
        esHALT:
            MOVE.W #10,8(A7)
            BRA endOSR
        
endOSR:

    MOVE.W (A7)+,D0 ; restauramos el valor inicial de D0

    RTS

    END    START        ; last line of source




















*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
