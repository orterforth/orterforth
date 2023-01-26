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
	LEAX   ,U
	PSHU   X
	LBRA   NEXT
funcend_rf_code_spat EQU *
funcsize_rf_code_spat EQU funcend_rf_code_spat-_rf_code_spat

_rf_code_lit EXPORT
_rf_code_lit EQU *
	LDD    ,Y++
	LBRA   PUSHD
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
	LDD    ,U++ get quantity on stack and drop it
	BNE    ZBNO
_rf_code_bran EXPORT
_rf_code_bran EQU *
ZBYES EQU *
	TFR    Y,D  puts IP = Y into D for arithmetic
	ADDD   ,Y   adds offset to which IP is pointing
	TFR    D,Y  sets new IP
	LBRA   NEXT
ZBNO EQU *
	LEAY   2,Y  skip over branch
	LBRA   NEXT
funcend_rf_code_zbran EQU *
funcsize_rf_code_zbran EQU funcend_rf_code_zbran-_rf_code_zbran
funcend_rf_code_bran EQU *
funcsize_rf_code_bran EQU funcend_rf_code_bran-_rf_code_bran

	ENDSECTION

	SECTION	rwdata

usave EQU *
	FDB	$00

	ENDSECTION
