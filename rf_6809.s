	SECTION	code

_rf_ip IMPORT
_rf_fp IMPORT
_rf_rp IMPORT
_rf_sp IMPORT
_rf_up IMPORT
_rf_w IMPORT

_rf_start EXPORT
_rf_start EQU *
	STY    _rf_ip+0,PCR * Y to IP
	STX    _rf_w+0,PCR  * X to W

	PULS   X			* pull rf_start return

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

start1 EQU *
	LDD    ,U           * get previous U
	STD    _rf_sp+0,PCR * save it into SP

	LEAY   2,U          * get original S (RP), skip pushed BP
	STY    _rf_rp+0,PCR * save into RP

	TFR    S,D          * get S
	PSHS   U            * save U for arithmetic
	SUBD   ,S           * now D = S-U, i.e., frame size

	LDU    ssave+0,PCR  * to make U the C stack base pointer
	LEAU   -4,U         * keep fp return and BP

	PSHS   U            * to make S the C stack pointer
	ADDD   ,S           * D = (S-U) + U
	TFR    D,S

	JMP    ,X           * return

funcend_rf_start EQU *
funcsize_rf_start EQU funcend_rf_start-_rf_start

_rf_trampoline EXPORT
_rf_trampoline EQU *
	PSHS   U,Y
	STS    ssave+0,PCR
	BRA	   trampoline2
trampoline1 EQU *
	LEAX   trampoline2+0,PCR * push return address before modifying S
	PSHS   X
	LDS    _rf_rp+0,PCR  * S to RP (after pushing return address)
	LDU    _rf_sp+0,PCR  * U to SP
	LDX    _rf_w+0,PCR   * X to W
	LDY    _rf_ip+0,PCR  * Y to IP
	JMP	   [_rf_fp+0,PCR]
trampoline2 EQU *
	LDD	   _rf_fp+0,PCR
	BNE	   trampoline1
	LDS    ssave+0,PCR
	PULS   U,Y
	RTS
funcend_rf_trampoline EQU *
funcsize_rf_trampoline EQU funcend_rf_trampoline-_rf_trampoline

N EQU *
	RMB    10

PUSHD EQU *
	PSHU   D
	BRA    NEXT

_rf_code_docol EXPORT
_rf_code_docol EQU *
	PSHS   Y         save present IP on ret stack RP
	LEAY   2,X       kick Y up to first param after CFA in W=X
funcend_rf_code_docol EQU *
funcsize_rf_code_docol EQU funcend_rf_code_docol-_rf_code_docol

_rf_code_ln EXPORT
_rf_code_ln EQU *
_rf_next EXPORT
_rf_next EQU *
NEXT EQU *
	LDX    ,Y++
NEXT3 EQU *
	JMP    [,X]
funcend_rf_next EQU *
funcsize_rf_next EQU funcend_rf_next-_rf_next

_rf_code_semis EXPORT
_rf_code_semis EQU *
	LDY    ,S++      reset Y=IP to next addr and drop frm S=RP
	BRA    NEXT
funcend_rf_code_semis EQU *
funcsize_rf_code_semis EQU funcend_rf_code_semis-_rf_code_semis

_rf_code_spat EXPORT
_rf_code_spat EQU *
	LEAX   ,U        X = VALUE OF SP
	PSHU   X
	BRA   NEXT
funcend_rf_code_spat EQU *
funcsize_rf_code_spat EQU funcend_rf_code_spat-_rf_code_spat

_rf_code_spsto EXPORT
_rf_code_spsto EQU *
	LDU    _rf_up+0,PCR
	LDU    6,U
	BRA   NEXT
funcend_rf_code_spsto EQU *
funcsize_rf_code_spsto EQU funcend_rf_code_spsto-_rf_code_spsto

_rf_code_rpsto EXPORT
_rf_code_rpsto EQU *
	LDX    _rf_up+0,PCR
	LDS    8,X
	BRA   NEXT
funcend_rf_code_rpsto EQU *
funcsize_rf_code_rpsto EQU funcend_rf_code_rpsto-_rf_code_rpsto

_rf_code_lit EXPORT
_rf_code_lit EQU *
	LDD    ,Y++      get word pointed to by Y=IP and increment
	BRA   PUSHD     push D to data stack and then NEXT
funcend_rf_code_lit EQU *
funcsize_rf_code_lit EQU funcend_rf_code_lit-_rf_code_lit

_rf_code_exec EXPORT
_rf_code_exec EQU *
	PULU   X
	BRA    NEXT3
funcend_rf_code_exec EQU *
funcsize_rf_code_exec EQU funcend_rf_code_exec-_rf_code_exec

_rf_code_zbran EXPORT
_rf_code_zbran EQU *
	LDD    ,U++      get quantity on stack and drop it
	BNE    ZBNO
_rf_code_bran EXPORT
_rf_code_bran EQU *
ZBYES EQU *
	TFR    Y,D       puts IP = Y into D for arithmetic
	ADDD   ,Y        adds offset to which IP is pointing
	TFR    D,Y       sets new IP
	BRA   NEXT
ZBNO EQU *
	LEAY   2,Y       skip over branch
	BRA   NEXT
funcend_rf_code_zbran EQU *
funcsize_rf_code_zbran EQU funcend_rf_code_zbran-_rf_code_zbran
funcend_rf_code_bran EQU *
funcsize_rf_code_bran EQU funcend_rf_code_bran-_rf_code_bran

_rf_code_xloop EXPORT
_rf_code_xloop EQU *
	LDD    #1
	BRA    XPLOP2
_rf_code_xploo EXPORT
_rf_code_xploo EQU *
XPLOOP EQU *
	PULU   D
XPLOP2 EQU *
	TSTA
	BPL    XPLOF     forward loopint
	ADDD   ,S        add D to counter on RP=S
	STD    ,S
	ANDCC  #$1       set c bit
	SBCB   3,S
	SBCA   2,S
	BPL    ZBYES
	BRA    XPLONO    fall thru
XPLOF EQU *
	ADDD   ,S
	STD    ,S
	SUBD   2,S
	BMI    ZBYES
XPLONO EQU *
	LEAS   4,S       drop 4 bytes of counter and limit
	BRA    ZBNO      use ZBRAN to skip over unused delta
funcend_rf_code_xloop EQU *
funcsize_rf_code_xloop EQU funcend_rf_code_xloop-_rf_code_xloop
funcend_rf_code_xploo EQU *
funcsize_rf_code_xploo EQU funcend_rf_code_xploo-_rf_code_xploo

_rf_code_xdo EXPORT
_rf_code_xdo EQU *
	PULU   D         counter
	PULU   X         limit
	PSHS   X,D       X goes first, so becomes second on RP=S
	BRA   NEXT
funcend_rf_code_xdo EQU *
funcsize_rf_code_xdo EQU funcend_rf_code_xdo-_rf_code_xdo

_rf_code_rr EXPORT
_rf_code_rr EQU *
	LDD    ,S        get counter from RP
	BRA   PUSHD
funcend_rf_code_rr EQU *
funcsize_rf_code_rr EQU funcend_rf_code_rr-_rf_code_rr

_rf_code_digit EXPORT
_rf_code_digit EQU *
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
DIGIT0 EQU *
	CMPA   1,U
	BPL    DIGIT2    if not less than base
	LDB    #1
	STA    3,U
DIGIT1 EQU *
	STB    1,U       store flag
	LBRA   NEXT
DIGIT2 EQU *
	CLRB
	LEAU   2,U       pop top off
	STB    0,U       make sure both bytes 0
	BRA    DIGIT1
funcend_rf_code_digit EQU *
funcsize_rf_code_digit EQU funcend_rf_code_digit-_rf_code_digit

_rf_code_pfind EXPORT
_rf_code_pfind EQU *
PD EQU N
PA0 EQU N+2
PA EQU N+4
PCHR EQU N+6
	PSHS   Y         save Y
PFIND0 EQU *
	PULU   X,Y
	STY    PA0
PFIND1 EQU *
	LDB    ,X+       get count from dict
	STB    PCHR
	ANDB   #$3F      mask sign and precedence
	LDY    PA0
	CMPB   ,Y+
	BNE    PFIND4    not equal
PFIND2 EQU *
	LDA    ,Y+
	TST    ,X        is dict entry neg?
	BPL    PFIND8
	ORA    #$80      make A neg also
	CMPA   ,X+
	BEQ    FOUND
PFIND3 EQU *
	LDX    0,X       get new link in dict
	BNE    PFIND1    continue if new link not = 0
*   not found :
	TFR    X,D
	BRA    PFINDE
*
PFIND8 EQU *
	CMPA   ,X+
	BEQ    PFIND2
PFIND4 EQU *
	LDB    ,X+
	BPL    PFIND4
	BRA    PFIND3
*
* found :
FOUND EQU *
	LEAX   4,X       point to parameter field
	LDB    PCHR
	CLRA
	PSHU   X,D
	LDB    #1
PFINDE EQU *
	PULS   Y
	LBRA   PUSHD
funcend_rf_code_pfind EQU *
funcsize_rf_code_pfind EQU funcend_rf_code_pfind-_rf_code_pfind

_rf_code_encl EXPORT
_rf_code_encl EQU *
	PULU   D         get char off stack to use as delim into B
	LDX    ,U        addr to begin
	CLR    N
	STB    N+1       save delim to use
*  wait for a non-delimiter or NUL
ENCL2 EQU *
	LDA    0,X
	BEQ    ENCL6
	CMPA   N+1       check for delim
	BNE    ENCL3
	LEAX   1,X
	INC    N
	BRA    ENCL2
*    found first character, Push PC
ENCL3 EQU *
	LDB    N         found first character
	CLRA
	PSHU   D
*   wait for a delimiter or NUL
ENCL4 EQU *
	LDA    ,X+
	BEQ    ENCL7
	CMPA   N+1       check for delim
	BEQ    ENCL5
	INC    N
	BRA    ENCL4
*   found EW,  Push it
ENCL5 EQU *
	LDB    N
	CLRA
	PSHU   D
*advance and push NC
	INCB
	LBRA   PUSHD
* found NUL before non delimiter, therefore, no word
ENCL6 EQU *
	LDB    N         A is zero
	PSHU   D
	INCB
	BRA    ENCL7P
* found NUL following word instead of SPACE
ENCL7 EQU *
	LDB    N
ENCL7P EQU *
	PSHU   D         save EW
ENCL8 EQU *
	LDB    N         save NC
	LBRA   PUSHD
funcend_rf_code_encl EQU *
funcsize_rf_code_encl EQU funcend_rf_code_encl-_rf_code_encl

_rf_code_cmove EXPORT
_rf_code_cmove EQU *
	BSR    PCMOVE
	LBRA   NEXT
PCMOVE EQU *
	PSHS   X,Y
	PULU   D,X,Y     D=ct, X=dest, Y=source
	PSHS   U
	TFR    Y,U
	TFR    D,Y       use Y as COUNTER
	LEAY   1,Y
CMOV2 EQU *
	LEAY   -1,Y
	BEQ    CMOV3
	LDA    ,U+
	STA    ,X+
	BRA    CMOV2
CMOV3 EQU *
	PULS   U
	PULS   X,Y
	RTS
funcend_rf_code_cmove EQU *
funcsize_rf_code_cmove EQU funcend_rf_code_cmove-_rf_code_cmove

_rf_code_ustar EXPORT
_rf_code_ustar EQU *
	BSR    USTARS
	LEAU   2,U
	LBRA   PUSHD
USTARS EQU *
	LDX    #17
	LDD    #0
USTAR2 EQU *
	ROR    2,U       shift mult
	ROR    3,U
	LEAX   -1,X      done ?
	BEQ    USTAR4
	BCC    USTAR3
	ADDD   ,U
USTAR3 EQU *
	RORA
	RORB
	BRA    USTAR2
USTAR4 EQU *
	RTS
funcend_rf_code_ustar EQU *
funcsize_rf_code_ustar EQU funcend_rf_code_ustar-_rf_code_ustar

_rf_code_uslas EXPORT
_rf_code_uslas EQU *
	LDD    2,U
	LDX    4,U
	STX    2,U
	STD    4,U
	ASL    3,U
	ROL    2,U
	LDX    #$10
USLL1 EQU *
	ROL    5,U
	ROL    4,U
	LDD    4,U
	SUBD   ,U
	ANDCC  #$FE      CLC
	BMI    USLL2
	STD    4,U
	ORCC   #1        SEC
USLL2 EQU *
	ROL    3,U
	ROL    2,U
	LEAX   -$1,X
	BNE    USLL1
	LEAU   2,U
	LBRA   NEXT
funcend_rf_code_uslas EQU *
funcsize_rf_code_uslas EQU funcend_rf_code_uslas-_rf_code_uslas

_rf_code_andd EXPORT
_rf_code_andd EQU *
	PULU   D
	ANDB   1,U
	ANDA   0,U
PUTD EQU *
	STD    ,U
	LBRA   NEXT
funcend_rf_code_andd EQU *
funcsize_rf_code_andd EQU funcend_rf_code_andd-_rf_code_andd

_rf_code_orr EXPORT
_rf_code_orr EQU *
	PULU   D
	ORB    1,U
	ORA    0,U
	BRA    PUTD
funcend_rf_code_orr EQU *
funcsize_rf_code_orr EQU funcend_rf_code_orr-_rf_code_orr

_rf_code_xorr EXPORT
_rf_code_xorr EQU *
	PULU   D
	EORB   1,U
	EORA   0,U
	BRA    PUTD
funcend_rf_code_xorr EQU *
funcsize_rf_code_xorr EQU funcend_rf_code_xorr-_rf_code_xorr

_rf_code_plus EXPORT
_rf_code_plus EQU *
	PULU   D
	ADDD   ,U
	LBRA   PUTD
funcend_rf_code_plus EQU *
funcsize_rf_code_plus EQU funcend_rf_code_plus-_rf_code_plus

_rf_code_dplus EXPORT
_rf_code_dplus EQU *
	LDD    2,U
	ADDD   6,U
	STD    6,U
	LDD    ,U
	ADCB   5,U
	ADCA   4,U
	LEAU   4,U
	STD    ,U
	LBRA   NEXT
funcend_rf_code_dplus EQU *
funcsize_rf_code_dplus EQU funcend_rf_code_dplus-_rf_code_dplus

_rf_code_minus EXPORT
_rf_code_minus EQU *
	NEG    1,U
	BCS    MINUS2
	NEG    ,U
	LBRA   NEXT
MINUS2 EQU *
	COM    ,U
	LBRA   NEXT
funcend_rf_code_minus EQU *
funcsize_rf_code_minus EQU funcend_rf_code_minus-_rf_code_minus

_rf_code_dminu EXPORT
_rf_code_dminu EQU *
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
DMINX EQU *
	LBRA   NEXT
funcend_rf_code_dminu EQU *
funcsize_rf_code_dminu EQU funcend_rf_code_dminu-_rf_code_dminu

_rf_code_stod EXPORT
_rf_code_stod EQU *
	LDD    #0
	TST    ,U
	BPL    STOD2
	COMA
	COMB
STOD2 EQU *
	STD    ,--U
	LBRA   NEXT
funcend_rf_code_stod EQU *
funcsize_rf_code_stod EQU funcend_rf_code_stod-_rf_code_stod

_rf_code_zequ EXPORT
_rf_code_zequ EQU *
	CLRA
	CLRB
	LDX    ,U
	BNE    ZEQU2
	INCB
ZEQU2 EQU *
	STD    ,U
	LBRA   NEXT
funcend_rf_code_zequ EQU *
funcsize_rf_code_zequ EQU funcend_rf_code_zequ-_rf_code_zequ

_rf_code_zless EXPORT
_rf_code_zless EQU *
	LDA    #$80      check sign bit
	ANDA   ,U
	BEQ    ZLESS2
	CLRA
	LDB    #1
	LBRA   PUTD
ZLESS2 EQU *
	CLRB
	LBRA   PUTD
funcend_rf_code_zless EQU *
funcsize_rf_code_zless EQU funcend_rf_code_zless-_rf_code_zless

_rf_code_leave EXPORT
_rf_code_leave EQU *
	LDD    ,S
	STD    2,S
	LBRA   NEXT
funcend_rf_code_leave EQU *
funcsize_rf_code_leave EQU funcend_rf_code_leave-_rf_code_leave

_rf_code_tor EXPORT
_rf_code_tor EQU *
	PULU   D
	PSHS   D
	LBRA   NEXT
funcend_rf_code_tor EQU *
funcsize_rf_code_tor EQU funcend_rf_code_tor-_rf_code_tor

_rf_code_fromr EXPORT
_rf_code_fromr EQU *
	PULS   D
	PSHU   D
	LBRA   NEXT
funcend_rf_code_fromr EQU *
funcsize_rf_code_fromr EQU funcend_rf_code_fromr-_rf_code_fromr

_rf_code_over EXPORT
_rf_code_over EQU *
	LDD    2,U
	LBRA   PUSHD
funcend_rf_code_over EQU *
funcsize_rf_code_over EQU funcend_rf_code_over-_rf_code_over

_rf_code_drop EXPORT
_rf_code_drop EQU *
	LEAU   2,U
	LBRA   NEXT
funcend_rf_code_drop EQU *
funcsize_rf_code_drop EQU funcend_rf_code_drop-_rf_code_drop

_rf_code_swap EXPORT
_rf_code_swap EQU *
	PULU   D,X
	EXG    D,X       swap order
	PSHU   D,X
	LBRA   NEXT
funcend_rf_code_swap EQU *
funcsize_rf_code_swap EQU funcend_rf_code_swap-_rf_code_swap

_rf_code_dup EXPORT
_rf_code_dup EQU *
	LDD    ,U
	LBRA   PUSHD
funcend_rf_code_dup EQU *
funcsize_rf_code_dup EQU funcend_rf_code_dup-_rf_code_dup

_rf_code_pstor EXPORT
_rf_code_pstor EQU *
	LDX    ,U++
	LDD    ,U++
	ADDD   ,X
	STD    ,X
	LBRA   NEXT
funcend_rf_code_pstor EQU *
funcsize_rf_code_pstor EQU funcend_rf_code_pstor-_rf_code_pstor

_rf_code_at EXPORT
_rf_code_at EQU *
	LDD    [,U]      U points to address on stack, get # there
	LBRA   PUTD      replace stack add with #
funcend_rf_code_at EQU *
funcsize_rf_code_at EQU funcend_rf_code_at-_rf_code_at

_rf_code_cat EXPORT
_rf_code_cat EQU *
	LDB    [,U]
	CLRA
	LBRA   PUTD
funcend_rf_code_cat EQU *
funcsize_rf_code_cat EQU funcend_rf_code_cat-_rf_code_cat

_rf_code_store EXPORT
_rf_code_store EQU *
	PULU   X
	PULU   D         forced to do this because in wrong order
	STD    ,X
	LBRA   NEXT
funcend_rf_code_store EQU *
funcsize_rf_code_store EQU funcend_rf_code_store-_rf_code_store

_rf_code_cstor EXPORT
_rf_code_cstor EQU *
	PULU   X
	PULU   D
	STB    ,X
	LBRA   NEXT
funcend_rf_code_cstor EQU *
funcsize_rf_code_cstor EQU funcend_rf_code_cstor-_rf_code_cstor

_rf_code_dodoe EXPORT
_rf_code_dodoe EQU *
	PSHS   Y         push return address to RP=S
	LDY    2,X       get new IP
	LEAX   4,X       get address of parameter
	PSHU   X
	LBRA   NEXT
funcend_rf_code_dodoe EQU *
funcsize_rf_code_dodoe EQU funcend_rf_code_dodoe-_rf_code_dodoe

_rf_code_toggl EXPORT
_rf_code_toggl EQU *
	PULU   D
	PULU   X
	EORB   ,X
	STB    ,X
	LBRA   NEXT
funcend_rf_code_toggl EQU *
funcsize_rf_code_toggl EQU funcend_rf_code_toggl-_rf_code_toggl

_rf_code_docon EXPORT
_rf_code_docon EQU *
	LDD    2,X
	LBRA   PUSHD
funcend_rf_code_docon EQU *
funcsize_rf_code_docon EQU funcend_rf_code_docon-_rf_code_docon

_rf_code_dovar EXPORT
_rf_code_dovar EQU *
	LEAX   2,X
	PSHU   X
	LBRA NEXT
funcend_rf_code_dovar EQU *
funcsize_rf_code_dovar EQU funcend_rf_code_dovar-_rf_code_dovar

_rf_code_douse EXPORT
_rf_code_douse EQU *
	LDD    2,X
	ADDD   _rf_up+0,PCR
	LBRA   PUSHD
funcend_rf_code_douse EQU *
funcsize_rf_code_douse EQU funcend_rf_code_douse-_rf_code_douse

_rf_code_xt EXPORT
_rf_code_xt EQU *
	LDD    #0
	STD    _rf_fp+0,PCR
	LBSR   _rf_start
	RTS
funcend_rf_code_xt EQU *
funcsize_rf_code_xt EQU funcend_rf_code_xt-_rf_code_xt

_rf_code_cl EXPORT
_rf_code_cl EQU *
	LDD    #2
	LBRA   PUSHD
funcend_rf_code_cl EQU *
funcsize_rf_code_cl EQU funcend_rf_code_cl-_rf_code_cl

_rf_code_cs EXPORT
_rf_code_cs EQU *
	ASL    1,U
	ROL    0,U
	LBRA   NEXT
funcend_rf_code_cs EQU *
funcsize_rf_code_cs EQU funcend_rf_code_cs-_rf_code_cs

	ENDSECTION

	SECTION	rwdata

ssave EQU *
	FDB	$0000

	ENDSECTION
