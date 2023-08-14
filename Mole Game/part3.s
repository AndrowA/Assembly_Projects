.section .vectors, "ax"
B _start            // reset vector
B SERVICE_UND       // undefined instruction vector
B SERVICE_SVC       // software interrupt vector
B SERVICE_ABT_INST  // aborted prefetch vector
B SERVICE_ABT_DATA  // aborted data vector
.word 0             // unused vector
B SERVICE_IRQ       // IRQ interrupt vector
B SERVICE_FIQ       // FIQ interrupt vector

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

.global _start

PB_int_flag:
    .word 0x0

tim_int_flag:
    .word 0x0

CONFIG_GIC:
    PUSH {LR}
/* To configure the FPGA KEYS interrupt (ID 73):
* 1. set the target to cpu0 in the ICDIPTRn register
* 2. enable the interrupt in the ICDISERn register */
/* CONFIG_INTERRUPT (int_ID (R0), CPU_target (R1)); */
/* NOTE: you can configure different interrupts
   by passing their IDs to R0 and repeating the next 3 lines */
    MOV R0, #73            // KEY port (Interrupt ID = 73)
    MOV R1, #1             // this field is a bit-mask; bit 0 targets cpu0
    BL CONFIG_INTERRUPT
	
	MOV R0, #29            // KEY port (Interrupt ID = 73)
    MOV R1, #1             // this field is a bit-mask; bit 0 targets cpu0
    BL CONFIG_INTERRUPT

/* configure the GIC CPU Interface */
    LDR R0, =0xFFFEC100    // base address of CPU Interface
/* Set Interrupt Priority Mask Register (ICCPMR) */
    LDR R1, =0xFFFF        // enable interrupts of all priorities levels
    STR R1, [R0, #0x04]
/* Set the enable bit in the CPU Interface Control Register (ICCICR).
* This allows interrupts to be forwarded to the CPU(s) */
    MOV R1, #1
    STR R1, [R0]
/* Set the enable bit in the Distributor Control Register (ICDDCR).
* This enables forwarding of interrupts to the CPU Interface(s) */
    LDR R0, =0xFFFED000
    STR R1, [R0]
    POP {PC}
	////////////////////////////////////////////////////////
/*
* Configure registers in the GIC for an individual Interrupt ID
* We configure only the Interrupt Set Enable Registers (ICDISERn) and
* Interrupt Processor Target Registers (ICDIPTRn). The default (reset)
* values are used for other registers in the GIC
* Arguments: R0 = Interrupt ID, N
* R1 = CPU target
*/
CONFIG_INTERRUPT:
    PUSH {R4-R5, LR}
/* Configure Interrupt Set-Enable Registers (ICDISERn).
* reg_offset = (integer_div(N / 32) * 4
* value = 1 << (N mod 32) */
    LSR R4, R0, #3    // calculate reg_offset
    BIC R4, R4, #3    // R4 = reg_offset
    LDR R2, =0xFFFED100
    ADD R4, R2, R4    // R4 = address of ICDISER
    AND R2, R0, #0x1F // N mod 32
    MOV R5, #1        // enable
    LSL R2, R5, R2    // R2 = value
/* Using the register address in R4 and the value in R2 set the
* correct bit in the GIC register */
    LDR R3, [R4]      // read current register value
    ORR R3, R3, R2    // set the enable bit
    STR R3, [R4]      // store the new register value
/* Configure Interrupt Processor Targets Register (ICDIPTRn)
* reg_offset = integer_div(N / 4) * 4
* index = N mod 4 */
    BIC R4, R0, #3    // R4 = reg_offset
    LDR R2, =0xFFFED800
    ADD R4, R2, R4    // R4 = word address of ICDIPTR
    AND R2, R0, #0x3  // N mod 4
    ADD R4, R2, R4    // R4 = byte address in ICDIPTR
/* Using register address in R4 and the value in R2 write to
* (only) the appropriate byte */
    STRB R1, [R4]
    POP {R4-R5, PC}
	
	/////////////////////////////////////////////////////////

/*--- Undefined instructions --------------------------------------*/
SERVICE_UND:
    B SERVICE_UND
/*--- Software interrupts ----------------------------------------*/
SERVICE_SVC:
    B SERVICE_SVC
/*--- Aborted data reads ------------------------------------------*/
SERVICE_ABT_DATA:
    B SERVICE_ABT_DATA
/*--- Aborted instruction fetch -----------------------------------*/
SERVICE_ABT_INST:
    B SERVICE_ABT_INST
/*--- IRQ ---------------------------------------------------------*/
SERVICE_IRQ:
    PUSH {R0-R7, LR}
/* Read the ICCIAR from the CPU Interface */
    LDR R4, =0xFFFEC100
    LDR R5, [R4, #0x0C] // read from ICCIAR
/* NOTE: Check which interrupt has occurred (check interrupt IDs)
   Then call the corresponding ISR
   If the ID is not recognized, branch to UNEXPECTED
   See the assembly example provided in the DE1-SoC Computer Manual
   on page 46 */
Timer_check:
	CMP r5, #29
	bne Pushbutton_check
	
	bl ARM_TIM_ISR
	b EXIT_IRQ

Pushbutton_check:
    CMP R5, #73

UNEXPECTED:
    BNE UNEXPECTED      // if not recognized, stop here
	BL KEY_ISR
	
EXIT_IRQ:
/* Write to the End of Interrupt Register (ICCEOIR) */
    STR R5, [R4, #0x10] // write to ICCEOIR
    POP {R0-R7, LR}
	SUBS PC, LR, #4
/*--- FIQ ---------------------------------------------------------*/
SERVICE_FIQ:
    B SERVICE_FIQ
	
	//////////////////////////////////////////////////////

ARM_TIM_ISR:
	push {lr}
	ldr r0, =tim_int_flag
	mov r1, #1
	str r1, [r0]
	bl ARM_TIM_clear_INT_ASM
	pop {lr}
	bx lr

KEY_ISR:
    LDR R0, =0xFF200050    // base address of pushbutton KEY port
    LDR R1, [R0, #0xC]     // read edge capture register
	
	// clear the interrupt
	MOV r2, #0xF 
    STR R2, [R0, #0xC]     
	
	ldr r0, =PB_int_flag
	str r1, [r0]
	
END_KEY_ISR:
    BX LR

enable_PB_INT_ASM:
	push {r0, r1}
	LDR r2, =PB_IM_ADDR
	ORR r0, r2, r1 // exclusive or
	str r0, [r2] 
	pop {r0, r1}
	bx lr
	
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
	////////////////////////////////////////////////////////////

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
	
	ldr r1, =PB_int_flag
	str r0, [r1]
	
	ldr r0, =tim_int_flag
	ldr r0, [r0]	//f-bit
	
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
	ldr r0, =tim_int_flag
	ldr r0, [r0]	//f-bit
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
	
	
clear_tim_int_flag:
	push {r1}
	ldr r0, =tim_int_flag
	mov r1, #0
	str r1, [r0]
	pop {r1}
	bx lr
	
	//////////////////////////////////////////////////////////////

_start:
    /* Set up stack pointers for IRQ and SVC processor modes */
    MOV R1, #0b11010010      // interrupts masked, MODE = IRQ
    MSR CPSR_c, R1           // change to IRQ mode
    LDR SP, =0xFFFFFFFF - 3  // set IRQ stack to A9 on-chip memory
    /* Change to SVC (supervisor) mode with interrupts disabled */
    MOV R1, #0b11010011      // interrupts masked, MODE = SVC
    MSR CPSR, R1             // change to supervisor mode
    LDR SP, =0x3FFFFFFF - 3  // set SVC stack to top of DDR3 memory
    BL  CONFIG_GIC           // configure the ARM GIC
    // NOTE: write to the pushbutton KEY interrupt mask register
    // Or, you can call enable_PB_INT_ASM subroutine from previous task
    bl enable_PB_INT_ASM
	// to enable interrupt for ARM A9 private timer, 
    // use ARM_TIM_config_ASM subroutine
	movw r0, #0x2D00
	movt r0, #0x0131
	mov r1, #0b100 // Config Bits
    bl ARM_TIM_config_ASM
	LDR R0, =0xFF200050      // pushbutton KEY base address
    MOV R1, #0xF             // set interrupt mask bits
    STR R1, [R0, #0x8]       // interrupt mask register (base + 8)
    // enable IRQ interrupts in the processor
    MOV R0, #0b01010011      // IRQ unmasked, MODE = SVC
    MSR CPSR_c, R0
	
	// Setup
	
	// To write 200 000 000 in r0
	movw r0, #0x2D00
	movt r0, #0x0131
	mov r1, #0b100 // Config Bits
	bl ARM_TIM_config_ASM
	mov r0, #tim_int_flag	//f-bit
	mov r1, #300 // time
	mov r2, #0 	//score
	mov r3, #512
	bl PB_clear_edgecp_ASM
	bl PB_clear_Hex
	bl display_time	
	
IDLE:
	
	ldr r0, =tim_int_flag
	ldr r0, [r0]	
	
	ldr r4, =PB_int_flag
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
	beq IDLE
	
	// Timer
	cmp r1, #0
	moveq r0, r2
	cmp r1, #0
	blle display_score
	cmp r1, #0
	moveq r2, r0
	cmp r1, #0
	ble IDLE
	
	cmp r0, #1
	bleq display_time
	cmp r0, #1
	bleq time_subs_one
//	cmp r0, #1
//	bleq ARM_TIM_clear_INT_ASM
	cmp r0, #1
	bleq clear_tim_int_flag
	// Check switches
	bl check_switches
	
    B IDLE // This is where you write your main program task(s)

	
	