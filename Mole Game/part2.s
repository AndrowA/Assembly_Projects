.global _start

//Timer
.equ CFG_ADDR, 0xFFFEC600
// 7 segment display
.equ ADDR_7SEG1, 0xFF200020
.equ ADDR_7SEG2, 0xFF200030
array: .byte 0b0111111, 0b0000110, 0b1011011, 0b1001111, 0b1100110, 0b1101101, 0b1111101, 0b0000111, 0b1111111, 0b1100111, 0b1110111, 0b1111100, 0b0111001, 0b1011110, 0b1111001, 0b1110001, 0b0111110, 0b1110111, 0b0111000, 0b0000000
// PushButton Keys
.equ PB_ADDR, 0xFF200050
.equ PB_EC_ADDR, 0xFF20005C
.equ PB_IM_ADDR, 0xFF200058
// Slider Switches Driver
.equ SW_ADDR, 0xFF200040

ARM_TIM_config_ASM:
	// Store the load value 
	push {r3}
	ldr r3, =CFG_ADDR
	str r0, [r3]
	//Setup the configuration bits
	str r1, [r3, #8]
	pop {r3}
	bx lr

ARM_TIM_read_INT_ASM:
	push {r3, r4}
	ldr r3, =CFG_ADDR
	ldr r0, [r3, #12]
	pop {r3, r4}
	bx lr

ARM_TIM_clear_INT_ASM:
	push {r3, r4}
	ldr r3, =CFG_ADDR
	mov r4, #1
	str r4, [r3, #12]
	pop {r3, r4}
	bx lr
	
PB_clear_edgecp_ASM:
	push {r0, r3}
	LDR r3, =PB_EC_ADDR
	LDR r0, [r3]
	str r0, [r3]
	pop {r0, r3}
	BX lr
	
PB_clear_Hex:
	push {r3, r4}
	ldr r3, =ADDR_7SEG1 
	mov r4, #0
	str r4, [r3]
	pop {r3, r4}
	bx lr

HEX_write_ASM:
	push {r3, r4, r5, lr}
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
	pop {r3, r4, r5, lr}
	bx lr 

change_to_decimal:
	mov r2, #0
	mov r3, #0
less_100:
	cmp r1, #100
	blt less_10
	sub r1, r1, #100
	add r2, r2, #1
	b less_100
less_10:
	cmp r1, #10
	blt result
	sub r1, r1, #10
	add r3, r3, #1
	b less_10
result:
	// r1 = 0 (last)
	// r3 = 0 (before last)\
	// r2 = 3 (first number)
	bx lr

display_time:
	push {r0, r1, r2, r3, r5, lr}
	mov r0, #0b010000
	bl change_to_decimal
	cmp r2, #0
	moveq r5, r1
	movne r5, r3
	bl HEX_write_ASM
	mov r0, #0b100000
	cmp r2, #0
	moveq r5, r3
	movne r5, r2
	bl HEX_write_ASM
	pop {r0, r1, r2, r3, r5, lr}
	bx lr

display_score:
	push {r0, r1, r5, lr}
	mov r0, #0b000001
	mov r1, r2
	bl change_to_decimal
	mov r5, r1
	bl HEX_write_ASM
	mov r0, #0b000010
	mov r5, r3
	bl HEX_write_ASM
	mov r0, #0b000100
	mov r5, r2
	bl HEX_write_ASM
	mov r0, #0b001000
	mov r5, #0
	bl HEX_write_ASM
	mov r0, #0b010000
	bl HEX_write_ASM
	pop {r0, r1, r5, lr}
	bx lr
	
time_subs_one:
	cmp r1, #0
	subgt r1, r1, #1
	bx lr

start:
	push {r1, lr}
	mov r1, #0b111 // Config Bits
	movw r0, #0x2D00
	movt r0, #0x0131
	//To put a mole if there is none
	cmp r3, #512 // Number that we cant get with the switches
	bleq show_moles
	bl ARM_TIM_config_ASM
	bl PB_clear_edgecp_ASM
	mov r0, #0	//f-bit
	pop {r1, lr}
	bx lr

stop:
	push {r1, r3, lr}
	movw r0, #0x2D00
	movt r0, #0x0131
	mov r1, #0b100 // Config Bits
	bl ARM_TIM_config_ASM
	bl PB_clear_edgecp_ASM
	pop {r1, r3, lr}
	bx lr

reset:
	push {lr}
	// To write 200 000 000 in r0
	movw r0, #0x2D00
	movt r0, #0x0131
	mov r1, #0b100 // Config Bits
	bl ARM_TIM_config_ASM
	mov r0, #0	//f-bit
	mov r1, #300 // time
	mov r2, #0 	//score
	mov r3, #512
	bl PB_clear_edgecp_ASM
	bl PB_clear_Hex
	bl display_time
	pop {lr}
	bx lr

show_moles:
	push {r0, r4, r5, lr}
	// Make moles appear
	mov r5, #0 // to display the value 
	ldr r4, =CFG_ADDR
	ldr r4, [r4, #4]
	and r4, r4, #0x3
	
	// Get the prev value of r3
	sub r3, r3, #2
	
	// Adjustment if it's the same mole
	cmp r4, r3
	addeq r4, r4, #1
	
	cmp r4, #4
	moveq r4, #0
	
	cmp r4, #0
	moveq r0, #0b000001
	cmp r4, #1
	moveq r0, #0b000010
	cmp r4, #2
	moveq r0, #0b000100
	cmp r4, #3
	moveq r0, #0b001000
	
	// There is a mole
	bl HEX_write_ASM
	add r4, r4, #2
	mov r3, r4
	pop {r0, r4, r5, lr}
	bx lr

check_switches:
	push {r4, r5, lr}
	ldr r5, =SW_ADDR     
    ldr r5, [r5]
	
	//Initial value
	mov r4, r3
	
	// Encoding
	cmp r3, #2
	moveq r4, #1
	
	cmp r3, #3
	moveq r4, #2
	
	cmp r3, #4
	moveq r4, #4
	
	cmp r3, #5
	moveq r4, #8
	
	//compare values and give points if hit
	
	cmp r5, r4
	addeq r2, r2, #1
	
	cmp r5, r4
	bleq PB_clear_Hex
	
	cmp r5, r4
	bleq show_moles
	
	pop {r4, r5, lr}
	bx lr

polling:
	//Check push bottons 
	ldr r4, =PB_EC_ADDR
	ldr r4, [r4]
	TST r4, #1
	blne start
	TST r4, #2
	blne stop
	TST r4, #4
	blne reset
	
	movw r6, #0x2D00
	movt r6, #0x0131
	cmp r0, r6
	beq polling
	
	// Timer
	cmp r1, #0
	moveq r0, r2
	cmp r1, #0
	blle display_score
	cmp r1, #0
	moveq r2, r0
	cmp r1, #0
	ble polling
	
	bl ARM_TIM_read_INT_ASM
	cmp r0, #1
	bleq display_time
	cmp r0, #1
	bleq time_subs_one
	cmp r0, #1
	bleq ARM_TIM_clear_INT_ASM
	
	//If timer is done go to polling again
	cmp r1, #0
	beq polling
	
	// Check switches
	bl check_switches
	
	b polling

_start:
	// To write 200 000 000 in r0
	movw r0, #0x2D00
	movt r0, #0x0131
	mov r1, #0b100 // Config Bits
	bl ARM_TIM_config_ASM
	mov r0, #0	//f-bit
	mov r1, #300 // time
	mov r2, #0 	//score
	mov r3, #512
	bl PB_clear_edgecp_ASM
	bl PB_clear_Hex
	bl display_time
	bl polling
