	.file	"rf.c"
	.option nopic
	.attribute arch, "rv32i2p1_m2p0_a2p1_c2p0_zicsr2p0_zifencei2p0_zba1p0_zbb1p0_zbkb1p0_zbs1p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
.Ltext0:
	.cfi_sections	.debug_frame
	.file 0 "pico" "rf.c"

        .globl rf_sp
        .section .sbss,"aw",@nobits
        .align 2
        .type rf_sp, @object
        .size rf_sp, 4
rf_sp:  .zero 4

        .globl rf_rp
        .align 2
        .type rf_rp, @object
        .size rf_rp, 4
rf_rp:  .zero 4

        .globl rf_ip
        .align 2
        .type rf_ip, @object
        .size rf_ip, 4
rf_ip:  .zero 4

        .globl rf_w
        .align 2
        .type rf_w, @object
        .size rf_w, 4
rf_w:   .zero 4

        .globl rf_up
        .align 2
        .type rf_up, @object
        .size rf_up, 4
rf_up:  .zero 4

        .globl rf_fp
        .align 2
        .type rf_fp, @object
        .size rf_fp, 4
rf_fp:  .zero 4

        .text
        .align 1
        .globl rf_trampoline
        .type rf_trampoline, @function
rf_trampoline:
.LFB0:
	.file 1 "rf.c"
	.loc 1 66 1
	.cfi_startproc
	addi	sp,sp,-16
	.cfi_def_cfa_offset 16
	sw	ra,12(sp)
	sw	s0,8(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,16
	.cfi_def_cfa 8, 0
	.loc 1 67 9
	j	.L2

.L3:

        lui     a5,%hi(rf_ip)   # IP into S11
        lw      s11,%lo(rf_ip)(a5)
        lui     a5,%hi(rf_sp)   # SP into S10
        lw      s10,%lo(rf_sp)(a5)
        lui     a5,%hi(rf_w)    # W into S8
        lw      s8,%lo(rf_w)(a5)

	.loc 1 73 5
	lui	a5,%hi(rf_fp)
	lw	a5,%lo(rf_fp)(a5)
	jalr	a5
.LVL0:
.L2:
	.loc 1 67 10
	lui	a5,%hi(rf_fp)
	lw	a5,%lo(rf_fp)(a5)
	bne	a5,zero,.L3

	.loc 1 75 1
	nop
	nop
	lw	ra,12(sp)
	.cfi_restore 1
	lw	s0,8(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 16
	addi	sp,sp,16
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE0:
	.size	rf_trampoline, .-rf_trampoline

        .align 1
        .globl rf_start
        .type rf_start, @function
rf_start:
.LFB1:
        .loc 1 79 1
        .cfi_startproc
#       addi    sp, sp, -16
        .cfi_def_cfa_offset 16
#       sw      ra, 12(sp)
#       sw      s0, 8(sp)
        .cfi_offset 1, -4
        .cfi_offset 8, -8
#       addi    s0, sp, 16
        .cfi_def_cfa 8, 0
        .loc 1 84 1
#       nop

        lui     a5,%hi(rf_ip)   # S11 into IP
        sw      s11,%lo(rf_ip)(a5)
        lui     a5,%hi(rf_sp)   # S10 into SP
        sw      s10,%lo(rf_sp)(a5)
        lui     a5,%hi(rf_w)    # S8 into W
        sw      s8,%lo(rf_w)(a5)

#       lw      ra, 12(sp)
        .cfi_restore 1
#       lw      s0, 8(sp)
        .cfi_restore 8
        .cfi_def_cfa 2, 16
#       addi    sp, sp, 16
        .cfi_def_cfa_offset 0
        jr      ra
        .cfi_endproc
.LFE1:
        .size rf_start, .-rf_start

#
# *********************************************
# ******   DICTIONARY WORDS START HERE   ******
# *********************************************
#
#
# ***********
# *   LIT   *
# ***********
#
        .align 1
        .globl rf_code_lit
        .type rf_code_lit, @function
rf_code_lit:
.LFB2:

	.loc 1 91 1
	.cfi_startproc

        lw      a5,(s11)        # AX <- LITERAL
        addi    s11,s11,4
        j       APUSH           # TO TOP OF STACK



# 	addi	sp,sp,-32
# 	.cfi_def_cfa_offset 32
# 	sw	ra,28(sp)
# 	sw	s0,24(sp)
# 	.cfi_offset 1, -4
# 	.cfi_offset 8, -8
# 	addi	s0,sp,32
# 	.cfi_def_cfa 8, 0
# 	.loc 1 92 3
# 	call	rf_start
 .LBB2:
# 	.loc 1 94 19
# 	lui	a5,%hi(rf_ip)
# 	lw	a5,%lo(rf_ip)(a5)
# 	.loc 1 94 15
# 	lw	a5,0(a5)
# 	sw	a5,-20(s0)
# 	.loc 1 95 5
# 	lui	a5,%hi(rf_sp)
# 	lw	a5,%lo(rf_sp)(a5)
# 	addi	a4,a5,-4
# 	lui	a5,%hi(rf_sp)
# 	sw	a4,%lo(rf_sp)(a5)
# 	lui	a5,%hi(rf_sp)
# 	lw	a5,%lo(rf_sp)(a5)
# 	lw	a4,-20(s0)
# 	sw	a4,0(a5)
# 	.loc 1 96 10
# 	lui	a5,%hi(rf_ip)
# 	lw	a5,%lo(rf_ip)(a5)
# 	addi	a4,a5,4
# 	lui	a5,%hi(rf_ip)
# 	sw	a4,%lo(rf_ip)(a5)
 .LBE2:
# 	.loc 1 98 3
# 	lui	a5,%hi(rf_fp)
# 	lui	a4,%hi(rf_next)
# 	addi	a4,a4,%lo(rf_next)
# 	sw	a4,%lo(rf_fp)(a5)
# 	.loc 1 99 1
# 	nop
# 	lw	ra,28(sp)
# 	.cfi_restore 1
# 	lw	s0,24(sp)
# 	.cfi_restore 8
# 	.cfi_def_cfa 2, 32
# 	addi	sp,sp,32
# 	.cfi_def_cfa_offset 0
# 	jr	ra
 	.cfi_endproc

.LFE2:
        .size rf_code_lit, .-rf_code_lit

        .align 1
APUSH:  addi    s10,s10,-4
        sw      a5,(s10)
#
# -----------------------------------------
#
# PATCH THE NEXT 3 LOCATIONS
# (USING A DEBUG MONITOR; I.E. DDT86)
# WITH  (JMP TNEXT)  FOR TRACING THROUGH
# HIGH LEVEL FORTH WORDS.
#
        .align 1
        .globl rf_next
        .type rf_next, @function
rf_next:
.LFB3:
NEXT:   lw      s8,(s11)        # AX<- (IP)
                                # (W) <- (IP)
        addi    s11,s11,4
#
# -----------------------------------------
#
NEXT1:  lw      a5,(s8)         # TO 'CFA'
        jr      a5

# 	.loc 1 104 1
# 	.cfi_startproc
# 	addi	sp,sp,-16
# 	.cfi_def_cfa_offset 16
# 	sw	ra,12(sp)
# 	sw	s0,8(sp)
# 	.cfi_offset 1, -4
# 	.cfi_offset 8, -8
# 	addi	s0,sp,16

# 	.cfi_def_cfa 8, 0
# 	.loc 1 105 3
# 	call	rf_start

# 	.loc 1 106 24
# 	lui	a5,%hi(rf_ip)
# 	lw	a5,%lo(rf_ip)(a5)
# 	lw	a5,0(a5)
# 	.loc 1 106 10
# 	mv	a4,a5
# 	.loc 1 106 8
# 	lui	a5,%hi(rf_w)
# 	sw	a4,%lo(rf_w)(a5)
# 	.loc 1 107 8
# 	lui	a5,%hi(rf_ip)
# 	lw	a5,%lo(rf_ip)(a5)
# 	addi	a4,a5,4
# 	lui	a5,%hi(rf_ip)
# 	sw	a4,%lo(rf_ip)(a5)
# 	.loc 1 108 3
# 	lui	a5,%hi(rf_w)
# 	lw	a5,%lo(rf_w)(a5)
# 	lw	a4,0(a5)
# 	lui	a5,%hi(rf_fp)
# 	sw	a4,%lo(rf_fp)(a5)

# 	.loc 1 109 1
# 	nop
# 	lw	ra,12(sp)
# 	.cfi_restore 1
# 	lw	s0,8(sp)
# 	.cfi_restore 8
# 	.cfi_def_cfa 2, 16
# 	addi	sp,sp,16
# 	.cfi_def_cfa_offset 0
# 	jr	ra
# 	.cfi_endproc
.LFE3:
        .size rf_next, .-rf_next


# ***************
# *   EXECUTE   *
# ***************
#
        .align 1
        .globl  rf_code_exec
        .type rf_code_exec, @function
rf_code_exec:
.LFB4:
	.loc 1 114 1
	.cfi_startproc

        lw      s8,(s10)        # GET CFA
        addi    s10,s10,4
        j       NEXT1           # EXECUTE NEXT

	# addi	sp,sp,-16
	# .cfi_def_cfa_offset 16
	# sw	ra,12(sp)
	# sw	s0,8(sp)
	# .cfi_offset 1, -4
	# .cfi_offset 8, -8
	# addi	s0,sp,16
	# .cfi_def_cfa 8, 0
	# .loc 1 115 3
	# call	rf_start
	# .loc 1 116 24
	# lui	a5,%hi(rf_sp)
	# lw	a5,%lo(rf_sp)(a5)
	# addi	a3,a5,4
	# lui	a4,%hi(rf_sp)
	# sw	a3,%lo(rf_sp)(a4)
	# lw	a5,0(a5)
	# .loc 1 116 10
	# mv	a4,a5
	# .loc 1 116 8
	# lui	a5,%hi(rf_w)
	# sw	a4,%lo(rf_w)(a5)
	# .loc 1 117 3
	# lui	a5,%hi(rf_w)
	# lw	a5,%lo(rf_w)(a5)
	# lw	a4,0(a5)
	# lui	a5,%hi(rf_fp)
	# sw	a4,%lo(rf_fp)(a5)
	# .loc 1 118 1
	# nop
	# lw	ra,12(sp)
	# .cfi_restore 1
	# lw	s0,8(sp)
	# .cfi_restore 8
	# .cfi_def_cfa 2, 16
	# addi	sp,sp,16
	# .cfi_def_cfa_offset 0
	# jr	ra
	.cfi_endproc
.LFE4:
        .size rf_code_exec, .-rf_code_exec


# **************
# *   BRANCH   *
# **************
#
        .align 1
        .globl rf_code_bran
        .type rf_code_bran, @function
rf_code_bran:
.LFB5:
BRAN1:  lw      a5,(s11)
        add     s11,s11,a5      # (IP) <- (IP) + ((IP))
        j       NEXT            # JUMP TO OFFSET


	# .loc 1 129 1
	# .cfi_startproc
	# addi	sp,sp,-16
	# .cfi_def_cfa_offset 16
	# sw	ra,12(sp)
	# sw	s0,8(sp)
	# .cfi_offset 1, -4
	# .cfi_offset 8, -8
	# addi	s0,sp,16
	# .cfi_def_cfa 8, 0
	# .loc 1 130 3
	# call	rf_start
	# .loc 1 131 3
	# call	rf_branch
	# .loc 1 132 3
	# lui	a5,%hi(rf_fp)
	# lui	a4,%hi(rf_next)
	# addi	a4,a4,%lo(rf_next)
	# sw	a4,%lo(rf_fp)(a5)
	# .loc 1 133 1
	# nop
	# lw	ra,12(sp)
	# .cfi_restore 1
	# lw	s0,8(sp)
	# .cfi_restore 8
	# .cfi_def_cfa 2, 16
	# addi	sp,sp,16
	# .cfi_def_cfa_offset 0
	# jr	ra
	# .cfi_endproc
.LFE5:
	.size	rf_code_bran, .-rf_code_bran


# ***************
# *   0BRANCH   *
# ***************
#
        .align 1
        .globl rf_code_zbran
        .type rf_code_zbran, @function
rf_code_zbran:
.LFB6:
        lw      a5,(s10)        # GET STACK VALUE
        addi    s10,s10,4
        beqz    a5,BRAN1        # ZERO?
                                # YES, BRANCH
        addi    s11,s11,4       # NO, CONTINUE...
        j       NEXT

# 	.loc 1 141 1
# 	.cfi_startproc
# 	addi	sp,sp,-16
# 	.cfi_def_cfa_offset 16
# 	sw	ra,12(sp)
# 	sw	s0,8(sp)
# 	.cfi_offset 1, -4
# 	.cfi_offset 8, -8
# 	addi	s0,sp,16
# 	.cfi_def_cfa 8, 0
# 	.loc 1 142 3
# 	call	rf_start
# 	.loc 1 143 7
# 	lui	a5,%hi(rf_sp)
# 	lw	a5,%lo(rf_sp)(a5)
# 	addi	a3,a5,4
# 	lui	a4,%hi(rf_sp)
# 	sw	a3,%lo(rf_sp)(a4)
# 	lw	a5,0(a5)
# 	.loc 1 143 6
# 	beq	a5,zero,.L10
# 	.loc 1 144 10
# 	lui	a5,%hi(rf_ip)
# 	lw	a5,%lo(rf_ip)(a5)
# 	addi	a4,a5,4
# 	lui	a5,%hi(rf_ip)
# 	sw	a4,%lo(rf_ip)(a5)
# 	j	.L11
# .L10:
# 	.loc 1 146 5
# 	call	rf_branch
# .L11:
# 	.loc 1 148 3
# 	lui	a5,%hi(rf_fp)
# 	lui	a4,%hi(rf_next)
# 	addi	a4,a4,%lo(rf_next)
# 	sw	a4,%lo(rf_fp)(a5)
# 	.loc 1 149 1
# 	nop
# 	lw	ra,12(sp)
# 	.cfi_restore 1
# 	lw	s0,8(sp)
# 	.cfi_restore 8
# 	.cfi_def_cfa 2, 16
# 	addi	sp,sp,16
# 	.cfi_def_cfa_offset 0
# 	jr	ra
# 	.cfi_endproc
.LFE6:
	.size	rf_code_zbran, .-rf_code_zbran

	.align	1
	.globl	rf_code_xloop
	.type	rf_code_xloop, @function
rf_code_xloop:
.LFB7:
	.loc 1 157 1
	.cfi_startproc
	addi	sp,sp,-32
	.cfi_def_cfa_offset 32
	sw	ra,28(sp)
	sw	s0,24(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,32
	.cfi_def_cfa 8, 0
	.loc 1 158 3
	call	rf_start
.LBB3:
	.loc 1 160 33
	lui	a5,%hi(rf_rp)
	lw	a5,%lo(rf_rp)(a5)
	addi	a3,a5,4
	lui	a4,%hi(rf_rp)
	sw	a3,%lo(rf_rp)(a4)
	lw	a5,0(a5)
	.loc 1 160 14
	sw	a5,-20(s0)
	.loc 1 161 33
	lui	a5,%hi(rf_rp)
	lw	a5,%lo(rf_rp)(a5)
	addi	a3,a5,4
	lui	a4,%hi(rf_rp)
	sw	a3,%lo(rf_rp)(a4)
	lw	a5,0(a5)
	.loc 1 161 14
	sw	a5,-24(s0)
	.loc 1 162 5
	lw	a5,-20(s0)
	addi	a5,a5,1
	sw	a5,-20(s0)
	.loc 1 163 8
	lw	a4,-24(s0)
	lw	a5,-20(s0)
	ble	a4,a5,.L13
	.loc 1 164 7
	lui	a5,%hi(rf_rp)
	lw	a5,%lo(rf_rp)(a5)
	addi	a4,a5,-4
	lui	a5,%hi(rf_rp)
	sw	a4,%lo(rf_rp)(a5)
	lui	a5,%hi(rf_rp)
	lw	a5,%lo(rf_rp)(a5)
	lw	a4,-24(s0)
	sw	a4,0(a5)
	.loc 1 165 7
	lui	a5,%hi(rf_rp)
	lw	a5,%lo(rf_rp)(a5)
	addi	a4,a5,-4
	lui	a5,%hi(rf_rp)
	sw	a4,%lo(rf_rp)(a5)
	lui	a5,%hi(rf_rp)
	lw	a5,%lo(rf_rp)(a5)
	lw	a4,-20(s0)
	sw	a4,0(a5)
	.loc 1 166 7
	call	rf_branch
	j	.L14
.L13:
	.loc 1 168 12
	lui	a5,%hi(rf_ip)
	lw	a5,%lo(rf_ip)(a5)
	addi	a4,a5,4
	lui	a5,%hi(rf_ip)
	sw	a4,%lo(rf_ip)(a5)
.L14:
.LBE3:
	.loc 1 171 3
	lui	a5,%hi(rf_fp)
	lui	a4,%hi(rf_next)
	addi	a4,a4,%lo(rf_next)
	sw	a4,%lo(rf_fp)(a5)
	.loc 1 172 1
	nop
	lw	ra,28(sp)
	.cfi_restore 1
	lw	s0,24(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 32
	addi	sp,sp,32
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE7:
	.size	rf_code_xloop, .-rf_code_xloop
	.align	1
	.globl	rf_code_xploo
	.type	rf_code_xploo, @function
rf_code_xploo:
.LFB8:
	.loc 1 180 1
	.cfi_startproc
	addi	sp,sp,-32
	.cfi_def_cfa_offset 32
	sw	ra,28(sp)
	sw	s0,24(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,32
	.cfi_def_cfa 8, 0
	.loc 1 181 3
	call	rf_start
.LBB4:
	.loc 1 183 29
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a3,a5,4
	lui	a4,%hi(rf_sp)
	sw	a3,%lo(rf_sp)(a4)
	lw	a5,0(a5)
	.loc 1 183 14
	sw	a5,-20(s0)
	.loc 1 184 33
	lui	a5,%hi(rf_rp)
	lw	a5,%lo(rf_rp)(a5)
	addi	a3,a5,4
	lui	a4,%hi(rf_rp)
	sw	a3,%lo(rf_rp)(a4)
	lw	a5,0(a5)
	.loc 1 184 14
	sw	a5,-24(s0)
	.loc 1 185 33
	lui	a5,%hi(rf_rp)
	lw	a5,%lo(rf_rp)(a5)
	addi	a3,a5,4
	lui	a4,%hi(rf_rp)
	sw	a3,%lo(rf_rp)(a4)
	lw	a5,0(a5)
	.loc 1 185 14
	sw	a5,-28(s0)
	.loc 1 187 11
	lw	a4,-24(s0)
	lw	a5,-20(s0)
	add	a5,a4,a5
	sw	a5,-24(s0)
	.loc 1 189 8
	lw	a5,-20(s0)
	ble	a5,zero,.L16
	.loc 1 189 18 discriminator 1
	lw	a4,-24(s0)
	lw	a5,-28(s0)
	blt	a4,a5,.L17
.L16:
	.loc 1 189 38 discriminator 3
	lw	a5,-20(s0)
	bge	a5,zero,.L18
	.loc 1 189 50 discriminator 4
	lw	a4,-24(s0)
	lw	a5,-28(s0)
	ble	a4,a5,.L18
.L17:
	.loc 1 190 7
	lui	a5,%hi(rf_rp)
	lw	a5,%lo(rf_rp)(a5)
	addi	a4,a5,-4
	lui	a5,%hi(rf_rp)
	sw	a4,%lo(rf_rp)(a5)
	lui	a5,%hi(rf_rp)
	lw	a5,%lo(rf_rp)(a5)
	lw	a4,-28(s0)
	sw	a4,0(a5)
	.loc 1 191 7
	lui	a5,%hi(rf_rp)
	lw	a5,%lo(rf_rp)(a5)
	addi	a4,a5,-4
	lui	a5,%hi(rf_rp)
	sw	a4,%lo(rf_rp)(a5)
	lui	a5,%hi(rf_rp)
	lw	a5,%lo(rf_rp)(a5)
	lw	a4,-24(s0)
	sw	a4,0(a5)
	.loc 1 192 7
	call	rf_branch
	j	.L19
.L18:
	.loc 1 194 12
	lui	a5,%hi(rf_ip)
	lw	a5,%lo(rf_ip)(a5)
	addi	a4,a5,4
	lui	a5,%hi(rf_ip)
	sw	a4,%lo(rf_ip)(a5)
.L19:
.LBE4:
	.loc 1 197 3
	lui	a5,%hi(rf_fp)
	lui	a4,%hi(rf_next)
	addi	a4,a4,%lo(rf_next)
	sw	a4,%lo(rf_fp)(a5)
	.loc 1 198 1
	nop
	lw	ra,28(sp)
	.cfi_restore 1
	lw	s0,24(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 32
	addi	sp,sp,32
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE8:
	.size	rf_code_xploo, .-rf_code_xploo
	.align	1
	.type	rf_branch, @function
rf_branch:
.LFB9:
	.loc 1 203 1
	.cfi_startproc
	addi	sp,sp,-32
	.cfi_def_cfa_offset 32
	sw	ra,28(sp)
	sw	s0,24(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,32
	.cfi_def_cfa 8, 0
	.loc 1 204 22
	lui	a5,%hi(rf_ip)
	lw	a5,%lo(rf_ip)(a5)
	.loc 1 204 13
	lw	a5,0(a5)
	sw	a5,-20(s0)
	.loc 1 205 11
	lui	a5,%hi(rf_ip)
	lw	a4,%lo(rf_ip)(a5)
	lw	a5,-20(s0)
	add	a4,a4,a5
	.loc 1 205 9
	lui	a5,%hi(rf_ip)
	sw	a4,%lo(rf_ip)(a5)
	.loc 1 206 1
	nop
	lw	ra,28(sp)
	.cfi_restore 1
	lw	s0,24(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 32
	addi	sp,sp,32
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE9:
	.size	rf_branch, .-rf_branch
	.align	1
	.globl	rf_code_xdo
	.type	rf_code_xdo, @function
rf_code_xdo:
.LFB10:
	.loc 1 211 1
	.cfi_startproc
	addi	sp,sp,-32
	.cfi_def_cfa_offset 32
	sw	ra,28(sp)
	sw	s0,24(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,32
	.cfi_def_cfa 8, 0
	.loc 1 212 3
	call	rf_start
.LBB5:
	.loc 1 214 20
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a3,a5,4
	lui	a4,%hi(rf_sp)
	sw	a3,%lo(rf_sp)(a4)
	.loc 1 214 15
	lw	a5,0(a5)
	sw	a5,-20(s0)
	.loc 1 215 20
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a3,a5,4
	lui	a4,%hi(rf_sp)
	sw	a3,%lo(rf_sp)(a4)
	.loc 1 215 15
	lw	a5,0(a5)
	sw	a5,-24(s0)
	.loc 1 216 5
	lui	a5,%hi(rf_rp)
	lw	a5,%lo(rf_rp)(a5)
	addi	a4,a5,-4
	lui	a5,%hi(rf_rp)
	sw	a4,%lo(rf_rp)(a5)
	lui	a5,%hi(rf_rp)
	lw	a5,%lo(rf_rp)(a5)
	lw	a4,-24(s0)
	sw	a4,0(a5)
	.loc 1 217 5
	lui	a5,%hi(rf_rp)
	lw	a5,%lo(rf_rp)(a5)
	addi	a4,a5,-4
	lui	a5,%hi(rf_rp)
	sw	a4,%lo(rf_rp)(a5)
	lui	a5,%hi(rf_rp)
	lw	a5,%lo(rf_rp)(a5)
	lw	a4,-20(s0)
	sw	a4,0(a5)
.LBE5:
	.loc 1 219 3
	lui	a5,%hi(rf_fp)
	lui	a4,%hi(rf_next)
	addi	a4,a4,%lo(rf_next)
	sw	a4,%lo(rf_fp)(a5)
	.loc 1 220 1
	nop
	lw	ra,28(sp)
	.cfi_restore 1
	lw	s0,24(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 32
	addi	sp,sp,32
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE10:
	.size	rf_code_xdo, .-rf_code_xdo
	.align	1
	.globl	rf_code_dodoe
	.type	rf_code_dodoe, @function
rf_code_dodoe:
.LFB11:
	.loc 1 225 1
	.cfi_startproc
	addi	sp,sp,-32
	.cfi_def_cfa_offset 32
	sw	ra,28(sp)
	sw	s0,24(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,32
	.cfi_def_cfa 8, 0
	.loc 1 226 3
	call	rf_start
.LBB6:
	.loc 1 234 5
	lui	a5,%hi(rf_ip)
	lw	a3,%lo(rf_ip)(a5)
	lui	a5,%hi(rf_rp)
	lw	a5,%lo(rf_rp)(a5)
	addi	a4,a5,-4
	lui	a5,%hi(rf_rp)
	sw	a4,%lo(rf_rp)(a5)
	lui	a5,%hi(rf_rp)
	lw	a5,%lo(rf_rp)(a5)
	mv	a4,a3
	sw	a4,0(a5)
	.loc 1 237 10
	lui	a5,%hi(rf_w)
	lw	a5,%lo(rf_w)(a5)
	.loc 1 237 8
	addi	a5,a5,4
	sw	a5,-20(s0)
	.loc 1 238 28
	lw	a5,-20(s0)
	lw	a5,0(a5)
	.loc 1 238 13
	mv	a4,a5
	.loc 1 238 11
	lui	a5,%hi(rf_ip)
	sw	a4,%lo(rf_ip)(a5)
	.loc 1 241 10
	lui	a5,%hi(rf_w)
	lw	a5,%lo(rf_w)(a5)
	.loc 1 241 8
	addi	a5,a5,8
	sw	a5,-24(s0)
	.loc 1 242 5
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a4,a5,-4
	lui	a5,%hi(rf_sp)
	sw	a4,%lo(rf_sp)(a5)
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	lw	a4,-24(s0)
	sw	a4,0(a5)
.LBE6:
	.loc 1 244 3
	lui	a5,%hi(rf_fp)
	lui	a4,%hi(rf_next)
	addi	a4,a4,%lo(rf_next)
	sw	a4,%lo(rf_fp)(a5)
	.loc 1 245 1
	nop
	lw	ra,28(sp)
	.cfi_restore 1
	lw	s0,24(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 32
	addi	sp,sp,32
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE11:
	.size	rf_code_dodoe, .-rf_code_dodoe
	.align	1
	.globl	rf_code_rr
	.type	rf_code_rr, @function
rf_code_rr:
.LFB12:
	.loc 1 250 1
	.cfi_startproc
	addi	sp,sp,-32
	.cfi_def_cfa_offset 32
	sw	ra,28(sp)
	sw	s0,24(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,32
	.cfi_def_cfa 8, 0
	.loc 1 251 3
	call	rf_start
.LBB7:
	.loc 1 253 19
	lui	a5,%hi(rf_rp)
	lw	a5,%lo(rf_rp)(a5)
	.loc 1 253 15
	lw	a5,0(a5)
	sw	a5,-20(s0)
	.loc 1 254 5
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a4,a5,-4
	lui	a5,%hi(rf_sp)
	sw	a4,%lo(rf_sp)(a5)
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	lw	a4,-20(s0)
	sw	a4,0(a5)
.LBE7:
	.loc 1 256 3
	lui	a5,%hi(rf_fp)
	lui	a4,%hi(rf_next)
	addi	a4,a4,%lo(rf_next)
	sw	a4,%lo(rf_fp)(a5)
	.loc 1 257 1
	nop
	lw	ra,28(sp)
	.cfi_restore 1
	lw	s0,24(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 32
	addi	sp,sp,32
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE12:
	.size	rf_code_rr, .-rf_code_rr
	.align	1
	.type	rf_digit, @function
rf_digit:
.LFB13:
	.loc 1 262 1
	.cfi_startproc
	addi	sp,sp,-32
	.cfi_def_cfa_offset 32
	sw	ra,28(sp)
	sw	s0,24(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,32
	.cfi_def_cfa 8, 0
	mv	a5,a0
	mv	a4,a1
	sb	a5,-17(s0)
	mv	a5,a4
	sb	a5,-18(s0)
	.loc 1 263 5
	lbu	a5,-18(s0)
	addi	a5,a5,-48
	sb	a5,-18(s0)
	.loc 1 264 6
	lbu	a4,-18(s0)
	li	a5,9
	bleu	a4,a5,.L25
	.loc 1 265 8
	lbu	a4,-18(s0)
	li	a5,16
	bgtu	a4,a5,.L26
	.loc 1 266 14
	li	a5,255
	j	.L27
.L26:
	.loc 1 268 7
	lbu	a5,-18(s0)
	addi	a5,a5,-7
	sb	a5,-18(s0)
.L25:
	.loc 1 270 6
	lbu	a4,-18(s0)
	lbu	a5,-17(s0)
	bgeu	a4,a5,.L28
	.loc 1 271 12
	lbu	a5,-18(s0)
	j	.L27
.L28:
	.loc 1 274 10
	li	a5,255
.L27:
	.loc 1 275 1
	mv	a0,a5
	lw	ra,28(sp)
	.cfi_restore 1
	lw	s0,24(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 32
	addi	sp,sp,32
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE13:
	.size	rf_digit, .-rf_digit
	.align	1
	.globl	rf_code_digit
	.type	rf_code_digit, @function
rf_code_digit:
.LFB14:
	.loc 1 278 1
	.cfi_startproc
	addi	sp,sp,-32
	.cfi_def_cfa_offset 32
	sw	ra,28(sp)
	sw	s0,24(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,32
	.cfi_def_cfa 8, 0
	.loc 1 279 3
	call	rf_start
.LBB8:
	.loc 1 283 19
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a3,a5,4
	lui	a4,%hi(rf_sp)
	sw	a3,%lo(rf_sp)(a4)
	lw	a5,0(a5)
	.loc 1 283 7
	sb	a5,-17(s0)
	.loc 1 284 19
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a3,a5,4
	lui	a4,%hi(rf_sp)
	sw	a3,%lo(rf_sp)(a4)
	lw	a5,0(a5)
	.loc 1 284 7
	sb	a5,-18(s0)
	.loc 1 285 9
	lbu	a4,-18(s0)
	lbu	a5,-17(s0)
	mv	a1,a4
	mv	a0,a5
	call	rf_digit
	mv	a5,a0
	sb	a5,-19(s0)
	.loc 1 286 8
	lbu	a4,-19(s0)
	li	a5,255
	bne	a4,a5,.L30
	.loc 1 287 7
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a4,a5,-4
	lui	a5,%hi(rf_sp)
	sw	a4,%lo(rf_sp)(a5)
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	sw	zero,0(a5)
	j	.L31
.L30:
	.loc 1 289 7
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a4,a5,-4
	lui	a5,%hi(rf_sp)
	sw	a4,%lo(rf_sp)(a5)
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	lbu	a4,-19(s0)
	sw	a4,0(a5)
	.loc 1 290 7
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a4,a5,-4
	lui	a5,%hi(rf_sp)
	sw	a4,%lo(rf_sp)(a5)
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	li	a4,1
	sw	a4,0(a5)
.L31:
.LBE8:
	.loc 1 293 3
	lui	a5,%hi(rf_fp)
	lui	a4,%hi(rf_next)
	addi	a4,a4,%lo(rf_next)
	sw	a4,%lo(rf_fp)(a5)
	.loc 1 294 1
	nop
	lw	ra,28(sp)
	.cfi_restore 1
	lw	s0,24(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 32
	addi	sp,sp,32
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE14:
	.size	rf_code_digit, .-rf_code_digit
	.align	1
	.type	rf_lfa, @function
rf_lfa:
.LFB15:
	.loc 1 299 1
	.cfi_startproc
	addi	sp,sp,-32
	.cfi_def_cfa_offset 32
	sw	ra,28(sp)
	sw	s0,24(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,32
	.cfi_def_cfa 8, 0
	sw	a0,-20(s0)
	.loc 1 300 9
	nop
.L33:
	.loc 1 300 10 discriminator 1
	lw	a5,-20(s0)
	addi	a5,a5,1
	sw	a5,-20(s0)
	.loc 1 300 12 discriminator 1
	lw	a5,-20(s0)
	lbu	a5,0(a5)
	.loc 1 300 10 discriminator 1
	sext.b	a5,a5
	bge	a5,zero,.L33
	.loc 1 302 10
	lw	a5,-20(s0)
	addi	a5,a5,1
	sw	a5,-20(s0)
	lw	a5,-20(s0)
	.loc 1 303 1
	mv	a0,a5
	lw	ra,28(sp)
	.cfi_restore 1
	lw	s0,24(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 32
	addi	sp,sp,32
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE15:
	.size	rf_lfa, .-rf_lfa
	.align	1
	.type	rf_find, @function
rf_find:
.LFB16:
	.loc 1 306 1
	.cfi_startproc
	addi	sp,sp,-48
	.cfi_def_cfa_offset 48
	sw	ra,44(sp)
	sw	s0,40(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,48
	.cfi_def_cfa 8, 0
	sw	a0,-36(s0)
	mv	a5,a1
	sw	a2,-44(s0)
	sb	a5,-37(s0)
	.loc 1 310 9
	j	.L36
.L41:
	.loc 1 312 16
	lbu	a4,-37(s0)
	.loc 1 312 20
	lw	a5,-44(s0)
	lbu	a5,0(a5)
	.loc 1 312 25
	andi	a5,a5,63
	.loc 1 312 8
	bne	a4,a5,.L37
	.loc 1 314 9
	lw	a5,-44(s0)
	sw	a5,-24(s0)
	.loc 1 315 9
	lw	a5,-36(s0)
	sw	a5,-20(s0)
	.loc 1 316 13
	j	.L38
.L40:
	.loc 1 317 13
	lb	a5,-25(s0)
	.loc 1 317 12
	bge	a5,zero,.L38
	.loc 1 317 30 discriminator 1
	lw	a5,-44(s0)
	.loc 1 317 30 is_stmt 0
	j	.L39
.L38:
	.loc 1 316 17 is_stmt 1
	lw	a5,-20(s0)
	addi	a4,a5,1
	sw	a4,-20(s0)
	.loc 1 316 14
	lbu	a5,0(a5)
	mv	a4,a5
	.loc 1 316 21
	lw	a5,-24(s0)
	addi	a5,a5,1
	sw	a5,-24(s0)
	.loc 1 316 28
	lw	a5,-24(s0)
	lbu	a5,0(a5)
	sb	a5,-25(s0)
	.loc 1 316 38
	lbu	a5,-25(s0)
	andi	a5,a5,127
	.loc 1 316 21
	beq	a4,a5,.L40
.L37:
	.loc 1 321 13
	lw	a0,-44(s0)
	call	rf_lfa
	mv	a5,a0
	.loc 1 321 9 discriminator 1
	lw	a5,0(a5)
	sw	a5,-44(s0)
.L36:
	.loc 1 310 10
	lw	a5,-44(s0)
	bne	a5,zero,.L41
	.loc 1 325 10
	li	a5,0
.L39:
	.loc 1 326 1
	mv	a0,a5
	lw	ra,44(sp)
	.cfi_restore 1
	lw	s0,40(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 48
	addi	sp,sp,48
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE16:
	.size	rf_find, .-rf_find
	.align	1
	.type	rf_pfa, @function
rf_pfa:
.LFB17:
	.loc 1 329 1
	.cfi_startproc
	addi	sp,sp,-48
	.cfi_def_cfa_offset 48
	sw	ra,44(sp)
	sw	s0,40(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,48
	.cfi_def_cfa 8, 0
	sw	a0,-36(s0)
	.loc 1 330 19
	lw	a0,-36(s0)
	call	rf_lfa
	sw	a0,-20(s0)
	.loc 1 331 14
	lw	a5,-20(s0)
	addi	a5,a5,8
	sw	a5,-24(s0)
	.loc 1 332 10
	lw	a5,-24(s0)
	.loc 1 333 1
	mv	a0,a5
	lw	ra,44(sp)
	.cfi_restore 1
	lw	s0,40(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 48
	addi	sp,sp,48
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE17:
	.size	rf_pfa, .-rf_pfa
	.align	1
	.type	rf_pfind, @function
rf_pfind:
.LFB18:
	.loc 1 336 1
	.cfi_startproc
	addi	sp,sp,-48
	.cfi_def_cfa_offset 48
	sw	ra,44(sp)
	sw	s0,40(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,48
	.cfi_def_cfa 8, 0
	sw	a0,-36(s0)
	sw	a1,-40(s0)
	.loc 1 340 10
	lw	a5,-36(s0)
	lbu	a5,0(a5)
	sb	a5,-17(s0)
	.loc 1 341 7
	lw	a5,-36(s0)
	addi	a5,a5,1
	lbu	a4,-17(s0)
	lw	a2,-40(s0)
	mv	a1,a4
	mv	a0,a5
	call	rf_find
	sw	a0,-24(s0)
	.loc 1 342 6
	lw	a5,-24(s0)
	beq	a5,zero,.L45
	.loc 1 343 5
	lw	a0,-24(s0)
	call	rf_pfa
	mv	a3,a0
	.loc 1 343 5 is_stmt 0 discriminator 1
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a4,a5,-4
	lui	a5,%hi(rf_sp)
	sw	a4,%lo(rf_sp)(a5)
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	mv	a4,a3
	sw	a4,0(a5)
	.loc 1 344 5 is_stmt 1
	lw	a5,-24(s0)
	lbu	a3,0(a5)
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a4,a5,-4
	lui	a5,%hi(rf_sp)
	sw	a4,%lo(rf_sp)(a5)
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	mv	a4,a3
	sw	a4,0(a5)
	.loc 1 345 12
	li	a5,1
	j	.L46
.L45:
	.loc 1 347 12
	li	a5,0
.L46:
	.loc 1 349 1
	mv	a0,a5
	lw	ra,44(sp)
	.cfi_restore 1
	lw	s0,40(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 48
	addi	sp,sp,48
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE18:
	.size	rf_pfind, .-rf_pfind
	.align	1
	.globl	rf_code_pfind
	.type	rf_code_pfind, @function
rf_code_pfind:
.LFB19:
	.loc 1 352 1
	.cfi_startproc
	addi	sp,sp,-32
	.cfi_def_cfa_offset 32
	sw	ra,28(sp)
	sw	s0,24(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,32
	.cfi_def_cfa 8, 0
	.loc 1 353 3
	call	rf_start
.LBB9:
	.loc 1 359 25
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a3,a5,4
	lui	a4,%hi(rf_sp)
	sw	a3,%lo(rf_sp)(a4)
	lw	a5,0(a5)
	.loc 1 359 11
	sw	a5,-20(s0)
	.loc 1 360 25
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a3,a5,4
	lui	a4,%hi(rf_sp)
	sw	a3,%lo(rf_sp)(a4)
	lw	a5,0(a5)
	.loc 1 360 11
	sw	a5,-24(s0)
	.loc 1 361 9
	lw	a1,-20(s0)
	lw	a0,-24(s0)
	call	rf_pfind
	sw	a0,-28(s0)
	.loc 1 362 5
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a4,a5,-4
	lui	a5,%hi(rf_sp)
	sw	a4,%lo(rf_sp)(a5)
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	lw	a4,-28(s0)
	sw	a4,0(a5)
.LBE9:
	.loc 1 364 3
	lui	a5,%hi(rf_fp)
	lui	a4,%hi(rf_next)
	addi	a4,a4,%lo(rf_next)
	sw	a4,%lo(rf_fp)(a5)
	.loc 1 365 1
	nop
	lw	ra,28(sp)
	.cfi_restore 1
	lw	s0,24(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 32
	addi	sp,sp,32
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE19:
	.size	rf_code_pfind, .-rf_code_pfind
	.align	1
	.type	rf_enclose, @function
rf_enclose:
.LFB20:
	.loc 1 370 1
	.cfi_startproc
	addi	sp,sp,-64
	.cfi_def_cfa_offset 64
	sw	ra,60(sp)
	sw	s0,56(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,64
	.cfi_def_cfa 8, 0
	mv	a5,a0
	sw	a1,-40(s0)
	sw	a2,-44(s0)
	sw	a3,-48(s0)
	sw	a4,-52(s0)
	sb	a5,-33(s0)
	.loc 1 371 9
	lw	a5,-40(s0)
	sw	a5,-20(s0)
	.loc 1 372 11
	li	a5,-1
	sb	a5,-21(s0)
	.loc 1 375 5
	lw	a5,-20(s0)
	addi	a5,a5,-1
	sw	a5,-20(s0)
.L49:
	.loc 1 377 5
	lw	a5,-20(s0)
	addi	a5,a5,1
	sw	a5,-20(s0)
	.loc 1 378 4
	lbu	a5,-21(s0)
	addi	a5,a5,1
	sb	a5,-21(s0)
	.loc 1 379 11 discriminator 1
	lw	a5,-20(s0)
	lbu	a5,0(a5)
	.loc 1 379 15 discriminator 1
	lbu	a4,-33(s0)
	beq	a4,a5,.L49
	.loc 1 380 6
	lw	a5,-44(s0)
	lbu	a4,-21(s0)
	sb	a4,0(a5)
	.loc 1 383 7
	lw	a5,-20(s0)
	lbu	a5,0(a5)
	.loc 1 383 5
	bne	a5,zero,.L50
	.loc 1 384 8
	lw	a5,-52(s0)
	lbu	a4,-21(s0)
	sb	a4,0(a5)
	.loc 1 385 4
	lbu	a5,-21(s0)
	addi	a5,a5,1
	sb	a5,-21(s0)
	.loc 1 386 8
	lw	a5,-48(s0)
	lbu	a4,-21(s0)
	sb	a4,0(a5)
	.loc 1 387 4
	j	.L48
.L50:
	.loc 1 392 4
	lw	a5,-20(s0)
	addi	a5,a5,1
	sw	a5,-20(s0)
	.loc 1 393 4
	lbu	a5,-21(s0)
	addi	a5,a5,1
	sb	a5,-21(s0)
	.loc 1 395 8
	lw	a5,-20(s0)
	lbu	a5,0(a5)
	.loc 1 395 7
	lbu	a4,-33(s0)
	bne	a4,a5,.L52
	.loc 1 396 11
	lw	a5,-48(s0)
	lbu	a4,-21(s0)
	sb	a4,0(a5)
	.loc 1 397 7
	lbu	a5,-21(s0)
	addi	a5,a5,1
	sb	a5,-21(s0)
	.loc 1 398 11
	lw	a5,-52(s0)
	lbu	a4,-21(s0)
	sb	a4,0(a5)
	.loc 1 399 7
	j	.L48
.L52:
	.loc 1 401 11
	lw	a5,-20(s0)
	lbu	a5,0(a5)
	bne	a5,zero,.L50
	.loc 1 404 6
	lw	a5,-48(s0)
	lbu	a4,-21(s0)
	sb	a4,0(a5)
	.loc 1 405 6
	lw	a5,-52(s0)
	lbu	a4,-21(s0)
	sb	a4,0(a5)
.L48:
	.loc 1 406 1
	lw	ra,60(sp)
	.cfi_restore 1
	lw	s0,56(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 64
	addi	sp,sp,64
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE20:
	.size	rf_enclose, .-rf_enclose
	.align	1
	.type	rf_encl, @function
rf_encl:
.LFB21:
	.loc 1 409 1
	.cfi_startproc
	addi	sp,sp,-32
	.cfi_def_cfa_offset 32
	sw	ra,28(sp)
	sw	s0,24(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,32
	.cfi_def_cfa 8, 0
	.loc 1 414 14
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a3,a5,4
	lui	a4,%hi(rf_sp)
	sw	a3,%lo(rf_sp)(a4)
	lw	a5,0(a5)
	.loc 1 414 5
	sb	a5,-17(s0)
	.loc 1 415 20
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a3,a5,4
	lui	a4,%hi(rf_sp)
	sw	a3,%lo(rf_sp)(a4)
	lw	a5,0(a5)
	.loc 1 415 9
	sw	a5,-24(s0)
	.loc 1 416 3
	addi	a4,s0,-27
	addi	a3,s0,-26
	addi	a2,s0,-25
	lbu	a5,-17(s0)
	lw	a1,-24(s0)
	mv	a0,a5
	call	rf_enclose
	.loc 1 417 3
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a4,a5,-4
	lui	a5,%hi(rf_sp)
	sw	a4,%lo(rf_sp)(a5)
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	lw	a4,-24(s0)
	sw	a4,0(a5)
	.loc 1 418 3
	lbu	a3,-25(s0)
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a4,a5,-4
	lui	a5,%hi(rf_sp)
	sw	a4,%lo(rf_sp)(a5)
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	mv	a4,a3
	sw	a4,0(a5)
	.loc 1 419 3
	lbu	a3,-26(s0)
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a4,a5,-4
	lui	a5,%hi(rf_sp)
	sw	a4,%lo(rf_sp)(a5)
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	mv	a4,a3
	sw	a4,0(a5)
	.loc 1 420 3
	lbu	a3,-27(s0)
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a4,a5,-4
	lui	a5,%hi(rf_sp)
	sw	a4,%lo(rf_sp)(a5)
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	mv	a4,a3
	sw	a4,0(a5)
	.loc 1 421 1
	nop
	lw	ra,28(sp)
	.cfi_restore 1
	lw	s0,24(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 32
	addi	sp,sp,32
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE21:
	.size	rf_encl, .-rf_encl
	.align	1
	.globl	rf_code_encl
	.type	rf_code_encl, @function
rf_code_encl:
.LFB22:
	.loc 1 424 1
	.cfi_startproc
	addi	sp,sp,-16
	.cfi_def_cfa_offset 16
	sw	ra,12(sp)
	sw	s0,8(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,16
	.cfi_def_cfa 8, 0
	.loc 1 425 3
	call	rf_start
	.loc 1 426 3
	call	rf_encl
	.loc 1 427 3
	lui	a5,%hi(rf_fp)
	lui	a4,%hi(rf_next)
	addi	a4,a4,%lo(rf_next)
	sw	a4,%lo(rf_fp)(a5)
	.loc 1 428 1
	nop
	lw	ra,12(sp)
	.cfi_restore 1
	lw	s0,8(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 16
	addi	sp,sp,16
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE22:
	.size	rf_code_encl, .-rf_code_encl
	.align	1
	.globl	rf_code_cmove
	.type	rf_code_cmove, @function
rf_code_cmove:
.LFB23:
	.loc 1 433 1
	.cfi_startproc
	addi	sp,sp,-32
	.cfi_def_cfa_offset 32
	sw	ra,28(sp)
	sw	s0,24(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,32
	.cfi_def_cfa 8, 0
	.loc 1 434 3
	call	rf_start
.LBB10:
	.loc 1 436 23
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a3,a5,4
	lui	a4,%hi(rf_sp)
	sw	a3,%lo(rf_sp)(a4)
	.loc 1 436 15
	lw	a5,0(a5)
	sw	a5,-20(s0)
	.loc 1 437 25
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a3,a5,4
	lui	a4,%hi(rf_sp)
	sw	a3,%lo(rf_sp)(a4)
	lw	a5,0(a5)
	.loc 1 437 11
	sw	a5,-24(s0)
	.loc 1 438 27
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a3,a5,4
	lui	a4,%hi(rf_sp)
	sw	a3,%lo(rf_sp)(a4)
	lw	a5,0(a5)
	.loc 1 438 11
	sw	a5,-28(s0)
	.loc 1 440 5
	j	.L56
.L57:
	.loc 1 441 23
	lw	a4,-28(s0)
	addi	a5,a4,1
	sw	a5,-28(s0)
	.loc 1 441 11
	lw	a5,-24(s0)
	addi	a3,a5,1
	sw	a3,-24(s0)
	.loc 1 441 17
	lbu	a4,0(a4)
	.loc 1 441 15
	sb	a4,0(a5)
	.loc 1 440 24 discriminator 2
	lw	a5,-20(s0)
	addi	a5,a5,-1
	sw	a5,-20(s0)
.L56:
	.loc 1 440 12 discriminator 1
	lw	a5,-20(s0)
	bne	a5,zero,.L57
.LBE10:
	.loc 1 444 3
	lui	a5,%hi(rf_fp)
	lui	a4,%hi(rf_next)
	addi	a4,a4,%lo(rf_next)
	sw	a4,%lo(rf_fp)(a5)
	.loc 1 445 1
	nop
	lw	ra,28(sp)
	.cfi_restore 1
	lw	s0,24(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 32
	addi	sp,sp,32
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE23:
	.size	rf_code_cmove, .-rf_code_cmove
	.align	1
	.type	rf_double, @function
rf_double:
.LFB24:
	.loc 1 477 1
	.cfi_startproc
	addi	sp,sp,-48
	.cfi_def_cfa_offset 48
	sw	ra,44(sp)
	sw	s0,40(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,48
	.cfi_def_cfa 8, 0
	sw	a0,-36(s0)
	sw	a1,-40(s0)
	sw	a2,-44(s0)
	.loc 1 478 19
	lw	a3,-36(s0)
	mv	a6,a3
	li	a7,0
	.loc 1 478 15
	slli	a3,a6,0
	sw	a3,-20(s0)
	sw	zero,-24(s0)
	.loc 1 479 15
	lw	a3,-40(s0)
	sw	a3,-32(s0)
	sw	zero,-28(s0)
	.loc 1 480 10
	lw	a2,-24(s0)
	lw	a3,-32(s0)
	or	a4,a2,a3
	lw	a2,-20(s0)
	lw	a3,-28(s0)
	or	a5,a2,a3
	.loc 1 480 6
	lw	a3,-44(s0)
	sw	a4,0(a3)
	sw	a5,4(a3)
	.loc 1 481 1
	nop
	lw	ra,44(sp)
	.cfi_restore 1
	lw	s0,40(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 48
	addi	sp,sp,48
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE24:
	.size	rf_double, .-rf_double
	.align	1
	.type	rf_undouble, @function
rf_undouble:
.LFB25:
	.loc 1 486 1
	.cfi_startproc
	addi	sp,sp,-32
	.cfi_def_cfa_offset 32
	sw	ra,28(sp)
	sw	s0,24(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,32
	.cfi_def_cfa 8, 0
	sw	a0,-24(s0)
	sw	a1,-20(s0)
	sw	a2,-28(s0)
	sw	a3,-32(s0)
	.loc 1 487 10
	lw	a3,-20(s0)
	srli	a4,a3,0
	li	a5,0
	.loc 1 487 6
	lw	a5,-28(s0)
	sw	a4,0(a5)
	.loc 1 488 6
	lw	a4,-24(s0)
	lw	a5,-32(s0)
	sw	a4,0(a5)
	.loc 1 489 1
	nop
	lw	ra,28(sp)
	.cfi_restore 1
	lw	s0,24(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 32
	addi	sp,sp,32
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE25:
	.size	rf_undouble, .-rf_undouble
	.align	1
	.type	rf_ustar, @function
rf_ustar:
.LFB26:
	.loc 1 496 1
	.cfi_startproc
	addi	sp,sp,-48
	.cfi_def_cfa_offset 48
	sw	ra,44(sp)
	sw	s0,40(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,48
	.cfi_def_cfa 8, 0
	sw	a0,-36(s0)
	sw	a1,-40(s0)
	sw	a2,-44(s0)
	sw	a3,-48(s0)
	.loc 1 499 7
	lw	a3,-36(s0)
	mv	t1,a3
	li	t2,0
	.loc 1 499 23
	lw	a3,-40(s0)
	mv	a6,a3
	li	a7,0
	.loc 1 499 5
	mul	a2,t2,a6
	mul	a3,a7,t1
	add	a3,a2,a3
	mul	a2,t1,a6
	mulhu	a5,t1,a6
	mv	a4,a2
	add	a3,a3,a5
	mv	a5,a3
	sw	a4,-24(s0)
	sw	a5,-20(s0)
	sw	a4,-24(s0)
	sw	a5,-20(s0)
	.loc 1 500 3
	lw	a3,-48(s0)
	lw	a2,-44(s0)
	lw	a0,-24(s0)
	lw	a1,-20(s0)
	call	rf_undouble
	.loc 1 501 1
	nop
	lw	ra,44(sp)
	.cfi_restore 1
	lw	s0,40(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 48
	addi	sp,sp,48
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE26:
	.size	rf_ustar, .-rf_ustar
	.align	1
	.globl	rf_code_ustar
	.type	rf_code_ustar, @function
rf_code_ustar:
.LFB27:
	.loc 1 545 1
	.cfi_startproc
	addi	sp,sp,-32
	.cfi_def_cfa_offset 32
	sw	ra,28(sp)
	sw	s0,24(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,32
	.cfi_def_cfa 8, 0
	.loc 1 546 3
	call	rf_start
.LBB11:
	.loc 1 550 9
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a3,a5,4
	lui	a4,%hi(rf_sp)
	sw	a3,%lo(rf_sp)(a4)
	.loc 1 550 7
	lw	a5,0(a5)
	sw	a5,-20(s0)
	.loc 1 551 9
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a3,a5,4
	lui	a4,%hi(rf_sp)
	sw	a3,%lo(rf_sp)(a4)
	.loc 1 551 7
	lw	a5,0(a5)
	sw	a5,-24(s0)
	.loc 1 552 5
	addi	a4,s0,-32
	addi	a5,s0,-28
	mv	a3,a4
	mv	a2,a5
	lw	a1,-24(s0)
	lw	a0,-20(s0)
	call	rf_ustar
	.loc 1 553 5
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a4,a5,-4
	lui	a5,%hi(rf_sp)
	sw	a4,%lo(rf_sp)(a5)
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	lw	a4,-32(s0)
	sw	a4,0(a5)
	.loc 1 554 5
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a4,a5,-4
	lui	a5,%hi(rf_sp)
	sw	a4,%lo(rf_sp)(a5)
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	lw	a4,-28(s0)
	sw	a4,0(a5)
.LBE11:
	.loc 1 556 3
	lui	a5,%hi(rf_fp)
	lui	a4,%hi(rf_next)
	addi	a4,a4,%lo(rf_next)
	sw	a4,%lo(rf_fp)(a5)
	.loc 1 557 1
	nop
	lw	ra,28(sp)
	.cfi_restore 1
	lw	s0,24(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 32
	addi	sp,sp,32
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE27:
	.size	rf_code_ustar, .-rf_code_ustar
	.align	1
	.type	rf_uslas, @function
rf_uslas:
.LFB28:
	.loc 1 564 1
	.cfi_startproc
	addi	sp,sp,-48
	.cfi_def_cfa_offset 48
	sw	ra,44(sp)
	sw	s0,40(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,48
	.cfi_def_cfa 8, 0
	sw	a0,-36(s0)
	sw	a1,-40(s0)
	sw	a2,-44(s0)
	sw	a3,-48(s0)
	.loc 1 568 6
	lw	a4,-36(s0)
	lw	a5,-44(s0)
	bltu	a4,a5,.L63
	.loc 1 569 8
	lw	a5,-48(s0)
	li	a4,-1
	sw	a4,0(a5)
	.loc 1 570 12
	li	a5,-1
	j	.L65
.L63:
	.loc 1 573 3
	addi	a5,s0,-24
	mv	a2,a5
	lw	a1,-40(s0)
	lw	a0,-36(s0)
	call	rf_double
	.loc 1 574 3
	addi	a5,s0,-32
	mv	a2,a5
	lw	a1,-44(s0)
	li	a0,0
	call	rf_double
	.loc 1 575 23
	lw	a4,-24(s0)
	lw	a5,-20(s0)
	lw	a2,-32(s0)
	lw	a3,-28(s0)
	mv	a0,a4
	mv	a1,a5
	call	__umoddi3
	mv	a4,a0
	mv	a5,a1
	.loc 1 575 6
	lw	a5,-48(s0)
	sw	a4,0(a5)
	.loc 1 576 25
	lw	a4,-24(s0)
	lw	a5,-20(s0)
	lw	a2,-32(s0)
	lw	a3,-28(s0)
	mv	a0,a4
	mv	a1,a5
	call	__udivdi3
	mv	a4,a0
	mv	a5,a1
	.loc 1 576 10
	mv	a5,a4
.L65:
	.loc 1 577 1
	mv	a0,a5
	lw	ra,44(sp)
	.cfi_restore 1
	lw	s0,40(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 48
	addi	sp,sp,48
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE28:
	.size	rf_uslas, .-rf_uslas
	.align	1
	.globl	rf_code_uslas
	.type	rf_code_uslas, @function
rf_code_uslas:
.LFB29:
	.loc 1 623 1
	.cfi_startproc
	addi	sp,sp,-48
	.cfi_def_cfa_offset 48
	sw	ra,44(sp)
	sw	s0,40(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,48
	.cfi_def_cfa 8, 0
	.loc 1 624 3
	call	rf_start
.LBB12:
	.loc 1 628 9
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a3,a5,4
	lui	a4,%hi(rf_sp)
	sw	a3,%lo(rf_sp)(a4)
	.loc 1 628 7
	lw	a5,0(a5)
	sw	a5,-20(s0)
	.loc 1 629 10
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a3,a5,4
	lui	a4,%hi(rf_sp)
	sw	a3,%lo(rf_sp)(a4)
	.loc 1 629 8
	lw	a5,0(a5)
	sw	a5,-24(s0)
	.loc 1 630 10
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a3,a5,4
	lui	a4,%hi(rf_sp)
	sw	a3,%lo(rf_sp)(a4)
	.loc 1 630 8
	lw	a5,0(a5)
	sw	a5,-28(s0)
	.loc 1 631 9
	addi	a5,s0,-36
	mv	a3,a5
	lw	a2,-20(s0)
	lw	a1,-28(s0)
	lw	a0,-24(s0)
	call	rf_uslas
	sw	a0,-32(s0)
	.loc 1 632 5
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a4,a5,-4
	lui	a5,%hi(rf_sp)
	sw	a4,%lo(rf_sp)(a5)
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	lw	a4,-36(s0)
	sw	a4,0(a5)
	.loc 1 633 5
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a4,a5,-4
	lui	a5,%hi(rf_sp)
	sw	a4,%lo(rf_sp)(a5)
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	lw	a4,-32(s0)
	sw	a4,0(a5)
.LBE12:
	.loc 1 635 3
	lui	a5,%hi(rf_fp)
	lui	a4,%hi(rf_next)
	addi	a4,a4,%lo(rf_next)
	sw	a4,%lo(rf_fp)(a5)
	.loc 1 636 1
	nop
	lw	ra,44(sp)
	.cfi_restore 1
	lw	s0,40(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 48
	addi	sp,sp,48
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE29:
	.size	rf_code_uslas, .-rf_code_uslas
	.align	1
	.globl	rf_code_andd
	.type	rf_code_andd, @function
rf_code_andd:
.LFB30:
	.loc 1 641 1
	.cfi_startproc
	addi	sp,sp,-32
	.cfi_def_cfa_offset 32
	sw	ra,28(sp)
	sw	s0,24(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,32
	.cfi_def_cfa 8, 0
	.loc 1 642 3
	call	rf_start
.LBB13:
	.loc 1 647 9
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a3,a5,4
	lui	a4,%hi(rf_sp)
	sw	a3,%lo(rf_sp)(a4)
	.loc 1 647 7
	lw	a5,0(a5)
	sw	a5,-20(s0)
	.loc 1 648 9
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a3,a5,4
	lui	a4,%hi(rf_sp)
	sw	a3,%lo(rf_sp)(a4)
	.loc 1 648 7
	lw	a5,0(a5)
	sw	a5,-24(s0)
	.loc 1 649 5
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a4,a5,-4
	lui	a5,%hi(rf_sp)
	sw	a4,%lo(rf_sp)(a5)
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	lw	a3,-20(s0)
	lw	a4,-24(s0)
	and	a4,a3,a4
	sw	a4,0(a5)
.LBE13:
	.loc 1 651 3
	lui	a5,%hi(rf_fp)
	lui	a4,%hi(rf_next)
	addi	a4,a4,%lo(rf_next)
	sw	a4,%lo(rf_fp)(a5)
	.loc 1 652 1
	nop
	lw	ra,28(sp)
	.cfi_restore 1
	lw	s0,24(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 32
	addi	sp,sp,32
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE30:
	.size	rf_code_andd, .-rf_code_andd
	.align	1
	.globl	rf_code_orr
	.type	rf_code_orr, @function
rf_code_orr:
.LFB31:
	.loc 1 657 1
	.cfi_startproc
	addi	sp,sp,-32
	.cfi_def_cfa_offset 32
	sw	ra,28(sp)
	sw	s0,24(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,32
	.cfi_def_cfa 8, 0
	.loc 1 658 3
	call	rf_start
.LBB14:
	.loc 1 663 9
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a3,a5,4
	lui	a4,%hi(rf_sp)
	sw	a3,%lo(rf_sp)(a4)
	.loc 1 663 7
	lw	a5,0(a5)
	sw	a5,-20(s0)
	.loc 1 664 9
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a3,a5,4
	lui	a4,%hi(rf_sp)
	sw	a3,%lo(rf_sp)(a4)
	.loc 1 664 7
	lw	a5,0(a5)
	sw	a5,-24(s0)
	.loc 1 665 5
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a4,a5,-4
	lui	a5,%hi(rf_sp)
	sw	a4,%lo(rf_sp)(a5)
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	lw	a3,-20(s0)
	lw	a4,-24(s0)
	or	a4,a3,a4
	sw	a4,0(a5)
.LBE14:
	.loc 1 667 3
	lui	a5,%hi(rf_fp)
	lui	a4,%hi(rf_next)
	addi	a4,a4,%lo(rf_next)
	sw	a4,%lo(rf_fp)(a5)
	.loc 1 668 1
	nop
	lw	ra,28(sp)
	.cfi_restore 1
	lw	s0,24(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 32
	addi	sp,sp,32
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE31:
	.size	rf_code_orr, .-rf_code_orr
	.align	1
	.globl	rf_code_xorr
	.type	rf_code_xorr, @function
rf_code_xorr:
.LFB32:
	.loc 1 673 1
	.cfi_startproc
	addi	sp,sp,-32
	.cfi_def_cfa_offset 32
	sw	ra,28(sp)
	sw	s0,24(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,32
	.cfi_def_cfa 8, 0
	.loc 1 674 3
	call	rf_start
.LBB15:
	.loc 1 679 9
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a3,a5,4
	lui	a4,%hi(rf_sp)
	sw	a3,%lo(rf_sp)(a4)
	.loc 1 679 7
	lw	a5,0(a5)
	sw	a5,-20(s0)
	.loc 1 680 9
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a3,a5,4
	lui	a4,%hi(rf_sp)
	sw	a3,%lo(rf_sp)(a4)
	.loc 1 680 7
	lw	a5,0(a5)
	sw	a5,-24(s0)
	.loc 1 681 5
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a4,a5,-4
	lui	a5,%hi(rf_sp)
	sw	a4,%lo(rf_sp)(a5)
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	lw	a3,-20(s0)
	lw	a4,-24(s0)
	xor	a4,a3,a4
	sw	a4,0(a5)
.LBE15:
	.loc 1 683 3
	lui	a5,%hi(rf_fp)
	lui	a4,%hi(rf_next)
	addi	a4,a4,%lo(rf_next)
	sw	a4,%lo(rf_fp)(a5)
	.loc 1 684 1
	nop
	lw	ra,28(sp)
	.cfi_restore 1
	lw	s0,24(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 32
	addi	sp,sp,32
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE32:
	.size	rf_code_xorr, .-rf_code_xorr
	.align	1
	.globl	rf_code_spat
	.type	rf_code_spat, @function
rf_code_spat:
.LFB33:
	.loc 1 689 1
	.cfi_startproc
	addi	sp,sp,-32
	.cfi_def_cfa_offset 32
	sw	ra,28(sp)
	sw	s0,24(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,32
	.cfi_def_cfa 8, 0
	.loc 1 690 3
	call	rf_start
.LBB16:
	.loc 1 694 10
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	.loc 1 694 8
	sw	a5,-20(s0)
	.loc 1 695 5
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a4,a5,-4
	lui	a5,%hi(rf_sp)
	sw	a4,%lo(rf_sp)(a5)
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	lw	a4,-20(s0)
	sw	a4,0(a5)
.LBE16:
	.loc 1 697 3
	lui	a5,%hi(rf_fp)
	lui	a4,%hi(rf_next)
	addi	a4,a4,%lo(rf_next)
	sw	a4,%lo(rf_fp)(a5)
	.loc 1 698 1
	nop
	lw	ra,28(sp)
	.cfi_restore 1
	lw	s0,24(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 32
	addi	sp,sp,32
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE33:
	.size	rf_code_spat, .-rf_code_spat
	.align	1
	.globl	rf_code_spsto
	.type	rf_code_spsto, @function
rf_code_spsto:
.LFB34:
	.loc 1 703 1
	.cfi_startproc
	addi	sp,sp,-16
	.cfi_def_cfa_offset 16
	sw	ra,12(sp)
	sw	s0,8(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,16
	.cfi_def_cfa 8, 0
	.loc 1 704 3
	call	rf_start
	.loc 1 705 30
	lui	a5,%hi(rf_up)
	lw	a5,%lo(rf_up)(a5)
	addi	a5,a5,12
	lw	a5,0(a5)
	.loc 1 705 11
	mv	a4,a5
	.loc 1 705 9
	lui	a5,%hi(rf_sp)
	sw	a4,%lo(rf_sp)(a5)
	.loc 1 706 3
	lui	a5,%hi(rf_fp)
	lui	a4,%hi(rf_next)
	addi	a4,a4,%lo(rf_next)
	sw	a4,%lo(rf_fp)(a5)
	.loc 1 707 1
	nop
	lw	ra,12(sp)
	.cfi_restore 1
	lw	s0,8(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 16
	addi	sp,sp,16
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE34:
	.size	rf_code_spsto, .-rf_code_spsto
	.align	1
	.globl	rf_code_rpsto
	.type	rf_code_rpsto, @function
rf_code_rpsto:
.LFB35:
	.loc 1 712 1
	.cfi_startproc
	addi	sp,sp,-16
	.cfi_def_cfa_offset 16
	sw	ra,12(sp)
	sw	s0,8(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,16
	.cfi_def_cfa 8, 0
	.loc 1 713 3
	call	rf_start
	.loc 1 714 30
	lui	a5,%hi(rf_up)
	lw	a5,%lo(rf_up)(a5)
	addi	a5,a5,16
	lw	a5,0(a5)
	.loc 1 714 11
	mv	a4,a5
	.loc 1 714 9
	lui	a5,%hi(rf_rp)
	sw	a4,%lo(rf_rp)(a5)
	.loc 1 715 3
	lui	a5,%hi(rf_fp)
	lui	a4,%hi(rf_next)
	addi	a4,a4,%lo(rf_next)
	sw	a4,%lo(rf_fp)(a5)
	.loc 1 716 1
	nop
	lw	ra,12(sp)
	.cfi_restore 1
	lw	s0,8(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 16
	addi	sp,sp,16
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE35:
	.size	rf_code_rpsto, .-rf_code_rpsto
	.align	1
	.globl	rf_code_semis
	.type	rf_code_semis, @function
rf_code_semis:
.LFB36:
	.loc 1 721 1
	.cfi_startproc
	addi	sp,sp,-16
	.cfi_def_cfa_offset 16
	sw	ra,12(sp)
	sw	s0,8(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,16
	.cfi_def_cfa 8, 0
	.loc 1 722 3
	call	rf_start
	.loc 1 723 25
	lui	a5,%hi(rf_rp)
	lw	a5,%lo(rf_rp)(a5)
	addi	a3,a5,4
	lui	a4,%hi(rf_rp)
	sw	a3,%lo(rf_rp)(a4)
	lw	a5,0(a5)
	.loc 1 723 11
	mv	a4,a5
	.loc 1 723 9
	lui	a5,%hi(rf_ip)
	sw	a4,%lo(rf_ip)(a5)
	.loc 1 724 3
	lui	a5,%hi(rf_fp)
	lui	a4,%hi(rf_next)
	addi	a4,a4,%lo(rf_next)
	sw	a4,%lo(rf_fp)(a5)
	.loc 1 725 1
	nop
	lw	ra,12(sp)
	.cfi_restore 1
	lw	s0,8(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 16
	addi	sp,sp,16
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE36:
	.size	rf_code_semis, .-rf_code_semis
	.align	1
	.globl	rf_code_leave
	.type	rf_code_leave, @function
rf_code_leave:
.LFB37:
	.loc 1 730 1
	.cfi_startproc
	addi	sp,sp,-32
	.cfi_def_cfa_offset 32
	sw	ra,28(sp)
	sw	s0,24(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,32
	.cfi_def_cfa 8, 0
	.loc 1 731 3
	call	rf_start
.LBB17:
	.loc 1 735 25
	lui	a5,%hi(rf_rp)
	lw	a5,%lo(rf_rp)(a5)
	addi	a3,a5,4
	lui	a4,%hi(rf_rp)
	sw	a3,%lo(rf_rp)(a4)
	.loc 1 735 11
	lw	a5,0(a5)
	sw	a5,-20(s0)
	.loc 1 736 12
	lui	a5,%hi(rf_rp)
	lw	a5,%lo(rf_rp)(a5)
	addi	a4,a5,4
	lui	a5,%hi(rf_rp)
	sw	a4,%lo(rf_rp)(a5)
	.loc 1 737 5
	lui	a5,%hi(rf_rp)
	lw	a5,%lo(rf_rp)(a5)
	addi	a4,a5,-4
	lui	a5,%hi(rf_rp)
	sw	a4,%lo(rf_rp)(a5)
	lui	a5,%hi(rf_rp)
	lw	a5,%lo(rf_rp)(a5)
	lw	a4,-20(s0)
	sw	a4,0(a5)
	.loc 1 738 5
	lui	a5,%hi(rf_rp)
	lw	a5,%lo(rf_rp)(a5)
	addi	a4,a5,-4
	lui	a5,%hi(rf_rp)
	sw	a4,%lo(rf_rp)(a5)
	lui	a5,%hi(rf_rp)
	lw	a5,%lo(rf_rp)(a5)
	lw	a4,-20(s0)
	sw	a4,0(a5)
.LBE17:
	.loc 1 740 3
	lui	a5,%hi(rf_fp)
	lui	a4,%hi(rf_next)
	addi	a4,a4,%lo(rf_next)
	sw	a4,%lo(rf_fp)(a5)
	.loc 1 741 1
	nop
	lw	ra,28(sp)
	.cfi_restore 1
	lw	s0,24(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 32
	addi	sp,sp,32
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE37:
	.size	rf_code_leave, .-rf_code_leave
	.align	1
	.globl	rf_code_tor
	.type	rf_code_tor, @function
rf_code_tor:
.LFB38:
	.loc 1 746 1
	.cfi_startproc
	addi	sp,sp,-16
	.cfi_def_cfa_offset 16
	sw	ra,12(sp)
	sw	s0,8(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,16
	.cfi_def_cfa 8, 0
	.loc 1 747 3
	call	rf_start
	.loc 1 748 3
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a3,a5,4
	lui	a4,%hi(rf_sp)
	sw	a3,%lo(rf_sp)(a4)
	lui	a4,%hi(rf_rp)
	lw	a4,%lo(rf_rp)(a4)
	addi	a3,a4,-4
	lui	a4,%hi(rf_rp)
	sw	a3,%lo(rf_rp)(a4)
	lui	a4,%hi(rf_rp)
	lw	a4,%lo(rf_rp)(a4)
	lw	a5,0(a5)
	sw	a5,0(a4)
	.loc 1 749 3
	lui	a5,%hi(rf_fp)
	lui	a4,%hi(rf_next)
	addi	a4,a4,%lo(rf_next)
	sw	a4,%lo(rf_fp)(a5)
	.loc 1 750 1
	nop
	lw	ra,12(sp)
	.cfi_restore 1
	lw	s0,8(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 16
	addi	sp,sp,16
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE38:
	.size	rf_code_tor, .-rf_code_tor
	.align	1
	.globl	rf_code_fromr
	.type	rf_code_fromr, @function
rf_code_fromr:
.LFB39:
	.loc 1 755 1
	.cfi_startproc
	addi	sp,sp,-16
	.cfi_def_cfa_offset 16
	sw	ra,12(sp)
	sw	s0,8(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,16
	.cfi_def_cfa 8, 0
	.loc 1 756 3
	call	rf_start
	.loc 1 757 3
	lui	a5,%hi(rf_rp)
	lw	a5,%lo(rf_rp)(a5)
	addi	a3,a5,4
	lui	a4,%hi(rf_rp)
	sw	a3,%lo(rf_rp)(a4)
	lui	a4,%hi(rf_sp)
	lw	a4,%lo(rf_sp)(a4)
	addi	a3,a4,-4
	lui	a4,%hi(rf_sp)
	sw	a3,%lo(rf_sp)(a4)
	lui	a4,%hi(rf_sp)
	lw	a4,%lo(rf_sp)(a4)
	lw	a5,0(a5)
	sw	a5,0(a4)
	.loc 1 758 3
	lui	a5,%hi(rf_fp)
	lui	a4,%hi(rf_next)
	addi	a4,a4,%lo(rf_next)
	sw	a4,%lo(rf_fp)(a5)
	.loc 1 759 1
	nop
	lw	ra,12(sp)
	.cfi_restore 1
	lw	s0,8(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 16
	addi	sp,sp,16
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE39:
	.size	rf_code_fromr, .-rf_code_fromr
	.align	1
	.globl	rf_code_zequ
	.type	rf_code_zequ, @function
rf_code_zequ:
.LFB40:
	.loc 1 764 1
	.cfi_startproc
	addi	sp,sp,-32
	.cfi_def_cfa_offset 32
	sw	ra,28(sp)
	sw	s0,24(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,32
	.cfi_def_cfa 8, 0
	.loc 1 765 3
	call	rf_start
.LBB18:
	.loc 1 769 10
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a3,a5,4
	lui	a4,%hi(rf_sp)
	sw	a3,%lo(rf_sp)(a4)
	lw	a5,0(a5)
	.loc 1 769 20
	seqz	a5,a5
	andi	a5,a5,0xff
	.loc 1 769 7
	sw	a5,-20(s0)
	.loc 1 770 5
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a4,a5,-4
	lui	a5,%hi(rf_sp)
	sw	a4,%lo(rf_sp)(a5)
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	lw	a4,-20(s0)
	sw	a4,0(a5)
.LBE18:
	.loc 1 772 3
	lui	a5,%hi(rf_fp)
	lui	a4,%hi(rf_next)
	addi	a4,a4,%lo(rf_next)
	sw	a4,%lo(rf_fp)(a5)
	.loc 1 773 1
	nop
	lw	ra,28(sp)
	.cfi_restore 1
	lw	s0,24(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 32
	addi	sp,sp,32
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE40:
	.size	rf_code_zequ, .-rf_code_zequ
	.align	1
	.globl	rf_code_zless
	.type	rf_code_zless, @function
rf_code_zless:
.LFB41:
	.loc 1 778 1
	.cfi_startproc
	addi	sp,sp,-32
	.cfi_def_cfa_offset 32
	sw	ra,28(sp)
	sw	s0,24(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,32
	.cfi_def_cfa 8, 0
	.loc 1 779 3
	call	rf_start
.LBB19:
	.loc 1 783 22
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a3,a5,4
	lui	a4,%hi(rf_sp)
	sw	a3,%lo(rf_sp)(a4)
	lw	a5,0(a5)
	.loc 1 783 33
	srli	a5,a5,31
	andi	a5,a5,0xff
	.loc 1 783 7
	sw	a5,-20(s0)
	.loc 1 784 5
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a4,a5,-4
	lui	a5,%hi(rf_sp)
	sw	a4,%lo(rf_sp)(a5)
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	lw	a4,-20(s0)
	sw	a4,0(a5)
.LBE19:
	.loc 1 786 3
	lui	a5,%hi(rf_fp)
	lui	a4,%hi(rf_next)
	addi	a4,a4,%lo(rf_next)
	sw	a4,%lo(rf_fp)(a5)
	.loc 1 787 1
	nop
	lw	ra,28(sp)
	.cfi_restore 1
	lw	s0,24(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 32
	addi	sp,sp,32
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE41:
	.size	rf_code_zless, .-rf_code_zless
	.align	1
	.globl	rf_code_plus
	.type	rf_code_plus, @function
rf_code_plus:
.LFB42:
	.loc 1 792 1
	.cfi_startproc
	addi	sp,sp,-32
	.cfi_def_cfa_offset 32
	sw	ra,28(sp)
	sw	s0,24(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,32
	.cfi_def_cfa 8, 0
	.loc 1 793 3
	call	rf_start
.LBB20:
	.loc 1 798 9
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a3,a5,4
	lui	a4,%hi(rf_sp)
	sw	a3,%lo(rf_sp)(a4)
	lw	a5,0(a5)
	.loc 1 798 7
	sw	a5,-20(s0)
	.loc 1 799 9
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a3,a5,4
	lui	a4,%hi(rf_sp)
	sw	a3,%lo(rf_sp)(a4)
	lw	a5,0(a5)
	.loc 1 799 7
	sw	a5,-24(s0)
	.loc 1 800 5
	lw	a4,-20(s0)
	lw	a5,-24(s0)
	add	a3,a4,a5
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a4,a5,-4
	lui	a5,%hi(rf_sp)
	sw	a4,%lo(rf_sp)(a5)
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	mv	a4,a3
	sw	a4,0(a5)
.LBE20:
	.loc 1 802 3
	lui	a5,%hi(rf_fp)
	lui	a4,%hi(rf_next)
	addi	a4,a4,%lo(rf_next)
	sw	a4,%lo(rf_fp)(a5)
	.loc 1 803 1
	nop
	lw	ra,28(sp)
	.cfi_restore 1
	lw	s0,24(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 32
	addi	sp,sp,32
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE42:
	.size	rf_code_plus, .-rf_code_plus
	.align	1
	.type	rf_dplus, @function
rf_dplus:
.LFB43:
	.loc 1 810 1
	.cfi_startproc
	addi	sp,sp,-80
	.cfi_def_cfa_offset 80
	sw	ra,76(sp)
	sw	s0,72(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,80
	.cfi_def_cfa 8, 0
	sw	a0,-52(s0)
	sw	a1,-56(s0)
	sw	a2,-60(s0)
	sw	a3,-64(s0)
	sw	a4,-68(s0)
	sw	a5,-72(s0)
	.loc 1 815 3
	addi	a5,s0,-32
	mv	a2,a5
	lw	a1,-56(s0)
	lw	a0,-52(s0)
	call	rf_double
	.loc 1 816 3
	addi	a5,s0,-40
	mv	a2,a5
	lw	a1,-64(s0)
	lw	a0,-60(s0)
	call	rf_double
	.loc 1 817 9
	lw	a2,-32(s0)
	lw	a3,-28(s0)
	lw	a0,-40(s0)
	lw	a1,-36(s0)
	.loc 1 817 5
	add	a4,a2,a0
	mv	a6,a4
	sltu	a6,a6,a2
	add	a5,a3,a1
	add	a3,a6,a5
	mv	a5,a3
	sw	a4,-24(s0)
	sw	a5,-20(s0)
	.loc 1 818 3
	lw	a3,-72(s0)
	lw	a2,-68(s0)
	lw	a0,-24(s0)
	lw	a1,-20(s0)
	call	rf_undouble
	.loc 1 819 1
	nop
	lw	ra,76(sp)
	.cfi_restore 1
	lw	s0,72(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 80
	addi	sp,sp,80
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE43:
	.size	rf_dplus, .-rf_dplus
	.align	1
	.globl	rf_code_dplus
	.type	rf_code_dplus, @function
rf_code_dplus:
.LFB44:
	.loc 1 831 1
	.cfi_startproc
	addi	sp,sp,-48
	.cfi_def_cfa_offset 48
	sw	ra,44(sp)
	sw	s0,40(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,48
	.cfi_def_cfa 8, 0
	.loc 1 832 3
	call	rf_start
.LBB21:
	.loc 1 836 10
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a3,a5,4
	lui	a4,%hi(rf_sp)
	sw	a3,%lo(rf_sp)(a4)
	.loc 1 836 8
	lw	a5,0(a5)
	sw	a5,-20(s0)
	.loc 1 837 10
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a3,a5,4
	lui	a4,%hi(rf_sp)
	sw	a3,%lo(rf_sp)(a4)
	.loc 1 837 8
	lw	a5,0(a5)
	sw	a5,-24(s0)
	.loc 1 838 10
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a3,a5,4
	lui	a4,%hi(rf_sp)
	sw	a3,%lo(rf_sp)(a4)
	.loc 1 838 8
	lw	a5,0(a5)
	sw	a5,-28(s0)
	.loc 1 839 10
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a3,a5,4
	lui	a4,%hi(rf_sp)
	sw	a3,%lo(rf_sp)(a4)
	.loc 1 839 8
	lw	a5,0(a5)
	sw	a5,-32(s0)
	.loc 1 840 5
	addi	a5,s0,-40
	addi	a4,s0,-36
	lw	a3,-32(s0)
	lw	a2,-28(s0)
	lw	a1,-24(s0)
	lw	a0,-20(s0)
	call	rf_dplus
	.loc 1 841 5
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a4,a5,-4
	lui	a5,%hi(rf_sp)
	sw	a4,%lo(rf_sp)(a5)
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	lw	a4,-40(s0)
	sw	a4,0(a5)
	.loc 1 842 5
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a4,a5,-4
	lui	a5,%hi(rf_sp)
	sw	a4,%lo(rf_sp)(a5)
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	lw	a4,-36(s0)
	sw	a4,0(a5)
.LBE21:
	.loc 1 844 3
	lui	a5,%hi(rf_fp)
	lui	a4,%hi(rf_next)
	addi	a4,a4,%lo(rf_next)
	sw	a4,%lo(rf_fp)(a5)
	.loc 1 845 1
	nop
	lw	ra,44(sp)
	.cfi_restore 1
	lw	s0,40(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 48
	addi	sp,sp,48
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE44:
	.size	rf_code_dplus, .-rf_code_dplus
	.align	1
	.globl	rf_code_minus
	.type	rf_code_minus, @function
rf_code_minus:
.LFB45:
	.loc 1 850 1
	.cfi_startproc
	addi	sp,sp,-32
	.cfi_def_cfa_offset 32
	sw	ra,28(sp)
	sw	s0,24(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,32
	.cfi_def_cfa 8, 0
	.loc 1 851 3
	call	rf_start
.LBB22:
	.loc 1 855 11
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a3,a5,4
	lui	a4,%hi(rf_sp)
	sw	a3,%lo(rf_sp)(a4)
	lw	a5,0(a5)
	.loc 1 855 7
	neg	a5,a5
	sw	a5,-20(s0)
	.loc 1 856 5
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a4,a5,-4
	lui	a5,%hi(rf_sp)
	sw	a4,%lo(rf_sp)(a5)
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	lw	a4,-20(s0)
	sw	a4,0(a5)
.LBE22:
	.loc 1 858 3
	lui	a5,%hi(rf_fp)
	lui	a4,%hi(rf_next)
	addi	a4,a4,%lo(rf_next)
	sw	a4,%lo(rf_fp)(a5)
	.loc 1 859 1
	nop
	lw	ra,28(sp)
	.cfi_restore 1
	lw	s0,24(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 32
	addi	sp,sp,32
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE45:
	.size	rf_code_minus, .-rf_code_minus
	.align	1
	.type	rf_dminu, @function
rf_dminu:
.LFB46:
	.loc 1 866 1
	.cfi_startproc
	addi	sp,sp,-48
	.cfi_def_cfa_offset 48
	sw	ra,44(sp)
	sw	s0,40(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,48
	.cfi_def_cfa 8, 0
	sw	a0,-36(s0)
	sw	a1,-40(s0)
	sw	a2,-44(s0)
	sw	a3,-48(s0)
	.loc 1 869 3
	addi	a5,s0,-24
	mv	a2,a5
	lw	a1,-40(s0)
	lw	a0,-36(s0)
	call	rf_double
	.loc 1 870 7
	lw	a0,-24(s0)
	lw	a1,-20(s0)
	li	a4,0
	li	a5,0
	sub	a2,a4,a0
	mv	a6,a2
	sgtu	a6,a6,a4
	sub	a3,a5,a1
	sub	a5,a3,a6
	mv	a3,a5
	mv	a4,a2
	mv	a5,a3
	.loc 1 870 5
	sw	a4,-24(s0)
	sw	a5,-20(s0)
	.loc 1 871 3
	lw	a4,-24(s0)
	lw	a5,-20(s0)
	lw	a3,-48(s0)
	lw	a2,-44(s0)
	mv	a0,a4
	mv	a1,a5
	call	rf_undouble
	.loc 1 872 1
	nop
	lw	ra,44(sp)
	.cfi_restore 1
	lw	s0,40(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 48
	addi	sp,sp,48
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE46:
	.size	rf_dminu, .-rf_dminu
	.align	1
	.globl	rf_code_dminu
	.type	rf_code_dminu, @function
rf_code_dminu:
.LFB47:
	.loc 1 884 1
	.cfi_startproc
	addi	sp,sp,-32
	.cfi_def_cfa_offset 32
	sw	ra,28(sp)
	sw	s0,24(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,32
	.cfi_def_cfa 8, 0
	.loc 1 885 3
	call	rf_start
.LBB23:
	.loc 1 889 10
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a3,a5,4
	lui	a4,%hi(rf_sp)
	sw	a3,%lo(rf_sp)(a4)
	.loc 1 889 8
	lw	a5,0(a5)
	sw	a5,-20(s0)
	.loc 1 890 10
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a3,a5,4
	lui	a4,%hi(rf_sp)
	sw	a3,%lo(rf_sp)(a4)
	.loc 1 890 8
	lw	a5,0(a5)
	sw	a5,-24(s0)
	.loc 1 891 5
	addi	a4,s0,-32
	addi	a5,s0,-28
	mv	a3,a4
	mv	a2,a5
	lw	a1,-24(s0)
	lw	a0,-20(s0)
	call	rf_dminu
	.loc 1 892 5
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a4,a5,-4
	lui	a5,%hi(rf_sp)
	sw	a4,%lo(rf_sp)(a5)
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	lw	a4,-32(s0)
	sw	a4,0(a5)
	.loc 1 893 5
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a4,a5,-4
	lui	a5,%hi(rf_sp)
	sw	a4,%lo(rf_sp)(a5)
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	lw	a4,-28(s0)
	sw	a4,0(a5)
.LBE23:
	.loc 1 895 3
	lui	a5,%hi(rf_fp)
	lui	a4,%hi(rf_next)
	addi	a4,a4,%lo(rf_next)
	sw	a4,%lo(rf_fp)(a5)
	.loc 1 896 1
	nop
	lw	ra,28(sp)
	.cfi_restore 1
	lw	s0,24(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 32
	addi	sp,sp,32
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE47:
	.size	rf_code_dminu, .-rf_code_dminu
	.align	1
	.globl	rf_code_over
	.type	rf_code_over, @function
rf_code_over:
.LFB48:
	.loc 1 901 1
	.cfi_startproc
	addi	sp,sp,-32
	.cfi_def_cfa_offset 32
	sw	ra,28(sp)
	sw	s0,24(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,32
	.cfi_def_cfa 8, 0
	.loc 1 902 3
	call	rf_start
.LBB24:
	.loc 1 907 9
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a3,a5,4
	lui	a4,%hi(rf_sp)
	sw	a3,%lo(rf_sp)(a4)
	.loc 1 907 7
	lw	a5,0(a5)
	sw	a5,-20(s0)
	.loc 1 908 9
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a3,a5,4
	lui	a4,%hi(rf_sp)
	sw	a3,%lo(rf_sp)(a4)
	.loc 1 908 7
	lw	a5,0(a5)
	sw	a5,-24(s0)
	.loc 1 909 5
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a4,a5,-4
	lui	a5,%hi(rf_sp)
	sw	a4,%lo(rf_sp)(a5)
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	lw	a4,-24(s0)
	sw	a4,0(a5)
	.loc 1 910 5
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a4,a5,-4
	lui	a5,%hi(rf_sp)
	sw	a4,%lo(rf_sp)(a5)
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	lw	a4,-20(s0)
	sw	a4,0(a5)
	.loc 1 911 5
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a4,a5,-4
	lui	a5,%hi(rf_sp)
	sw	a4,%lo(rf_sp)(a5)
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	lw	a4,-24(s0)
	sw	a4,0(a5)
.LBE24:
	.loc 1 913 3
	lui	a5,%hi(rf_fp)
	lui	a4,%hi(rf_next)
	addi	a4,a4,%lo(rf_next)
	sw	a4,%lo(rf_fp)(a5)
	.loc 1 914 1
	nop
	lw	ra,28(sp)
	.cfi_restore 1
	lw	s0,24(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 32
	addi	sp,sp,32
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE48:
	.size	rf_code_over, .-rf_code_over
	.align	1
	.globl	rf_code_drop
	.type	rf_code_drop, @function
rf_code_drop:
.LFB49:
	.loc 1 919 1
	.cfi_startproc
	addi	sp,sp,-16
	.cfi_def_cfa_offset 16
	sw	ra,12(sp)
	sw	s0,8(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,16
	.cfi_def_cfa 8, 0
	.loc 1 920 3
	call	rf_start
	.loc 1 921 10
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a4,a5,4
	lui	a5,%hi(rf_sp)
	sw	a4,%lo(rf_sp)(a5)
	.loc 1 922 3
	lui	a5,%hi(rf_fp)
	lui	a4,%hi(rf_next)
	addi	a4,a4,%lo(rf_next)
	sw	a4,%lo(rf_fp)(a5)
	.loc 1 923 1
	nop
	lw	ra,12(sp)
	.cfi_restore 1
	lw	s0,8(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 16
	addi	sp,sp,16
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE49:
	.size	rf_code_drop, .-rf_code_drop
	.align	1
	.globl	rf_code_swap
	.type	rf_code_swap, @function
rf_code_swap:
.LFB50:
	.loc 1 928 1
	.cfi_startproc
	addi	sp,sp,-32
	.cfi_def_cfa_offset 32
	sw	ra,28(sp)
	sw	s0,24(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,32
	.cfi_def_cfa 8, 0
	.loc 1 929 3
	call	rf_start
.LBB25:
	.loc 1 934 9
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a3,a5,4
	lui	a4,%hi(rf_sp)
	sw	a3,%lo(rf_sp)(a4)
	.loc 1 934 7
	lw	a5,0(a5)
	sw	a5,-20(s0)
	.loc 1 935 9
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a3,a5,4
	lui	a4,%hi(rf_sp)
	sw	a3,%lo(rf_sp)(a4)
	.loc 1 935 7
	lw	a5,0(a5)
	sw	a5,-24(s0)
	.loc 1 936 5
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a4,a5,-4
	lui	a5,%hi(rf_sp)
	sw	a4,%lo(rf_sp)(a5)
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	lw	a4,-20(s0)
	sw	a4,0(a5)
	.loc 1 937 5
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a4,a5,-4
	lui	a5,%hi(rf_sp)
	sw	a4,%lo(rf_sp)(a5)
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	lw	a4,-24(s0)
	sw	a4,0(a5)
.LBE25:
	.loc 1 939 3
	lui	a5,%hi(rf_fp)
	lui	a4,%hi(rf_next)
	addi	a4,a4,%lo(rf_next)
	sw	a4,%lo(rf_fp)(a5)
	.loc 1 940 1
	nop
	lw	ra,28(sp)
	.cfi_restore 1
	lw	s0,24(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 32
	addi	sp,sp,32
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE50:
	.size	rf_code_swap, .-rf_code_swap
	.align	1
	.globl	rf_code_dup
	.type	rf_code_dup, @function
rf_code_dup:
.LFB51:
	.loc 1 945 1
	.cfi_startproc
	addi	sp,sp,-32
	.cfi_def_cfa_offset 32
	sw	ra,28(sp)
	sw	s0,24(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,32
	.cfi_def_cfa 8, 0
	.loc 1 946 3
	call	rf_start
.LBB26:
	.loc 1 950 9
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a3,a5,4
	lui	a4,%hi(rf_sp)
	sw	a3,%lo(rf_sp)(a4)
	.loc 1 950 7
	lw	a5,0(a5)
	sw	a5,-20(s0)
	.loc 1 951 5
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a4,a5,-4
	lui	a5,%hi(rf_sp)
	sw	a4,%lo(rf_sp)(a5)
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	lw	a4,-20(s0)
	sw	a4,0(a5)
	.loc 1 952 5
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a4,a5,-4
	lui	a5,%hi(rf_sp)
	sw	a4,%lo(rf_sp)(a5)
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	lw	a4,-20(s0)
	sw	a4,0(a5)
.LBE26:
	.loc 1 954 3
	lui	a5,%hi(rf_fp)
	lui	a4,%hi(rf_next)
	addi	a4,a4,%lo(rf_next)
	sw	a4,%lo(rf_fp)(a5)
	.loc 1 955 1
	nop
	lw	ra,28(sp)
	.cfi_restore 1
	lw	s0,24(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 32
	addi	sp,sp,32
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE51:
	.size	rf_code_dup, .-rf_code_dup
	.align	1
	.globl	rf_code_pstor
	.type	rf_code_pstor, @function
rf_code_pstor:
.LFB52:
	.loc 1 960 1
	.cfi_startproc
	addi	sp,sp,-32
	.cfi_def_cfa_offset 32
	sw	ra,28(sp)
	sw	s0,24(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,32
	.cfi_def_cfa 8, 0
	.loc 1 961 3
	call	rf_start
.LBB27:
	.loc 1 966 26
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a3,a5,4
	lui	a4,%hi(rf_sp)
	sw	a3,%lo(rf_sp)(a4)
	lw	a5,0(a5)
	.loc 1 966 10
	sw	a5,-20(s0)
	.loc 1 967 20
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a3,a5,4
	lui	a4,%hi(rf_sp)
	sw	a3,%lo(rf_sp)(a4)
	lw	a5,0(a5)
	.loc 1 967 7
	sw	a5,-24(s0)
	.loc 1 968 5
	lw	a5,-20(s0)
	lw	a4,0(a5)
	.loc 1 968 11
	lw	a5,-24(s0)
	add	a4,a4,a5
	lw	a5,-20(s0)
	sw	a4,0(a5)
.LBE27:
	.loc 1 970 3
	lui	a5,%hi(rf_fp)
	lui	a4,%hi(rf_next)
	addi	a4,a4,%lo(rf_next)
	sw	a4,%lo(rf_fp)(a5)
	.loc 1 971 1
	nop
	lw	ra,28(sp)
	.cfi_restore 1
	lw	s0,24(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 32
	addi	sp,sp,32
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE52:
	.size	rf_code_pstor, .-rf_code_pstor
	.align	1
	.globl	rf_code_toggl
	.type	rf_code_toggl, @function
rf_code_toggl:
.LFB53:
	.loc 1 976 1
	.cfi_startproc
	addi	sp,sp,-32
	.cfi_def_cfa_offset 32
	sw	ra,28(sp)
	sw	s0,24(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,32
	.cfi_def_cfa 8, 0
	.loc 1 977 3
	call	rf_start
.LBB28:
	.loc 1 982 19
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a3,a5,4
	lui	a4,%hi(rf_sp)
	sw	a3,%lo(rf_sp)(a4)
	lw	a5,0(a5)
	.loc 1 982 10
	sb	a5,-17(s0)
	.loc 1 983 21
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a3,a5,4
	lui	a4,%hi(rf_sp)
	sw	a3,%lo(rf_sp)(a4)
	lw	a5,0(a5)
	.loc 1 983 10
	sw	a5,-24(s0)
	.loc 1 984 5
	lw	a5,-24(s0)
	lbu	a5,0(a5)
	.loc 1 984 11
	lbu	a4,-17(s0)
	xor	a5,a5,a4
	andi	a4,a5,0xff
	lw	a5,-24(s0)
	sb	a4,0(a5)
.LBE28:
	.loc 1 986 3
	lui	a5,%hi(rf_fp)
	lui	a4,%hi(rf_next)
	addi	a4,a4,%lo(rf_next)
	sw	a4,%lo(rf_fp)(a5)
	.loc 1 987 1
	nop
	lw	ra,28(sp)
	.cfi_restore 1
	lw	s0,24(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 32
	addi	sp,sp,32
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE53:
	.size	rf_code_toggl, .-rf_code_toggl
	.align	1
	.globl	rf_code_at
	.type	rf_code_at, @function
rf_code_at:
.LFB54:
	.loc 1 992 1
	.cfi_startproc
	addi	sp,sp,-32
	.cfi_def_cfa_offset 32
	sw	ra,28(sp)
	sw	s0,24(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,32
	.cfi_def_cfa 8, 0
	.loc 1 993 3
	call	rf_start
.LBB29:
	.loc 1 998 26
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a3,a5,4
	lui	a4,%hi(rf_sp)
	sw	a3,%lo(rf_sp)(a4)
	lw	a5,0(a5)
	.loc 1 998 10
	sw	a5,-20(s0)
	.loc 1 999 10
	lw	a5,-20(s0)
	lw	a5,0(a5)
	sw	a5,-24(s0)
	.loc 1 1000 5
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a4,a5,-4
	lui	a5,%hi(rf_sp)
	sw	a4,%lo(rf_sp)(a5)
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	lw	a4,-24(s0)
	sw	a4,0(a5)
.LBE29:
	.loc 1 1002 3
	lui	a5,%hi(rf_fp)
	lui	a4,%hi(rf_next)
	addi	a4,a4,%lo(rf_next)
	sw	a4,%lo(rf_fp)(a5)
	.loc 1 1003 1
	nop
	lw	ra,28(sp)
	.cfi_restore 1
	lw	s0,24(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 32
	addi	sp,sp,32
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE54:
	.size	rf_code_at, .-rf_code_at
	.align	1
	.globl	rf_code_cat
	.type	rf_code_cat, @function
rf_code_cat:
.LFB55:
	.loc 1 1008 1
	.cfi_startproc
	addi	sp,sp,-32
	.cfi_def_cfa_offset 32
	sw	ra,28(sp)
	sw	s0,24(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,32
	.cfi_def_cfa 8, 0
	.loc 1 1009 3
	call	rf_start
.LBB30:
	.loc 1 1013 24
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a3,a5,4
	lui	a4,%hi(rf_sp)
	sw	a3,%lo(rf_sp)(a4)
	lw	a5,0(a5)
	.loc 1 1013 10
	sw	a5,-20(s0)
	.loc 1 1014 5
	lw	a5,-20(s0)
	lbu	a3,0(a5)
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a4,a5,-4
	lui	a5,%hi(rf_sp)
	sw	a4,%lo(rf_sp)(a5)
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	mv	a4,a3
	sw	a4,0(a5)
.LBE30:
	.loc 1 1016 3
	lui	a5,%hi(rf_fp)
	lui	a4,%hi(rf_next)
	addi	a4,a4,%lo(rf_next)
	sw	a4,%lo(rf_fp)(a5)
	.loc 1 1017 1
	nop
	lw	ra,28(sp)
	.cfi_restore 1
	lw	s0,24(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 32
	addi	sp,sp,32
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE55:
	.size	rf_code_cat, .-rf_code_cat
	.align	1
	.globl	rf_code_store
	.type	rf_code_store, @function
rf_code_store:
.LFB56:
	.loc 1 1022 1
	.cfi_startproc
	addi	sp,sp,-32
	.cfi_def_cfa_offset 32
	sw	ra,28(sp)
	sw	s0,24(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,32
	.cfi_def_cfa 8, 0
	.loc 1 1023 3
	call	rf_start
.LBB31:
	.loc 1 1028 26
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a3,a5,4
	lui	a4,%hi(rf_sp)
	sw	a3,%lo(rf_sp)(a4)
	lw	a5,0(a5)
	.loc 1 1028 10
	sw	a5,-20(s0)
	.loc 1 1029 9
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a3,a5,4
	lui	a4,%hi(rf_sp)
	sw	a3,%lo(rf_sp)(a4)
	.loc 1 1029 7
	lw	a5,0(a5)
	sw	a5,-24(s0)
	.loc 1 1030 11
	lw	a5,-20(s0)
	lw	a4,-24(s0)
	sw	a4,0(a5)
.LBE31:
	.loc 1 1032 3
	lui	a5,%hi(rf_fp)
	lui	a4,%hi(rf_next)
	addi	a4,a4,%lo(rf_next)
	sw	a4,%lo(rf_fp)(a5)
	.loc 1 1033 1
	nop
	lw	ra,28(sp)
	.cfi_restore 1
	lw	s0,24(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 32
	addi	sp,sp,32
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE56:
	.size	rf_code_store, .-rf_code_store
	.align	1
	.globl	rf_code_cstor
	.type	rf_code_cstor, @function
rf_code_cstor:
.LFB57:
	.loc 1 1038 1
	.cfi_startproc
	addi	sp,sp,-32
	.cfi_def_cfa_offset 32
	sw	ra,28(sp)
	sw	s0,24(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,32
	.cfi_def_cfa 8, 0
	.loc 1 1039 3
	call	rf_start
.LBB32:
	.loc 1 1044 24
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a3,a5,4
	lui	a4,%hi(rf_sp)
	sw	a3,%lo(rf_sp)(a4)
	lw	a5,0(a5)
	.loc 1 1044 10
	sw	a5,-20(s0)
	.loc 1 1045 19
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a3,a5,4
	lui	a4,%hi(rf_sp)
	sw	a3,%lo(rf_sp)(a4)
	lw	a5,0(a5)
	.loc 1 1045 7
	sb	a5,-21(s0)
	.loc 1 1046 11
	lw	a5,-20(s0)
	lbu	a4,-21(s0)
	sb	a4,0(a5)
.LBE32:
	.loc 1 1048 3
	lui	a5,%hi(rf_fp)
	lui	a4,%hi(rf_next)
	addi	a4,a4,%lo(rf_next)
	sw	a4,%lo(rf_fp)(a5)
	.loc 1 1049 1
	nop
	lw	ra,28(sp)
	.cfi_restore 1
	lw	s0,24(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 32
	addi	sp,sp,32
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE57:
	.size	rf_code_cstor, .-rf_code_cstor
	.align	1
	.globl	rf_code_docol
	.type	rf_code_docol, @function
rf_code_docol:
.LFB58:
	.loc 1 1054 1
	.cfi_startproc
	addi	sp,sp,-16
	.cfi_def_cfa_offset 16
	sw	ra,12(sp)
	sw	s0,8(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,16
	.cfi_def_cfa 8, 0
	.loc 1 1055 3
	call	rf_start
	.loc 1 1056 3
	lui	a5,%hi(rf_ip)
	lw	a3,%lo(rf_ip)(a5)
	lui	a5,%hi(rf_rp)
	lw	a5,%lo(rf_rp)(a5)
	addi	a4,a5,-4
	lui	a5,%hi(rf_rp)
	sw	a4,%lo(rf_rp)(a5)
	lui	a5,%hi(rf_rp)
	lw	a5,%lo(rf_rp)(a5)
	mv	a4,a3
	sw	a4,0(a5)
	.loc 1 1057 11
	lui	a5,%hi(rf_w)
	lw	a5,%lo(rf_w)(a5)
	.loc 1 1057 30
	addi	a4,a5,4
	.loc 1 1057 9
	lui	a5,%hi(rf_ip)
	sw	a4,%lo(rf_ip)(a5)
	.loc 1 1058 3
	lui	a5,%hi(rf_fp)
	lui	a4,%hi(rf_next)
	addi	a4,a4,%lo(rf_next)
	sw	a4,%lo(rf_fp)(a5)
	.loc 1 1059 1
	nop
	lw	ra,12(sp)
	.cfi_restore 1
	lw	s0,8(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 16
	addi	sp,sp,16
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE58:
	.size	rf_code_docol, .-rf_code_docol
	.align	1
	.globl	rf_code_docon
	.type	rf_code_docon, @function
rf_code_docon:
.LFB59:
	.loc 1 1064 1
	.cfi_startproc
	addi	sp,sp,-16
	.cfi_def_cfa_offset 16
	sw	ra,12(sp)
	sw	s0,8(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,16
	.cfi_def_cfa 8, 0
	.loc 1 1065 3
	call	rf_start
	.loc 1 1066 3
	lui	a5,%hi(rf_w)
	lw	a4,%lo(rf_w)(a5)
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a3,a5,-4
	lui	a5,%hi(rf_sp)
	sw	a3,%lo(rf_sp)(a5)
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	lw	a4,4(a4)
	sw	a4,0(a5)
	.loc 1 1067 3
	lui	a5,%hi(rf_fp)
	lui	a4,%hi(rf_next)
	addi	a4,a4,%lo(rf_next)
	sw	a4,%lo(rf_fp)(a5)
	.loc 1 1068 1
	nop
	lw	ra,12(sp)
	.cfi_restore 1
	lw	s0,8(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 16
	addi	sp,sp,16
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE59:
	.size	rf_code_docon, .-rf_code_docon
	.align	1
	.globl	rf_code_dovar
	.type	rf_code_dovar, @function
rf_code_dovar:
.LFB60:
	.loc 1 1073 1
	.cfi_startproc
	addi	sp,sp,-16
	.cfi_def_cfa_offset 16
	sw	ra,12(sp)
	sw	s0,8(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,16
	.cfi_def_cfa 8, 0
	.loc 1 1074 3
	call	rf_start
	.loc 1 1075 3
	lui	a5,%hi(rf_w)
	lw	a5,%lo(rf_w)(a5)
	addi	a3,a5,4
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a4,a5,-4
	lui	a5,%hi(rf_sp)
	sw	a4,%lo(rf_sp)(a5)
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	mv	a4,a3
	sw	a4,0(a5)
	.loc 1 1076 3
	lui	a5,%hi(rf_fp)
	lui	a4,%hi(rf_next)
	addi	a4,a4,%lo(rf_next)
	sw	a4,%lo(rf_fp)(a5)
	.loc 1 1077 1
	nop
	lw	ra,12(sp)
	.cfi_restore 1
	lw	s0,8(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 16
	addi	sp,sp,16
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE60:
	.size	rf_code_dovar, .-rf_code_dovar
	.align	1
	.globl	rf_code_douse
	.type	rf_code_douse, @function
rf_code_douse:
.LFB61:
	.loc 1 1082 1
	.cfi_startproc
	addi	sp,sp,-32
	.cfi_def_cfa_offset 32
	sw	ra,28(sp)
	sw	s0,24(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,32
	.cfi_def_cfa 8, 0
	.loc 1 1083 3
	call	rf_start
.LBB33:
	.loc 1 1087 9
	lui	a5,%hi(rf_w)
	lw	a5,%lo(rf_w)(a5)
	lw	a5,4(a5)
	sw	a5,-20(s0)
	.loc 1 1088 5
	lui	a5,%hi(rf_up)
	lw	a4,%lo(rf_up)(a5)
	lw	a5,-20(s0)
	add	a3,a4,a5
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a4,a5,-4
	lui	a5,%hi(rf_sp)
	sw	a4,%lo(rf_sp)(a5)
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	mv	a4,a3
	sw	a4,0(a5)
.LBE33:
	.loc 1 1090 3
	lui	a5,%hi(rf_fp)
	lui	a4,%hi(rf_next)
	addi	a4,a4,%lo(rf_next)
	sw	a4,%lo(rf_fp)(a5)
	.loc 1 1091 1
	nop
	lw	ra,28(sp)
	.cfi_restore 1
	lw	s0,24(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 32
	addi	sp,sp,32
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE61:
	.size	rf_code_douse, .-rf_code_douse
	.align	1
	.globl	rf_code_stod
	.type	rf_code_stod, @function
rf_code_stod:
.LFB62:
	.loc 1 1096 1
	.cfi_startproc
	addi	sp,sp,-32
	.cfi_def_cfa_offset 32
	sw	ra,28(sp)
	sw	s0,24(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,32
	.cfi_def_cfa 8, 0
	.loc 1 1097 3
	call	rf_start
.LBB34:
	.loc 1 1101 9
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a3,a5,4
	lui	a4,%hi(rf_sp)
	sw	a3,%lo(rf_sp)(a4)
	lw	a5,0(a5)
	.loc 1 1101 7
	sw	a5,-20(s0)
	.loc 1 1102 5
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a4,a5,-4
	lui	a5,%hi(rf_sp)
	sw	a4,%lo(rf_sp)(a5)
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	lw	a4,-20(s0)
	sw	a4,0(a5)
	.loc 1 1103 5
	lw	a5,-20(s0)
	bge	a5,zero,.L100
	.loc 1 1103 5 is_stmt 0 discriminator 1
	li	a5,-1
	j	.L101
.L100:
	.loc 1 1103 5 discriminator 2
	li	a5,0
.L101:
	.loc 1 1103 5 discriminator 4
	lui	a4,%hi(rf_sp)
	lw	a4,%lo(rf_sp)(a4)
	addi	a3,a4,-4
	lui	a4,%hi(rf_sp)
	sw	a3,%lo(rf_sp)(a4)
	lui	a4,%hi(rf_sp)
	lw	a4,%lo(rf_sp)(a4)
	sw	a5,0(a4)
.LBE34:
	.loc 1 1105 3 is_stmt 1
	lui	a5,%hi(rf_fp)
	lui	a4,%hi(rf_next)
	addi	a4,a4,%lo(rf_next)
	sw	a4,%lo(rf_fp)(a5)
	.loc 1 1106 1
	nop
	lw	ra,28(sp)
	.cfi_restore 1
	lw	s0,24(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 32
	addi	sp,sp,32
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE62:
	.size	rf_code_stod, .-rf_code_stod
	.align	1
	.type	rf_cold, @function
rf_cold:
.LFB63:
	.loc 1 1111 1
	.cfi_startproc
	addi	sp,sp,-32
	.cfi_def_cfa_offset 32
	sw	ra,28(sp)
	sw	s0,24(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,32
	.cfi_def_cfa 8, 0
	.loc 1 1113 14
	lui	a5,%hi(rf_origin)
	lw	a5,%lo(rf_origin)(a5)
	sw	a5,-24(s0)
	.loc 1 1118 25
	lw	a5,-24(s0)
	addi	a5,a5,84
	lw	a5,0(a5)
	.loc 1 1118 5
	mv	a4,a5
	.loc 1 1118 31
	lw	a5,-24(s0)
	lw	a5,24(a5)
	sw	a5,0(a4)
	.loc 1 1121 5
	li	a5,10
	sw	a5,-20(s0)
	.loc 1 1128 31
	lw	a5,-24(s0)
	addi	a5,a5,32
	lw	a5,0(a5)
	.loc 1 1128 11
	mv	a4,a5
	.loc 1 1128 9
	lui	a5,%hi(rf_up)
	sw	a4,%lo(rf_up)(a5)
	.loc 1 1134 3
	j	.L103
.L104:
	.loc 1 1135 22
	lw	a5,-20(s0)
	addi	a5,a5,6
	slli	a5,a5,2
	lw	a4,-24(s0)
	add	a4,a4,a5
	.loc 1 1135 10
	lui	a5,%hi(rf_up)
	lw	a3,%lo(rf_up)(a5)
	lw	a5,-20(s0)
	slli	a5,a5,2
	add	a5,a3,a5
	.loc 1 1135 22
	lw	a4,0(a4)
	.loc 1 1135 14
	sw	a4,0(a5)
	.loc 1 1134 18 discriminator 2
	lw	a5,-20(s0)
	addi	a5,a5,-1
	sw	a5,-20(s0)
.L103:
	.loc 1 1134 12 discriminator 1
	lw	a5,-20(s0)
	bge	a5,zero,.L104
	.loc 1 1141 31
	lw	a5,-24(s0)
	addi	a5,a5,88
	lw	a5,0(a5)
	.loc 1 1141 11
	mv	a4,a5
	.loc 1 1141 9
	lui	a5,%hi(rf_ip)
	sw	a4,%lo(rf_ip)(a5)
	.loc 1 1145 3
	lui	a5,%hi(rf_fp)
	lui	a4,%hi(rf_code_rpsto)
	addi	a4,a4,%lo(rf_code_rpsto)
	sw	a4,%lo(rf_fp)(a5)
	.loc 1 1146 1
	nop
	lw	ra,28(sp)
	.cfi_restore 1
	lw	s0,24(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 32
	addi	sp,sp,32
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE63:
	.size	rf_cold, .-rf_cold
	.align	1
	.globl	rf_code_cold
	.type	rf_code_cold, @function
rf_code_cold:
.LFB64:
	.loc 1 1149 1
	.cfi_startproc
	addi	sp,sp,-16
	.cfi_def_cfa_offset 16
	sw	ra,12(sp)
	sw	s0,8(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,16
	.cfi_def_cfa 8, 0
	.loc 1 1150 3
	call	rf_start
	.loc 1 1151 3
	call	rf_cold
	.loc 1 1152 1
	nop
	lw	ra,12(sp)
	.cfi_restore 1
	lw	s0,8(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 16
	addi	sp,sp,16
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE64:
	.size	rf_code_cold, .-rf_code_cold
	.align	1
	.globl	rf_code_mon
	.type	rf_code_mon, @function
rf_code_mon:
.LFB65:
	.loc 1 1157 1
	.cfi_startproc
	addi	sp,sp,-16
	.cfi_def_cfa_offset 16
	sw	ra,12(sp)
	sw	s0,8(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,16
	.cfi_def_cfa 8, 0
	.loc 1 1158 3
	call	rf_start
	.loc 1 1159 9
	lui	a5,%hi(rf_fp)
	sw	zero,%lo(rf_fp)(a5)
	.loc 1 1160 1
	nop
	lw	ra,12(sp)
	.cfi_restore 1
	lw	s0,8(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 16
	addi	sp,sp,16
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE65:
	.size	rf_code_mon, .-rf_code_mon
	.align	1
	.globl	rf_code_cl
	.type	rf_code_cl, @function
rf_code_cl:
.LFB66:
	.loc 1 1165 1
	.cfi_startproc
	addi	sp,sp,-16
	.cfi_def_cfa_offset 16
	sw	ra,12(sp)
	sw	s0,8(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,16
	.cfi_def_cfa 8, 0
	.loc 1 1166 3
	call	rf_start
	.loc 1 1167 3
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	addi	a4,a5,-4
	lui	a5,%hi(rf_sp)
	sw	a4,%lo(rf_sp)(a5)
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	li	a4,4
	sw	a4,0(a5)
	.loc 1 1168 3
	lui	a5,%hi(rf_fp)
	lui	a4,%hi(rf_next)
	addi	a4,a4,%lo(rf_next)
	sw	a4,%lo(rf_fp)(a5)
	.loc 1 1169 1
	nop
	lw	ra,12(sp)
	.cfi_restore 1
	lw	s0,8(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 16
	addi	sp,sp,16
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE66:
	.size	rf_code_cl, .-rf_code_cl
	.align	1
	.globl	rf_code_cs
	.type	rf_code_cs, @function
rf_code_cs:
.LFB67:
	.loc 1 1174 1
	.cfi_startproc
	addi	sp,sp,-16
	.cfi_def_cfa_offset 16
	sw	ra,12(sp)
	sw	s0,8(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,16
	.cfi_def_cfa 8, 0
	.loc 1 1175 3
	call	rf_start
	.loc 1 1177 5
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	lw	a4,0(a5)
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	.loc 1 1177 12
	slli	a4,a4,2
	sw	a4,0(a5)
	.loc 1 1179 3
	lui	a5,%hi(rf_fp)
	lui	a4,%hi(rf_next)
	addi	a4,a4,%lo(rf_next)
	sw	a4,%lo(rf_fp)(a5)
	.loc 1 1180 1
	nop
	lw	ra,12(sp)
	.cfi_restore 1
	lw	s0,8(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 16
	addi	sp,sp,16
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE67:
	.size	rf_code_cs, .-rf_code_cs
	.align	1
	.globl	rf_code_ln
	.type	rf_code_ln, @function
rf_code_ln:
.LFB68:
	.loc 1 1185 1
	.cfi_startproc
	addi	sp,sp,-16
	.cfi_def_cfa_offset 16
	sw	ra,12(sp)
	sw	s0,8(sp)
	.cfi_offset 1, -4
	.cfi_offset 8, -8
	addi	s0,sp,16
	.cfi_def_cfa 8, 0
	.loc 1 1186 3
	call	rf_start
	.loc 1 1189 8
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	lw	a4,0(a5)
	.loc 1 1189 5
	addi	a4,a4,-1
	sw	a4,0(a5)
	.loc 1 1190 5
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	lw	a4,0(a5)
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	.loc 1 1190 12
	ori	a4,a4,3
	sw	a4,0(a5)
	.loc 1 1191 8
	lui	a5,%hi(rf_sp)
	lw	a5,%lo(rf_sp)(a5)
	lw	a4,0(a5)
	.loc 1 1191 5
	addi	a4,a4,1
	sw	a4,0(a5)
	.loc 1 1194 3
	lui	a5,%hi(rf_fp)
	lui	a4,%hi(rf_next)
	addi	a4,a4,%lo(rf_next)
	sw	a4,%lo(rf_fp)(a5)
	.loc 1 1195 1
	nop
	lw	ra,12(sp)
	.cfi_restore 1
	lw	s0,8(sp)
	.cfi_restore 8
	.cfi_def_cfa 2, 16
	addi	sp,sp,16
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE68:
	.size	rf_code_ln, .-rf_code_ln
.Letext0:
	.file 2 ".pico-sdk/toolchain/RISCV_RPI_2_0_0_5/riscv32-unknown-elf/include/machine/_default_types.h"
	.file 3 ".pico-sdk/toolchain/RISCV_RPI_2_0_0_5/riscv32-unknown-elf/include/sys/_stdint.h"
	.file 4 "rf.h"
	.file 5 "system.inc"
	.section	.debug_info,"",@progbits
.Ldebug_info0:
	.4byte	0xfc0
	.2byte	0x5
	.byte	0x1
	.byte	0x4
	.4byte	.Ldebug_abbrev0
	.uleb128 0x15
	.4byte	.LASF111
	.byte	0x1d
	.4byte	.LASF0
	.4byte	.LASF1
	.4byte	.Ltext0
	.4byte	.Letext0-.Ltext0
	.4byte	.Ldebug_line0
	.uleb128 0x7
	.byte	0x1
	.byte	0x6
	.4byte	.LASF2
	.uleb128 0x8
	.4byte	.LASF9
	.byte	0x2
	.byte	0x2b
	.byte	0x18
	.4byte	0x39
	.uleb128 0x7
	.byte	0x1
	.byte	0x8
	.4byte	.LASF3
	.uleb128 0x7
	.byte	0x2
	.byte	0x5
	.4byte	.LASF4
	.uleb128 0x7
	.byte	0x2
	.byte	0x7
	.4byte	.LASF5
	.uleb128 0x7
	.byte	0x4
	.byte	0x5
	.4byte	.LASF6
	.uleb128 0x7
	.byte	0x4
	.byte	0x7
	.4byte	.LASF7
	.uleb128 0x7
	.byte	0x8
	.byte	0x5
	.4byte	.LASF8
	.uleb128 0x8
	.4byte	.LASF10
	.byte	0x2
	.byte	0x69
	.byte	0x19
	.4byte	0x6f
	.uleb128 0x7
	.byte	0x8
	.byte	0x7
	.4byte	.LASF11
	.uleb128 0x8
	.4byte	.LASF12
	.byte	0x2
	.byte	0xe6
	.byte	0x19
	.4byte	0x82
	.uleb128 0x16
	.byte	0x4
	.byte	0x5
	.string	"int"
	.uleb128 0x8
	.4byte	.LASF13
	.byte	0x2
	.byte	0xe8
	.byte	0x1a
	.4byte	0x95
	.uleb128 0x7
	.byte	0x4
	.byte	0x7
	.4byte	.LASF14
	.uleb128 0x8
	.4byte	.LASF15
	.byte	0x3
	.byte	0x18
	.byte	0x13
	.4byte	0x2d
	.uleb128 0x8
	.4byte	.LASF16
	.byte	0x3
	.byte	0x3c
	.byte	0x14
	.4byte	0x63
	.uleb128 0x8
	.4byte	.LASF17
	.byte	0x3
	.byte	0x4d
	.byte	0x14
	.4byte	0x76
	.uleb128 0x8
	.4byte	.LASF18
	.byte	0x3
	.byte	0x52
	.byte	0x15
	.4byte	0x89
	.uleb128 0x8
	.4byte	.LASF19
	.byte	0x4
	.byte	0xc
	.byte	0x12
	.4byte	0xa8
	.uleb128 0x17
	.4byte	.LASF21
	.byte	0x5
	.byte	0x4e
	.byte	0xe
	.4byte	0xe4
	.uleb128 0x9
	.4byte	0xe9
	.uleb128 0x7
	.byte	0x1
	.byte	0x8
	.4byte	.LASF20
	.uleb128 0xb
	.4byte	.LASF22
	.2byte	0x144
	.byte	0x13
	.4byte	0xfc
	.uleb128 0x9
	.4byte	0xc0
	.uleb128 0xb
	.4byte	.LASF23
	.2byte	0x155
	.byte	0x13
	.4byte	0xfc
	.uleb128 0xb
	.4byte	.LASF24
	.2byte	0x166
	.byte	0x13
	.4byte	0xfc
	.uleb128 0x18
	.4byte	.LASF25
	.byte	0x4
	.2byte	0x169
	.byte	0x10
	.4byte	0x126
	.uleb128 0x9
	.4byte	0x12b
	.uleb128 0x19
	.uleb128 0xb
	.4byte	.LASF26
	.2byte	0x16b
	.byte	0x13
	.4byte	0x138
	.uleb128 0x9
	.4byte	0x119
	.uleb128 0xb
	.4byte	.LASF27
	.2byte	0x16e
	.byte	0x13
	.4byte	0xfc
	.uleb128 0xb
	.4byte	.LASF28
	.2byte	0x173
	.byte	0x12
	.4byte	0x119
	.uleb128 0xc
	.4byte	0xf0
	.byte	0x9
	.byte	0xc
	.uleb128 0x5
	.byte	0x3
	.4byte	rf_sp
	.uleb128 0xc
	.4byte	0x101
	.byte	0x1a
	.byte	0xc
	.uleb128 0x5
	.byte	0x3
	.4byte	rf_rp
	.uleb128 0xc
	.4byte	0x10d
	.byte	0x2b
	.byte	0xc
	.uleb128 0x5
	.byte	0x3
	.4byte	rf_ip
	.uleb128 0xc
	.4byte	0x12c
	.byte	0x30
	.byte	0xc
	.uleb128 0x5
	.byte	0x3
	.4byte	rf_w
	.uleb128 0xc
	.4byte	0x13d
	.byte	0x35
	.byte	0xc
	.uleb128 0x5
	.byte	0x3
	.4byte	rf_up
	.uleb128 0xc
	.4byte	0x149
	.byte	0x3c
	.byte	0xb
	.uleb128 0x5
	.byte	0x3
	.4byte	rf_fp
	.uleb128 0x6
	.4byte	.LASF29
	.2byte	0x4a0
	.4byte	.LFB68
	.4byte	.LFE68-.LFB68
	.uleb128 0x1
	.byte	0x9c
	.uleb128 0x6
	.4byte	.LASF30
	.2byte	0x495
	.4byte	.LFB67
	.4byte	.LFE67-.LFB67
	.uleb128 0x1
	.byte	0x9c
	.uleb128 0x6
	.4byte	.LASF31
	.2byte	0x48c
	.4byte	.LFB66
	.4byte	.LFE66-.LFB66
	.uleb128 0x1
	.byte	0x9c
	.uleb128 0x6
	.4byte	.LASF32
	.2byte	0x484
	.4byte	.LFB65
	.4byte	.LFE65-.LFB65
	.uleb128 0x1
	.byte	0x9c
	.uleb128 0x6
	.4byte	.LASF33
	.2byte	0x47c
	.4byte	.LFB64
	.4byte	.LFE64-.LFB64
	.uleb128 0x1
	.byte	0x9c
	.uleb128 0x11
	.4byte	.LASF54
	.2byte	0x456
	.4byte	.LFB63
	.4byte	.LFE63-.LFB63
	.uleb128 0x1
	.byte	0x9c
	.4byte	0x22a
	.uleb128 0x1
	.string	"i"
	.2byte	0x458
	.byte	0x7
	.4byte	0x82
	.uleb128 0x2
	.byte	0x91
	.sleb128 -20
	.uleb128 0x5
	.4byte	.LASF34
	.2byte	0x459
	.byte	0xe
	.4byte	0xfc
	.uleb128 0x2
	.byte	0x91
	.sleb128 -24
	.byte	0
	.uleb128 0x4
	.4byte	.LASF35
	.2byte	0x447
	.4byte	.LFB62
	.4byte	.LFE62-.LFB62
	.uleb128 0x1
	.byte	0x9c
	.4byte	0x257
	.uleb128 0x2
	.4byte	.LBB34
	.4byte	.LBE34-.LBB34
	.uleb128 0x1
	.string	"a"
	.2byte	0x44b
	.byte	0xe
	.4byte	0xb4
	.uleb128 0x2
	.byte	0x91
	.sleb128 -20
	.byte	0
	.byte	0
	.uleb128 0x4
	.4byte	.LASF36
	.2byte	0x439
	.4byte	.LFB61
	.4byte	.LFE61-.LFB61
	.uleb128 0x1
	.byte	0x9c
	.4byte	0x286
	.uleb128 0x2
	.4byte	.LBB33
	.4byte	.LBE33-.LBB33
	.uleb128 0x1
	.string	"idx"
	.2byte	0x43d
	.byte	0xf
	.4byte	0xc0
	.uleb128 0x2
	.byte	0x91
	.sleb128 -20
	.byte	0
	.byte	0
	.uleb128 0x6
	.4byte	.LASF37
	.2byte	0x430
	.4byte	.LFB60
	.4byte	.LFE60-.LFB60
	.uleb128 0x1
	.byte	0x9c
	.uleb128 0x6
	.4byte	.LASF38
	.2byte	0x427
	.4byte	.LFB59
	.4byte	.LFE59-.LFB59
	.uleb128 0x1
	.byte	0x9c
	.uleb128 0x6
	.4byte	.LASF39
	.2byte	0x41d
	.4byte	.LFB58
	.4byte	.LFE58-.LFB58
	.uleb128 0x1
	.byte	0x9c
	.uleb128 0x4
	.4byte	.LASF40
	.2byte	0x40d
	.4byte	.LFB57
	.4byte	.LFE57-.LFB57
	.uleb128 0x1
	.byte	0x9c
	.4byte	0x2f5
	.uleb128 0x2
	.4byte	.LBB32
	.4byte	.LBE32-.LBB32
	.uleb128 0x5
	.4byte	.LASF41
	.2byte	0x411
	.byte	0xe
	.4byte	0x2f5
	.uleb128 0x2
	.byte	0x91
	.sleb128 -20
	.uleb128 0x1
	.string	"c"
	.2byte	0x412
	.byte	0xd
	.4byte	0x9c
	.uleb128 0x2
	.byte	0x91
	.sleb128 -21
	.byte	0
	.byte	0
	.uleb128 0x9
	.4byte	0x9c
	.uleb128 0x4
	.4byte	.LASF42
	.2byte	0x3fd
	.4byte	.LFB56
	.4byte	.LFE56-.LFB56
	.uleb128 0x1
	.byte	0x9c
	.4byte	0x336
	.uleb128 0x2
	.4byte	.LBB31
	.4byte	.LBE31-.LBB31
	.uleb128 0x5
	.4byte	.LASF41
	.2byte	0x401
	.byte	0x10
	.4byte	0xfc
	.uleb128 0x2
	.byte	0x91
	.sleb128 -20
	.uleb128 0x1
	.string	"p"
	.2byte	0x402
	.byte	0xf
	.4byte	0xc0
	.uleb128 0x2
	.byte	0x91
	.sleb128 -24
	.byte	0
	.byte	0
	.uleb128 0x4
	.4byte	.LASF43
	.2byte	0x3ef
	.4byte	.LFB55
	.4byte	.LFE55-.LFB55
	.uleb128 0x1
	.byte	0x9c
	.4byte	0x365
	.uleb128 0x2
	.4byte	.LBB30
	.4byte	.LBE30-.LBB30
	.uleb128 0x5
	.4byte	.LASF41
	.2byte	0x3f3
	.byte	0xe
	.4byte	0x2f5
	.uleb128 0x2
	.byte	0x91
	.sleb128 -20
	.byte	0
	.byte	0
	.uleb128 0x4
	.4byte	.LASF44
	.2byte	0x3df
	.4byte	.LFB54
	.4byte	.LFE54-.LFB54
	.uleb128 0x1
	.byte	0x9c
	.4byte	0x3a3
	.uleb128 0x2
	.4byte	.LBB29
	.4byte	.LBE29-.LBB29
	.uleb128 0x5
	.4byte	.LASF41
	.2byte	0x3e3
	.byte	0x10
	.4byte	0xfc
	.uleb128 0x2
	.byte	0x91
	.sleb128 -20
	.uleb128 0x5
	.4byte	.LASF45
	.2byte	0x3e4
	.byte	0xf
	.4byte	0xc0
	.uleb128 0x2
	.byte	0x91
	.sleb128 -24
	.byte	0
	.byte	0
	.uleb128 0x4
	.4byte	.LASF46
	.2byte	0x3cf
	.4byte	.LFB53
	.4byte	.LFE53-.LFB53
	.uleb128 0x1
	.byte	0x9c
	.4byte	0x3e1
	.uleb128 0x2
	.4byte	.LBB28
	.4byte	.LBE28-.LBB28
	.uleb128 0x5
	.4byte	.LASF47
	.2byte	0x3d3
	.byte	0xa
	.4byte	0xe9
	.uleb128 0x2
	.byte	0x91
	.sleb128 -17
	.uleb128 0x5
	.4byte	.LASF41
	.2byte	0x3d4
	.byte	0xb
	.4byte	0xe4
	.uleb128 0x2
	.byte	0x91
	.sleb128 -24
	.byte	0
	.byte	0
	.uleb128 0x4
	.4byte	.LASF48
	.2byte	0x3bf
	.4byte	.LFB52
	.4byte	.LFE52-.LFB52
	.uleb128 0x1
	.byte	0x9c
	.4byte	0x41d
	.uleb128 0x2
	.4byte	.LBB27
	.4byte	.LBE27-.LBB27
	.uleb128 0x5
	.4byte	.LASF41
	.2byte	0x3c3
	.byte	0x10
	.4byte	0xfc
	.uleb128 0x2
	.byte	0x91
	.sleb128 -20
	.uleb128 0x1
	.string	"n"
	.2byte	0x3c4
	.byte	0xe
	.4byte	0xb4
	.uleb128 0x2
	.byte	0x91
	.sleb128 -24
	.byte	0
	.byte	0
	.uleb128 0x4
	.4byte	.LASF49
	.2byte	0x3b0
	.4byte	.LFB51
	.4byte	.LFE51-.LFB51
	.uleb128 0x1
	.byte	0x9c
	.4byte	0x44a
	.uleb128 0x2
	.4byte	.LBB26
	.4byte	.LBE26-.LBB26
	.uleb128 0x1
	.string	"a"
	.2byte	0x3b4
	.byte	0xf
	.4byte	0xc0
	.uleb128 0x2
	.byte	0x91
	.sleb128 -20
	.byte	0
	.byte	0
	.uleb128 0x4
	.4byte	.LASF50
	.2byte	0x39f
	.4byte	.LFB50
	.4byte	.LFE50-.LFB50
	.uleb128 0x1
	.byte	0x9c
	.4byte	0x484
	.uleb128 0x2
	.4byte	.LBB25
	.4byte	.LBE25-.LBB25
	.uleb128 0x1
	.string	"a"
	.2byte	0x3a3
	.byte	0xf
	.4byte	0xc0
	.uleb128 0x2
	.byte	0x91
	.sleb128 -20
	.uleb128 0x1
	.string	"b"
	.2byte	0x3a4
	.byte	0xf
	.4byte	0xc0
	.uleb128 0x2
	.byte	0x91
	.sleb128 -24
	.byte	0
	.byte	0
	.uleb128 0x6
	.4byte	.LASF51
	.2byte	0x396
	.4byte	.LFB49
	.4byte	.LFE49-.LFB49
	.uleb128 0x1
	.byte	0x9c
	.uleb128 0x4
	.4byte	.LASF52
	.2byte	0x384
	.4byte	.LFB48
	.4byte	.LFE48-.LFB48
	.uleb128 0x1
	.byte	0x9c
	.4byte	0x4cf
	.uleb128 0x2
	.4byte	.LBB24
	.4byte	.LBE24-.LBB24
	.uleb128 0x1
	.string	"a"
	.2byte	0x388
	.byte	0xf
	.4byte	0xc0
	.uleb128 0x2
	.byte	0x91
	.sleb128 -20
	.uleb128 0x1
	.string	"b"
	.2byte	0x389
	.byte	0xf
	.4byte	0xc0
	.uleb128 0x2
	.byte	0x91
	.sleb128 -24
	.byte	0
	.byte	0
	.uleb128 0x4
	.4byte	.LASF53
	.2byte	0x373
	.4byte	.LFB47
	.4byte	.LFE47-.LFB47
	.uleb128 0x1
	.byte	0x9c
	.4byte	0x527
	.uleb128 0x2
	.4byte	.LBB23
	.4byte	.LBE23-.LBB23
	.uleb128 0x1
	.string	"bh"
	.2byte	0x377
	.byte	0xf
	.4byte	0xc0
	.uleb128 0x2
	.byte	0x91
	.sleb128 -20
	.uleb128 0x1
	.string	"bl"
	.2byte	0x377
	.byte	0x13
	.4byte	0xc0
	.uleb128 0x2
	.byte	0x91
	.sleb128 -24
	.uleb128 0x1
	.string	"ch"
	.2byte	0x377
	.byte	0x17
	.4byte	0xc0
	.uleb128 0x2
	.byte	0x91
	.sleb128 -28
	.uleb128 0x1
	.string	"cl"
	.2byte	0x377
	.byte	0x1b
	.4byte	0xc0
	.uleb128 0x2
	.byte	0x91
	.sleb128 -32
	.byte	0
	.byte	0
	.uleb128 0x12
	.4byte	.LASF55
	.2byte	0x361
	.4byte	.LFB46
	.4byte	.LFE46-.LFB46
	.uleb128 0x1
	.byte	0x9c
	.4byte	0x582
	.uleb128 0x3
	.string	"bh"
	.2byte	0x361
	.byte	0x20
	.4byte	0xc0
	.uleb128 0x2
	.byte	0x91
	.sleb128 -36
	.uleb128 0x3
	.string	"bl"
	.2byte	0x361
	.byte	0x2e
	.4byte	0xc0
	.uleb128 0x2
	.byte	0x91
	.sleb128 -40
	.uleb128 0x3
	.string	"ch"
	.2byte	0x361
	.byte	0x3d
	.4byte	0xfc
	.uleb128 0x2
	.byte	0x91
	.sleb128 -44
	.uleb128 0x3
	.string	"cl"
	.2byte	0x361
	.byte	0x4c
	.4byte	0xfc
	.uleb128 0x2
	.byte	0x91
	.sleb128 -48
	.uleb128 0x1
	.string	"d"
	.2byte	0x363
	.byte	0xf
	.4byte	0xcc
	.uleb128 0x2
	.byte	0x91
	.sleb128 -24
	.byte	0
	.uleb128 0x4
	.4byte	.LASF56
	.2byte	0x351
	.4byte	.LFB45
	.4byte	.LFE45-.LFB45
	.uleb128 0x1
	.byte	0x9c
	.4byte	0x5af
	.uleb128 0x2
	.4byte	.LBB22
	.4byte	.LBE22-.LBB22
	.uleb128 0x1
	.string	"a"
	.2byte	0x355
	.byte	0xf
	.4byte	0xc0
	.uleb128 0x2
	.byte	0x91
	.sleb128 -20
	.byte	0
	.byte	0
	.uleb128 0x4
	.4byte	.LASF57
	.2byte	0x33e
	.4byte	.LFB44
	.4byte	.LFE44-.LFB44
	.uleb128 0x1
	.byte	0x9c
	.4byte	0x623
	.uleb128 0x2
	.4byte	.LBB21
	.4byte	.LBE21-.LBB21
	.uleb128 0x1
	.string	"ah"
	.2byte	0x342
	.byte	0xf
	.4byte	0xc0
	.uleb128 0x2
	.byte	0x91
	.sleb128 -20
	.uleb128 0x1
	.string	"al"
	.2byte	0x342
	.byte	0x13
	.4byte	0xc0
	.uleb128 0x2
	.byte	0x91
	.sleb128 -24
	.uleb128 0x1
	.string	"bh"
	.2byte	0x342
	.byte	0x17
	.4byte	0xc0
	.uleb128 0x2
	.byte	0x91
	.sleb128 -28
	.uleb128 0x1
	.string	"bl"
	.2byte	0x342
	.byte	0x1b
	.4byte	0xc0
	.uleb128 0x2
	.byte	0x91
	.sleb128 -32
	.uleb128 0x1
	.string	"ch"
	.2byte	0x342
	.byte	0x1f
	.4byte	0xc0
	.uleb128 0x2
	.byte	0x91
	.sleb128 -36
	.uleb128 0x1
	.string	"cl"
	.2byte	0x342
	.byte	0x23
	.4byte	0xc0
	.uleb128 0x2
	.byte	0x91
	.sleb128 -40
	.byte	0
	.byte	0
	.uleb128 0x12
	.4byte	.LASF58
	.2byte	0x329
	.4byte	.LFB43
	.4byte	.LFE43-.LFB43
	.uleb128 0x1
	.byte	0x9c
	.4byte	0x6b6
	.uleb128 0x3
	.string	"ah"
	.2byte	0x329
	.byte	0x20
	.4byte	0xc0
	.uleb128 0x2
	.byte	0x91
	.sleb128 -52
	.uleb128 0x3
	.string	"al"
	.2byte	0x329
	.byte	0x2e
	.4byte	0xc0
	.uleb128 0x2
	.byte	0x91
	.sleb128 -56
	.uleb128 0x3
	.string	"bh"
	.2byte	0x329
	.byte	0x3c
	.4byte	0xc0
	.uleb128 0x2
	.byte	0x91
	.sleb128 -60
	.uleb128 0x3
	.string	"bl"
	.2byte	0x329
	.byte	0x4a
	.4byte	0xc0
	.uleb128 0x2
	.byte	0x91
	.sleb128 -64
	.uleb128 0x3
	.string	"ch"
	.2byte	0x329
	.byte	0x59
	.4byte	0xfc
	.uleb128 0x3
	.byte	0x91
	.sleb128 -68
	.uleb128 0x3
	.string	"cl"
	.2byte	0x329
	.byte	0x68
	.4byte	0xfc
	.uleb128 0x3
	.byte	0x91
	.sleb128 -72
	.uleb128 0x1
	.string	"a"
	.2byte	0x32b
	.byte	0xf
	.4byte	0xcc
	.uleb128 0x2
	.byte	0x91
	.sleb128 -32
	.uleb128 0x1
	.string	"b"
	.2byte	0x32c
	.byte	0xf
	.4byte	0xcc
	.uleb128 0x2
	.byte	0x91
	.sleb128 -40
	.uleb128 0x1
	.string	"c"
	.2byte	0x32d
	.byte	0xf
	.4byte	0xcc
	.uleb128 0x2
	.byte	0x91
	.sleb128 -24
	.byte	0
	.uleb128 0x4
	.4byte	.LASF59
	.2byte	0x317
	.4byte	.LFB42
	.4byte	.LFE42-.LFB42
	.uleb128 0x1
	.byte	0x9c
	.4byte	0x6f0
	.uleb128 0x2
	.4byte	.LBB20
	.4byte	.LBE20-.LBB20
	.uleb128 0x1
	.string	"a"
	.2byte	0x31b
	.byte	0xe
	.4byte	0xb4
	.uleb128 0x2
	.byte	0x91
	.sleb128 -20
	.uleb128 0x1
	.string	"b"
	.2byte	0x31c
	.byte	0xe
	.4byte	0xb4
	.uleb128 0x2
	.byte	0x91
	.sleb128 -24
	.byte	0
	.byte	0
	.uleb128 0x4
	.4byte	.LASF60
	.2byte	0x309
	.4byte	.LFB41
	.4byte	.LFE41-.LFB41
	.uleb128 0x1
	.byte	0x9c
	.4byte	0x71d
	.uleb128 0x2
	.4byte	.LBB19
	.4byte	.LBE19-.LBB19
	.uleb128 0x1
	.string	"a"
	.2byte	0x30d
	.byte	0xf
	.4byte	0xc0
	.uleb128 0x2
	.byte	0x91
	.sleb128 -20
	.byte	0
	.byte	0
	.uleb128 0x4
	.4byte	.LASF61
	.2byte	0x2fb
	.4byte	.LFB40
	.4byte	.LFE40-.LFB40
	.uleb128 0x1
	.byte	0x9c
	.4byte	0x74a
	.uleb128 0x2
	.4byte	.LBB18
	.4byte	.LBE18-.LBB18
	.uleb128 0x1
	.string	"a"
	.2byte	0x2ff
	.byte	0xf
	.4byte	0xc0
	.uleb128 0x2
	.byte	0x91
	.sleb128 -20
	.byte	0
	.byte	0
	.uleb128 0x6
	.4byte	.LASF62
	.2byte	0x2f2
	.4byte	.LFB39
	.4byte	.LFE39-.LFB39
	.uleb128 0x1
	.byte	0x9c
	.uleb128 0x6
	.4byte	.LASF63
	.2byte	0x2e9
	.4byte	.LFB38
	.4byte	.LFE38-.LFB38
	.uleb128 0x1
	.byte	0x9c
	.uleb128 0x4
	.4byte	.LASF64
	.2byte	0x2d9
	.4byte	.LFB37
	.4byte	.LFE37-.LFB37
	.uleb128 0x1
	.byte	0x9c
	.4byte	0x79b
	.uleb128 0x2
	.4byte	.LBB17
	.4byte	.LBE17-.LBB17
	.uleb128 0x5
	.4byte	.LASF65
	.2byte	0x2dd
	.byte	0xf
	.4byte	0xc0
	.uleb128 0x2
	.byte	0x91
	.sleb128 -20
	.byte	0
	.byte	0
	.uleb128 0x6
	.4byte	.LASF66
	.2byte	0x2d0
	.4byte	.LFB36
	.4byte	.LFE36-.LFB36
	.uleb128 0x1
	.byte	0x9c
	.uleb128 0x6
	.4byte	.LASF67
	.2byte	0x2c7
	.4byte	.LFB35
	.4byte	.LFE35-.LFB35
	.uleb128 0x1
	.byte	0x9c
	.uleb128 0x6
	.4byte	.LASF68
	.2byte	0x2be
	.4byte	.LFB34
	.4byte	.LFE34-.LFB34
	.uleb128 0x1
	.byte	0x9c
	.uleb128 0x4
	.4byte	.LASF69
	.2byte	0x2b0
	.4byte	.LFB33
	.4byte	.LFE33-.LFB33
	.uleb128 0x1
	.byte	0x9c
	.4byte	0x7fc
	.uleb128 0x2
	.4byte	.LBB16
	.4byte	.LBE16-.LBB16
	.uleb128 0x1
	.string	"sp"
	.2byte	0x2b4
	.byte	0xf
	.4byte	0xc0
	.uleb128 0x2
	.byte	0x91
	.sleb128 -20
	.byte	0
	.byte	0
	.uleb128 0x4
	.4byte	.LASF70
	.2byte	0x2a0
	.4byte	.LFB32
	.4byte	.LFE32-.LFB32
	.uleb128 0x1
	.byte	0x9c
	.4byte	0x836
	.uleb128 0x2
	.4byte	.LBB15
	.4byte	.LBE15-.LBB15
	.uleb128 0x1
	.string	"a"
	.2byte	0x2a4
	.byte	0xf
	.4byte	0xc0
	.uleb128 0x2
	.byte	0x91
	.sleb128 -20
	.uleb128 0x1
	.string	"b"
	.2byte	0x2a5
	.byte	0xf
	.4byte	0xc0
	.uleb128 0x2
	.byte	0x91
	.sleb128 -24
	.byte	0
	.byte	0
	.uleb128 0x4
	.4byte	.LASF71
	.2byte	0x290
	.4byte	.LFB31
	.4byte	.LFE31-.LFB31
	.uleb128 0x1
	.byte	0x9c
	.4byte	0x870
	.uleb128 0x2
	.4byte	.LBB14
	.4byte	.LBE14-.LBB14
	.uleb128 0x1
	.string	"a"
	.2byte	0x294
	.byte	0xf
	.4byte	0xc0
	.uleb128 0x2
	.byte	0x91
	.sleb128 -20
	.uleb128 0x1
	.string	"b"
	.2byte	0x295
	.byte	0xf
	.4byte	0xc0
	.uleb128 0x2
	.byte	0x91
	.sleb128 -24
	.byte	0
	.byte	0
	.uleb128 0x4
	.4byte	.LASF72
	.2byte	0x280
	.4byte	.LFB30
	.4byte	.LFE30-.LFB30
	.uleb128 0x1
	.byte	0x9c
	.4byte	0x8aa
	.uleb128 0x2
	.4byte	.LBB13
	.4byte	.LBE13-.LBB13
	.uleb128 0x1
	.string	"a"
	.2byte	0x284
	.byte	0xf
	.4byte	0xc0
	.uleb128 0x2
	.byte	0x91
	.sleb128 -20
	.uleb128 0x1
	.string	"b"
	.2byte	0x285
	.byte	0xf
	.4byte	0xc0
	.uleb128 0x2
	.byte	0x91
	.sleb128 -24
	.byte	0
	.byte	0
	.uleb128 0x4
	.4byte	.LASF73
	.2byte	0x26e
	.4byte	.LFB29
	.4byte	.LFE29-.LFB29
	.uleb128 0x1
	.byte	0x9c
	.4byte	0x90d
	.uleb128 0x2
	.4byte	.LBB12
	.4byte	.LBE12-.LBB12
	.uleb128 0x1
	.string	"ah"
	.2byte	0x272
	.byte	0xf
	.4byte	0xc0
	.uleb128 0x2
	.byte	0x91
	.sleb128 -24
	.uleb128 0x1
	.string	"al"
	.2byte	0x272
	.byte	0x13
	.4byte	0xc0
	.uleb128 0x2
	.byte	0x91
	.sleb128 -28
	.uleb128 0x1
	.string	"b"
	.2byte	0x272
	.byte	0x17
	.4byte	0xc0
	.uleb128 0x2
	.byte	0x91
	.sleb128 -20
	.uleb128 0x1
	.string	"q"
	.2byte	0x272
	.byte	0x1a
	.4byte	0xc0
	.uleb128 0x2
	.byte	0x91
	.sleb128 -32
	.uleb128 0x1
	.string	"r"
	.2byte	0x272
	.byte	0x1d
	.4byte	0xc0
	.uleb128 0x2
	.byte	0x91
	.sleb128 -36
	.byte	0
	.byte	0
	.uleb128 0x13
	.4byte	.LASF87
	.2byte	0x233
	.byte	0x12
	.4byte	0xc0
	.4byte	.LFB28
	.4byte	.LFE28-.LFB28
	.uleb128 0x1
	.byte	0x9c
	.4byte	0x978
	.uleb128 0x3
	.string	"uh"
	.2byte	0x233
	.byte	0x25
	.4byte	0xc0
	.uleb128 0x2
	.byte	0x91
	.sleb128 -36
	.uleb128 0x3
	.string	"ul"
	.2byte	0x233
	.byte	0x33
	.4byte	0xc0
	.uleb128 0x2
	.byte	0x91
	.sleb128 -40
	.uleb128 0x3
	.string	"v"
	.2byte	0x233
	.byte	0x41
	.4byte	0xc0
	.uleb128 0x2
	.byte	0x91
	.sleb128 -44
	.uleb128 0x3
	.string	"r"
	.2byte	0x233
	.byte	0x4f
	.4byte	0xfc
	.uleb128 0x2
	.byte	0x91
	.sleb128 -48
	.uleb128 0x1
	.string	"a"
	.2byte	0x235
	.byte	0xf
	.4byte	0xcc
	.uleb128 0x2
	.byte	0x91
	.sleb128 -24
	.uleb128 0x1
	.string	"b"
	.2byte	0x235
	.byte	0x12
	.4byte	0xcc
	.uleb128 0x2
	.byte	0x91
	.sleb128 -32
	.byte	0
	.uleb128 0x4
	.4byte	.LASF74
	.2byte	0x220
	.4byte	.LFB27
	.4byte	.LFE27-.LFB27
	.uleb128 0x1
	.byte	0x9c
	.4byte	0x9ce
	.uleb128 0x2
	.4byte	.LBB11
	.4byte	.LBE11-.LBB11
	.uleb128 0x1
	.string	"a"
	.2byte	0x224
	.byte	0xf
	.4byte	0xc0
	.uleb128 0x2
	.byte	0x91
	.sleb128 -20
	.uleb128 0x1
	.string	"b"
	.2byte	0x224
	.byte	0x12
	.4byte	0xc0
	.uleb128 0x2
	.byte	0x91
	.sleb128 -24
	.uleb128 0x1
	.string	"ch"
	.2byte	0x224
	.byte	0x15
	.4byte	0xc0
	.uleb128 0x2
	.byte	0x91
	.sleb128 -28
	.uleb128 0x1
	.string	"cl"
	.2byte	0x224
	.byte	0x19
	.4byte	0xc0
	.uleb128 0x2
	.byte	0x91
	.sleb128 -32
	.byte	0
	.byte	0
	.uleb128 0x12
	.4byte	.LASF75
	.2byte	0x1ef
	.4byte	.LFB26
	.4byte	.LFE26-.LFB26
	.uleb128 0x1
	.byte	0x9c
	.4byte	0xa27
	.uleb128 0x3
	.string	"a"
	.2byte	0x1ef
	.byte	0x20
	.4byte	0xc0
	.uleb128 0x2
	.byte	0x91
	.sleb128 -36
	.uleb128 0x3
	.string	"b"
	.2byte	0x1ef
	.byte	0x2d
	.4byte	0xc0
	.uleb128 0x2
	.byte	0x91
	.sleb128 -40
	.uleb128 0x3
	.string	"ch"
	.2byte	0x1ef
	.byte	0x3b
	.4byte	0xfc
	.uleb128 0x2
	.byte	0x91
	.sleb128 -44
	.uleb128 0x3
	.string	"cl"
	.2byte	0x1ef
	.byte	0x4a
	.4byte	0xfc
	.uleb128 0x2
	.byte	0x91
	.sleb128 -48
	.uleb128 0x1
	.string	"d"
	.2byte	0x1f1
	.byte	0xf
	.4byte	0xcc
	.uleb128 0x2
	.byte	0x91
	.sleb128 -24
	.byte	0
	.uleb128 0x11
	.4byte	.LASF76
	.2byte	0x1e5
	.4byte	.LFB25
	.4byte	.LFE25-.LFB25
	.uleb128 0x1
	.byte	0x9c
	.4byte	0xa64
	.uleb128 0x3
	.string	"d"
	.2byte	0x1e5
	.byte	0x25
	.4byte	0xcc
	.uleb128 0x2
	.byte	0x91
	.sleb128 -24
	.uleb128 0x3
	.string	"h"
	.2byte	0x1e5
	.byte	0x33
	.4byte	0xfc
	.uleb128 0x2
	.byte	0x91
	.sleb128 -28
	.uleb128 0x3
	.string	"l"
	.2byte	0x1e5
	.byte	0x41
	.4byte	0xfc
	.uleb128 0x2
	.byte	0x91
	.sleb128 -32
	.byte	0
	.uleb128 0x11
	.4byte	.LASF77
	.2byte	0x1dc
	.4byte	.LFB24
	.4byte	.LFE24-.LFB24
	.uleb128 0x1
	.byte	0x9c
	.4byte	0xabb
	.uleb128 0x3
	.string	"h"
	.2byte	0x1dc
	.byte	0x21
	.4byte	0xc0
	.uleb128 0x2
	.byte	0x91
	.sleb128 -36
	.uleb128 0x3
	.string	"l"
	.2byte	0x1dc
	.byte	0x2e
	.4byte	0xc0
	.uleb128 0x2
	.byte	0x91
	.sleb128 -40
	.uleb128 0x3
	.string	"d"
	.2byte	0x1dc
	.byte	0x3e
	.4byte	0xabb
	.uleb128 0x2
	.byte	0x91
	.sleb128 -44
	.uleb128 0x1
	.string	"a"
	.2byte	0x1de
	.byte	0xf
	.4byte	0xcc
	.uleb128 0x2
	.byte	0x91
	.sleb128 -24
	.uleb128 0x1
	.string	"b"
	.2byte	0x1df
	.byte	0xf
	.4byte	0xcc
	.uleb128 0x2
	.byte	0x91
	.sleb128 -32
	.byte	0
	.uleb128 0x9
	.4byte	0xcc
	.uleb128 0x4
	.4byte	.LASF78
	.2byte	0x1b0
	.4byte	.LFB23
	.4byte	.LFE23-.LFB23
	.uleb128 0x1
	.byte	0x9c
	.4byte	0xb0c
	.uleb128 0x2
	.4byte	.LBB10
	.4byte	.LBE10-.LBB10
	.uleb128 0x5
	.4byte	.LASF79
	.2byte	0x1b4
	.byte	0xf
	.4byte	0xc0
	.uleb128 0x2
	.byte	0x91
	.sleb128 -20
	.uleb128 0x1
	.string	"to"
	.2byte	0x1b5
	.byte	0xb
	.4byte	0xe4
	.uleb128 0x2
	.byte	0x91
	.sleb128 -24
	.uleb128 0x5
	.4byte	.LASF80
	.2byte	0x1b6
	.byte	0xb
	.4byte	0xe4
	.uleb128 0x2
	.byte	0x91
	.sleb128 -28
	.byte	0
	.byte	0
	.uleb128 0x6
	.4byte	.LASF81
	.2byte	0x1a7
	.4byte	.LFB22
	.4byte	.LFE22-.LFB22
	.uleb128 0x1
	.byte	0x9c
	.uleb128 0x12
	.4byte	.LASF82
	.2byte	0x198
	.4byte	.LFB21
	.4byte	.LFE21-.LFB21
	.uleb128 0x1
	.byte	0x9c
	.4byte	0xb79
	.uleb128 0x1
	.string	"c"
	.2byte	0x19a
	.byte	0x8
	.4byte	0xe9
	.uleb128 0x2
	.byte	0x91
	.sleb128 -17
	.uleb128 0x5
	.4byte	.LASF83
	.2byte	0x19b
	.byte	0x9
	.4byte	0xe4
	.uleb128 0x2
	.byte	0x91
	.sleb128 -24
	.uleb128 0x1
	.string	"n1"
	.2byte	0x19c
	.byte	0xb
	.4byte	0x9c
	.uleb128 0x2
	.byte	0x91
	.sleb128 -25
	.uleb128 0x1
	.string	"n2"
	.2byte	0x19c
	.byte	0xf
	.4byte	0x9c
	.uleb128 0x2
	.byte	0x91
	.sleb128 -26
	.uleb128 0x1
	.string	"n3"
	.2byte	0x19c
	.byte	0x13
	.4byte	0x9c
	.uleb128 0x2
	.byte	0x91
	.sleb128 -27
	.byte	0
	.uleb128 0x11
	.4byte	.LASF84
	.2byte	0x171
	.4byte	.LFB20
	.4byte	.LFE20-.LFB20
	.uleb128 0x1
	.byte	0x9c
	.4byte	0xbf0
	.uleb128 0x3
	.string	"c"
	.2byte	0x171
	.byte	0x1d
	.4byte	0xe9
	.uleb128 0x2
	.byte	0x91
	.sleb128 -33
	.uleb128 0xe
	.4byte	.LASF83
	.2byte	0x171
	.byte	0x26
	.4byte	0xe4
	.uleb128 0x2
	.byte	0x91
	.sleb128 -40
	.uleb128 0x3
	.string	"s3"
	.2byte	0x171
	.byte	0x36
	.4byte	0x2f5
	.uleb128 0x2
	.byte	0x91
	.sleb128 -44
	.uleb128 0x3
	.string	"s2"
	.2byte	0x171
	.byte	0x43
	.4byte	0x2f5
	.uleb128 0x2
	.byte	0x91
	.sleb128 -48
	.uleb128 0x3
	.string	"s1"
	.2byte	0x171
	.byte	0x50
	.4byte	0x2f5
	.uleb128 0x2
	.byte	0x91
	.sleb128 -52
	.uleb128 0x1
	.string	"hl"
	.2byte	0x173
	.byte	0x9
	.4byte	0xe4
	.uleb128 0x2
	.byte	0x91
	.sleb128 -20
	.uleb128 0x1
	.string	"e"
	.2byte	0x174
	.byte	0xb
	.4byte	0x9c
	.uleb128 0x2
	.byte	0x91
	.sleb128 -21
	.byte	0
	.uleb128 0x4
	.4byte	.LASF85
	.2byte	0x15f
	.4byte	.LFB19
	.4byte	.LFE19-.LFB19
	.uleb128 0x1
	.byte	0x9c
	.4byte	0xc3b
	.uleb128 0x2
	.4byte	.LBB9
	.4byte	.LBE9-.LBB9
	.uleb128 0x5
	.4byte	.LASF86
	.2byte	0x163
	.byte	0xe
	.4byte	0x2f5
	.uleb128 0x2
	.byte	0x91
	.sleb128 -20
	.uleb128 0x5
	.4byte	.LASF83
	.2byte	0x164
	.byte	0xe
	.4byte	0x2f5
	.uleb128 0x2
	.byte	0x91
	.sleb128 -24
	.uleb128 0x1
	.string	"f"
	.2byte	0x165
	.byte	0xf
	.4byte	0xc0
	.uleb128 0x2
	.byte	0x91
	.sleb128 -28
	.byte	0
	.byte	0
	.uleb128 0x13
	.4byte	.LASF88
	.2byte	0x14f
	.byte	0x12
	.4byte	0xc0
	.4byte	.LFB18
	.4byte	.LFE18-.LFB18
	.uleb128 0x1
	.byte	0x9c
	.4byte	0xc90
	.uleb128 0xe
	.4byte	.LASF83
	.2byte	0x14f
	.byte	0x24
	.4byte	0x2f5
	.uleb128 0x2
	.byte	0x91
	.sleb128 -36
	.uleb128 0xe
	.4byte	.LASF86
	.2byte	0x14f
	.byte	0x34
	.4byte	0x2f5
	.uleb128 0x2
	.byte	0x91
	.sleb128 -40
	.uleb128 0x5
	.4byte	.LASF89
	.2byte	0x151
	.byte	0xb
	.4byte	0x9c
	.uleb128 0x2
	.byte	0x91
	.sleb128 -17
	.uleb128 0x1
	.string	"f"
	.2byte	0x152
	.byte	0xc
	.4byte	0x2f5
	.uleb128 0x2
	.byte	0x91
	.sleb128 -24
	.byte	0
	.uleb128 0x13
	.4byte	.LASF90
	.2byte	0x148
	.byte	0x20
	.4byte	0xfc
	.4byte	.LFB17
	.4byte	.LFE17-.LFB17
	.uleb128 0x1
	.byte	0x9c
	.4byte	0xcd8
	.uleb128 0x3
	.string	"nfa"
	.2byte	0x148
	.byte	0x30
	.4byte	0x2f5
	.uleb128 0x2
	.byte	0x91
	.sleb128 -36
	.uleb128 0x1
	.string	"lfa"
	.2byte	0x14a
	.byte	0xd
	.4byte	0xcd8
	.uleb128 0x2
	.byte	0x91
	.sleb128 -20
	.uleb128 0x1
	.string	"pfa"
	.2byte	0x14b
	.byte	0xe
	.4byte	0xfc
	.uleb128 0x2
	.byte	0x91
	.sleb128 -24
	.byte	0
	.uleb128 0x9
	.4byte	0x2f5
	.uleb128 0x13
	.4byte	.LASF91
	.2byte	0x131
	.byte	0x11
	.4byte	0x2f5
	.4byte	.LFB16
	.4byte	.LFE16-.LFB16
	.uleb128 0x1
	.byte	0x9c
	.4byte	0xd4a
	.uleb128 0x3
	.string	"t"
	.2byte	0x131
	.byte	0x22
	.4byte	0x2f5
	.uleb128 0x2
	.byte	0x91
	.sleb128 -36
	.uleb128 0xe
	.4byte	.LASF89
	.2byte	0x131
	.byte	0x2d
	.4byte	0x9c
	.uleb128 0x2
	.byte	0x91
	.sleb128 -37
	.uleb128 0x3
	.string	"nfa"
	.2byte	0x131
	.byte	0x3e
	.4byte	0x2f5
	.uleb128 0x2
	.byte	0x91
	.sleb128 -44
	.uleb128 0x1
	.string	"b"
	.2byte	0x133
	.byte	0xb
	.4byte	0x9c
	.uleb128 0x2
	.byte	0x91
	.sleb128 -25
	.uleb128 0x1
	.string	"m"
	.2byte	0x134
	.byte	0xc
	.4byte	0x2f5
	.uleb128 0x2
	.byte	0x91
	.sleb128 -20
	.uleb128 0x1
	.string	"n"
	.2byte	0x134
	.byte	0x10
	.4byte	0x2f5
	.uleb128 0x2
	.byte	0x91
	.sleb128 -24
	.byte	0
	.uleb128 0x14
	.4byte	.LASF92
	.2byte	0x12a
	.byte	0x1f
	.4byte	0xcd8
	.4byte	.LFB15
	.4byte	.LFE15-.LFB15
	.uleb128 0x1
	.byte	0x9c
	.4byte	0xd74
	.uleb128 0x3
	.string	"nfa"
	.2byte	0x12a
	.byte	0x2f
	.4byte	0x2f5
	.uleb128 0x2
	.byte	0x91
	.sleb128 -20
	.byte	0
	.uleb128 0x4
	.4byte	.LASF93
	.2byte	0x115
	.4byte	.LFB14
	.4byte	.LFE14-.LFB14
	.uleb128 0x1
	.byte	0x9c
	.4byte	0xdbb
	.uleb128 0x2
	.4byte	.LBB8
	.4byte	.LBE8-.LBB8
	.uleb128 0x1
	.string	"b"
	.2byte	0x119
	.byte	0xd
	.4byte	0x9c
	.uleb128 0x2
	.byte	0x91
	.sleb128 -17
	.uleb128 0x1
	.string	"c"
	.2byte	0x119
	.byte	0x10
	.4byte	0x9c
	.uleb128 0x2
	.byte	0x91
	.sleb128 -18
	.uleb128 0x1
	.string	"d"
	.2byte	0x119
	.byte	0x13
	.4byte	0x9c
	.uleb128 0x2
	.byte	0x91
	.sleb128 -19
	.byte	0
	.byte	0
	.uleb128 0x14
	.4byte	.LASF94
	.2byte	0x105
	.byte	0x10
	.4byte	0x9c
	.4byte	.LFB13
	.4byte	.LFE13-.LFB13
	.uleb128 0x1
	.byte	0x9c
	.4byte	0xdf2
	.uleb128 0xe
	.4byte	.LASF95
	.2byte	0x105
	.byte	0x21
	.4byte	0x9c
	.uleb128 0x2
	.byte	0x91
	.sleb128 -17
	.uleb128 0x3
	.string	"c"
	.2byte	0x105
	.byte	0x2f
	.4byte	0x9c
	.uleb128 0x2
	.byte	0x91
	.sleb128 -18
	.byte	0
	.uleb128 0xd
	.4byte	.LASF96
	.byte	0xf9
	.4byte	.LFB12
	.4byte	.LFE12-.LFB12
	.uleb128 0x1
	.byte	0x9c
	.4byte	0xe1d
	.uleb128 0x2
	.4byte	.LBB7
	.4byte	.LBE7-.LBB7
	.uleb128 0xa
	.string	"i"
	.byte	0xfd
	.byte	0xf
	.4byte	0xc0
	.uleb128 0x2
	.byte	0x91
	.sleb128 -20
	.byte	0
	.byte	0
	.uleb128 0xd
	.4byte	.LASF97
	.byte	0xe0
	.4byte	.LFB11
	.4byte	.LFE11-.LFB11
	.uleb128 0x1
	.byte	0x9c
	.4byte	0xe56
	.uleb128 0x2
	.4byte	.LBB6
	.4byte	.LBE6-.LBB6
	.uleb128 0xa
	.string	"p1"
	.byte	0xe4
	.byte	0x10
	.4byte	0xfc
	.uleb128 0x2
	.byte	0x91
	.sleb128 -20
	.uleb128 0xa
	.string	"p2"
	.byte	0xe5
	.byte	0x10
	.4byte	0xfc
	.uleb128 0x2
	.byte	0x91
	.sleb128 -24
	.byte	0
	.byte	0
	.uleb128 0xd
	.4byte	.LASF98
	.byte	0xd2
	.4byte	.LFB10
	.4byte	.LFE10-.LFB10
	.uleb128 0x1
	.byte	0x9c
	.4byte	0xe8f
	.uleb128 0x2
	.4byte	.LBB5
	.4byte	.LBE5-.LBB5
	.uleb128 0xa
	.string	"n2"
	.byte	0xd6
	.byte	0xf
	.4byte	0xc0
	.uleb128 0x2
	.byte	0x91
	.sleb128 -20
	.uleb128 0xa
	.string	"n1"
	.byte	0xd7
	.byte	0xf
	.4byte	0xc0
	.uleb128 0x2
	.byte	0x91
	.sleb128 -24
	.byte	0
	.byte	0
	.uleb128 0x1a
	.4byte	.LASF99
	.byte	0x1
	.byte	0xca
	.byte	0xd
	.4byte	.LFB9
	.4byte	.LFE9-.LFB9
	.uleb128 0x1
	.byte	0x9c
	.4byte	0xeb4
	.uleb128 0xf
	.4byte	.LASF100
	.byte	0xcc
	.byte	0xd
	.4byte	0xc0
	.uleb128 0x2
	.byte	0x91
	.sleb128 -20
	.byte	0
	.uleb128 0xd
	.4byte	.LASF101
	.byte	0xb3
	.4byte	.LFB8
	.4byte	.LFE8-.LFB8
	.uleb128 0x1
	.byte	0x9c
	.4byte	0xefb
	.uleb128 0x2
	.4byte	.LBB4
	.4byte	.LBE4-.LBB4
	.uleb128 0xa
	.string	"n"
	.byte	0xb7
	.byte	0xe
	.4byte	0xb4
	.uleb128 0x2
	.byte	0x91
	.sleb128 -20
	.uleb128 0xf
	.4byte	.LASF65
	.byte	0xb8
	.byte	0xe
	.4byte	0xb4
	.uleb128 0x2
	.byte	0x91
	.sleb128 -24
	.uleb128 0xf
	.4byte	.LASF102
	.byte	0xb9
	.byte	0xe
	.4byte	0xb4
	.uleb128 0x2
	.byte	0x91
	.sleb128 -28
	.byte	0
	.byte	0
	.uleb128 0xd
	.4byte	.LASF103
	.byte	0x9c
	.4byte	.LFB7
	.4byte	.LFE7-.LFB7
	.uleb128 0x1
	.byte	0x9c
	.4byte	0xf36
	.uleb128 0x2
	.4byte	.LBB3
	.4byte	.LBE3-.LBB3
	.uleb128 0xf
	.4byte	.LASF65
	.byte	0xa0
	.byte	0xe
	.4byte	0xb4
	.uleb128 0x2
	.byte	0x91
	.sleb128 -20
	.uleb128 0xf
	.4byte	.LASF102
	.byte	0xa1
	.byte	0xe
	.4byte	0xb4
	.uleb128 0x2
	.byte	0x91
	.sleb128 -24
	.byte	0
	.byte	0
	.uleb128 0x10
	.4byte	.LASF104
	.byte	0x8c
	.4byte	.LFB6
	.4byte	.LFE6-.LFB6
	.uleb128 0x1
	.byte	0x9c
	.uleb128 0x10
	.4byte	.LASF105
	.byte	0x80
	.4byte	.LFB5
	.4byte	.LFE5-.LFB5
	.uleb128 0x1
	.byte	0x9c
	.uleb128 0x10
	.4byte	.LASF106
	.byte	0x71
	.4byte	.LFB4
	.4byte	.LFE4-.LFB4
	.uleb128 0x1
	.byte	0x9c
	.uleb128 0x10
	.4byte	.LASF107
	.byte	0x67
	.4byte	.LFB3
	.4byte	.LFE3-.LFB3
	.uleb128 0x1
	.byte	0x9c
	.uleb128 0xd
	.4byte	.LASF108
	.byte	0x5a
	.4byte	.LFB2
	.4byte	.LFE2-.LFB2
	.uleb128 0x1
	.byte	0x9c
	.4byte	0xfa1
	.uleb128 0x2
	.4byte	.LBB2
	.4byte	.LBE2-.LBB2
	.uleb128 0xa
	.string	"a"
	.byte	0x5e
	.byte	0xf
	.4byte	0xc0
	.uleb128 0x2
	.byte	0x91
	.sleb128 -20
	.byte	0
	.byte	0
	.uleb128 0x1b
	.4byte	.LASF109
	.byte	0x1
	.byte	0x4e
	.byte	0x6
	.4byte	.LFB1
	.4byte	.LFE1-.LFB1
	.uleb128 0x1
	.byte	0x9c
	.uleb128 0x10
	.4byte	.LASF110
	.byte	0x41
	.4byte	.LFB0
	.4byte	.LFE0-.LFB0
	.uleb128 0x1
	.byte	0x9c
	.byte	0
	.section	.debug_abbrev,"",@progbits
.Ldebug_abbrev0:
	.uleb128 0x1
	.uleb128 0x34
	.byte	0
	.uleb128 0x3
	.uleb128 0x8
	.uleb128 0x3a
	.uleb128 0x21
	.sleb128 1
	.uleb128 0x3b
	.uleb128 0x5
	.uleb128 0x39
	.uleb128 0xb
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x2
	.uleb128 0x18
	.byte	0
	.byte	0
	.uleb128 0x2
	.uleb128 0xb
	.byte	0x1
	.uleb128 0x11
	.uleb128 0x1
	.uleb128 0x12
	.uleb128 0x6
	.byte	0
	.byte	0
	.uleb128 0x3
	.uleb128 0x5
	.byte	0
	.uleb128 0x3
	.uleb128 0x8
	.uleb128 0x3a
	.uleb128 0x21
	.sleb128 1
	.uleb128 0x3b
	.uleb128 0x5
	.uleb128 0x39
	.uleb128 0xb
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x2
	.uleb128 0x18
	.byte	0
	.byte	0
	.uleb128 0x4
	.uleb128 0x2e
	.byte	0x1
	.uleb128 0x3f
	.uleb128 0x19
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0x21
	.sleb128 1
	.uleb128 0x3b
	.uleb128 0x5
	.uleb128 0x39
	.uleb128 0x21
	.sleb128 6
	.uleb128 0x27
	.uleb128 0x19
	.uleb128 0x11
	.uleb128 0x1
	.uleb128 0x12
	.uleb128 0x6
	.uleb128 0x40
	.uleb128 0x18
	.uleb128 0x7c
	.uleb128 0x19
	.uleb128 0x1
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0x5
	.uleb128 0x34
	.byte	0
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0x21
	.sleb128 1
	.uleb128 0x3b
	.uleb128 0x5
	.uleb128 0x39
	.uleb128 0xb
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x2
	.uleb128 0x18
	.byte	0
	.byte	0
	.uleb128 0x6
	.uleb128 0x2e
	.byte	0
	.uleb128 0x3f
	.uleb128 0x19
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0x21
	.sleb128 1
	.uleb128 0x3b
	.uleb128 0x5
	.uleb128 0x39
	.uleb128 0x21
	.sleb128 6
	.uleb128 0x27
	.uleb128 0x19
	.uleb128 0x11
	.uleb128 0x1
	.uleb128 0x12
	.uleb128 0x6
	.uleb128 0x40
	.uleb128 0x18
	.uleb128 0x7c
	.uleb128 0x19
	.byte	0
	.byte	0
	.uleb128 0x7
	.uleb128 0x24
	.byte	0
	.uleb128 0xb
	.uleb128 0xb
	.uleb128 0x3e
	.uleb128 0xb
	.uleb128 0x3
	.uleb128 0xe
	.byte	0
	.byte	0
	.uleb128 0x8
	.uleb128 0x16
	.byte	0
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x39
	.uleb128 0xb
	.uleb128 0x49
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0x9
	.uleb128 0xf
	.byte	0
	.uleb128 0xb
	.uleb128 0x21
	.sleb128 4
	.uleb128 0x49
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0xa
	.uleb128 0x34
	.byte	0
	.uleb128 0x3
	.uleb128 0x8
	.uleb128 0x3a
	.uleb128 0x21
	.sleb128 1
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x39
	.uleb128 0xb
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x2
	.uleb128 0x18
	.byte	0
	.byte	0
	.uleb128 0xb
	.uleb128 0x34
	.byte	0
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0x21
	.sleb128 4
	.uleb128 0x3b
	.uleb128 0x5
	.uleb128 0x39
	.uleb128 0xb
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x3f
	.uleb128 0x19
	.uleb128 0x3c
	.uleb128 0x19
	.byte	0
	.byte	0
	.uleb128 0xc
	.uleb128 0x34
	.byte	0
	.uleb128 0x47
	.uleb128 0x13
	.uleb128 0x3a
	.uleb128 0x21
	.sleb128 1
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x39
	.uleb128 0xb
	.uleb128 0x2
	.uleb128 0x18
	.byte	0
	.byte	0
	.uleb128 0xd
	.uleb128 0x2e
	.byte	0x1
	.uleb128 0x3f
	.uleb128 0x19
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0x21
	.sleb128 1
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x39
	.uleb128 0x21
	.sleb128 6
	.uleb128 0x27
	.uleb128 0x19
	.uleb128 0x11
	.uleb128 0x1
	.uleb128 0x12
	.uleb128 0x6
	.uleb128 0x40
	.uleb128 0x18
	.uleb128 0x7c
	.uleb128 0x19
	.uleb128 0x1
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0xe
	.uleb128 0x5
	.byte	0
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0x21
	.sleb128 1
	.uleb128 0x3b
	.uleb128 0x5
	.uleb128 0x39
	.uleb128 0xb
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x2
	.uleb128 0x18
	.byte	0
	.byte	0
	.uleb128 0xf
	.uleb128 0x34
	.byte	0
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0x21
	.sleb128 1
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x39
	.uleb128 0xb
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x2
	.uleb128 0x18
	.byte	0
	.byte	0
	.uleb128 0x10
	.uleb128 0x2e
	.byte	0
	.uleb128 0x3f
	.uleb128 0x19
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0x21
	.sleb128 1
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x39
	.uleb128 0x21
	.sleb128 6
	.uleb128 0x27
	.uleb128 0x19
	.uleb128 0x11
	.uleb128 0x1
	.uleb128 0x12
	.uleb128 0x6
	.uleb128 0x40
	.uleb128 0x18
	.uleb128 0x7c
	.uleb128 0x19
	.byte	0
	.byte	0
	.uleb128 0x11
	.uleb128 0x2e
	.byte	0x1
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0x21
	.sleb128 1
	.uleb128 0x3b
	.uleb128 0x5
	.uleb128 0x39
	.uleb128 0x21
	.sleb128 13
	.uleb128 0x27
	.uleb128 0x19
	.uleb128 0x11
	.uleb128 0x1
	.uleb128 0x12
	.uleb128 0x6
	.uleb128 0x40
	.uleb128 0x18
	.uleb128 0x7a
	.uleb128 0x19
	.uleb128 0x1
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0x12
	.uleb128 0x2e
	.byte	0x1
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0x21
	.sleb128 1
	.uleb128 0x3b
	.uleb128 0x5
	.uleb128 0x39
	.uleb128 0x21
	.sleb128 13
	.uleb128 0x27
	.uleb128 0x19
	.uleb128 0x11
	.uleb128 0x1
	.uleb128 0x12
	.uleb128 0x6
	.uleb128 0x40
	.uleb128 0x18
	.uleb128 0x7c
	.uleb128 0x19
	.uleb128 0x1
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0x13
	.uleb128 0x2e
	.byte	0x1
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0x21
	.sleb128 1
	.uleb128 0x3b
	.uleb128 0x5
	.uleb128 0x39
	.uleb128 0xb
	.uleb128 0x27
	.uleb128 0x19
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x11
	.uleb128 0x1
	.uleb128 0x12
	.uleb128 0x6
	.uleb128 0x40
	.uleb128 0x18
	.uleb128 0x7c
	.uleb128 0x19
	.uleb128 0x1
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0x14
	.uleb128 0x2e
	.byte	0x1
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0x21
	.sleb128 1
	.uleb128 0x3b
	.uleb128 0x5
	.uleb128 0x39
	.uleb128 0xb
	.uleb128 0x27
	.uleb128 0x19
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x11
	.uleb128 0x1
	.uleb128 0x12
	.uleb128 0x6
	.uleb128 0x40
	.uleb128 0x18
	.uleb128 0x7a
	.uleb128 0x19
	.uleb128 0x1
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0x15
	.uleb128 0x11
	.byte	0x1
	.uleb128 0x25
	.uleb128 0xe
	.uleb128 0x13
	.uleb128 0xb
	.uleb128 0x3
	.uleb128 0x1f
	.uleb128 0x1b
	.uleb128 0x1f
	.uleb128 0x11
	.uleb128 0x1
	.uleb128 0x12
	.uleb128 0x6
	.uleb128 0x10
	.uleb128 0x17
	.byte	0
	.byte	0
	.uleb128 0x16
	.uleb128 0x24
	.byte	0
	.uleb128 0xb
	.uleb128 0xb
	.uleb128 0x3e
	.uleb128 0xb
	.uleb128 0x3
	.uleb128 0x8
	.byte	0
	.byte	0
	.uleb128 0x17
	.uleb128 0x34
	.byte	0
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x39
	.uleb128 0xb
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x3f
	.uleb128 0x19
	.uleb128 0x3c
	.uleb128 0x19
	.byte	0
	.byte	0
	.uleb128 0x18
	.uleb128 0x16
	.byte	0
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0x5
	.uleb128 0x39
	.uleb128 0xb
	.uleb128 0x49
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0x19
	.uleb128 0x15
	.byte	0
	.uleb128 0x27
	.uleb128 0x19
	.byte	0
	.byte	0
	.uleb128 0x1a
	.uleb128 0x2e
	.byte	0x1
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x39
	.uleb128 0xb
	.uleb128 0x27
	.uleb128 0x19
	.uleb128 0x11
	.uleb128 0x1
	.uleb128 0x12
	.uleb128 0x6
	.uleb128 0x40
	.uleb128 0x18
	.uleb128 0x7a
	.uleb128 0x19
	.uleb128 0x1
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0x1b
	.uleb128 0x2e
	.byte	0
	.uleb128 0x3f
	.uleb128 0x19
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x39
	.uleb128 0xb
	.uleb128 0x27
	.uleb128 0x19
	.uleb128 0x11
	.uleb128 0x1
	.uleb128 0x12
	.uleb128 0x6
	.uleb128 0x40
	.uleb128 0x18
	.uleb128 0x7a
	.uleb128 0x19
	.byte	0
	.byte	0
	.byte	0
	.section	.debug_aranges,"",@progbits
	.4byte	0x1c
	.2byte	0x2
	.4byte	.Ldebug_info0
	.byte	0x4
	.byte	0
	.2byte	0
	.2byte	0
	.4byte	.Ltext0
	.4byte	.Letext0-.Ltext0
	.4byte	0
	.4byte	0
	.section	.debug_line,"",@progbits
.Ldebug_line0:
	.section	.debug_str,"MS",@progbits,1
.LASF79:
	.string	"count"
.LASF21:
	.string	"rf_origin"
.LASF70:
	.string	"rf_code_xorr"
.LASF18:
	.string	"uintptr_t"
.LASF99:
	.string	"rf_branch"
.LASF24:
	.string	"rf_ip"
.LASF16:
	.string	"uint64_t"
.LASF55:
	.string	"rf_dminu"
.LASF9:
	.string	"__uint8_t"
.LASF11:
	.string	"long long unsigned int"
.LASF78:
	.string	"rf_code_cmove"
.LASF58:
	.string	"rf_dplus"
.LASF41:
	.string	"addr"
.LASF102:
	.string	"limit"
.LASF67:
	.string	"rf_code_rpsto"
.LASF107:
	.string	"rf_next"
.LASF49:
	.string	"rf_code_dup"
.LASF8:
	.string	"long long int"
.LASF2:
	.string	"signed char"
.LASF69:
	.string	"rf_code_spat"
.LASF62:
	.string	"rf_code_fromr"
.LASF52:
	.string	"rf_code_over"
.LASF47:
	.string	"bits"
.LASF6:
	.string	"long int"
.LASF23:
	.string	"rf_rp"
.LASF91:
	.string	"rf_find"
.LASF64:
	.string	"rf_code_leave"
.LASF35:
	.string	"rf_code_stod"
.LASF51:
	.string	"rf_code_drop"
.LASF12:
	.string	"__intptr_t"
.LASF98:
	.string	"rf_code_xdo"
.LASF81:
	.string	"rf_code_encl"
.LASF14:
	.string	"unsigned int"
.LASF88:
	.string	"rf_pfind"
.LASF7:
	.string	"long unsigned int"
.LASF22:
	.string	"rf_sp"
.LASF104:
	.string	"rf_code_zbran"
.LASF25:
	.string	"rf_code_t"
.LASF75:
	.string	"rf_ustar"
.LASF5:
	.string	"short unsigned int"
.LASF103:
	.string	"rf_code_xloop"
.LASF84:
	.string	"rf_enclose"
.LASF83:
	.string	"addr1"
.LASF86:
	.string	"addr2"
.LASF17:
	.string	"intptr_t"
.LASF44:
	.string	"rf_code_at"
.LASF80:
	.string	"from"
.LASF63:
	.string	"rf_code_tor"
.LASF95:
	.string	"base"
.LASF61:
	.string	"rf_code_zequ"
.LASF110:
	.string	"rf_trampoline"
.LASF97:
	.string	"rf_code_dodoe"
.LASF101:
	.string	"rf_code_xploo"
.LASF68:
	.string	"rf_code_spsto"
.LASF33:
	.string	"rf_code_cold"
.LASF26:
	.string	"rf_w"
.LASF40:
	.string	"rf_code_cstor"
.LASF108:
	.string	"rf_code_lit"
.LASF10:
	.string	"__uint64_t"
.LASF66:
	.string	"rf_code_semis"
.LASF111:
	.string	"GNU C11 14.2.1 20240927 -mabi=ilp32 -mtune=rocket -misa-spec=20191213 -march=rv32imac_zicsr_zifencei_zba_zbb_zbkb_zbs -g -O3 -O0 -std=gnu11 -fno-inline"
.LASF82:
	.string	"rf_encl"
.LASF92:
	.string	"rf_lfa"
.LASF27:
	.string	"rf_up"
.LASF28:
	.string	"rf_fp"
.LASF3:
	.string	"unsigned char"
.LASF105:
	.string	"rf_code_bran"
.LASF39:
	.string	"rf_code_docol"
.LASF38:
	.string	"rf_code_docon"
.LASF4:
	.string	"short int"
.LASF53:
	.string	"rf_code_dminu"
.LASF13:
	.string	"__uintptr_t"
.LASF43:
	.string	"rf_code_cat"
.LASF31:
	.string	"rf_code_cl"
.LASF48:
	.string	"rf_code_pstor"
.LASF30:
	.string	"rf_code_cs"
.LASF34:
	.string	"origin"
.LASF32:
	.string	"rf_code_mon"
.LASF57:
	.string	"rf_code_dplus"
.LASF106:
	.string	"rf_code_exec"
.LASF42:
	.string	"rf_code_store"
.LASF89:
	.string	"length"
.LASF71:
	.string	"rf_code_orr"
.LASF20:
	.string	"char"
.LASF109:
	.string	"rf_start"
.LASF94:
	.string	"rf_digit"
.LASF65:
	.string	"index"
.LASF56:
	.string	"rf_code_minus"
.LASF76:
	.string	"rf_undouble"
.LASF45:
	.string	"word"
.LASF100:
	.string	"offset"
.LASF93:
	.string	"rf_code_digit"
.LASF87:
	.string	"rf_uslas"
.LASF19:
	.string	"rf_double_t"
.LASF59:
	.string	"rf_code_plus"
.LASF77:
	.string	"rf_double"
.LASF72:
	.string	"rf_code_andd"
.LASF54:
	.string	"rf_cold"
.LASF96:
	.string	"rf_code_rr"
.LASF50:
	.string	"rf_code_swap"
.LASF29:
	.string	"rf_code_ln"
.LASF90:
	.string	"rf_pfa"
.LASF15:
	.string	"uint8_t"
.LASF36:
	.string	"rf_code_douse"
.LASF46:
	.string	"rf_code_toggl"
.LASF85:
	.string	"rf_code_pfind"
.LASF37:
	.string	"rf_code_dovar"
.LASF73:
	.string	"rf_code_uslas"
.LASF60:
	.string	"rf_code_zless"
.LASF74:
	.string	"rf_code_ustar"
	.section	.debug_line_str,"MS",@progbits,1
.LASF1:
	.string	"pico"
.LASF0:
	.string	"rf.c"
	.globl	__udivdi3
	.globl	__umoddi3
	.ident	"GCC: (g37a302fb7) 14.2.1 20240927"
	.section	.note.GNU-stack,"",@progbits
