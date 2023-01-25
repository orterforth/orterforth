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
	STY _rf_ip+0,PCR
	STX _rf_w+0,PCR
	RTS
funcend_rf_start EQU *
funcsize_rf_start EQU funcend_rf_start-_rf_start

_rf_trampoline EXPORT
_rf_trampoline EQU *
	BRA	trampoline2
trampoline1 EQU *
	LDX _rf_w+0,PCR
	LDY _rf_ip+0,PCR
	JSR	[_rf_fp+0,PCR]
trampoline2 EQU *
	LDD	_rf_fp+0,PCR
	BNE	trampoline1
	RTS
funcend_rf_trampoline EQU *
funcsize_rf_trampoline EQU funcend_rf_trampoline-_rf_trampoline

_rf_next EXPORT
_rf_next EQU *
	LDX ,Y++
	JMP [,X]
funcend_rf_next EQU *
funcsize_rf_next EQU funcend_rf_next-_rf_next

	ENDSECTION

	SECTION	rwdata

* Statically-initialized global variables
usave EQU *
	FDB	$00

	ENDSECTION
