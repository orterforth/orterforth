# Modified for orterforth integration and armv6l
# in 2022. Some info in the comments no longer 
# applies (CP/M, 8086 register names, 
# segmentation, byte offsets).

        .arch armv6
        .eabi_attribute 28, 1
        .eabi_attribute 20, 1
        .eabi_attribute 21, 1
        .eabi_attribute 23, 3
        .eabi_attribute 24, 1
        .eabi_attribute 25, 1
        .eabi_attribute 26, 2
        .eabi_attribute 30, 6
        .eabi_attribute 34, 1
        .eabi_attribute 18, 4
        .text

        .p2align 2
        .global rf_trampoline
rf_trampoline:
        PUSH    {R7, R8, R10, FP, LR}
trampoline1:
        LDR     R0, =rf_fp
        LDR     R0, [R0]
        CMP     R0, #0
        BEQ     trampoline2
        LDR     R10, =rf_ip     @ IP to R10
        LDR     R10, [R10]
        LDR     R3, =rf_w       @ W to R3
        LDR     R3, [R3]
        LDR     R8, =rf_sp      @ SP to R8
        LDR     R8, [R8]
        LDR     R7, =rf_rp      @ RP to R7
        LDR     R7, [R7]
        LDR     LR, =trampoline1 @ return addr
        BX      R0
trampoline2:
        POP     {R7, R8, R10, FP, PC}

        .p2align 2
        .global rf_start
rf_start:
        LDR     R0, =rf_ip      @ R10 to IP
        STR     R10, [R0]
        LDR     R0, =rf_w       @ R3 to W
        STR     R3, [R0]
        LDR     R0, =rf_sp      @ R8 to SP
        STR     R8, [R0]
        LDR     R0, =rf_rp      @ R7 to RP
        STR     R7, [R0]
        BX      LR              @ carry on in C

        .p2align 2
        .global rf_code_cl
rf_code_cl:
        MOV     R0, #4
#       B       APUSH
        STR     R0, [R8, #-4]!
        LDR     R3, [R10], #4
        LDR     R0, [R3]
        BX      R0

        .p2align 2
        .global rf_code_cs
rf_code_cs:
        LDR     R0, [R8]
        LSL     R0, #2
        STR     R0, [R8]
#       B       NEXT
        LDR     R3, [R10], #4
        LDR     R0, [R3]
        BX      R0

        .p2align 2
        .global rf_code_ln
rf_code_ln:
        LDR     R0, [R8]
        TST     R0, #3
        BEQ     ln1
        AND     R0, R0, #-4
        ADD     R0, R0, #4
ln1:    STR     R0, [R8]
#       B       NEXT
        LDR     R3, [R10], #4
        LDR     R0, [R3]
        BX      R0

        .p2align 2
        .global rf_code_xt
rf_code_xt:
        PUSH    {FP, LR}
        BL      rf_start
        LDR     R1, =rf_fp
        MOV     R0, #0
        STR     R0, [R1]
        POP     {FP, PC}

        .p2align 2
        .global rf_code_cold
rf_code_cold:
        LDR     R3, =rf_origin
        LDR     R3, [R3]
        LDR     R0, [R3, #24]   @ FORTH vocabulary init
        LDR     R1, [R3, #68]
        STR     R0, [R1]
        LDR     R1, [R3, #32]   @ UP init
        LDR     R0, =rf_up
        STR     R1, [R0]
        MOV     R2, #11         @ USER variables init
        ADD     R3, R3, #24
cold1:
        LDR   R0, [R3], #4
        STR   R0, [R1], #4
        SUBS  R2, R2, #1
        BNE   cold1
        LDR   R10, [R3, #4]     @ IP init to ABORT
        B     rf_code_rpsto     @ jump to RP!

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
        .p2align 2
DPUSH:  STR     R3, [R8, #-4]!
APUSH:  STR     R0, [R8, #-4]!
#
# -----------------------------------------
#
# PATCH THE NEXT 3 LOCATIONS
# (USING A DEBUG MONITOR; I.E. DDT86)
# WITH  (JMP TNEXT)  FOR TRACING THROUGH
# HIGH LEVEL FORTH WORDS.
#
        .p2align 2
        .global rf_next
rf_next:
NEXT:   LDR     R3, [R10], #4   @ AX<- (IP)
                                @ (W) <- (IP)
#
# -----------------------------------------
#
NEXT1:  LDR     R0, [R3]        @ TO 'CFA'
        BX      R0

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
        .p2align 2
        .global rf_code_lit
rf_code_lit:
        LDR     R0, [R10], #4   @ AX <- LITERAL
#       B       APUSH           @ TO TOP OF STACK
        STR     R0, [R8, #-4]!
        LDR     R3, [R10], #4
        LDR     R0, [R3]
        BX      R0


# ***************
# *   EXECUTE   *
# ***************
#
        .p2align 2
        .global rf_code_exec
rf_code_exec:
        LDR     R3, [R8], #4    @ GET CFA
#       B       NEXT1           @ EXECUTE NEXT
        LDR     R0, [R3]
        BX      R0


# **************
# *   BRANCH   *
# **************
#
        .p2align 2
        .global rf_code_bran
rf_code_bran:
BRAN1:  LDR     R0, [R10]       @ (IP) <- (IP) + ((IP))
        ADD     R10, R10, R0
#       B       NEXT            @ JUMP TO OFFSET
        LDR     R3, [R10], #4
        LDR     R0, [R3]
        BX      R0


# ***************
# *   0BRANCH   *
# ***************
#
        .p2align 2
        .global rf_code_zbran
rf_code_zbran:
        LDR     R0, [R8], #4   @ GET STACK VALUE
        ORRS    R0, R0         @ ZERO?
        BEQ     BRAN1          @ YES, BRANCH
        ADD     R10, R10, #4   @ NO, CONTINUE...
#       B       NEXT
        LDR     R3, [R10], #4
        LDR     R0, [R3]
        BX      R0


# **************
# *   (LOOP)   *
# **************
#
        .p2align 2
        .global rf_code_xloop
rf_code_xloop:
        MOV     R1, #1          @ INCREMENT
XLOO1:  LDR     R0, [R7]        @ INDEX=INDEX+INCR
        ADD     R0, R0, R1
        STR     R0, [R7]        @ GET NEW INDEX
        LDR     R2, [R7, #4]    @ COMPARE WITH LIMIT
        SUB     R0, R0, R2
        EORS    R0, R1          @ TEST SIGN (BIT-16)
        BMI     BRAN1           @ KEEP LOOPING...

# END OF 'DO' LOOP.
        ADD     R7, R7, #8      @ ADJ. RETURN STK
        ADD     R10, R10, #4    @ BYPASS BRANCH OFFSET
#       B       NEXT            @ CONTINUE...
        LDR     R3, [R10], #4
        LDR     R0, [R3]
        BX      R0


# ***************
# *   (+LOOP)   *
# ***************
#
        .p2align 2
        .global rf_code_xploo
rf_code_xploo:
        LDR     R1, [R8], #4    @ GET LOOP VALUE
        B       XLOO1


# ************
# *   (DO)   *
# ************
#
        .p2align 2
        .global rf_code_xdo
rf_code_xdo:
        LDM     R8!, {R0, R3}   @ INITIAL INDEX VALUE
                                @ LIMIT VALUE
                                @ GET RETURN STACK
        STMDB   R7!, {R0, R3}
                                @ GET PARAMETER STACK
#       B       NEXT
        LDR     R3, [R10], #4
        LDR     R0, [R3]
        BX      R0


# *********
# *   I   *
# *********
#
        .p2align 2
        .global rf_code_rr
rf_code_rr:
        LDR     R0, [R7]        @ GET INDEX VALUE
#       B       APUSH           @ TO PARAMETER STACK
        STR     R0, [R8, #-4]!
        LDR     R3, [R10], #4
        LDR     R0, [R3]
        BX      R0


# *************
# *   DIGIT   *
# *************
#
        .p2align 2
        .global rf_code_digit
rf_code_digit:
        LDRB    R3, [R8], #4    @ NUMBER BASE
        LDRB    R0, [R8], #4    @ ASCII DIGIT
        SUBS    R0, R0, #'0'
        BLT     DIGI2           @ NUMBER ERROR
        CMP     R0, #9
        BLE     DIGI1           @ NUMBER = 0 THRU 9
        SUB     R0, R0, #7
        CMP     R0, #10         @ NUMBER 'A' THRU 'Z' ?
        BLT     DIGI2           @ NO
#
DIGI1:  CMP     R0, R3          @ COMPARE NUMBER TO BASE
        BGE     DIGI2           @ NUMBER ERROR
#       SUB     R3, R3, R3      @ ZERO
        MOV     R3, R0          @ NEW BINARY NUMBER
        MOV     R0, #1          @ TRUE FLAG
#       B       DPUSH           @ ADD TO STACK
        STMDB   R8!, {R0, R3}
        LDR     R3, [R10], #4
        LDR     R0, [R3]
        BX      R0

# NUMBER ERROR
#
DIGI2:  SUB     R0, R0, R0      @ FALSE FLAG
#       B       APUSH           @ BYE
        STR     R0, [R8, #-4]!
        LDR     R3, [R10], #4
        LDR     R0, [R3]
        BX      R0


# *************
# *   PFIND   *
# *************
#
        .p2align 2
        .global rf_code_pfind
rf_code_pfind:
        LDM     R8!, {R1, R2}   @ NFA
                                @ STRING ADDR
#
# SEARCH LOOP
PFIN1:  MOV     R4, R2          @ GET ADDR
        LDRB    R0, [R1]        @ GET WORD LENGTH
        MOV     R3, R0          @ SAVE LENGTH
        LDRB    R5, [R4]
        EOR     R0, R5
        ANDS    R0, #63         @ CHECK LENGTHS
        BNE     PFIN5           @ LENGTHS DIFFER
#
# LENGTH MATCH, CHECK EACH CHARACTER IN NAME
PFIN2:  ADD     R1, R1, #1
        ADD     R4, R4, #1      @ NEXT CHAR OF NAME
        LDRB    R0, [R1]
        LDRB    R5, [R4]        @ COMPARE NAMES
        EOR     R0, R5
        TST     R0, #127
        BNE     PFIN5           @ NO MATCH
        TST     R0, #128        @ THIS WILL TEST BIT-8
        BEQ     PFIN2           @ MATCH SO FAR, LOOP

# FOUND END OF NAME (BIT-8 SET); A MATCH
        ADD     R1, R1, #9      @ BX = PFA
        STR     R1, [R8, #-4]!  @ (S3) <- PFA
        MOV     R0, #1          @ TRUE VALUE
        AND     R3, #255        @ CLEAR HIGH LENGTH
#       B       DPUSH
        STMDB   R8!, {R0, R3}
        LDR     R3, [R10], #4
        LDR     R0, [R3]
        BX      R0

# NO NAME FIELD MATCH, TRY ANOTHER
#
# GET NEXT LINK FIELD ADDR (LFA)
# (ZERO = FIRST WORD OF DICTIONARY)
#
PFIN5:  ADD     R1, R1, #1      @ NEXT ADDR
        TST     R0, #128        @ END OF NAME
        BNE     PFIN6
        LDRB    R0, [R1]        @ GET NEXT CHAR
        B       PFIN5           @ LOOP UNTIL FOUND
#
PFIN6:  LDR     R1, [R1]        @ GET LINK FIELD ADDR
        ORRS    R1, R1          @ START OF DICT. (0)?
        BNE     PFIN1           @ NO, LOOK SOME MORE
        MOV     R0, #0          @ FALSE FLAG
#       B       APUSH           @ DONE (NO MATCH FOUND)
        STR     R0, [R8, #-4]!
        LDR     R3, [R10], #4
        LDR     R0, [R3]
        BX      R0


# ***************
# *   ENCLOSE   *
# ***************
#
        .p2align 2
        .global rf_code_encl
rf_code_encl:
        LDR     R0, [R8], #4    @ S1 - TERMINATOR CHAR.
        LDR     R1, [R8]        @ S2 - TEXT ADDR
                                @ ADDR BACK TO STACK
        AND     R0, #255        @ ZERO
        MOV     R3, #-1         @ CHAR OFFSET COUNTER
        SUB     R1, R1, #1      @ ADDR -1

# SCAN TO FIRST NON-TERMINATOR CHAR
#
ENCL1:  ADD     R1, R1, #1      @ ADDR +1
        ADD     R3, R3, #1      @ COUNT +1
        LDRB    R2, [R1]
        CMP     R0, R2
        BEQ     ENCL1           @ WAIT FOR NON-TERMINATOR
        STR     R3, [R8, #-4]!  @ OFFSET TO 1ST TEXT CHR
        CMP     R2, #0          @ NULL CHAR?
        BNE     ENCL2           @ NO

# FOUND NULL BEFORE FIRST NON-TERMINATOR CHAR.
        MOV     R0, R3          @ COPY COUNTER
        ADD     R3, R3, #1      @ +1
@       B       DPUSH
        STMDB   R8!, {R0, R3}
        LDR     R3, [R10], #4
        LDR     R0, [R3]
        BX      R0

# FOUND FIRST TEXT CHAR, COUNT THE CHARACTERS
#
ENCL2:  ADD     R1, R1, #1      @ ADDR+1
        ADD     R3, R3, #1      @ COUNT +1
        LDRB    R2, [R1]        @ TERMINATOR CHAR?
        CMP     R0, R2
        BEQ     ENCL4           @ YES
        CMP     R2, #0          @ NULL CHAR
        BNE     ENCL2           @ NO, LOOP AGAIN

# FOUND NULL AT END OF TEXT
#
ENCL3:  MOV     R0, R3          @ COUNTERS ARE EQUAL
@       B       DPUSH
        STMDB   R8!, {R0, R3}
        LDR     R3, [R10], #4
        LDR     R0, [R3]
        BX      R0

# FOUND TERINATOR CHARACTER
ENCL4:  MOV     R0, R3
        ADD     R0, R0, #1      @ COUNT +1
@       B       DPUSH
        STMDB   R8!, {R0, R3}
        LDR     R3, [R10], #4
        LDR     R0, [R3]
        BX      R0


# *************
# *   CMOVE   *
# *************
#
        .p2align 2
        .global rf_code_cmove
rf_code_cmove:
                                @ INC DIRECTION
                                @ SAVE IP
        LDM     R8!, {R1, R2, R3} @ COUNT
                                @ DEST.
                                @ SOURCE
        CMP     R1, #0          @ THATS THE MOVE
        BEQ     CMOV2
CMOV1:  LDRB    R0, [R3], #1
        STRB    R0, [R2], #1
        SUBS    R1, R1, #1
        BNE     CMOV1
CMOV2:                          @ GET BACK IP
#       B       NEXT
        LDR     R3, [R10], #4
        LDR     R0, [R3]
        BX      R0


# **********
# *   U*   *
# **********
#
        .p2align 2
        .global rf_code_ustar
rf_code_ustar:
        LDM     R8!, {R1, R2}
        UMULL   R3, R0, R1, R2  @ UNSIGNED
@       B       DPUSH           @ STORE DOUBLE WORD
        STMDB   R8!, {R0, R3}
        LDR     R3, [R10], #4
        LDR     R0, [R3]
        BX      R0


# **********
# *   U/   *
# **********
#
        .p2align 2
        .global rf_code_uslas
rf_code_uslas:
        LDM     R8!, {R0, R1, R2} @ DIVISOR
                                @ MSW OF DIVIDEND
                                @ LSW OF DIVIDEND
        MOV     R3, #1
        LSL     R3, R3, #31     @ init mask with highest bit set
        MOV     R4, #0          @ init quot
        CMP     R1, R0          @ test modh - div
        BLO     umdiv1          @ modh < div
        @ overflow condition ( divide by zero ) - show max numbers
        ASR     R4, R3, #31
        MOV     R1, R4
        BAL     umdiv3          @ return
umdiv1: ADDS    R2, R2, R2      @ double precision shift (modh, modl)
        ADCS    R1, R1, R1      @ ADD with carry and set flags again !
        BCS     umdiv4
        CMP     R0, R1          @ test div - modh
        BHI     umdiv2          @ div >  modh ?
umdiv4: ADD     R4, R4, R3      @ add single pecision mask
        SUB     R1, R1, R0      @ subtract single precision div
umdiv2: LSR     R3, R3, #1      @ shift mask one bit to the right
        ANDS    R3, R3, R3
        BNE     umdiv1
umdiv3: STR     R1, [r8, #-4]!  @ remainder
        STR     R4, [r8, #-4]!  @ quotient
#       B       NEXT
        LDR     R3, [R10], #4
        LDR     R0, [R3]
        BX      R0


# ***********
# *   AND   *
# ***********
#
        .p2align 2
        .global rf_code_andd
rf_code_andd:                   @ (S1) <- (S1) AND (S2)
        LDR   R0, [R8], #4
        LDR   R1, [R8]
        AND   R0, R0, R1
        STR   R0, [R8]
#       B       NEXT
        LDR     R3, [R10], #4
        LDR     R0, [R3]
        BX      R0


# **********
# *   OR   *
# **********
#
        .p2align 2
        .global rf_code_orr
rf_code_orr:                    @ (S1) <- (S1) OR (S2)
        LDR   R0, [R8], #4
        LDR   R1, [R8]
        ORR   R0, R0, R1
        STR   R0, [R8]
#       B       NEXT
        LDR     R3, [R10], #4
        LDR     R0, [R3]
        BX      R0


# ***********
# *   XOR   *
# ***********
#
        .p2align 2
        .global rf_code_xorr
rf_code_xorr:                   @ (S1) <- (S1) XOR (S2)
        LDR   R0, [R8], #4
        LDR   R1, [R8]
        EOR   R0, R0, R1
        STR   R0, [R8]
#       B       NEXT
        LDR     R3, [R10], #4
        LDR     R0, [R3]
        BX      R0


# ***********
# *   SP@   *
# ***********
#
        .p2align 2
        .global rf_code_spat
rf_code_spat:                   @ (S1) <- (SP)
        MOV     R0, R8
#       B       APUSH
        STR     R0, [R8, #-4]!
        LDR     R3, [R10], #4
        LDR     R0, [R3]
        BX      R0


# ***********
# *   SP!   *
# ***********
#
        .p2align 2
        .global rf_code_spsto
rf_code_spsto:
        LDR     R1, =rf_up      @ USER VAR BASE ADDR
        LDR     R1, [R1]
        LDR     R8, [R1, #12]   @ RESET PARAM. STACK PT.
#       B       NEXT
        LDR     R3, [R10], #4
        LDR     R0, [R3]
        BX      R0

  .p2align 2
  .global rf_code_rpsto
rf_code_rpsto:
        LDR     R1, =rf_up      @ (AX) <- USR VAR. BASE
        LDR     R1, [R1]
        LDR     R7, [R1, #16]   @ RESET RETURN STACK PT.
#       B       NEXT
        LDR     R3, [R10], #4
        LDR     R0, [R3]
        BX      R0


# **********
# *   ;S   *
# **********
#
        .p2align 2
        .global rf_code_semis
rf_code_semis:
        LDR     R10, [R7], #4   @ (IP) <- (R1)
                                @ ADJUST STACK
#       B       NEXT
        LDR     R3, [R10], #4
        LDR     R0, [R3]
        BX      R0


# *************
# *   LEAVE   *
# *************
#
        .p2align 2
        .global rf_code_leave
rf_code_leave:                  @ LIMIT <- INDEX
        LDR   R0, [R7]          @ GET INDEX
        STR   R0, [R7, #4]      @ STORE IT AT LIMIT
#       B       NEXT
        LDR     R3, [R10], #4
        LDR     R0, [R3]
        BX      R0


# **********
# *   >R   *
# **********
#
        .p2align 2
        .global rf_code_tor
rf_code_tor:                    @ (R1) <- (S1)
        LDR     R1, [R8], #4    @ GET STACK PARAMETER
        STR     R1, [R7, #-4]!  @ MOVE RETURN STACK DOWN
                                @ ADD TO RETURN STACK
#       B       NEXT
        LDR     R3, [R10], #4
        LDR     R0, [R3]
        BX      R0


# **********
# *   R>   *
# **********
#
        .p2align 2
        .global rf_code_fromr
rf_code_fromr:                  @ (S1) <- (R1)
        LDR     R0, [R7], #4    @ GET RETURN STACK VALUE
        STR     R0, [R8, #-4]!  @ DELETE FROM STACK
#       B       NEXT
        LDR     R3, [R10], #4
        LDR     R0, [R3]
        BX      R0


# **********
# *   0=   *
# **********
#
        .p2align 2
        .global rf_code_zequ
rf_code_zequ:
        LDR     R0, [R8], #4
        ORRS    R0, R0          @ DO TEST
        MOV     R0, #1          @ TRUE
        BEQ     ZEQU1           @ ITS ZERO
        SUB     R0, R0, #1      @ FALSE
ZEQU1:  # B       APUSH
        STR     R0, [R8, #-4]!
        LDR     R3, [R10], #4
        LDR     R0, [R3]
        BX      R0


# **********
# *   0<   *
# **********
#
        .p2align 2
        .global rf_code_zless
rf_code_zless:
        LDR     R0, [R8], #4
        ORRS    R0, R0          @ SET FLAGS
        MOV     R0, #1          @ TRUE
        BMI     ZLESS1
        SUB     R0, R0, #1      @ FLASE
ZLESS1: # B       APUSH
        STR     R0, [R8, #-4]!
        LDR     R3, [R10], #4
        LDR     R0, [R3]
        BX      R0


# *********
# *   +   *
# *********
#
        .p2align 2
        .global rf_code_plus
rf_code_plus:                   @ (S1) <- (S1) + (S2)
        LDM     R8!, {R0, R1}
        ADD     R0, R0, R1
#       B       APUSH
        STR     R0, [R8, #-4]!
        LDR     R3, [R10], #4
        LDR     R0, [R3]
        BX      R0


# **********
# *   D+   *
# **********
#
# XLW XHW  YLW YHW --> SLW SHW
# S4  S3   S2  S1      S2  S1
#
        .p2align 2
        .global rf_code_dplus
rf_code_dplus:
        LDM     R8!, {R0, R1, R2, R3} @ YHW
                                @ YLW
                                @ XHW
                                @ XLW
        ADDS    R1, R1, R3      @ SLW
        ADC     R0, R0, R2      @ SHW
#       B       DPUSH
#       STMDB   R8!, {R0, R3}
        STMDB   R8!, {R0, R1}
        LDR     R3, [R10], #4
        LDR     R0, [R3]
        BX      R0


# *************
# *   MINUS   *
# *************
#
        .p2align 2
        .global rf_code_minus
rf_code_minus:
        LDR     R0, [R8]
        NEG     R0, R0
#       B       APUSH
        STR     R0, [R8]
        LDR     R3, [R10], #4
        LDR     R0, [R3]
        BX      R0


# **************
# *   DMINUS   *
# **************
#
        .p2align 2
        .global rf_code_dminu
rf_code_dminu:
        LDM     R8!, {R1, R2}
        SUB     R0, R0, R0      @ ZERO
        MOV     R3, R0
        SUBS    R3, R3, R2      @ MAKE 2'S COMPLEMENT
        SBC     R0, R0, R1      @ HIGH WORD
#       B       DPUSH
        STMDB   R8!, {R0, R3}
        LDR     R3, [R10], #4
        LDR     R0, [R3]
        BX      R0


# ************
# *   OVER   *
# ************
#
        .p2align 2
        .global rf_code_over
rf_code_over:
        LDR     R0, [R8, #4]
#       B       APUSH
        STR     R0, [R8, #-4]!
        LDR     R3, [R10], #4
        LDR     R0, [R3]
        BX      R0


# ************
# *   DROP   *
# ************
#
        .p2align 2
        .global rf_code_drop
rf_code_drop:
        ADD     R8, R8, #4
#       B       NEXT
        LDR     R3, [R10], #4
        LDR     R0, [R3]
        BX      R0


# ************
# *   SWAP   *
# ************
#
        .p2align 2
        .global rf_code_swap
rf_code_swap:
        LDM     R8, {R0, R3}
        STR     R0, [R8, #4]
        STR     R3, [R8]
#       B       NEXT
        LDR     R3, [R10], #4
        LDR     R0, [R3]
        BX      R0


# ***********
# *   DUP   *
# ***********
#
        .p2align 2
        .global rf_code_dup
rf_code_dup:
        LDR     R0, [R8]
#       B       APUSH
        STR     R0, [R8, #-4]!
        LDR     R3, [R10], #4
        LDR     R0, [R3]
        BX      R0


# **********
# *   +!   *
# **********
#
        .p2align 2
        .global rf_code_pstor
rf_code_pstor:                  @ ((S1)) <- ((S1)) + (S2)
        LDM     R8!, {R0, R1}   @ ADDRESS
                                @ INCREMENT
        LDR     R2, [R0]
        ADD     R2, R2, R1
        STR     R2, [R0]
#       B       NEXT
        LDR     R3, [R10], #4
        LDR     R0, [R3]
        BX      R0


# **************
# *   TOGGLE   *
# **************
#
        .p2align 2
        .global rf_code_toggl
rf_code_toggl:
        LDM     R8!, {R0, R1}   @ BIT PATTERN
                                @ ADDR
        LDRB    R2, [R1]
        EOR     R2, R2, R0
        STRB    R2, [R1]
#       B       NEXT
        LDR     R3, [R10], #4
        LDR     R0, [R3]
        BX      R0


# *********
# *   @   *
# *********
#
        .p2align 2
        .global rf_code_at
rf_code_at:                     @ (S1) <- ((S1))
        LDR     R1, [R8]
        LDR     R0, [R1]
        STR     R0, [R8]
#       B       NEXT
        LDR     R3, [R10], #4
        LDR     R0, [R3]
        BX      R0


# **********
# *   C@   *
# **********
#
        .p2align 2
        .global rf_code_cat
rf_code_cat:
        LDR     R1, [R8]
        LDRB    R0, [R1]
        STR     R0, [R8]
#       B       NEXT
        LDR     R3, [R10], #4
        LDR     R0, [R3]
        BX      R0


# *********
# *   !   *
# *********
#
        .p2align 2
        .global rf_code_store
rf_code_store:                  @ ((S1)) <- (S2)
        LDM     R8!, {R0, R1}   @ ADDR
                                @ DATA
        STR     R1, [R0]
#       B       NEXT
        LDR     R3, [R10], #4
        LDR     R0, [R3]
        BX      R0


# **********
# *   C!   *
# **********
#
        .p2align 2
        .global rf_code_cstor
rf_code_cstor:
        LDM     R8!, {R0, R1}   @ ADDR
                                @ DATA
        STRB    R1, [R0]
#       B       NEXT
        LDR     R3, [R10], #4
        LDR     R0, [R3]
        BX      R0


# *********
# *   :   *
# *********
#
        .p2align 2
        .global rf_code_docol
rf_code_docol:
DOCOL:  ADD     R3, R3, #4      @ W=W+1
        STR     R10, [R7, #-4]! @ (RP) <- (RP)-2
                                @ R1 <- (RP)
        MOV     R10, R3         @ (IP) <- (W)
#       B       NEXT
        LDR     R3, [R10], #4
        LDR     R0, [R3]
        BX      R0


# ****************
# *   CONSTANT   *
# ****************
#
        .p2align 2
        .global rf_code_docon
rf_code_docon:
DOCON:  LDR     R0, [R3, #4]    @ PFA
                                @ GET DATA
#       B       APUSH
        STR     R0, [R8, #-4]!
        LDR     R3, [R10], #4
        LDR     R0, [R3]
        BX      R0

# ****************
# *   VARIABLE   *
# ****************
#
        .p2align 2
        .global rf_code_dovar
rf_code_dovar:
DOVAR:  ADD     R3, R3, #4      @ (DE) <- PFA
        STR     R3, [R8, #-4]!  @ (S1) <- PFA
#       B       NEXT
        LDR     R3, [R10], #4
        LDR     R0, [R3]
        BX      R0

# ************
# *   USER   *
# ************
#
        .p2align 2
        .global rf_code_douse
rf_code_douse:
DOUSE:  LDRB    R1, [R3, #4]    @ PFA
        LDR     R0, =rf_up      @ USER VARIABLE ADDR
        LDR     R0, [R0]
        ADD     R0, R0, R1      @ ADDR OF VARIABLE
#       B       APUSH
        STR     R0, [R8, #-4]!
        LDR     R3, [R10], #4
        LDR     R0, [R3]
        BX      R0


# *************
# *   DOES>   *
# *************
#
        .p2align 2
        .global rf_code_dodoe
rf_code_dodoe:
DODOE:                          @ GET RETURN STACK
        STR     R10, [R7, #-4]! @ (RP) <- (IP)
        ADD     R3, R3, #4      @ PFA
        LDR     R10, [R3], #4   @ NEW CFA
        STR     R3, [R8, #-4]!  @ PFA
#       B       NEXT
        LDR     R3, [R10], #4
        LDR     R0, [R3]
        BX      R0


# ************
# *   S->D   *
# ************
#
        .p2align 2
        .global rf_code_stod
rf_code_stod:
        LDR     R3, [R8], #4    @ S1
        SUB     R0, R0, R0      @ AX = 0
        ORRS    R3, R3          @ SET FLAGS
        BPL     STOD1           @ POSITIVE NUMBER
        SUB     R0, R0, #1      @ NEGITIVE NUMBER
STOD1:  # B       DPUSH
        STMDB   R8!, {R0, R3}
        LDR     R3, [R10], #4
        LDR     R0, [R3]
        BX      R0
