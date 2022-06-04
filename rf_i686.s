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
	leal trampoline1@GOTOFF(%ebx), %ecx  # push the return address
	push %ecx

	# movq %rbp, _rf_x86_64_rbp_save(%rip) # save rsp and rbp
	# movq %rsp, _rf_x86_64_rsp_save(%rip)
  # movq _rf_rp(%rip), %rbp       # put SP and RP into rsp and rbp
  # movq _rf_sp(%rip), %rsp

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

	# old SP now in rsi
#	movq %rsp, %rsi

	# save rcx for later
#	movq %rcx, %rdx

	# empty the stack frame, i.e., make rsp = rbp
#	movq %rbp, %rsp

	# get the pushed rbp (this is RP)
#	popq %rbp
#  movq %rbp, _rf_rp(%rip)

	# now rsp is SP
#  movq %rsp, _rf_sp(%rip)

	# get the saved rsp and rbp from _rf_trampoline
	# (these are not the same as return addr has been pushed)
#	movq _rf_x86_64_rbp_save(%rip), %rbp
#	movq _rf_x86_64_rsp_save(%rip), %rsp

	# push rbp as it would have been
#	pushq %rbp

	# and mov rsp into rbp
#	movq %rsp, %rbp

	# sub the difference from rsp
#	subq %rdx, %rsp

	movl %esp, %edi               # this is the new stack frame

	# copy old stack frame here
	# stack spills make this necessary as even if RF_START
	# is the first thing in C code, stack spills happen before
	# _rf_start is called. If a stack value is a reference 
	# to the address of another this will not work.
#	cld
#  rep movsb

	pushl %edx                    # rewind rf_start return address

	ret                           # carry on in C

	.globl _rf_next
_rf_next:
next:

	lodsl                         # AX<- (IP)
	movl %eax, %edx               # (W) <- (IP)
# next1:
#	movl %ebx, %edx
	jmp *(%edx)                   # TO 'CFA'
