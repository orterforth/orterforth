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
rf_start:
        lui     a5,%hi(rf_ip)   # S11 into IP
        sw      s11,%lo(rf_ip)(a5)
        lui     a5,%hi(rf_sp)   # S10 into SP
        sw      s10,%lo(rf_sp)(a5)
        lui     a5,%hi(rf_rp)   # S9 into RP
        sw      s9,%lo(rf_rp)(a5)
        lui     a5,%hi(rf_w)    # S8 into W
        sw      s8,%lo(rf_w)(a5)
        jr      ra

        .align 1
        .globl rf_code_cold
rf_code_cold:
        lui     a2,%hi(rf_origin)
        lw      a2,%lo(rf_origin)(a2)
        lw      a5,24(a2)       # FORTH vocabulary init
        lw      a4,84(a2)
        sw      a5,(a4)
        lw      a4,32(a2)       # UP init
        lui     a5,%hi(rf_up)
        lw      a5,%lo(rf_up)(a5)
        sw      a4,(a5)
        li      a3,11           # USER variables init
        addi    a2,a2,24
cold1:  lw      a5,(a2)
        addi    a2,a2,4
        sw      a5,(a4)
        addi    a4,a4,4
        addi    a3,a3,-1
        bnez    a3,cold1
        lw      s11,20(a2)      # IP init to ABORT
        j       rf_code_rpsto   # jump to RP!

        .align 1
        .globl rf_code_cl
rf_code_cl:
        li      a5,4
        j       APUSH

        .align 1
        .globl rf_code_cs
rf_code_cs:
        lw      a5,(s10)
        slli    a5,a5,2
        sw      a5,(s10)
        j       NEXT

        .align 1
        .globl rf_code_ln
rf_code_ln:
        lw      a5,(s10)
        addi    a5,a5,-1
        ori     a5,a5,3
        addi    a5,a5,1
        sw      a5,(s10)
        j       NEXT

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

UP      =       rf_up

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
rf_next:
NEXT:   lw      s8,(s11)        # AX<- (IP)
                                # (W) <- (IP)
        addi    s11,s11,4
#
# -----------------------------------------
#
NEXT1:  lw      a5,(s8)         # TO 'CFA'
        jr      a5
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
rf_code_lit:
        lw      a5,(s11)        # AX <- LITERAL
        addi    s11,s11,4
        j       APUSH           # TO TOP OF STACK


# ***************
# *   EXECUTE   *
# ***************
#
        .align 1
        .globl  rf_code_exec
rf_code_exec:
        lw      s8,(s10)        # GET CFA
        addi    s10,s10,4
        j       NEXT1           # EXECUTE NEXT


# **************
# *   BRANCH   *
# **************
#
        .align 1
        .globl rf_code_bran
rf_code_bran:
BRAN1:  lw      a5,(s11)
        add     s11,s11,a5      # (IP) <- (IP) + ((IP))
        j       NEXT            # JUMP TO OFFSET


# ***************
# *   0BRANCH   *
# ***************
#
        .align 1
        .globl rf_code_zbran
rf_code_zbran:
        lw      a5,(s10)        # GET STACK VALUE
        addi    s10,s10,4
        beqz    a5,BRAN1        # ZERO?
                                # YES, BRANCH
        addi    s11,s11,4       # NO, CONTINUE...
        j       NEXT


# **************
# *   (LOOP)   *
# **************
#
        .align 1
        .globl rf_code_xloop
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


# ***************
# *   (+LOOP)   *
# ***************
#
        .align 1
        .globl rf_code_xploo
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
rf_code_xdo:
        lw      a5,(s10)        # INITIAL INDEX VALUE
        lw      a2,4(s10)       # LIMIT VALUE
        addi    s10,s10,8
        addi    s9,s9,-8
        sw      a2,4(s9)
        sw      a5,(s9)
        j       NEXT


# *********
# *   I   *
# *********
#
        .align 1
        .globl rf_code_rr
rf_code_rr:
        lw      a5,(s9)         # GET INDEX VALUE
        j       APUSH           # TO PARAMETER STACK


# *************
# *   DIGIT   *
# *************
#
        .align 1
        .globl rf_code_digit
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


# **************
# *   (FIND)   *
# **************
#
        .align 1
        .globl rf_code_pfind
rf_code_pfind:
        lw      a4,(s10)        # NFA
        lw      a3,4(s10)       # STRING ADDR
        addi    s10,s10,8
#
# SEARCH LOOP
PFIN1:  mv      a1,a3           # GET ADDR
        lbu     a5,(a4)         # GET WORD LENGTH
        mv      a2,a5           # SAVE LENGTH
        lbu     a0,(a1)
        xor     a5,a5,a0
        andi    a5,a5,63        # CHECK LENGTHS
        bnez    a5,PFIN5        # LENGTHS DIFFER
#
# LENGTH MATCH, CHECK EACH CHARACTER IN NAME
PFIN2:  addi    a4,a4,1
        addi    a1,a1,1         # NEXT CHAR OF NAME
        lbu     a5,(a4)
        lbu     a0,(a1)         # COMPARE NAMES
        xor     a5,a5,a0
        andi    a6,a5,127
        bnez    a6,PFIN5        # NO MATCH
        andi    a6,a5,128       # THIS WILL TEST BIT-8
        beqz    a6,PFIN2        # MATCH SO FAR, LOOP

# FOUND END OF NAME (BIT-8 SET); A MATCH
        addi    a4,a4,9         # BX = PFA
        addi    s10,s10,-4
        sw      a4,(s10)        # (S3) <- PFA
        li      a5,1            # TRUE VALUE
        andi    a2,a2,255       # CLEAR HIGH LENGTH
        j       DPUSH

# NO NAME FIELD MATCH, TRY ANOTHER
#
# GET NEXT LINK FIELD ADDR (LFA)
# (ZERO = FIRST WORD OF DICTIONARY)
#
PFIN5:  addi    a4,a4,1         # NEXT ADDR
        andi    a6,a5,128       # END OF NAME
        bnez    a6,PFIN6
        lbu     a5,(a4)         # GET NEXT CHAR
        j       PFIN5           # LOOP UNTIL FOUND
#
PFIN6:  lw      a4,(a4)         # GET LINK FIELD ADDR
                                # START OF DICT. (0)?
        bnez    a4,PFIN1        # NO, LOOK SOME MORE
        li      a5,0            # FALSE FLAG
        j       APUSH           # DONE (NO MATCH FOUND)


# ***************
# *   ENCLOSE   *
# ***************
#
        .align 1
        .globl rf_code_encl
rf_code_encl:
        lw      a5,(s10)        # S1 - TERMINATOR CHAR.
        addi    s10,s10,4
        lw      a4,(s10)        # S2 - TEXT ADDR
                                # ADDR BACK TO STACK
        andi    a5,a5,255       # ZERO
        li      a2,0            # CHAR OFFSET COUNTER
        addi    a2,a2,-1
        addi    a4,a4,-1        # ADDR -1

# SCAN TO FIRST NON-TERMINATOR CHAR
#
ENCL1:  addi    a4,a4,1         # ADDR +1
        addi    a2,a2,1         # COUNT +1
        lbu     a3,(a4)
        beq     a5,a3,ENCL1     # WAIT FOR NON-TERMINATOR
        addi    s10,s10,-4
        sw      a2,(s10)        # OFFSET TO 1ST TEXT CHR
        bnez    a3,ENCL2        # NULL CHAR?
                                # NO

# FOUND NULL BEFORE FIRST NON-TERMINATOR CHAR.
        mv      a5,a2           # COPY COUNTER
        addi    a2,a2,1         # +1
        j       DPUSH

# FOUND FIRST TEXT CHAR, COUNT THE CHARACTERS
#
ENCL2:  addi    a4,a4,1         # ADDR+1
        addi    a2,a2,1         # COUNT +1
        lbu     a3,(a4)         # TERMINATOR CHAR?
        beq     a5,a3,ENCL4     # YES
        bnez    a3,ENCL2        # NULL CHAR
                                # NO, LOOP AGAIN

# FOUND NULL AT END OF TEXT
#
ENCL3:  mv      a5,a2           # COUNTERS ARE EQUAL
        j       DPUSH

# FOUND TERINATOR CHARACTER
ENCL4:  mv      a5,a2
        addi    a5,a5,1         # COUNT +1
        j       DPUSH


# *************
# *   CMOVE   *
# *************
#
        .align 1
        .globl rf_code_cmove
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


# **********
# *   U*   *
# **********
#
        .align 1
        .globl rf_code_ustar
rf_code_ustar:
        lw      a3,(s10)
        lw      a4,4(s10)
        addi    s10,s10,8
        mul     a2,a3,a4
        mulhu   a5,a3,a4
        j       DPUSH           # STORE DOUBLE WORD


# **********
# *   U/   *
# **********
#
        .align 1
        .globl rf_code_uslas
rf_code_uslas:
        lw      a5,(s10)        # DIVISOR
        lw      a4,4(s10)       # MSW OF DIVIDEND
        lw      a3,8(s10)       # LSW OF DIVIDEND
        addi    s10,s10,12
        li      a2,1
        slli    a2,a2,31        # init mask with highest bit set
        li      a1,0            # init quot
                                # test modh - div
        bltu    a4,a5,UMDIV1    # modh < div
        # overflow condition ( divide by zero ) - show max numbers
        srai    a1,a2,31
        mv      a4,a1
        j       UMDIV3          # return
UMDIV1: sltz    t0,a3           # double precision shift (modh, modl)
        slli    a3,a3,1
        sltz    t1,a4           # ADD with carry and set flags again !
        slli    a4,a4,1
        or      a4,a4,t0
        bnez    t1,UMDIV4
                                # test div - modh
        bgtu    a5,a4,UMDIV2    # div >  modh ?
UMDIV4: add     a1,a1,a2        # add single pecision mask
        sub     a4,a4,a5        # subtract single precision div
UMDIV2: srli    a2,a2,1         # shift mask one bit to the right
        bnez    a2,UMDIV1
UMDIV3: addi    s10,s10,-8
        sw      a4,4(s10)       # remainder
        sw      a1,(s10)        # quotient
        j       NEXT


# ***********
# *   AND   *
# ***********
#
        .align 1
        .globl rf_code_andd
rf_code_andd:
        lw      a5,(s10)
        addi    s10,s10,4
        lw      a4,(s10)
        and     a5,a5,a4
        sw      a5,(s10)
        j       NEXT


# **********
# *   OR   *
# **********
#
        .align 1
        .globl rf_code_orr
rf_code_orr:
        lw      a5,(s10)
        addi    s10,s10,4
        lw      a4,(s10)
        or      a5,a5,a4
        sw      a5,(s10)
        j       NEXT


# ***********
# *   XOR   *
# ***********
#
        .align 1
        .globl rf_code_xorr
rf_code_xorr:
        lw      a5,(s10)
        addi    s10,s10,4
        lw      a4,(s10)
        xor     a5,a5,a4
        sw      a5,(s10)
        j       NEXT


# ***********
# *   SP@   *
# ***********
#
        .align 1
        .globl rf_code_spat
rf_code_spat:
        mv      a5,s10
        j       APUSH


# ***********
# *   SP!   *
# ***********
#
        .align 1
        .globl rf_code_spsto
rf_code_spsto:
        lui     a4,%hi(UP)      # USER VAR BASE ADDR
        lw      a4,%lo(UP)(a4)
        lw      s10,12(a4)      # RESET PARAM. STACK PT.
        j       NEXT


# ***********
# *   RP!   *
# ***********
#
        .align 1
        .globl rf_code_rpsto
rf_code_rpsto:
        lui     a4,%hi(UP)      # (AX) <- USR VAR. BASE
        lw      a4,%lo(UP)(a4)
        lw      s9,16(a4)       # RESET RETURN STACK PT.
        j       NEXT


# **********
# *   ;S   *
# **********
#
        .align 1
        .globl rf_code_semis
rf_code_semis:
        lw      s11,(s9)        # (IP) <- (R1)
        addi    s9,s9,4
        j       NEXT


# *************
# *   LEAVE   *
# *************
#
        .align 1
        .globl rf_code_leave
rf_code_leave:
        lw      a5,(s9)         # GET INDEX
        sw      a5,4(s9)        # STORE IT AT LIMIT
        j       NEXT


# **********
# *   >R   *
# **********
#
        .align 1
        .globl rf_code_tor
rf_code_tor:
        lw      a4,(s10)        # GET STACK PARAMETER
        addi    s10,s10,4
        addi    s9,s9,-4
        sw      a4,(s9)         # ADD TO RETURN STACK
        j       NEXT


# **********
# *   R>   *
# **********
#
        .align 1
        .globl rf_code_fromr
rf_code_fromr:
        lw      a4,(s9)        # GET RETURN STACK VALUE
        addi    s9,s9,4
        addi    s10,s10,-4
        sw      a4,(s10)       # DELETE FROM STACK
        j       NEXT


# **********
# *   0=   *
# **********
#
        .align 1
        .globl rf_code_zequ
rf_code_zequ:
        lw      a5,(s10)
        seqz    a5,a5
        sw      a5,(s10)
        j       NEXT


# **********
# *   0<   *
# **********
#
        .align 1
        .globl rf_code_zless
rf_code_zless:
        lw      a5,(s10)
        sltz    a5,a5
        sw      a5,(s10)
        j       NEXT


# *********
# *   +   *
# *********
#
        .align 1
        .globl rf_code_plus
rf_code_plus:
        lw      a5,(s10)
        lw      a4,4(s10)
        addi    s10,s10,8
        add     a5,a5,a4
        j       APUSH


# **********
# *   D+   *
# **********
#
# XLW XHW  YLW YHW --> SLW SHW
# S4  S3   S2  S1      S2  S1
#
        .align 1
        .globl rf_code_dplus
rf_code_dplus:
        lw      a5,(s10)        # YHW
        lw      a4,4(s10)       # YLW
        lw      a3,8(s10)       # XHW 
        lw      a2,12(s10)      # XLW
        addi    s10,s10,16
        add     a2,a2,a4        # SLW
        sltu    a4,a2,a4
        add     a5,a5,a3        # SHW
        add     a5,a5,a4
        j       DPUSH


# *************
# *   MINUS   *
# *************
#
        .align 1
        .globl rf_code_minus
rf_code_minus:
        lw      a5,(s10)
        neg     a5,a5
        sw      a5,(s10)
        j       NEXT


# **************
# *   DMINUS   *
# **************
#
        .align 1
        .globl rf_code_dminu
rf_code_dminu:
        lw      a4,(s10)
        lw      a3,4(s10)
        addi    s10,s10,8
        sub     a5,a5,a5        # ZERO
        mv      a1,a5
        sub     a2,a1,a3        # MAKE 2'S COMPLEMENT
        sgtu    a3,a2,a1
        sub     a5,a5,a4        # HIGH WORD
        sub     a5,a5,a3
        j       DPUSH


# ************
# *   OVER   *
# ************
#
        .align 1
        .globl rf_code_over
rf_code_over:
        lw      a5,4(s10)
        j       APUSH


# ************
# *   DROP   *
# ************
#
        .align 1
        .globl rf_code_drop
rf_code_drop:
        addi    s10,s10,4
        j       NEXT


# ************
# *   SWAP   *
# ************
#
        .align 1
        .globl rf_code_swap
rf_code_swap:
        lw      a2,(s10)
        lw      a5,4(s10)
        sw      a2,4(s10)
        sw      a5,(s10)
        j       NEXT


# ***********
# *   DUP   *
# ***********
#
        .align 1
        .globl rf_code_dup
rf_code_dup:
        lw      a5,(s10)
        j       APUSH


# **********
# *   +!   *
# **********
#
        .align 1
        .globl rf_code_pstor
rf_code_pstor:
        lw      a5,(s10)        # ADDRESS
        lw      a4,4(s10)       # INCREMENT
        addi    s10,s10,8
        lw      a3,(a5)
        add     a3,a3,a4
        sw      a3,(a5)
        j       NEXT


# **************
# *   TOGGLE   *
# **************
#
        .align 1
        .globl rf_code_toggl
rf_code_toggl:
        lw      a5,(s10)        # BIT PATTERN
        lw      a4,4(s10)       # ADDR
        addi    s10,s10,8
        lbu     a3,(a4)
        xor     a3,a3,a5
        sb      a3,(a4)
        j       NEXT


# *********
# *   @   *
# *********
#
        .align 1
        .globl rf_code_at
rf_code_at:
        lw      a4,(s10)
        lw      a5,(a4)
        sw      a5,(s10)
        j       NEXT


# **********
# *   C@   *
# **********
#
        .align 1
        .globl rf_code_cat
rf_code_cat:
        lw      a4,(s10)
        lbu     a5,(a4)
        sw      a5,(s10)
        j       NEXT


# *********
# *   !   *
# *********
#
        .align 1
        .globl rf_code_store
rf_code_store:
        lw      a5,(s10)        # ADDR
        lw      a4,4(s10)       # DATA
        addi    s10,s10,8
        sw      a4,(a5)
        j       NEXT


# **********
# *   C!   *
# **********
#
        .align 1
        .globl rf_code_cstor
rf_code_cstor:
        lw      a5,(s10)        # ADDR
        lbu     a4,4(s10)       # DATA
        addi    s10,s10,8
        sb      a4,(a5)
        j       NEXT


# *********
# *   :   *
# *********
#
        .align 1
        .globl rf_code_docol
rf_code_docol:
        addi    s8,s8,4         # W=W+1
        addi    s9,s9,-4
        sw      s11,(s9)        # R1 <- (RP)
        mv      s11,s8          # (IP) <- (W)
        j       NEXT


# ****************
# *   CONSTANT   *
# ****************
#
        .align 1
        .globl rf_code_docon
rf_code_docon:
        lw      a5,4(s8)        # PFA
                                # GET DATA
        j       APUSH


# ****************
# *   VARIABLE   *
# ****************
#
        .align 1
        .globl rf_code_dovar
rf_code_dovar:
        addi    s8,s8,4         # (DE) <- PFA
        addi    s10,s10,-4
        sw      s8,(s10)        # (S1) <- PFA
        j       NEXT


# ************
# *   USER   *
# ************
#
        .align 1
        .globl rf_code_douse
rf_code_douse:
        lbu     a4,4(s8)        # PFA
        lui     a5,%hi(rf_up)   # USER VARIABLE ADDR
        lw      a5,%lo(rf_up)(a5)
        add     a5,a5,a4
        j       APUSH


# *************
# *   DOES>   *
# *************
#
        .align 1
        .globl rf_code_dodoe
rf_code_dodoe:
        addi    s9,s9,-4
        sw      s11,(s9)        # (RP) <- (IP)
        lw      s11,4(s8)       # NEW CFA
        addi    s8,s8,8         # PFA
        addi    s10,s10,-4
        sw      s8,(s10)        # PFA
        j       NEXT


# ************
# *   S->D   *
# ************
#
        .align 1
        .globl rf_code_stod
rf_code_stod:
        lw      a2,(s10)        # S1
                                # AX = 0
        sltz    a5,a2           # SET FLAGS
                                # POSITIVE NUMBER
        neg     a5,a5           # NEGITIVE NUMBER
STOD1:  j       APUSH

        .align 1
        .globl rf_code_mon
rf_code_mon:
        addi    sp,sp,-16
        sw      ra,12(sp)
        sw      s0,8(sp)
        addi    s0,sp,16
        call    rf_start
        lui     a4,%hi(rf_fp)
        sw      zero,%lo(rf_fp)(a4)
        lw      ra,12(sp)
        lw      s0,8(sp)
        addi    sp,sp,16
        jr      ra
