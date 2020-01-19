	.arch armv8-a+crc
	.file	"delays.c"
	.text
	.align	2
	.global	wait_cycles
	.type	wait_cycles, %function
wait_cycles:
	sub	sp, sp, #16
	str	w0, [sp, 12]
	ldr	w0, [sp, 12]
	cmp	w0, 0
	beq	.L5
	b	.L3
.L4:
	// Start of user assembly
// 36 "delays.c" 1
	nop
// 0 "" 2
	// End of user assembly
.L3:
	ldr	w0, [sp, 12]
	sub	w1, w0, #1
	str	w1, [sp, 12]
	cmp	w0, 0
	bne	.L4
.L5:
	nop
	add	sp, sp, 16
	ret
	.size	wait_cycles, .-wait_cycles
	.ident	"GCC: (GNU) 7.2.0"
