;
; lab1_task2.asm
;
; Created: 2019/10/3 12:19:02
; Author : Haowen Guo
;


; Replace with your application code
;int a, b; /* Initialized elsewhere */
;while (a!=b)
;{ /* Assume a, b > 0 */
;if (a>b)
;a = a - b;
;else
;b = b - a;
;}
;return 0; /* a and b both hold the result */
.include "m2560def.inc"

.def ah = r10
.def al = r11
.def bh = r12
.def bl = r13

.dseg
.org 0x200

.cseg

loop:
	
	;cp bl,al
	;cpc bh,ah
	
	cp bl,al
	cpc bh,ah		;compare b , a
	breq end		;while(a!=b) ;; if a==b branch to the end of loop
	brlt case1		;if(b<a) branch to case1
	jmp case2		;else to case2

	case1:
		sub al,bl
		sbc ah,bh	;a = a - b
		jmp loop	;go back to the next loop

	case2:
		sub bl,al
		sbc bh,ah	;b = b - a
		jmp loop	;go back to the next loop	
	

end:
    rjmp end
