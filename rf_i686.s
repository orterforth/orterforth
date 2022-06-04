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
	.globl	_rf_trampoline
_rf_trampoline:

	pushl	%ebp
	movl %esp, %ebp
	pushl %ebx
	pushl %esi

	call __x86.get_pc_thunk.bx
	addl $_GLOBAL_OFFSET_TABLE_, %ebx

trampoline1:

	movl rf_fp@GOTOFF(%ebx), %eax
	testl %eax, %eax
	je trampoline2

  movl _rf_ip@GOTOFF(%ebx), %esi # IP to esi
  movl _rf_w@GOTOFF(%ebx), %edx  # W to edx

	movl rf_fp@GOTOFF(%ebx), %eax
	call *%eax
	jmp trampoline1

trampoline2:

	popl %esi
	popl %ebx
	leave
	ret

	.globl	_rf_start
_rf_start:

	call	__x86.get_pc_thunk.ax
	addl	$_GLOBAL_OFFSET_TABLE_, %eax

  movl %edx, _rf_w@GOTOFF(%eax)  # edx to W
  movl %esi, _rf_ip@GOTOFF(%eax) # esi to IP

	ret

	.globl _rf_next
_rf_next:
next:

	lodsl                         # AX<- (IP)
	movl %eax, %edx               # (W) <- (IP)
# next1:
#	movl %ebx, %edx
	jmp *(%edx)                   # TO 'CFA'
