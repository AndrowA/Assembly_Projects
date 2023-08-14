.global _start
// int a[2] = {{-1, 2}, {3, -4}};
matrixA: .short -1, 2, 3, -4
// int b[2] = {{6, -3}, {2, 4}};
matrixB: .short 6, -3, 2, 4
// int c[2] = {{0, 0}, {0, 0}};
matrixC: .short 0, 0, 0, 0

multiply:
	PUSH {r4-r11}

start:
	
	// For u = (cc - aa)*(CC - DD) (r3)				
	ldrsh r6, [r0] //aa
	ldrsh r7, [r0, #4] //cc
	sub r8, r7, r6 // cc - aa
	ldrsh r6, [r1,#6] // DD
	ldrsh r7, [r1,#2] //CC
	sub r9, r7, r6 // CC - DD
	mul r3, r9, r8 // u 
	
	// For v = (cc + dd)*(CC - AA) (r4)
	ldrsh r6, [r1]
	sub r8, r7, r6 //CC - AA
	ldrsh r6, [r0, #4] //cc
	ldrsh r7, [r0, #6] //dd
	add r9, r7, r6 // cc+dd
	mul r4, r9, r8 // u 
	
	// For w = aa*AA + (cc + dd - aa)*(AA + DD - CC) (r5)
	ldrsh r6, [r0] 
	ldrsh r7, [r1] 
	mul r8, r6, r7 //aa*AA
	sub r9, r9, r6 // cc + dd - aa
	ldrsh r10, [r1,#6] // DD
	ldrsh r11, [r1, #2] // CC
	add r10, r10, r7 // AA + DD
	sub r10, r10, r11 // AA + DD - CC
	mul r11, r9, r10 // (cc + dd - aa)*(AA + DD - CC)
	add r5, r11, r8  
	
	// *c = aa*AA + bb*BB;
	ldrsh r6, [r0] //aa
	ldrsh r7, [r1] //AA
	mul r6, r6, r7
	ldrsh r7, [r0, #2]
	ldrsh r8, [r1, #4]
	mul r7, r7, r8
	add r7, r7, r6
	strh r7, [r2]
	
	//*(c + 0*2 + 1) = w + v + (aa + bb - cc - dd)*DD;
	ldrsh r6, [r0]
	ldrsh r7, [r0, #2]
	add r6, r6, r7
	ldrsh r7, [r0, #4]
	sub r6, r6, r7
	ldrsh r7, [r0, #6]
	sub r6, r6, r7
	ldrsh r7, [r1, #6]
	mul r6, r6, r7
	add r6, r6, r4
	add r6, r6, r5
	strh r6, [r2, #2]
	
	//*(c + 1*2 + 0) = w + u + dd*(BB + CC - AA - DD);
	ldrsh r6, [r1, #4]
	ldrsh r7, [r1, #2]
	add r6, r6, r7
	ldrsh r7, [r1]
	sub r6, r6, r7
	ldrsh r7, [r1, #6]
	sub r6, r6, r7
	ldrsh r7, [r0, #6]
	mul r6, r6, r7
	add r6, r6, r3
	add r6, r6, r5
	strh r6, [r2, #4]
	
	//*(c + 1*2 + 1) = w + u + v;
	add r6, r3, r4
	add r6, r6, r5
	strh r6, [r2, #6]
	
	
mulDone:
	POP {r4-r11}
	BX LR 

_start: 
// int a_s = sum((int *) a, 4); // 10
LDR	r0, =matrixA 
LDR	r1, =matrixB  
LDR	r2, =matrixC  
BL multiply

inf: 
	B 	inf     // infinite loop!
