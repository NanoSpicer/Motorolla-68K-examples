*-----------------------------------------------------------------------------*
* Title : PRAFIN15                                                            *
* Written by : Miquel Àngel Román Colom y Alejandro Gálvez Monje              *
* Date : 01/05/2015  ---> 02/05/2015                                          *
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

*-----------------------------------------------------------------------------*
*                              Inicio del programa                            *
*-----------------------------------------------------------------------------*

START:

FETCH:

    CLR     D0
    MOVEA.L #0,A1
    
    MOVE.W  EPC,D0
    MULU.W #2,D0          ; Para que encaje con las palabras del 68k
    MOVE.W D0,A1 
    MOVE.W  EPROG(A1),EIR ; Cargamos la instrucción en el eregistro de 
                          ; instrucción
    ADDQ.W #1,EPC
    ;endOFetch
    
    SUBQ.W #2,A7          ; Reservamos espacio en la pila para obtener
                          ; el resultado de la decodificación de EIR
    MOVE.W EIR,-(A7)      ; PUSH de EIR
    
    JSR DESPEPA4R
    
    ADDQ.W #2,A7          ; Vaciamos la "basura" que hemos metido
    MOVE.W (A7)+,D0       ; Extraemos el resultado obtenido de la
                          ; decodificación
    
    MULU #6,D0            ; Multiplicamos por 6 para llegar al JMP de la
                          ; etiqueta en cuestión para llegar a su etiqueta
                          ; de salto
    MOVEA.L D0,A1
    JMP JMPLIST(A1)       ; Indexado básico al JMP correspondiente
    
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
        CLR.L D0           ; Limpiamos el registro D0 para poder operar en el
        
        MOVE.W EIR,D0      ; Cargamos EIR en D0 para obtener la direccion de M
        AND.W #$00FF,D0
        
        MULU.W #2,D0       ; Adaptamos la dirección de M a las palabras del 68k
        MOVE.W D0,A1       ; y posteriormente lo indexaremos con la etiqueta 
                           ; EPROG [EPROG(A1)] usaremos la misma estrategia en
                           ; instrucciones posteriores a esta.
        
        MOVE.W ER1,EPROG(A1)
        BRA endOExecution
        
    ELOA:
        CLR.L D0           ; Similar a "ESTO". ELOA es la operación inversa de
                           ; "ESTO".
        MOVE.W EIR,D0
        AND.W #$00FF,D0
        
        MULU.W #2,D0
        MOVE.W D0,A1
        
        MOVE.W EPROG(A1),ER1 ; En este caso es la inversa de "ESTO"
        BRA endOExecution
        
    ECMP:
        JSR ACTUFLAG         ; ECMP sera una simple actualización de flags
                             ; debido a que no se guardan los resultados de la
                             ; operación en teoría realizada por el mnemónico
                             ; CMP.
       
        BRA endOExecution
        
    EADD:
        JSR trobaREGS        ; Subrutina que encuentra los operandos fuente y
                             ; destino. 
        ADD.W ER0,D0         ; SUMA
        MOVE.W D0,ER0
        JSR ACTUFLAG
        
        BRA endOExecution
        
    ESUB:
        JSR trobaREGS       
        
        MOVE.W ER0,D1
        SUB.W D0,D1          ; RESTA |||||||| suma del negat? 
        MOVE.W D1,ER0
        
        JSR ACTUFLAG
        
        BRA endOExecution
        
    ENAN:
        JSR trobaREGS        ; falta comprovar el correcte funcionament d'aquesta operacio.
                             ; request pepa4r tests
        MOVE.W ER0,D1
        AND.W D0,D1
        NOT.W D1
        AND.W #$0FFF,D1
        MOVE.W D1,ER0
        
        ; VERSIO ADAPTADA DE ACTUALITZACIO DE FLAGS
        
        JSR ACTUFLAGX
        
        BRA endOExecution
        
    EADQ:
        MOVE.W ESR,D7       ; PARA MIRAR LOS FLAGS
        JSR trobaREGS
        
        MOVE.W EIR,D0
        AND.W #$000C,D0     ; Nos quedamos con la constante en D0
        ROR #2,D0           ; adaptamos la constantne
        
        
        ; EXTENDER EL SIGNO
        BTST #1,D0          ; En caso de que el bit testeado sea 1, implicara
                            ; que la constante tiene signo negativo. En caso
                            ; contrario, viceversa.
        
        BEQ extPOSq
        BNE extNEGq
        
        extPOSq:
        AND.W #$0003,D0
        BRA executeADQ
        extNEGq:
        OR.W #$FFFC,D0
        
        executeADQ:
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
            BCLR #2,D7
            BRA XtestN
        XactualitzaC1:
            BSET #2,D7
    
        XtestN:
            BTST #11,D0
            BEQ XactualitzaN0
            BNE XactualitzaN1
        
        XactualitzaN0:
            BCLR #1,D7
            BRA XtestZ
        XactualitzaN1:
            BSET #1,D7
        
        XtestZ:
            CMP.W #$0000,D0
            BEQ XactualitzaZ1
        
        XactualitzaZ0:
            BCLR #2,D7
            BRA XendOAF
        XactualitzaZ1:
            BSET #2,D7
    
        XendOAF:
        ; devolver valores
            MOVE.W D7,ESR
        BRA endOExecution
        
    ETRA:
        
        JSR trobaREGS
        MOVE.W D0,(A1)          ; Simple transferencia entre eregistros.
        
        JSR ACTUFLAGX
        
        BRA endOExecution
    ESET:
        CLR.L D0
        JSR trobaREGS           ; Busqueda del Eregistro destino.
        MOVE.W EIR,D0           ; Nos quedamos la constante de 6 bits
        AND.W #$00FC,D0         ; La adaptamos y extendemos su signo
        ROR #2,D0 

              
        ; EXTENDER EL SIGNO
        BTST #5,D0
        
        BEQ extPOSSET
        BNE extNEGSET
        
        extPOSSET:
        AND.W #$0003,D0
        BRA executeSET
        extNEGSET:
        OR.W #$FFFC,D0
        
        executeSET:

        
        
        MOVE.W D0,(A1)
        
        BRA endOExecution
        
    EJMZ:              
        MOVE.W ESR,D0       ; Las instrucciones de JMP se basan en comprobar
        BTST #2,D0          ; que se cumple la condición especificada y, si
        BNE EJMI            ; esta se verifica, saltar a la instrucción de
        BRA endOExecution   ; salto incondicional (JMI)
        
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
        BRA FINISH          ; Salto a la dirección que contiene la directiva
                            ; de parar el simulador.

endOExecution:
    JMP FETCH               ; Al final de la fase de ejecución, debemos
                            ; volver a inicar la fase de fetch.
    


FINISH:
    SIMHALT             ; halt simulator
    
    
    
    
*-----------------------------------------------------------------------------*
*                                   Subrutinas                                *
*-----------------------------------------------------------------------------*

trobaREGS:
* La subrutina trobaREGS es una subrutina de usuario programada con el fin de,
* dado el EIR de una einstrucción, a traves de su codificación, obtener los
* operandos fuente y destino. Al final de la subrutina, obtendremos:
* D0 = Operando fuente. (Contenido de la posición de memoria de el registro 
* "descodificado", por ejemplo).
* A1 = Operando destino. (A1 contendrá la dirección del operando destino)

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
        
        
ACTUFLAG: 
* La subrutina ACTUFLAG es una subrutina de usuario programada con el fin de,
* dado el EIR de una einstrucción, a traves de su codificación, obtener los
* operandos fuente y destino gracias a la subrutina "trobaREGS". 
* Una vez obtenida esta información realizamos el calculo de los flags.

* NOTA: ESTA RUTINA SE EJECUTARÁ AL FINAL DE LA FASE DE EJECUCIÓN DE LAS 
*       INSTRUCCIONES PERTENECIENTES (las que hagan una actualizacion de ZNC)

* Al final de la subrutina, obtendremos los flags actualizados en D7.
* Después, pasaremos el contenido de D7 a ESR por tal de tener el eStatusReg
* actualizado.
    
    CLR.L D7 
    testC:
    MOVE.W EIR,D0
    MOVE.W ESR,D7
    
    AND.W #$0030,D0
    MOVE.W D0,D1
    
    SUB.W #$0000,D0
    BEQ esRESTA
    SUB.W #$0020,D0
    BEQ esRESTA
    
    esSUMA:
        JSR trobaREGS
        ; REVERTIR LOS CAMBIOS DE LA PREVIA OPERACION
        MOVE.W ER0,D1
        SUB.W D0,D1
        ADD.W D0,D1
        BTST #12,D0
        BEQ actualitzaC0
        BNE actualitzaC1
    esRESTA:
        JSR trobaREGS
        ; REVERTIR LOS CAMBIOS DE LA PREVIA OPERACION
        MOVE.W ER0,D1
        ADD.W D0,D1
        SUB.W D0,D1
        BEQ actualitzaC0
        BPL actualitzaC0
        BMI actualitzaC1
    
    
    actualitzaC0:
    BCLR #2,D7
    BRA testN
    actualitzaC1:
    BSET #2,D7
    
    testN:
    BTST #11,D1
    BEQ actualitzaN0
    BNE actualitzaN1
        
    actualitzaN0:
    BCLR #1,D7
    BRA testZ
    actualitzaN1:
    BSET #1,D7
        
    testZ:
    CMP.W #$0000,D1
    BEQ actualitzaZ1
        
    actualitzaZ0:
    BCLR #2,D7
    BRA endOAF
    actualitzaZ1:
    BSET #2,D7
    
    endOAF:
    MOVE.W D7,ESR
    ; devolver valores
    RTS
    



ACTUFLAGX:
* Muy similar a ACTUFLAG, solo que esta subrutina no actualiza el flag C.
* Pensada para las instrucciones  NAN y TRA.

        CLR.L D7       
        MOVE.W (A1),D0 ; PASSAM Rbb ON Raa PER A ACTUALITZAR ELS FLAGS DINS D0
        MOVE.W ESR,D7
    SPtestN:
        BTST #11,D0
        BEQ SPactualitzaN0
        BNE SPactualitzaN1
        
    SPactualitzaN0:
        BCLR #1,D7
        BRA SPtestZ
    SPactualitzaN1:
        BSET #1,D7
        
    SPtestZ:
        CMP.W #$0000,D0
        BEQ SPactualitzaZ1
        
    SPactualitzaZ0:
        BCLR #2,D7
        BRA endOACTUFLAGX
    SPactualitzaZ1:
        BSET #2,D7
        
    endOACTUFLAGX:
    MOVE.W D7,ESR
        RTS

DESPEPA4R:
* DESPEPA4R es la subrutina de libreria programada con el cbjetivo de, a partir
* del EIR obtener los opcodes y descifrar de que tipo de instrucción se trata.
* Una vez sabemos de que instrucción se trata, cargamos un valor de 
* einstrucción en el espacio que el programador ha reservado previamente para 
* que al finalizar la subrutina el emulador emule la instrucción adecuada.

* La subrutina se basa en ir leyendo los opcodes correspondientes a cada una 
* de las einstrucciones, y realizando una resta, comprobar si ese opcode es 
* el de tal instrucción. 

* Si lo es, cargamos el valor de einstrucción en el
* espacio reservado por el programador, si no lo es, pasamos a realizar la
* misma operacion hasta que encontremos su einstrucción correspondiente.

    MOVE.W D0,-(A7)       ; Guardamos los registros que vamos a utilizar
    MOVE.W 6(A7),D0       ; Posteriormente, recargaremos D0 con su valor 
                          ; correspondiente.

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
