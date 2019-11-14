;
; task1.asm
;
; Created: 2019/10/10 09:31:43
; Author : GHW
;


; Replace with your application code

.include "m2560def.inc"
.def a_high = r16
.def a_low = r17
.def b_high =r18
.def b_low =r19
.def zero = r24


.macro mod
loop:
	cp @0,@1           
	cpc @2,@3           ;compare a, b
	brsh a_higher       ;a>=b 
	brlo exit           ;a<b 
a_higher:
	sub @0,@1
	sbc @2,@3           ;a <-- a-b
	rjmp loop
exit:
	nop                 ; exit from macro
.endmacro

  rcall gcd

end:
rjmp end

gcd:
   push YL
   push YH
   push zero
   push r20
   push r21
   in YL,SPL
   in YH,SPH
   sbiw Y,4
   out SPH,YH
   out SPL,YL

   std Y+1,a_low
   std Y+2,a_high
   std Y+3,b_low
   std Y+4,b_high
   clr zero
   cp b_low,zero             
   cpc b_high,zero 
   brne  L1
   jmp L2

L1:
   ldd a_low,Y+1
   ldd a_high,Y+2
   ldd b_low,Y+3
   ldd b_high,Y+4
   movw r21:r20,b_high:b_low          ;use temp pair to store b
   mod a_low,b_low,a_high,b_high   ;a <-- a%b
   movw b_high:b_low,a_high:a_low     ;b <-- a%b
   movw a_high:a_low,r21:r20          ;a <-- b
   rcall gcd

L2:
   adiw Y,4
   out SPH,YH
   out SPL,YL
   pop r21
   pop r20
   pop zero
   pop YH
   pop YL
   ret


