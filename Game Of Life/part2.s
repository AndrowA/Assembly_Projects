.global _start

.equ ADDR_color, 0xc8000000
.equ ADDR_char, 0xc9000000
.equ ADDR_keyboard, 0xff200100

_start:
        bl      input_loop
end:
        b       end

@ TODO: copy VGA driver here.
VGA_clear_pixelbuff_ASM:
	push {r4, r5, lr}
	mov r4, #0
	
	loopPixX:
		cmp r4, #320
		bge end_Pix_Clear
		mov r5, #0
		loopPixY:
			cmp r5, #239
			addgt r4, #1
			bgt loopPixX
			mov r0, r4
			mov r1, r5
			mov r2, #0
			bl VGA_draw_point_ASM
			add r5, #1
			b loopPixY
end_Pix_Clear:
	pop {r4, r5, lr}
	bx lr
	
VGA_clear_charbuff_ASM:
	push {r4, r5, lr}
	mov r4, #0
	
	loopCharxX:
		cmp r4, #320
		bge end_Char_Clear
		mov r5, #0
		loopCharxY:
			cmp r5, #239
			addgt r4, #1
			bgt loopCharxX
			mov r0, r4
			mov r1, r5
			mov r2, #0
			bl VGA_write_char_ASM
			add r5, #1
			b loopCharxY
end_Char_Clear:
	pop {r4, r5, lr}
	bx lr
	
VGA_draw_point_ASM:
	// Checking for conditions
	cmp r0, #0 
	bxlt lr
	cmp r1, #0
	bxlt lr
	cmp r0, #320
	bxge lr
	cmp r1, #239
	bxgt lr
	
	// Write the point
	push {r4,r5,r6}
	lsl r4, r0, #1 //x
	lsl r5, r1, #10 //y
	ldr r6, =ADDR_color 
	orr r0, r4, r5
	orr r0, r0, r6
	strh r2, [r0]
	pop {r4,r5,r6}
	bx lr 
	
VGA_write_char_ASM:
	// Checking for conditions
	cmp r0, #0 
	bxlt lr
	cmp r1, #0
	bxlt lr
	cmp r0, #79
	bxgt lr
	cmp r1, #59
	bxgt lr
	
	// Write the char
	push {r4,r5}
	lsl r4, r1, #7 //y
	ldr r5, =ADDR_char
	orr r0, r0, r4
	orr r0, r0, r5
	strb r2, [r0]
	pop {r4,r5}
	bx lr 

@ TODO: insert PS/2 driver here.

read_PS2_data_ASM:
	ldr r1, =ADDR_keyboard
	ldr r1, [r1]
	lsr r2, r1, #15
	and r2, r2, #0x1
	cmp r2, #1
	streqb r1, [r0] 
	moveq r0, #1
	movne r0, #0 
	bx lr

write_hex_digit:
        push    {r4, lr}
        cmp     r2, #9
        addhi   r2, r2, #55
        addls   r2, r2, #48
        and     r2, r2, #255
        bl      VGA_write_char_ASM
        pop     {r4, pc}
write_byte:
        push    {r4, r5, r6, lr}
        mov     r5, r0
        mov     r6, r1
        mov     r4, r2
        lsr     r2, r2, #4
        bl      write_hex_digit
        and     r2, r4, #15
        mov     r1, r6
        add     r0, r5, #1
        bl      write_hex_digit
        pop     {r4, r5, r6, pc}
input_loop:
        push    {r4, r5, lr}
        sub     sp, sp, #12
        bl      VGA_clear_pixelbuff_ASM
        bl      VGA_clear_charbuff_ASM
        mov     r4, #0
        mov     r5, r4
        b       .input_loop_L9
.input_loop_L13:
        ldrb    r2, [sp, #7]
        mov     r1, r4
        mov     r0, r5
        bl      write_byte
        add     r5, r5, #3
        cmp     r5, #79
        addgt   r4, r4, #1
        movgt   r5, #0
.input_loop_L8:
        cmp     r4, #59
        bgt     .input_loop_L12
.input_loop_L9:
        add     r0, sp, #7
        bl      read_PS2_data_ASM
        cmp     r0, #0
        beq     .input_loop_L8
        b       .input_loop_L13
.input_loop_L12:
        add     sp, sp, #12
        pop     {r4, r5, pc}
