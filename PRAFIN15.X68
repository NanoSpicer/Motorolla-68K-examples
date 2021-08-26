*-----------------------------------------------------------------------------*
* Title : PRAFIN15                                                            *
* Written by : Miquel Àngel Román Colom y Alejandro Gálvez Monje              *
* Date : 24/05/2015                                                           *
* Description : Emulador de la PEPA4r                                         *
*-----------------------------------------------------------------------------*
        ORG $1000
        
EPROG:  DC.W $0700,$020F,$0606,$0C0B,$020E,$0605,$0C0B,$0418,$050D
        DC.W $0C0B,$0E07,$0601,$0010,$0F00,$0008,$0004,$0000

EIR:    DC.W 0 ;eregistre d'instrucció

EPC:    DC.W 0 ;ecomptador de programa

ER0:    DC.W 0 ;eregistre R0

ER1:    DC.W 0 ;eregistre R1

ER2:    DC.W 0 ;eregistre R2

ER3:    DC.W 0 ;eregistre R3

ESR:    DC.W 0 ;eregistre d’estat (00000000 00000ZNC)



START:                  ; first instruction of program



FETCH:

    CLR     D0
    MOVEA.L #0,A1
    
    MOVE.W  EPC,D0
    MULU.W #2,D0
    MOVE.W D0,A1 
    MOVE.W  EPROG(A1),EIR
    ADDQ.W #1,EPC
    ;endOFetch
    
    SUBQ.W #2,A7
    MOVE.W EIR,-(A7)
    
    JSR DESPEPA4R
    
    ADDQ.W #2,A7
    MOVE.W (A7)+,D0
    
    MULU #6,D0
    MOVEA.L D0,A1
    JMP JMPLIST(A1)
    
JMPLIST:

    JMP ESTO
    JMP ELOA
    JMP ECMP
    JMP EADD
    JMP ESUB
    JMP ENAN
    JMP EADQ
    JMP ETRA
    JMP ESET
    JMP EJMZ
    JMP EJMN
    JMP EJMI
    JMP EHLT

    ESTO:
        CLR.L D0
        MOVE.W EIR,D0
        AND.W #$00FF,D0
        
        MULU.W #2,D0
        MOVE.W D0,A1
        
        MOVE.W ER1,EPROG(A1)
        BRA endOExecution
    ELOA:
        CLR.L D0
        MOVE.W EIR,D0
        AND.W #$00FF,D0
        
        MULU.W #2,D0
        MOVE.W D0,A1
        
        MOVE.W EPROG(A1),ER1 
        BRA endOExecution
    ECMP:

        JSR ACTUFLAG
        
        BRA endOExecution
    EADD:
        JSR trobaREGS
        MOVE.W (A1),D0
        ADD.W ER0,D0
        
        JSR ACTUFLAG
        
        BRA endOExecution
    ESUB:
        JSR trobaREGS
        MOVE.W (A1),D0
        SUB.W D0,ER0
        
        JSR ACTUFLAG
        
        BRA endOExecution
    ENAN:
    
        JSR trobaREGS
        MOVE.W (A1),D1
        AND.W D0,D1
        NOT.W D1
        AND.W #$0FFF,D1
        
        ; VERSIO ADAPTADA DE ACTUALITZACIO DE FLAGS
        
        JSR ACTUFLAGX
        
        BRA endOExecution
    EADQ:
        JSR trobaREGS
        ROR #2,D0 ; D0 = K
        MOVE.W (A1),D1 ; D1 = DESTINY
        ADD.W D0,D1
        MOVE.W D1,(A1)
        
        ; VERSION ADAPTADA DE LA ACTUALIZACION DE LOS FLAGS
        
        CLR.L D0
        XtestC:
        
            JSR trobaREGS
            ROR #2,D0
            ADD.W (A1),D0
            BTST #12,D0
            BEQ XactualitzaC0
            BNE XactualitzaC1
    
    
        XactualitzaC0:
            BCLR #2,ESR
            BRA XtestN
        XactualitzaC1:
            BSET #2,ESR
    
        XtestN:
            BTST #11,D0
            BEQ XactualitzaN0
            BNE XactualitzaN1
        
        XactualitzaN0:
            BCLR #1,ESR
            BRA XtestZ
        XactualitzaN1:
            BSET #1,ESR
        
        XtestZ:
            CMP.W #$0000,D0
            BEQ XactualitzaZ1
        
        XactualitzaZ0:
            BCLR #2,ESR
            BRA XendOAF
        XactualitzaZ1:
            BSET #2,ESR
    
        XendOAF:
        ; devolver valores

        BRA endOExecution
        
    ETRA:
        
        JSR trobaREGS
        MOVE.W D0,(A1)
        
        JSR ACTUFLAGX
        
        BRA endOExecution
    ESET:
        CLR.L D0
        MOVE.W EIR,D0
        AND.W #$00FC,D0
        
        ROR #2,D0 ;desplazamos el valor de la constante 2 hacia la derecha.
        
        CLR.L D1
        MOVE.W EIR,D1
        AND.W #$0003,D1
        
        CMP.W #$0000,D1
        BEQ esR0
        CMP.W #$0001,D1
        BEQ esR1
        CMP.W #$0002,D1
        BEQ esR2
        CMP.W #$0003,D1
        BEQ esR3
        
            esR0:
                MOVE.W D0,ER0
                BRA endOComparison
            esR1:
                MOVE.W D0,ER1
                BRA endOComparison
            esR2:
                MOVE.W D0,ER2
                BRA endOComparison
            esR3:
                MOVE.W D0,ER3
                BRA endOComparison
                
        endOComparison:
        BRA endOExecution
    EJMZ:
        MOVE.W ESR,D0
        BTST #2,D0
        BNE EJMI
        BRA endOExecution
    EJMN:
        MOVE.W ESR,D0
        BTST #1,D0
        BNE EJMI
        BRA endOExecution
    EJMI:
        CLR.L D0
        MOVE.W EIR,D0
        AND.W #$00FF,D0
        MOVE.W D0,EPC
        BRA endOExecution
    EHLT:
    
        BRA FINISH

endOExecution:
    JMP FETCH
    


FINISH:
    SIMHALT             ; halt simulator
trobaREGS:
* la idea de esta subrutina es que dados dos operandos, fuente y destino, despues de toda esta subrutina
* en d0 encontraremos el valor del operando fuente y en a1 encontraremos la @del operando destino.

        CLR.L D0        ;operando Raa
        MOVE.W EIR,D0
        AND.W #$000C,D0
        
        ROR #2,D0
        
        CMP.W #$0000,D0
        BEQ esRaa0
        CMP.W #$0001,D0
        BEQ esRaa1
        CMP.W #$0002,D0
        BEQ esRaa2
        CMP.W #$0003,D0
        BEQ esRaa3
        
            esRaa0:
                MOVE.W ER0,D0
                BRA endOfRaa
            esRaa1:
                MOVE.W ER1,D0
                BRA endOfRaa
            esRaa2:
                MOVE.W ER2,D0
                BRA endOfRaa
            esRaa3:
                MOVE.W ER3,D0
                BRA endOfRaa
                
        endOfRaa: ;tenemos resultado de el operando fuente en d0
        

        CLR.L D1        ;operando Rbb 
        MOVE.W EIR,D1
        AND.W #$0003,D1
        
        CMP.W #$0000,D1
        BEQ esRbb0
        CMP.W #$0001,D1
        BEQ esRbb1
        CMP.W #$0002,D1
        BEQ esRbb2
        CMP.W #$0003,D1
        BEQ esRbb3
        
            esRbb0:
                LEA.L ER0,A1
                BRA endOInstruction 
            esRbb1:
                LEA.L ER1,A1
                BRA endOInstruction 
            esRbb2:
                LEA.L ER2,A1
                BRA endOInstruction 
            esRbb3:
                LEA.L ER3,A1
                BRA endOInstruction 
                
        endOInstruction:
        RTS
        
        
ACTUFLAG: ;subrutina de usuario para la actualizacion de los flegs
* dados un operando fuente y un operando destino más el codigo de instruccion actualizaremos sus flags en funcion del resultado adecuado
* operando fuente = da || destino = db
    CLR.L D0
    testC:
    MOVE.W EIR,D0
    AND.W #$0030,D0
    MOVE.W D0,D1
    
    SUB.W #$0000,D0
    BEQ esRESTA
    SUB.W #$0020,D0
    BEQ esRESTA
    
    esSUMA:
        JSR trobaREGS
        ADD.W (A1),D0
        BTST #12,D0
        BEQ actualitzaC0
        BNE actualitzaC1
    esRESTA:
        JSR trobaREGS
        MOVE.W (A1),D1
        CMP D0,D1
        BEQ actualitzaC0
        BPL actualitzaC0
        BMI actualitzaC1
    
    
    actualitzaC0:
    BCLR #2,ESR
    BRA testN
    actualitzaC1:
    BSET #2,ESR
    
    testN:
    BTST #11,D0
    BEQ actualitzaN0
    BNE actualitzaN1
        
    actualitzaN0:
    BCLR #1,ESR
    BRA testZ
    actualitzaN1:
    BSET #1,ESR
        
    testZ:
    CMP.W #$0000,D0
    BEQ actualitzaZ1
        
    actualitzaZ0:
    BCLR #2,ESR
    BRA endOAF
    actualitzaZ1:
    BSET #2,ESR
    
    endOAF:
    ; devolver valores
    RTS
    

ACTUFLAGX:
    
        MOVE.W ESR,D3  ; lo guardamos para luego resetear el valor del flag C
        BSET #4,EIR
        JSR ACTUFLAG
        
        AND.W #$0001,D3 ; "desactualitzamos" el flag C ya que no debe actualizarse
        BEQ es0
        BNE es1
        es0:
        BCLR #0,ESR
        BRA endOACTUFLAGX
        es1:
        BSET #0,ESR
        
        endOACTUFLAGX:
        RTS

DESPEPA4R:
    ;SAVE ALL REGISTERS THAT ARE ABOUT TO BE USED
    MOVE.W D0,-(A7)
    MOVE.W 6(A7),D0

    STOM:
    
        AND.W #$0E00,D0   ; LIBREAMOS EIR DE LA INFORMACION INNECESARIA
        SUB.W #$0000,D0   ; COMPARAMOS CON UNA RESTA SI EL OPCODE ES EL DE
                          ; TAL INSTRUCCION
        BEQ esSTOM        ; Si lo es, saltamos. Sino recopiamos EIR a D0
        MOVE.W 6(A7),D0
    
    LOAM:
    
        AND.W #$0E00,D0
        SUB.W #$0200,D0
        BEQ esLOAM
        MOVE.W 6(A7),D0
    
    CMP:
    
        AND.W #$0F33,D0
        SUB.W #$0400,D0
        BEQ esCMP
        MOVE.W 6(A7),D0
    
    ADD:
    
        AND.W #$0F33,D0
        SUB.W #$0410,D0
        BEQ esADD
        MOVE.W 6(A7),D0
    
    SUB:
    
        AND.W #$0F33,D0
        SUB.W #$0420,D0
        BEQ esSUB
        MOVE.W 6(A7),D0
    
    NAN:
    
        AND.W #$0F33,D0
        SUB.W #$0430,D0
        BEQ esNAN
        MOVE.W 6(A7),D0
    
    ADQ:
        
        AND.W #$0F00,D0
        SUB.W #$0500,D0
        BEQ esADQ
        MOVE.W 6(A7),D0
    
    TRA:
        
        AND.W #$0F00,D0
        SUB.W #$0600,D0
        BEQ esTRA
        MOVE.W 6(A7),D0
    
    SET:
    
        AND.W #$0F00,D0
        SUB.W #$0700,D0
        BEQ esSET
        MOVE.W 6(A7),D0
    
    JMZ:
    
        AND.W #$0F00,D0
        SUB.W #$0C00,D0
        BEQ esJMZ
        MOVE.W 6(A7),D0
    
    JMN:
    
        AND.W #$0F00,D0
        SUB.W #$0D00,D0
        BEQ esJMN
        MOVE.W 6(A7),D0
    
    JMI:
    
        AND.W #$0F00,D0
        SUB.W #$0E00,D0
        BEQ esJMI
        MOVE.W 6(A7),D0
    
    HLT:
    
        AND.W #$0F00,D0
        SUB.W #$0F00,D0
        BEQ esHLT
        MOVE.W 6(A7),D0
    
        esSTOM:
            MOVE.W #0,8(A7)
            BRA endOSR
        esLOAM:
            MOVE.W #1,8(A7)
            BRA endOSR
        esCMP:
            MOVE.W #2,8(A7)
            BRA endOSR
        esADD:
            MOVE.W #3,8(A7)
            BRA endOSR
        esSUB:
            MOVE.W #4,8(A7)
            BRA endOSR
        esNAN:
            MOVE.W #5,8(A7)
            BRA endOSR
        esADQ:
            MOVE.W #6,8(A7)
            BRA endOSR
        esTRA:
            MOVE.W #7,8(A7)
            BRA endOSR
        esSET:
            MOVE.W #8,8(A7)
            BRA endOSR
        esJMZ:
            MOVE.W #9,8(A7)
            BRA endOSR
        esJMN:
            MOVE.W #10,8(A7)
            BRA endOSR
        esJMI:
            MOVE.W #11,8(A7)
            BRA endOSR
        esHLT:
            MOVE.W #12,8(A7)
            BRA endOSR
        
endOSR:
    MOVE.W (A7)+,D0 ; restauramos el valor inicial de D0
    RTS

    END    START        ; last line of source





*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
