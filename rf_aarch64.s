        .arch armv8-a

        .text

        .align 2
        .global rf_trampoline
rf_trampoline:
        stp     x13, x14, [sp, #-16]!
        stp     x15, x30, [sp, #-16]!
tramp1: ldr     x0, =rf_fp
        ldr     x0, [x0]
        cbz     x0, tramp2
        ldr     x15, =rf_ip
        ldr     x15, [x15]
        ldr     x3, =rf_w
        ldr     x3, [x3]
        ldr     x14, =rf_sp
        ldr     x14, [x14]
        ldr     x13, =rf_rp
        ldr     x13, [x13]
        ldr     lr, =tramp1
        br      x0
tramp2: ldp     x15, x30, [sp], #16
        ldp     x13, x14, [sp], #16
        ret

        .align 2
        .global rf_start
rf_start:
        ldr     x0, =rf_ip
        str     x15, [x0]
        ldr     x0, =rf_w
        str     x3, [x0]
        ldr     x0, =rf_sp
        str     x14, [x0]
        ldr     x0, =rf_rp
        str     x13, [x0]
        ret

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
        .global rf_code_lit
rf_code_lit:
        ldr     x0, [x15], #8   // AX <- LITERAL
#       b       apush           // TO TOP OF STACK
        str     x0, [x14, #-8]!
        ldr     x3, [x15], #8
        ldr     x0, [x3]
        br      x0

        .align 2
dpush:  str     x3, [x14, #-8]!
apush:  str     x0, [x14, #-8]!

        .align 2
        .global rf_next
rf_next:
next:   ldr     x3, [x15], #8   // (W) <- (IP)
next1:  ldr     x0, [x3]        // TO 'CFA'
        br      x0

        .align 2
        .global rf_code_exec
rf_code_exec:
        ldr     x3, [x14], #8   // GET CFA
#       b       next1           // EXECUTE NEXT
        ldr     x0, [x3]
        br      x0

        .align 2
        .global rf_code_bran
rf_code_bran:
bran1:  ldr     x0, [x15]
        add     x15, x15, x0    // (IP) <- (IP) + ((IP))
#       b       next            // JUMP TO OFFSET
        ldr     x3, [x15], #8
        ldr     x0, [x3]
        br      x0

        .align 2
        .global rf_code_zbran
rf_code_zbran:
        ldr     x0, [x14], #8   // GET STACK VALUE
        cbz     x0, bran1       // ZERO?
                                // YES, BRANCH
        add     x15, x15, #8    // NO, CONTINUE...
#       b       next
        ldr     x3, [x15], #8
        ldr     x0, [x3]
        br      x0

        .align 2
        .global rf_code_xloop
rf_code_xloop:
        mov     x1, #1          // INCREMENT
xloo1:  ldr     x0, [x13]       // INDEX=INDEX+INCR
        add     x0, x0, x1
        str     x0, [x13]       // GET NEW INDEX
        ldr     x2, [x13, #8]   // COMPARE WITH LIMIT
        sub     x0, x0, x2
        eor     x0, x0, x1      // TEST SIGN (BIT-16)
        tst     x0, x0
        bmi     bran1           // KEEP LOOPING...

# END OF 'DO' LOOP
        add     x13, x13, #16   // ADJ. RETURN STK
        add     x15, x15, #8    // BYPASS BRANCH OFFSET
#       b       next            // CONTINUE...
        ldr     x3, [x15], #8
        ldr     x0, [x3]
        br      x0

        .align 2
        .global rf_code_xploo
rf_code_xploo:
        ldr     x1, [x14], #8   // GET LOOP VALUE
        b       xloo1

        .align 2
        .global rf_code_xdo
rf_code_xdo:
        ldp     x3, x0, [x14], #16 // INITIAL INDEX VALUE
                                // LIMIT VALUE
        stp     x3, x0, [x13, #-16]!
#       b       next
        ldr     x3, [x15], #8
        ldr     x0, [x3]
        br      x0

        .align 2
        .global rf_code_rr
rf_code_rr:
        ldr     x0, [x13]       // GET INDEX VALUE
#       b       apush           // TO PARAMETER STACK
        str     x0, [x14, #-8]!
        ldr     x3, [x15], #8
        ldr     x0, [x3]
        br      x0

        .align 2
        .global rf_code_digit
rf_code_digit:
        ldrb    w3, [x14], #8   // NUMBER BASE
        ldrb    w0, [x14], #8   // ASCII DIGIT
        subs    x0, x0, #48
        blt     digi2           // NUMBER ERROR
        cmp     x0, #9
        ble     digi1           // NUMBER = 0 THRU 9
        sub     x0, x0, #7
        cmp     x0, #10         // NUMBER 'A' THRU 'Z' ?
        blt     digi2           // NO
#
digi1:  cmp     x0, x3          // COMPARE NUMBER TO BASE
        bge     digi2           // NUMBER ERROR
        mov     x3, x0          // NEW BINARY NUMBER
        mov     x0, #1          // TRUE FLAG
#       b       dpush           // ADD TO STACK
        stp     x0, x3, [x14, #-16]!
        ldr     x3, [x15], #8
        ldr     x0, [x3]
        br      x0

# NUMBER ERROR
#
digi2:  mov     x0, #0          // FALSE FLAG
#       b       apush           // BYE
        str     x0, [x14, #-8]!
        ldr     x3, [x15], #8
        ldr     x0, [x3]
        br      x0

        .align 2
        .global rf_code_pfind
rf_code_pfind:
        ldp     x1, x2, [x14], #16 // NFA
                                // STRING ADDR
#
# SEARCH LOOP
pfin1:  mov     x4, x2          // GET ADDR
        ldrb    w0, [x1]        // GET WORD LENGTH
        mov     x3, x0          // SAVE LENGTH
        ldrb    w5, [x4]
        eor     x0, x0, x5
        ands    x0, x0, #63     // CHECK LENGTHS
        bne     pfin5           // LENGTHS DIFFER
#
# LENGTH MATCH, CHECK EACH CHARACTER IN NAME
pfin2:  add     x1, x1, #1
        add     x4, x4, #1      // NEXT CHAR OF NAME
        ldrb    w0, [x1]
        ldrb    w5, [x4]        // COMPARE NAMES
        eor     x0, x0, x5
        tst     x0, #127
        bne     pfin5           // NO MATCH
        tst     x0, #128        // THIS WILL TEST BIT-8
        beq     pfin2           // MATCH SO FAR, LOOP

# FOUND END OF NAME (BIT-8 SET); A MATCH
        add     x1, x1, #17     // BX = PFA
        str     x1, [x14, #-8]! // (S3) <- PFA
        mov     x0, #1          // TRUE VALUE
        and     x3, x3, #255    // CLEAR HIGH LENGTH

#       b       dpush
        stp     x0, x3, [x14, #-16]!
        ldr     x3, [x15], #8
        ldr     x0, [x3]
        br      x0

# NO NAME FIELD MATCH, TRY ANOTHER
#
# GET NEXT LINK FIELD ADDR (LFA)
# (ZERO = FIRST WORD OF DICTIONARY)
#
pfin5:  add     x1, x1, #1      // NEXT ADDR
        tst     x0, #128        // END OF NAME
        bne     pfin6
        ldrb    w0, [x1]        // GET NEXT CHAR
        b       pfin5           // LOOP UNTIL FOUND
#
pfin6:  ldr     x1, [x1]        // GET LINK FIELD ADDR
        cbnz    x1, pfin1       // START OF DICT. (0)?
                                // NO, LOOK SOME MORE
        mov     x0, #0          // FALSE FLAG

#       b       apush           // DONE (NO MATCH FOUND)
        str     x0, [x14, #-8]!
        ldr     x3, [x15], #8
        ldr     x0, [x3]
        br      x0

        .align 2
        .global rf_code_encl
rf_code_encl:
        ldp     x0, x1, [x14], #8 // S1 - TERMINATOR CHAR.
                                // S2 - TEXT ADDR
        and     x0, x0, #255    // ZERO
        mov     x3, #-1         // CHAR OFFSET COUNTER
        sub     x1, x1, #1      // ADDR -1

# SCAN TO FIRST NON-TERMINATOR CHAR
#
encl1:  add     x1, x1, #1      // ADDR +1
        add     x3, x3, #1      // COUNT +1
        ldrb    w2, [x1]
        cmp     x0, x2
        beq     encl1           // WAIT FOR NON-TERMINATOR
        str     x3, [x14, #-8]! // OFFSET TO 1ST TEXT CHR
        cbnz    x2, encl2       // NULL CHAR?
                                // NO
#
# FOUND NULL BEFORE FIRST NON-TERMINATOR CHAR.
        mov     x0, x3          // COPY COUNTER
        add     x3, x3, #1      // +1
#       b       dpush
        stp     x0, x3, [x14, #-16]!
        ldr     x3, [x15], #8
        ldr     x0, [x3]
        br      x0
#
# FOUND FIRST TEXT CHAR, COUNT THE CHARACTERS
#
encl2:  add     x1, x1, #1      // ADDR+1
        add     x3, x3, #1      // COUNT +1
        ldrb    w2, [x1]        // TERMINATOR CHAR?
        cmp     x0, x2
        beq     encl4           // YES
        cbnz    x2, encl2       // NULL CHAR
                                // NO, LOOP AGAIN
#
# FOUND NULL AT END OF TEXT
#
encl3:  mov     x0, x3          // COUNTERS ARE EQUAL
#       b       dpush
        stp     x0, x3, [x14, #-16]!
        ldr     x3, [x15], #8
        ldr     x0, [x3]
        br      x0

# FOUND TERINATOR CHARACTER
encl4:  mov     x0, x3
        add     x0, x0, #1      // COUNT +1
#       b       dpush
        stp     x0, x3, [x14, #-16]!
        ldr     x3, [x15], #8
        ldr     x0, [x3]
        br      x0

        .align 2
        .global rf_code_cmove
rf_code_cmove:
        ldp     x2, x1, [x14], #16 // COUNT
                                // DEST.
        ldr     x3, [x14], #8   // SOURCE
        cbz     x2, cmov2
cmov1:  ldrb    w0, [x3], #1    // THATS THE MOVE
        strb    w0, [x1], #1
        subs    x2, x2, #1
        bne     cmov1
cmov2:  # b     next
        ldr     x3, [x15], #8
        ldr     x0, [x3]
        br      x0

        .align 2
        .global rf_code_ustar
rf_code_ustar:
        ldp     x2, x1, [x14], #16
        mul     x3, x1, x2
        umulh   x0, x1, x2
#       b       dpush
        stp     x0, x3, [x14, #-16]!
        ldr     x3, [x15], #8
        ldr     x0, [x3]
        br      x0

        .align 2
        .global rf_code_uslas
rf_code_uslas:
        ldp     x2, x1, [x14], #16 // DIVISOR
                                // MSW OF DIVIDEND
        ldr     x0, [x14], #8   // LSW OF DIVIDEND
#       bl      umdiv
#umdiv:
        mov     x3, #1
        lsl     x3, x3, #63     // init mask with highest bit set
        mov     x4, #0          // init quot
        cmp     x1, x2          // test modh - div
        blo     umdiv1          // modh < div
        # overflow condition ( divide by zero ) - show max numbers
        asr     x4, x3, #63
        mov     x1, x4

        b       umdiv3          // return

umdiv1: adds    x0, x0, x0      // double precision shift (modh, modl)
        adcs    x1, x1, x1      // ADD with carry and set flags again !
        bcs     umdiv4
        cmp     x2, x1          // test div - modh
        bhi     umdiv2          // div >  modh ?
umdiv4: add     x4, x4, x3      // add single pecision mask
        sub     x1, x1, x2      // subtract single precision div
umdiv2: lsr     x3, x3, #1      // shift mask one bit to the right
        cbnz    x3, umdiv1
umdiv3: stp     x4, x1, [x14, #-16]! // remainder
                                // quotient

#       b     next
        ldr   x3, [x15], #8
        ldr   x0, [x3]
        br    x0

        .align 2
        .global rf_code_andd
rf_code_andd:
        ldp     x0, x1, [x14], #8
        and     x0, x0, x1
        str     x0, [x14]
#       b       next
        ldr     x3, [x15], #8
        ldr     x0, [x3]
        br      x0

        .align 2
        .global rf_code_orr
rf_code_orr:
        ldp     x0, x1, [x14], #8
        orr     x0, x0, x1
        str     x0, [x14]
#       b       next
        ldr     x3, [x15], #8
        ldr     x0, [x3]
        br      x0

        .align 2
        .global rf_code_xorr
rf_code_xorr:
        ldp     x0, x1, [x14], #8
        eor     x0, x0, x1
        str     x0, [x14]
#       b       next
        ldr     x3, [x15], #8
        ldr     x0, [x3]
        br      x0

        .align 2
        .global rf_code_spat
rf_code_spat:
        mov     x0, x14
#       b       apush
        str     x0, [x14, #-8]!
        ldr     x3, [x15], #8
        ldr     x0, [x3]
        br      x0

        .align 2
        .global rf_code_spsto
rf_code_spsto:
        ldr     x1, =rf_up      // USER VAR BASE ADDR
        ldr     x1, [x1]
        ldr     x14, [x1, #24]  // RESET PARAM. STACK PT.
#       b       next
        ldr     x3, [x15], #8
        ldr     x0, [x3]
        br      x0

        .align 2
        .global rf_code_rpsto
rf_code_rpsto:
        ldr     x1, =rf_up      // (AX) <- USR VAR. BASE
        ldr     x1, [x1]
        ldr     x13, [x1, #32]  // RESET RETURN STACK PT.
#       b       next
        ldr     x3, [x15], #8
        ldr     x0, [x3]
        br      x0

        .align 2
        .global rf_code_semis
rf_code_semis:
        ldr     x15, [x13], #8  // (IP) <- (R1)
#       b       next            // ADJUST STACK
        ldr     x3, [x15], #8
        ldr     x0, [x3]
        br      x0

        .align 2
        .global rf_code_leave
rf_code_leave:
        ldr     x0, [x13]       // GET INDEX
        str     x0, [x13, #8]   // STORE IT AT LIMIT
#       b       next
        ldr     x3, [x15], #8
        ldr     x0, [x3]
        br      x0

        .align 2
        .global rf_code_tor
rf_code_tor:
        ldr     x1, [x14], #8   // GET STACK PARAMETER
        str     x1, [x13, #-8]! // ADD TO RETURN STACK
#       b       next
        ldr     x3, [x15], #8
        ldr     x0, [x3]
        br      x0

        .align 2
        .global rf_code_fromr
rf_code_fromr:
        ldr     x1, [x13], #8   // GET RETURN STACK VALUE
        str     x1, [x14, #-8]! // DELETE FROM STACK
#       b       next
        ldr     x3, [x15], #8
        ldr     x0, [x3]
        br      x0

        .align 2
        .global rf_code_zequ
rf_code_zequ:
        ldr     x1, [x14], #8
                                // DO TEST
        mov     x0, #1          // TRUE
        cbz     x1, zequ1       // ITS ZERO
        sub     x0, x0, #1      // FALSE
zequ1:  # b     apush
        str     x0, [x14, #-8]!
        ldr     x3, [x15], #8
        ldr     x0, [x3]
        br      x0

        .align 2
        .global rf_code_zless
rf_code_zless:
        ldr     x0, [x14], #8
        tst     x0, x0          // SET FLAGS
        mov     x0, #1          // TRUE
        bmi     zless1
        sub     x0, x0, #1      // FLASE
zless1: # b     apush
        str     x0, [x14, #-8]!
        ldr     x3, [x15], #8
        ldr     x0, [x3]
        br      x0

        .align 2
        .global rf_code_plus
rf_code_plus:
        ldp     x0, x1, [x14], #16
        add     x0, x0, x1
        b       apush
        str     x0, [x14, #-8]!
        ldr     x3, [x15], #8
        ldr     x0, [x3]
        br      x0

        .align 2
        .global rf_code_dplus
rf_code_dplus:
        ldp     x0, x3, [x14], #16 // YHW
                                // YLW
        ldp     x1, x2, [x14], #16 // XHW
                                // XLW
        adds    x3, x3, x2      // SLW
        adc     x0, x0, x1      // SHW
#       b       dpush
        stp     x0, x3, [x14, #-16]!
        ldr     x3, [x15], #8
        ldr     x0, [x3]
        br      x0

        .align 2
        .global rf_code_minus
rf_code_minus:
        ldr     x0, [x14], #8
        neg     x0, x0
#       b       apush
        str     x0, [x14, #-8]!
        ldr     x3, [x15], #8
        ldr     x0, [x3]
        br      x0

        .align 2
        .global rf_code_dminu
rf_code_dminu:
        ldp     x1, x2, [x14], #16
        sub     x0, x0, x0      // ZERO
        mov     x3, x0
        subs    x3, x3, x2      // MAKE 2'S COMPLEMENT
        sbc     x0, x0, x1      // HIGH WORD
#       b       dpush
        stp     x0, x3, [x14, #-16]!
        ldr     x3, [x15], #8
        ldr     x0, [x3]
        br      x0

        .align 2
        .global rf_code_over
rf_code_over:
        ldr     x0, [x14, #8]
#       b       apush
        str     x0, [x14, #-8]!
        ldr     x3, [x15], #8
        ldr     x0, [x3]
        br      x0

        .align 2
        .global rf_code_drop
rf_code_drop:
        add     x14, x14, #8
#       b       next
        ldr     x3, [x15], #8
        ldr     x0, [x3]
        br      x0

        .align 2
        .global rf_code_swap
rf_code_swap:
        ldp     x3, x0, [x14]
        stp     x0, x3, [x14]
#       b       next
        ldr     x3, [x15], #8
        ldr     x0, [x3]
        br      x0

        .align 2
        .global rf_code_dup
rf_code_dup:
        ldr     x0, [x14]
#       b       apush
        str     x0, [x14, #-8]!
        ldr     x3, [x15], #8
        ldr     x0, [x3]
        br      x0

        .align 2
        .global rf_code_pstor
rf_code_pstor:
        ldp     x1, x0, [x14], #16 // ADDRESS
                                // INCREMENT
        ldr     x2, [x1]
        add     x2, x2, x0
        str     x2, [x1]
#       b       next
        ldr     x3, [x15], #8
        ldr     x0, [x3]
        br      x0

        .align 2
        .global rf_code_toggl
rf_code_toggl:
        ldrb    w0, [x14], #8   // BIT PATTERN
        ldr     x1, [x14], #8   // ADDR
        ldrb    w2, [x1]
        eor     w2, w2, w0
        strb    w2, [x1]
#       b       next
        ldr     x3, [x15], #8
        ldr     x0, [x3]
        br      x0

        .align 2
        .global rf_code_at
rf_code_at:
        ldr     x1, [x14]
        ldr     x0, [x1]
        str     x0, [x14]
#       b       next
        ldr     x3, [x15], #8
        ldr     x0, [x3]
        br      x0

        .align 2
        .global rf_code_cat
rf_code_cat:
        ldr     x1, [x14]
        ldrb    w0, [x1]
        str     x0, [x14]
#       b       next
        ldr     x3, [x15], #8
        ldr     x0, [x3]
        br      x0

        .align 2
        .global rf_code_store
rf_code_store:
        ldp     x1, x0, [x14], #16 // ADDR
                                // DATA
        str     x0, [x1]
#       b       next
        ldr     x3, [x15], #8
        ldr     x0, [x3]
        br      x0

        .align 2
        .global rf_code_cstor
rf_code_cstor:
        ldr     x1, [x14], #8   // ADDR
        ldrb    w0, [x14], #8   // DATA
        strb    w0, [x1]
#       b       next
        ldr     x3, [x15], #8
        ldr     x0, [x3]
        br      x0

        .align 2
        .global rf_code_docol
rf_code_docol:
        add     x3, x3, #8      // W=W+1
        str     x15, [x13, #-8]! // R1 <- (RP)
        mov     x15, x3         // (IP) <- (W)
#       b       next
        ldr     x3, [x15], #8
        ldr     x0, [x3]
        br      x0

        .align 2
        .global rf_code_docon
rf_code_docon:
        ldr     x0, [x3, #8]!   // PFA @ GET DATA
#       b       apush
        str     x0, [x14, #-8]!
        ldr     x3, [x15], #8
        ldr     x0, [x3]
        br      x0

        .align 2
        .global rf_code_dovar
rf_code_dovar:
        add     x3, x3, #8      // (DE) <- PFA
        str     x3, [x14, #-8]! // (S1) <- PFA
#       b       next
        ldr     x3, [x15], #8
        ldr     x0, [x3]
        br      x0

        .align 2
        .global rf_code_douse
rf_code_douse:
        ldrb    w1, [x3, #8]!   // PFA
        ldr     x0, =rf_up      // USER VARIABLE ADDR
        ldr     x0, [x0]
        add     x0, x0, x1
#       b       apush
        str     x0, [x14, #-8]!
        ldr     x3, [x15], #8
        ldr     x0, [x3]
        br      x0

        .align 2
        .global rf_code_dodoe
rf_code_dodoe:
        str     x15, [x13, #-8]! // (RP) <- (IP)
        add     x3, x3, #8      // PFA
        ldr     x15, [x3], #8   // NEW CFA
        str     x3, [x14, #-8]! // PFA
#       b       next
        ldr     x3, [x15], #8
        ldr     x0, [x3]
        br      x0

        .align 2
        .global rf_code_stod
rf_code_stod:
        ldr     x3, [x14], #8   // S1
        sub     x0, x0, x0      // AX = 0
        tst     x3, x3          // SET FLAGS
        bpl     stod1           // POSITIVE NUMBER
        sub     x0, x0, #1      // NEGITIVE NUMBER
stod1:  # b     dpush
        stp     x0, x3, [x14, #-16]!
        ldr     x3, [x15], #8
        ldr     x0, [x3]
        br      x0

        .align 2
        .global rf_code_cold
rf_code_cold:
        ldr     x3, =rf_origin
        ldr     x3, [x3]
        ldr     x0, [x3, #48]   // FORTH vocabulary init
        ldr     x1, [x3, #168]
        str     x0, [x1]
        ldr     x1, [x3, #64]   // UP init
        ldr     x0, =rf_up
        str     x1, [x0]
        mov     x2, #11         // USER variables init
        add     x3, x3, #48
cold1:  ldr     x0, [x3], #8
        str     x0, [x1], #8
        subs    x2, x2, #1
        bne     cold1
        ldr     x15, [x3, #40]  // IP init to ABORT
        b       rf_code_rpsto   // jump to RP!

        .align 2
        .global rf_code_cl
rf_code_cl:
        mov     x0, #8
#       b       apush
        str     x0, [x14, #-8]!
        ldr     x3, [x15], #8
        ldr     x0, [x3]
        br      x0

        .align 2
        .global rf_code_cs
rf_code_cs:
        ldr     x0, [x14]
        lsl     x0, x0, #3
#       b       apush
        str     x0, [x14]
        ldr     x3, [x15], #8
        ldr     x0, [x3]
        br      x0

        .align 2
        .global rf_code_ln
rf_code_ln:
        ldr     x0, [x14]
        tst     x0, #7
        beq     ln1
        and     x0, x0, #-8
        add     x0, x0, #8
ln1:    # b     apush
        str     x0, [x14]
        ldr     x3, [x15], #8
        ldr     x0, [x3]
        br      x0

        .align 2
        .global rf_code_mon
rf_code_mon:
        stp     x29, x30, [sp, -16]!
        bl      rf_start
        ldr     x1, =rf_fp
        mov     x0, #0
        str     x0, [x1]
        ldp     x29, x30, [sp], 16
        ret
