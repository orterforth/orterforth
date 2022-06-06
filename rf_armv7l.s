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

	.align	2
	.global	rf_code_pfind
rf_code_pfind:

	@str r4, [r13, #-4]!
	@str r5, [r13, #-4]!

	ldr r1, [r8], #4              @ NFA
	ldr r2, [r8], #4              @ STRING ADDR
@
@ SEARCH LOOP
pfin1:
	mov r4, r2                    @ GET ADDR
	ldrb r0, [r1]                 @ GET WORD LENGTH
	mov r3, r0                    @ SAVE LENGTH
	ldrb r5, [r4]
	eor r0, r5
	ands r0, #63                  @ CHECK LENGTHS
	bne pfin5                     @ LENGTHS DIFFER
@
@ LENGTH MATCH, CHECK EACH CHARACTER IN NAME
pfin2:
	add r1, r1, #1
	add r4, r4, #1                @ NEXT CHAR OF NAME
	ldrb r0, [r1]
	ldrb r5, [r4]                 @ COMPARE NAMES
	eor r0, r5
	tst r0, #127
	bne pfin5                     @ NO MATCH
	tst r0, #128                  @ THIS WILL TEST BIT-8
	beq pfin2                     @ MATCH SO FAR, LOOP

@ FOUND END OF NAME (BIT-8 SET); A MATCH
	add r1, r1, #9                @ BX = PFA
	str r1, [r8,#-4]!             @ (S3) <- PFA
	mov r0, #1                    @ TRUE VALUE
	and r3, #255                  @ CLEAR HIGH LENGTH
	mov r1, r3

	@ldr r5, [r13], #4
	@ldr r4, [r13], #4

	b dpush

@ NO NAME FIELD MATCH, TRY ANOTHER
@
@ GET NEXT LINK FIELD ADDR (LFA)
@ (ZERO = FIRST WORD OF DICTIONARY)
@
pfin5:
	add r1, r1, #1                @ NEXT ADDR
	tst r0, #128                  @ END OF NAME
	bne pfin6
	ldrb r0, [r1]                 @ GET NEXT CHAR
	b pfin5                       @ LOOP UNTIL FOUND
@
pfin6:
	ldr r1, [r1]                  @ GET LINK FIELD ADDR
	orrs r1, r1                   @ START OF DICT. (0)?
	bne pfin1                     @ NO, LOOK SOME MORE
	mov r0, #0                    @ FALSE FLAG

	@ldr r5, [r13], #4
	@ldr r4, [r13], #4

	b apush                       @ DONE (NO MATCH FOUND)

	.align	2
	.global	rf_code_encl
rf_code_encl:

	ldr r0, [r8], #4             @ S1 - TERMINATOR CHAR.
	ldr r1, [r8]                  @ S2 - TEXT ADDR
	and r0, #255                  @ ZERO
	mov r3, #-1                   @ CHAR OFFSET COUNTER
	sub r1, r1, #1                @ ADDR -1

@ SCAN TO FIRST NON-TERMINATOR CHAR
@
encl1:
	add r1, r1, #1                @ ADDR +1
	add r3, r3, #1                @ COUNT +1
	ldrb r2, [r1]
	cmp r0, r2
	beq encl1                     @ WAIT FOR NON-TERMINATOR
	str r3, [r8, #-4]!            @ OFFSET TO 1ST TEXT CHR
	cmp r2, #0                    @ NULL CHAR?
	bne encl2                     @ NO
@
@ FOUND NULL BEFORE FIRST NON-TERMINATOR CHAR.
	mov r0, r3                    @ COPY COUNTER
	add r3, r3, #1                @ +1
	mov r1, r3
	b dpush
@
@ FOUND FIRST TEXT CHAR, COUNT THE CHARACTERS
@
encl2:
	add r1, r1, #1                @ ADDR+1
	add r3, r3, #1                @ COUNT +1
	ldrb r2, [r1]                 @ TERMINATOR CHAR?
	cmp r0, r2
	beq encl4                     @ YES
	cmp r2, #0                    @ NULL CHAR
	bne encl2                     @ NO, LOOP AGAIN
@
@ FOUND NULL AT END OF TEXT
@
encl3:
	mov r0, r3                    @ COUNTERS ARE EQUAL
	mov r1, r3
	b dpush

@ FOUND TERINATOR CHARACTER
encl4:
	mov r0, r3
	add r0, r0, #1                @ COUNT +1
	mov r1, r3
	b dpush

	.align	2
	.global	rf_code_cmove
rf_code_cmove:
	
	ldr r2, [r8], #4            @ COUNT
	ldr r1, [r8], #4            @ DEST.
	ldr r3, [r8], #4            @ SOURCE
	cmp r2, #0
	beq cmov2
cmov1:
	ldrb r0, [r3], #1           @ THATS THE MOVE
	strb r0, [r1], #1
	subs r2, r2, #1
	bne cmov1
cmov2:
	b next

	.align	2
	.global	rf_code_ustar
rf_code_ustar:

	ldr r2, [r8], #4
	ldr r3, [r8], #4
	umull r1, r0, r3, r2
	b dpush
