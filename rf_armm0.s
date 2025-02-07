# Modified for orterforth integration and ARM Cortex-M0+ in
# 2023. Some info in the comments no longer applies (CP/M, 8086
# register names, segmentation, byte offsets).

        .thumb_func

        .global rf_trampoline
        .align 4
rf_trampoline:
        PUSH    {R3, R4, R5, R6, R7, LR}
trampoline1:
        LDR     R4, fpp
        LDR     R0, [R4]
        CMP     R0, #0
        BEQ     trampoline2
        LDR     R6, ipp         @ IP into R6
        LDR     R6, [R6]
        LDR     R5, spp         @ SP into R5
        LDR     R5, [R5]
        LDR     R4, rpp         @ RP into R4
        LDR     R4, [R4]
        LDR     R3, wp          @ W into R3
        LDR     R3, [R3]
        BLX     R0
        B       trampoline1
trampoline2:
        POP     {R3, R4, R5, R6, R7, PC}

        .global rf_start
        .align 4
rf_start:
        LDR     R0, ipp         @ R6 into IP
        STR     R6, [R0]
        LDR     R0, spp         @ R5 into SP
        STR     R5, [R0]
        LDR     R0, rpp         @ R4 into RP
        STR     R4, [R0]
        LDR     R0, wp          @ R3 into W
        STR     R3, [R0]
        BX      LR              @ carry on in C

        .data

        .p2align 2
        .global rf_fp
rf_fp:  .long 0

        .p2align 2
        .global rf_ip
rf_ip:  .long 0

        .p2align 2
        .global rf_rp
rf_rp:  .long 0

        .p2align 2
        .global rf_sp
rf_sp:  .long 0

        .p2align 2
        .global rf_up
rf_up:  .long 0

        .p2align 2
        .global rf_w
rf_w:   .long 0

        .text

        .align 4
fpp:    .word rf_fp
ipp:    .word rf_ip
rpp:    .word rf_rp
spp:    .word rf_sp
wp:     .word rf_w

        .align 1
        .global rf_code_cold
        .syntax unified
        .thumb_func
        .code 16
rf_code_cold:
        LDR     R3, originp
        LDR     R3, [R3]
        LDR     R0, [R3, #24]   @ FORTH vocabulary init
        LDR     R1, [R3, #84]
        STR     R0, [R1]
        LDR     R1, [R3, #32]   @ UP init
        LDR     R0, upp
        STR     R1, [R0]
        MOVS    R2, #11         @ USER variables init
        ADDS    R3, R3, #24
cold1:  LDM     R3!, {R0}
        STM     R1!, {R0}
        SUBS    R2, R2, #1
        BNE     cold1
        LDR     R6, [R3, #20]   @ IP init to ABORT
        B       rf_code_rpsto   @ jump to RP!

        .align 4
originp:.word rf_origin
upp:    .word rf_up

        .align 1
        .global rf_code_cl
        .syntax unified
        .thumb_func
        .code 16
rf_code_cl:
        MOVS    R0, #4
#       B       APUSH
        SUBS    R5, R5, #4
        STR     R0, [R5]
        LDM     R6!, {R3}
        LDR     R0, [R3]
        BX      R0

        .align 1
        .global rf_code_cs
        .syntax unified
        .thumb_func
        .code 16
rf_code_cs:
        LDR     R0, [R5]
        LSLS    R0, #2
        STR     R0, [R5]
#       B       NEXT
        LDM     R6!, {R3}
        LDR     R0, [R3]
        BX      R0

        .align 1
        .global rf_code_ln
        .syntax unified
        .thumb_func
        .code 16
rf_code_ln:
        LDR     R0, [R5]
        SUBS    R0, R0, #1
        MOVS    R1, #3
        ORRS    R0, R1
        ADDS    R0, R0, #1
        STR     R0, [R5]
#       B       NEXT
        LDM     R6!, {R3}
        LDR     R0, [R3]
        BX      R0

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
        .syntax unified
        .thumb_func
        .code 16
DPUSH:  SUBS    R5, R5, #4
        STR     R3, [R5]
APUSH:  SUBS    R5, R5, #4
        STR     R0, [R5]
#
# -----------------------------------------
#
# PATCH THE NEXT 3 LOCATIONS
# (USING A DEBUG MONITOR; I.E. DDT86)
# WITH  (JMP TNEXT)  FOR TRACING THROUGH
# HIGH LEVEL FORTH WORDS.
#
        .align 1
        .global rf_next
        .syntax unified
        .thumb_func
        .code 16
rf_next:
NEXT:   LDM     R6!, {R3}       @ AX<- (IP)
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
        .align 1
        .global rf_code_lit
        .syntax unified
        .thumb_func
        .code 16
rf_code_lit:
        LDM     R6!, {R0}       @ AX <- LITERAL
#       B       APUSH           @ TO TOP OF STACK
        SUBS    R5, R5, #4
        STR     R0, [R5]
        LDM     R6!, {R3}
        LDR     R0, [R3]
        BX      R0


# ***************
# *   EXECUTE   *
# ***************
#
        .align 1
        .global rf_code_exec
        .syntax unified
        .thumb_func
        .code 16
rf_code_exec:
        LDM     R5!, {R3}       @ GET CFA
#       B       NEXT1           @ EXECUTE NEXT
        LDR     R0, [R3]
        BX      R0


# **************
# *   BRANCH   *
# **************
#
        .align 1
        .global rf_code_bran
        .syntax unified
        .thumb_func
        .code 16
rf_code_bran:
BRAN1:  LDR     R0, [R6]
        ADD     R6, R6, R0      @ (IP) <- (IP) + ((IP))
#       B       NEXT            @ JUMP TO OFFSET
        LDM     R6!, {R3}
        LDR     R0, [R3]
        BX      R0


# ***************
# *   0BRANCH   *
# ***************
#
        .align 1
        .global rf_code_zbran
        .syntax unified
        .thumb_func
        .code 16
rf_code_zbran:
        LDM     R5!, {R0}       @ GET STACK VALUE
        ORRS    R0, R0          @ ZERO?
        BEQ     BRAN1           @ YES, BRANCH
        ADDS    R6, R6, #4      @ NO, CONTINUE...
#       B       NEXT
        LDM     R6!, {R3}
        LDR     R0, [R3]
        BX      R0


# **************
# *   (LOOP)   *
# **************
#
        .align 1
        .global rf_code_xloop
        .syntax unified
        .thumb_func
        .code 16
rf_code_xloop:
        MOVS    R1, #1          @ INCREMENT
XLOO1:  LDR     R0, [R4]        @ INDEX=INDEX+INCR
        ADD     R0, R0, R1
        STR     R0, [R4]        @ GET NEW INDEX
        LDR     R2, [R4, #4]    @ COMPARE WITH LIMIT
        SUBS    R0, R0, R2
        EORS    R0, R1          @ TEST SIGN (BIT-16)
        BMI     BRAN1           @ KEEP LOOPING...

# END OF 'DO' LOOP
        ADDS    R4, R4, #8      @ ADJ. RETURN STK
        ADDS    R6, R6, #4      @ BYPASS BRANCH OFFSET
#       B       NEXT            @ CONTINUE...
        LDM     R6!, {R3}
        LDR     R0, [R3]
        BX      R0


# ***************
# *   (+LOOP)   *
# ***************
#
        .align 1
        .global rf_code_xploo
        .syntax unified
        .thumb_func
        .code 16
rf_code_xploo:
        LDM     R5!, {R1}       @ GET LOOP VALUE
        B       XLOO1


# ************
# *   (DO)   *
# ************
#
        .align 1
        .global rf_code_xdo
        .syntax unified
        .thumb_func
        .code 16
rf_code_xdo:
        LDM     R5!, {R0, R3}   @ INITIAL INDEX VALUE
                                @ LIMIT VALUE
        SUBS    R4, R4, #8
        STR     R3, [R4, #4]
        STR     R0, [R4]
#       B       NEXT
        LDM     R6!, {R3}
        LDR     R0, [R3]
        BX      R0


# *********
# *   I   *
# *********
#
        .align 1
        .global rf_code_rr
        .syntax unified
        .thumb_func
        .code 16
rf_code_rr:
        LDR     R0, [R4]        @ GET INDEX VALUE
#       B       APUSH           @ TO PARAMETER STACK
        SUBS    R5, R5, #4
        STR     R0, [R5]
        LDM     R6!, {R3}
        LDR     R0, [R3]
        BX      R0


# *************
# *   DIGIT   *
# *************
#
        .align 1
        .global rf_code_digit
        .syntax unified
        .thumb_func
        .code 16
rf_code_digit:
        LDRB    R3, [R5]        @ NUMBER BASE
        ADDS    R5, R5, #4
        LDRB    R0, [R5]        @ ASCII DIGIT
        ADDS    R5, R5, #4
        SUBS    R0, R0, #'0'
        BLT     DIGI2           @ NUMBER ERROR
        CMP     R0, #9
        BLE     DIGI1           @ NUMBER = 0 THRU 9
        SUBS    R0, R0, #7
        CMP     R0, #10         @ NUMBER 'A' THRU 'Z' ?
        BLT     DIGI2           @ NO
#
DIGI1:  CMP     R0, R3          @ COMPARE NUMBER TO BASE
        BGE     DIGI2           @ NUMBER ERROR
#       SUBS    R3, R3, R3      @ ZERO
        MOV     R3, R0          @ NEW BINARY NUMBER
        MOVS    R0, #1          @ TRUE FLAG
#       B       DPUSH           @ ADD TO STACK
        SUBS    R5, R5, #8
        STR     R3, [R5, #4]
        STR     R0, [R5]
        LDM     R6!, {R3}
        LDR     R0, [R3]
        BX      R0

# NUMBER ERROR
#
DIGI2:  MOVS    R0, #0          @ FALSE FLAG
#       B       APUSH           @ BYE
        SUBS    R5, R5, #4
        STR     R0, [R5]
        LDM     R6!, {R3}
        LDR     R0, [R3]
        BX      R0


# **************
# *   (FIND)   *
# **************
#
        .align 1
        .global rf_code_pfind
        .syntax unified
        .thumb_func
        .code 16
rf_code_pfind:
        LDM     R5!, {R1, R2}   @ NFA
                                @ STRING ADDR
        PUSH    {R4, R5, R6}
#
# SEARCH LOOP
PFIN1:  MOV     R4, R2          @ GET ADDR
        LDRB    R0, [R1]        @ GET WORD LENGTH
        MOV     R3, R0          @ SAVE LENGTH
        LDRB    R5, [R4]
        EORS    R0, R5
        MOVS    R6, #63
        ANDS    R0, R6          @ CHECK LENGTHS
        BNE     PFIN5           @ LENGTHS DIFFER
#
# LENGTH MATCH, CHECK EACH CHARACTER IN NAME
PFIN2:  ADDS    R1, R1, #1
        ADDS    R4, R4, #1      @ NEXT CHAR OF NAME
        LDRB    R0, [R1]
        LDRB    R5, [R4]        @ COMPARE NAMES
        EORS    R0, R5
        MOVS    R6, #127
        TST     R0, R6
        BNE     PFIN5           @ NO MATCH
        MOVS    R6, #128
        TST     R0, R6          @ THIS WILL TEST BIT-8
        BEQ     PFIN2           @ MATCH SO FAR, LOOP

# FOUND END OF NAME (BIT-8 SET); A MATCH
        POP     {R4, R5, R6}
        ADDS    R1, R1, #9      @ BX = PFA
        SUBS    R5, R5, #4
        STR     R1, [R5]        @ (S3) <- PFA
        MOVS    R0, #1          @ TRUE VALUE
        MOVS    R1, #255
        ANDS    R3, R1          @ CLEAR HIGH LENGTH
#       B       DPUSH
        SUBS    R5, R5, #8
        STR     R3, [R5, #4]
        STR     R0, [R5]
        LDM     R6!, {R3}
        LDR     R0, [R3]
        BX      R0

# NO NAME FIELD MATCH, TRY ANOTHER
#
# GET NEXT LINK FIELD ADDR (LFA)
# (ZERO = FIRST WORD OF DICTIONARY)
#
PFIN5:  ADDS    R1, R1, #1      @ NEXT ADDR
        MOVS    R6, #128
        TST     R0, R6          @ END OF NAME
        BNE     PFIN6
        LDRB    R0, [R1]        @ GET NEXT CHAR
        B       PFIN5           @ LOOP UNTIL FOUND
#
PFIN6:  LDR     R1, [R1]        @ GET LINK FIELD ADDR
        ORRS    R1, R1          @ START OF DICT. (0)?
        BNE     PFIN1           @ NO, LOOK SOME MORE
        MOVS    R0, #0          @ FALSE FLAG
        POP     {R4, R5, R6}
#       B       APUSH           @ DONE (NO MATCH FOUND)
        SUBS    R5, R5, #4
        STR     R0, [R5]
        LDM     R6!, {R3}
        LDR     R0, [R3]
        BX      R0


# ***************
# *   ENCLOSE   *
# ***************
#
        .align 1
        .global rf_code_encl
        .syntax unified
        .thumb_func
        .code 16
rf_code_encl:
        LDM     R5!, {R0}       @ S1 - TERMINATOR CHAR.
        LDR     R1, [R5]        @ S2 - TEXT ADDR
                                @ ADDR BACK TO STACK
        MOVS    R2, #255
        ANDS    R0, R2          @ ZERO
        MOVS    R3, #0          @ CHAR OFFSET COUNTER
        SUBS    R3, R3, #1
        SUBS    R1, R1, #1      @ ADDR -1

# SCAN TO FIRST NON-TERMINATOR CHAR
#
ENCL1:  ADDS    R1, R1, #1      @ ADDR +1
        ADDS    R3, R3, #1      @ COUNT +1
        LDRB    R2, [R1]
        CMP     R0, R2
        BEQ     ENCL1           @ WAIT FOR NON-TERMINATOR
        SUBS    R5, R5, #4
        STR     R3, [R5]        @ OFFSET TO 1ST TEXT CHR
        CMP     R2, #0          @ NULL CHAR?
        BNE     ENCL2           @ NO

# FOUND NULL BEFORE FIRST NON-TERMINATOR CHAR.
        MOV     R0, R3          @ COPY COUNTER
        ADDS    R3, R3, #1      @ +1
#       B       DPUSH
        SUBS    R5, R5, #8
        STR     R3, [R5, #4]
        STR     R0, [R5]
        LDM     R6!, {R3}
        LDR     R0, [R3]
        BX      R0

# FOUND FIRST TEXT CHAR, COUNT THE CHARACTERS
#
ENCL2:  ADDS    R1, R1, #1      @ ADDR+1
        ADDS    R3, R3, #1      @ COUNT +1
        LDRB    R2, [R1]        @ TERMINATOR CHAR?
        CMP     R0, R2
        BEQ     ENCL4           @ YES
        CMP     R2, #0          @ NULL CHAR
        BNE     ENCL2           @ NO, LOOP AGAIN

# FOUND NULL AT END OF TEXT
#
ENCL3:  MOV     R0, R3          @ COUNTERS ARE EQUAL
#       B       DPUSH
        SUBS    R5, R5, #8
        STR     R3, [R5, #4]
        STR     R0, [R5]
        LDM     R6!, {R3}
        LDR     R0, [R3]
        BX      R0

# FOUND TERINATOR CHARACTER
ENCL4:  MOV     R0, R3
        ADDS    R0, R0, #1      @ COUNT +1
#       B       DPUSH
        SUBS    R5, R5, #8
        STR     R3, [R5, #4]
        STR     R0, [R5]
        LDM     R6!, {R3}
        LDR     R0, [R3]
        BX      R0


# *************
# *   CMOVE   *
# *************
#
        .align 1
        .global rf_code_cmove
        .syntax unified
        .thumb_func
        .code 16
rf_code_cmove:
        LDM     R5!, {R1, R2, R3} @ COUNT
                                @ DEST.
                                @ SOURCE
        CMP     R1, #0
        BEQ     CMOV2
CMOV1:  LDRB    R0, [R3]        @ THATS THE MOVE
        ADDS    R3, R3, #1
        STRB    R0, [R2]
        ADDS    R2, R2, #1
        SUBS    R1, R1, #1
        BNE     CMOV1
CMOV2:  @ B     NEXT
        LDM     R6!, {R3}
        LDR     R0, [R3]
        BX      R0


# **********
# *   U*   *
# **********
#
        .align 1
        .global rf_code_ustar
        .syntax unified
        .thumb_func
        .code 16
rf_code_ustar:
        LDM     R5!, {R0, R3}
        MOV     R8, R4
        UXTH    R2, R0
        LSRS    R1, R3, #16
        LSRS    R0, R0, #16
        MOV     R4, R0
        MULS    R0, R1
        UXTH    R3, R3
        MULS    R1, R2
        MULS    R4, R3
        MULS    R3, R2
        MOVS    R2, #0
        ADDS    R1, R4
        ADCS    R2, R2
        LSLS    R2, #16
        ADDS    R0, R2
        LSLS    R2, R1, #16
        LSRS    R1, #16
        ADDS    R3, R2
        ADCS    R0, R1
        MOV     R4, R8
#       B       DPUSH           @ STORE DOUBLE WORD
        SUBS    R5, R5, #8
        STR     R3, [R5, #4]
        STR     R0, [R5]
        LDM     R6!, {R3}
        LDR     R0, [R3]
        BX      R0


# **********
# *   U/   *
# **********
#
        .align 1
        .global rf_code_uslas
        .syntax unified
        .thumb_func
        .code 16
rf_code_uslas:
        LDM     R5!, {R0, R1, R2} @ DIVISOR
                                @ MSW OF DIVIDEND
                                @ LSW OF DIVIDEND
        MOV     R8, R4
        MOVS    R3, #1
        LSLS    R3, R3, #31     @ init mask with highest bit set
        MOVS    R4, #0          @ init quot
        CMP     R1, R0          @ test modh - div
        BLO     UMDIV1          @ modh < div
        @ overflow condition ( divide by zero ) - show max numbers
        ASRS    R4, R3, #31
        MOV     R1, R4
        BAL     UMDIV3          @ return
UMDIV1: ADDS    R2, R2, R2      @ double precision shift (modh, modl)
        ADCS    R1, R1, R1      @ ADD with carry and set flags again !
        BCS     UMDIV4
        CMP     R0, R1          @ test div - modh
        BHI     UMDIV2          @ div >  modh ?
UMDIV4: ADDS    R4, R4, R3      @ add single pecision mask
        SUBS    R1, R1, R0      @ subtract single precision div
UMDIV2: LSRS    R3, R3, #1      @ shift mask one bit to the right
        ANDS    R3, R3, R3
        BNE     UMDIV1
UMDIV3: SUBS    R5, R5, #8
        STR     R1, [R5, #4]    @ remainder
        STR     R4, [R5]        @ quotient
        MOV     R4, R8
#       B       NEXT
        LDM     R6!, {R3}
        LDR     R0, [R3]
        BX      R0


# ***********
# *   AND   *
# ***********
#
        .align 1
        .global rf_code_andd
        .syntax unified
        .thumb_func
        .code 16
rf_code_andd:
        LDM     R5!, {R0}
        LDR     R1, [R5]
        ANDS    R0, R0, R1
        STR     R0, [R5]
#       B       NEXT
        LDM     R6!, {R3}
        LDR     R0, [R3]
        BX      R0


# **********
# *   OR   *
# **********
#
        .align 1
        .global rf_code_orr
        .syntax unified
        .thumb_func
        .code 16
rf_code_orr:
        LDM     R5!, {R0}
        LDR     R1, [R5]
        ORRS    R0, R0, R1
        STR     R0, [R5]
#       B       NEXT
        LDM     R6!, {R3}
        LDR     R0, [R3]
        BX      R0


# ***********
# *   XOR   *
# ***********
#
        .align 1
        .global rf_code_xorr
        .syntax unified
        .thumb_func
        .code 16
rf_code_xorr:
        LDM     R5!, {R0}
        LDR     R1, [R5]
        EORS    R0, R0, R1
        STR     R0, [R5]
#       B       NEXT
        LDM     R6!, {R3}
        LDR     R0, [R3]
        BX      R0


# ***********
# *   SP@   *
# ***********
#
        .align 1
        .global rf_code_spat
        .syntax unified
        .thumb_func
        .code 16
rf_code_spat:
        MOV     R0, R5
#       B       APUSH
        SUBS    R5, R5, #4
        STR     R0, [R5]
        LDM     R6!, {R3}
        LDR     R0, [R3]
        BX      R0


# ***********
# *   SP!   *
# ***********
#
        .align 1
        .global rf_code_spsto
        .syntax unified
        .thumb_func
        .code 16
rf_code_spsto:
        LDR     R1, =rf_up      @ USER VAR BASE ADDR
        LDR     R1, [R1]
        LDR     R5, [R1, #12]   @ RESET PARAM. STACK PT.
#       B       NEXT
        LDM     R6!, {R3}
        LDR     R0, [R3]
        BX      R0


# ***********
# *   RP!   *
# ***********
#
        .align 1
        .global rf_code_rpsto
        .syntax unified
        .thumb_func
        .code 16
rf_code_rpsto:
        LDR     R1, =rf_up      @ (AX) <- USR VAR. BASE
        LDR     R1, [R1]
        LDR     R4, [R1, #16]   @ RESET RETURN STACK PT.
#       B       NEXT
        LDM     R6!, {R3}
        LDR     R0, [R3]
        BX      R0


# **********
# *   ;S   *
# **********
#
        .align 1
        .global rf_code_semis
        .syntax unified
        .thumb_func
        .code 16
rf_code_semis:
        LDM     R4!, {R6}       @ (IP) <- (R1)
#       B       NEXT
        LDM     R6!, {R3}
        LDR     R0, [R3]
        BX      R0


# *************
# *   LEAVE   *
# *************
#
        .align 1
        .global rf_code_leave
        .syntax unified
        .thumb_func
        .code 16
rf_code_leave:
        LDR     R0, [R4]        @ GET INDEX
        STR     R0, [R4, #4]    @ STORE IT AT LIMIT
#       B       NEXT
        LDM     R6!, {R3}
        LDR     R0, [R3]
        BX      R0


# **********
# *   >R   *
# **********
#
        .align 1
        .global rf_code_tor
        .syntax unified
        .thumb_func
        .code 16
rf_code_tor:
        LDM     R5!, {R1}       @ GET STACK PARAMETER
        SUBS    R4, R4, #4
        STR     R1, [R4]        @ ADD TO RETURN STACK
#       B       NEXT
        LDM     R6!, {R3}
        LDR     R0, [R3]
        BX      R0


# **********
# *   R>   *
# **********
#
        .align 1
        .global rf_code_fromr
        .syntax unified
        .thumb_func
        .code 16
rf_code_fromr:
        LDM     R4!, {R1}       @ GET RETURN STACK VALUE
        SUBS    R5, R5, #4
        STR     R1, [R5]        @ DELETE FROM STACK
#       B       NEXT
        LDM     R6!, {R3}
        LDR     R0, [R3]
        BX      R0


# **********
# *   0=   *
# **********
#
        .align 1
        .global rf_code_zequ
        .syntax unified
        .thumb_func
        .code 16
rf_code_zequ:
        LDM     R5!, {R1}
        MOVS    R0, #1          @ TRUE
        ORRS    R1, R1          @ DO TEST
        BEQ     ZEQU1           @ ITS ZERO
        SUBS    R0, R0, #1      @ FALSE
ZEQU1:  @B      APUSH
        SUBS    R5, R5, #4
        STR     R0, [R5]
        LDM     R6!, {R3}
        LDR     R0, [R3]
        BX      R0


# **********
# *   0<   *
# **********
#
        .align 1
        .global rf_code_zless
        .syntax unified
        .thumb_func
        .code 16
rf_code_zless:
        LDM     R5!, {R1}
        MOVS    R0, #1          @ TRUE
        ORRS    R1, R1          @ SET FLAGS
        BMI     ZLESS1
        SUBS    R0, R0, #1      @ FLASE
ZLESS1: @B      APUSH
        SUBS    R5, R5, #4
        STR     R0, [R5]
        LDM     R6!, {R3}
        LDR     R0, [R3]
        BX      R0


# *********
# *   +   *
# *********
#
        .align 1
        .global rf_code_plus
        .syntax unified
        .thumb_func
        .code 16
rf_code_plus:
        LDM     R5!, {R0, R1}
        ADDS    R0, R0, R1
#       B       APUSH
        SUBS    R5, R5, #4
        STR     R0, [R5]
        LDM     R6!, {R3}
        LDR     R0, [R3]
        BX      R0


# **********
# *   D+   *
# **********
#
# XLW XHW  YLW YHW --> SLW SHW
# S4  S3   S2  S1      S2  S1
#
        .align 1
        .global rf_code_dplus
        .syntax unified
        .thumb_func
        .code 16
rf_code_dplus:
        LDM     R5!, {R0, R1, R2, R3} @ YHW
                                @ YLW
                                @ XHW
                                @ XLW
        ADDS    R3, R3, R1      @ SLW
        adcs    R0, R0, R2      @ SHW
#       B       DPUSH
        SUBS    R5, R5, #8
        STR     R3, [R5, #4]
        STR     R0, [R5]
        LDM     R6!, {R3}
        LDR     R0, [R3]
        BX      R0


# *************
# *   MINUS   *
# *************
#
        .align 1
        .global rf_code_minus
        .syntax unified
        .thumb_func
        .code 16
rf_code_minus:
        LDM     R5!, {R0}
        NEGS    R0, R0
#       B       APUSH
        SUBS    R5, R5, #4
        STR     R0, [R5]
        LDM     R6!, {R3}
        LDR     R0, [R3]
        BX      R0


# **************
# *   DMINUS   *
# **************
#
        .align 1
        .global rf_code_dminu
        .syntax unified
        .thumb_func
        .code 16
rf_code_dminu:
        LDM     R5!, {R1, R2}
        SUBS    R0, R0, R0      @ ZERO
        MOV     R3, R0
        SUBS    R3, R3, R2      @ MAKE 2'S COMPLEMENT
        SBCS    R0, R0, R1      @ HIGH WORD
#       B       DPUSH
        SUBS    R5, R5, #8
        STR     R3, [R5, #4]
        STR     R0, [R5]
        LDM     R6!, {R3}
        LDR     R0, [R3]
        BX      R0


# ************
# *   OVER   *
# ************
#
        .align 1
        .global rf_code_over
        .syntax unified
        .thumb_func
        .code 16
rf_code_over:
        LDR     R0, [R5, #4]
#       B       APUSH
        SUBS    R5, R5, #4
        STR     R0, [R5]
        LDM     R6!, {R3}
        LDR     R0, [R3]
        BX      R0


# ************
# *   DROP   *
# ************
#
        .align 1
        .global rf_code_drop
        .syntax unified
        .thumb_func
        .code 16
rf_code_drop:
        ADDS    R5, R5, #4
#       B       NEXT
        LDM     R6!, {R3}
        LDR     R0, [R3]
        BX      R0


# ************
# *   SWAP   *
# ************
#
        .align 1
        .global rf_code_swap
        .syntax unified
        .thumb_func
        .code 16
rf_code_swap:
        LDR     R3, [R5]
        LDR     R0, [R5, #4]
        STR     R3, [R5, #4]
        STR     R0, [R5]
#       B       NEXT
        LDM     R6!, {R3}
        LDR     R0, [R3]
        BX      R0


# ***********
# *   DUP   *
# ***********
#
        .align 1
        .global rf_code_dup
        .syntax unified
        .thumb_func
        .code 16
rf_code_dup:
        LDR     R0, [R5]
#       B       APUSH
        SUBS    R5, R5, #4
        STR     R0, [R5]
        LDM     R6!, {R3}
        LDR     R0, [R3]
        BX      R0


# **********
# *   +!   *
# **********
#
        .align 1
        .global rf_code_pstor
        .syntax unified
        .thumb_func
        .code 16
rf_code_pstor:
        LDM     R5!, {R0, R1}   @ ADDRESS
                                @ INCREMENT
        LDR     R2, [R0]
        ADD     R2, R2, R1
        STR     R2, [R0]
#       B       NEXT
        LDM     R6!, {R3}
        LDR     R0, [R3]
        BX      R0


# **************
# *   TOGGLE   *
# **************
#
        .align 1
        .global rf_code_toggl
        .syntax unified
        .thumb_func
        .code 16
rf_code_toggl:
        LDM     R5!, {R0, R1}   @ BIT PATTERN
                                @ ADDR
        LDRB    R2, [R1]
        EORS    R2, R2, R0
        STRB    R2, [R1]
#       B       NEXT
        LDM     R6!, {R3}
        LDR     R0, [R3]
        BX      R0


# *********
# *   @   *
# *********
#
        .align 1
        .global rf_code_at
        .syntax unified
        .thumb_func
        .code 16
rf_code_at:
        LDR     R1, [R5]
        LDR     R0, [R1]
        STR     R0, [R5]
#       B       NEXT
        LDM     R6!, {R3}
        LDR     R0, [R3]
        BX      R0


# **********
# *   C@   *
# **********
#
        .align 1
        .global rf_code_cat
        .syntax unified
        .thumb_func
        .code 16
rf_code_cat:
        LDR     R1, [R5]
        LDRb    R0, [R1]
        STR     R0, [R5]
#       B       NEXT
        LDM     R6!, {R3}
        LDR     R0, [R3]
        BX      R0


# *********
# *   !   *
# *********
#
        .align 1
        .global rf_code_store
        .syntax unified
        .thumb_func
        .code 16
rf_code_store:
        LDM     R5!, {R0, R1}   @ ADDR
                                @ DATA
        STR     R1, [R0]
#       B       NEXT
        LDM     R6!, {R3}
        LDR     R0, [R3]
        BX      R0


# **********
# *   C!   *
# **********
#
        .align 1
        .global rf_code_cstor
        .syntax unified
        .thumb_func
        .code 16
rf_code_cstor:
        LDM     R5!, {R0, R1}   @ ADDR
                                @ DATA
        STRB    R1, [R0]
#       B       NEXT
        LDM     R6!, {R3}
        LDR     R0, [R3]
        BX      R0


# *********
# *   :   *
# *********
#
        .align 1
        .global rf_code_docol
        .syntax unified
        .thumb_func
        .code 16
rf_code_docol:
        ADDS    R3, R3, #4      @ W=W+1
        SUBS    R4, R4, #4
        STR     R6, [R4]        @ R1 <- (RP)
        MOV     R6, R3          @ (IP) <- (W)
#       B       NEXT
        LDM     R6!, {R3}
        LDR     R0, [R3]
        BX      R0


# ****************
# *   CONSTANT   *
# ****************
#
        .align 1
        .global rf_code_docon
        .syntax unified
        .thumb_func
        .code 16
rf_code_docon:
        LDR     R0, [R3, #4]    @ PFA
                                @ GET DATA
#       B       APUSH
        SUBS    R5, R5, #4
        STR     R0, [R5]
        LDM     R6!, {R3}
        LDR     R0, [R3]
        BX      R0

# ****************
# *   VARIABLE   *
# ****************
#
        .align 1
        .global rf_code_dovar
        .syntax unified
        .thumb_func
        .code 16
rf_code_dovar:
        ADDS    R3, R3, #4      @ (DE) <- PFA
        SUBS    R5, R5, #4
        STR     R3, [R5]        @ (S1) <- PFA
#       B       NEXT
        LDM     R6!, {R3}
        LDR     R0, [R3]
        BX      R0

# ************
# *   USER   *
# ************
#
        .align 1
        .global rf_code_douse
        .syntax unified
        .thumb_func
        .code 16
rf_code_douse:
        LDRB    R1, [R3, #4]    @ PFA
        LDR     R0, =rf_up      @ USER VARIABLE ADDR
        LDR     R0, [R0]
        ADD     R0, R0, R1
#       B       APUSH
        SUBS    R5, R5, #4
        STR     R0, [R5]
        LDM     R6!, {R3}
        LDR     R0, [R3]
        BX      R0


# *************
# *   DOES>   *
# *************
#
        .align 1
        .global rf_code_dodoe
        .syntax unified
        .thumb_func
        .code 16
rf_code_dodoe:
        SUBS    R4, R4, #4
        STR     R6, [R4]        @ (RP) <- (IP)
        LDR     R6, [R3, #4]    @ NEW CFA
        ADDS    R3, R3, #8      @ PFA
        SUBS    R5, R5, #4
        STR     R3, [R5]        @ PFA
#       B       NEXT
        LDM     R6!, {R3}
        LDR     R0, [R3]
        BX      R0


# ************
# *   S->D   *
# ************
#
        .align 1
        .global rf_code_stod
        .syntax unified
        .thumb_func
        .code 16
rf_code_stod:
        LDM     R5!, {R3}       @ S1
        SUBS    R0, R0, R0      @ AX = 0
        ORRS    R3, R3          @ SET FLAGS
        BPL     STOD1           @ POSITIVE NUMBER
        SUBS    R0, R0, #1      @ NEGITIVE NUMBER
STOD1:  @B      DPUSH
        SUBS    R5, R5, #8
        STR     R3, [R5, #4]
        STR     R0, [R5]
        LDM     R6!, {R3}
        LDR     R0, [R3]
        BX      R0

        .align 1
        .global rf_code_mon
        .syntax unified
        .thumb_func
        .code 16
rf_code_mon:
        PUSH    {LR}
        BL      rf_start
        LDR     R1, =rf_fp
        MOVS    R0, #0
        STR     R0, [R1]
        POP     {PC}
