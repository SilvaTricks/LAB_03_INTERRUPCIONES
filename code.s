;*******************************************************************************
;   UNIVERSIDAD DEL VALLE DE GUATEMALA
;   IE2023 PROGRANACIÓN DE MICROCONTROLADORES 
;   AUTOR: JORGE SILVA
;   COMPILADOR: PIC-AS (v2.36), MPLAB X IDE (v6.00)
;   PROYECTO: Laboratorio 3, INTERRUPCIONES
;   HARDWARE: PIC16F887
;   CREADO: 9/08/2022
;   ÚLTIMA MODIFCACIÓN: 16/08/2022
;*******************************************************************************

PROCESSOR 16F887
#include <xc.inc>
    
;*******************************************************************************
;Palabra de configuración generada por MPLAB
;*******************************************************************************
; PIC16F887 Configuration Bit Settings

; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT 
  CONFIG  WDTE = OFF            
  CONFIG  PWRTE = ON           
  CONFIG  MCLRE = OFF           
  CONFIG  CP = OFF              
  CONFIG  CPD = OFF             
  CONFIG  BOREN = OFF           
  CONFIG  IESO = OFF            
  CONFIG  FCMEN = OFF           
  CONFIG  LVP = OFF             

; CONFIG2
  CONFIG  BOR4V = BOR40V        
  CONFIG  WRT = OFF    
  
;*******************************************************************************
;VARIABLES
;*******************************************************************************
PSECT udata_bank0
 flag:
	DS 2    ;Variable principal de datos de 2 BYTES
    
 tmrcero:   
	DS 2    ;Variable de los 20ms del TMR0 de 2 BYTES
	
 cont:
	DS 2    ;Variable para el contador del TMR0 de 2 BYTES
	
 cont2: 
	DS 2    ;Variable para el display de unidades de 2 BYTES
	
 cont3:
	DS 2    ;Variable para el display en decenas de 2 BYTES
	
 int1:
	DS 2    ;Variable para la interrupción del push y pop de 2 BYTES
    
 int2:
	DS 2	;Variable para la interrupción del push y pop de 2 BYTES
    
;******************************************************************************* 
; VECTOR RESET
;******************************************************************************* 
PSECT CODE, delta=2, abs
 ORG 0x0000
    
    goto main
;******************************************************************************* 
;INTERRUPCIONES
;******************************************************************************* 
PSECT CODE, delta=2, abs
 ORG 0x0004

confpush:			;Configuración del push
    movwf   int1
    swapf   STATUS, W
    movwf   int2
    
vectorTMR0:			;Ejecución del TMR0
    btfss   INTCON, 2		;Revisa T0IF
    goto    botones            
    
    incf    tmrcero, F
    movf    tmrcero, W
    sublw   42
    btfsc   STATUS, 2
    goto    intTMR0
    
    movlw   180
    movwf   TMR0
    bcf	    INTCON, 2
    
    goto    botones
    
intTMR0:			 ;Interrupción del TMR0
    clrf    tmrcero
    
    movlw   180
    movwf   TMR0                 
    bcf	    INTCON, 2           
    
    incf    cont, F
    movf    cont, W
    sublw   10
    btfsc   STATUS, 2
    bsf	    flag, 4
    btfsc   STATUS, 2
    clrf    cont
    
    btfss   flag ,0
    goto    verificar
    
    goto    botones
    
verificar:
    bsf	    flag, 0
    goto    botones

botones:		;Revisa si se presionó el botón para la interrupción
    btfss   INTCON, 0
    goto    confpop
    
    banksel PORTB
    btfsc   PORTB,0  
    bsf	    flag, 2
    btfsc   PORTB,1
    bsf	    flag, 3
    
    goto    resetboton
    
resetboton:		;Reinicia la bandera del botón
    bcf	    INTCON, 0        
    
confpop:		;Configuración del pop
    swapf   int2, W
    movwf   STATUS
    swapf   int1, F
    swapf   int1, W
    retfie
    
;******************************************************************************* 
;CÓDIGO PRINCIPAL
;******************************************************************************* 
main: 
    call    basic
    call    oscilador
    call    configTMR0
    call    interrupciones
    
loop:
    call    contbotones
    call    displayunits
    call    displaydec
    
    goto    loop
    
;*******************************************************************************
;TABLA DE VALORES HEXADECIMALES
;*******************************************************************************
tabla:			;Esta tabla traduce los valores a hexadecimales
    addwf   PCL, F
    retlw   3Fh
    retlw   06h	 
    retlw   5Bh	    
    retlw   4Fh	    
    retlw   66h	    
    retlw   6Dh	   
    retlw   7Dh	  
    retlw   07h	   
    retlw   7Fh	    
    retlw   6Fh	    
    retlw   77h	    
    retlw   7Ch	    
    retlw   39h	    
    retlw   5Eh	    
    retlw   79h	    
    retlw   71h     
    
;******************************************************************************* 
;SUBRUTINAS
;*******************************************************************************
basic:
    banksel ANSEL		;Volvemos los pines digitales
    banksel ANSELH
    clrf    ANSEL               
    clrf    ANSELH              
    
    banksel TRISA    
    banksel TRISB
    banksel TRISC
    banksel TRISD
    movlw   0b11111111		;Asignamos PORTB como entradas
    movwf   TRISB              
    
    clrf    TRISA               ;Asignamos PORTA como salidas
    clrf    TRISC               ;Asignamos PORTB como salidas
    clrf    TRISD               ;Asignamos PORTc como salidas
    
    banksel PORTA		;Limpiamos tofos los puertos antes de comenzar
    banksel PORTB		;Es una buena prática para evitar problemas
    banksel PORTC
    banksel PORTD
    clrf    PORTA              
    clrf    PORTB               
    clrf    PORTC               
    clrf    PORTD               
    
    RETURN

oscilador:
    banksel OSCCON		;Ponemos el oscilador interno a 4MHz
    bsf	    OSCCON, 6           
    bsf	    OSCCON, 5           
    bcf	    OSCCON, 4                                 
    bsf	    OSCCON, 0             
    
    RETURN
    
configTMR0: 
    banksel TRISA		;Asignamos el prescaler
    bcf     OPTION_REG, 5     
    bcf     OPTION_REG, 3     
    bsf     OPTION_REG, 2    
    bsf     OPTION_REG, 1     
    bsf     OPTION_REG, 0     
                                
    banksel PORTA		;Aignamos valor N calculado
    movlw   180
    movwf   TMR0                
    bcf     INTCON, 2        
    
    RETURN 
    
interrupciones:
    bsf	    INTCON, 5          ;Habilitamos y limpiamos la interrupción del TMR0
    bcf	    INTCON, 2            
    
    banksel IOCB	    ;Habilitamos las interrpuciones de los botones
    movlw   0b11111111	    
    movwf   IOCB                
    bsf	    INTCON, 3          
    bcf	    INTCON, 0            
    bsf	    INTCON, 7             
    
    RETURN

contbotones:	    ;Contador del PRELAB
    banksel flag
    
    btfsc   flag, 2
    call    inc1
    
    btfsc   flag, 3
    call    dec1
    
    RETURN

displayunits:	    ;Contador del TMR0
    btfsc   flag, 0
    call    inc2
    
    RETURN
    
displaydec:	    ;Contador de decenas
    btfsc   flag, 4
    call    inc3
    
    RETURN
    
inc1:			;Incrementamos contador de botones
    banksel PORTA
    btfsc   PORTA, 4
    clrf    PORTA
    
    incf    PORTA, F
    bcf	    flag, 2
    
    RETURN
    
dec1:			;Decrementamos contador de botones
    banksel PORTA
    btfsc   PORTA, 7
    movlw   0b1111
    btfsc   PORTA, 7
    movwf   PORTA
    
    decf    PORTA, F
    bcf	    flag, 3
    
    RETURN
    
inc2:	    ;Incrementamos TMR0
    banksel PORTC  
    incf    cont2, F
    
    movf    cont2, W
    sublw   10
    btfsc   STATUS, 2
    clrf    cont2
    
    movf    cont2, W
    call    tabla
    movwf   PORTC
    
    bcf	    flag, 0
    
    RETURN

inc3:		;Incrementamos contador de decenas
    incf    cont3, F
    
    movf    cont3, W
    sublw   6
    btfsc   STATUS, 2
    clrf    cont3 
    
    movf    cont3, W
    call    tabla
    movwf   PORTD
    bcf	    flag, 4
    
    RETURN
    
    END
