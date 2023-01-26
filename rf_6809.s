	SECTION	code

_rf_ip IMPORT
_rf_fp IMPORT
_rf_sp IMPORT
_rf_w IMPORT

* TODO Under OS-9, CMOC uses Y to refer to the data section of
* the current process. Any code that needs to use Y must 
* preserve its value and restore it when finished. For 
* portability, this rule should also be observed on platforms 
* other than OS-9.

_rf_start EXPORT
_rf_start EQU *
	STY    _rf_ip+0,PCR
	STX    _rf_w+0,PCR
	PSHS   U            * detect the stack frame
	CMPS   ,S
	PULS   U
	BLT    start1
	STU    _rf_sp+0,PCR * no stack frame pushed
	BRA    start2
start1 EQU *
	LDX    ,U           * stack frame pushed, get previous U
	STX    _rf_sp+0,PCR
start2 EQU *
	RTS
funcend_rf_start EQU *
funcsize_rf_start EQU funcend_rf_start-_rf_start

_rf_trampoline EXPORT
_rf_trampoline EQU *
	STU    usave+0,PCR
	BRA	   trampoline2
trampoline1 EQU *
	LDU    _rf_sp+0,PCR
	LDX    _rf_w+0,PCR
	LDY    _rf_ip+0,PCR
	JSR	   [_rf_fp+0,PCR]
trampoline2 EQU *
	LDD	   _rf_fp+0,PCR
	BNE	   trampoline1
	LDU    usave+0,PCR
	RTS
funcend_rf_trampoline EQU *
funcsize_rf_trampoline EQU funcend_rf_trampoline-_rf_trampoline

N EQU *
	RMB    10

PUSHD EQU *
	PSHU   D
	BRA    NEXT

_rf_next EXPORT
_rf_next EQU *
NEXT EQU *
	LDX    ,Y++
NEXT3 EQU *
	JMP    [,X]
funcend_rf_next EQU *
funcsize_rf_next EQU funcend_rf_next-_rf_next

_rf_code_spat EXPORT
_rf_code_spat EQU *
	LEAX   ,U        X = VALUE OF SP
	PSHU   X
	LBRA   NEXT
funcend_rf_code_spat EQU *
funcsize_rf_code_spat EQU funcend_rf_code_spat-_rf_code_spat

_rf_code_lit EXPORT
_rf_code_lit EQU *
	LDD    ,Y++      get word pointed to by Y=IP and increment
	LBRA   PUSHD     push D to data stack and then NEXT
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
	LBRA   NEXT
ZBNO EQU *
	LEAY   2,Y       skip over branch
	LBRA   NEXT
funcend_rf_code_zbran EQU *
funcsize_rf_code_zbran EQU funcend_rf_code_zbran-_rf_code_zbran
funcend_rf_code_bran EQU *
funcsize_rf_code_bran EQU funcend_rf_code_bran-_rf_code_bran

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

	ENDSECTION

	SECTION	rwdata

usave EQU *
	FDB	$00

	ENDSECTION
