$MODLP51
 
org 0000H
   ljmp MainProgram

CLK  EQU 22118400
BAUD equ 115200
CE_ADC    EQU  P2.0 
MY_MOSI   EQU  P2.1  
MY_MISO   EQU  P2.2 
MY_SCLK   EQU  P2.3 
DSEG at 30H
Result: ds 2
x: ds 4
y: ds 4
bcd: ds 5 

bseg 
mf: dbit 1

BRG_VAL equ (0x100-(CLK/(16*BAUD)))

CSEG

LCD_RS equ P1.1
LCD_RW equ P1.2
LCD_E  equ P1.3
LCD_D4 equ P3.2
LCD_D5 equ P3.3
LCD_D6 equ P3.4
LCD_D7 equ P3.5
$NOLIST
$include(LCD-4bit.inc) ; A library of LCD related functions and utility macros
$LIST
$NOLIST
$include(math32.inc)
$LIST






Delay:

    mov R2, #89
K3: mov R1, #250
K2: mov R0, #166
K1: djnz R0, K1 ; 3 cycles->3*45.21123ns*166=22.51519us
    djnz R1, K2 ; 22.51519us*250=5.629ms
    djnz R2, K3 ; 5.629ms*89=0.5s (approximately)
    ret
; Configure the serial port and baud rate
InitSerialPort:
    ; Since the reset button bounces, we need to wait a bit before
    ; sending messages, otherwise we risk displaying gibberish!
    mov R1, #222
    mov R0, #166
    djnz R0, $   ; 3 cycles->3*45.21123ns*166=22.51519us
    djnz R1, $-4 ; 22.51519us*222=4.998ms
    ; Now we can proceed with the configuration
	orl	PCON,#0x80
	mov	SCON,#0x52
	mov	BDRCON,#0x00
	mov	BRL,#BRG_VAL
	mov	BDRCON,#0x1E ; BDRCON=BRR|TBCK|RBCK|SPD;
    ret

INIT_SPI:     
setb MY_MISO    ; Make MISO an input pin     
clr MY_SCLK     ; For mode (0,0) SCLK is zero     
ret

DO_SPI_G:    
push acc     
mov R1, #0      ; Received byte stored in R1 
mov R2, #8      ; Loop counter (8-bits)

DO_SPI_G_LOOP:     
mov a, R0       ; Byte to write is in R0     
rlc a           ; Carry flag has bit to write    
mov R0, a     
mov MY_MOSI, c  
setb MY_SCLK    ; Transmit     
mov c, MY_MISO  ; Read received bit
mov a, R1       ; Save received bit in R1     
rlc a     
mov R1, a     
clr MY_SCLK     
djnz R2, DO_SPI_G_LOOP 
pop acc     
ret 

getchar: 
jnb RI, getchar
clr RI 
mov a, SBUF
ret


; Send a character using the serial port
putchar:
    jnb TI, putchar
    clr TI
    mov SBUF, a
    ret

; Send a constant-zero-terminated string using the serial port
SendString:
    clr A
    movc A, @A+DPTR
    jz SendStringDone
    lcall putchar
    inc DPTR
    sjmp SendString
SendStringDone:
    ret  
    
Send_BCD mac
	push ar0
	mov r0, %0
	lcall ?Send_BCD
	pop ar0
	endmac
	
?Send_BCD:
push acc; Write most significant digit
mov a, r0
swap a
anl a, #0fh
orl a, #30h
lcall putchar; write least significant digit
mov a, r0
anl a, #0fh
orl a, #30h
lcall putchar
pop acc
ret	

next_line:
db '\n','\r ',0

MainProgram:
    mov SP, #7FH ; Set the stack pointer to the begining of idata
    lcall LCD_4BIT
    lcall InitSerialPort
    ;mov DPTR, #Hello_World
    ;lcall SendString
    lcall INIT_SPI
    
    Forever: 
    clr CE_ADC 
    mov R0, #00000001B; Start bit:1
    lcall DO_SPI_G

    mov R0, #10000000B; Single ended, read channel 0 
    lcall DO_SPI_G 
    mov a, R1          ; R1 contains bits 8 and 9
    anl a, #00000011B  ; We need only the two least significant bits 
    mov Result+1, a    ; Save result high
    
    mov R0, #55H; It doesn't matter what we transmit... 
    lcall DO_SPI_G 
    mov Result, R1  ; R1 contains bits 0 to 7.  Save result low. 
    setb CE_ADC 
    lcall Delay
	lcall Delay
	
	
	mov x,Result
	mov x+1,Result+1
	mov x+2,#0
	mov x+3,#0

	

    load_y (410)
    lcall mul32
    
    load_y (1023)
    lcall div32
    
    load_y(273)
    lcall sub32
	
	lcall hex2bcd
	send_BCD(bcd+1)
	send_BCD(bcd+0)
	
	
	mov DPTR, #next_line
    lcall SendString
    
    sjmp Forever
    sjmp $ ; This is equivalent to 'forever: sjmp forever'
    
END
