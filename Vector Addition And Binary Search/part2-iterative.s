.global _start
array: .word -4, -1, 0, 1, 3, 5, 8, 10
x: .word 3
lowIdx: .word 0
highIdx: .word 6


binarySearch:
	push {r4-r5}
	
while:
	
	cmp r3, r2
	//are we done?
	ble searchDone
	
	//index in middle (r4)
	add r4, r3, r2
	lsr r4, r4, #1 // r4 = mid
	
	mov r5, #4 // value at mid
	mul r5, r4, r5
	ldr r5, [r0, r5]
	cmp r1, r5 
	beq ifMid
	bgt ifBigger // if x > value at mid
	
	sub r3, r4, #1
	
	B while

searchDone:
	mov r4, #4
	mul r4, r2, r4
	ldr r4, [r0, r4]
	cmp r4, r1
	beq ifDone
	
	mov r0, #-1
	pop {r4-r5}
	bx lr 

ifDone:
	mov r0, r2
	pop {r4-r5}
	bx lr 
	
ifMid:
	mov r0, r4
	pop {r4-r5}
	bx lr 
	
ifBigger:
	add r2, r4, #1
	b while

_start: 
ldr	r0, =array  
ldr	r1, x  
ldr r2, lowIdx
ldr r3, highIdx
BL binarySearch

inf: 
	B 	inf     // infinite loop!
