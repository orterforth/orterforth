# Adapted from the original document in 2025:
# https://www.forth.org/fig-forth/fig-forth_8086-8088_ver_10.pdf
# to create a RISC-V port and integrate into orterforth. Some
# info in the comments no longer applies as a result.

        .option nopic
        .attribute arch, "rv32i2p1_m2p0_a2p1_c2p0_zicsr2p0_zifencei2p0_zba1p0_zbb1p0_zbkb1p0_zbs1p0"
        .attribute unaligned_access, 0
        .attribute stack_align, 16

        .section .sbss,"aw",@nobits

        .globl rf_sp
        .align 2
rf_sp:  .zero 4

        .globl rf_rp
        .align 2
rf_rp:  .zero 4

        .globl rf_ip
        .align 2
rf_ip:  .zero 4

        .globl rf_w
        .align 2
rf_w:   .zero 4

        .globl rf_up
        .align 2
rf_up:  .zero 4

        .globl rf_fp
        .align 2
rf_fp:  .zero 4

        .text

        .align 1
        .globl rf_trampoline
rf_trampoline:
        .file 1 "rf.c"
        addi    sp,sp,-16
        sw      ra,12(sp)
        sw      s0,8(sp)
        addi    s0,sp,16
        lui     ra,%hi(tramp1)
        addi    ra,ra,%lo(tramp1)
tramp1: lui     a4,%hi(rf_fp)
        lw      a4,%lo(rf_fp)(a4)
        beqz    a4,tramp2
        lui     a5,%hi(rf_ip)   # IP into S11
        lw      s11,%lo(rf_ip)(a5)
        lui     a5,%hi(rf_sp)   # SP into S10
        lw      s10,%lo(rf_sp)(a5)
        lui     a5,%hi(rf_rp)   # RP into S9
        lw      s9,%lo(rf_rp)(a5)
        lui     a5,%hi(rf_w)    # W into S8
        lw      s8,%lo(rf_w)(a5)
        jr      a4
tramp2: lw      ra,12(sp)
        lw      s0,8(sp)
        addi    sp,sp,16
        jr      ra

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
        lui     a5,%hi(rf_rp)   # S9 into RP
        sw      s9,%lo(rf_rp)(a5)
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


# fig-FORTH 8086/8088
# ASSEMBLY SOURCE LISTING

# RELEASE 1.0
# WITH COMPILER SECURITY
# AND
# VARIABLE LENGTH WORDS
# MARCH 1981
# This public domain publication is provided through the courtesy
# of the FORTH Interest Group, PO Box 8231, San Jose, CA 95155.
# Further distribution must contain this notice.

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

UP      =       _rf_up

#-----------------------------------------------
#
# FORTH REGISTERS
#
# FORTH 8086    FORTH PRESERVATION RULES
# ----- ----    ------------------------
#
# IP    SI      INTERPRETER POINTER.
#               MUST BE PRESERVED
#               ACROSS FORTH WORDS.
#
# W     DX      WORKING REGISTER.
#               JUMP TO 'DPUSH' WILL
#               PUSH CONTENTS ONTO THE
#               PARAMETER STACK BEFORE
#               EXECUTING 'APUSH'.
#
# SP    SP      PARAMETER STACK POINTER.
#               MUST BE PRESERVED
#               ACROSS FORTH WORDS.
#
# RP    BP      RETURN STACK.
#               MUST BE PRESERVED
#               ACROSS FORTH WORDS.
#
#       AX      GENERAL REGISTER.
#               JUMP TO 'APUSH' WILL PUSH
#               CONTENTS ONTO THE PARAMETER
#               STACK BEFORE EXECUTING 'NEXT'.
#
#       BX      GENERAL PURPOSE REGISTER.
#
#       CX      GENERAL PURPOSE REGISTER.
#
#       DI      GENERAL PURPOSE REGISTER.
#
#       CS      SEGMENT REGISTER.  MUST BE
#               PRESERVED ACROSS FORTH WORDS.
#
#       DS         "    "       "
#
#       SS         "    "       "
#
#       ES      TEMPORARY SEGMENT REGISTER
#               ONLY USED BY A FEW WORDS.
#
################################################

# *************
# *           *
# *   NEXT    *
# *           *
# *   DPUSH   *
# *           *
# *   APUSH   *
# *           *
# *************
#
#
        .align 1
DPUSH:  addi    s10,s10,-4
        sw      a2,(s10)
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
        .size rf_next, .-rf_next

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
        lw      a5,(s11)        # AX <- LITERAL
        addi    s11,s11,4
        j       APUSH           # TO TOP OF STACK
        .size rf_code_lit, .-rf_code_lit


# ***************
# *   EXECUTE   *
# ***************
#
        .align 1
        .globl  rf_code_exec
        .type rf_code_exec, @function
rf_code_exec:
        lw      s8,(s10)        # GET CFA
        addi    s10,s10,4
        j       NEXT1           # EXECUTE NEXT
        .size rf_code_exec, .-rf_code_exec


# **************
# *   BRANCH   *
# **************
#
        .align 1
        .globl rf_code_bran
        .type rf_code_bran, @function
rf_code_bran:
BRAN1:  lw      a5,(s11)
        add     s11,s11,a5      # (IP) <- (IP) + ((IP))
        j       NEXT            # JUMP TO OFFSET
	.size	rf_code_bran, .-rf_code_bran


# ***************
# *   0BRANCH   *
# ***************
#
        .align 1
        .globl rf_code_zbran
        .type rf_code_zbran, @function
rf_code_zbran:
        lw      a5,(s10)        # GET STACK VALUE
        addi    s10,s10,4
        beqz    a5,BRAN1        # ZERO?
                                # YES, BRANCH
        addi    s11,s11,4       # NO, CONTINUE...
        j       NEXT
	.size	rf_code_zbran, .-rf_code_zbran


# **************
# *   (LOOP)   *
# **************
#
        .align 1
        .globl rf_code_xloop
        .type rf_code_xloop, @function
rf_code_xloop:
        li      a4,1            # INCREMENT
XLOO1:  lw      a5,(s9)         # INDEX=INDEX+INCR
        add     a5,a5,a4
        sw      a5,(s9)         # GET NEW INDEX
        lw      a3,4(s9)        # COMPARE WITH LIMIT
        sub     a5,a5,a3
        xor     a5,a5,a4        # TEST SIGN (BIT-16)
        bltz    a5,BRAN1        # KEEP LOOPING...

# END OF 'DO' LOOP
        addi    s9,s9,8         # ADJ. RETURN STK
        addi    s11,s11,4       # BYPASS BRANCH OFFSET
        j       NEXT            # CONTINUE...
	.size	rf_code_xloop, .-rf_code_xloop


# ***************
# *   (+LOOP)   *
# ***************
#
        .align 1
        .globl rf_code_xploo
        .type rf_code_xploo, @function
rf_code_xploo:
        lw      a4,(s10)        # GET LOOP VALUE
        addi    s10,s10,4
        j       XLOO1


# ************
# *   (DO)   *
# ************
#
        .align 1
        .globl rf_code_xdo
        .type rf_code_xdo, @function
rf_code_xdo:
        lw      a5,(s10)        # INITIAL INDEX VALUE
        lw      a2,4(s10)       # LIMIT VALUE
        addi    s10,s10,8
        addi    s9,s9,-8
        sw      a2,4(s9)
        sw      a5,(s9)
        j       NEXT
 	.size	rf_code_xdo, .-rf_code_xdo


# *********
# *   I   *
# *********
#
        .align 1
        .globl rf_code_rr
        .type rf_code_rr, @function
rf_code_rr:
        lw      a5,(s9)         # GET INDEX VALUE
        j       APUSH           # TO PARAMETER STACK
	.size	rf_code_rr, .-rf_code_rr



# *************
# *   DIGIT   *
# *************
#
        .align 1
        .globl rf_code_digit
        .type rf_code_digit, @function
rf_code_digit:
        lb      a2,(s10)        # NUMBER BASE
        addi    s10,s10,4
        lb      a5,(s10)        # ASCII DIGIT
        addi    s10,s10,4
        addi    a5,a5,-'0'
        bltz    a5,DIGI2        # NUMBER ERROR
		li      a4,9
        ble     a5,a4,DIGI1     # NUMBER = 0 THRU 9
        addi    a5,a5,-7
		li      a4,10
        blt     a5,a4,DIGI2     # NUMBER 'A' THRU 'Z' ?
                                # NO
#
DIGI1:  bge     a5,a2,DIGI2     # COMPARE NUMBER TO BASE
                                # NUMBER ERROR
                                # ZERO
        mv      a2,a5           # NEW BINARY NUMBER
        li      a5,1            # TRUE FLAG
        j       DPUSH           # ADD TO STACK

# NUMBER ERROR
#
DIGI2:  li      a5,0            # FALSE FLAG
        j       APUSH           # BYE

	.size	rf_code_digit, .-rf_code_digit


# *************
# *   CMOVE   *
# *************
#
        .align 1
        .globl rf_code_cmove
        .type rf_code_cmove, @function
rf_code_cmove:
		lw      a4,(s10)        # COUNT
		lw      a3,4(s10)       # DEST.
		lw      a2,8(s10)       # SOURCE
		addi    s10,s10,12
        beqz    a4,CMOV2
CMOV1:  lbu     a5,(a2)         # THATS THE MOVE
        addi    a2,a2,1
        sb      a5,(a3)
        addi    a3,a3,1
        addi    a4,a4,-1
        bnez    a4,CMOV1
CMOV2:  j       NEXT


# ***********
# *   AND   *
# ***********
#
        .align 1
        .globl rf_code_andd
        .type rf_code_andd, @function
rf_code_andd:
        lw      a5,(s10)
		addi    s10,s10,4
        lw      a4,(s10)
        and     a5,a5,a4
        sw      a5,(s10)
        j       NEXT

        .size rf_code_andd, .-rf_code_andd


# **********
# *   OR   *
# **********
#
        .align 1
        .globl rf_code_orr
        .type rf_code_orr, @function
rf_code_orr:
        lw      a5,(s10)
		addi    s10,s10,4
        lw      a4,(s10)
        or      a5,a5,a4
        sw      a5,(s10)
        j       NEXT

        .size rf_code_orr, .-rf_code_orr


# ***********
# *   XOR   *
# ***********
#
        .align 1
        .globl rf_code_xorr
        .type rf_code_xorr, @function
rf_code_xorr:
        lw      a5,(s10)
		addi    s10,s10,4
        lw      a4,(s10)
        xor     a5,a5,a4
        sw      a5,(s10)
        j       NEXT

        .size rf_code_xorr, .-rf_code_xorr


# ***********
# *   SP@   *
# ***********
#
        .align 1
        .globl rf_code_spat
        .type rf_code_spat, @function
rf_code_spat:
        mv      a5,s10
        j       APUSH


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
