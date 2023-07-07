.thumb_func

  .global rf_start
  .align 4
rf_start:
  ldr   r0, ipp                 @ r6 into IP
  str   r6, [r0]
  ldr   r0, spp                 @ r5 into SP
  str   r5, [r0]
  ldr   r0, rpp                 @ r4 into RP
  str   r4, [r0]
  ldr   r0, wp                  @ r3 into W
  str   r3, [r0]
  bx    lr

  .global rf_trampoline
  .align 4
rf_trampoline:
  push  {r3, r4, r6, r7, lr}
trampoline1:
  ldr   r4, fpp
  ldr   r0, [r4]
  cmp   r0, #0
  beq   trampoline2
  ldr   r6, ipp                 @ IP into r6
  ldr   r6, [r6]
  ldr   r5, spp                 @ SP into r5
  ldr   r5, [r5]
  ldr   r4, rpp                 @ RP into r4
  ldr   r4, [r4]
  ldr   r3, wp                  @ W into r3
  ldr   r3, [r3]
  blx   r0
  b     trampoline1
trampoline2:
  pop  {r3, r4, r6, r7, pc}

  .align 4
fpp:
  .word rf_fp
ipp:
  .word rf_ip
rpp:
  .word rf_rp
spp:
  .word rf_sp
wp:
  .word rf_w

  .align 1
  .syntax unified
  .thumb_func
  .code 16
dpush:
  subs  r5, r5, #4
  str   r3, [r5]

  .align 1
  .syntax unified
  .thumb_func
apush:
  subs  r5, r5, #4
  str   r0, [r5]

  .align 1
  .global rf_next
  .syntax unified
  .thumb_func
  .code 16
rf_next:
next:
  ldm   r6!, {r3}               @ (W) <- (IP)
next1:
  ldr   r0, [r3]                @ TO 'CFA'
  bx    r0

  .align 1
  .global rf_code_lit
  .syntax unified
  .thumb_func
  .code 16
rf_code_lit:
  ldm   r6!, {r0}               @ AX <- LITERAL
@ b     apush                   @ TO TOP OF STACK
  subs  r5, r5, #4
  str   r0, [r5]
  ldm   r6!, {r3}
  ldr   r0, [r3]
  bx    r0

  .align 1
  .global rf_code_exec
  .syntax unified
  .thumb_func
  .code 16
rf_code_exec:
  ldm   r5!, {r3}               @ GET CFA
@ b     next1                   @ EXECUTE NEXT
  ldr   r0, [r3]
  bx    r0

  .align 1
  .global rf_code_bran
  .syntax unified
  .thumb_func
  .code 16
rf_code_bran:
bran1:
  ldr   r0, [r6]
  add   r6, r6, r0              @ (IP) <- (IP) + ((IP))
@ b     next                    @ JUMP TO OFFSET
  ldm   r6!, {r3}
  ldr   r0, [r3]
  bx    r0

  .align 1
  .global rf_code_zbran
  .syntax unified
  .thumb_func
  .code 16
rf_code_zbran:
  ldm   r5!, {r0}               @ GET STACK VALUE
  orrs  r0, r0                  @ ZERO?
  beq   bran1                   @ YES, BRANCH
  adds  r6, r6, #4              @ NO, CONTINUE...
@ b     next
  ldm   r6!, {r3}
  ldr   r0, [r3]
  bx    r0

  .align 1
  .global rf_code_xloop
  .syntax unified
  .thumb_func
  .code 16
rf_code_xloop:
  movs  r1, #1                  @ INCREMENT
xloo1:
  ldr   r0, [r4]                @ INDEX=INDEX+INCR
  add   r0, r0, r1
  str   r0, [r4]                @ GET NEW INDEX
  ldr   r2, [r4, #4]            @ COMPARE WITH LIMIT
  subs  r0, r0, r2
  eors  r0, r1                  @ TEST SIGN (BIT-16)
  bmi   bran1                   @ KEEP LOOPING...

@ END OF 'DO' LOOP
  adds  r4, r4, #8              @ ADJ. RETURN STK
  adds  r6, r6, #4              @ BYPASS BRANCH OFFSET
@ b     next                    @ CONTINUE...
  ldm   r6!, {r3}
  ldr   r0, [r3]
  bx    r0

  .align 1
  .global rf_code_xploo
  .syntax unified
  .thumb_func
  .code 16
rf_code_xploo:
  ldm   r5!, {r1}               @ GET LOOP VALUE
  b     xloo1

  .align 1
  .global rf_code_xdo
  .syntax unified
  .thumb_func
  .code 16
rf_code_xdo:
  ldm   r5!, {r0, r3}           @ INITIAL INDEX VALUE
                                @ LIMIT VALUE
  subs  r4, r4, #4
  str   r3, [r4]
  subs  r4, r4, #4
  str   r0, [r4]
@ b     next
  ldm   r6!, {r3}
  ldr   r0, [r3]
  bx    r0

  .align 1
  .global rf_code_rr
  .syntax unified
  .thumb_func
  .code 16
rf_code_rr:
  ldr   r0, [r4]                @ GET INDEX VALUE
@ b     apush                   @ TO PARAMETER STACK
  subs  r5, r5, #4
  str   r0, [r5]
  ldm   r6!, {r3}
  ldr   r0, [r3]
  bx    r0

  .align 1
  .global rf_code_digit
  .syntax unified
  .thumb_func
  .code 16
rf_code_digit:
  ldrb  r3, [r5]                @ NUMBER BASE
  adds  r5, r5, #4
  ldrb  r0, [r5]                @ ASCII DIGIT
  adds  r5, r5, #4
  subs  r0, r0, #48
  blt   digi2                   @ NUMBER ERROR
  cmp   r0, #9
  ble   digi1                   @ NUMBER = 0 THRU 9
  subs  r0, r0, #7
  cmp   r0, #10                 @ NUMBER 'A' THRU 'Z' ?
  blt   digi2                   @ NO
@
digi1:
  cmp   r0, r3                  @ COMPARE NUMBER TO BASE
  bge   digi2                   @ NUMBER ERROR
  movs  r3, r0                  @ NEW BINARY NUMBER
  movs  r0, #1                  @ TRUE FLAG
@ b     dpush                   @ ADD TO STACK
  subs  r5, r5, #4
  str   r3, [r5]
  subs  r5, r5, #4
  str   r0, [r5]
  ldm   r6!, {r3}
  ldr   r0, [r3]
  bx    r0

@ NUMBER ERROR
@
digi2:
  movs  r0, #0                  @ FALSE FLAG
@ b     apush                   @ BYE
  subs  r5, r5, #4
  str   r0, [r5]
  ldm   r6!, {r3}
  ldr   r0, [r3]
  bx    r0

  .align 1
  .global rf_code_pfind
  .syntax unified
  .thumb_func
  .code 16
rf_code_pfind:
  ldm   r5!, {r1, r2}           @ NFA
                                @ STRING ADDR
  push  {r4, r5, r6}
@
@ SEARCH LOOP
pfin1:
  mov   r4, r2                  @ GET ADDR
  ldrb  r0, [r1]                @ GET WORD LENGTH
  mov   r3, r0                  @ SAVE LENGTH
  ldrb  r5, [r4]
  eors  r0, r5
  movs  r6, #63
  ands  r0, r6                  @ CHECK LENGTHS
  bne   pfin5                   @ LENGTHS DIFFER
@
@ LENGTH MATCH, CHECK EACH CHARACTER IN NAME
pfin2:
  adds  r1, r1, #1
  adds  r4, r4, #1              @ NEXT CHAR OF NAME
  ldrb  r0, [r1]
  ldrb  r5, [r4]                @ COMPARE NAMES
  eors  r0, r5
  movs  r6, #127
  tst   r0, r6
  bne   pfin5                   @ NO MATCH
  movs  r6, #128
  tst   r0, r6                  @ THIS WILL TEST BIT-8
  beq   pfin2                   @ MATCH SO FAR, LOOP

@ FOUND END OF NAME (BIT-8 SET); A MATCH
  pop   {r4, r5, r6}
  adds  r1, r1, #9              @ BX = PFA
  subs  r5, r5, #4
  str   r1, [r5]                @ (S3) <- PFA
  movs  r0, #1                  @ TRUE VALUE
  movs  r1, #255
  ands  r3, r1                  @ CLEAR HIGH LENGTH

@ b     dpush
  subs  r5, r5, #4
  str   r3, [r5]
  subs  r5, r5, #4
  str   r0, [r5]
  ldm   r6!, {r3}
  ldr   r0, [r3]
  bx    r0

@ NO NAME FIELD MATCH, TRY ANOTHER
@
@ GET NEXT LINK FIELD ADDR (LFA)
@ (ZERO = FIRST WORD OF DICTIONARY)
@
pfin5:
  adds  r1, r1, #1              @ NEXT ADDR
  movs  r6, #128
  tst   r0, r6                  @ END OF NAME
  bne   pfin6
  ldrb  r0, [r1]                @ GET NEXT CHAR
  b     pfin5                   @ LOOP UNTIL FOUND
@
pfin6:
  ldr   r1, [r1]                @ GET LINK FIELD ADDR
  orrs  r1, r1                  @ START OF DICT. (0)?
  bne   pfin1                   @ NO, LOOK SOME MORE
  movs  r0, #0                  @ FALSE FLAG

  pop   {r4, r5, r6}
@ b     apush                   @ DONE (NO MATCH FOUND)
  subs  r5, r5, #4
  str   r0, [r5]
  ldm   r6!, {r3}
  ldr   r0, [r3]
  bx    r0

  .align 1
  .global rf_code_encl
  .syntax unified
  .thumb_func
  .code 16
rf_code_encl:
  ldm   r5!, {r0}               @ S1 - TERMINATOR CHAR.
  ldr   r1, [r5]                @ S2 - TEXT ADDR
  movs  r2, #255
  ands  r0, r2                  @ ZERO
  movs  r3, #0                  @ CHAR OFFSET COUNTER
  subs  r3, r3, #1              @ ADDR -1
  subs  r1, r1, #1              @ ADDR -1

@ SCAN TO FIRST NON-TERMINATOR CHAR
@
encl1:
  adds  r1, r1, #1              @ ADDR +1
  adds  r3, r3, #1              @ COUNT +1
  ldrb  r2, [r1]
  cmp   r0, r2
  beq   encl1                   @ WAIT FOR NON-TERMINATOR
  subs  r5, r5, #4
  str   r3, [r5]                @ OFFSET TO 1ST TEXT CHR
  cmp   r2, #0                  @ NULL CHAR?
  bne   encl2                   @ NO
@
@ FOUND NULL BEFORE FIRST NON-TERMINATOR CHAR.
  mov   r0, r3                  @ COPY COUNTER
  adds  r3, r3, #1              @ +1
@ b     dpush
  subs  r5, r5, #4
  str   r3, [r5]
  subs  r5, r5, #4
  str   r0, [r5]
  ldm   r6!, {r3}
  ldr   r0, [r3]
  bx    r0
@
@ FOUND FIRST TEXT CHAR, COUNT THE CHARACTERS
@
encl2:
  adds  r1, r1, #1              @ ADDR+1
  adds  r3, r3, #1              @ COUNT +1
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
  subs  r5, r5, #4
  str   r3, [r5]
  subs  r5, r5, #4
  str   r0, [r5]
  ldm   r6!, {r3}
  ldr   r0, [r3]
  bx    r0

@ FOUND TERINATOR CHARACTER
encl4:
  mov   r0, r3
  adds  r0, r0, #1              @ COUNT +1
@ b     dpush
  subs  r5, r5, #4
  str   r3, [r5]
  subs  r5, r5, #4
  str   r0, [r5]
  ldm   r6!, {r3}
  ldr   r0, [r3]
  bx    r0

  .align 1
  .global rf_code_cmove
  .syntax unified
  .thumb_func
  .code 16
rf_code_cmove:
  ldm   r5!, {r1, r2, r3}       @ COUNT
                                @ DEST.
                                @ SOURCE
  cmp   r1, #0
  beq   cmov2
cmov1:
  ldrb  r0, [r3]                @ THATS THE MOVE
  adds  r3, r3, #1
  strb  r0, [r2]
  adds  r2, r2, #1
  subs  r1, r1, #1
  bne   cmov1
cmov2:
@ b     next
  ldm   r6!, {r3}
  ldr   r0, [r3]
  bx    r0

  .align 1
  .global rf_code_ustar
  .syntax unified
  .thumb_func
  .code 16
rf_code_ustar:
  ldm   r5!, {r0, r3}
  mov   r8, r4
  uxth  r2, r0
  lsrs  r1, r3, #16
  lsrs  r0, r0, #16
  mov   r4, r0
  muls  r0, r1
  uxth  r3, r3
  muls  r1, r2
  muls  r4, r3
  muls  r3, r2
  movs  r2, #0
  adds  r1, r4
  adcs  r2, r2
  lsls  r2, #16
  adds  r0, r2
  lsls  r2, r1, #16
  lsrs  r1, #16
  adds  r3, r2
  adcs  r0, r1
  mov   r4, r8
@ b     dpush
  subs  r5, r5, #4
  str   r3, [r5]
  subs  r5, r5, #4
  str   r0, [r5]
  ldm   r6!, {r3}
  ldr   r0, [r3]
  bx    r0

  .align 1
  .global rf_code_uslas
  .syntax unified
  .thumb_func
  .code 16
rf_code_uslas:
  ldm   r5!, {r0, r1, r2}       @ DIVISOR
                                @ MSW OF DIVIDEND
                                @ LSW OF DIVIDEND
  mov   r8, r4
@  bl   umdiv
@umdiv:
  movs  r3, #1
  lsls  r3, r3, #31             @ init mask with highest bit set
  movs  r4, #0                  @ init quot
  cmp   r1, r0                  @ test modh - div
  blo   umdiv1                  @ modh < div
  @ overflow condition ( divide by zero ) - show max numbers
  asrs  r4, r3, #31
  mov   r1, r4

@   bal   umdiv3                  @ return
  bal   umdiv3                  @ return

umdiv1:
  adds  r2, r2, r2              @ double precision shift (modh, modl)
  adcs  r1, r1, r1              @ ADD with carry and set flags again !
  bcs   umdiv4
  cmp   r0, r1                  @ test div - modh
  bhi   umdiv2                  @ div >  modh ?
umdiv4:
  adds  r4, r4, r3              @ add single pecision mask
  subs  r1, r1, r0              @ subtract single precision div
umdiv2:
  lsrs  r3, r3, #1              @ shift mask one bit to the right
  ands  r3, r3, r3
  bne   umdiv1
umdiv3:
  subs  r5, r5, #4
  str   r1, [r5]                @ remainder
  subs  r5, r5, #4
  str   r4, [r5]                @ quotient
  mov   r4, r8
@ b     next
  ldm   r6!, {r3}
  ldr   r0, [r3]
  bx    r0

  .align 1
  .global rf_code_andd
  .syntax unified
  .thumb_func
  .code 16
rf_code_andd:
  ldm   r5!, {r0}
  ldr   r1, [r5]
  ands  r0, r0, r1
  str   r0, [r5]
@ b     next
  ldm   r6!, {r3}
  ldr   r0, [r3]
  bx    r0

  .align 1
  .global rf_code_orr
  .syntax unified
  .thumb_func
  .code 16
rf_code_orr:
  ldm   r5!, {r0}
  ldr   r1, [r5]
  orrs  r0, r0, r1
  str   r0, [r5]
@ b     next
  ldm   r6!, {r3}
  ldr   r0, [r3]
  bx    r0

  .align 1
  .global rf_code_xorr
  .syntax unified
  .thumb_func
  .code 16
rf_code_xorr:
  ldm   r5!, {r0}
  ldr   r1, [r5]
  eors  r0, r0, r1
  str   r0, [r5]
@ b     next
  ldm   r6!, {r3}
  ldr   r0, [r3]
  bx    r0

  .align 1
  .global rf_code_spat
  .syntax unified
  .thumb_func
  .code 16
rf_code_spat:
  mov   r0, r5
@ b     apush
  subs  r5, r5, #4
  str   r0, [r5]
  ldm   r6!, {r3}
  ldr   r0, [r3]
  bx    r0

  .align 1
  .global rf_code_spsto
  .syntax unified
  .thumb_func
  .code 16
rf_code_spsto:
  ldr   r1, =rf_up              @ USER VAR BASE ADDR
  ldr   r1, [r1]
  ldr   r5, [r1, #12]           @ RESET PARAM. STACK PT.
@ b     next
  ldm   r6!, {r3}
  ldr   r0, [r3]
  bx    r0

  .align 1
  .global rf_code_rpsto
  .syntax unified
  .thumb_func
  .code 16
rf_code_rpsto:
  ldr   r1, =rf_up              @ (AX) <- USR VAR. BASE
  ldr   r1, [r1]
  ldr   r4, [r1, #16]           @ RESET RETURN STACK PT.
@ b     next
  ldm   r6!, {r3}
  ldr   r0, [r3]
  bx    r0

  .align 1
  .global rf_code_semis
  .syntax unified
  .thumb_func
  .code 16
rf_code_semis:
  ldm   r4!, {r6}               @ (IP) <- (R1)
@ b     next                    @ ADJUST STACK
  ldm   r6!, {r3}
  ldr   r0, [r3]
  bx    r0

  .align 1
  .global rf_code_leave
  .syntax unified
  .thumb_func
  .code 16
rf_code_leave:
  ldr   r0, [r4]                @ GET INDEX
  str   r0, [r4, #4]            @ STORE IT AT LIMIT
@ b     next
  ldm   r6!, {r3}
  ldr   r0, [r3]
  bx    r0

  .align 1
  .global rf_code_tor
  .syntax unified
  .thumb_func
  .code 16
rf_code_tor:
  ldm   r5!, {r1}               @ GET STACK PARAMETER
  subs  r4, r4, #4
  str   r1, [r4]                @ ADD TO RETURN STACK
@ b     next
  ldm   r6!, {r3}
  ldr   r0, [r3]
  bx    r0

  .align 1
  .global rf_code_fromr
  .syntax unified
  .thumb_func
  .code 16
rf_code_fromr:
  ldm   r4!, {r1}               @ GET RETURN STACK VALUE
  subs  r5, r5, #4
  str   r1, [r5]                @ DELETE FROM STACK
@ b     next
  ldm   r6!, {r3}
  ldr   r0, [r3]
  bx    r0

  .align 1
  .global rf_code_zequ
  .syntax unified
  .thumb_func
  .code 16
rf_code_zequ:
  ldm   r5!, {r1}
  movs  r0, #1                  @ TRUE
  orrs  r1, r1                  @ DO TEST
  beq   zequ1                   @ ITS ZERO
  subs  r0, r0, #1              @ FALSE
zequ1:
@ b     apush
  subs  r5, r5, #4
  str   r0, [r5]
  ldm   r6!, {r3}
  ldr   r0, [r3]
  bx    r0

  .align 1
  .global rf_code_zless
  .syntax unified
  .thumb_func
  .code 16
rf_code_zless:
  ldm   r5!, {r1}
  movs  r0, #1                  @ TRUE
  orrs  r1, r1                  @ SET FLAGS
  bmi   zless1
  subs  r0, r0, #1              @ FLASE
zless1:
@ b     apush
  subs  r5, r5, #4
  str   r0, [r5]
  ldm   r6!, {r3}
  ldr   r0, [r3]
  bx    r0

  .align 1
  .global rf_code_plus
  .syntax unified
  .thumb_func
  .code 16
rf_code_plus:
  ldm   r5!, {r0, r1}
  adds  r0, r0, r1
@ b     apush
  subs  r5, r5, #4
  str   r0, [r5]
  ldm   r6!, {r3}
  ldr   r0, [r3]
  bx    r0

  .align 1
  .global rf_code_dplus
  .syntax unified
  .thumb_func
  .code 16
rf_code_dplus:
  ldm   r5!, {r0, r1, r2, r3}   @ YHW
                                @ YLW
                                @ XHW
                                @ XLW
  adds  r3, r3, r1              @ SLW
  adcs  r0, r0, r2              @ SHW
@ b     dpush
  subs  r5, r5, #4
  str   r3, [r5]
  subs  r5, r5, #4
  str   r0, [r5]
  ldm   r6!, {r3}
  ldr   r0, [r3]
  bx    r0

  .align 1
  .global rf_code_minus
  .syntax unified
  .thumb_func
  .code 16
rf_code_minus:
  ldm   r5!, {r0}
  negs  r0, r0
@ b     apush
  subs  r5, r5, #4
  str   r0, [r5]
  ldm   r6!, {r3}
  ldr   r0, [r3]
  bx    r0

  .align 1
  .global rf_code_dminu
  .syntax unified
  .thumb_func
  .code 16
rf_code_dminu:
  ldm   r5!, {r1, r2}
  subs  r0, r0, r0              @ ZERO
  mov   r3, r0
  subs  r3, r3, r2              @ MAKE 2'S COMPLEMENT
  sbcs  r0, r0, r1              @ HIGH WORD
@ b     dpush
  subs  r5, r5, #4
  str   r3, [r5]
  subs  r5, r5, #4
  str   r0, [r5]
  ldm   r6!, {r3}
  ldr   r0, [r3]
  bx    r0

  .align 1
  .global rf_code_over
  .syntax unified
  .thumb_func
  .code 16
rf_code_over:
  ldr   r0, [r5, #4]
@ b     apush
  subs  r5, r5, #4
  str   r0, [r5]
  ldm   r6!, {r3}
  ldr   r0, [r3]
  bx    r0

  .align 1
  .global rf_code_drop
  .syntax unified
  .thumb_func
  .code 16
rf_code_drop:
  adds  r5, r5, #4
@ b     next
  ldm   r6!, {r3}
  ldr   r0, [r3]
  bx    r0

  .align 1
  .global rf_code_swap
  .syntax unified
  .thumb_func
  .code 16
rf_code_swap:
  ldr   r3, [r5]
  ldr   r0, [r5, #4]
  str   r3, [r5, #4]
  str   r0, [r5]
@ b     next
  ldm   r6!, {r3}
  ldr   r0, [r3]
  bx    r0

  .align 1
  .global rf_code_dup
  .syntax unified
  .thumb_func
  .code 16
rf_code_dup:
  ldr   r0, [r5]
@ b     apush
  subs  r5, r5, #4
  str   r0, [r5]
  ldm   r6!, {r3}
  ldr   r0, [r3]
  bx    r0

  .align 1
  .global rf_code_pstor
  .syntax unified
  .thumb_func
  .code 16
rf_code_pstor:
  ldm   r5!, {r0, r1}           @ ADDRESS
                                @ INCREMENT
  ldr   r2, [r0]
  add   r2, r2, r1
  str   r2, [r0]
@ b     next
  ldm   r6!, {r3}
  ldr   r0, [r3]
  bx    r0

  .align 1
  .global rf_code_toggl
  .syntax unified
  .thumb_func
  .code 16
rf_code_toggl:
  ldm   r5!, {r0, r1}           @ BIT PATTERN
                                @ ADDR
  ldrb  r2, [r1]
  eors  r2, r2, r0
  strb  r2, [r1]
@ b     next
  ldm   r6!, {r3}
  ldr   r0, [r3]
  bx    r0

  .align 1
  .global rf_code_at
  .syntax unified
  .thumb_func
  .code 16
rf_code_at:
  ldr   r1, [r5]
  ldr   r0, [r1]
  str   r0, [r5]
@ b     next
  ldm   r6!, {r3}
  ldr   r0, [r3]
  bx    r0

  .align 1
  .global rf_code_cat
  .syntax unified
  .thumb_func
  .code 16
rf_code_cat:
  ldr   r1, [r5]
  ldrb  r0, [r1]
  str   r0, [r5]
@ b     next
  ldm   r6!, {r3}
  ldr   r0, [r3]
  bx    r0

  .align 1
  .global rf_code_store
  .syntax unified
  .thumb_func
  .code 16
rf_code_store:
  ldm   r5!, {r0, r1}           @ ADDR
                                @ DATA
  str   r1, [r0]
@ b     next
  ldm   r6!, {r3}
  ldr   r0, [r3]
  bx    r0

  .align 1
  .global rf_code_cstor
  .syntax unified
  .thumb_func
  .code 16
rf_code_cstor:
  ldm   r5!, {r0, r1}           @ ADDR
                                @ DATA
  strb  r1, [r0]
@ b     next
  ldm   r6!, {r3}
  ldr   r0, [r3]
  bx    r0

  .align 1
  .global rf_code_docol
  .syntax unified
  .thumb_func
  .code 16
rf_code_docol:
  adds  r3, r3, #4              @ W=W+1
  subs  r4, r4, #4
  str   r6, [r4]                @ R1 <- (RP)
  mov   r6, r3                  @ (IP) <- (W)
@ b     next
  ldm   r6!, {r3}
  ldr   r0, [r3]
  bx    r0

  .align 1
  .global rf_code_docon
  .syntax unified
  .thumb_func
  .code 16
rf_code_docon:
  ldr   r0, [r3, #4]            @ PFA @ GET DATA
@ b     apush
  subs  r5, r5, #4
  str   r0, [r5]
  ldm   r6!, {r3}
  ldr   r0, [r3]
  bx    r0

  .align 1
  .global rf_code_dovar
  .syntax unified
  .thumb_func
  .code 16
rf_code_dovar:
  adds  r3, r3, #4              @ (DE) <- PFA
  subs  r5, r5, #4
  str   r3, [r5]                @ (S1) <- PFA
@ b    next
  ldm   r6!, {r3}
  ldr   r0, [r3]
  bx    r0

  .align 1
  .global rf_code_douse
  .syntax unified
  .thumb_func
  .code 16
rf_code_douse:
  ldrb  r1, [r3, #4]            @ PFA
  ldr   r0, =rf_up              @ USER VARIABLE ADDR
  ldr   r0, [r0]
  add   r0, r0, r1
@ b     apush
  subs  r5, r5, #4
  str   r0, [r5]
  ldm   r6!, {r3}
  ldr   r0, [r3]
  bx    r0

  .align 1
  .global rf_code_dodoe
  .syntax unified
  .thumb_func
  .code 16
rf_code_dodoe:
  subs  r4, r4, #4
  str   r6, [r4]                @ (RP) <- (IP)
  ldr   r6, [r3, #4]            @ NEW CFA
  adds  r3, r3, #8              @ PFA
  subs  r5, r5, #4
  str   r3, [r5]                @ PFA
@ b     next
  ldm   r6!, {r3}
  ldr   r0, [r3]
  bx    r0

  .align 1
  .global rf_code_stod
  .syntax unified
  .thumb_func
  .code 16
rf_code_stod:
  ldm   r5!, {r3}               @ S1
  subs  r0, r0, r0              @ AX = 0
  orrs  r3, r3                  @ SET FLAGS
  bpl   stod1                   @ POSITIVE NUMBER
  subs  r0, r0, #1              @ NEGITIVE NUMBER
stod1:
@ b     dpush
  subs  r5, r5, #4
  str   r3, [r5]
  subs  r5, r5, #4
  str   r0, [r5]
  ldm   r6!, {r3}
  ldr   r0, [r3]
  bx    r0

  .align 1
  .global rf_code_cold
  .syntax unified
  .thumb_func
  .code 16
rf_code_cold:
  ldr   r3, =rf_origin
  ldr   r3, [r3]
  ldr   r0, =rf_code_cold       @ COLD vector init
  str   r0, [r3, #4]
  ldr   r0, [r3, #24]           @ FORTH vocabulary init
  ldr   r1, [r3, #68]
  str   r0, [r1]
  ldr   r1, [r3, #32]           @ UP init
  ldr   r0, =rf_up
  str   r1, [r0]
  movs  r2, #11                 @ USER variables init
  adds  r3, r3, #24
cold1:
  ldm   r3!, {r0}
  stm   r1!, {r0}
  subs  r2, r2, #1
  bne   cold1
  ldr   r6, [r3, #4]            @ IP init to ABORT
  b     rf_code_rpsto           @ jump to RP!

  .align 1
  .global rf_code_cl
  .syntax unified
  .thumb_func
  .code 16
rf_code_cl:
  movs  r0, #4
@ b     apush
  subs  r5, r5, #4
  str   r0, [r5]
  ldm   r6!, {r3}
  ldr   r0, [r3]
  bx    r0

  .align 1
  .global rf_code_cs
  .syntax unified
  .thumb_func
  .code 16
rf_code_cs:
  ldr   r0, [r5]
  lsls  r0, #2
  str   r0, [r5]
@ b     next
  ldm   r6!, {r3}
  ldr   r0, [r3]
  bx    r0

  .align 1
  .global rf_code_ln
  .syntax unified
  .thumb_func
  .code 16
rf_code_ln:
  ldr   r0, [r5]
  cmp   r0, #3
  beq   ln1
  movs  r1, #4
  negs  r1, r1
  ands  r0, r0, r1
  adds  r0, r0, #4
ln1:
  str   r0, [r5]
@ b     next
  ldm   r6!, {r3}
  ldr   r0, [r3]
  bx    r0

  .align 1
  .global rf_code_xt
  .syntax unified
  .thumb_func
  .code 16
rf_code_xt:
  push  {lr}
  bl    rf_start
  ldr   r1, =rf_fp
  movs  r0, #0
  str   r0, [r1]
  pop   {pc}
