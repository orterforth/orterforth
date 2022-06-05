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

@	.data
@	.align	2
@savefp:
@	.space	4
@
@	.align	2
@savesp:
@	.space	4

	.text
	.align	2
	.global	_rf_trampoline
_rf_trampoline:

	push	{fp, lr}

.trampoline1:

	ldr	r3, =rf_fp
	ldr	r3, [r3]
	cmp	r3, #0
	beq	.trampoline2

	ldr	r10, =rf_ip             @ IP into r10
	ldr	r10, [r10]
	ldr	r9, =rf_w               @ W into r9
	ldr	r9, [r9]

	@ ldr r0, =savesp             @ save sp and fp
	@ str r13, [r0]
	@ ldr r0, =savefp
	@ str r11, [r0]
	ldr r0, =rf_sp
	ldr r8, [r0]                @ SP into r8 (for now)

	blx	r3
	b .trampoline1

.trampoline2:

	pop	{fp, pc}

	.align	2
	.global	_rf_start
_rf_start:

	ldr r3, =rf_ip
	str	r10, [r3]               @ r10 into IP
	ldr r3, =rf_w
	str	r9, [r3]                @ r9 into W
	ldr r3, =rf_sp
	str	r8, [r3]                @ r8 into SP

	bx	lr
	.size	_rf_start, .-_rf_start

dpush:

	str r1, [r8,#-4]!

apush:

	str r0, [r8,#-4]!

	.align	2
	.global	rf_next
rf_next:
next:
	ldr r9, [r10], #4
next1:
	ldr	r0, [r9]
	bx r0

	.align	2
	.global	rf_code_lit
rf_code_lit:

	ldr r0, [r10], #4           @ AX <- LITERAL
	b apush                     @ TO TOP OF STACK

	.align	2
	.global	rf_code_exec
rf_code_exec:

	ldr r9, [r8], #4            @ GET CFA
	b next1                     @ EXECUTE NEXT

	.align	2
	.global	rf_code_bran
rf_code_bran:

bran1:
	ldr r0, [r10]
	add r10, r10, r0            @ (IP) <- (IP) + ((IP))
	b next                      @ JUMP TO OFFSET

	.align	2
	.global	rf_code_zbran
rf_code_zbran:

	ldr r0, [r8], #4            @ GET STACK VALUE
	orrs r0, r0                 @ ZERO?
	beq bran1                   @ YES, BRANCH
	add r10, r10, #4            @ NO, CONTINUE...
	b next
