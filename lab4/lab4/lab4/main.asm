;
; lab4.asm
;
; Created: 2019/11/7 16:27:48
; Author : GHW
;


; Replace with your application code
.include "m2560def.inc"

.macro do_lcd_command
	ldi r16, @0
	rcall lcd_command
	rcall lcd_wait
.endmacro
.macro do_lcd_data
	ldi r16, @0
	rcall lcd_data
	rcall lcd_wait
.endmacro
.macro do_lcd_data_register
	mov r16, @0
	rcall lcd_data
	rcall lcd_wait
.endmacro

;@0:ZH @1:ZL @2:XH @3:XL @4:YH @5:YL
.macro DivMod
DMod:						;X stands for 10000, 1000, 100 or 10
	cp @1, @3         
	cpc @0, @2				;compare Z, X
	brsh higher				;Z>=X
	brlo exit				;Z<X 
higher:
	sub @1, @3
	sbc @0, @2				;Z <-- Z-10
							;mod result in Z
	adiw @4:@5, 1			;div result in temp1:temp2
	rjmp DMod
exit:
	;out PORTC, @0
	;subi @5, -'0'
	;do_lcd_data_register @5              ; display the result of mod(10)
.endmacro

;.org 0
;	jmp RESET
.def temp = r17
	
	jmp RESET
.org INT0addr
	jmp EXT_INT0

RESET:

	ldi r16, low(RAMEND)
	out SPL, r16
	ldi r16, high(RAMEND)
	out SPH, r16

	ser r16
	out DDRF, r16
	out DDRA, r16
	clr r16
	out PORTF, r16
	out PORTA, r16

	do_lcd_command 0b00111000 ; 2x5x7
	rcall sleep_5ms
	do_lcd_command 0b00111000 ; 2x5x7
	rcall sleep_1ms
	do_lcd_command 0b00111000 ; 2x5x7
	do_lcd_command 0b00111000 ; 2x5x7
	do_lcd_command 0b00001000 ; display off

	do_lcd_command 0b00000001 ; clear display
	do_lcd_command 0b00000110 ; increment, no display shift
	do_lcd_command 0b00001110 ; Cursor on, bar, no blink

	ldi temp,(2<<ISC00)			;set INTO as falling edge triggered interrupt
	sts EICRA, temp

	in temp,EIMSK
	ori temp,(1<<INT0)
	out EIMSK,temp

	sei 
	jmp main

EXT_INT0:
	push temp			;save register
	in temp, SREG		;save SREG
	push temp

	adiw ZH:ZL, 1

	pop temp			;restore SREG
	out SREG,temp
	pop temp			;restore register
	reti

main:
speed_loop:

	do_lcd_data 'R'
	do_lcd_data 'P'
	do_lcd_data 'S'
	do_lcd_data ':'
	do_lcd_data ' '
	
	clr ZL			;Z: speed
	clr ZH
	;sbi DDRD,2		;set Port D TDX2 as 0 for input
	clr YL
	clr YH
	clr XH
	ldi XL,4
	rcall speed_avg_1s
	DivMod ZH,ZL,XH,XL,YH,YL
	mov ZL,YL
	mov ZH,YH
output:					;output rps to LCD
	clr YL
	clr YH
	clr XH
	clr XL

	cpi ZL, 100
	brsh digitnext3
	do_lcd_data '0'
	cpi ZL, 10
	brsh digitnext2
	do_lcd_data '0'

digitnext3:
	clr YH
	clr YL
	ldi XH, high(100)
	ldi XL, low(100)
	cp ZL, XL
	cpc ZH, XH
	brlo digitnext2
	DivMod ZH,ZL,XH,XL,YH,YL
	subi YL, -'0'
	do_lcd_data_register YL
	cpi ZL, 10
	brsh digitnext2
	do_lcd_data '0'
digitnext2:
	clr YH
	clr YL
	ldi XH, high(10)
	ldi XL, low(10)
	cp ZL, XL
	cpc ZH, XH
	brlo digitnext1
	DivMod ZH,ZL,XH,XL,YH,YL
	subi YL, -'0'
	do_lcd_data_register YL

digitnext1:
	clr YH
	clr YL
	subi ZL, -'0'
	do_lcd_data_register ZL

	do_lcd_command 0b00000011		; cursor move to the leftmost
	rjmp speed_loop

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
; Send a command to the LCD (r16)
;

lcd_command:
	out PORTF, r16
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
	out PORTF, r16
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
	push r16
	clr r16
	out DDRF, r16
	out PORTF, r16
	lcd_set LCD_RW
lcd_wait_loop:
	nop
	lcd_set LCD_E
	nop
	nop
    nop
	in r16, PINF
	lcd_clr LCD_E
	sbrc r16, 7
	rjmp lcd_wait_loop
	lcd_clr LCD_RW
	ser r16
	out DDRF, r16
	pop r16
	ret

.equ F_CPU = 16000000
.equ DELAY_1MS = F_CPU / 4 / 1000 - 4
; 4 cycles per iteration - setup/call-return overhead

sleep_1ms:
	push r24
	push r25

	;sbis PIND,2			;skip if TDX2 is set
	;adiw ZH:ZL, 1

	ldi r25, high(DELAY_1MS)
	ldi r24, low(DELAY_1MS)
delayloop_1ms:
	sbiw r25:r24, 1
	brne delayloop_1ms
	pop r25
	pop r24
	ret

sleep_5ms:
	

	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	ret
speed_avg_1s:
	push r23
	ldi r23,200
delay_1s:
	rcall sleep_5ms
	subi r23,1
	brne delay_1s
	pop r23
	ret

