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
        LDR   R0, =rf_fp
        LDR   R0, [R0]
        CMP   R0, #0
        BEQ   trampoline2
        LDR   R10, =rf_ip       @ IP to R10
        LDR   R10, [R10]
        LDR   R3, =rf_w         @ W to R3
        LDR   R3, [R3]
        LDR   R8, =rf_sp        @ SP to R8
        LDR   R8, [R8]
        LDR   R7, =rf_rp        @ RP to R7
        LDR   R7, [R7]
        LDR   LR, =trampoline1  @ return addr
        BX    R0
trampoline2:
        POP   {R7, R8, R10, FP, PC}

        .p2align 2
        .global rf_start
rf_start:
        LDR   R0, =rf_ip        @ R10 to IP
        STR   R10, [R0]
        LDR   R0, =rf_w         @ R3 to W
        STR   R3, [R0]
        LDR   R0, =rf_sp        @ R8 to SP
        STR   R8, [R0]
        LDR   R0, =rf_rp        @ R7 to RP
        STR   R7, [R0]
        BX    LR                @ carry on in C

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
        .globl rf_code_xdo
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
        .globl rf_code_rr
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
        .globl rf_code_digit
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

  .p2align 2
  .global rf_code_encl
rf_code_encl:
  ldr   r0, [r8], #4            @ S1 - TERMINATOR CHAR.
  ldr   r1, [r8]                @ S2 - TEXT ADDR
  and   r0, #255                @ ZERO
  mov   r3, #-1                 @ CHAR OFFSET COUNTER
  sub   r1, r1, #1              @ ADDR -1

@ SCAN TO FIRST NON-TERMINATOR CHAR
@
encl1:
  add   r1, r1, #1              @ ADDR +1
  add   r3, r3, #1              @ COUNT +1
  ldrb  r2, [r1]
  CMP   r0, r2
  beq   encl1                   @ WAIT FOR NON-TERMINATOR
  str   r3, [r8, #-4]!          @ OFFSET TO 1ST TEXT CHR
  cmp   r2, #0                  @ NULL CHAR?
  bne   encl2                   @ NO
@
@ FOUND NULL BEFORE FIRST NON-TERMINATOR CHAR.
  mov   r0, r3                  @ COPY COUNTER
  add   r3, r3, #1              @ +1
@ b     dpush
  stmdb r8!, {r0, r3}
  ldr   r3, [r10], #4
  ldr   r0, [r3]
  bx    r0
@
@ FOUND FIRST TEXT CHAR, COUNT THE CHARACTERS
@
encl2:
  add   r1, r1, #1              @ ADDR+1
  add   r3, r3, #1              @ COUNT +1
  ldrb  r2, [r1]                @ TERMINATOR CHAR?
  cmp   r0, r2
  beq   encl4                   @ YES
  cmp   r2, #0                  @ NULL CHAR
  bne   encl2                   @ NO, LOOP AGAIN
@
@ FOUND NULL AT END OF TEXT
@
encl3:
  mov   r0, r3                  @ COUNTERS ARE EQUAL
@ b     dpush
  stmdb r8!, {r0, r3}
  ldr   r3, [r10], #4
  ldr   r0, [r3]
  bx    r0

@ FOUND TERINATOR CHARACTER
encl4:
  mov   r0, r3
  add   r0, r0, #1              @ COUNT +1
@ b     dpush
  stmdb r8!, {r0, r3}
  ldr   r3, [r10], #4
  ldr   r0, [r3]
  bx    r0

  .p2align 2
  .global rf_code_cmove
rf_code_cmove:
  ldm   r8!, {r1, r2, r3}       @ COUNT
                                @ DEST.
                                @ SOURCE
  cmp   r1, #0
  beq   cmov2
cmov1:
  ldrb  r0, [r3], #1            @ THATS THE MOVE
  strb  r0, [r2], #1
  subs  r1, r1, #1
  bne   cmov1
cmov2:
@ b     next
  ldr   r3, [r10], #4
  ldr   r0, [r3]
  bx    r0

  .p2align 2
  .global rf_code_ustar
rf_code_ustar:
  ldm   r8!, {r1, r2}
  umull r3, r0, r1, r2
@ b     dpush
  stmdb r8!, {r0, r3}
  ldr   r3, [r10], #4
  ldr   r0, [r3]
  bx    r0

  .p2align 2
  .global rf_code_uslas
rf_code_uslas:
  ldm   r8!, {r0, r1, r2}       @ DIVISOR
                                @ MSW OF DIVIDEND
                                @ LSW OF DIVIDEND
@  bl   umdiv
@umdiv:
  mov   r3, #1
  lsl   r3, r3, #31             @ init mask with highest bit set
  mov   r4, #0                  @ init quot
  cmp   r1, r0                  @ test modh - div
  blo   umdiv1                  @ modh < div
  @ overflow condition ( divide by zero ) - show max numbers
  asr   r4, r3, #31
  mov   r1, r4

  bal   umdiv3                  @ return

umdiv1:
  adds  r2, r2, r2              @ double precision shift (modh, modl)
  adcs  r1, r1, r1              @ ADD with carry and set flags again !
  bcs   umdiv4
  cmp   r0, r1                  @ test div - modh
  bhi   umdiv2                  @ div >  modh ?
umdiv4:
  add   r4, r4, r3              @ add single pecision mask
  sub   r1, r1, r0              @ subtract single precision div
umdiv2:
  lsr   r3, r3, #1              @ shift mask one bit to the right
  ands  r3, r3, r3
  bne   umdiv1
umdiv3:
  str   r1, [r8, #-4]!          @ remainder
  str   r4, [r8, #-4]!          @ quotient
@ b     next
  ldr   r3, [r10], #4
  ldr   r0, [r3]
  bx    r0

  .p2align 2
  .global rf_code_andd
rf_code_andd:
  ldr   r0, [r8], #4
  ldr   r1, [r8]
  and   r0, r0, r1
  str   r0, [r8]
@ b     next
  ldr   r3, [r10], #4
  ldr   r0, [r3]
  bx    r0

  .p2align 2
  .global rf_code_orr
rf_code_orr:
  ldr   r0, [r8], #4
  ldr   r1, [r8]
  orr   r0, r0, r1
  str   r0, [r8]
@ b     next
  ldr   r3, [r10], #4
  ldr   r0, [r3]
  bx    r0

  .p2align 2
  .global rf_code_xorr
rf_code_xorr:
  ldr   r0, [r8], #4
  ldr   r1, [r8]
  eor   r0, r0, r1
  str   r0, [r8]
@ b     next
  ldr   r3, [r10], #4
  ldr   r0, [r3]
  bx    r0

  .p2align 2
  .global rf_code_spat
rf_code_spat:
  mov   r0, r8
@ b     apush
  str   r0, [r8, #-4]!
  ldr   r3, [r10], #4
  ldr   r0, [r3]
  bx    r0

  .p2align 2
  .global rf_code_spsto
rf_code_spsto:
  ldr   r1, =rf_up              @ USER VAR BASE ADDR
  ldr   r1, [r1]
  ldr   r8, [r1, #12]           @ RESET PARAM. STACK PT.
@ b     next
  ldr   r3, [r10], #4
  ldr   r0, [r3]
  bx    r0

  .p2align 2
  .global rf_code_rpsto
rf_code_rpsto:
  ldr   r1, =rf_up              @ (AX) <- USR VAR. BASE
  ldr   r1, [r1]
  ldr   r7, [r1, #16]           @ RESET RETURN STACK PT.
@ b     next
  ldr   r3, [r10], #4
  ldr   r0, [r3]
  bx    r0

  .p2align 2
  .global rf_code_semis
rf_code_semis:
  ldr   r10, [r7], #4           @ (IP) <- (R1)
@ b     next                    @ ADJUST STACK
  ldr   r3, [r10], #4
  ldr   r0, [r3]
  bx    r0

  .p2align 2
  .global rf_code_leave
rf_code_leave:
  ldr   r0, [r7]                @ GET INDEX
  str   r0, [r7, #4]            @ STORE IT AT LIMIT
@ b     next
  ldr   r3, [r10], #4
  ldr   r0, [r3]
  bx    r0

  .p2align 2
  .global rf_code_tor
rf_code_tor:
  ldr   r1, [r8], #4            @ GET STACK PARAMETER
  str   r1, [r7, #-4]!          @ ADD TO RETURN STACK
@ b     next
  ldr   r3, [r10], #4
  ldr   r0, [r3]
  bx    r0

  .p2align 2
  .global rf_code_fromr
rf_code_fromr:
  ldr   r1, [r7], #4            @ GET RETURN STACK VALUE
  str   r1, [r8, #-4]!          @ DELETE FROM STACK
@ b     next
  ldr   r3, [r10], #4
  ldr   r0, [r3]
  bx    r0

  .p2align 2
  .global rf_code_zequ
rf_code_zequ:
  ldr   r0, [r8], #4
  orrs  r0, r0                  @ DO TEST
  mov   r0, #1                  @ TRUE
  beq   APUSH
  @beq  zequ1                   @ ITS ZERO
  sub   r0, r0, #1              @ FALSE
zequ1:
@ b     apush
  str   r0, [r8, #-4]!
  ldr   r3, [r10], #4
  ldr   r0, [r3]
  bx    r0

  .p2align 2
  .global rf_code_zless
rf_code_zless:
  ldr   r0, [r8], #4
  orrs  r0, r0                  @ SET FLAGS
  mov   r0, #1                  @ TRUE
  bmi   APUSH
  @bmi  zless1
  sub   r0, r0, #1              @ FLASE
zless1:
@ b     apush
  str   r0, [r8, #-4]!
  ldr   r3, [r10], #4
  ldr   r0, [r3]
  bx    r0

  .p2align 2
  .global rf_code_plus
rf_code_plus:
  ldm   r8!, {r0, r1}
  add   r0, r0, r1
@ b     apush
  str   r0, [r8, #-4]!
  ldr   r3, [r10], #4
  ldr   r0, [r3]
  bx    r0

  .p2align 2
  .global rf_code_dplus
rf_code_dplus:
  ldm   r8!, {r0, r1, r2, r3}   @ YHW
                                @ YLW
                                @ XHW
                                @ XLW
  adds  r1, r1, r3              @ SLW
  adc   r0, r0, r2              @ SHW
@ b     dpush
  stmdb r8!, {r0, r1}
  ldr   r3, [r10], #4
  ldr   r0, [r3]
  bx    r0

  .p2align 2
  .global rf_code_minus
rf_code_minus:
  ldr   r0, [r8]
  neg   r0, r0
@ b     apush
  str   r0, [r8]
  ldr   r3, [r10], #4
  ldr   r0, [r3]
  bx    r0

  .p2align 2
  .global rf_code_dminu
rf_code_dminu:
  ldm   r8!, {r1, r2}
  sub   r0, r0, r0              @ ZERO
  mov   r3, r0
  subs  r3, r3, r2              @ MAKE 2'S COMPLEMENT
  sbc   r0, r0, r1              @ HIGH WORD
@ b     dpush
  stmdb r8!, {r0, r3}
  ldr   r3, [r10], #4
  ldr   r0, [r3]
  bx    r0

  .p2align 2
  .global rf_code_over
rf_code_over:
  ldr   r0, [r8, #4]
@ b     apush
  str   r0, [r8, #-4]!
  ldr   r3, [r10], #4
  ldr   r0, [r3]
  bx    r0

  .p2align 2
  .global rf_code_drop
rf_code_drop:
  add   r8, r8, #4
@ b     next
  ldr   r3, [r10], #4
  ldr   r0, [r3]
  bx    r0

  .p2align 2
  .global rf_code_swap
rf_code_swap:
  ldm   r8, {r0, r3}
  str   r0, [r8, #4]
  str   r3, [r8]
@ b     next
  ldr   r3, [r10], #4
  ldr   r0, [r3]
  bx    r0

  .p2align 2
  .global rf_code_dup
rf_code_dup:
  ldr   r0, [r8]
@ b     apush
  str   r0, [r8, #-4]!
  ldr   r3, [r10], #4
  ldr   r0, [r3]
  bx    r0

  .p2align 2
  .global rf_code_pstor
rf_code_pstor:
  ldm   r8!, {r0, r1}           @ ADDRESS
                                @ INCREMENT
  ldr   r2, [r0]
  add   r2, r2, r1
  str   r2, [r0]
@ b     next
  ldr   r3, [r10], #4
  ldr   r0, [r3]
  bx    r0

  .p2align 2
  .global rf_code_toggl
rf_code_toggl:
  ldm   r8!, {r0, r1}           @ BIT PATTERN
                                @ ADDR
  ldrb  r2, [r1]
  eor   r2, r2, r0
  strb  r2, [r1]
@ b     next
  ldr   r3, [r10], #4
  ldr   r0, [r3]
  bx    r0

  .p2align 2
  .global rf_code_at
rf_code_at:
  ldr   r1, [r8]
  ldr   r0, [r1]
  str   r0, [r8]
@ b     next
  ldr   r3, [r10], #4
  ldr   r0, [r3]
  bx    r0

  .p2align 2
  .global rf_code_cat
rf_code_cat:
  ldr   r1, [r8]
  ldrb  r0, [r1]
  str   r0, [r8]
@ b     next
  ldr   r3, [r10], #4
  ldr   r0, [r3]
  bx    r0

  .p2align 2
  .global rf_code_store
rf_code_store:
  ldm   r8!, {r0, r1}           @ ADDR
                                @ DATA
  str   r1, [r0]
@ b     next
  ldr   r3, [r10], #4
  ldr   r0, [r3]
  bx    r0

  .p2align 2
  .global rf_code_cstor
rf_code_cstor:
  ldm   r8!, {r0, r1}           @ ADDR
                                @ DATA
  strb  r1, [r0]
@ b     next
  ldr   r3, [r10], #4
  ldr   r0, [r3]
  bx    r0

  .p2align 2
  .global rf_code_docol
rf_code_docol:
  add   r3, r3, #4              @ W=W+1
  str   r10, [r7, #-4]!         @ R1 <- (RP)
  mov   r10, r3                 @ (IP) <- (W)
@ b     next
  ldr   r3, [r10], #4
  ldr   r0, [r3]
  bx    r0

  .p2align 2
  .global rf_code_docon
rf_code_docon:
  ldr   r0, [r3, #4]            @ PFA @ GET DATA
@ b     apush
  str   r0, [r8, #-4]!
  ldr   r3, [r10], #4
  ldr   r0, [r3]
  bx    r0

  .p2align 2
  .global rf_code_dovar
rf_code_dovar:
  add   r3, r3, #4              @ (DE) <- PFA
  str   r3, [r8, #-4]!          @ (S1) <- PFA
@ b     next
  ldr   r3, [r10], #4
  ldr   r0, [r3]
  bx    r0

  .p2align 2
  .global rf_code_douse
rf_code_douse:
  ldrb  r1, [r3, #4]            @ PFA
  ldr   r0, =rf_up              @ USER VARIABLE ADDR
  ldr   r0, [r0]
  add   r0, r0, r1
@ b     apush
  str   r0, [r8, #-4]!
  ldr   r3, [r10], #4
  ldr   r0, [r3]
  bx    r0

  .p2align 2
  .global rf_code_dodoe
rf_code_dodoe:
  str   r10, [r7, #-4]!         @ (RP) <- (IP)
  add   r3, r3, #4              @ PFA
  ldr   r10, [r3], #4           @ NEW CFA
  str   r3, [r8, #-4]!          @ PFA
@ b     next
  ldr   r3, [r10], #4
  ldr   r0, [r3]
  bx    r0

  .p2align 2
  .global rf_code_stod
rf_code_stod:
  ldr   r3, [r8], #4            @ S1
  sub   r0, r0, r0              @ AX = 0
  orrs  r3, r3                  @ SET FLAGS
  bpl   stod1                   @ POSITIVE NUMBER
  sub   r0, r0, #1              @ NEGITIVE NUMBER
stod1:
@ b     dpush
  stmdb r8!, {r0, r3}
  ldr   r3, [r10], #4
  ldr   r0, [r3]
  bx    r0

  .p2align 2
  .global rf_code_cold
rf_code_cold:
  ldr   r3, =rf_origin
  ldr   r3, [r3]
  ldr   r0, [r3, #24]           @ FORTH vocabulary init
  ldr   r1, [r3, #68]
  str   r0, [r1]
  ldr   r1, [r3, #32]           @ UP init
  ldr   r0, =rf_up
  str   r1, [r0]
  mov   r2, #11                 @ USER variables init
  add   r3, r3, #24
cold1:
  ldr   r0, [r3], #4
  str   r0, [r1], #4
  subs  r2, r2, #1
  bne   cold1
  ldr   r10, [r3, #4]           @ IP init to ABORT
  b     rf_code_rpsto           @ jump to RP!

  .p2align 2
  .global rf_code_cl
rf_code_cl:
  mov   r0, #4
@ b     apush
  str   r0, [r8, #-4]!
  ldr   r3, [r10], #4
  ldr   r0, [r3]
  bx    r0

  .p2align 2
  .global rf_code_cs
rf_code_cs:
  ldr   r0, [r8]
  lsl   r0, #2
@ b     apush
  str   r0, [r8]
  ldr   r3, [r10], #4
  ldr   r0, [r3]
  bx    r0

  .p2align 2
  .global rf_code_ln
rf_code_ln:
  ldr   r0, [r8]
  tst   r0, #3
  beq   ln1
  and   r0, r0, #-4
  add   r0, r0, #4
ln1:
@ b     apush
  str   r0, [r8]
  ldr   r3, [r10], #4
  ldr   r0, [r3]
  bx    r0

  .p2align 2
  .global rf_code_xt
rf_code_xt:
  push  {fp, lr}
  bl    rf_start
  ldr   r1, =rf_fp
  mov   r0, #0
  str   r0, [r1]
  pop   {fp, pc}
