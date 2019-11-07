;
; lab_1.asm
;
; Created: 2019/9/23 16:24:24
; Author : Haowen Guo
;


; Replace with your application code
.include "m2560def.inc"

.def al = r18		;low digit 0x38
.def ah = r19		;high digit decimal -> 0x37 hex -> 0xB7
.def hl = r20		;store the high value
.def hh = r21		;store the low value
.def dl = r16		;for the purpose of comparing low
.def dh = r17		;for the purpose of comparing high
.def b = r22		;store the final binary result 

.dseg
.org 0x200



.cseg
	
	sbrc ah,7		;if 7th digit is 1, then go to case2:hex, else jump to case1:decimal
	jmp case2

case1:				;calculate the decimal to binary
	mov dh,ah		;copy the low value
	mov dl,al		;copy the high value
	subi dh,$30		;get the real value of decimal
	subi dl,$30		;get the real value of decimal

	ldi hl,10		;load 10 to hl
	mul dh,hl		;calculate the real high decimal value
	mov dh,r0		;get the mul result
	
	add dh,dl		;add high and low
	mov b,dh		;get the result
	jmp end

case2:
	subi ah,0b10000000		;remove flag bit

	mov dh,ah		;copy the high value 
	mov dl,al		;copy the low value

	subi dh,$41		;compare the value of $41, which means >= 'A' or not
	brsh higherthanA1		;if higher or equal to 'A', then go to get the real value of high digit
higherthanA1:
	subi ah,$37		;get the real value of high digit
	jmp secdigit	;jump to the low digit

	subi ah,$30		;if not >= 'A', get the real value of number

secdigit:
	subi dl,$41		;compare the value of $41, which means >= 'A' or not
	brsh higherthanA2		;if higher or equal to 'A', then go to get the real value of low digit
higherthanA2:
	subi al,$37		;get the real value of high digit
	jmp next		;jump to the low digit

	subi al,$30		;if not >= 'A', get the real value of number

next:
	mov hh,ah		;copy the value of ah
	mov hl,al		;copy the value of al
	
	swap hh					;swap digit to high position
	mov b,hh				
	add b,hl		;b binaty result for hex
	;mov dh,hh		;nothing

end:	rjmp end	



	