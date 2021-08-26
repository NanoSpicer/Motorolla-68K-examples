*------------------------------------------------------------------------------*
* Title      : Practica 4                                                      *
* Written by : Miquel Àngel Román Colom                                        *
* Date       : 03/04/2015                                                      *
* Description: Descodificación de las einstrucciones del eprograma             *
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
    
    MOVE.W EIR,D0
    
DECODING:


    eJMI:
        AND.W MASK1,D0
        SUB.W MJMI,D0
        BEQ esJMI
        MOVE.W EIR,D0
    eJMZ:
        AND.W MASK1,D0
        SUB.W MJMZ,D0
        BEQ esJMZ
        MOVE.W EIR,D0
    eJMN:
        AND.W MASK1,D0
        SUB.W MJMN,D0
        BEQ esJMN
        MOVE.W EIR,D0
    eSTR:
        AND.W MASK1,D0
        SUB.W MSTRM,D0
        BEQ esSTR
        MOVE.W EIR,D0
    eLDM:
        AND.W MASK1,D0
        SUB.W MLDM,D0
        BEQ esLDM
        MOVE.W EIR,D0
    eCMP:
        AND.W MASK2,D0
        SUB.W MCMP,D0
        BEQ esCMP
        MOVE.W EIR,D0
    eADD:
        AND.W MASK2,D0
        SUB.W MADD,D0
        BEQ esADD
        MOVE.W EIR,D0
    eSUB:
        AND.W MASK2,D0
        SUB.W MSUB,D0
        BEQ esSUB
        MOVE.W EIR,D0
    eR1R0:
        AND.W MASK2,D0
        SUB.W MR1R0,D0
        BEQ esR1R0
        MOVE.W EIR,D0
    eR0R1:
        AND.W MASK2,D0
        SUB.W MR0R1,D0
        BEQ esR0R1
        MOVE.W EIR,D0
    eHALT:
        AND.W MASK2,D0
        SUB.W MHALT,D0
        BEQ esHALT
        MOVE.W EIR,D0
    
    
        esJMI:
            MOVE.W #0,(A1)+
            BRA goFETCH
        esJMZ:
            MOVE.W #1,(A1)+
            BRA goFETCH
        esJMN:
            MOVE.W #2,(A1)+
            BRA goFETCH
        esSTR:
            MOVE.W #3,(A1)+
            BRA goFETCH
        esLDM:
            MOVE.W #4,(A1)+
            BRA goFETCH
        esCMP:
            MOVE.W #5,(A1)+
            BRA goFETCH
        esADD:
            MOVE.W #6,(A1)+
            BRA goFETCH
        esSUB:
            MOVE.W #7,(A1)+
            BRA goFETCH
        esR1R0:
            MOVE.W #8,(A1)+
            BRA goFETCH
        esR0R1:
            MOVE.W #9,(A1)+
            BRA goFETCH
        esHALT:
            MOVE.W #10,(A1)+
            BRA goFETCH
    
goFETCH:    

    DBRA D7,FETCHING

FINISH:
    SIMHALT             ; halt simulator
    END    START        ; last line of source






*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
