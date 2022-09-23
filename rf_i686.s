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
# Modified for orterforth integration and i686
# in 2022. Some info in the comments no longer 
# applies (CP/M, 8086 register names, 
# segmentation, byte offsets).

	.text
	.globl rf_trampoline
	.globl _rf_trampoline
rf_trampoline:
_rf_trampoline:

	pushl	%ebp                    # enter stack frame
	movl %esp, %ebp

	pushl %ebx                    # callee save ebx
	pushl %esi                    # callee save esi

	call __x86.get_pc_thunk.bx
	addl $_GLOBAL_OFFSET_TABLE_, %ebx
	pushl %ebx

trampoline1:

	popl %ebx
	pushl %ebx

	movl rf_fp@GOTOFF(%ebx), %eax # if FP is null skip to exit
	# testl %eax, %eax
	cmpl $0, %eax
	je trampoline2

  movl _rf_ip@GOTOFF(%ebx), %esi # IP to esi
  movl _rf_w@GOTOFF(%ebx), %edx  # W to edx
	leal trampoline1@GOTOFF(%ebx), %ecx # push the return address
	push %ecx

	movl %ebp, _rf_i686_ebp_save@GOTOFF(%ebx) # save esp and ebp
	movl %esp, _rf_i686_esp_save@GOTOFF(%ebx)
  movl _rf_rp@GOTOFF(%ebx), %ebp # put SP and RP into rsp and rbp
  movl _rf_sp@GOTOFF(%ebx), %esp

	jmp *%eax                     # jump to FP
                                # will return to trampoline1

trampoline2:

	popl %ebx
	popl %esi
	popl %ebx
	leave                         # leave stack frame
	ret                           # bye

	.globl	rf_start
	.globl	_rf_start
rf_start:
_rf_start:

	call	__x86.get_pc_thunk.ax
	addl	$_GLOBAL_OFFSET_TABLE_, %eax

  movl %edx, _rf_w@GOTOFF(%eax)  # edx to W
  movl %esi, _rf_ip@GOTOFF(%eax) # esi to IP

	popl %edx                     # unwind rf_start return address

	movl %ebp, %ecx               # get difference between esp and ebp
	subl %esp, %ecx

	movl %esp, %esi               # old SP now in esi

	movl %ebp, %esp               # empty the stack frame, i.e., make esp = ebp

	popl %ebp                     # get the pushed ebp (this is RP)
  movl %ebp, _rf_rp@GOTOFF(%eax)

  movl %esp, _rf_sp@GOTOFF(%eax) # now esp is SP

	movl _rf_i686_ebp_save@GOTOFF(%eax), %ebp # get the saved esp and ebp from _rf_trampoline
	movl _rf_i686_esp_save@GOTOFF(%eax), %esp # (these are not the same as return addr has been pushed)

	pushl %ebp                    # push ebp as it would have been

	movl %esp, %ebp               # and mov esp into ebp

	subl %ecx, %esp               # sub the difference from esp

	movl %esp, %edi               # this is the new stack frame

	# copy old stack frame here
	# stack spills make this necessary as even if RF_START
	# is the first thing in C code, stack spills happen before
	# _rf_start is called. If a stack value is a reference 
	# to the address of another this will not work.
	cld
  rep movsb

	jmp *%edx                       # carry on in C

dpush:
	pushl %edx
apush:
	pushl %eax

	.globl rf_next
	.globl _rf_next
rf_next:
_rf_next:
next:

	lodsl                         # AX<- (IP)
	movl %eax, %edx               # (W) <- (IP)
next1:
	jmp *(%edx)                   # TO 'CFA'

	.globl	rf_code_lit
	.globl	_rf_code_lit
rf_code_lit:
_rf_code_lit:

	lodsl                         # AX <- LITERAL
	jmp apush                     # TO TOP OF STACK

	.globl	rf_code_exec
	.globl	_rf_code_exec
rf_code_exec:
_rf_code_exec:

	popl %edx                     # GET CFA
	jmp next1                     # EXECUTE NEXT
	# jmp *(%edx)

	.globl	rf_code_bran
	.globl	_rf_code_bran
rf_code_bran:
_rf_code_bran:

bran1:
	addl (%esi), %esi             # (IP) <- (IP) + ((IP))
	jmp next                      # JUMP TO OFFSET

	.globl	rf_code_zbran
	.globl	_rf_code_zbran
rf_code_zbran:
_rf_code_zbran:

	popl %eax                     # GET STACK VALUE
	orl %eax, %eax                # ZERO?
	jz bran1                      # YES, BRANCH
	addl $4, %esi                 # NO, CONTINUE...
	jmp next

	.globl	rf_code_xloop
	.globl	_rf_code_xloop
rf_code_xloop:
_rf_code_xloop:

	movl $1, %ebx                 # INCREMENT
xloo1:
	addl %ebx, (%ebp)             # INDEX=INDEX+INCR
	movl (%ebp), %eax             # GET NEW INDEX
	subl 4(%ebp), %eax            # COMPARE WITH LIMIT
	xorl %ebx, %eax               # TEST SIGN (BIT-16)
	js bran1                      # KEEP LOOPING...

# END OF 'DO' LOOP
	addl $8, %ebp                 # ADJ. RETURN STK
	addl $4, %esi                 # BYPASS BRANCH OFFSET
	jmp next                      # CONTINUE...

	.globl	rf_code_xploo
	.globl	_rf_code_xploo
rf_code_xploo:
_rf_code_xploo:

	popl %ebx                     # GET LOOP VALUE
	jmp xloo1

	.globl	rf_code_xdo
	.globl	_rf_code_xdo
rf_code_xdo:
_rf_code_xdo:

	popl %edx                     # INITIAL INDEX VALUE
	popl %eax                     # LIMIT VALUE
	xchgl %esp, %ebp              # GET RETURN STACK
	pushl %eax
	pushl %edx
	xchgl %esp, %ebp              # GET PARAMETER STACK
	jmp next

	.globl	rf_code_rr
	.globl	_rf_code_rr
rf_code_rr:
_rf_code_rr:

	movl (%ebp), %eax             # GET INDEX VALUE
	jmp apush                     # TO PARAMETER STACK

	.globl	rf_code_digit
	.globl	_rf_code_digit
rf_code_digit:
_rf_code_digit:

	popl %edx                     # NUMBER BASE
	popl %eax                     # ASCII DIGIT
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
	subl %edx, %edx               # ZERO
	mov %al, %dl                  # NEW BINARY NUMBER
	mov $1, %al                   # TRUE FLAG
	jmp dpush                     # ADD TO STACK

# NUMBER ERROR
#
digi2:
	subl %eax, %eax               # FALSE FLAG
	jmp apush                     # BYE

	.globl	rf_code_pfind
	.globl	_rf_code_pfind
rf_code_pfind:
_rf_code_pfind:

  # mov %ds, %ax
  # mov %ax, %es                  # ES = DS
	popl %ebx                     # NFA
	popl %ecx                     # STRING ADDR
#
# SEARCH LOOP
pfin1:
	movl %ecx, %edi               # GET ADDR
	movb (%ebx), %al              # GET WORD LENGTH
	movb %al, %dl                 # SAVE LENGTH
	xorb (%edi), %al
	andb $0x3F, %al               # CHECK LENGTHS
	jnz pfin5                     # LENGTHS DIFFER
#
# LENGTH MATCH, CHECK EACH CHARACTER IN NAME
pfin2:
	incl %ebx
	incl %edi                     # NEXT CHAR OF NAME
	movb (%ebx), %al
	xorb (%edi), %al              # COMPARE NAMES
	addb %al, %al                 # THIS WILL TEST BIT-8
	jnz pfin5                     # NO MATCH
	jnb pfin2                     # MATCH SO FAR, LOOP

# FOUND END OF NAME (BIT-8 SET); A MATCH
	addl $9, %ebx                 # BX = PFA
	pushl %ebx                    # (S3) <- PFA
	movl $1, %eax                 # TRUE VALUE
	andl $0xFF, %edx              # CLEAR HIGH LENGTH
	jmp dpush

# NO NAME FIELD MATCH, TRY ANOTHER
#
# GET NEXT LINK FIELD ADDR (LFA)
# (ZERO = FIRST WORD OF DICTIONARY)
#
pfin5:
	incl %ebx                     # NEXT ADDR
	jb pfin6                      # END OF NAME
	movb (%ebx), %al              # GET NEXT CHAR
	addb %al, %al                 # SET/RESET CARRY
	jmp pfin5                     # LOOP UNTIL FOUND
#
pfin6:
	movl (%ebx), %ebx             # GET LINK FIELD ADDR
	orl %ebx, %ebx                # START OF DICT. (0)?
	jnz pfin1                     # NO, LOOK SOME MORE
	movl $0, %eax                 # FALSE FLAG
	jmp apush                     # DONE (NO MATCH FOUND)

	.globl	rf_code_encl
	.globl	_rf_code_encl
rf_code_encl:
_rf_code_encl:

	popl %eax                     # S1 - TERMINATOR CHAR.
	popl %ebx                     # S2 - TEXT ADDR
	pushl %ebx                    # ADDR BACK TO STACK
	andl $0xFF, %eax              # ZERO
	movl $-1, %edx                # CHAR OFFSET COUNTER
	decl %ebx                     # ADDR -1

# SCAN TO FIRST NON-TERMINATOR CHAR
#
encl1:
	incl %ebx                     # ADDR +1
	incl %edx                     # COUNT +1
	cmpb (%ebx), %al
	jz encl1                      # WAIT FOR NON-TERMINATOR
	pushl %edx                    # OFFSET TO 1ST TEXT CHR
	cmpb (%ebx), %ah              # NULL CHAR?
	jnz encl2                     # NO

# FOUND NULL BEFORE FIRST NON-TERMINATOR CHAR.
	movl %edx, %eax               # COPY COUNTER
	incl %edx                     # +1
	jmp dpush

# FOUND FIRST TEXT CHAR, COUNT THE CHARACTERS
#
encl2:
	incl %ebx                     # ADDR+1
	incl %edx                     # COUNT +1
	cmpb (%ebx), %al              # TERMINATOR CHAR?
	jz encl4                      # YES
	cmpb (%ebx), %ah              # NULL CHAR
	jnz encl2                     # NO, LOOP AGAIN

# FOUND NULL AT END OF TEXT
#
encl3:
	movl %edx, %eax               # COUNTERS ARE EQUAL
	jmp dpush

# FOUND TERINATOR CHARACTER
encl4:
	movl %edx, %eax
	incl %eax                     # COUNT +1
	jmp dpush

	.globl	rf_code_cmove
	.globl	_rf_code_cmove
rf_code_cmove:
_rf_code_cmove:

	cld                           # INC DIRECTION
	movl %esi, %ebx               # SAVE IP
	popl %ecx                     # COUNT
	popl %edi                     # DEST.
	popl %esi                     # SOURCE
	# mov %ds, %ax
	# mov %ax, %es                  # ES <- DS
	rep movsb                     # THATS THE MOVE
 	movl %ebx, %esi               # GET BACK IP
 	jmp next

	.globl	rf_code_ustar
	.globl	_rf_code_ustar
rf_code_ustar:
_rf_code_ustar:

	popl %eax
	popl %ebx
	mull %ebx                     # UNSIGNED
	xchgl %edx, %eax              # AX NOW = MSW
	jmp dpush                     # STORE DOUBLE WORD

	.globl rf_code_uslas
	.globl _rf_code_uslas
rf_code_uslas:
_rf_code_uslas:

	popl %ebx                     # DIVISOR
	popl %edx                     # MSW OF DIVIDEND
	popl %eax                     # LSW OF DIVIDEND
	cmpl %ebx, %edx               # DIVIDE BY ZERO?
	jnb dzero                     # ZERO DIVIDE, NO WAY
	divl %ebx                     # 16 BIT DIVIDE
	jmp dpush                     # STORE QUOT/REM

# DIVIDE BY ZERO ERROR (SHOW MAX NUMBERS)
#
dzero:
	movl $-1, %eax
	movl %eax, %edx
	jmp dpush                     # STORE QUOT/REM

	.globl	rf_code_andd
	.globl	_rf_code_andd
rf_code_andd:
_rf_code_andd:

	popl %eax
	popl %ebx
	andl %ebx, %eax
	jmp apush

	.globl	rf_code_orr
	.globl	_rf_code_orr
rf_code_orr:
_rf_code_orr:

	popl %eax
	popl %ebx
	orl %ebx, %eax
	jmp apush

	.globl	rf_code_xorr
	.globl	_rf_code_xorr
rf_code_xorr:
_rf_code_xorr:

	popl %eax
	popl %ebx
	xorl %ebx, %eax
	jmp apush

	.globl	rf_code_spat
	.globl	_rf_code_spat
rf_code_spat:
_rf_code_spat:

	movl %esp, %eax
	jmp apush

	.globl	rf_code_spsto
	.globl	_rf_code_spsto
rf_code_spsto:
_rf_code_spsto:

	call __x86.get_pc_thunk.ax
	addl $_GLOBAL_OFFSET_TABLE_, %eax
	movl _rf_up@GOTOFF(%eax), %ebx # USER VAR BASE ADDR
	movl 12(%ebx), %esp           # RESET PARAM. STACK PT.
	jmp next

	.globl	rf_code_rpsto
	.globl	_rf_code_rpsto
rf_code_rpsto:
_rf_code_rpsto:

	call __x86.get_pc_thunk.ax
	addl $_GLOBAL_OFFSET_TABLE_, %eax
	movl _rf_up@GOTOFF(%eax), %ebx # (AX) <- USR VAR. BASE
	movl 16(%ebx), %ebp           # RESET RETURN STACK PT.
	jmp next

	.globl	rf_code_semis
	.globl	_rf_code_semis
rf_code_semis:
_rf_code_semis:

	movl (%ebp), %esi             # (IP) <- (R1)
	addl $4, %ebp                 # ADJUST STACK
	jmp next

	.globl	rf_code_leave
	.globl	_rf_code_leave
rf_code_leave:
_rf_code_leave:

	movl (%ebp), %eax             # GET INDEX
	movl %eax, 4(%ebp)            # STORE IT AT LIMIT
	jmp next

	.globl	rf_code_tor
	.globl	_rf_code_tor
rf_code_tor:
_rf_code_tor:

	popl %ebx                     # GET STACK PARAMETER
	subl $4, %ebp                 # MOVE RETURN STACK DOWN
	movl %ebx, (%ebp)             # ADD TO RETURN STACK
	jmp next

	.globl	rf_code_fromr
	.globl	_rf_code_fromr
rf_code_fromr:
_rf_code_fromr:

	movl (%ebp), %eax             # GET RETURN STACK VALUE
	addl $4, %ebp                 # DELETE FROM STACK
	jmp apush

	.globl	rf_code_zequ
	.globl	_rf_code_zequ
rf_code_zequ:
_rf_code_zequ:

	popl %eax
	orl %eax, %eax                # DO TEST
	movl $1, %eax                 # TRUE
	jz zequ1                      # ITS ZERO
	decl %eax                     # FALSE
zequ1:
	jmp apush

	.globl	rf_code_zless
	.globl	_rf_code_zless
rf_code_zless:
_rf_code_zless:

	popl %eax
	orl %eax, %eax                # SET FLAGS
	movl $1, %eax                 # TRUE
	js zless1
	decl %eax                     # FLASE
zless1:
	jmp apush

	.globl	rf_code_plus
	.globl	_rf_code_plus
rf_code_plus:
_rf_code_plus:

	popl %eax
	popl %ebx
	addl %ebx, %eax
	jmp apush

	.globl	rf_code_dplus
	.globl	_rf_code_dplus
rf_code_dplus:
_rf_code_dplus:

	popl %eax                     # YHW
	popl %edx                     # YLW
	popl %ebx                     # XHW
	popl %ecx                     # XLW
	addl %ecx, %edx               # SLW
	adcl %ebx, %eax               # SHW
	jmp dpush

	.globl	rf_code_minus
	.globl	_rf_code_minus
rf_code_minus:
_rf_code_minus:

	popl %eax
	negl %eax
	jmp apush

	.globl	rf_code_dminu
	.globl	_rf_code_dminu
rf_code_dminu:
_rf_code_dminu:

	popl %ebx
	popl %ecx
	subl %eax, %eax               # ZERO
	movl %eax, %edx
	subl %ecx, %edx               # MAKE 2'S COMPLEMENT
	sbbl %ebx, %eax               # HIGH WORD
	jmp dpush

	.globl	rf_code_over
	.globl	_rf_code_over
rf_code_over:
_rf_code_over:

	popl %edx
	popl %eax
	pushl %eax
	jmp dpush

	.globl	rf_code_drop
	.globl	_rf_code_drop
rf_code_drop:
_rf_code_drop:

	popl %eax
	jmp next

	.globl	rf_code_swap
	.globl	_rf_code_swap
rf_code_swap:
_rf_code_swap:

	popl %edx
	popl %eax
	jmp dpush

	.globl	rf_code_dup
	.globl	_rf_code_dup
rf_code_dup:
_rf_code_dup:

	popl %eax
	pushl %eax
	jmp apush

	.globl	rf_code_pstor
	.globl	_rf_code_pstor
rf_code_pstor:
_rf_code_pstor:

	popl %ebx                     # ADDRESS
	popl %eax                     # INCREMENT
	addl %eax, (%ebx)
	jmp next

	.globl	rf_code_toggl
	.globl	_rf_code_toggl
rf_code_toggl:
_rf_code_toggl:

	popl %eax                     # BIT PATTERN
	popl %ebx                     # ADDR
	xorb %al, (%ebx)
	jmp next

	.globl	rf_code_at
	.globl	_rf_code_at
rf_code_at:
_rf_code_at:

	popl %ebx
	movl (%ebx), %eax
	jmp apush

	.globl	rf_code_cat
	.globl	_rf_code_cat
rf_code_cat:
_rf_code_cat:

	popl %ebx
	movb (%ebx), %al
	andl $0xFF, %eax
	jmp apush

	.globl	rf_code_store
	.globl	_rf_code_store
rf_code_store:
_rf_code_store:

	popl %ebx                     # ADDR
	popl %eax                     # DATA
	movl %eax, (%ebx)
	jmp next

	.globl	rf_code_cstor
	.globl	_rf_code_cstor
rf_code_cstor:
_rf_code_cstor:

	popl %ebx                     # ADDR
	popl %eax                     # DATA
	movb %al, (%ebx)
	jmp next

	.globl	rf_code_docol
	.globl	_rf_code_docol
rf_code_docol:
_rf_code_docol:

	addl $4, %edx                 # W=W+1
	subl $4, %ebp                 # (RP) <- (RP)-2
	movl %esi, (%ebp)             # R1 <- (RP)
	movl %edx, %esi               # (IP) <- (W)
	jmp next

	.globl	rf_code_docon
	.globl	_rf_code_docon
rf_code_docon:
_rf_code_docon:

	addl $4, %edx                 # PFA
	movl %edx, %ebx
	movl (%ebx), %eax             # GET DATA
	jmp apush

	.globl	rf_code_dovar
	.globl	_rf_code_dovar
rf_code_dovar:
_rf_code_dovar:

	addl $4, %edx                 # (DE) <- PFA
	pushl %edx                    # (S1) <- PFA
	jmp next

	.globl	rf_code_douse
	.globl	_rf_code_douse
rf_code_douse:
_rf_code_douse:

	addl $4, %edx                 # PFA
	movl %edx, %ebx
	movb (%ebx), %bl
	andl $0xFF, %ebx
	call __x86.get_pc_thunk.ax
	addl $_GLOBAL_OFFSET_TABLE_, %eax
	movl _rf_up@GOTOFF(%eax), %edi # USER VARIABLE ADDR
	leal (%ebx, %edi), %eax       # ADDR OF VARIABLE
	jmp apush

	.globl	rf_code_dodoe
	.globl	_rf_code_dodoe
rf_code_dodoe:
_rf_code_dodoe:

	xchgl %esp, %ebp              # GET RETURN STACK
	pushl %esi                    # (RP) <- (IP)
	xchgl %esp, %ebp
	addl $4, %edx                 # PFA
	movl %edx, %ebx
	movl (%ebx), %esi             # NEW CFA
	addl $4, %edx
	pushl %edx                    # PFA
	jmp next

	.globl	rf_code_stod
	.globl	_rf_code_stod
rf_code_stod:
_rf_code_stod:

	popl %edx                     # S1
	subl %eax, %eax               # AX = 0
	orl %edx, %edx                # SET FLAGS
	jns stod1                     # POSITIVE NUMBER
	decl %eax                     # NEGITIVE NUMBER
stod1:
	jmp dpush

	.globl	rf_code_cl
	.globl	_rf_code_cl
rf_code_cl:
_rf_code_cl:

	movl $4, %eax
	jmp apush

	.globl	rf_code_cs
	.globl	_rf_code_cs
rf_code_cs:
_rf_code_cs:

	popl %eax
	shll $2, %eax
	jmp apush

	.globl rf_code_xt
	.globl _rf_code_xt
rf_code_xt:
_rf_code_xt:

  pushl %ebp
  movl %esp, %ebp
	movl $0, %eax
	call __x86.get_pc_thunk.bx
	addl $_GLOBAL_OFFSET_TABLE_, %ebx
	movl %eax, _rf_fp@GOTOFF(%ebx)
	call _rf_start
	popl %ebp
	ret

	.section __DATA.__data,""

	.data
	.globl rf_i686_ebp_save
	.globl _rf_i686_ebp_save
	.p2align 2
_rf_i686_ebp_save:

	.long	0

	.data
	.globl rf_i686_esp_save
	.globl _rf_i686_esp_save
	.p2align 2
_rf_i686_esp_save:

	.long	0
