*-----------------------------------------------------------------------------*
* Title      : Practica 3                                                     *
* Written by : Miquel �ngel Rom�n Colom                                       *
* Date       : 13/03/2015                                                     *
* Description: Reordenar un vector de bytes de tal manera que los elementos   *
*              del tal queden reordenados de menor a mayor mediante el        *
*              algoritmo presentado en el .pdf del informe.                   *
*              Una vez reordenado, colocar los numeros de mayor a menor en el *
*              segundo vector.                                                *
*-----------------------------------------------------------------------------*
*                         Aqu� hay ochenta caracteres                         *
*-----------------------------------------------------------------------------*
     ORG    $1000

N:   EQU     6
V:   DC.B    5,3,8,10,1,4
VIN: DS.B    N
     DS.W    0

*-----------------------------------------------------------------------------*
*                                MIS VARIABLES                                *
*-----------------------------------------------------------------------------*

* TRABAJAMOS CON BYTES POR TANTO EL M�XIMO SERA 2^8 -1 (YA QUE EL 0 TAMBIEN
* DEBEMOS REPRESENTARLO) POR TANTO M�X=256-1=255.
* La idea es considerar este numero como el "primer" mnimo que vamos a
* encontrar.

MIN  DC.B    255
CPT  DC.B    1
     DS.W    0

*-----------------------------------------------------------------------------*
*                            INICIO DEL PROGRAMA                              *
*-----------------------------------------------------------------------------*

START:                  ; first instruction of program

    MOVE.B  MIN,D6      ; D6 = DATA REGISTER PARA COMPARAR EL 1� NUMERO Y
                        ; GUARDAR EL MINIMO

    MOVEQ   #N,D1       ; D1 = REG COUNTER.
    SUB.B   CPT,D1      ; CPT = 1 PARA HACER N ITERACIONES.
                        ; NOTA: ITERACIONES = BUSCAS DE ELEMENTOS M�NIMOS
    
    MOVE.B  D1,D2       ; D2 = NUMERO DE ORDENACIONES

    MOVEA.L #0,A0       ; USARE EL DIRECCIONAMIENTO INDEXADO BASICO
    MOVEA.L A0,A1



BuscarElementoMinimo:



        MOVE.B V(A0),D0

        CMP D6,D0

        BGE NoActualizarMinimo
        ; Si no se ejecuta el Branch if Greater or Equal, pasamos a actualizar
        ; nuestro elemento m�nimo.

        MOVE.B  D0,D6   ; Actualizamos el m�nimo.
        MOVEA.L A0,A3   ; Guardamos la direcci�n en la que se encuentra.

        NoActualizarMinimo:

        ; Al no actualizar el m�nimo, debemos seguir avanzando en el vector.
        ADDA.L  #$1,A0

        DBRA    D1,BuscarElementoMinimo
        ; UNA VEZ HAYAMOS ENCONTRADO EL MINIMO, PASAMOS A ORDENAR


ORDENAR:

        MOVEA.L #0,A0       ; JUNK INSTRUCTIONS? ||usando otro registro en vez de A0? !!!!MAS DE 80 CHARS

        ADDA.L  A6,A0

        MOVE.B V(A3),D4     ; Copiamos los valores a intercambiar de posicion
        MOVE.B V(A0),D5     ; en el vector en registros auxiliares, y,
        MOVE.B D4,V(A0)     ; posteriormente los intercambiamos de registro.
        MOVE.B D5,V(A3)


        MOVEA.L #0,A0       ; JUNK INSTRUCTIONS?
        ADDA.L  #1,A6
        ADDA.L  A6,A0



        ADD.B   #1,CPT      ; A medida que vayamos ordenando valores
        MOVEQ   #N,D1       ; tendremos que ir obviando los que ya hayamos
        SUB.B   CPT,D1      ; ordenado cuando procedamos a buscar un nuevo
                            ; m�nimo.



        MOVE.B  MIN,D6      ; Al buscar un nuevo m�nimo, tendremos que
                            ; registrar como m�nimo nuestro valor m�ximo
                            ; ya que sino, en nuestro registro nos constar�
                            ; el m�nimo anterior que seguro que es m�s peque�o
                            ; que el siguiente m�nimo que vayamos a buscar.
        



        DBRA    D2,BuscarElementoMinimo
        *******************************

        BRA OrdenarVectorVIN



*-----------------------------------------------------------------------------*
*        PARTE EN LA QUE REORDENAMOS EL VECTOR DE MAYOR A MENOR EN VIN        *
*-----------------------------------------------------------------------------*
OrdenarVectorVIN:

    LEA.L VIN,A0        ; La idea es bastante simple:
    LEA.L VIN,A1        ; Lo que har�, es cargar 2 veces la EA de VIN
    MOVE  #N,D1         ; con tal de que una, la decrementar� para recorrer
    SUBQ  #1,D1         ; el vector hacia atr�s y la otra hacia delante.


    ITERACION:

    MOVE.B -(A0),(A1)+  ; Con esto, lo que consigo es que, como ya he ordenado*
    DBRA   D1,ITERACION ; V de menor a mayor, recorri�ndolo hacia atr�s,
                        ; Obtendr� un nuevo vector V, ordenado de mayor
                        ; a menor. El cual (mientras que avanzo en (A1)) ser� *
                        ; guardado como vector VIN tal y como indica el .pdf.
    BRA FINISH


FINISH:

    SIMHALT             ; halt simulator
    END    START        ; last line of source

*-------------------------------FIN DEL PROGRAMA------------------------------*    

















*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
