* Modified for orterforth integration and 68000 in 2022. Cell
* width is now 32 bits. Some info in the comments no longer
* applies (e.g. RP is A1 not A7)

        .sect .text
        .align 2
        .extern _rf_trampoline
_rf_trampoline:
        move.l  a6, -(sp)
trampoline1:
        move.l  _rf_fp, a0
        cmp.l   #0, a0
        beq     trampoline2
        move.l  _rf_rp, a1
        move.l  _rf_sp, a3
        move.l  _rf_ip, a4
        move.l  _rf_up, a6
        move.l  _rf_w, a5
        addq.l  #4, a5
        jsr     (a0)
        bra     trampoline1
trampoline2:
        move.l  (sp)+, a6
        rts

        .align 2
        .extern _rf_start
_rf_start:
        move.l  a1, _rf_rp
        move.l  a3, _rf_sp
        move.l  a4, _rf_ip
        subq.l  #4, a5
        move.l  a5, _rf_w
        rts

        .align 2
        .extern _rf_code_cl
_rf_code_cl:
        move.l  #4, -(a3)
;       bra     _rf_next
        move.l  (a4)+, a5
        move.l  (a5)+, a0
        jmp     (a0)

        .align 2
        .extern _rf_code_cs
_rf_code_cs:
        move.l  (a3), d0
        lsl.l   #2, d0
        move.l  d0, (a3)
;       bra     _rf_next
        move.l  (a4)+, a5
        move.l  (a5)+, a0
        jmp     (a0)

        .align 2
        .extern _rf_code_ln
_rf_code_ln:
        btst    #0, (a3)
        beq     ln1
        add.l   #1, (a3)
ln1: ;  bra     _rf_next
        move.l  (a4)+, a5
        move.l  (a5)+, a0
        jmp     (a0)

*  OPT <OPTIONS> 
* NAM  "68000 FIG-FORTH 1.0 DECEMBER 1982"
*
* FIG-FORTH  RELEASE 1.0  FOR THE 68000 PROCESSOR
*
* ALL PUBLICATIONS OF THE FORTH INTEREST GROUP
* ARE PUBLIC DOMAIN. THEY MAY BE FURTHER
* DISTRIBUTED BY THE INCLUSION OF THIS CREDIT
* NOTICE:
*
* THIS PUBLICATION HAS BEEN MADE AVAILABLE BY THE
*  FORTH INTEREST GROUP
*  P.O. BOX 1105
*  SAN CARLOS, CA 94070
*
* IMPLEMENTATION BY:
*  KENNETH MANTEI
*  DEPARTMENT OF CHEMISTRY
*  CALIFORNIA STATE COLLEGE
*  SAN BERNARDINO, CALIFORNIA 92407
*
***********************************************
*
* ADAPTED FOR THE MOTOROLA ASSEMBLER BY:
*  ALBERT VAN DER HORST
*  ARIE KATTENBERG
*  FIG CHAPTER HOLLAND, WHICH IS
*  A USER GROUP OF
*  HCCH ( HOBBY COMPUTER CLUB HOLLAND)
*  PETER NOY
*  68000 USER GROUP OF HCCH
*
* >> WARNING :
* THIS IS INTENDED TO BE A BYTE FOR BYTE RENDITION
*  OF THE FORTH AS IMPLEMENTED BY KENNETH MANTEI
*  THAT CONTAINS A FEW SUBSTANTIAL DEVIATIONS FROM THE
*  FIG MODEL AS MENTIONED IN THE ACCOMPANYING NOTE
*
* SOME LINES ARE PRECEEDED WITH *F
* THIS IS FOR THOSE WHO WANT TO FOLLOW THE
*       FIG MODEL MORE CLOSELY THAN IN THE ORIGINAL
*       68000 FIG FORTH 1.0
*
******************************************************

*--------------------------------------------------------
*
* FORTH REGISTERS
*
* FORTH 68000 FORTH PRESERVATION RULES
* ----- ---- ------------------------
*  SP    A3   SHOULD BE USED ONLY AS DATA STACK
*              ACROSS FORTH WORDS
*              GROWS TOWARDS LOW MEMORY
*  IP    A4   SHOULD BE PRESERVED ACROSS
*              FORTH WORDS
*  W     A5   WORD POINTER, LOADED VIA IP
*  UP    A6   POINTS TO THE USER BLOCK
*  RP    A7   RETURN STACK POINTER
*              GROWS TOWARDS LOW MEMORY
*
* ALL FORTH REGISTERS SHOULD BE PRESERVED
*       ACROSS CODE WORDS.
*
*--------------------------------------------------------
*
*	COMMENT CONVENTIONS:
*
*       =       MEANS   "IS EQUAL TO"
*       <-      MEANS ASSIGNMENT
*
*       NAME    =       ADDRESS OF NAME
*       (NAME)	=       CONTENTS AT NAME
*       ((NAME))=       INDIRECT CONTENTS
*
*       CFA     =       ADDRESS OF CODE FIELD
*       LFA     =       ADDRESS         OF LINK FIELD
*       NFA     =       ADDRESS OF START OF NAME FIELD
*       PFA     =       ADDRESS OF START OF PARAMETER FIELD
*
*       S1      =       ADDR OF 1ST WORD OF PARAMETER STACK
*       S2      =       ADDR OF 2VD WORD OF PARAMETER STACK
*       R1      =       ADDR OF 1ST WORD OF RETURN STACK
*       R2      =       ADDR OF 2ND WORD OF RETURN STACK
*       ( ABOVE STACK POSITIONS VALID BEFORE & AFTER EXECUTION
*       OF ANY WORD, NOT DURING.)
*
*       LSB     =       LEAST SIGNIFICANT BIT
*       MSB     =       MOST SIGNIFICANT BIT
*       LB      =       LOW BYTE
*       HB      =       HIGH BYTE
*       LW      =       LOW WORD
*       HW      =       HIGH WORD
*       (MAY BE USED AS SUFFIX TO ABOVE NAMES)
* PAGE
*
*--------------------------------------------------------
*
* NEXT, THE FORTH ADDRESS INTERPRETER
* IS APPENDED TO EACH LOW LEVEL WORD
*
* PAGE
*
*  FORTH DICTIONARY
*
*
* DICTIONARY FORMAT:
*
*	                              BYTE
*       ADDRESS	NAME            CONTENTS
*       ------- ----            --------
*                               OPTIONAL 0 BYTE
*                               WHEN LENGTH OF NAME FIELD WOULD
*                               BE ODD
*                                       ( MSB=1
*                                       ( P=PRECEDENCE BIT
*                                       ( S=SMUDGE BIT
*       NFA     NAME FIELD      1PS<LEN> < NAME LENGTH
*                               0<1CHAR> MSB=0, NAME'S 1ST CHAR
*                               0<2CHAR>
*                               ...
*                               1<LCHAR> MSB=1, NAME'S LAST CHR
*       LFA     LINK FIELD      <LINKHB> = PREVIOUS WORD'S NFA
*                               <LINKLB>
*LABEL: CFA     CODE FIELD      <CODEHB> = ADDR CPU CODE
*                               <CODELB>
*       PFA     PARAMETER       <1PARAM> 1ST PARAMETER BYTE
*               FIELD           <2PARAM>
*                                 ...
*
*
*-------------------------------------------------------------

        .align 2
        .extern _rf_code_lit
_rf_code_lit:
        move.l  (a4)+, -(a3)

        .align 2
        .extern _rf_next
_rf_next:
        move.l  (a4)+, a5
        move.l  (a5)+, a0
        jmp     (a0)

        .align 2
        .extern _rf_code_exec
_rf_code_exec:
        move.l  (a3)+, a5
        move.l  (a5)+, a0
        jmp     (a0)

        .align 2
        .extern _rf_code_bran
_rf_code_bran:
        move.l  (a4), d0
        add.l   d0, a4
;       bra     _rf_next
        move.l  (a4)+, a5
        move.l  (a5)+, a0
        jmp     (a0)

        .align 2
        .extern _rf_code_zbran
_rf_code_zbran:
        tst.l   (a3)+
        beq     _rf_code_bran
        addq.l  #4, a4
;       bra     _rf_next
        move.l  (a4)+, a5
        move.l  (a5)+, a0
        jmp     (a0)

        .align 2
        .extern _rf_code_xloop
_rf_code_xloop:
        addq.l  #1, (a1)
xloo2:  move.l  4(a1), d0
        cmp.l   (a1), d0
        bhi     xloo3
        add.l   #4, a4
        add.l   #8, a1
        bra     xloo4
xloo3:  move.l  (a4), d0
        add.l   d0, a4
xloo4: ;bra     _rf_next
        move.l  (a4)+, a5
        move.l  (a5)+, a0
        jmp     (a0)

        .align 2
        .extern _rf_code_xploo
_rf_code_xploo:
        move.l  (a3)+, d0
        add.l   d0, (a1)
        bra     xloo2

        .align 2
        .extern _rf_code_xdo
_rf_code_xdo:
        move.l  (a3)+, d0
        move.l  (a3)+, -(a1)
        move.l  d0, -(a1)
;       bra     _rf_next
        move.l  (a4)+, a5
        move.l  (a5)+, a0
        jmp     (a0)

        .align 2
        .extern _rf_code_andd
_rf_code_andd:
        move.l  (a3)+, d0
        and.l   d0, (a3)
;       bra     _rf_next
        move.l  (a4)+, a5
        move.l  (a5)+, a0
        jmp     (a0)

        .align 2
        .extern _rf_code_orr
_rf_code_orr:
        move.l  (a3)+, d0
        or.l    d0, (a3)
;       bra     _rf_next
        move.l  (a4)+, a5
        move.l  (a5)+, a0
        jmp     (a0)

        .align 2
        .extern _rf_code_xorr
_rf_code_xorr:
        move.l  (a3)+, d0
        eor.l   d0, (a3)
;       bra     _rf_next
        move.l  (a4)+, a5
        move.l  (a5)+, a0
        jmp     (a0)

        .align 2
        .extern _rf_code_spat
_rf_code_spat:
        move.l  a3, d0
        move.l  d0, -(a3)
;       bra     _rf_next
        move.l  (a4)+, a5
        move.l  (a5)+, a0
        jmp     (a0)

        .align 2
        .extern _rf_code_spsto
_rf_code_spsto:
        move.l  12(a6), a3
;       bra     _rf_next
        move.l  (a4)+, a5
        move.l  (a5)+, a0
        jmp     (a0)

        .align 2
        .extern _rf_code_rpsto
_rf_code_rpsto:
        move.l  16(a6), a1
;       bra     _rf_next
        move.l  (a4)+, a5
        move.l  (a5)+, a0
        jmp     (a0)

        .align 2
        .extern _rf_code_cmove
_rf_code_cmove:
        move.l  (a3)+, d0
        move.l  (a3)+, a2
        move.l  (a3)+, a0
        bra     movfw1
movfwd: move.b  (a0)+, (a2)+
movfw1: dbf     d0, movfwd
;       bra     _rf_next
        move.l  (a4)+, a5
        move.l  (a5)+, a0
        jmp     (a0)

        .align 2
        .extern _rf_code_ustar
_rf_code_ustar:
        move.l  (a3)+, d0
        move.l  (a3)+, d1

        move.w  d0, d3
        mulu.w  d1, d3  ; d3.l is Al*Bl now

        swap    d0
        swap    d1
        move.w  d0, d2
        mulu.w  d1, d2  ; d2.l is Ah*Bh now

        swap    d0
        move.w  d0, d4
        mulu.w  d1, d4  ; d4 is Al*Bh

        swap    d4
        moveq   #0, d5
        move.w  d4, d5
        clr.w   d4      ; d5:d4 is 0x0000:Nh:Nl:0x0000, where N is Al*Bh

        add.l   d4, d3
        addx.l  d5, d2  ; add Al*Bh*0x10000 to the partial result in d2:d3

        swap    d0
        swap    d1

        move.w  d0, d4
        mulu.w  d1, d4  ; d4 is Ah*Bl

        swap    d4
        moveq   #0, d5
        move.w  d4, d5
        clr.w   d4      ; d5:d4 is 0x0000:Nh:Nl:0x0000, where N is Ah*Bl

        add.l   d4 ,d3

        addx.l  d5, d2  ; add Ah*Bl*0x10000 to the partial result

        ;d2:d3 is now the result
        move.l  d3, -(a3)
        move.l  d2, -(a3)
;       bra     _rf_next
        move.l  (a4)+, a5
        move.l  (a5)+, a0
        jmp     (a0)
*
        .align 2
        .extern _rf_code_uslas
_rf_code_uslas:
        move.l  (a3)+, d0
        move.l  (a3)+, d1
        move.l  (a3)+, d2
        move.l  #0x80000000, d3
        move.l  #0, d4
        cmp.l   d0, d1
        blo     umdiv1
        move.l  #-1, d4
        move.l  d4, d1
        bra     umdiv3
umdiv1: add.l   d2, d2
        addx.l  d1, d1
        bcs     umdiv4
        cmp.l   d1, d0
        bhi     umdiv2
umdiv4: add.l   d3, d4
        sub.l   d0, d1
umdiv2: lsr.l   #1, d3
        and.l   d3, d3
        bne     umdiv1
umdiv3: move.l  d1, -(a3)
        move.l  d4, -(a3)
;       bra     _rf_next
        move.l  (a4)+, a5
        move.l  (a5)+, a0
        jmp     (a0)
*
        .align 2
        .extern _rf_code_semis
_rf_code_semis:
        move.l  (a1)+, a4
;       bra     _rf_next
        move.l  (a4)+, a5
        move.l  (a5)+, a0
        jmp     (a0)

        .align 2
        .extern _rf_code_leave
_rf_code_leave:
        move.l  (a1), 4(a1)
;       bra     _rf_next
        move.l  (a4)+, a5
        move.l  (a5)+, a0
        jmp     (a0)

        .align 2
        .extern _rf_code_tor
_rf_code_tor:
        move.l  (a3)+, -(a1)
;       bra     _rf_next
        move.l  (a4)+, a5
        move.l  (a5)+, a0
        jmp     (a0)

        .align 2
        .extern _rf_code_fromr
_rf_code_fromr:
        move.l  (a1)+, -(a3)
;       bra     _rf_next
        move.l  (a4)+, a5
        move.l  (a5)+, a0
        jmp     (a0)

        .align 2
        .extern _rf_code_rr
_rf_code_rr:
        move.l  (a1), -(a3)
;       bra     _rf_next
        move.l  (a4)+, a5
        move.l  (a5)+, a0
        jmp     (a0)

        .align 2
        .extern _rf_code_zequ
_rf_code_zequ:
        tst.l   (a3)
        seq     3(a3)
        and.l   #1, (a3)
;       bra     _rf_next
        move.l  (a4)+, a5
        move.l  (a5)+, a0
        jmp     (a0)

        .align 2
        .extern _rf_code_zless
_rf_code_zless:
        tst.l   (a3)
        smi     3(a3)
        and.l   #1, (a3)
;       bra     _rf_next
        move.l  (a4)+, a5
        move.l  (a5)+, a0
        jmp     (a0)

        .align 2
        .extern _rf_code_plus
_rf_code_plus:
        move.l  (a3)+, d0
        add.l   d0, (a3)
;       bra     _rf_next
        move.l  (a4)+, a5
        move.l  (a5)+, a0
        jmp     (a0)

        .align 2
        .extern _rf_code_minus
_rf_code_minus:
        neg.l   (a3)
;       bra     _rf_next
        move.l  (a4)+, a5
        move.l  (a5)+, a0
        jmp     (a0)

        .align 2
        .extern _rf_code_dplus
_rf_code_dplus:
        move.l  (a3)+, d0
        move.l  (a3)+, d1
        move.l  (a3)+, d2
        move.l  (a3)+, d3
        add.l   d3, d1
        addx.l  d2, d0
        move.l  d1, -(a3)
        move.l  d0, -(a3)
;       bra     _rf_next
        move.l  (a4)+, a5
        move.l  (a5)+, a0
        jmp     (a0)

        .align 2
        .extern _rf_code_dminu
_rf_code_dminu:
        neg.l   4(a3)
        negx.l  (a3)
;       bra     _rf_next
        move.l  (a4)+, a5
        move.l  (a5)+, a0
        jmp     (a0)

        .align 2
        .extern _rf_code_over
_rf_code_over:
        move.l  4(a3), d0
        move.l  d0, -(a3)
;       bra     _rf_next
        move.l  (a4)+, a5
        move.l  (a5)+, a0
        jmp     (a0)

        .align 2
        .extern _rf_code_drop
_rf_code_drop:
        addq.l  #4, a3
;       bra     _rf_next
        move.l  (a4)+, a5
        move.l  (a5)+, a0
        jmp     (a0)

        .align 2
        .extern _rf_code_swap
_rf_code_swap:
        move.l  (a3)+, d0
        move.l  (a3), d1
        move.l  d0, (a3)
        move.l  d1, -(a3)
;       bra     _rf_next
        move.l  (a4)+, a5
        move.l  (a5)+, a0
        jmp     (a0)

        .align 2
        .extern _rf_code_dup
_rf_code_dup:
        move.l  (a3), d0
        move.l  d0, -(a3)
;       bra     _rf_next
        move.l  (a4)+, a5
        move.l  (a5)+, a0
        jmp     (a0)

        .align 2
        .extern _rf_code_pstor
_rf_code_pstor:
        move.l  (a3)+, a0
        move.l  (a3)+, d0
        add.l   d0, (a0)
;       bra     _rf_next
        move.l  (a4)+, a5
        move.l  (a5)+, a0
        jmp     (a0)

        .align 2
        .extern _rf_code_toggl
_rf_code_toggl:
        move.l  (a3)+, d0
        move.l  (a3)+, a0
        eor.b   d0, (a0)
;       bra     _rf_next
        move.l  (a4)+, a5
        move.l  (a5)+, a0
        jmp     (a0)

        .align 2
        .extern _rf_code_at
_rf_code_at:
        move.l  (a3), a0
        move.l  (a0), (a3)
;       bra     _rf_next
        move.l  (a4)+, a5
        move.l  (a5)+, a0
        jmp     (a0)

        .align 2
        .extern _rf_code_cat
_rf_code_cat:
        move.l  (a3), a0
        move.l  #0, (a3)
        move.b  (a0), 3(a3)
;       bra     _rf_next
        move.l  (a4)+, a5
        move.l  (a5)+, a0
        jmp     (a0)

        .align 2
        .extern _rf_code_store
_rf_code_store:
        move.l  (a3)+, a0
        move.l  (a3)+, (a0)
;       move.b  (a3)+, (a0)+
;       move.b  (a3)+, (a0)+
;       move.b  (a3)+, (a0)+
;       move.b  (a3)+, (a0)
;       bra     _rf_next
        move.l  (a4)+, a5
        move.l  (a5)+, a0
        jmp     (a0)

        .align 2
        .extern _rf_code_cstor
_rf_code_cstor:
        move.l  (a3)+, a0
        addq.l  #3, a3
        move.b  (a3)+, (a0)
;       bra     _rf_next
        move.l  (a4)+, a5
        move.l  (a5)+, a0
        jmp     (a0)

        .align 2
        .extern _rf_code_docol
_rf_code_docol:
        move.l  a4, -(a1)
        move.l  a5, a4
;       bra     _rf_next
        move.l  (a4)+, a5
        move.l  (a5)+, a0
        jmp     (a0)

        .align 2
        .extern _rf_code_docon
_rf_code_docon:
        move.l  (a5), -(a3)
;       bra     _rf_next
        move.l  (a4)+, a5
        move.l  (a5)+, a0
        jmp     (a0)

        .align 2
        .extern _rf_code_dovar
_rf_code_dovar:
        move.l  a5, -(a3)
;       bra     _rf_next
        move.l  (a4)+, a5
        move.l  (a5)+, a0
        jmp     (a0)

        .align 2
        .extern _rf_code_douse
_rf_code_douse:
        move.l  (a5), d0
        add.l   a6, d0
        move.l  d0, -(a3)
;       bra     _rf_next
        move.l  (a4)+, a5
        move.l  (a5)+, a0
        jmp     (a0)

        .align 2
        .extern _rf_code_dodoe
_rf_code_dodoe:
        move.l  a4, -(a1)
        move.l  (a5)+, a4
        move.l  a5, -(a3)
;       bra     _rf_next
        move.l  (a4)+, a5
        move.l  (a5)+, a0
        jmp     (a0)

        .align 2
        .extern _rf_code_stod
_rf_code_stod:
        tst.l   (a3)
        bmi     stod1
        move.l  #0, -(a3)
        bra     stod2
stod1:  move.l  #-1, -(a3)
stod2: ;bra     _rf_next
        move.l  (a4)+, a5
        move.l  (a5)+, a0
        jmp     (a0)

        .align 2
        .extern _rf_code_mon
_rf_code_mon:
        jsr     _rf_start
        move.l  #0, _rf_fp
        rts

        .align 2
        .extern _rf_code_cold
_rf_code_cold:
        move.l  _rf_origin, a0
        move.l  0x18(a0), d0    ; FORTH
        move.l  0x44(a0), a2
        move.l  d0, (a2)
        move.l  0x20(a0), a6    ; UP
        move.l  a6, _rf_up
        move.l  a6, a2          ; USER
        move.l  #11, d0
        lea.l   0x18(a0), a0
        bra     cold2
cold1:  move.l  (a0)+, (a2)+
cold2:  dbf     d0, cold1
        move.l  0x04(a0), a4    ; ABORT
        bra     _rf_code_rpsto  ; RP!
