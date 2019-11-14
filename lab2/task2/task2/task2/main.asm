;
; task2.asm
;
; Created: 2019/10/17 11:20:41
; Author : z5251113
;


; Replace with your application code
.include "m2560def.inc"
.equ loop_count = 50000
.def iH = r25
.def iL = r24
.def countH = r17
.def countL = r16
.def tmp = r18
.macro halfSecondDelay
	ldi countL, low(loop_count)
	ldi countH, high(loop_count)
	clr iH
	clr iL
loop:
	cp iL, countL
	cpc iH, countH
	brsh done
	adiw iH:iL, 1
	clr r19				;6 cycles
	
innerloop:
	cpi r19, 30		;30*5 = 150	cycles
	brsh jmpout
	inc r19
	rjmp innerloop
jmpout:	
	nop
	nop
	rjmp loop		;4	cycles
done:				;160 cycles in total
.endmacro			;160 * 50000 = 8 * 10 pow 6

	ser r18
	out DDRC, r18	;set Port C for output
	cbi DDRD,0		;set Port D bit7 as 0 for input
	
start:

	ldi r18, 0xAA	;write the pattern
	out PORTC, r18
	halfSecondDelay			
pattern1:	
	sbis PIND,0	
	rjmp end	

	
	ldi r18, 0x11	
	out PORTC, r18
	halfSecondDelay			
pattern2:	
	sbis PIND,0	
	rjmp end	


	ldi r18, 0x66
	out PORTC, r18
	halfSecondDelay		
pattern3:	
	sbis PIND,0	
	rjmp end	

	rjmp start

end:
	rjmp end

