; ZX Spectrum 48K system integration - Z80 assembly, based on ROM routines

SECTION code_user

EXTERN _rf_next                 ; NEXT, when jp (ix) not available
EXTERN _rf_up                   ; UP, for incrementing OUT
EXTERN _rf_z80_hpush            ; HPUSH, for restoring into iy

PUBLIC _rf_init

_rf_init:
IFDEF USEIY
        DI                      ; use of IY means we need interrupts disabled
;       PUSH    IY
;       LD      IY,5C3AH
ENDIF
        LD      HL,5C6BH        ; DF-SZ
        LD      (HL),0          ; use all 24 rows on screen
        CALL    0DAFH           ; CL_ALL clear screen
;       LD      HL,01BEH        ; 300 baud
;       LD      HL,006EH        ; 1200 baud
        LD      HL,000CH        ; 9600 baud
;       LD      HL,0005H        ; 19200 baud
        LD      (5CC3H),HL      ; BAUD
        RST     8H              ; create Interface 1 system vars
        DEFB    31H
        LD      HL,5CC6H        ; IOBORD
        LD      (HL),6          ; yellow, less disturbing than black
IFDEF USEIY
;       POP     IY
ENDIF
        RET                     ; return to C

PUBLIC _rf_code_emit            ;EMIT

_rf_code_emit:
        POP     HL              ; get character
        LD      A,7FH           ; reset scroll
        LD      (5C8CH),A       ; SCR-CT
        AND     L               ; use low 7 bits
IFDEF USEIY
        LD      IY,5C3AH
ENDIF
        RST     10H             ; PRINT_A_1
IFDEF USEIY
        LD      IY,_rf_z80_hpush
ENDIF
        LD      HL,(_rf_up)     ; increment OUT
        LD      DE,1AH
        ADD     HL,DE
        INC     (HL)
        JP      NZ,_rf_next
        INC     HL
        INC     (HL)            ; 11t = 38t max
        JP      (IX)            ; next

PUBLIC _rf_code_key             ;KEY

_rf_code_key:
        PUSH    BC              ; save IP
IFDEF USEIY
        LD      IY,5C3AH
ENDIF
key0:   LD      A,(cursor)      ; get cursor value 'L' or 'C'
        LD      E,A             ; save for later test
        CALL    18C1H           ; OUT_FLASH show cursor
        LD      A,8             ; back up one
        RST     10H             ; PRINT_A_1
        XOR     A               ; set LAST-K to 0
        LD      (5C08H),A
IFDEF USEIY
        EI                      ; enable interrupts to scan keyboard
ENDIF
key1:   HALT                    ; wait for interrupt
        LD      A,(5C08H)       ; loop until LAST-K set
        AND     A
        JR      Z,key1
        CP      06H             ; caps lock? (caps shift + 2)
        JR      NZ,key2
        LD      A,E
        XOR     0FH             ; change 'L' to 'C' or vice versa
        LD      (cursor),A
        JR      key0            ; show changed cursor and scan again
key2:   BIT     1,E             ; test caps lock
        JR      Z,key3
        CP      61H             ; 'a'
        JR      C,key3
        CP      7BH             ; 'z' + 1
        JR      NC,key3
        AND     5FH             ; make upper case
        JR      key10
key3:   LD      HL,key11        ; chars normally from extended mode
        LD      B,7
key4:   CP      (HL)            ; read the original code
        INC     HL
        JR      Z,key6          ; found a mapping
        INC     HL      
        DJNZ    key4
        JR      key10           ; found no mapping
key6:   LD      A,(HL)          ; read the mapped code
key10:  AND     7FH             ; now we have the code
        LD      H,0
        LD      L,A
        PUSH    HL              ; make key click
        LD      D,0
        LD      E,(IY-1)        ; PIP
        LD      HL,00C8H
        PUSH    IX
        CALL    03B5H           ; BEEPER
        POP     IX
        POP     HL
        LD      A,20H           ; blank out cursor
        RST     10H             ; PRINT_A_1
        LD      A,08H           ; back up
        RST     10H             ; PRINT_A_1
IFDEF USEIY
        DI                      ; restore regs IP, hpush
        LD      IY,_rf_z80_hpush
ENDIF
        POP     BC
IFDEF USEIY
        JP      (IY)
ELSE
        PUSH    HL
        JP      (IX)
ENDIF

key11:  DEFB    0C6H            ; AND (symbol shift + Y)
        DEFB    5BH             ; [
        DEFB    0C5H            ; OR (symbol shift + U)
        DEFB    5DH             ; ]
        DEFB    0E2H            ; STOP (symbol shift + A)
        DEFB    7EH             ; ~
        DEFB    0C3H            ; NOT (symbol shift + S)
        DEFB    7CH             ; |
        DEFB    0CDH            ; STEP (symbol shift + D)
        DEFB    5CH             ; \
        DEFB    0CCH            ; TO (symbol shift + F)
        DEFB    7BH             ; {
        DEFB    0CBH            ; THEN (symbol shift + G)
        DEFB    7DH             ; }

PUBLIC _rf_code_cr              ;CR

_rf_code_cr:
        LD      A,0DH           ; CR
        LD      (5C8CH),A       ; reset SCR-CT
IFDEF USEIY
        LD      IY,5C3AH
ENDIF
        RST     10H             ; PRINT_A_1
IFDEF USEIY
        LD      IY,_rf_z80_hpush
ENDIF
        JP      (IX)            ; next

PUBLIC _rf_code_qterm           ;?TERMINAL

_rf_code_qterm:
        LD      HL,0
        CALL    1F54H           ; BREAK-KEY
        JP      C,_rf_z80_hpush ; push 0 if not pressed
        INC     HL              ; push 1 if pressed
IFDEF USEIY
        JP      (IY)
ELSE
        PUSH    HL
        JP      (IX)
ENDIF

PUBLIC _rf_code_bwrit           ;BLOCK-WRITE

_rf_code_bwrit:
        POP     DE              ; len
        POP     HL              ; addr
        PUSH    BC              ; save IP
IFDEF USEIY
        LD      IY,5C3AH
ENDIF
bwrit1: PUSH    DE              ; save len
        PUSH    HL              ; save addr
        LD      A,(HL)          ; read a byte from addr
        RST     08H             ; BCHAN-OUT
        DEFB    1EH
        POP     HL              ; restore addr
        POP     DE              ; restore len
        INC     HL              ; advance addr
        DEC     E               ; advance len
        JP      NZ,bwrit1       ; loop back for more bytes
        LD      A,04H           ; EOT
        RST     08H             ; BCHAN-OUT
        DEFB    1EH
IFDEF USEIY
        LD      IY,_rf_z80_hpush ; restore HPUSH
ENDIF
        POP     BC              ; restore IP
        JP      (IX)

discread:
        PUSH    BC              ; save IP
IFDEF USEIY
        LD      IY,5C3AH        ; restore Spectrum IY
ENDIF
discread1:
        RST     08H             ; BCHAN-IN
        DEFB    1DH
        JR      NC,discread1    ; loop back until byte available
IFDEF USEIY
        LD      IY,_rf_z80_hpush ; restore HPUSH
ENDIF
        POP     BC              ; restore IP
        RET                     ; with byte in A

PUBLIC _rf_code_dchar           ;D/CHAR

_rf_code_dchar:
        CALL    discread        ; read byte
        POP     HL              ; get expected byte
        CP      L               ; set flag if expected
        LD      HL,1
        JR      Z,dchar2
        DEC     L
dchar2: PUSH    HL              ; push flag
        LD      L,A             ; now push byte
IFDEF USEIY
        JP      (IY)
ELSE
        PUSH    HL
        JP      (IX)
ENDIF

PUBLIC _rf_code_bread           ;BLOCK-READ

_rf_code_bread:
        POP     HL
        PUSH    BC
        LD      B,80H
bread1: PUSH    HL
        CALL    discread
        POP     HL
        LD      (HL),A
        INC     HL
        DJNZ    bread1
        POP     BC
        JP      (IX)

PUBLIC _rf_fin

_rf_fin:
        LD      HL,5C6BH        ; DF-SZ
        LD      (HL),2          ; restore lower screen area for BASIC
IFDEF USEIY
        EI                      ; re-enable interrupts
ENDIF
        RET                     ; return to C

SECTION data_user

cursor: DEFB    43H             ; 'C'
