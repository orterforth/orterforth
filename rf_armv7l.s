	.arch armv6
	.eabi_attribute 28, 1
	.eabi_attribute 20, 1
	.eabi_attribute 21, 1
	.eabi_attribute 23, 3
	.eabi_attribute 24, 1
	.eabi_attribute 25, 1
	.eabi_attribute 26, 2
	.eabi_attribute 30, 6
	.eabi_attribute 34, 1
	.eabi_attribute 18, 4
	.text

	.align	2
	.global	_rf_trampoline
	.arch armv6
	.syntax unified
	.arm
	.fpu vfp
	.type	_rf_trampoline, %function
_rf_trampoline:

	push	{fp, lr}

.trampoline1:

	ldr	r3, .trampoline3
	ldr	r3, [r3]
	cmp	r3, #0
	beq	.trampoline2

	ldr	r10, .trampoline4       @ IP into r10
	ldr	r10, [r10]
	ldr	r9, .trampoline5        @ W into r9
	ldr	r9, [r9]

	blx	r3
	b .trampoline1

.trampoline2:
	nop
	pop	{fp, pc}

	.align	2
.trampoline3:
	.word	rf_fp

	.align	2
.trampoline4:
	.word	rf_ip

	.align	2
.trampoline5:
	.word	rf_w

	.size	_rf_trampoline, .-_rf_trampoline

	.align	2
	.global	_rf_start
	.syntax unified
	.arm
	.fpu vfp
	.type	_rf_start, %function
_rf_start:

	ldr r3, .trampoline4
	str	r10, [r3]               @ r10 into IP
	ldr r3, .trampoline5
	str	r9, [r3]                @ r9 into W

	bx	lr
	.size	_rf_start, .-_rf_start

	.align	2
	.global	rf_next
	.syntax unified
	.arm
	.fpu vfp
	.type	rf_next, %function
rf_next:

	ldr r9, [r10], #4
	ldr	r3, [r9]
	bx r3
