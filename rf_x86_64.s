# ***************************************
# ***                                 ***
# ***    FIG-FORTH for the 8086/88    ***
# ***                                 ***
# ***           Version 1.0           ***
# ***            2/18/81              ***
# ***                                 ***
# ***     Contains interface for      ***
# ***      CP/M-86 (version 1.0)      ***
# ***                                 ***
# ***                                 ***
# ***     Implementation by           ***
# ***           Thomas Newman         ***
# ***           27444 Berenda Way     ***
# ***           Hayward, Ca. 94544    ***
# ***                                 ***
# ***************************************
#
#
#
# NOTE: This version only supports one
#       memory segment of the 8086 (64k bytes).
#
#
# -----------------------------------------------
#
# All publications of the Forth Interest Group
# are public domain.  They may be further
# distributed by the inclusion of this credit
# notice:
#
# This publication has been made available by the
# FORTH INTEREST GROUP (fig)
# P.O. Box 8231
# San Jose, CA 95155
# -----------------------------------------------
#
# Acknowledgements:
#       John Cassady
#       Kim Harris
#       George Flammer
#       Robt. D. Villwock
#-----------------------------------------------
#
# Modified for orterforth integration and x86_64
# in 2022. Some info in the comments no longer 
# applies (CP/M, 8086 register names, 
# segmentation).

.globl _rf_trampoline
.p2align 4, 0x90
_rf_trampoline:

  pushq %rbp                    # enter stack frame
  movq %rsp, %rbp

trampoline1:

	cmpq $0, _rf_fp(%rip)         # if FP is null skip to exit
	je trampoline2

  movq _rf_ip(%rip), %rsi       # IP to rsi
  movq _rf_w(%rip), %rdx        # W to rdx
	leaq trampoline1(%rip), %rax  # push the return address
	push %rax

	movq %rbp, _rf_x86_64_rbp_save(%rip) # save rsp and rbp
	movq %rsp, _rf_x86_64_rsp_save(%rip)
  movq _rf_rp(%rip), %rbp       # put SP and RP into rsp and rbp
  movq _rf_sp(%rip), %rsp

	jmpq *_rf_fp(%rip)            # jump to FP
                                # will return to trampoline1

trampoline2:
	popq %rbp                     # leave stack frame
	retq                          # bye

.globl	_rf_start
.p2align	4, 0x90
_rf_start:

  movq %rdx, _rf_w(%rip)        # rdx to W
  movq %rsi, _rf_ip(%rip)       # rsi to IP

	# unwind rf_start return address
	popq %rax

	# get difference between rsp and rbp
	movq %rbp, %rcx
	subq %rsp, %rcx

	# old SP now in rsi
	movq %rsp, %rsi

	# empty the stack frame, i.e., make rsp = rbp
	movq %rbp, %rsp

	# get the pushed rbp (this is RP)
	popq %rbp
  movq %rbp, _rf_rp(%rip)

	# now rsp is SP
  movq %rsp, _rf_sp(%rip)

	# get the saved rsp and rbp from _rf_trampoline
	# (these are not the same as return addr has been pushed)
	movq _rf_x86_64_rbp_save(%rip), %rbp
	movq _rf_x86_64_rsp_save(%rip), %rsp

	# push rbp as it would have been
	pushq %rbp

	# and mov rsp into rbp
	movq %rsp, %rbp

	# sub the difference from rsp
	subq %rcx, %rsp

	# this is the new stack frame
	movq %rsp, %rdi

	# copy old stack frame here
	# stack spills make this necessary as even if RF_START
	# is the first thing in C code, stack spills happen before
	# _rf_start is called. If a stack value is a reference 
	# to the address of another this will not work.
	cld
  rep movsb

	jmp *%rax                     # carry on in C

dpush:
	pushq %rdx
apush:
	pushq %rax

.globl	_rf_next
.p2align	4, 0x90
_rf_next:

next:
	lodsq                         # AX<- (IP)
	movq %rax, %rbx
next1:
	movq %rbx, %rdx               # (W) <- (IP)
	jmpq *(%rbx)                  # TO 'CFA'

.globl	_rf_code_lit
.p2align	4, 0x90
_rf_code_lit:

	lodsq                         # AX <- LITERAL
	jmp apush                     # TO TOP OF STACK

.globl	_rf_code_exec
.p2align	4, 0x90
_rf_code_exec:

	popq %rbx                     # GET CFA
	jmp next1                     # EXECUTE NEXT

.globl	_rf_code_bran
.p2align	4, 0x90
_rf_code_bran:

bran1:
	addq (%rsi), %rsi             # (IP) <- (IP) + ((IP))
	jmp next                      # JUMP TO OFFSET

.globl	_rf_code_zbran
.p2align	4, 0x90
_rf_code_zbran:

	popq %rax                     # GET STACK VALUE
	orq %rax, %rax                # ZERO?
	jz bran1                      # YES, BRANCH
	addq $8, %rsi                 # NO, CONTINUE...
	jmp next

.globl	_rf_code_xloop
.p2align	4, 0x90
_rf_code_xloop:

	movq $1, %rbx                 # INCREMENT
xloo1:
	addq %rbx, (%rbp)             # INDEX=INDEX+INCR
	movq (%rbp), %rax             # GET NEW INDEX
	subq 8(%rbp), %rax            # COMPARE WITH LIMIT
	xorq %rbx, %rax               # TEST SIGN (BIT-16)
	js bran1                      # KEEP LOOPING...

# END OF 'DO' LOOP
	addq $16, %rbp                # ADJ. RETURN STK
	addq $8, %rsi                 # BYPASS BRANCH OFFSET
	jmp next                      # CONTINUE...

.globl	_rf_code_xploo
.p2align	4, 0x90
_rf_code_xploo:

	popq %rbx                     # GET LOOP VALUE
	jmp xloo1

.globl	_rf_code_xdo
.p2align	4, 0x90
_rf_code_xdo:

	popq %rdx                     # INITIAL INDEX VALUE
	popq %rax                     # LIMIT VALUE
	xchgq %rsp, %rbp              # GET RETURN STACK
	pushq %rax
	pushq %rdx
	xchgq %rsp, %rbp              # GET PARAMETER STACK
	jmp next

.globl	_rf_code_rr
.p2align	4, 0x90
_rf_code_rr:

	movq (%rbp), %rax             # GET INDEX VALUE
	jmp apush                     # TO PARAMETER STACK

.globl	_rf_code_digit
.p2align	4, 0x90
_rf_code_digit:

	popq %rdx                     # NUMBER BASE
	popq %rax                     # ASCII DIGIT
	sub $48, %al
	jb digi2                      # NUMBER ERROR
	cmp $9, %al
	jbe digi1                     # NUMBER = 0 THRU 9
	sub $7, %al
	cmp $10, %al                  # NUMBER 'A' THRU 'Z' ?
	jb digi2                      # NO
#
digi1:
	cmp %dl, %al                  # COMPARE NUMBER TO BASE
	jae digi2                     # NUMBER ERROR
	subq %rdx, %rdx               # ZERO
	mov %al, %dl                  # NEW BINARY NUMBER
	mov $1, %al                   # TRUE FLAG
	jmp dpush                     # ADD TO STACK

# NUMBER ERROR
#
digi2:
	subq %rax, %rax               # FALSE FLAG
	jmp apush                     # BYE

.globl	_rf_code_pfind
.p2align	4, 0x90
_rf_code_pfind:

  # mov %ds, %ax
  # mov %ax, %es                  # ES = DS
	popq %rbx                     # NFA
	popq %rcx                     # STRING ADDR
#
# SEARCH LOOP
pfin1:
	movq %rcx, %rdi               # GET ADDR
	movb (%rbx), %al              # GET WORD LENGTH
	movb %al, %dl                 # SAVE LENGTH
	xorb (%rdi), %al
	andb $0x3F, %al               # CHECK LENGTHS
	jnz pfin5                     # LENGTHS DIFFER
#
# LENGTH MATCH, CHECK EACH CHARACTER IN NAME
pfin2:
	incq %rbx
	incq %rdi                     # NEXT CHAR OF NAME
	movb (%rbx), %al
	xorb (%rdi), %al              # COMPARE NAMES
	addb %al, %al                 # THIS WILL TEST BIT-8
	jnz pfin5                     # NO MATCH
	jnb pfin2                     # MATCH SO FAR, LOOP

# FOUND END OF NAME (BIT-8 SET); A MATCH
	addq $17, %rbx                # BX = PFA
	pushq %rbx                    # (S3) <- PFA
	movq $1, %rax                 # TRUE VALUE
	andq $0xFF, %rdx              # CLEAR HIGH LENGTH
	jmp dpush

# NO NAME FIELD MATCH, TRY ANOTHER
#
# GET NEXT LINK FIELD ADDR (LFA)
# (ZERO = FIRST WORD OF DICTIONARY)
#
pfin5:
	incq %rbx                     # NEXT ADDR
	jb pfin6                      # END OF NAME
	movb (%rbx), %al              # GET NEXT CHAR
	addb %al, %al                 # SET/RESET CARRY
	jmp pfin5                     # LOOP UNTIL FOUND
#
pfin6:
	movq (%rbx), %rbx             # GET LINK FIELD ADDR
	orq %rbx, %rbx                # START OF DICT. (0)?
	jnz pfin1                     # NO, LOOK SOME MORE
	movq $0, %rax                 # FALSE FLAG
	jmp apush                     # DONE (NO MATCH FOUND)

.globl	_rf_code_encl
.p2align	4, 0x90
_rf_code_encl:

	popq %rax                     # S1 - TERMINATOR CHAR.
	popq %rbx                     # S2 - TEXT ADDR
	pushq %rbx                    # ADDR BACK TO STACK
	andq $0xFF, %rdx              # ZERO TODO MOV AH, 0
	movq $-1, %rdx                # CHAR OFFSET COUNTER
	decq %rbx                     # ADDR -1

# SCAN TO FIRST NON-TERMINATOR CHAR
#
encl1:
	incq %rbx                     # ADDR +1
	incq %rdx                     # COUNT +1
	cmpb (%rbx), %al
	jz encl1                      # WAIT FOR NON-TERMINATOR
	pushq %rdx                    # OFFSET TO 1ST TEXT CHR
	cmpb (%rbx), %ah              # NULL CHAR?
	jnz encl2                     # NO

# FOUND NULL BEFORE FIRST NON-TERMINATOR CHAR.
	movq %rdx, %rax               # COPY COUNTER
	incq %rdx                     # +1
	jmp dpush

# FOUND FIRST TEXT CHAR, COUNT THE CHARACTERS
#
encl2:
	incq %rbx                     # ADDR+1
	incq %rdx                     # COUNT +1
	cmpb (%rbx), %al              # TERMINATOR CHAR?
	jz encl4                      # YES
	cmpb (%rbx), %ah              # NULL CHAR
	jnz encl2                     # NO, LOOP AGAIN

# FOUND NULL AT END OF TEXT
#
encl3:
	movq %rdx, %rax               # COUNTERS ARE EQUAL
	jmp dpush

# FOUND TERINATOR CHARACTER
encl4:
	movq %rdx, %rax
	incq %rax                     # COUNT +1
	jmp dpush

.globl	_rf_code_cmove
.p2align	4, 0x90
_rf_code_cmove:

	cld                           # INC DIRECTION
	movq %rsi, %rbx               # SAVE IP
	popq %rcx                     # COUNT
	popq %rdi                     # DEST.
	popq %rsi                     # SOURCE
	# mov %ds, %ax
	# mov %ax, %es                  # ES <- DS
	rep movsb                     # THATS THE MOVE
	movq %rbx, %rsi               # GET BACK IP
	jmp next

.globl	_rf_code_ustar
.p2align	4, 0x90
_rf_code_ustar:

	popq %rax
	popq %rbx
	mulq %rbx                     # UNSIGNED
	xchg %rdx, %rax               # AX NOW = MSW
	jmp dpush                     # STORE DOUBLE WORD

.globl _rf_code_uslas
.p2align	4, 0x90
_rf_code_uslas:

	popq %rbx                     # DIVISOR
	popq %rdx                     # MSW OF DIVIDEND
	popq %rax                     # LSW OF DIVIDEND
	cmpq %rbx, %rdx               # DIVIDE BY ZERO?
	jnb dzero                     # ZERO DIVIDE, NO WAY
	divq %rbx                     # 16 BIT DIVIDE
	jmp dpush                     # STORE QUOT/REM

# DIVIDE BY ZERO ERROR (SHOW MAX NUMBERS)
#
dzero:
	movq $-1, %rax
	movq %rax, %rdx
	jmp dpush                     # STORE QUOT/REM

.globl	_rf_code_andd
.p2align	4, 0x90
_rf_code_andd:

	popq %rax
	popq %rbx
	andq %rbx, %rax
	jmp apush

.globl	_rf_code_orr
.p2align	4, 0x90
_rf_code_orr:

	popq %rax
	popq %rbx
	orq %rbx, %rax
	jmp apush

.globl	_rf_code_xorr
.p2align	4, 0x90
_rf_code_xorr:

	popq %rax
	popq %rbx
	xorq %rbx, %rax
	jmp apush

.globl	_rf_code_spat
.p2align	4, 0x90
_rf_code_spat:

	movq %rsp, %rax
	jmp apush

.globl	_rf_code_spsto
.p2align	4, 0x90
_rf_code_spsto:

	movq _rf_up(%rip), %rbx       # USER VAR BASE ADDR
	movq 24(%rbx), %rsp           # RESET PARAM. STACK PT.
	jmp next

.globl	_rf_code_rpsto
.p2align	4, 0x90
_rf_code_rpsto:

	movq _rf_up(%rip), %rbx       # USER VAR BASE ADDR
	movq 32(%rbx), %rbp           # RESET PARAM. STACK PT.
	jmp next

.globl	_rf_code_semis
.p2align	4, 0x90
_rf_code_semis:

	movq (%rbp), %rsi             # (IP) <- (R1)
	addq $8, %rbp                 # ADJUST STACK
	jmp next

.globl	_rf_code_leave
.p2align	4, 0x90
_rf_code_leave:

	movq (%rbp), %rax             # GET INDEX
	movq %rax, 8(%rbp)            # STORE IT AT LIMIT
	jmp next

.globl	_rf_code_tor
.p2align	4, 0x90
_rf_code_tor:

	popq %rbx                     # GET STACK PARAMETER
	subq $8, %rbp                 # MOVE RETURN STACK DOWN
	movq %rbx, (%rbp)             # ADD TO RETURN STACK
	jmp next

.globl	_rf_code_fromr
.p2align	4, 0x90
_rf_code_fromr:

	movq (%rbp), %rax             # GET RETURN STACK VALUE
	addq $8, %rbp                 # DELETE FROM STACK
	jmp apush

.globl	_rf_code_zequ
.p2align	4, 0x90
_rf_code_zequ:

	popq %rax
	orq %rax, %rax                # DO TEST
	movq $1, %rax                 # TRUE
	jz zequ1                      # ITS ZERO
	decq %rax                     # FALSE
zequ1:
	jmp apush

.globl	_rf_code_zless
.p2align	4, 0x90
_rf_code_zless:

	popq %rax
	orq %rax, %rax                # DO TEST
	movq $1, %rax                 # TRUE
	js zless1                     # ITS ZERO
	decq %rax                     # FALSE
zless1:
	jmp apush

.globl	_rf_code_plus
.p2align	4, 0x90
_rf_code_plus:

	popq %rax
	popq %rbx
	addq %rbx, %rax
	jmp apush

.globl	_rf_code_dplus
.p2align	4, 0x90
_rf_code_dplus:

	popq %rax                     # YHW
	popq %rdx                     # YLW
	popq %rbx                     # XHW
	popq %rcx                     # XLW
	addq %rcx, %rdx               # SLW
	adcq %rbx, %rax               # SHW
	jmp dpush

.globl	_rf_code_minus
.p2align	4, 0x90
_rf_code_minus:

	popq %rax
	negq %rax
	jmp apush

.globl	_rf_code_dminu
.p2align	4, 0x90
_rf_code_dminu:

	popq %rbx
	popq %rcx
	subq %rax, %rax               # ZERO
	movq %rax, %rdx
	subq %rcx, %rdx               # MAKE 2'S COMPLEMENT
	sbbq %rbx, %rax               # HIGH WORD
	jmp dpush

.globl	_rf_code_over
.p2align	4, 0x90
_rf_code_over:

	popq %rdx
	popq %rax
	pushq %rax
	jmp dpush

.globl	_rf_code_drop
.p2align	4, 0x90
_rf_code_drop:

	popq %rax
	jmp next

.globl	_rf_code_swap
.p2align	4, 0x90
_rf_code_swap:

	popq %rdx
	popq %rax
	jmp dpush

.globl	_rf_code_dup
.p2align	4, 0x90
_rf_code_dup:

	popq %rax
	pushq %rax
	jmp apush

.globl	_rf_code_pstor
.p2align	4, 0x90
_rf_code_pstor:

	popq %rbx                     # ADDRESS
	popq %rax                     # INCREMENT
	addq %rax, (%rbx)
	jmp next

.globl	_rf_code_toggl
.p2align	4, 0x90
_rf_code_toggl:

	popq %rax                     # BIT PATTERN
	popq %rbx                     # ADDR
	xorb %al, (%rbx)
	jmp next

.globl	_rf_code_at
.p2align	4, 0x90
_rf_code_at:

	popq %rbx
	movq (%rbx), %rax
	jmp apush

.globl	_rf_code_cat
.p2align	4, 0x90
_rf_code_cat:

	popq %rbx
	movb (%rbx), %al
	andq $0xFF, %rax
	jmp apush

.globl	_rf_code_store
.p2align	4, 0x90
_rf_code_store:

	popq %rbx                     # ADDR
	popq %rax                     # DATA
	movq %rax, (%rbx)
	jmp next

.globl	_rf_code_cstor
.p2align	4, 0x90
_rf_code_cstor:

	popq %rbx                     # ADDR
	popq %rax                     # DATA
	movb %al, (%rbx)
	jmp next

.globl	_rf_code_docol
.p2align	4, 0x90
_rf_code_docol:

	addq $8, %rdx                 # W=W+1
	subq $8, %rbp                 # (RP) <- (RP)-2
	movq %rsi, (%rbp)             # R1 <- (RP)
	movq %rdx, %rsi               # (IP) <- (W)
	jmp next

.globl	_rf_code_docon
.p2align	4, 0x90
_rf_code_docon:

	addq $8, %rdx                 # PFA
	movq %rdx, %rbx
	movq (%rbx), %rax             # GET DATA
	jmp apush

.globl	_rf_code_dovar
.p2align	4, 0x90
_rf_code_dovar:

	addq $8, %rdx                 # (DE) <- PFA
	pushq %rdx                    # (S1) <- PFA
	jmp next

.globl	_rf_code_douse
.p2align	4, 0x90
_rf_code_douse:

	addq $8, %rdx                 # PFA
	movq %rdx, %rbx
	movb (%rbx), %bl
	andq $0xFF, %rbx
	movq _rf_up(%rip), %rdi       # USER VARIABLE ADDR
	leaq (%rbx, %rdi), %rax       # ADDR OF VARIABLE
	jmp apush

.globl	_rf_code_dodoe
.p2align	4, 0x90
_rf_code_dodoe:

	xchgq %rsp, %rbp              # GET RETURN STACK
	pushq %rsi                    # (RP) <- (IP)
	xchgq %rsp, %rbp
	addq $8, %rdx                 # PFA
	movq %rdx, %rbx
	movq (%rbx), %rsi             # NEW CFA
	addq $8, %rdx
	pushq %rdx                    # PFA
	jmp next

.globl	_rf_code_stod
.p2align	4, 0x90
_rf_code_stod:

	popq %rdx                     # S1
	subq %rax, %rax               # AX = 0
	orq %rdx, %rdx                # SET FLAGS
	jns stod1                     # POSITIVE NUMBER
	decq %rax                     # NEGITIVE NUMBER
stod1:
	jmp dpush

.globl	_rf_code_rcll
.p2align	4, 0x90
_rf_code_rcll:

	movq $8, %rax
	jmp apush

.globl	_rf_code_rcls
.p2align	4, 0x90
_rf_code_rcls:

	popq %rax
	shlq $3, %rax
	jmp apush

.section __DATA.__data,""

.data
.globl _rf_x86_64_rbp_save
.p2align 3
_rf_x86_64_rbp_save:

	.quad	0

.data
.globl _rf_x86_64_rsp_save
.p2align 3
_rf_x86_64_rsp_save:

	.quad	0
