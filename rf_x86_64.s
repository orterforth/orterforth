# x86_64 implementation of fig-Forth machine and 

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

	# save rcx for later
	movq %rcx, %rdx

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
	subq %rdx, %rsp

	# this is the new stack frame
	movq %rsp, %rdi

	# copy old stack frame here
	# stack spills make this necessary as even if RF_START
	# is the first thing in C code, stack spills happen before
	# _rf_start is called. If a stack value is a reference 
	# to the address of another this will not work.
  rep movsb

	# rewind rf_start return address
	pushq %rax

  retq                          # carry on in C

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

.section	__DATA,__data

.globl _rf_x86_64_rbp_save
.p2align 3
_rf_x86_64_rbp_save:

	.quad	0

.globl _rf_x86_64_rsp_save
.p2align 3
_rf_x86_64_rsp_save:

	.quad	0
