	SECTION	code

_rf_next IMPORT
_rf_up IMPORT

_rf_code_emit EXPORT
_rf_code_emit EQU *
	PULU   D
	TFR    B,A
	ANDA   #$7F
	JSR    $B54A
	LDX    _rf_up+0,PCR
	LDD    #1
	ADDD   26,X
	STD    26,X
	LBRA   _rf_next
funcend_rf_code_emit EQU *
funcsize_rf_code_emit EQU funcend_rf_code_emit-_rf_code_emit

_rf_code_key EXPORT
_rf_code_key EQU *
	JSR    $B538
	ANDA   #$7F
	TFR    A,B
	CLRA
	PSHU   D
	LBRA   _rf_next
funcend_rf_code_key EQU *
funcsize_rf_code_key EQU funcend_rf_code_key-_rf_code_key

_rf_code_qterm EXPORT
_rf_code_qterm EQU *
	CLRA
	CLRB
	PSHU   D
	JSR    $8006
	CMPA   #$03
	LBNE   _rf_next
	INC    3,U
	LBRA   _rf_next
funcend_rf_code_qterm EQU *
funcsize_rf_code_qterm EQU funcend_rf_code_qterm-_rf_code_qterm

_rf_code_cr EXPORT
_rf_code_cr EQU *
	LDA    #$0D
	JSR    $B54A
	LBRA   _rf_next
funcend_rf_code_cr EQU *
funcsize_rf_code_cr EQU funcend_rf_code_cr-_rf_code_cr

	ENDSECTION
