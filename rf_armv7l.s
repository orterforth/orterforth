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

	.text
	.p2align 2
	.global	rf_trampoline
	.global	_rf_trampoline
rf_trampoline:
_rf_trampoline:

	push {fp, lr}
trampoline1:
	ldr	r0, =rf_fp
	ldr	r0, [r0]
	cmp	r0, #0
	beq	trampoline2
	ldr	r10, =rf_ip             @ IP into r10
	ldr	r10, [r10]
	ldr	r3, =rf_w               @ W into r3
	ldr	r3, [r3]
	ldr r8, =rf_sp              @ SP into r8
	ldr r8, [r8]
	ldr r7, =rf_rp              @ RP into r7
	ldr r7, [r7]
	ldr lr, =trampoline1        @ tail call
	bx r0
trampoline2:
	pop {fp, pc}

	.p2align 2
	.global	rf_start
	.global	_rf_start
rf_start:
_rf_start:

	ldr r0, =rf_ip              @ r10 into IP
	str	r10, [r0]
	ldr r0, =rf_w               @ r3 into W
	str	r3, [r0]
	ldr r0, =rf_sp              @ r8 into SP
	str	r8, [r0]
	ldr r0, =rf_rp              @ r7 into RP
	str	r7, [r0]
	bx	lr                      @ carry on in C

	.p2align 2
dpush:
	str r3, [r8, #-4]!
apush:
	str r0, [r8, #-4]!

	.p2align 2
	.global	rf_next
rf_next:
next:
	ldr r3, [r10], #4           @ (W) <- (IP)
next1:
	ldr	r0, [r3]                @ TO 'CFA'
	bx r0

	.p2align 2
	.global	rf_code_lit
rf_code_lit:

	ldr r0, [r10], #4           @ AX <- LITERAL
	b apush                     @ TO TOP OF STACK

	.p2align 2
	.global	rf_code_exec
rf_code_exec:

	ldr r3, [r8], #4            @ GET CFA
	b next1                     @ EXECUTE NEXT

	.p2align 2
	.global	rf_code_bran
rf_code_bran:

bran1:
	ldr r0, [r10]
	add r10, r10, r0            @ (IP) <- (IP) + ((IP))
	b next                      @ JUMP TO OFFSET

	.p2align 2
	.global	rf_code_zbran
rf_code_zbran:

	ldr r0, [r8], #4            @ GET STACK VALUE
	orrs r0, r0                 @ ZERO?
	beq bran1                   @ YES, BRANCH
	add r10, r10, #4            @ NO, CONTINUE...
	b next

	.p2align 2
	.global	rf_code_xloop
rf_code_xloop:

	mov r1, #1                  @ INCREMENT
xloo1:
	ldr r0, [r7]                @ INDEX=INDEX+INCR
	add r0, r0, r1
	str r0, [r7]                @ GET NEW INDEX
	ldr r2, [r7, #4]            @ COMPARE WITH LIMIT
	sub r0, r0, r2
	eors r0, r1                 @ TEST SIGN (BIT-16)
	bmi bran1                   @ KEEP LOOPING...

@ END OF 'DO' LOOP
	add r7, r7, #8              @ ADJ. RETURN STK
	add r10, r10, #4            @ BYPASS BRANCH OFFSET
	b next                      @ CONTINUE...

	.p2align 2
	.global	rf_code_xploo
rf_code_xploo:

	ldr r1, [r8], #4            @ GET LOOP VALUE
	b xloo1

	.p2align 2
	.global	rf_code_xdo
rf_code_xdo:

	ldr r3, [r8], #4            @ INITIAL INDEX VALUE
	ldr r0, [r8], #4            @ LIMIT VALUE
	str r0, [r7, #-4]!
	str r3, [r7, #-4]!
	b next

	.p2align 2
	.global	rf_code_rr
rf_code_rr:

	ldr r0, [r7]                @ GET INDEX VALUE
	b apush                     @ TO PARAMETER STACK

	.p2align 2
	.global	rf_code_digit
rf_code_digit:

	ldrb r3, [r8], #4           @ NUMBER BASE
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
	cmp r0, r3                  @ COMPARE NUMBER TO BASE
	bge digi2                   @ NUMBER ERROR
	mov r3, r0                  @ NEW BINARY NUMBER
	mov r0, #1                  @ TRUE FLAG
	b dpush                     @ ADD TO STACK

@ NUMBER ERROR
@
digi2:
	mov r0, #0                  @ FALSE FLAG
	b apush                     @ BYE

	.p2align 2
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
	str r1, [r8, #-4]!            @ (S3) <- PFA
	mov r0, #1                    @ TRUE VALUE
	and r3, #255                  @ CLEAR HIGH LENGTH

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

	.p2align 2
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
	b dpush

@ FOUND TERINATOR CHARACTER
encl4:
	mov r0, r3
	add r0, r0, #1                @ COUNT +1
	b dpush

	.p2align 2
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

	.p2align 2
	.global	rf_code_ustar
rf_code_ustar:

	ldr r2, [r8], #4
	ldr r1, [r8], #4
	umull r3, r0, r1, r2
	b dpush

	.p2align 2
	.global	rf_code_uslas
rf_code_uslas:

	@str r4, [r7, #-4]!
	ldr r2, [r8], #4            @ DIVISOR
	ldr r1, [r8], #4            @ MSW OF DIVIDEND
	ldr r0, [r8], #4            @ LSW OF DIVIDEND
@	bl umdiv
@umdiv:
	@str lr, [r7, #-4]!
	mov r3, #1
	lsl r3, r3, #31             @ init mask with highest bit set
	mov r4, #0                  @ init quot
	cmp r1, r2                  @ test modh - div
	blo umdiv1                  @ modh < div
	@ overflow condition ( divide by zero ) - show max numbers
	asr r4, r3, #31
	mov r1, r4

	bal umdiv3                  @ return

umdiv1:
	adds r0, r0, r0             @ double precision shift (modh, modl)
	adcs r1, r1, r1             @ ADD with carry and set flags again !
	bcs umdiv4
	cmp r2, r1                  @ test div - modh
	bhi umdiv2                  @ div >  modh ?
umdiv4:
	add r4, r4, r3              @ add single pecision mask
	sub r1, r1, r2              @ subtract single precision div
umdiv2:
	lsr r3, r3, #1              @ shift mask one bit to the right
	ands r3, r3, r3
	bne umdiv1
umdiv3:
	@ now R0 and R1 contain quotient and remainder
	@ldr r2, [r7], #4
	@bx r2

	str r1, [r8, #-4]!          @ remainder
	str r4, [r8, #-4]!          @ quotient

	@ldr r4, [r7], #4

	b next

	.p2align 2
	.global	rf_code_andd
rf_code_andd:

	ldr r0, [r8], #4
	ldr r1, [r8]
	and r0, r0, r1
	str r0, [r8]
	b next

	.p2align 2
	.global	rf_code_orr
rf_code_orr:

	ldr r0, [r8], #4
	ldr r1, [r8]
	orr r0, r0, r1
	str r0, [r8]
	b next

	.p2align 2
	.global	rf_code_xorr
rf_code_xorr:

	ldr r0, [r8], #4
	ldr r1, [r8]
	eor r0, r0, r1
	str r0, [r8]
	b next

	.p2align 2
	.global	rf_code_spat
rf_code_spat:

	mov r0, r8
	b apush

	.p2align 2
	.global	rf_code_spsto
rf_code_spsto:

	ldr r1, =rf_up              @ USER VAR BASE ADDR
	ldr r1, [r1]
	ldr r8, [r1, #12]           @ RESET PARAM. STACK PT.
	b next

	.p2align 2
	.global	rf_code_rpsto
rf_code_rpsto:

	ldr r1, =rf_up              @ (AX) <- USR VAR. BASE
	ldr r1, [r1]
	ldr r7, [r1, #16]           @ RESET RETURN STACK PT.
	b next

	.p2align 2
	.global	rf_code_semis
rf_code_semis:

	ldr r10, [r7], #4           @ (IP) <- (R1)
	b next                      @ ADJUST STACK

	.p2align 2
	.global	rf_code_leave
rf_code_leave:

	ldr r0, [r7]                @ GET INDEX
	str r0, [r7, #4]            @ STORE IT AT LIMIT
	b next

	.p2align 2
	.global rf_code_tor
rf_code_tor:

	ldr r1, [r8], #4            @ GET STACK PARAMETER
	str r1, [r7, #-4]!          @ ADD TO RETURN STACK
	b next

	.p2align 2
	.global rf_code_fromr
rf_code_fromr:

	ldr r1, [r7], #4            @ GET RETURN STACK VALUE
	str r1, [r8, #-4]!          @ DELETE FROM STACK
	b next

	.p2align 2
	.global rf_code_zequ
rf_code_zequ:

	ldr r0, [r8], #4
	orrs r0, r0                 @ DO TEST
	mov r0, #1                  @ TRUE
	beq apush
	@beq zequ1                   @ ITS ZERO
	sub r0, r0, #1              @ FALSE
zequ1:
	b apush

	.p2align 2
	.global rf_code_zless
rf_code_zless:

	ldr r0, [r8], #4
	orrs r0, r0                 @ SET FLAGS
	mov r0, #1                  @ TRUE
	bmi apush
	@bmi zless1
	sub r0, r0, #1              @ FLASE
zless1:
	b apush

	.p2align 2
	.global rf_code_plus
rf_code_plus:

	ldr r0, [r8], #4
	ldr r1, [r8], #4
	add r0, r0, r1
	b apush

	.p2align 2
	.global	rf_code_dplus
rf_code_dplus:

	ldr r0, [r8], #4            @ YHW
	ldr r3, [r8], #4            @ YLW
	ldr r1, [r8], #4            @ XHW
	ldr r2, [r8], #4            @ XLW
	adds r3, r3, r2             @ SLW
	adc r0, r0, r1              @ SHW
	b dpush

	.p2align 2
	.global rf_code_minus
rf_code_minus:

	ldr r0, [r8], #4
	neg r0, r0
	b apush

	.p2align 2
	.global	rf_code_dminu
rf_code_dminu:

	ldr r1, [r8], #4
	ldr r2, [r8], #4
	sub r0, r0, r0              @ ZERO
	mov r3, r0
	subs r3, r3, r2             @ MAKE 2'S COMPLEMENT
	sbc r0, r0, r1              @ HIGH WORD
	b dpush

	.p2align 2
	.global rf_code_over
rf_code_over:

	ldr r0, [r8, #4]
	b apush

	.p2align 2
	.global rf_code_drop
rf_code_drop:

	add r8, r8, #4
	b next

	.p2align 2
	.global rf_code_swap
rf_code_swap:

	ldr r3, [r8]
	ldr r0, [r8, #4]
	str r3, [r8, #4]
	str r0, [r8]
	b next

	.p2align 2
	.global rf_code_dup
rf_code_dup:

	ldr r0, [r8]
	b apush

	.p2align 2
	.global rf_code_pstor
rf_code_pstor:

	ldr r1, [r8], #4            @ ADDRESS
	ldr r0, [r8], #4            @ INCREMENT
	ldr r2, [r1]
	add r2, r2, r0
	str r2, [r1]
	b next

	.p2align 2
	.global rf_code_toggl
rf_code_toggl:

	ldrb r0, [r8], #4           @ BIT PATTERN
	ldr r1, [r8], #4            @ ADDR
	ldr r2, [r1]
	eor r2, r2, r0
	str r2, [r1]
	b next

	.p2align 2
	.global rf_code_at
rf_code_at:

	ldr r1, [r8]
	ldr r0, [r1]
	str r0, [r8]
	b next

	.p2align 2
	.global rf_code_cat
rf_code_cat:

	ldr r1, [r8]
	ldrb r0, [r1]
	str r0, [r8]
	b next

	.p2align 2
	.global rf_code_store
rf_code_store:

	ldr r1, [r8], #4            @ ADDR
	ldr r0, [r8], #4            @ DATA
	str r0, [r1]
	b next

	.p2align 2
	.global rf_code_cstor
rf_code_cstor:

	ldr r1, [r8], #4            @ ADDR
	ldrb r0, [r8], #4           @ DATA
	strb r0, [r1]
	b next

	.p2align 2
	.global rf_code_docol
rf_code_docol:

	add r3, r3, #4              @ W=W+1
	str r10, [r7, #-4]!         @ R1 <- (RP)
	mov r10, r3                 @ (IP) <- (W)
	b next

	.p2align 2
	.global rf_code_docon
rf_code_docon:

	ldr r0, [r3, #4]!           @ PFA @ GET DATA
	b apush

	.p2align 2
	.global rf_code_dovar
rf_code_dovar:

	add r3, r3, #4              @ (DE) <- PFA
	str r3, [r8, #-4]!          @ (S1) <- PFA
	b next

	.p2align 2
	.global rf_code_douse
rf_code_douse:

	ldrb r1, [r3, #4]!          @ PFA
	ldr r0, =rf_up              @ USER VARIABLE ADDR
	ldr r0, [r0]
	add r0, r0, r1
	b apush

	.p2align 2
	.global rf_code_dodoe
rf_code_dodoe:

	str r10, [r7, #-4]!         @ (RP) <- (IP)
	add r3, r3, #4              @ PFA
	ldr r10, [r3], #4           @ NEW CFA
	str r3, [r8, #-4]!          @ PFA
	b next

	.p2align 2
	.global rf_code_stod
rf_code_stod:

	ldr r3, [r8], #4            @ S1
	sub r0, r0, r0              @ AX = 0
	orrs r3, r3                 @ SET FLAGS
	bpl stod1                   @ POSITIVE NUMBER
	sub r1, r1, #1              @ NEGITIVE NUMBER
stod1:
	b dpush

	.p2align 2
	.global rf_code_cold
rf_code_cold:

 	ldr r3, =rf_memory
 	ldr r3, [r3]
	ldr r0, =rf_code_cold       @ COLD vector init
	str r0, [r3, #4]
	ldr r0, [r3, #24]           @ FORTH vocabulary init
	ldr r1, [r3, #68]
	str r0, [r1]
	ldr r1, [r3, #32]           @ UP init
	ldr r0, =rf_up
	str r1, [r0]
	mov r2, #11                 @ USER variables init
	mov r10, r3
	add r10, r10, #24           @ TODO use r3 and change below offset
cold1:
	ldr r0, [r10], #4
	str r0, [r1], #4
	subs r2, r2, #1
	bne cold1
	ldr r10, [r3, #72]          @ IP init to ABORT
	b rf_code_rpsto             @ jump to RP!

	.p2align 2
	.global rf_code_cl
rf_code_cl:

	mov r0, #4
	b apush

	.p2align 2
	.global rf_code_cs
rf_code_cs:

	ldr r0, [r8], #4
	lsl r0, #2
	b apush

 	.p2align 2
 	.global rf_code_tg
rf_code_tg:

 	ldr r3, =rf_memory
 	ldr r3, [r3]
 	add r3, r3, #76
 	ldr r0, [r3]
  ldr r3, [r3, #4]
 	b dpush

	.p2align 2
	.global rf_code_xt
rf_code_xt:

	push {fp, lr}
	bl rf_start
	ldr r1, =rf_fp
	mov r0, #0
	str r0, [r1]
	pop {fp, pc}
