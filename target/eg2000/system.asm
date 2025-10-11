INCH    EQU     002BH
OUTCH   EQU     0033H
INCHW   EQU     0049H
DELAY   EQU     0060H

;BDHALF  EQU     140 ; (85251.5/ 300 - 4.846) / 2
BDHALF  EQU      69 ; (85251.5/ 600 - 4.846) / 2
;BDHALF  EQU      33 ; (85251.5/1200 - 4.846) / 2
;BDHALF  EQU      15 ; (85251.5/2400 - 4.846) / 2
BDRATE  EQU     BDHALF+BDHALF

PUBLIC _rf_init
_rf_init:
        LD      A,(431CH)       ; set TXD inactive
        OR      02H
        LD      (431CH),A
        OUT     (0FFH),A
PUBLIC _rf_fin
_rf_fin:
        RET

PUBLIC _rf_console_get
_rf_console_get:
        LD      A,0EH           ; show cursor
        CALL    OUTCH
        CALL    INCHW           ; get key
        PUSH    AF
        LD      A,0FH           ; hide cursor
        CALL    OUTCH
        POP     AF              ; return key
        LD      L,A
        RET

PUBLIC _rf_console_put
_rf_console_put:
        LD      A,L
        JP      OUTCH

PUBLIC _rf_console_cr
_rf_console_cr:
        LD      A,0DH
        JP      OUTCH

PUBLIC _rf_console_qterm
_rf_console_qterm:
        CALL    INCH
        CP      01H             ; break
        LD      HL,0000H
        RET     NZ
        INC     L               ; return 1 if true
        RET

PUBLIC _rf_serial_put
_rf_serial_put:
;TXBYTE: PUSH    BC             ; Save registers on stack.
;       PUSH    DE
;       LD      E,A             ; Save byte to send in E.
        LD      E,L             ;+

        LD      A,(431CH)       ; Get control port value from image
        AND     0FDH            ;  in RAM, and zero TXD bit.
        LD      C,A             ; Save this in C reg.

        LD      D,1             ; Put stop bit into D reg.
        SLA     E               ; Carry top bit from E into D.
        RL      D               ; Now DE holds 10 bits to send,
                                ;  with data, start and stop bits.

        LD      B,10            ; Set bit counter.
SLOOP:  XOR     A               ; Clear A
        SRA     D               ;  and shift lsb out of DE
        RR      E               ;  into carry flag.
        ADC     A,0             ; Put carry flag into A
        SLA     A               ;  in bit 1.
        OR      C               ; Set up control port value
        OUT     (0FFH),A        ;  and output.
        PUSH    BC
        LD      BC,BDRATE       ; Wait for one bit period
        CALL    DELAY           ;  using ROM delay routine.
        POP     BC
        DJNZ    SLOOP           ; Loop for all 10 bits.
;       POP     DE              ; Restore registers
;       POP     BC
        RET                     ;  and return.

PUBLIC _rf_serial_get
_rf_serial_get:
;RXBYTE: PUSH    BC             ; Save registers on stack
;       PUSH    DE

STLOOP: IN      A,(0FFH)        ; Wait for start bit:
        AND     2               ;   Mask RXD bit from port
        JR      NZ,STLOOP       ;   Loop until zero.

        LD      BC,BDHALF       ;+ wait half bit period
        CALL    DELAY           ;+

        LD      B,8             ; Set counter for bits

RDLOOP: PUSH    BC              ; Wait one bit period for next bit
        LD      BC,BDRATE
        CALL    DELAY           ; Use ROM delay routine
        POP     BC              ; Restore reg

        IN      A,(0FFH)        ; Read control port data
        RRA                     ; Rotate RXD bit into carry flag
        RRA
;       RR      E               ;  and rotate this into E reg.
        RR      L               ;+
        DJNZ    RDLOOP          ; Now go and get next bit.

SPLOOP: IN      A,(0FFH)        ;+ wait for stop bit
        AND     2               ;+
        JR      Z,SPLOOP        ;+

;RXDONE: LD      A,E            ; Put received char into A.
;       POP     DE              ; Restore register contents
;       POP     BC
        RET                     ;  and return.
