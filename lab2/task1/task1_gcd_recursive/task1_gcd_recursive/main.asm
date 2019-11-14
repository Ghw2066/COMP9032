;
; task1_gcd_recursive.asm
;
; Created: 2019/10/10 11:43:21
; Author : GHW
;
;int gcd(int a, int b) 
;{    
;	if (b != 0)        
;		return gcd(b, a%b);   
;	else
;       return a;
;} 
 

; Replace with your application code
.include "m2560def.inc"
.def zero = r15			;to store constant value 0
.def al = r22
.def ah = r23
.def bl = r20
.def bh = r21

.macro mod		;a%b a->@1:@0   b->@3@2	
loop:
	cp @0,@2	
	cpc @1,@3
	brsh sbtr
	rjmp done
sbtr:
	sub @0,@2
	sbc @1,@3	
	rjmp loop
done:
.endmacro

.CSEG			;start code segment

main:
	;mod ah,al,bh,bl,r25,r24
	ldi al,low(3500)
	ldi ah,high(3500)
	ldi bl,low(500)
	ldi bh,high(500)
	rcall gcd
	;movw r23:r22,r25:r24
end:
	rjmp end

gcd:
	;prologue
				;Y -> r29:r28 will be used as the frame pointer
	push YL		;save r29:r28 in the stack
	push YH		
	push r16
	push r17
	push zero
	in YL,SPL
	in YH,SPH
	sbiw Y,4

	out SPH,YH	;update the stack pointer to 
	out SPL,YL	;point to the new stack top

	std Y+1,al	;pass a's value to local_a in the function
	std Y+2,ah
	std Y+3,bl	;pass b's value to local_b in the function
	std Y+4,bh
	;End of prologue

	;function body
	clr zero
	cp r20,zero
	cpc r21,zero
	brne L1		;if(b!=0) branch to L1: gcd(b, a%b)

	rjmp L2		;else jump to L2, return a
L1:
	ldd al,Y+3	;load b to a
	ldd ah,Y+4
	ldd bl,Y+1	;load a to b
	ldd bh,Y+2
	;swap the value of a,b
	movw r16:r17,al:ah		;copy b_value to r16:r17
	mod bl,bh,r16,r17		;calculate a%b and put the result in b
	;now a is b, b is a%b

	rcall gcd				;return gcd(b, a%b);

L2:
	adiw Y,4		;deallocate the reserved space
	out SPH,YH
	out SPL,YL
	pop zero		
	pop r17			;restore registers
	pop r16
	pop YH
	pop YL
	ret				;return to main()
	;End of epilogue


