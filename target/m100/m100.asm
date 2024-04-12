SECTION data_user

serb:   DEFB    0               ; buffer write index
sera:   DEFB    0               ; buffer read index

SECTION code_user

PUBLIC _rf_init
_rf_init:
        MVI     A,$25           ; RS232 not modem
        OUT     $BA
        MVI     A,28            ; 8N1
        OUT     $D8
        MVI     A,64            ; 9600 baud
        OUT     $BD
        MVI     A,16
        OUT     $BC
        MVI     A,$C3
        OUT     $B8
        LXI     H,serint        ; redirect interrupts
        SHLD    $F5FD
        LXI     H,$F5FC
        MVI     M,$C3
        RET

PUBLIC _rf_console_get
_rf_console_get:
        CALL    $12CB           ; KYREAD
        MOV     L,A
        RET

PUBLIC _rf_console_put
_rf_console_put:
        MOV     A,L
        JP      $4B44           ; CHROUT

PUBLIC _rf_console_qterm
_rf_console_qterm:
        CALL    $729F
        LXI     H,0
        RNZ
        INR     L
        RET

PUBLIC _rf_console_cr
_rf_console_cr:
        MVI     A,$0D           ; CR
        CALL    $4B44           ; CHROUT
        MVI     A,$0A           ; LF
        JP      $4B44           ; CHROUT

                                ; serial interrupt handler 6.5

serint: XTHL                    ; discard return addr
        PUSH    D               ; and save regs
        PUSH    PSW

        LHLD    serb            ; fetch both idxs
        MOV     D,H
        MOV     E,L

        LXI     H,$FF46         ; get write ptr
        MOV     A,E
        ADD     L
        MOV     L,A

        IN      $C8             ; get and write byte
        MOV     M,A

        INR     E               ; increment write idx
        MOV     A,E
        ANI     $3F
        STA     serb
   
        SUB     D               ; get buffer size
        ANI     $3F
        CPI     $28             ; if high water, deassert RTS
    	JC      serin1
        IN      $BA
        ORI     $80
        OUT     $BA

serin1: POP     PSW             ; restore regs
        POP     D
        POP     H

        EI                      ; int handler finished
        RET

PUBLIC _rf_serial_get
_rf_serial_get:
        LHLD    serb            ; fetch both idxs
        MOV     A,L             ; get buffer size
        MOV     E,H
        SUB     E
        ANI     $3F
        JZ      _rf_serial_get  ; if empty, wait

        CPI     $0A             ; if low water, assert RTS
        JNC     get1
        IN      $BA
        ANI     $7F
        OUT     $BA

get1:   LXI     H,$FF46         ; get read ptr
        MOV     A,E
        ADD     L
        MOV     L,A
        MOV     D,M             ; read byte

        INR     E               ; increment read idx
        MOV     A,E
        ANI     $3F
        STA     sera
    
        MOV     L,D             ; return byte
        RET

PUBLIC _rf_serial_put
_rf_serial_put:
        IN      $D8             ; wait for ready
        ANI     $10
        JZ      _rf_serial_put

put1:   IN      $BB             ; wait for CTS
        CMA
        ANI     $10
        JZ      put1

        MOV     A,L             ; write byte
        OUT     $C8
        RET

PUBLIC _rf_fin
_rf_fin:
        LXI     H,$F5FC         ; restore interrupt vector
        MVI     M,$C9
        INX     H
        MVI     M,$00
        INX     H
        MVI     M,$00
        RET
