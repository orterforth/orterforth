    SECTION code

* cmoc - S = stack pointer, U = base pointer.
* cmoc creates no stack frame if not necessary,
* so we need to detect whether it did. We assume
* that the Forth memory map puts U=SP < S=RP, so
* if U >= S we assume the prologue has created a
* stack frame and we take steps to retrieve the
* original values and create the right stack
* frame in the correct location on the C stack.

_rf_start EXPORT
_rf_start
        STY    _rf_ip+0,PCR * Y to IP
        STX    _rf_w+0,PCR  * X to W

        PULS   X            * pull rf_start return

        PSHS   U            * detect the stack frame
        CMPS   ,S
        PULS   U
        BLT    start1

                            * NO STACK FRAME PUSHED

        STU    _rf_sp+0,PCR * save U into SP
        STS    _rf_rp+0,PCR * save S into RP

        LDY    ssave+0,PCR  * get saved S
        LEAS   -2,Y         * keep fp return

        JMP    ,X           * return

                            * STACK FRAME PUSHED

start1
        LDD    ,U           * get previous U
        STD    _rf_sp+0,PCR * save it into SP

        LEAY   2,U          * get original S (RP), skip pushed BP
        STY    _rf_rp+0,PCR * save into RP

        TFR    S,D          * get S
        PSHS   U            * save U for arithmetic
        SUBD   ,S           * now D = S-U, i.e., frame size

        LDU    ssave+0,PCR  * to make U the C stack base pointer
        LEAU   -4,U         * keep fp return and BP

* NB it is not necessary to copy the actual value of the BP
* to the new stack frame, as it is simply the value of U
* that was pushed by the C prologue that we already copied
* into _rf_sp above and will be discarded by _rf_trampoline

        PSHS   U            * to make S the C stack pointer
        ADDD   ,S           * D = (S-U) + U
        TFR    D,S

        JMP    ,X           * return

_rf_trampoline EXPORT
_rf_trampoline
        PSHS   U,Y
        STS    ssave+0,PCR
        BRA    trampoline2
trampoline1
        LEAX   trampoline2+0,PCR * push return address before modifying S
        PSHS   X
        LDS    _rf_rp+0,PCR  * S to RP (after pushing return address)
        LDU    _rf_sp+0,PCR  * U to SP
        LDX    _rf_w+0,PCR   * X to W
        LDY    _rf_ip+0,PCR  * Y to IP
        JMP    [_rf_fp+0,PCR]
trampoline2
        LDD    _rf_fp+0,PCR
        BNE    trampoline1
        LDS    ssave+0,PCR
        PULS   U,Y
        RTS

* What follows is adapted from the original document to create compatible 
* assembly source for the orterforth project in January 2023. Some comments
* are preserved, although apart from acknowledgements much no longer applies.

* 6809
* fig-FORTH
* ASSEMBLY SOURCE LISTING
* RELEASE 1
* WITH COMPILER SECURITY
* AND
* VARIABLE LENGTH NAMES
*
* V 1.0
*
* JUNE 1980
*
* This public domain publication is provided through the courtesy of the 
* FORTH Interest Group. Further distribution must include this notice.

*       TTL    (C)1980 TALBOT MICROSYSTEMS
*       STTL   68'FORTH FOR 6809  : FIG MODEL
*       OPT    PAG,NOC,MAG,NOE
*
*
*** FORTH FOR 6809  By R. J. Talbot, Jr.         80.03.20
*
*** TALBOT  MICROSYSTEMS
***
***
***
*  This  version of FORTH follows the model created by the
*     The FORTH Interest Group   (FIG)
*    PO Box 1105,    San Carlos, CA 94070
*            (415) 962-8653
*  The  model is described in a document which nay be obtained from
*  them for $15.00 entitled  "fig-FORTH Installation Manual"
*
*  This version was developed for a  SWTPC 6809 system with FLEX, but
*  all terminal I/O is done by internal code, so it is independent
*  of the rom monitor or operating system such as FLEX.
*  The only systm dependent terminal I/O code which night need
*  changing is the location of the control ACIA port in memory
*  space - - the present assignments to E004 and the data word is
*  the control address + 1.
*
*  All terminal I/O is done in three assembly language subroutines:
*     PEMIT  - emits a character to terninal
*     PKEY   - reads a character from terminal (no echo)
*     PQTERM - tests terminal for a character having been typed
*
* The FORTH words for disk  I/O follow the model of the FORTH
* Interest Group -there are both a RAM simulation of disk I/O and real
* disk I/O of standard FORTH SCREENS. Also, there is an interface
* which allows  input or output using DOS fomat TEXT files, and
* there is a link to the DOS command structure so that
* DOS  commands may be executed from FORTH, including read into
* or write from  RAM simulated disk using TAPE or DISK SAVE or LOAD.
*
* This 68'FORTH Vers 1.1 assembled machine code program is available on
* a FLEX 9.0 soft-sectored 5-1/4 " diskette or
* on a 300 baud KCS cassette from TALBOT MICROSYSTEMS.
*              The cassette version may be used in conjunction with the
* RAM simulation of disk to implement a cassette-only version or to
* modify the DOS interface to something other than FLEX.
*
* Advanced versions are available ( in
* diskette form only) which contains a full 6809 assembler in FORTH,
* a screen oriented FORTH source text editor, and many other
* useful vocabularies -- contact TALBOT Microsystems.
*
* This assembly source code is available ( on FLEX 9.0 soft sectored
* 5 1/4" diskette only) -- contact TALBOT Microsystems.
*
*

*** * * *
*  CONVENTIONS USED IN THIS  PROGRAM ARE -
*
*  IP   = register Y points towards the next word to execute
*  SP   = register U points to LAST BYTE on the data stack
*  RP   = register S points to LAST WORD on return stack
*         register X is used as a general index register for pointing
*                at things. For some indexing purposes, Y,U, or S are
*                saved so X and Y, U, or S may be used at same time.
*  W    upon entry to a word, X = W = location of word containing
*                address of code to execute.
*
*
*  When A and B are used seperately, in order to maintain compatibility
*             with D register, A contains high byte, B the low byte.
*
*** * * *

	ENDSECTION

	SECTION	rwdata

N       RMB    10        used as scratch
UP      RMB    2         the pointer to the base of current user's
*                                   USER table ( for multi-tasking)
	ENDSECTION

	SECTION	code

*
* Start of FORTH Kernel
*
PUSHD   PSHU   D
        BRA    NEXT
*
* Here is the IP pusher for allowing nested words
* ;S is the equivalent  unnester
*
_rf_code_docol EXPORT
_rf_code_docol
DOCOL   PSHS   Y         save present IP on ret stack RP
        LEAY   2,X       kick Y up to first param after CFA in W=X
* LBRA NEXT  JUST DROP ON THROUGH T NEXT
*
*  NEXT takes 14 cycles
*
****  BEGINNING OF SIMULATION OF VIRTUAL FORTH MACHINE
*
_rf_code_ln EXPORT
_rf_code_ln
_rf_next EXPORT
_rf_next
NEXT    LDX    ,Y++      get W to X and then increment Y=IP
* the address of the pointer to the present code is in X now
*  if need it at any time, it may be computed by LDX -2,Y
NEXT3   JMP    [,X]      jump indirect to code pointed to by W
*
****  END OF SIMULATION OF THE VIRTUAL  FORTH MACHINE
_rf_code_semis EXPORT
_rf_code_semis
PSEMIS  LDY    ,S++      reset Y=IP to next addr and drop frm S=RP
        BRA    NEXT
_rf_code_spat EXPORT
_rf_code_spat
        LEAX   ,U        X = VALUE OF SP
        PSHU   X
        BRA    NEXT
_rf_code_spsto EXPORT
_rf_code_spsto
        LDU    UP,PCR
        LDU    6,U
        BRA    NEXT
_rf_code_rpsto EXPORT
_rf_code_rpsto
        LDX    UP,PCR
        LDS    8,X
        BRA    NEXT
_rf_code_lit EXPORT
_rf_code_lit
        LDD    ,Y++      get word pointed to by Y=IP and increment
        BRA    PUSHD     push D to data stack and then NEXT
_rf_code_exec EXPORT
_rf_code_exec
        PULU   X
        BRA    NEXT3
_rf_code_cold EXPORT
_rf_code_cold
        LDX    #RF_ORIGIN
        LDD    _rf_code_cold+0,PCR  COLD vector init
        LDY    2,X
        STD    ,Y
        LDD    12,X                 FORTH vocabulary init
        LDY    34,X
        STD    ,Y
        LDY    16,X                 UP init
        STY    UP,PCR
        LDB    #22                  USER variables init
        LEAX   12,X
COLD2   LDA    ,X+
        STA    ,Y+
        DECB
        BNE    COLD2
        LDY    2,X                  IP init to ABORT
        LBRA   _rf_code_rpsto       jump to RP!
_rf_code_zbran EXPORT
_rf_code_zbran
        LDD    ,U++      get quantity on stack and drop it
        BNE    ZBNO
_rf_code_bran EXPORT
_rf_code_bran
ZBYES   TFR    Y,D       puts IP = Y into D for arithmetic
        ADDD   ,Y        adds offset to which IP is pointing
        TFR    D,Y       sets new IP
        BRA    NEXT
ZBNO    LEAY   2,Y       skip over branch
        BRA    NEXT
_rf_code_xloop EXPORT
_rf_code_xloop
        LDD    #1
        BRA    XPLOP2
_rf_code_xploo EXPORT
_rf_code_xploo
XPLOOP  PULU   D
XPLOP2  TSTA
        BPL    XPLOF     forward loopint
        ADDD   ,S        add D to counter on RP=S
        STD    ,S
        ANDCC  #$1       set c bit
        SBCB   3,S
        SBCA   2,S
        BPL    ZBYES
        BRA    XPLONO    fall thru
XPLOF   ADDD   ,S
        STD    ,S
        SUBD   2,S
        BMI    ZBYES
XPLONO  LEAS   4,S       drop 4 bytes of counter and limit
        BRA    ZBNO      use ZBRAN to skip over unused delta
_rf_code_xdo EXPORT
_rf_code_xdo
        PULU   D         counter
        PULU   X         limit
        PSHS   X,D       X goes first, so becomes second on RP=S
        LBRA    NEXT
_rf_code_rr EXPORT
_rf_code_rr
        LDD    ,S        get counter from RP
        LBRA    PUSHD
_rf_code_digit EXPORT
_rf_code_digit
        LDA    3,U       second item is char of interest
        SUBA   #$30      ascii zero
        BMI    DIGIT2    if less than '0', ILLEGAL
        CMPA   #$A
        BMI    DIGIT0    if '9' or less
        CMPA   #$11
        BMI    DIGIT2    if less than 'A'
        CMPA   #$2B
        BPL    DIGIT2    if greater than 'Z'
        SUBA   #$7       translate 'A' thru 'Z'
DIGIT0  CMPA   1,U
        BPL    DIGIT2    if not less than base
        LDB    #1
        STA    3,U
DIGIT1  STB    1,U       store flag
        LBRA   NEXT
DIGIT2  CLRB
        LEAU   2,U       pop top off
        STB    0,U       make sure both bytes 0
        BRA    DIGIT1
_rf_code_pfind EXPORT
_rf_code_pfind
PD      EQU    N
PA0     EQU    N+2
PA      EQU    N+4
PCHR    EQU    N+6
        PSHS   Y         save Y
PFIND0  PULU   X,Y
        STY    PA0
*     *   *   *   *    X is dict ptr     Y is ptr to word that finding
PFIND1  LDB    ,X+       get count from dict
        STB    PCHR
        ANDB   #$3F      mask sign and precedence
        LDY    PA0
        CMPB   ,Y+
        BNE    PFIND4    not equal
PFIND2  LDA    ,Y+
        TST    ,X        is dict entry neg?
        BPL    PFIND8
        ORA    #$80      make A neg also
        CMPA   ,X+
        BEQ    FOUND
PFIND3  LDX    0,X       get new link in dict
        BNE    PFIND1    continue if new link not = 0
*   not found :
        TFR    X,D
        BRA    PFINDE
*
PFIND8  CMPA   ,X+
        BEQ    PFIND2
PFIND4  LDB    ,X+       scan forward to end of name
        BPL    PFIND4
        BRA    PFIND3
*
* found :
FOUND   LEAX   4,X       point to parameter field
        LDB    PCHR
        CLRA
        PSHU   X,D       X goes first
        LDB    #1
PFINDE  PULS   Y
        LBRA   PUSHD
* NOTE:  FC means offset (bytes) to First Character of next word
*        EW   "     "    to End of next Word
*        NC   "     "    to Next Character to start next enclose at
_rf_code_encl EXPORT
_rf_code_encl
        PULU   D         get char off stack to use as delim into B
        LDX    ,U        addr to begin
        CLR    N
        STB    N+1       save delim to use
*  wait for a non-delimiter or NUL
ENCL2   LDA    0,X
        BEQ    ENCL6
        CMPA   N+1       check for delim
        BNE    ENCL3
        LEAX   1,X
        INC    N
        BRA    ENCL2
*    found first character, Push PC
ENCL3   LDB    N         found first character
        CLRA
        PSHU   D
*   wait for a delimiter or NUL
ENCL4   LDA    ,X+
        BEQ    ENCL7
        CMPA   N+1       check for delim
        BEQ    ENCL5
        INC    N
        BRA    ENCL4
*   found EW,  Push it
ENCL5   LDB    N
        CLRA
        PSHU   D
*advance and push NC
        INCB
        LBRA   PUSHD
* found NUL before non delimiter, therefore, no word
ENCL6   LDB    N         A is zero
        PSHU   D
        INCB
        BRA    ENCL7P
* found NUL following word instead of SPACE
ENCL7   LDB    N
ENCL7P  PSHU   D         save EW
ENCL8   LDB    N         save NC
        LBRA   PUSHD
_rf_code_cmove EXPORT
_rf_code_cmove
        BSR    PCMOVE
        LBRA   NEXT
PCMOVE  PSHS   X,Y
        PULU   D,X,Y     D=ct, X=dest, Y=source
        PSHS   U
        TFR    Y,U
        TFR    D,Y       use Y as COUNTER
        LEAY   1,Y
CMOV2   LEAY   -1,Y
        BEQ    CMOV3
        LDA    ,U+
        STA    ,X+
        BRA    CMOV2
CMOV3   PULS   U
        PULS   X,Y
        RTS
_rf_code_ustar EXPORT
_rf_code_ustar
        BSR    USTARS
        LEAU   2,U
        LBRA   PUSHD
*
* The following is a  subroutine which multiplies top
* 2 words on stack, leaving 32-bit result: high order in D
* and low order word in 2ND word on stack.
USTARS  LDX    #17
        LDD    #0
USTAR2  ROR    2,U       shift mult
        ROR    3,U
        LEAX   -1,X      done ?
        BEQ    USTAR4
        BCC    USTAR3
        ADDD   ,U
USTAR3  RORA
        RORB
        BRA    USTAR2
USTAR4  RTS
_rf_code_uslas EXPORT
_rf_code_uslas
        LDD    2,U
        LDX    4,U
        STX    2,U
        STD    4,U
        ASL    3,U
        ROL    2,U
        LDX    #$10
USLL1   ROL    5,U
        ROL    4,U
        LDD    4,U
        SUBD   ,U
        ANDCC  #$FE      CLC
        BMI    USLL2
        STD    4,U
        ORCC   #1        SEC
USLL2   ROL    3,U
        ROL    2,U
        LEAX   -$1,X
        BNE    USLL1
        LEAU   2,U
        LBRA   NEXT
_rf_code_andd EXPORT
_rf_code_andd
        PULU   D
        ANDB   1,U
        ANDA   0,U
PUTD    STD    ,U
        LBRA   NEXT
_rf_code_orr EXPORT
_rf_code_orr
        PULU   D
        ORB    1,U
        ORA    0,U
        BRA    PUTD
_rf_code_xorr EXPORT
_rf_code_xorr
        PULU   D
        EORB   1,U
        EORA   0,U
        BRA    PUTD
_rf_code_plus EXPORT
_rf_code_plus
        PULU   D
        ADDD   ,U
        LBRA   PUTD
_rf_code_dplus EXPORT
_rf_code_dplus
        LDD    2,U
        ADDD   6,U
        STD    6,U
        LDD    ,U
        ADCB   5,U
        ADCA   4,U
        LEAU   4,U
        STD    ,U
        LBRA   NEXT
_rf_code_minus EXPORT
_rf_code_minus
        NEG    1,U
        BCS    MINUS2
        NEG    ,U
        LBRA   NEXT
MINUS2  COM    ,U
        LBRA   NEXT
_rf_code_dminu EXPORT
_rf_code_dminu
        COM    0,U
        COM    1,U
        COM    2,U
        NEG    3,U
        BNE    DMINX
        INC    2,U
        BNE    DMINX
        INC    1,U
        BNE    DMINX
        INC    ,U
DMINX   LBRA   NEXT
_rf_code_stod EXPORT
_rf_code_stod
        LDD    #0
        TST    ,U
        BPL    STOD2
        COMA
        COMB
STOD2   STD    ,--U
        LBRA   NEXT
_rf_code_zequ EXPORT
_rf_code_zequ
        CLRA
        CLRB
        LDX    ,U
        BNE    ZEQU2
        INCB
ZEQU2   STD    ,U
        LBRA   NEXT
_rf_code_zless EXPORT
_rf_code_zless
        LDA    #$80      check sign bit
        ANDA   ,U
        BEQ    ZLESS2
        CLRA
        LDB    #1
        LBRA   PUTD
ZLESS2  CLRB
        LBRA   PUTD
_rf_code_leave EXPORT
_rf_code_leave
        LDD    ,S
        STD    2,S
        LBRA   NEXT
_rf_code_tor EXPORT
_rf_code_tor
        PULU   D
        PSHS   D
        LBRA   NEXT
_rf_code_fromr EXPORT
_rf_code_fromr
        PULS   D
        PSHU   D
        LBRA   NEXT
_rf_code_over EXPORT
_rf_code_over
        LDD    2,U
        LBRA   PUSHD
_rf_code_drop EXPORT
_rf_code_drop
        LEAU   2,U
        LBRA   NEXT
_rf_code_swap EXPORT
_rf_code_swap
        PULU   D,X
        EXG    D,X       swap order
        PSHU   D,X
        LBRA   NEXT
_rf_code_dup EXPORT
_rf_code_dup
        LDD    ,U
        LBRA   PUSHD
_rf_code_pstor EXPORT
_rf_code_pstor
        LDX    ,U++
        LDD    ,U++
        ADDD   ,X
        STD    ,X
        LBRA   NEXT
_rf_code_at EXPORT
_rf_code_at
        LDD    [,U]      U points to address on stack, get # there
        LBRA   PUTD      replace stack add with #
_rf_code_cat EXPORT
_rf_code_cat
        LDB    [,U]
        CLRA
        LBRA   PUTD
_rf_code_store EXPORT
_rf_code_store
        PULU   X
        PULU   D         forced to do this because in wrong order
        STD    ,X
        LBRA   NEXT
_rf_code_cstor EXPORT
_rf_code_cstor
        PULU   X
        PULU   D
        STB    ,X
        LBRA   NEXT
_rf_code_dodoe EXPORT
_rf_code_dodoe
DODOES  PSHS   Y         push return address to RP=S
        LDY    2,X       get new IP
        LEAX   4,X       get address of parameter
        PSHU   X
        LBRA   NEXT
_rf_code_toggl EXPORT
_rf_code_toggl
        PULU   D
        PULU   X
        EORB   ,X
        STB    ,X
        LBRA   NEXT
_rf_code_docon EXPORT
_rf_code_docon
DOCON   LDD    2,X
        LBRA   PUSHD
_rf_code_dovar EXPORT
_rf_code_dovar
DOVAR   LEAX   2,X       gets address after CFA in W=X
        PSHU   X
        LBRA   NEXT
_rf_code_douse EXPORT
_rf_code_douse
DOUSER  LDD    2,X
        ADDD   UP,PCR
        LBRA   PUSHD
_rf_code_xt EXPORT
_rf_code_xt
        LDD    #0
        STD    _rf_fp+0,PCR
        LBSR   _rf_start
        RTS
_rf_code_cl EXPORT
_rf_code_cl
        LDD    #2
        LBRA   PUSHD
_rf_code_cs EXPORT
_rf_code_cs
        ASL    1,U
        ROL    0,U
        LBRA   NEXT

	ENDSECTION

	SECTION	rwdata

_rf_fp EXPORT
_rf_fp
	FDB	$0000

_rf_ip EXPORT
_rf_ip
	FDB	$0000

_rf_rp EXPORT
_rf_rp
	FDB	$0000

_rf_sp EXPORT
_rf_sp
	FDB	$0000

_rf_up EXPORT
_rf_up EQU UP

_rf_w EXPORT
_rf_w
	FDB	$0000

ssave
	FDB	$0000

	ENDSECTION
