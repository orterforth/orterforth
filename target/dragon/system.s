	SECTION	code

_rf_next IMPORT
_rf_up IMPORT

_rf_init EXPORT
_rf_init EQU *
*  Speedkey http://archive.worldofdragon.org/phpBB3/viewtopic.php?f=8&t=314
	LDD    $010D
	CMPD   #$00FA
	BEQ    init1
	LDA    $FF03
	ANDA   #$FE
	STA    $FF03
	LDX    #$00FA
	LDD    #$7401
	STD    0,X
	LDD    #$517E
	STD    2,X
	LDD    19,X
	STD    4,X
	LDD    #$00FA
	STD    19,X
	LDA    $FF03
	ORA    #$01
	STA    $FF03
init1 EQU *
	RTS
funcend_rf_init EQU *
funcsize_rf_init EQU funcend_rf_init-_rf_init

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

_rf_code_dchar EXPORT
_rf_code_dchar EQU *
dchar1 EQU *
	LDB    $FF05
	ANDB   #$10
	BEQ    dchar1
	LDB    $FF04
	LDX    #$0000
	CMPB   1,U
	BNE    dchar2
	LEAX   1,X
dchar2 EQU *
	STX    ,U
	CLRA
	PSHU   D
	LBRA   _rf_next
funcend_rf_code_dchar EQU *
funcsize_rf_code_dchar EQU funcend_rf_code_dchar-_rf_code_dchar

_rf_code_bread EXPORT
_rf_code_bread EQU *
	PULU   X
	LDB    #$80
bread1 EQU *
	LDA    $FF05
	ANDA   #$10
	BEQ    bread1
	LDA    $FF04
	STA    ,X+
	DECB
	BNE    bread1
	LBRA   _rf_next
funcend_rf_code_bread EQU *
funcsize_rf_code_bread EQU funcend_rf_code_bread-_rf_code_bread

_rf_code_bwrit EXPORT
_rf_code_bwrit EQU *
	PULU   X,D
	LDA    $FF06
	ORA    #$01
	STA    $FF06
bwrit1 EQU *
	LDA    $FF05
	ANDA   #$08
	BEQ    bwrit1
	LDA    ,X+
	STA    $FF04
	DECB
	BNE    bwrit1
bwrit2 EQU *
	LDA    $FF05
	ANDA   #$08
	BEQ    bwrit2
	LDA    #$04
	STA    $FF04
	LDA    $FF06
	ANDA   #$01
	STA    $FF06
	LBRA   _rf_next
funcend_rf_code_bwrit EQU *
funcsize_rf_code_bwrit EQU funcend_rf_code_bwrit-_rf_code_bwrit

_rf_fin EXPORT
_rf_fin EQU *
	RTS
funcend_rf_fin EQU *
funcsize_rf_fin EQU funcend_rf_fin-_rf_fin

	ENDSECTION
