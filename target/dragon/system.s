        SECTION code

_rf_init_origin IMPORT
_rf_next IMPORT
_rf_up IMPORT

NEXT    EQU    _rf_next
UP      EQU    _rf_up

_rf_init EXPORT
_rf_init
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
init1   LBSR   _rf_init_origin
        RTS

_rf_code_emit EXPORT
_rf_code_emit
        PULU   D
        TFR    B,A
        ANDA   #$7F
        JSR    $B54A
        LDX    UP,PCR
        LDD    #1
        ADDD   26,X
        STD    26,X
        LBRA   NEXT

_rf_code_key EXPORT
_rf_code_key
        JSR    $B538
        ANDA   #$7F
        TFR    A,B
        CLRA
        PSHU   D
        LBRA   NEXT

_rf_code_qterm EXPORT
_rf_code_qterm
        LDD    #0
        PSHU   D
        JSR    $8006
        CMPA   #$03
        LBNE   NEXT
        INC    3,U
        LBRA   NEXT

_rf_code_cr EXPORT
_rf_code_cr
        LDA    #$0D
        JSR    $B54A
        LBRA   NEXT

_rf_code_dchar EXPORT
_rf_code_dchar
dchar1  LDB    $FF05
        ANDB   #$10
        BEQ    dchar1
        LDB    $FF04
        LDX    #$0000
        CMPB   1,U
        BNE    dchar2
        LEAX   1,X
dchar2  STX    ,U
        CLRA
        PSHU   D
        LBRA   NEXT

_rf_code_bread EXPORT
_rf_code_bread
        PULU   X
        LDB    #$80
bread1  LDA    $FF05
        ANDA   #$10
        BEQ    bread1
        LDA    $FF04
        STA    ,X+
        DECB
        BNE    bread1
        LBRA   NEXT

_rf_code_bwrit EXPORT
_rf_code_bwrit
        PULU   X,D
        LDA    $FF06
        ORA    #$01
        STA    $FF06
bwrit1  LDA    $FF05
        ANDA   #$08
        BEQ    bwrit1
        LDA    ,X+
        STA    $FF04
        DECB
        BNE    bwrit1
bwrit2  LDA    $FF05
        ANDA   #$08
        BEQ    bwrit2
        LDA    #$04
        STA    $FF04
        LDA    $FF06
        ANDA   #$01
        STA    $FF06
        LBRA   NEXT

_rf_fin EXPORT
_rf_fin RTS

        ENDSECTION
