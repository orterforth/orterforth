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
# segmentation).

	.text
	.globl _rf_trampoline
_rf_trampoline:

	pushl	%ebp                    # enter stack frame
	movl %esp, %ebp

	pushl %ebx                    # callee save ebx
	pushl %esi                    # callee save esi

	call __x86.get_pc_thunk.bx
	addl $_GLOBAL_OFFSET_TABLE_, %ebx

trampoline1:

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

	popl %esi
	popl %ebx
	leave                         # leave stack frame
	ret                           # bye

.globl	_rf_start
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

	.globl _rf_next
_rf_next:
next:

	lodsl                         # AX<- (IP)
	movl %eax, %edx               # (W) <- (IP)
	# movl %eax, %ebx
next1:
	#	movl %ebx, %edx
	jmp *(%edx)                   # TO 'CFA'

	.globl	_rf_code_lit
_rf_code_lit:

	lodsl                         # AX <- LITERAL
	jmp apush                     # TO TOP OF STACK

	.globl	_rf_code_exec
_rf_code_exec:

	popl %edx                     # GET CFA
	jmp next1                     # EXECUTE NEXT
	# jmp *(%edx)

	.globl	_rf_code_bran
_rf_code_bran:

bran1:
	addl (%esi), %esi             # (IP) <- (IP) + ((IP))
	jmp next                      # JUMP TO OFFSET

	.globl	_rf_code_zbran
_rf_code_zbran:

	popl %eax                     # GET STACK VALUE
	orl %eax, %eax                # ZERO?
	jz bran1                      # YES, BRANCH
	addl $4, %esi                 # NO, CONTINUE...
	jmp next

.section __DATA.__data,""

.data
.globl _rf_i686_ebp_save
.p2align 2
_rf_i686_ebp_save:

	.long	0

.data
.globl _rf_i686_esp_save
.p2align 2
_rf_i686_esp_save:

	.long	0
