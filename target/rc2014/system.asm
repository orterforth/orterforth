SECTION code_user

EXTERN _rf_next                 ; NEXT, when JP (IX) not available
EXTERN _rf_up                   ; UP, for incrementing OUT
EXTERN _rf_z80_hpush            ; HPUSH, when JP (IY) not available

PUBLIC _rf_init
PUBLIC _rf_fin

_rf_init:
_rf_fin:
        RET

PUBLIC _rf_code_emit

_rf_code_emit:
        POP     HL              ; get char
        LD      A,$7F           ; use low 7 bits
        AND     L
        CP      $08             ; BS erase
        JP      NZ,EMIT1
;       RST     $0008
        CALL    tx
        LD      A,$20
;       RST     $0008
        CALL    tx
        LD      A,$08
EMIT1: ;RST     $0008           ; output char
        CALL    tx
        LD      HL,(_rf_up)     ; increment OUT
        LD      DE,$001A
        ADD     HL,DE
        INC     (HL)
        JP      NZ,_rf_next
        INC     HL
        INC     (HL)
        JP      (IX)

PUBLIC _rf_code_key

_rf_code_key:
;       RST     $0010           ; expect bit 7 reset
        CALL    rx
        AND     A
        JP      M,_rf_code_key
        LD      H,$00
        AND     $7F
        CP      $0A             ; LF to CR
        JR      NZ,KEY1
        LD      A,$0D
KEY1:   LD      L,A             ; push
        JP      (IY)

PUBLIC _rf_code_cr

_rf_code_cr:
        LD      A,$0A           ; LF
;       RST     $0008
        CALL    tx
        JP      (IX)

PUBLIC _rf_code_qterm

_rf_code_qterm:
        LD      HL,$0000
;       RST     $0018           ; poll key
;       OR      A
        IN      A,($80)
        BIT     0,A
        JP      Z,_rf_z80_hpush ; no key pressed
;       RST     $0010           ; get key
        CALL    rx
        CP      $1B             ; ESC (Escape)
        JP      Z,qterm1
        CP      $03             ; ETX (Ctrl-C)
        JP      NZ,_rf_z80_hpush
qterm1: INC     L
        JP      (IY)

discr: ;RST     $0010           ; expect bit 7 set
        CALL    rx
        AND     A
        JP      P,discr
        AND     $7F             ; reset it
        RET

PUBLIC _rf_code_dchar

_rf_code_dchar:
        CALL    discr           ; read byte
        POP     HL              ; get expected byte
        CP      L               ; set flag if expected
        LD      HL,$0001
        JR      Z,dchar2
        DEC     L
dchar2: PUSH    HL              ; push flag
        LD      L,A             ; now push byte
        JP      (IY)

PUBLIC _rf_code_bread

_rf_code_bread:
        POP     HL              ; addr
        PUSH    BC              ; save IP
        LD      B,$80           ; loop for 128 bytes
bread1: CALL    discr           ; read a byte
        LD      (HL),A          ; write byte to addr
        CP      $04             ; see if EOT
        JR      Z,bread2        ; finish if so
        INC     HL              ; advance addr
        DJNZ    bread1          ; loop back for more bytes
bread2: POP     BC              ; restore IP
        JP      (IX)

PUBLIC _rf_code_bwrit

_rf_code_bwrit:
        POP     DE              ; len
        POP     HL              ; addr
        PUSH    BC              ; save IP
        LD      B,E             ; loop for len
bwrit1: LD      A,(HL)          ; read a byte from addr
        OR      $80             ; set bit 7
;       RST     $0008           ; write byte
        CALL    tx
        INC     HL              ; advance addr
        DJNZ    bwrit1          ; loop back for more bytes
        LD      A,$84           ; EOT + bit 7
;       RST     $0008           ; write byte
        CALL    tx
        POP     BC              ; restore IP
        JP      (IX)

tx:     LD      E,A
txbusy: IN      A,($80)
        BIT     1,A
        JR      Z,txbusy
        LD      A,E
        OUT     ($81),A
        RET

rx:     IN      A,($80)
        BIT     0,A
        JR      Z,rx
        IN      A,($81)
        RET
