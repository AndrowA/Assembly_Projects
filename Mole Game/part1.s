.global _start

// Slider Switches Driver
.equ SW_ADDR, 0xFF200040
//LED Drivers
.equ LED_ADDR, 0xFF200000
// 7 segment display
.equ ADDR_7SEG1, 0xFF200020
.equ ADDR_7SEG2, 0xFF200030
array: .byte 0b0111111, 0b0000110, 0b1011011, 0b1001111, 0b1100110, 0b1101101, 0b1111101, 0b0000111, 0b1111111, 0b1100111, 0b1110111, 0b1111100, 0b0111001, 0b1011110, 0b1111001, 0b1110001, 0b0111110, 0b1110111, 0b0111000, 0b0000000
// PushButton Keys
.equ PB_ADDR, 0xFF200050
.equ PB_EC_ADDR, 0xFF20005C
.equ PB_IM_ADDR, 0xFF200058

HEX_clear_ASM:
	push {r5,lr}
	mov r0, #0b011111
	mov r5, #0
	mov r3, #0
	bl HEX_clear_negative_ASM
	bl HEX_write_ASM
	bl PB_clear_edgecp_ASM
	pop {r5,lr}
	bx lr

HEX_clear_negative_ASM:
	push {r3, r4}
	mov r3, #0
	ldr r4, =ADDR_7SEG2 
	strneb r3, [r4,#1]
	pop {r3, r4}
	bx lr

PB_clear_edgecp_ASM:
	push {r0, r3}
	LDR r3, =PB_EC_ADDR
	LDR r0, [r3]
	str r0, [r3]
	pop {r0, r3}
	BX lr
	
read_PB_edgecp_ASM:
	LDR r4, =PB_EC_ADDR
	LDR r4, [r3]
	BX lr

negative:
	push {r3, r4, lr}
	rsb r3, r3, #0
	bl display_whole_number
	mov r3, #0b1000000
	ldr r4, =ADDR_7SEG2
	strb r3, [r4,#1]
	pop {r3, r4, lr}
	bx lr

HEX_write_ASM:
	push {r3, r4, r5}
	ldr r3, =ADDR_7SEG1  
	ldrb r4, =array
	ldrb r5, [r4, r5] 
	TST r0, #1
	strneb r5, [r3] 
	TST r0, #2
	strneb r5, [r3,#1] 
	TST r0, #4
	strneb r5, [r3,#2] 
	TST r0, #8
	strneb r5, [r3,#3] 
	TST r0, #16
	ldr r3, =ADDR_7SEG2
	strneb r5, [r3] 
	TST r0, #32
	strneb r5, [r3,#1] 
	pop {r3, r4, r5}
	bx lr 

display_whole_number:
	push {r0, r5, lr}
	mov r0, #0b000001
	ubfx r5, r3, #0, #4 //0-3
	bl HEX_write_ASM
	mov r0, #0b000010
	ubfx r5, r3, #4, #4 //4-7
	bl HEX_write_ASM
	mov r0, #0b000100
	ubfx r5, r3, #8, #4 //8-11
	bl HEX_write_ASM
	mov r0, #0b001000
	ubfx r5, r3, #12, #4 //12-15
	bl HEX_write_ASM
	mov r0, #0b010000
	ubfx r5, r3, #16, #4 //16-19
	bl HEX_write_ASM
	pop {r0, r5, lr}
	bx lr

overflow:
	push {r0, r5, lr}
	mov r0, #0b000001
	mov r5, #0
	bl HEX_write_ASM
	mov r0, #0b000010
	mov r5, #18
	bl HEX_write_ASM
	mov r0, #0b000100
	mov r5, #15
	bl HEX_write_ASM
	mov r0, #0b001000
	mov r5, #17
	bl HEX_write_ASM
	mov r0, #0b010000
	mov r5, #16
	bl HEX_write_ASM
	mov r0, #0b100000
	mov r5, #0
	bl HEX_write_ASM
	pop {r0, r5, lr}
	mov r6, #1
	bx lr

multiply:
	push {r5, lr}
	bl HEX_clear_negative_ASM
	cmp r6, #0
	mulne r3, r1, r3
	muleq r3, r1, r2
	msr CPSR_f, r3
	bl display_whole_number
	tst r3, #0x80000000
	blne negative
	movw r5, #0xFFFF
	movt r5, #0x000F
	cmp r3, r5
	blgt overflow
	movw r5, #0x0001
	movt r5, #0xFFF0
	cmp r3, r5
	bllt overflow
	bl PB_clear_edgecp_ASM
	pop {r5, lr}
	bx  LR
	
substract:
	push {r5, lr}
	bl HEX_clear_negative_ASM
	cmp r6, #0
	subne r3, r3, r1
	subeq r3, r1, r2
	msr CPSR_f, r3
	bl display_whole_number
	tst r3, #0x80000000
	blne negative
	movw r5, #0xFFFF
	movt r5, #0x000F
	cmp r3, r5
	blgt overflow
	movw r5, #0x0001
	movt r5, #0xFFF0
	cmp r3, r5
	bllt overflow
	bl PB_clear_edgecp_ASM
	pop {r5, lr}
	bx  LR
	
add:
	push {r5, r6, lr}
	bl HEX_clear_negative_ASM
	cmp r6, #0
	addne r3, r3, r1
	addeq r3, r1, r2
	msr CPSR_f, r3
	bl display_whole_number
	tst r3, #0x80000000
	blne negative
	movw r5, #0xFFFF
	movt r5, #0x000F
	cmp r3, r5
	blgt overflow
	movw r5, #0x0001
	movt r5, #0xFFF0
	cmp r3, r5
	bllt overflow
	bl PB_clear_edgecp_ASM
	pop {r5, r6, lr}
	bx  LR
	
main_loop:
	ldr r5, =SW_ADDR     
    ldr r5, [r5]
	ubfx r1, r5, #0, #4 //sw0-sw3
	ubfx r2, r5, #4, #4 //sw4-sw7
	//read_PB_edgecp_ASM
	ldr r4, =PB_EC_ADDR
	ldr r4, [r4]
	TST r4, #1
	movne r6, #0
	blne HEX_clear_ASM
	// dealing with overflow
	movw r5, #0xFFFF
	movt r5, #0x000F
	cmp r3, r5
	bgt main_loop
	movw r5, #0x0001
	movt r5, #0xFFF0
	cmp r3, r5
	blt main_loop
	//Rest of operations
	TST r4, #2
	blne add
	movne r6, #1
	TST r4, #4
	blne substract
	movne r6, #1
	TST r4, #8
	blne multiply
	movne r6, #1
	TST r4, #1
	movne r6, #0
	blne HEX_clear_ASM
	b main_loop

_start:
 	mov r6, #0
	bl HEX_clear_ASM
	bl PB_clear_edgecp_ASM
	bl main_loop

end:
	b end	
