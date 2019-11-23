;
; FinalProject.asm
;
; Created: 2019/11/19 2:20:18
; Author : GHW

; The program gets input from keypad and displays its ascii value on LEDs and string value on LCD.

; Port K is used for keypad, high 4 bits for column selection, low four bits for reading rows. On the board, PK15-PK12 connect to C3-0, PK11-PK8 connect to R3-0. K
; Port C is used to display the ASCII value of a key.

.include "m2560def.inc"

.def temp = r23
.def row = r16		; current row number
.def col = r17		; current column number
.def rmask = r18	; mask for current row
.def cmask = r19	; mask for current column
.def temp1 = r20
.def temp2 = r21


.equ PORTKDIR = 0xF0		; use PortL for input/output from keypad: PL7-4, output, PL3-0, input
.equ ROWMASK = 0x0F			; low four bits are output from the keypad. This value mask the high 4 bits.
.equ INITCOLMASK = 0xEF		; scan from the leftmost column, the value to mask output
.equ INITROWMASK = 0x01		; scan from the bottom row


.macro do_lcd_command
	ldi r22, @0
	rcall lcd_command
	rcall lcd_wait
.endmacro
.macro do_lcd_data
	ldi r22, @0
	rcall lcd_data
	rcall lcd_wait
.endmacro
.macro do_lcd_data_register
	mov r22, @0
	rcall lcd_data
	rcall lcd_wait
.endmacro
.macro displayLocal 
	cpi @0,0
	breq play0
	cpi @0,1
	breq play1
	cpi @0,2
	breq play2
	cpi @0,3
	breq play3
	jmp main
play0:
	ldi temp1,0x00
	rjmp endm
play1:
	ldi temp1,0x55
	rjmp endm
play2:
	ldi temp1,0xAA
	rjmp endm
play3:
	ldi temp1,0xFF
	rjmp endm
endm:
.endmacro

	jmp RESET
.org INT0addr
	jmp EXT_INT0
.org INT1addr
	jmp EXT_INT1


RESET:
	clr YL
	clr YH
	clr ZL
	clr ZH

	ldi temp1,PORTKDIR		; columns are outputs, rows are inputs
	sts DDRK, temp1
	
	;ser temp1				; PORTC is outputs
	;sts DDRL,temp1

	ldi temp1, 0b00111000
	sts DDRL,temp1			;

	ldi temp1, 0b00001000
	out DDRE, temp1

	clr temp1
	sts OCR5AH,temp1
	sts OCR5BH,temp1
	sts OCR5CH,temp1
	sts OCR3AH,temp1

	ldi temp1,0x00
	sts OCR5AL,temp1
	sts OCR5BL,temp1
	sts OCR5CL,temp1

	sts OCR3AL,temp1

	ldi temp1,(1<<CS50)
	sts TCCR5B,temp1
	ldi temp1,(1<<CS30)
	sts TCCR3B,temp1
	ldi temp1,(1<<WGM50)|(1<<COM5A1)|(1<<COM5B1)|(1<<COM5C1)	;
	sts TCCR5A,temp1

	ldi temp1,(1<<WGM30)|(1<<COM3A1)
	sts TCCR3A,temp1

	;rcall sleep_500ms
	;ldi temp1,0x00
	;sts OCR5AL,temp1
	;sts OCR5BL,temp1
	;sts OCR5CL,temp1
	;sts OCR3AL,temp1
	
	ldi r22, low(RAMEND)
	out SPL, r22
	ldi r22, high(RAMEND)
	out SPH, r22

	ser r22
	out DDRF, r22
	out DDRA, r22
	clr r22
	out PORTF, r22
	out PORTA, r22

	do_lcd_command 0b00111000 ; 2x5x7
	rcall sleep_10ms
	do_lcd_command 0b00111000 ; 2x5x7
	rcall sleep_2ms
	do_lcd_command 0b00111000 ; 2x5x7
	do_lcd_command 0b00111000 ; 2x5x7
	do_lcd_command 0b00001000 ; display off
	do_lcd_command 0b00000001 ; clear display
	do_lcd_command 0b00000110 ; increment, no display shift
	do_lcd_command 0b00001111 ; Cursor on, bar, no blink
	
	do_lcd_data 'S'
	do_lcd_data ':'
	do_lcd_data ' '
	do_lcd_data 'W'
	do_lcd_data '1'
	do_lcd_data ' '
	do_lcd_data 'W'
	do_lcd_data '2'
	do_lcd_data ' '
	do_lcd_data 'W'
	do_lcd_data '3'
	do_lcd_data ' '
	do_lcd_data 'W'
	do_lcd_data '4'
	do_lcd_command 0b10101011
	do_lcd_data '0'
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data '0'
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data '0'
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data '0'

	rcall sleep_500ms
	rcall sleep_500ms
	rcall sleep_500ms
	rcall sleep_500ms
	rcall sleep_500ms
	rcall sleep_500ms
	rcall sleep_500ms
	rcall sleep_500ms
	rcall sleep_500ms
	rcall sleep_500ms

	ldi temp, 0b00000010
	out DDRD, temp
	out PORTD, temp

	ldi temp,(2<<ISC00)|(2<<ISC10)		;set INTO and INT1 as falling edge triggered interrupts
	sts EICRA, temp

	in temp,EIMSK
	ori temp,(1<<INT0)|(1<<INT1)
	out EIMSK,temp

	sei 
	jmp main

EXT_INT0:
	push temp			;save register
	in temp, SREG		;save SREG
	push temp

	
	;clr temp1
	do_lcd_command 0b00000001 ; clear display
	
	ldi temp1,0x00
	sts OCR5AL,temp1
	sts OCR5BL,temp1
	sts OCR5CL,temp1
	sts OCR3AL,temp1
	do_lcd_data '!'
	do_lcd_data '!'
	do_lcd_data ' '
	do_lcd_data 'W'
	do_lcd_data '1'
	do_lcd_data ' '
	do_lcd_data 'W'
	do_lcd_data '2'
	do_lcd_data ' '
	do_lcd_data 'W'
	do_lcd_data '3'
	do_lcd_data ' '
	do_lcd_data 'W'
	do_lcd_data '4'
	do_lcd_command 0b10101011
	do_lcd_data '0'
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data '0'
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data '0'
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data '0'
	
	rcall sleep_500ms

	pop temp			;restore SREG
	out SREG,temp
	pop temp			;restore register
	reti

EXT_INT1:
	push temp
	in temp, SREG
	push temp

	do_lcd_command 0b00000001 ; clear display
	cpi temp2,1
	breq cdark
	jmp cclear

cdark:
	
	ldi temp1,0xFF
	sts OCR5AL,temp1
	sts OCR5BL,temp1
	sts OCR5CL,temp1
	sts OCR3AL,temp1
	do_lcd_data 'C'
	do_lcd_data ':'
	do_lcd_data ' '
	do_lcd_data 'W'
	do_lcd_data '1'
	do_lcd_data ' '
	do_lcd_data 'W'
	do_lcd_data '2'
	do_lcd_data ' '
	do_lcd_data 'W'
	do_lcd_data '3'
	do_lcd_data ' '
	do_lcd_data 'W'
	do_lcd_data '4'
	do_lcd_command 0b10101011
	
	do_lcd_data '3'
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data '3'
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data '3'
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data '3'

	rcall sleep_500ms
	jmp int1end

cclear:
	
	ldi temp1,0x00
	sts OCR5AL,temp1
	sts OCR5BL,temp1
	sts OCR5CL,temp1
	sts OCR3AL,temp1
	do_lcd_data 'C'
	do_lcd_data ':'
	do_lcd_data ' '
	do_lcd_data 'W'
	do_lcd_data '1'
	do_lcd_data ' '
	do_lcd_data 'W'
	do_lcd_data '2'
	do_lcd_data ' '
	do_lcd_data 'W'
	do_lcd_data '3'
	do_lcd_data ' '
	do_lcd_data 'W'
	do_lcd_data '4'
	do_lcd_command 0b10101011
	do_lcd_data '0'
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data '0'
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data '0'
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data '0'
	
	rcall sleep_500ms

int1end:
	sbi PORTD,1			;set bit for INT1
	pop temp
	out SREG,temp
	pop temp
	reti

main:
	ldi cmask, INITCOLMASK	; initial column mask
	clr col					; initial column

	colloop:
		cpi col,4
		breq main
		sts PORTK,cmask		; set column to mask value (one column off)

		ldi temp1,0xFF
	delay:
		dec temp1
		brne delay

		lds temp1,PINK		; read PORTL
		andi temp1,ROWMASK
		cpi temp1,0xF		; check if any rows are on
		breq nextcol
							; if yes, find which row is on
		ldi rmask,INITROWMASK	; initialise row check
		clr row				; initial row

		rowloop:
			cpi row,4
			breq nextcol
			mov temp2,temp1
			and temp2,rmask	; check masked bit
			breq convert	; if bit is clear, convert the bitcode
			inc row			; else move to the next row
			lsl rmask		; shift the mask to the next bit
			jmp rowloop

	nextcol:
		lsl cmask			; else get new mask by shifting and 
		inc col				; increment column value
		jmp colloop			; and check the next column

convert:
	cpi col, 3				; if column is 3 we have a letter
	breq letters


	cpi row, 3				; if row is 3 we have a symbol or 0
	breq symbols

	mov	temp1,row			; otherwise we have a number in 1-9
	lsl temp1
	add temp1, row				; temp1 = row * 3
	add temp1, col				; add the column address to get the value, temp = row*3+col
	subi temp1, -'1'			; add the value of character '1', temp = '1' + row*3 + col
	jmp convert_end

letters:
	ldi temp1, 'A'
	add temp1, row				; increment the character 'A' by the row value
	jmp convert_end

symbols:
	cpi col, 0					; check if we have a star
	breq star
	cpi col, 1					; or if we have zero
	breq zero					
	ldi temp1, '#'				; if not we have hash
	jmp convert_end
star:
	ldi temp1, '*'				; set to star
	jmp convert_end
zero:
	ldi temp1, '0'				; set to zero

convert_end:
	clr temp2
	;out PORTC, temp1			; write value to PORTC
	;do_lcd_data_register temp1
	
	cpi temp1, 'A'
	brne next1
	jmp central_clear
next1:
	cpi temp1, 'B'
	brne next2
	jmp central_dark
next2:
	do_lcd_command 0b00000001
	do_lcd_data 'L'
	do_lcd_data ':'
	do_lcd_data ' '
	do_lcd_data 'W'
	do_lcd_data '1'
	do_lcd_data ' '
	do_lcd_data 'W'
	do_lcd_data '2'
	do_lcd_data ' '
	do_lcd_data 'W'
	do_lcd_data '3'
	do_lcd_data ' '
	do_lcd_data 'W'
	do_lcd_data '4'
	do_lcd_command 0b10101011
	cpi temp1, '2'
	brne next3
	jmp YLinc
next3:
	cpi temp1, '3'
	brne next4
	jmp YLdec
next4:
	cpi temp1, '4'
	brne next5
	jmp YHinc
next5:
	cpi temp1, '5'
	brne next6
	jmp YHdec
next6: 
	cpi temp1, '6'
	brne next7
	jmp ZLinc
next7:
	cpi temp1, '7'
	brne next8
	jmp ZLdec
next8:
	cpi temp1, '8'
	brne next9
	jmp ZHinc
next9:
	cpi temp1, '9'
	brne next10
	jmp ZHdec
next10:
	jmp main

YLinc:
	inc YL
	mov r27, YL
	displayLocal r27
	sts OCR5AL,temp1
	jmp endl
YLdec:
	dec YL
	mov r27, YL
	displayLocal r27
	sts OCR5AL,temp1
	jmp endl
YHinc:
	inc YH
	mov r27, YH
	displayLocal r27
	sts OCR5BL,temp1
	jmp endl
YHdec:
	dec YH
	mov r27, YH
	displayLocal r27
	sts OCR5BL,temp1
	jmp endl
ZLinc:
	inc ZL
	mov r27, ZL
	displayLocal r27
	sts OCR5CL,temp1
	jmp endl
ZLdec:
	dec ZL
	mov r27, ZL
	displayLocal r27
	sts OCR5CL,temp1
	jmp endl
ZHinc:
	inc ZH
	mov r27, ZH
	displayLocal r27
	sts OCR3AL,temp1
	jmp endl
ZHdec:
	dec ZH
	mov r27, ZH
	displayLocal r27
	sts OCR3AL,temp1
	jmp endl

central_clear:
	ldi temp2,0
	cbi PORTD,1					;generate an INT1 request
	jmp main

central_dark:
	ldi temp2,1
	cbi PORTD,1					;generate an INT1 request
	jmp main
		
endl:
	mov r27,YL
	subi r27,-'0'	
	do_lcd_data_register r27
	do_lcd_data ' '
	do_lcd_data ' '
endyh:
	mov r27,YH
	subi r27,-'0'	
	do_lcd_data_register r27
	do_lcd_data ' '
	do_lcd_data ' '
endzl:
	mov r27,ZL
	subi r27,-'0'	
	do_lcd_data_register r27
	do_lcd_data ' '
	do_lcd_data ' '
endzh:
	mov r27,ZH
	subi r27,-'0'	
	do_lcd_data_register r27 
	rcall sleep_500ms
	jmp main
	

halt:
	rjmp halt					

.equ LCD_RS = 7
.equ LCD_E = 6
.equ LCD_RW = 5
.equ LCD_BE = 4

.macro lcd_set
	sbi PORTA, @0
.endmacro
.macro lcd_clr
	cbi PORTA, @0
.endmacro

;
; Send a command to the LCD (r22)
;

lcd_command:
	out PORTF, r22
	nop
	lcd_set LCD_E
	nop
	nop
	nop
	lcd_clr LCD_E
	nop
	nop
	nop
	ret

lcd_data:
	out PORTF, r22
	lcd_set LCD_RS
	nop
	nop
	nop
	lcd_set LCD_E
	nop
	nop
	nop
	lcd_clr LCD_E
	nop
	nop
	nop
	lcd_clr LCD_RS
	ret

lcd_wait:
	push r22
	clr r22
	out DDRF, r22
	out PORTF, r22
	lcd_set LCD_RW
lcd_wait_loop:
	nop
	lcd_set LCD_E
	nop
	nop
    nop
	in r22, PINF
	lcd_clr LCD_E
	sbrc r22, 7
	rjmp lcd_wait_loop
	lcd_clr LCD_RW
	ser r22
	out DDRF, r22
	pop r22
	ret

.equ F_CPU = 16000000
.equ DELAY_2MS = F_CPU / 4 / 500 - 4
; 4 cycles per iteration - setup/call-return overhead

sleep_2ms:
	push r24
	push r25
	ldi r25, high(DELAY_2MS)
	ldi r24, low(DELAY_2MS)
delayloop_2ms:
	sbiw r25:r24, 1
	brne delayloop_2ms
	pop r25
	pop r24
	ret

sleep_10ms:
	rcall sleep_2ms
	rcall sleep_2ms
	rcall sleep_2ms
	rcall sleep_2ms
	rcall sleep_2ms
	ret

sleep_500ms:
	push r26
	ldi r26,50
delay_500ms:
	rcall sleep_10ms
	subi r26,1
	brne delay_500ms
	pop r26
	ret