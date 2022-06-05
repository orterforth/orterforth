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
	ldr r0, =rf_rp
	ldr r7, [r0]                @ RP into r7 (for now)

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
	ldr r3, =rf_rp
	str	r7, [r3]                @ r7 into RP

	bx	lr                      @ carry on in C

dpush:

	str r1, [r8,#-4]!

apush:

	str r0, [r8,#-4]!

	.align	2
	.global	rf_next
rf_next:
next:
	ldr r9, [r10], #4           @ (W) <- (IP)
next1:
	ldr	r0, [r9]                @ TO 'CFA'
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

	.align	2
	.global	rf_code_xloop
rf_code_xloop:

	mov r1, #1                  @ INCREMENT
xloo1:
	ldr r0, [r7]                @ INDEX=INDEX+INCR
	add r0, r0, r1
	str r0, [r7]                @ GET NEW INDEX
	ldr r2, [r7,#4]             @ COMPARE WITH LIMIT
	sub r0, r0, r2
	eors r0, r1                 @ TEST SIGN (BIT-16)
	bmi bran1                   @ KEEP LOOPING...

@ END OF 'DO' LOOP
	add r7, r7, #8              @ ADJ. RETURN STK
	add r10, r10, #4            @ BYPASS BRANCH OFFSET
	b next                      @ CONTINUE...

	.align	2
	.global	rf_code_xploo
rf_code_xploo:

	ldr r1, [r8], #4            @ GET LOOP VALUE
	b xloo1

	.align	2
	.global	rf_code_xdo
rf_code_xdo:

	ldr r3, [r8], #4            @ INITIAL INDEX VALUE
	ldr r0, [r8], #4            @ LIMIT VALUE
	str r0, [r7,#-4]!
	str r3, [r7,#-4]!
	b next

	.align	2
	.global	rf_code_rr
rf_code_rr:

	ldr r0, [r7]                @ GET INDEX VALUE
	b apush                     @ TO PARAMETER STACK

	.align	2
	.global	rf_code_digit
rf_code_digit:

	ldrb r1, [r8], #4           @ NUMBER BASE
	ldrb r0, [r8], #4           @ ASCII DIGIT
	subs r0, r0, #48
	blt digi2                   @ NUMBER ERROR
	cmp r0, #9
	ble digi1                   @ NUMBER = 0 THRU 9
	sub r0, r0, #7
	cmp r0, #10                 @ NUMBER 'A' THRU 'Z' ?
	blt digi2                   @ NO
@
digi1:
	cmp r0, r1                  @ COMPARE NUMBER TO BASE
	bge digi2                   @ NUMBER ERROR
	mov r1, r0                  @ NEW BINARY NUMBER
	mov r0, #1                  @ TRUE FLAG
	b dpush                     @ ADD TO STACK

@ NUMBER ERROR
@
digi2:
	mov r0, #0                  @ FALSE FLAG
	b apush                     @ BYE
