	SECTION	code

_rf_fp	IMPORT

_rf_start	EXPORT
_rf_start	EQU	*
	RTS
funcend_rf_start	EQU *
funcsize_rf_start	EQU	funcend_rf_start-_rf_start

_rf_trampoline	EXPORT
_rf_trampoline	EQU	*
	BRA	L00243		jump to while condition
L00242	EQU	*		while body
	LDX	_rf_fp+0,PCR	optim: removeTfrDX
	JSR	,X
L00243	EQU	*		while condition at rf.c:67
	LDD	_rf_fp+0,PCR	variable `rf_fp', declared at rf.c:60
	BNE	L00242
	RTS
funcend_rf_trampoline	EQU *
funcsize_rf_trampoline	EQU	funcend_rf_trampoline-_rf_trampoline
