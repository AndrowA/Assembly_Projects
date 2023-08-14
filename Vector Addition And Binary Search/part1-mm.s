.global _start
// int a[2] = {{-1, 2}, {3, -4}};
matrixA: .short -1, 2, 3, -4
// int b[2] = {{6, -3}, {2, 4}};
matrixB: .short 6, -3, 2, 4
// int c[2] = {{0, 0}, {0, 0}};
matrixC: .short 0, 0, 0, 0
// length of arrays 
length: .word 2

multiply:
	PUSH {r4-r11}
	
row:
	CMP r4, r3
	BGE mulDone

column:
	CMP r5, r3
	BGE ifRow
	MLA r7, r4, r3, r5 // row*size+col
	MOV r8, #2
	MUL r8, r7, r8// To get the numebr of bytes
	LDRSH r8, [r2, r8]// c + row*size+col
	MOV r8, #0

elements:
	CMP r6, r3
	BGE ifColumn
	MOV r7, #2
	MLA r9, r4, r3, r6 //row*size+iter
	MUL r9, r9, r7 // To get the numebr of bytes
	LDRSH r10, [r0, r9] // a+row*size+iter
	MLA r9, r6, r3, r5 // itter*size+col
	MUL r9, r9, r7
	LDRSH r11, [r1, r9]
	MLA r8, r10, r11, r8
	ADD r6, r6, #1
	B elements

mulDone:
	POP {r4-r11}
	BX LR 

ifColumn:
	MLA r7, r4, r3, r5 // row*size+col
	MOV r9, #2
	MUL r9, r7, r9// To get the numebr of bytes
	STRH r8, [r2, r9]
	ADD r5, r5, #1
	MOV r6, #0
	B column
	
ifRow:
	ADD r4, r4, #1
	MOV r5, #0
	B row

_start: 
// int a_s = sum((int *) a, 4); // 10
LDR	r0, =matrixA  // put the address of A in A1
LDR	r1, =matrixB  // put the address of A in A1
LDR	r2, =matrixC  // put the address of A in A1
LDR	r3, length   // put the length of A in A2
BL multiply

inf: 
	B 	inf     // infinite loop!
