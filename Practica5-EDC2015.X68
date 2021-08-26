*------------------------------------------------------------------------------*
* Title      : Practica 5                                                      *
* Written by : Miquel Àngel Román Colom                                        *
* Date       : 10/04/2015                                                      *
* Description: Descodificacion de las einstrucciones del eprograma a modo de   *
*              subrutina de libreria                                           *
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
* La idea es crear mascaras que representen cada uno de los opcodes de las 
* eInstrucciones y con ANDs ver que tipo de eInstruccion se trata.
*------------------------------------------------------------------------------*
MJMI     DC.W $0000 ; considerare que las condiciones "don't care" son 0's.
MJMZ     DC.W $0100
MJMN     DC.W $0200
MSTRM    DC.W $0400
MLDM     DC.W $0600
MCMP     DC.W $0804
MADD     DC.W $0810
MSUB     DC.W $0814
MR1R0    DC.W $0818
MR0R1    DC.W $0820
MHALT    DC.W $0C00

MASK1    DC.W $0F00
MASK2    DC.W $0FFF 

ITER    EQU  10

CODE    DS.W ITER

START:                  ; first instruction of program
    
    MOVE.B #ITER,D7 
    SUBQ.B #1,D7
    
    LEA.L EPROG,A0
    LEA.L CODE,A1    ; EMPRARE A1 PER A GUARDAR ELS NOMBRES
    MOVE.W A0,EPC

FETCHING:
    
    MOVE.W  EPC,A0
    MOVE.W (A0)+,EIR
    MOVE.W  A0,EPC
    
    SUB.L #$2,A7     ; RESERVAM UN W PER A GUARDAR-HI POSTERIORMENT EL RESULTAT
    MOVE.W EIR,-(A7) ; INTRODUIM LA eINSTRUCCIO A DESCODIFICAR EN LA PILA
    
*----Operaciones de push de mascaras y opcodes----*
    
    MOVE.W MASK1,-(A7)
    MOVE.W MASK2,-(A7)
    
    MOVE.W MJMI,-(A7)
    MOVE.W MJMZ,-(A7)
    MOVE.W MJMN,-(A7)
    MOVE.W MSTRM,-(A7)
    MOVE.W MLDM,-(A7)
    MOVE.W MCMP,-(A7)
    MOVE.W MADD,-(A7)
    MOVE.W MSUB,-(A7)
    MOVE.W MR1R0,-(A7)
    MOVE.W MR0R1,-(A7)
    MOVE.W MHALT,-(A7)
    
    JSR DESCO
    ; SACAMOS TODA LA BASURA QUE HEMOS METIDO
    
    MOVE.W D0,(A7)+
    MOVE.W D0,(A7)+
    MOVE.W D0,(A7)+
    MOVE.W D0,(A7)+
    MOVE.W D0,(A7)+
    MOVE.W D0,(A7)+
    MOVE.W D0,(A7)+
    MOVE.W D0,(A7)+
    MOVE.W D0,(A7)+
    MOVE.W D0,(A7)+
    MOVE.W D0,(A7)+
    MOVE.W D0,(A7)+
    MOVE.W D0,(A7)+
    MOVE.W D0,(A7)+
    MOVE.W (A7)+,(A1)+
    
    DBRA D7,FETCHING
    BRA FINISH
DESCO:
    ;SAVE ALL REGISTERS THAT ARE ABOUT TO BE USED
    MOVE.W D0,-(A7)
    MOVE.W 32(A7),D0
    ;EXECUTE SUBROUTINE
    eJMI:
        AND.W 30(A7),D0
        SUB.W 26(A7),D0
        BEQ esJMI
        MOVE.W 32(A7),D0
    eJMZ:
        AND.W 30(A7),D0
        SUB.W 24(A7),D0
        BEQ esJMZ
        MOVE.W 32(A7),D0
    eJMN:
        AND.W 30(A7),D0
        SUB.W 22(A7),D0
        BEQ esJMN
        MOVE.W 32(A7),D0
    eSTR:
        AND.W 30(A7),D0
        SUB.W 20(A7),D0
        BEQ esSTR
        MOVE.W 32(A7),D0
    eLDM:
        AND.W 30(A7),D0
        SUB.W 18(A7),D0
        BEQ esLDM
        MOVE.W 32(A7),D0
    eCMP:
        AND.W 28(A7),D0
        SUB.W 16(A7),D0
        BEQ esCMP
        MOVE.W 32(A7),D0
    eADD:
        AND.W 28(A7),D0
        SUB.W 14(A7),D0
        BEQ esADD
        MOVE.W 32(A7),D0
    eSUB:
        AND.W 28(A7),D0
        SUB.W 12(A7),D0
        BEQ esSUB
        MOVE.W 32(A7),D0
    eR1R0:
        AND.W 28(A7),D0
        SUB.W 10(A7),D0
        BEQ esR1R0
        MOVE.W 32(A7),D0
    eR0R1:
        AND.W 28(A7),D0
        SUB.W 8(A7),D0
        BEQ esR0R1
        MOVE.W 32(A7),D0
    eHALT:
        AND.W 28(A7),D0
        SUB.W 6(A7),D0
        BEQ esHALT
        MOVE.W 32(A7),D0
    
    
        esJMI:
            MOVE.W #0,34(A7)
            BRA endOSR
        esJMZ:
            MOVE.W #1,34(A7)
            BRA endOSR
        esJMN:
            MOVE.W #2,34(A7)
            BRA endOSR
        esSTR:
            MOVE.W #3,34(A7)
            BRA endOSR
        esLDM:
            MOVE.W #4,34(A7)
            BRA endOSR
        esCMP:
            MOVE.W #5,34(A7)
            BRA endOSR
        esADD:
            MOVE.W #6,34(A7)
            BRA endOSR
        esSUB:
            MOVE.W #7,34(A7)
            BRA endOSR
        esR1R0:
            MOVE.W #8,34(A7)
            BRA endOSR
        esR0R1:
            MOVE.W #9,34(A7)
            BRA endOSR
        esHALT:
            MOVE.W #10,34(A7)
            BRA endOSR
        
endOSR:

    MOVE.W (A7)+,D0 ; restauramos el valor inicial de D0

        RTS

FINISH:
    SIMHALT             ; halt simulator
    END    START        ; last line of source













*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
