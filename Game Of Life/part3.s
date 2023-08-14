.global _start

.equ ADDR_color, 0xc8000000
.equ ADDR_char, 0xc9000000
.equ ADDR_keyboard, 0xff200100
data: .word 0

GoLBoardCopy:
	//  x 0 1 2 3 4 5 6 7 8 9 a b c d e f    y
	.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // 0
	.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // 1
	.word 0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0 // 2
	.word 0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0 // 3
	.word 0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0 // 4
	.word 0,0,0,0,0,0,0,1,1,1,1,1,0,0,0,0 // 5
	.word 0,0,0,0,1,1,1,1,1,0,0,0,0,0,0,0 // 6
	.word 0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0 // 7
	.word 0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0 // 8
	.word 0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0 // 9
	.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // a
	.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // b

GoLBoard:
	//  x 0 1 2 3 4 5 6 7 8 9 a b c d e f    y
	.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // 0
	.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // 1
	.word 0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0 // 2
	.word 0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0 // 3
	.word 0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0 // 4
	.word 0,0,0,0,0,0,0,1,1,1,1,1,0,0,0,0 // 5
	.word 0,0,0,0,1,1,1,1,1,0,0,0,0,0,0,0 // 6
	.word 0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0 // 7
	.word 0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0 // 8
	.word 0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0 // 9
	.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // a
	.word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 // b

_start:
	bl VGA_clear_pixelbuff_ASM
	bl VGA_clear_charbuff_ASM
	bl Draw_Board
	mov r4, #0 //x
	mov r5, #0 //y
	mov r6, #0 //reinitialize
	mov r7, #0 // Track f0
	bl read_input
	end:
    b       end

read_input:
	ldr r0, =data
	ldr r1, [r0]
	ldr r2, =ADDR_keyboard
	
	bl read_PS2_data_ASM
	
	// If There Is An Input
	cmp r0, #1
	cmpeq r7, #0
	bleq if_input
	
	ldr r0, =data
	ldr r1, [r0]
	
	// Avoid the 2nd read
	cmp r7, #1
	streqb r6, [r0]
	moveq r7, #0
	beq read_input
	
	// Get values again
	ldr r0, =data
	ldr r1, [r0]
	
	cmp r1, #0xF0
	moveq r7, #1
	beq read_input
	
	ldr r0, =data
	ldr r1, [r0]
	
	// Left
	cmp r1, #0x1c
	subeq r4, r4, #1
	streqb r6, [r0] 
	
	ldr r0, =data
	ldr r1, [r0]
	
	// Right
	cmp r1, #0x23
	addeq r4, r4, #1
	streqb r6, [r0] 
	
	ldr r0, =data
	ldr r1, [r0]
	
	// Up
	cmp r1, #0x1D
	subeq r5, r5, #1
	streqb r6, [r0]
	
	ldr r0, =data
	ldr r1, [r0]
	
	//Down
	cmp r1, #0x1B
	addeq r5, r5, #1
	streqb r6, [r0]
	
	cmp r4, #0
	movlt r4, #0
	
	cmp r4, #15
	movgt r4, #15
	
	cmp r5, #0
	movlt r5, #0
	
	cmp r5, #11
	movgt r5, #11
	
	mov r0, r4 //x
	mov r1, r5 //y
	mov r2, #0b1111111100000000//Color
	
	bl GoL_fill_gridxy_ASM
	
	// If Space
	ldr r0, =data
	ldr r1, [r0]
	cmp r1, #0x29
	bleq change_toggle	
	//
	
	// If n
	ldr r0, =data
	ldr r1, [r0]
	cmp r1, #0x31
	bleq state_update
	streqb r6, [r0]
	//
	
	b read_input
	
//State Update

copy_array:
	push {r4, r5, r6, r7}
	mov r6, #192
	
	copy_loop:
		ldr r7, [r4], #4
		str r7, [r5], #4
		subs r6, r6, #1 //size of array
		bne copy_loop
		
	pop {r4, r5, r6, r7}
	bx lr

state_update:
	push {r3, r4, r5, r6, r7, r8, r9, r10, r11, lr}
	
	ldr r4, =GoLBoard
	ldr r5, =GoLBoardCopy 
	bl copy_array
	
	mov r4, #0 //x
	mov r5, #0 //y
	ldr r9, =GoLBoard
	ldr r10, =GoLBoardCopy
	
	update_grid:

	//Get the number of neighbors
	mov r0, #0 // total number of cubes around
	bl check_total_active
	
	// Get shift for the cell in the array (r6)
	mov r1, r4 // x for now
	mov r2, r5 // y for now
	
	bl convert_to_array_index
	
	cmp r0, #0
	beq case1
	
	cmp r0, #1
	beq case1
	
//	cmp r0, #2
//	beq case2
	
	cmp r0, #3
	beq case3
	
	cmp r0, #4
	bge case4
	
	b iterate
	
	// Active cell with 0 or 1 neighbors
	case1:
	ldr r11, [r9, r3] //load from the original
	cmp r11, #1
	bne iterate
	mov r1, #0
	str r1, [r10, r3] //store in the copy
	ldr r1, [r10, r3]
	b iterate
	
	// Active cell with 4 or more active neighbors
	case3:
	ldr r11, [r9, r3] //load from the original
	cmp r11, #1
	beq iterate
	mov r1, #1
	str r1, [r10, r3] //store in the copy
	b iterate
	
	// Inactive cell with exactly 3 active neighbors
	case4:
	ldr r11, [r9, r3] //load from the original
	cmp r11, #1
	moveq r1, #0
	streq r1, [r10, r3] //store in the copy
	b iterate
	
	// Iterate, and increase x, and y
	iterate:
		cmp r5, #11
		bgt end_state_update
		cmp r4, #15
		addlt r4, r4, #1
		movge r4, #0	
		addge r5, #1
		b update_grid
	
end_state_update:
	ldr r4, =GoLBoardCopy 
	ldr r5, =GoLBoard
	bl copy_array
	bl VGA_clear_pixelbuff_ASM
	bl VGA_clear_charbuff_ASM
	bl Draw_Board
	pop {r3, r4, r5, r6, r7, r8, r9, r10, r11, lr}
	bx lr

// Checks total active blocks around location x (r4), y (r5)
check_total_active:
	
	push {r1, r2, r3, r4, r5, r6, r7, r8, r10, lr}
	
	//above
	
	mov r1, r4 // x for now
	sub r2, r5, #1  // y for now
	
	bl convert_to_array_index

	ldr r10, [r9, r3]
	cmp r10, #1
	addeq r0, r0, #1
	
	//top left
	
	sub r1, r4, #1 // x for now
	sub r2, r5, #1  // y for now
	
	bl convert_to_array_index
	
	ldr r10, [r9, r3]
	cmp r10, #1
	addeq r0, r0, #1
	
	//left
	
	sub r1, r4, #1 // x for now
	mov r2, r5  // y for now
	
	bl convert_to_array_index
	
	ldr r10, [r9, r3]
	cmp r10, #1
	addeq r0, r0, #1
	
	//bot left
	
	sub r1, r4, #1 // x for now
	add r2, r5, #1  // y for now
	
	bl convert_to_array_index
	
	ldr r10, [r9, r3]
	cmp r10, #1
	addeq r0, r0, #1
	
	//bot
	
	mov r1, r4 // x for now
	add r2, r5, #1  // y for now
	
	bl convert_to_array_index
	
	ldr r10, [r9, r3]
	cmp r10, #1
	addeq r0, r0, #1
	
	// bot right
	
	add r1, r4, #1 // x for now
	add r2, r5, #1  // y for now
	
	bl convert_to_array_index
	
	ldr r10, [r9, r3]
	cmp r10, #1
	addeq r0, r0, #1
	
	//right
	
	add r1, r4, #1 // x for now
	mov r2, r5  // y for now
	
	bl convert_to_array_index
	
	ldr r10, [r9, r3]
	cmp r10, #1
	addeq r0, r0, #1
	
	// top right
	
	add r1, r4, #1 // x for now
	sub r2, r5, #1  // y for now
	
	bl convert_to_array_index
	
	ldr r10, [r9, r3]
	cmp r10, #1
	addeq r0, r0, #1
	
	pop {r1, r2, r3, r4, r5, r6, r7, r8, r10, lr}
	bx lr


////

change_toggle:
	push {r6, r7, r8, r9}
	ldr r9, =GoLBoard
	
	mov r6, #4
	mul r6, r4, r6
	mov r7, #16
	mov r8, #4
	mul r7, r7, r8
	mul r7, r5, r7
	add r6, r6, r7

	ldr r3, [r9, r6]
	cmp r3, #0
	moveq r3, #1
	movne r3, #0
	str r3, [r9, r6]
	mov r6, #0
	strb r6, [r0]
	
	pop {r6, r7, r8, r9}
	bx lr
	
if_input:
	push {lr}
	mov r0, r4 //x
	mov r1, r5 //y
	mov r2, #0 //Color
	
	bl GoL_fill_gridxy_ASM
	bl Draw_Board
	
	pop {lr}
	bx lr

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

// End Of Drivers


//Verticle Lines
VGA_draw_VerticleLine_ASM:
	push {r1, r2, r3, r4, r5, r6, r7, lr}
	mov r4, r0 // start y
	mov r5, r1 // end y
	mov r6, r2 // color 
	mov r7, r3 // x
	
VGA_draw_verticle:
	mov r0, r7
	mov r1, r4
	mov r2, r6
	
	bl VGA_draw_point_ASM
	add r4, r4, #1
	cmp r4, r5
	bgt end_draw_verticle
	b VGA_draw_verticle

end_draw_verticle:
	pop {r1, r2, r3, r4, r5, r6, r7, lr}
	bx lr

// Horizontal Lines 
VGA_draw_HorizontalLine_ASM:
	push {r4, r5, r6, r7, lr}
	mov r4, r0 // start x
	mov r5, r1 // end x
	mov r6, r2 // color 
	mov r7, r3 // y
	
VGA_draw_horizontal:
	mov r0, r4
	mov r1, r7
	mov r2, r6
	
	bl VGA_draw_point_ASM
	add r4, r4, #1
	cmp r4, r5
	bgt end_draw_horizontal
	b VGA_draw_horizontal

end_draw_horizontal:
	pop {r4, r5, r6, r7, lr}
	bx lr	

// Grid
GoL_draw_grid_ASM:
	push {r4, r5, r6, r7, lr}
	mov r4, #0
	mov r5, #239
	mov r6, #0b000011111100000
	mov r7, #20
	
	draw_verticle_grid:
	mov r0, r4
	mov r1, r5
	mov r2, r6
	mov r3, r7
	cmp r7, #320
	bgt draw_horizontal_grid_setup
	bl VGA_draw_VerticleLine_ASM
	add r7, r7, #20
	b draw_verticle_grid
	
	draw_horizontal_grid_setup:
		mov r4, #0
		mov r5, #320
		mov r6, #0b000011111100000
		mov r7, #20
	
	draw_horizontal_grid:
		mov r0, r4
		mov r1, r5
		mov r2, r6
		mov r3, r7
		cmp r7, #240
		bgt end_grid
		bl VGA_draw_HorizontalLine_ASM
		add r7, r7, #20
		b draw_horizontal_grid
	
end_grid:
	pop {r4, r5, r6, r7, lr}
	bx lr 	
	
// Draw Rectangle 

VGA_draw_rect_ASM:
	push {r4, r5, r6, r7, lr}
	mov r4, r0 // x1
	mov r5, r1 // x2
	mov r6, r2 // y1
	mov r7, r3 // y2
	
	rectangle_horizontal:
		mov r0, r4
		mov r1, r5
		mov r2, r8
		mov r3, r6
		cmp r6, r7
		bgt end_rectangle
		bl VGA_draw_HorizontalLine_ASM
		add r6, r6, #1
		b rectangle_horizontal
		
end_rectangle:
	pop {r4, r5, r6, r7, lr}
	bx lr

// Fill Square In Grid
GoL_fill_gridxy_ASM:
	push {r3, r4, r5, r8, lr}
	mov r4, #20
	mul r4, r0, r4 // x
	mov r5, #20
	mul r5, r1, r5 // y
	mov r8, r2 // color
	
	mov r0, r4
	add r1, r4, #20
	mov r2, r5
	add r3, r5, #20
	bl VGA_draw_rect_ASM

	pop {r3, r4, r5, r8, lr}
	bx lr
	
// Takes r1=x, and r2=y as input
convert_to_array_index:
	push { r6, r7, r8}
	mov r6, #4
	mul r6, r1, r6 //x*4
	mov r7, #16 
	mov r8, #4
	mul r7, r7, r8 // 64 for 1 row
	mul r7, r2, r7 // number of rows
	add r3, r6, r7 // total
	pop { r6, r7, r8}
	bx lr

// Draw Board:
Draw_Board:
	push {r4,r5, r6, r7, r8, r9, lr}
	mov r4, #0 //x
	mov r5, #0 //y
	ldr r9, =GoLBoard
	
	build_grid:
	mov r1, r4 // x
	mov r2, r5 // y
	bl convert_to_array_index

	ldr r3, [r9, r3]
	cmp r3, #1
	mov r0, r4 //x
	mov r1, r5 //y
	moveq r2, #0b000000000011111 //Color
	bleq GoL_fill_gridxy_ASM
	
	cmp r5, #11
	bgt end_board
	
	cmp r4, #15
	addlt r4, r4, #1
	movge r4, #0	
	addge r5, #1
	b build_grid
	
end_board:
	bl GoL_draw_grid_ASM
	pop {r4,r5, r6, r7, r8, r9, lr}
	bx lr
	
	
	
	





		