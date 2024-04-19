# Modified for orterforth integration and aarch64 in 2023. Some
# info in the comments no longer applies (CP/M, 8086 register 
# names, segmentation, byte offsets).

        .arch armv8-a

        .text

        .align 2
        .global rf_trampoline
rf_trampoline:
        STP     X13, X14, [SP, #-16]!
        STP     X15, X30, [SP, #-16]!
tramp1: LDR     X0, =rf_fp
        LDR     X0, [X0]
        CBZ     X0, tramp2
        LDR     X15, =rf_ip     // IP to X15
        LDR     X15, [X15]
        LDR     X3, =rf_w       // W to X3
        LDR     X3, [X3]
        LDR     X14, =rf_sp     // SP to X14
        LDR     X14, [X14]
        LDR     X13, =rf_rp     // RP to X13
        LDR     X13, [X13]
        LDR     LR, =tramp1
        BR      X0
tramp2: LDP     X15, X30, [SP], #16
        LDP     X13, X14, [SP], #16
        RET

        .align 2
        .global rf_start
rf_start:
        LDR     X0, =rf_ip      // X15 to IP
        STR     X15, [X0]
        LDR     X0, =rf_w       // X3 to W
        STR     X3, [X0]
        LDR     X0, =rf_sp      // X14 to SP
        STR     X14, [X0]
        LDR     X0, =rf_rp      // X13 to RP
        STR     X13, [X0]
        RET

        .data

        .p2align 3
        .global rf_fp
rf_fp:  .quad 0

        .p2align 3
        .global rf_ip
rf_ip:  .quad 0

        .p2align 3
        .global rf_rp
rf_rp:  .quad 0

        .p2align 3
        .global rf_sp
rf_sp:  .quad 0

        .p2align 3
        .global rf_up
rf_up:  .quad 0

        .p2align 3
        .global rf_w
rf_w:   .quad 0

        .text

        .align 2
        .global rf_code_cold
rf_code_cold:
        LDR     X3, =rf_origin
        LDR     X3, [X3]
        LDR     X0, [X3, #48]   // FORTH vocabulary init
        LDR     X1, [X3, #168]
        STR     X0, [X1]
        LDR     X1, [X3, #64]   // UP init
        LDR     X0, =UP
        STR     X1, [X0]
        MOV     X2, #11         // USER variables init
        ADD     X3, X3, #48
COLD1:  LDR     X0, [X3], #8
        STR     X0, [X1], #8
        SUBS    X2, X2, #1
        BNE     COLD1
        LDR     X15, [X3, #40]  // IP init to ABORT
        B       rf_code_rpsto   // jump to RP!

        .align 2
        .global rf_code_cl
rf_code_cl:
        MOV     X0, #8
#       B       APUSH
        STR     X0, [X14, #-8]!
        LDR     X3, [X15], #8
        LDR     X0, [X3]
        BR      X0

        .align 2
        .global rf_code_cs
rf_code_cs:
        LDR     X0, [X14]
        LSL     X0, X0, #3
#       B       APUSH
        STR     X0, [X14]
        LDR     X3, [X15], #8
        LDR     X0, [X3]
        BR      X0

        .align 2
        .global rf_code_ln
rf_code_ln:
        LDR     X0, [X14]
        SUB     X0, X0, #1
        ORR     X0, X0, #7
        ADD     X0, X0, #1
#       B       APUSH
        STR     X0, [X14]
        LDR     X3, [X15], #8
        LDR     X0, [X3]
        BR      X0

        .align 2
        .global rf_code_mon
rf_code_mon:
        STP     X29, X30, [SP, -16]!
        BL      rf_start
        LDR     X1, =rf_fp
        MOV     X0, #0
        STR     X0, [X1]
        LDP     X29, X30, [SP], 16
        RET

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
        .align 2
DPUSH:  STR     X3, [X14, #-8]!
APUSH:  STR     X0, [X14, #-8]!
#
# -----------------------------------------
#
# PATCH THE NEXT 3 LOCATIONS
# (USING A DEBUG MONITOR; I.E. DDT86)
# WITH  (JMP TNEXT)  FOR TRACING THROUGH
# HIGH LEVEL FORTH WORDS.
#
        .align 2
        .global rf_next
rf_next:
NEXT:   LDR     X3, [X15], #8   // (W) <- (IP)
NEXT1:  LDR     X0, [X3]        // TO 'CFA'
        BR      X0

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
        .align 2
        .global rf_code_lit
rf_code_lit:
        LDR     X0, [X15], #8   // AX <- LITERAL
#       B       APUSH           // TO TOP OF STACK
        STR     X0, [X14, #-8]!
        LDR     X3, [X15], #8
        LDR     X0, [X3]
        BR      X0


# ***************
# *   EXECUTE   *
# ***************
#
        .align 2
        .global rf_code_exec
rf_code_exec:
        LDR     X3, [X14], #8   // GET CFA
#       B       NEXT1           // EXECUTE NEXT
        LDR     X0, [X3]
        BR      X0


# **************
# *   BRANCH   *
# **************
#
        .align 2
        .global rf_code_bran
rf_code_bran:
BRAN1:  LDR     X0, [X15]
        ADD     X15, X15, X0    // (IP) <- (IP) + ((IP))
#       B       NEXT            // JUMP TO OFFSET
        LDR     X3, [X15], #8
        LDR     X0, [X3]
        BR      X0


# ***************
# *   0BRANCH   *
# ***************
#
        .align 2
        .global rf_code_zbran
rf_code_zbran:
        LDR     X0, [X14], #8   // GET STACK VALUE
        CBZ     X0, BRAN1       // ZERO?
                                // YES, BRANCH
        ADD     X15, X15, #8    // NO, CONTINUE...
#       B       NEXT
        LDR     X3, [X15], #8
        LDR     X0, [X3]
        BR      X0


# **************
# *   (LOOP)   *
# **************
#
        .align 2
        .global rf_code_xloop
rf_code_xloop:
        MOV     X1, #1          // INCREMENT
XLOO1:  LDR     X0, [X13]       // INDEX=INDEX+INCR
        ADD     X0, X0, X1
        STR     X0, [X13]       // GET NEW INDEX
        LDR     X2, [X13, #8]   // COMPARE WITH LIMIT
        SUB     X0, X0, X2
        EOR     X0, X0, X1      // TEST SIGN (BIT-16)
        TST     X0, X0
        BMI     BRAN1           // KEEP LOOPING...

# END OF 'DO' LOOP
        ADD     X13, X13, #16   // ADJ. RETURN STK
        ADD     X15, X15, #8    // BYPASS BRANCH OFFSET
#       B       NEXT            // CONTINUE...
        LDR     X3, [X15], #8
        LDR     X0, [X3]
        BR      X0


# ***************
# *   (+LOOP)   *
# ***************
#
        .align 2
        .global rf_code_xploo
rf_code_xploo:
        LDR     X1, [X14], #8   // GET LOOP VALUE
        B       XLOO1


# ************
# *   (DO)   *
# ************
#
        .align 2
        .global rf_code_xdo
rf_code_xdo:
        LDP     X3, X0, [X14], #16 // INITIAL INDEX VALUE
                                // LIMIT VALUE
        STP     X3, X0, [X13, #-16]!
#       B       NEXT
        LDR     X3, [X15], #8
        LDR     X0, [X3]
        BR      X0


# *********
# *   I   *
# *********
#
        .align 2
        .global rf_code_rr
rf_code_rr:
        LDR     X0, [X13]       // GET INDEX VALUE
#       B       APUSH           // TO PARAMETER STACK
        STR     X0, [X14, #-8]!
        LDR     X3, [X15], #8
        LDR     X0, [X3]
        BR      X0


# *************
# *   DIGIT   *
# *************
#
        .align 2
        .global rf_code_digit
rf_code_digit:
        LDRB    W3, [X14], #8   // NUMBER BASE
        LDRB    W0, [X14], #8   // ASCII DIGIT
        SUBS    X0, X0, #48
        BLT     DIGI2           // NUMBER ERROR
        CMP     X0, #9
        BLE     DIGI1           // NUMBER = 0 THRU 9
        SUB     X0, X0, #7
        CMP     X0, #10         // NUMBER 'A' THRU 'Z' ?
        BLT     DIGI2           // NO
#
DIGI1:  CMP     X0, X3          // COMPARE NUMBER TO BASE
        BGE     DIGI2           // NUMBER ERROR
        MOV     X3, X0          // NEW BINARY NUMBER
        MOV     X0, #1          // TRUE FLAG
#       B       DPUSH           // ADD TO STACK
        STP     X0, X3, [X14, #-16]!
        LDR     X3, [X15], #8
        LDR     X0, [X3]
        BR      X0

# NUMBER ERROR
#
DIGI2:  MOV     X0, #0          // FALSE FLAG
#       B       APUSH           // BYE
        STR     X0, [X14, #-8]!
        LDR     X3, [X15], #8
        LDR     X0, [X3]
        BR      X0


# **************
# *   (FIND)   *
# **************
#
        .align 2
        .global rf_code_pfind
rf_code_pfind:
        LDP     X1, X2, [X14], #16 // NFA
                                // STRING ADDR
#
# SEARCH LOOP
PFIN1:  MOV     X4, X2          // GET ADDR
        LDRB    W0, [X1]        // GET WORD LENGTH
        MOV     X3, X0          // SAVE LENGTH
        LDRB    W5, [X4]
        EOR     X0, X0, X5
        ANDS    X0, X0, #63     // CHECK LENGTHS
        BNE     PFIN5           // LENGTHS DIFFER
#
# LENGTH MATCH, CHECK EACH CHARACTER IN NAME
PFIN2:  ADD     X1, X1, #1
        ADD     X4, X4, #1      // NEXT CHAR OF NAME
        LDRB    W0, [X1]
        LDRB    W5, [X4]        // COMPARE NAMES
        EOR     X0, X0, X5
        TST     X0, #127
        BNE     PFIN5           // NO MATCH
        TST     X0, #128        // THIS WILL TEST BIT-8
        BEQ     PFIN2           // MATCH SO FAR, LOOP

# FOUND END OF NAME (BIT-8 SET); A MATCH
        ADD     X1, X1, #17     // BX = PFA
        STR     X1, [X14, #-8]! // (S3) <- PFA
        MOV     X0, #1          // TRUE VALUE
        AND     X3, X3, #255    // CLEAR HIGH LENGTH

#       B       DPUSH
        STP     X0, X3, [X14, #-16]!
        LDR     X3, [X15], #8
        LDR     X0, [X3]
        BR      X0

# NO NAME FIELD MATCH, TRY ANOTHER
#
# GET NEXT LINK FIELD ADDR (LFA)
# (ZERO = FIRST WORD OF DICTIONARY)
#
PFIN5:  ADD     X1, X1, #1      // NEXT ADDR
        TST     X0, #128        // END OF NAME
        BNE     PFIN6
        LDRB    W0, [X1]        // GET NEXT CHAR
        B       PFIN5           // LOOP UNTIL FOUND
#
PFIN6:  LDR     X1, [X1]        // GET LINK FIELD ADDR
        CBNZ    X1, PFIN1       // START OF DICT. (0)?
                                // NO, LOOK SOME MORE
        MOV     X0, #0          // FALSE FLAG

#       B       APUSH           // DONE (NO MATCH FOUND)
        STR     X0, [X14, #-8]!
        LDR     X3, [X15], #8
        LDR     X0, [X3]
        BR      X0


# ***************
# *   ENCLOSE   *
# ***************
#
        .align 2
        .global rf_code_encl
rf_code_encl:
        LDP     X0, X1, [X14], #8 // S1 - TERMINATOR CHAR.
                                // S2 - TEXT ADDR
        AND     X0, X0, #255    // ZERO
        MOV     X3, #-1         // CHAR OFFSET COUNTER
        SUB     X1, X1, #1      // ADDR -1

# SCAN TO FIRST NON-TERMINATOR CHAR
#
ENCL1:  ADD     X1, X1, #1      // ADDR +1
        ADD     X3, X3, #1      // COUNT +1
        LDRB    W2, [X1]
        CMP     X0, X2
        BEQ     ENCL1           // WAIT FOR NON-TERMINATOR
        STR     X3, [X14, #-8]! // OFFSET TO 1ST TEXT CHR
        CBNZ    X2, ENCL2       // NULL CHAR?
                                // NO
#
# FOUND NULL BEFORE FIRST NON-TERMINATOR CHAR.
        MOV     X0, X3          // COPY COUNTER
        ADD     X3, X3, #1      // +1
#       B       DPUSH
        STP     X0, X3, [X14, #-16]!
        LDR     X3, [X15], #8
        LDR     X0, [X3]
        BR      X0
#
# FOUND FIRST TEXT CHAR, COUNT THE CHARACTERS
#
ENCL2:  ADD     X1, X1, #1      // ADDR+1
        ADD     X3, X3, #1      // COUNT +1
        LDRB    W2, [X1]        // TERMINATOR CHAR?
        CMP     X0, X2
        BEQ     ENCL4           // YES
        CBNZ    X2, ENCL2       // NULL CHAR
                                // NO, LOOP AGAIN
#
# FOUND NULL AT END OF TEXT
#
ENCL3:  MOV     X0, X3          // COUNTERS ARE EQUAL
#       B       DPUSH
        STP     X0, X3, [X14, #-16]!
        LDR     X3, [X15], #8
        LDR     X0, [X3]
        BR      X0

# FOUND TERINATOR CHARACTER
ENCL4:  MOV     X0, X3
        ADD     X0, X0, #1      // COUNT +1
#       B       DPUSH
        STP     X0, X3, [X14, #-16]!
        LDR     X3, [X15], #8
        LDR     X0, [X3]
        BR      X0


# *************
# *   CMOVE   *
# *************
#
        .align 2
        .global rf_code_cmove
rf_code_cmove:
        LDP     X2, X1, [X14], #16 // COUNT
                                // DEST.
        LDR     X3, [X14], #8   // SOURCE
        CBZ     X2, CMOV2
CMOV1:  LDRB    W0, [X3], #1    // THATS THE MOVE
        STRB    W0, [X1], #1
        SUBS    X2, X2, #1
        BNE     CMOV1
CMOV2:  # B     NEXT
        LDR     X3, [X15], #8
        LDR     X0, [X3]
        BR      X0


# **********
# *   U*   *
# **********
#
        .align 2
        .global rf_code_ustar
rf_code_ustar:
        LDP     X2, X1, [X14], #16
        MUL     X3, X1, X2
        UMULH   X0, X1, X2
#       B       DPUSH
        STP     X0, X3, [X14, #-16]!
        LDR     X3, [X15], #8
        LDR     X0, [X3]
        BR      X0


# **********
# *   U/   *
# **********
#
        .align 2
        .global rf_code_uslas
rf_code_uslas:
        LDP     X2, X1, [X14], #16 // DIVISOR
                                // MSW OF DIVIDEND
        LDR     X0, [X14], #8   // LSW OF DIVIDEND
#       BL      umdiv
#umdiv:
        MOV     X3, #1
        LSL     X3, X3, #63     // init mask with highest bit set
        MOV     X4, #0          // init quot
        CMP     X1, X2          // test modh - div
        BLO     umdiv1          // modh < div
        # overflow condition ( divide by zero ) - show max numbers
        ASR     X4, X3, #63
        MOV     X1, X4

        B       umdiv3          // return

umdiv1: ADDS    X0, X0, X0      // double precision shift (modh, modl)
        ADCS    X1, X1, X1      // ADD with carry and set flags again !
        BCS     umdiv4
        CMP     X2, X1          // test div - modh
        BHI     umdiv2          // div >  modh ?
umdiv4: ADD     X4, X4, X3      // add single pecision mask
        SUB     X1, X1, X2      // subtract single precision div
umdiv2: LSR     X3, X3, #1      // shift mask one bit to the right
        CBNZ    X3, umdiv1
umdiv3: STP     X4, X1, [X14, #-16]! // remainder
                                // quotient

#       B     NEXT
        LDR   X3, [X15], #8
        LDR   X0, [X3]
        BR    X0


# ***********
# *   AND   *
# ***********
#
        .align 2
        .global rf_code_andd
rf_code_andd:
        LDP     X0, X1, [X14], #8
        AND     X0, X0, X1
        STR     X0, [X14]
#       B       NEXT
        LDR     X3, [X15], #8
        LDR     X0, [X3]
        BR      X0


# **********
# *   OR   *
# **********
#
        .align 2
        .global rf_code_orr
rf_code_orr:
        LDP     X0, X1, [X14], #8
        ORR     X0, X0, X1
        STR     X0, [X14]
#       B       NEXT
        LDR     X3, [X15], #8
        LDR     X0, [X3]
        BR      X0


# ***********
# *   XOR   *
# ***********
#
        .align 2
        .global rf_code_xorr
rf_code_xorr:
        LDP     X0, X1, [X14], #8
        EOR     X0, X0, X1
        STR     X0, [X14]
#       B       NEXT
        LDR     X3, [X15], #8
        LDR     X0, [X3]
        BR      X0


# ***********
# *   SP@   *
# ***********
#
        .align 2
        .global rf_code_spat
rf_code_spat:
        MOV     X0, X14
#       B       APUSH
        STR     X0, [X14, #-8]!
        LDR     X3, [X15], #8
        LDR     X0, [X3]
        BR      X0


# ***********
# *   SP!   *
# ***********
#
        .align 2
        .global rf_code_spsto
rf_code_spsto:
        LDR     X1, =UP         // USER VAR BASE ADDR
        LDR     X1, [X1]
        LDR     X14, [X1, #24]  // RESET PARAM. STACK PT.
#       B       NEXT
        LDR     X3, [X15], #8
        LDR     X0, [X3]
        BR      X0


# ***********
# *   RP!   *
# ***********
#
        .align 2
        .global rf_code_rpsto
rf_code_rpsto:
        LDR     X1, =UP         // (AX) <- USR VAR. BASE
        LDR     X1, [X1]
        LDR     X13, [X1, #32]  // RESET RETURN STACK PT.
#       B       NEXT
        LDR     X3, [X15], #8
        LDR     X0, [X3]
        BR      X0


# **********
# *   ;S   *
# **********
#
        .align 2
        .global rf_code_semis
rf_code_semis:
        LDR     X15, [X13], #8  // (IP) <- (R1)
#       B       NEXT            // ADJUST STACK
        LDR     X3, [X15], #8
        LDR     X0, [X3]
        BR      X0


# *************
# *   LEAVE   *
# *************
#
        .align 2
        .global rf_code_leave
rf_code_leave:
        LDR     X0, [X13]       // GET INDEX
        STR     X0, [X13, #8]   // STORE IT AT LIMIT
#       B       NEXT
        LDR     X3, [X15], #8
        LDR     X0, [X3]
        BR      X0


# **********
# *   >R   *
# **********
#
        .align 2
        .global rf_code_tor
rf_code_tor:
        LDR     X1, [X14], #8   // GET STACK PARAMETER
        STR     X1, [X13, #-8]! // ADD TO RETURN STACK
#       B       NEXT
        LDR     X3, [X15], #8
        LDR     X0, [X3]
        BR      X0


# **********
# *   R>   *
# **********
#
        .align 2
        .global rf_code_fromr
rf_code_fromr:
        LDR     X1, [X13], #8   // GET RETURN STACK VALUE
        STR     X1, [X14, #-8]! // DELETE FROM STACK
#       B       NEXT
        LDR     X3, [X15], #8
        LDR     X0, [X3]
        BR      X0


# **********
# *   0=   *
# **********
#
        .align 2
        .global rf_code_zequ
rf_code_zequ:
        LDR     X1, [X14], #8
                                // DO TEST
        MOV     X0, #1          // TRUE
        CBZ     X1, ZEQU1       // ITS ZERO
        SUB     X0, X0, #1      // FALSE
ZEQU1:  # B     APUSH
        STR     X0, [X14, #-8]!
        LDR     X3, [X15], #8
        LDR     X0, [X3]
        BR      X0


# **********
# *   0<   *
# **********
#
        .align 2
        .global rf_code_zless
rf_code_zless:
        LDR     X0, [X14], #8
        TST     X0, X0          // SET FLAGS
        MOV     X0, #1          // TRUE
        BMI     ZLESS1
        SUB     X0, X0, #1      // FLASE
ZLESS1: # B     APUSH
        STR     X0, [X14, #-8]!
        LDR     X3, [X15], #8
        LDR     X0, [X3]
        BR      X0


# *********
# *   +   *
# *********
#
        .align 2
        .global rf_code_plus
rf_code_plus:
        LDP     X0, X1, [X14], #16
        add     X0, X0, X1
        B       APUSH
        STR     X0, [X14, #-8]!
        LDR     X3, [X15], #8
        LDR     X0, [X3]
        BR      X0


# **********
# *   D+   *
# **********
#
# XLW XHW  YLW YHW --> SLW SHW
# S4  S3   S2  S1      S2  S1
#
        .align 2
        .global rf_code_dplus
rf_code_dplus:
        LDP     X0, X3, [X14], #16 // YHW
                                // YLW
        LDP     X1, X2, [X14], #16 // XHW
                                // XLW
        ADDS    X3, X3, X2      // SLW
        ADC     X0, X0, X1      // SHW
#       B       DPUSH
        STP     X0, X3, [X14, #-16]!
        LDR     X3, [X15], #8
        LDR     X0, [X3]
        BR      X0


# *************
# *   MINUS   *
# *************
#
        .align 2
        .global rf_code_minus
rf_code_minus:
        LDR     X0, [X14], #8
        NEG     X0, X0
#       B       APUSH
        STR     X0, [X14, #-8]!
        LDR     X3, [X15], #8
        LDR     X0, [X3]
        BR      X0


# **************
# *   DMINUS   *
# **************
#
        .align 2
        .global rf_code_dminu
rf_code_dminu:
        LDP     X1, X2, [X14], #16
        SUB     X0, X0, X0      // ZERO
        MOV     X3, X0
        SUBS    X3, X3, X2      // MAKE 2'S COMPLEMENT
        SBC     X0, X0, X1      // HIGH WORD
#       B       DPUSH
        STP     X0, X3, [X14, #-16]!
        LDR     X3, [X15], #8
        LDR     X0, [X3]
        BR      X0


# ************
# *   OVER   *
# ************
#
        .align 2
        .global rf_code_over
rf_code_over:
        LDR     X0, [X14, #8]
#       B       APUSH
        STR     X0, [X14, #-8]!
        LDR     X3, [X15], #8
        LDR     X0, [X3]
        BR      X0


# ************
# *   DROP   *
# ************
#
        .align 2
        .global rf_code_drop
rf_code_drop:
        ADD     X14, X14, #8
#       B       NEXT
        LDR     X3, [X15], #8
        LDR     X0, [X3]
        BR      X0


# ************
# *   SWAP   *
# ************
#
        .align 2
        .global rf_code_swap
rf_code_swap:
        LDP     X3, X0, [X14]
        STP     X0, X3, [X14]
#       B       NEXT
        LDR     X3, [X15], #8
        LDR     X0, [X3]
        BR      X0


# ***********
# *   DUP   *
# ***********
#
        .align 2
        .global rf_code_dup
rf_code_dup:
        LDR     X0, [X14]
#       B       APUSH
        STR     X0, [X14, #-8]!
        LDR     X3, [X15], #8
        LDR     X0, [X3]
        BR      X0


# **********
# *   +!   *
# **********
#
        .align 2
        .global rf_code_pstor
rf_code_pstor:
        LDP     X1, X0, [X14], #16 // ADDRESS
                                // INCREMENT
        LDR     X2, [X1]
        ADD     X2, X2, X0
        STR     X2, [X1]
#       B       NEXT
        LDR     X3, [X15], #8
        LDR     X0, [X3]
        BR      X0


# **************
# *   TOGGLE   *
# **************
#
        .align 2
        .global rf_code_toggl
rf_code_toggl:
        LDRB    W0, [X14], #8   // BIT PATTERN
        LDR     X1, [X14], #8   // ADDR
        LDRB    W2, [X1]
        EOR     W2, W2, W0
        STRB    W2, [X1]
#       B       NEXT
        LDR     X3, [X15], #8
        LDR     X0, [X3]
        BR      X0


# *********
# *   @   *
# *********
#
        .align 2
        .global rf_code_at
rf_code_at:
        LDR     X1, [X14]
        LDR     X0, [X1]
        STR     X0, [X14]
#       B       NEXT
        LDR     X3, [X15], #8
        LDR     X0, [X3]
        BR      X0


# **********
# *   C@   *
# **********
#
        .align 2
        .global rf_code_cat
rf_code_cat:
        LDR     X1, [X14]
        LDRB    W0, [X1]
        STR     X0, [X14]
#       B       NEXT
        LDR     X3, [X15], #8
        LDR     X0, [X3]
        BR      X0


# *********
# *   !   *
# *********
#
        .align 2
        .global rf_code_store
rf_code_store:
        LDP     X1, X0, [X14], #16 // ADDR
                                // DATA
        STR     X0, [X1]
#       B       NEXT
        LDR     X3, [X15], #8
        LDR     X0, [X3]
        BR      X0


# **********
# *   C!   *
# **********
#
        .align 2
        .global rf_code_cstor
rf_code_cstor:
        LDR     X1, [X14], #8   // ADDR
        LDRB    W0, [X14], #8   // DATA
        STRB    W0, [X1]
#       B       NEXT
        LDR     X3, [X15], #8
        LDR     X0, [X3]
        BR      X0


# *********
# *   :   *
# *********
#
        .align 2
        .global rf_code_docol
rf_code_docol:
        ADD     X3, X3, #8      // W=W+1
        STR     X15, [X13, #-8]! // R1 <- (RP)
        MOV     X15, X3         // (IP) <- (W)
#       B       NEXT
        LDR     X3, [X15], #8
        LDR     X0, [X3]
        BR      X0


# ****************
# *   CONSTANT   *
# ****************
#
        .align 2
        .global rf_code_docon
rf_code_docon:
        LDR     X0, [X3, #8]!   // PFA @ GET DATA
#       B       APUSH
        STR     X0, [X14, #-8]!
        LDR     X3, [X15], #8
        LDR     X0, [X3]
        BR      X0

# ****************
# *   VARIABLE   *
# ****************
#
        .align 2
        .global rf_code_dovar
rf_code_dovar:
        ADD     X3, X3, #8      // (DE) <- PFA
        STR     X3, [X14, #-8]! // (S1) <- PFA
#       B       NEXT
        LDR     X3, [X15], #8
        LDR     X0, [X3]
        BR      X0

# ************
# *   USER   *
# ************
#
        .align 2
        .global rf_code_douse
rf_code_douse:
        LDRB    W1, [X3, #8]!   // PFA
        LDR     X0, =UP         // USER VARIABLE ADDR
        LDR     X0, [X0]
        ADD     X0, X0, X1
#       B       APUSH
        STR     X0, [X14, #-8]!
        LDR     X3, [X15], #8
        LDR     X0, [X3]
        BR      X0


# *************
# *   DOES>   *
# *************
#
        .align 2
        .global rf_code_dodoe
rf_code_dodoe:
        STR     X15, [X13, #-8]! // (RP) <- (IP)
        ADD     X3, X3, #8      // PFA
        LDR     X15, [X3], #8   // NEW CFA
        STR     X3, [X14, #-8]! // PFA
#       B       NEXT
        LDR     X3, [X15], #8
        LDR     X0, [X3]
        BR      X0


# ************
# *   S->D   *
# ************
#
        .align 2
        .global rf_code_stod
rf_code_stod:
        LDR     X3, [X14], #8   // S1
        SUB     X0, X0, X0      // AX = 0
        TST     X3, X3          // SET FLAGS
        BPL     STOD1           // POSITIVE NUMBER
        SUB     X0, X0, #1      // NEGITIVE NUMBER
STOD1:  # B     DPUSH
        STP     X0, X3, [X14, #-16]!
        LDR     X3, [X15], #8
        LDR     X0, [X3]
        BR      X0
