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
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 1, uses_anonymous_args = 0
	push	{fp, lr}
	add	fp, sp, #4
	b	.L2
.L3:
	ldr	r3, .L4
	ldr	r3, [r3]
	blx	r3
.L2:
	ldr	r3, .L4
	ldr	r3, [r3]
	cmp	r3, #0
	bne	.L3
	nop
	pop	{fp, pc}
.L5:
	.align	2
.L4:
	.word	rf_fp
	.size	_rf_trampoline, .-_rf_trampoline
	.align	2
	.global	_rf_start
	.syntax unified
	.arm
	.fpu vfp
	.type	_rf_start, %function
_rf_start:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 1, uses_anonymous_args = 0
	@ link register save eliminated.
	str	fp, [sp, #-4]!
	add	fp, sp, #0
	nop
	add	sp, fp, #0
	@ sp needed
	ldr	fp, [sp], #4
	bx	lr
	.size	_rf_start, .-_rf_start
