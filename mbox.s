	.arch armv8-a+crc
	.file	"mbox.c"
	.comm	mbox,144,16
	.text
	.align	2
	.global	mbox_call
	.type	mbox_call, %function
mbox_call:
	sub	sp, sp, #32
	strb	w0, [sp, 15]
	ldrb	w0, [sp, 15]
	and	w1, w0, 15
	adrp	x0, mbox
	add	x0, x0, :lo12:mbox
	and	w0, w0, -16
	orr	w0, w1, w0
	str	w0, [sp, 28]
.L2:
	// Start of user assembly
// 49 "mbox.c" 1
	nop
// 0 "" 2
	// End of user assembly
	mov	x0, 47256
	movk	x0, 0x3f00, lsl 16
	ldr	w0, [x0]
	cmp	w0, 0
	blt	.L2
	mov	x0, 47264
	movk	x0, 0x3f00, lsl 16
	ldr	w1, [sp, 28]
	str	w1, [x0]
.L3:
	// Start of user assembly
// 55 "mbox.c" 1
	nop
// 0 "" 2
	// End of user assembly
	mov	x0, 47256
	movk	x0, 0x3f00, lsl 16
	ldr	w0, [x0]
	and	w0, w0, 1073741824
	cmp	w0, 0
	bne	.L3
	mov	x0, 47232
	movk	x0, 0x3f00, lsl 16
	ldr	w0, [x0]
	ldr	w1, [sp, 28]
	cmp	w1, w0
	bne	.L3
	adrp	x0, mbox
	add	x0, x0, :lo12:mbox
	ldr	w1, [x0, 4]
	mov	w0, -2147483648
	cmp	w1, w0
	cset	w0, eq
	and	w0, w0, 255
	add	sp, sp, 32
	ret
	.size	mbox_call, .-mbox_call
	.ident	"GCC: (GNU) 7.2.0"
