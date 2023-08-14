.global _start

.equ ADDR_color, 0xc8000000
.equ ADDR_char, 0xc9000000
//.equ ADDR_keyboard, 0xc9000000

_start:
        bl      draw_test_screen
end:
        b       end
		
@ TODO: Insert VGA driver functions here.

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

draw_test_screen:
        push    {r4, r5, r6, r7, r8, r9, r10, lr}
        bl      VGA_clear_pixelbuff_ASM
        bl      VGA_clear_charbuff_ASM
        mov     r6, #0
        ldr     r10, .draw_test_screen_L8
        ldr     r9, .draw_test_screen_L8+4
        ldr     r8, .draw_test_screen_L8+8
        b       .draw_test_screen_L2
.draw_test_screen_L7:
        add     r6, r6, #1
        cmp     r6, #320
        beq     .draw_test_screen_L4
.draw_test_screen_L2:
        smull   r3, r7, r10, r6
        asr     r3, r6, #31
        rsb     r7, r3, r7, asr #2
        lsl     r7, r7, #5
        lsl     r5, r6, #5
        mov     r4, #0
.draw_test_screen_L3:
        smull   r3, r2, r9, r5
        add     r3, r2, r5
        asr     r2, r5, #31
        rsb     r2, r2, r3, asr #9
        orr     r2, r7, r2, lsl #11
        lsl     r3, r4, #5
        smull   r0, r1, r8, r3
        add     r1, r1, r3
        asr     r3, r3, #31
        rsb     r3, r3, r1, asr #7
        orr     r2, r2, r3
        mov     r1, r4
        mov     r0, r6
        bl      VGA_draw_point_ASM
        add     r4, r4, #1
        add     r5, r5, #32
        cmp     r4, #240
        bne     .draw_test_screen_L3
        b       .draw_test_screen_L7
.draw_test_screen_L4:
        mov     r2, #72
        mov     r1, #5
        mov     r0, #20
        bl      VGA_write_char_ASM
        mov     r2, #101
        mov     r1, #5
        mov     r0, #21
        bl      VGA_write_char_ASM
        mov     r2, #108
        mov     r1, #5
        mov     r0, #22
        bl      VGA_write_char_ASM
        mov     r2, #108
        mov     r1, #5
        mov     r0, #23
        bl      VGA_write_char_ASM
        mov     r2, #111
        mov     r1, #5
        mov     r0, #24
        bl      VGA_write_char_ASM
        mov     r2, #32
        mov     r1, #5
        mov     r0, #25
        bl      VGA_write_char_ASM
        mov     r2, #87
        mov     r1, #5
        mov     r0, #26
        bl      VGA_write_char_ASM
        mov     r2, #111
        mov     r1, #5
        mov     r0, #27
        bl      VGA_write_char_ASM
        mov     r2, #114
        mov     r1, #5
        mov     r0, #28
        bl      VGA_write_char_ASM
        mov     r2, #108
        mov     r1, #5
        mov     r0, #29
        bl      VGA_write_char_ASM
        mov     r2, #100
        mov     r1, #5
        mov     r0, #30
        bl      VGA_write_char_ASM
        mov     r2, #33
        mov     r1, #5
        mov     r0, #31
        bl      VGA_write_char_ASM
        pop     {r4, r5, r6, r7, r8, r9, r10, pc}
.draw_test_screen_L8:
        .word   1717986919
        .word   -368140053
        .word   -2004318071
		