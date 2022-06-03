	.text
	.globl	_rf_trampoline
	.type	_rf_trampoline, @function
_rf_trampoline:
.LFB0:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	pushl	%ebx
	subl	$4, %esp
	.cfi_offset 3, -12
	call	__x86.get_pc_thunk.bx
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx
	jmp	.L2
.L3:
	movl	rf_fp@GOTOFF(%ebx), %eax
	call	*%eax
.L2:
	movl	rf_fp@GOTOFF(%ebx), %eax
	testl	%eax, %eax
	jne	.L3
	nop
	nop
	movl	-4(%ebp), %ebx
	leave
	.cfi_restore 5
	.cfi_restore 3
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE0:
	.size	_rf_trampoline, .-_rf_trampoline
	.globl	_rf_start
	.type	_rf_start, @function
_rf_start:
.LFB1:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	call	__x86.get_pc_thunk.ax
	addl	$_GLOBAL_OFFSET_TABLE_, %eax
	nop
	popl	%ebp
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE1:
	.size	_rf_start, .-_rf_start
