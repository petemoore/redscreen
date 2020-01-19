	.arch armv8-a+crc
	.file	"uart.c"
	.text
	.align	2
	.global	uart_init
	.type	uart_init, %function
uart_init:
	stp	x29, x30, [sp, -32]!
	add	x29, sp, 0
	str	x19, [sp, 16]
	mov	x0, 4144
	movk	x0, 0x3f20, lsl 16
	str	wzr, [x0]
	adrp	x0, mbox
	add	x0, x0, :lo12:mbox
	mov	w1, 36
	str	w1, [x0]
	adrp	x0, mbox
	add	x0, x0, :lo12:mbox
	str	wzr, [x0, 4]
	adrp	x0, mbox
	add	x0, x0, :lo12:mbox
	mov	w1, 32770
	movk	w1, 0x3, lsl 16
	str	w1, [x0, 8]
	adrp	x0, mbox
	add	x0, x0, :lo12:mbox
	mov	w1, 12
	str	w1, [x0, 12]
	adrp	x0, mbox
	add	x0, x0, :lo12:mbox
	mov	w1, 8
	str	w1, [x0, 16]
	adrp	x0, mbox
	add	x0, x0, :lo12:mbox
	mov	w1, 2
	str	w1, [x0, 20]
	adrp	x0, mbox
	add	x0, x0, :lo12:mbox
	mov	w1, 2304
	movk	w1, 0x3d, lsl 16
	str	w1, [x0, 24]
	adrp	x0, mbox
	add	x0, x0, :lo12:mbox
	str	wzr, [x0, 28]
	adrp	x0, mbox
	add	x0, x0, :lo12:mbox
	str	wzr, [x0, 32]
	mov	w0, 8
	bl	mbox_call
	mov	x0, 4
	movk	x0, 0x3f20, lsl 16
	ldr	w19, [x0]
	and	w19, w19, -258049
	mov	w0, 16384
	movk	w0, 0x2, lsl 16
	orr	w19, w19, w0
	mov	x0, 4
	movk	x0, 0x3f20, lsl 16
	str	w19, [x0]
	mov	x0, 148
	movk	x0, 0x3f20, lsl 16
	str	wzr, [x0]
	mov	w0, 150
	bl	wait_cycles
	mov	x0, 152
	movk	x0, 0x3f20, lsl 16
	mov	w1, 49152
	str	w1, [x0]
	mov	w0, 150
	bl	wait_cycles
	mov	x0, 152
	movk	x0, 0x3f20, lsl 16
	str	wzr, [x0]
	mov	x0, 4164
	movk	x0, 0x3f20, lsl 16
	mov	w1, 2047
	str	w1, [x0]
	mov	x0, 4132
	movk	x0, 0x3f20, lsl 16
	mov	w1, 2
	str	w1, [x0]
	mov	x0, 4136
	movk	x0, 0x3f20, lsl 16
	mov	w1, 11
	str	w1, [x0]
	mov	x0, 4140
	movk	x0, 0x3f20, lsl 16
	mov	w1, 96
	str	w1, [x0]
	mov	x0, 4144
	movk	x0, 0x3f20, lsl 16
	mov	w1, 769
	str	w1, [x0]
	nop
	ldr	x19, [sp, 16]
	ldp	x29, x30, [sp], 32
	ret
	.size	uart_init, .-uart_init
	.align	2
	.global	uart_send
	.type	uart_send, %function
uart_send:
	sub	sp, sp, #16
	str	w0, [sp, 12]
.L3:
	// Start of user assembly
// 85 "uart.c" 1
	nop
// 0 "" 2
	// End of user assembly
	mov	x0, 4120
	movk	x0, 0x3f20, lsl 16
	ldr	w0, [x0]
	and	w0, w0, 32
	cmp	w0, 0
	bne	.L3
	mov	x0, 4096
	movk	x0, 0x3f20, lsl 16
	ldr	w1, [sp, 12]
	str	w1, [x0]
	nop
	add	sp, sp, 16
	ret
	.size	uart_send, .-uart_send
	.align	2
	.global	uart_getc
	.type	uart_getc, %function
uart_getc:
	sub	sp, sp, #16
.L5:
	// Start of user assembly
// 96 "uart.c" 1
	nop
// 0 "" 2
	// End of user assembly
	mov	x0, 4120
	movk	x0, 0x3f20, lsl 16
	ldr	w0, [x0]
	and	w0, w0, 16
	cmp	w0, 0
	bne	.L5
	mov	x0, 4096
	movk	x0, 0x3f20, lsl 16
	ldr	w0, [x0]
	strb	w0, [sp, 15]
	ldrb	w0, [sp, 15]
	cmp	w0, 13
	beq	.L6
	ldrb	w0, [sp, 15]
	b	.L7
.L6:
	mov	w0, 10
.L7:
	add	sp, sp, 16
	ret
	.size	uart_getc, .-uart_getc
	.align	2
	.global	uart_puts
	.type	uart_puts, %function
uart_puts:
	stp	x29, x30, [sp, -32]!
	add	x29, sp, 0
	str	x0, [x29, 24]
	b	.L10
.L12:
	ldr	x0, [x29, 24]
	ldrb	w0, [x0]
	cmp	w0, 10
	bne	.L11
	mov	w0, 13
	bl	uart_send
.L11:
	ldr	x0, [x29, 24]
	add	x1, x0, 1
	str	x1, [x29, 24]
	ldrb	w0, [x0]
	bl	uart_send
.L10:
	ldr	x0, [x29, 24]
	ldrb	w0, [x0]
	cmp	w0, 0
	bne	.L12
	nop
	ldp	x29, x30, [sp], 32
	ret
	.size	uart_puts, .-uart_puts
	.align	2
	.global	uart_hex
	.type	uart_hex, %function
uart_hex:
	stp	x29, x30, [sp, -48]!
	add	x29, sp, 0
	str	w0, [x29, 28]
	mov	w0, 28
	str	w0, [x29, 44]
	b	.L14
.L17:
	ldr	w0, [x29, 44]
	ldr	w1, [x29, 28]
	lsr	w0, w1, w0
	and	w0, w0, 15
	str	w0, [x29, 40]
	ldr	w0, [x29, 40]
	cmp	w0, 9
	bls	.L15
	mov	w0, 55
	b	.L16
.L15:
	mov	w0, 48
.L16:
	ldr	w1, [x29, 40]
	add	w0, w1, w0
	str	w0, [x29, 40]
	ldr	w0, [x29, 40]
	bl	uart_send
	ldr	w0, [x29, 44]
	sub	w0, w0, #4
	str	w0, [x29, 44]
.L14:
	ldr	w0, [x29, 44]
	cmp	w0, 0
	bge	.L17
	nop
	ldp	x29, x30, [sp], 48
	ret
	.size	uart_hex, .-uart_hex
	.ident	"GCC: (GNU) 7.2.0"
