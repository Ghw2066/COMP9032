;
; lab3.asm
;
; Created: 2019/10/31 16:05:35
; Author : GHW
;


; The program gets input from keypad and displays its ascii value on LEDs and string value on LCD.
; Port F is used for keypad, high 4 bits for column selection, low four bits for reading rows. On the board, RF7-4 connect to C3-0, RF3-0 connect to R3-0. L
; Port C is used to display the ASCII value of a key.

.include "m2560def.inc"

.def ten = r23
.def row = r16		; current row number
.def col = r17		; current column number
.def rmask = r18	; mask for current row
.def cmask = r19	; mask for current column
.def temp1 = r20
.def temp2 = r21
.def flag = r13
.def num1 = r14
.def num2 = r15

.equ PORTLDIR = 0xF0		; use PortL for input/output from keypad: PL7-4, output, PL3-0, input
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
	subi @5, -'0'
	do_lcd_data_register @5              ; display the result of mod(10)
.endmacro
;rjmp	RESET

RESET:

	ldi temp1,PORTLDIR		; columns are outputs, rows are inputs
	sts DDRL, temp1
	clr num1				;store the first number
	clr num2				;store the second number
	clr flag				;flag is to indicate whether the first number or the second
	ldi ten, 10
	ser temp1				; PORTC is outputs
	out DDRC,temp1
	out PORTC,temp1
	
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
	do_lcd_command 0b00001110 ; Cursor on, bar, no blink


main:
	ldi cmask, INITCOLMASK	; initial column mask
	clr col					; initial column

	colloop:
		cpi col,4
		breq main
		sts PORTL,cmask		; set column to mask value (one column off)

		ldi temp1,0xFF
	delay:
		dec temp1
		brne delay

		lds temp1,PINL		; read PORTL
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
	
	;out PORTC, temp1			; write value to PORTC
	do_lcd_data_register temp1
		
	cpi temp1, '*'				
	breq multiply				; if input from keypad is '*', go to multiply
	cp flag, ten
	breq secnum					; if flag == ten, go to the second number

firstnum:
	ser temp2
	subi temp1, '0'				; turn string number into real value
	
	mul num1, ten				
	mov num1, r0

	sub temp2, temp1			; check if there is a overflow
	cp temp2, num1
	brlo overfl 

	add num1, temp1				; add the value from keypad this time into num1  
	out PORTC, num1				; display this num1 on LED in binaray form
	rcall sleep_500ms
	jmp main

multiply:
	;out PORTC, num1				
	mov flag, ten				; set flag = ten, which means the first num has been finished
	rcall sleep_500ms
	jmp main

secnum:
	cpi temp1, '#'				; check if input is '#', go to result
	breq result

	ser temp2					
	subi temp1, '0'
	mul num2, ten				
	mov num2, r0

	sub temp2, temp1			; check if overflow occurs
	cp temp2, num2
	brlo overfl 	

	add num2, temp1				; add the value from keypad this time into num2
	out PORTC, num2				; display this num1 on LED in binaray form
	rcall sleep_500ms
	jmp main

overfl:							; flash three times
	ser temp2
	out PORTC, temp2
	rcall sleep_500ms
	clr temp2
	out PORTC, temp2
	rcall sleep_500ms
	
	ser temp2
	out PORTC, temp2
	rcall sleep_500ms
	clr temp2
	out PORTC, temp2
	rcall sleep_500ms

	ser temp2
	out PORTC, temp2
	rcall sleep_500ms
	clr temp2
	out PORTC, temp2
	rcall sleep_500ms
	jmp halt


result:					
	mul num1, num2				; calculate the result of num1 * num2
	movw ZH:ZL, r1:r0			; store in Z
	cpi ZH,1
	brsh overfl
	;mov num1, r0
	;subi num1, -'0'
	;out PORTC, num1

output:
	clr YH
	clr YL
	ldi XH, high(10000)
	ldi XL, low(10000)
	cp ZL, XL
	cpc ZH, XH
	brlo digitnext4
	DivMod ZH,ZL,XH,XL,YH,YL
	ldi XH, high(1000)
	ldi XL, low(1000)
	cp ZL, XL
	cpc ZH, XH
	brsh digitnext4
	do_lcd_data '0'
	cpi ZL, 100
	brsh digitnext3
	do_lcd_data '0'
	cpi ZL, 10
	brsh digitnext2
	do_lcd_data '0'

digitnext4:
	clr YH
	clr YL
	ldi XH, high(1000)
	ldi XL, low(1000)
	cp ZL, XL
	cpc ZH, XH
	brlo digitnext3
	DivMod ZH,ZL,XH,XL,YH,YL
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

digitnext1:
	clr YH
	clr YL
	subi ZL, -'0'
	do_lcd_data_register ZL
	out PORTC, ZL
	rcall sleep_500ms
	jmp halt


halt:
	jmp halt					

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