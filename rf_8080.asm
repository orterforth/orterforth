; Modified for orterforth integration in 2024. In particular
; for 8085, undocumented opcodes are used and minor operational
; changes (DE not incremented to W+1) made accordingly.

SECTION code_user

PUBLIC _rf_start
_rf_start:
IFNDEF I8085
        DCX     D               ; DE to W
ENDIF
        MOV     L,E
        MOV     H,D
        SHLD    _rf_w
        MOV     L,C             ; BC to IP
        MOV     H,B
        SHLD    _rf_ip
        POP     D               ; return address
        LXI     H,0             ; SP to SP
        DAD     SP
        SHLD    _rf_sp
        LHLD    spsave
        SPHL
        XCHG                    ; return to C
        PCHL

PUBLIC _rf_trampoline
_rf_trampoline:
        LHLD    _rf_fp          ; if FP is null, return
        MOV     A,H
        ORA     L
        RZ
        LXI     D,_rf_trampoline ; to return to start
        PUSH    D
        XCHG                    ; FP
        LXI     H,0             ; SP to SP
        DAD     SP
        SHLD    spsave
        LHLD    _rf_sp
        SPHL
        PUSH    D               ; FP
        LHLD    _rf_ip          ; IP to BC
        MOV     B,H
        MOV     C,L
        LHLD    _rf_w           ; W to DE
        MOV     D,H
        MOV     E,L
IFNDEF I8085
        INX     D
ENDIF
        RET                     ; jump to FP, return to start

PUBLIC _rf_code_cl
_rf_code_cl:
        LXI     H,2
        JMP     HPUSH

PUBLIC _rf_code_cs
_rf_code_cs:
        POP     H
        DAD     H
        JMP     HPUSH

PUBLIC _rf_code_ln
DEFC _rf_code_ln = NEXT

PUBLIC _rf_code_mon
_rf_code_mon:
        LXI     H,0
        SHLD    _rf_fp
        CALL    _rf_start
        RET

SECTION data_user

PUBLIC _rf_fp
_rf_fp: DEFW    0

PUBLIC _rf_ip
_rf_ip: DEFW    0

PUBLIC _rf_sp
_rf_sp: DEFW    0

PUBLIC _rf_w
_rf_w:  DEFW    0

spsave: DEFW    0

;
;       FIG-FORTH  RELEASE 1.1  FOR THE 8080 PROCESSOR
;
;       ALL PUBLICATIONS OF THE FORTH INTEREST GROUP
;       ARE PUBLIC DOMAIN.  THEY MAY BE FURTHER
;       DISTRIBUTED BY THE INCLUSION OF THIS CREDIT
;       NOTICE:
;
;       THIS PUBLICATION HAS BEEN MADE AVAILABLE BY THE
;                    FORTH INTEREST GROUP
;                    P. O. BOX 1105
;                    SAN CARLOS, CA 94070
;
;       IMPLEMENTATION BY:
;               JOHN CASSADY
;               339 15TH STREET
;               OAKLAND,CA 94612
;               ON 790528
;       MODIFIED BY:
;               KIM HARRIS
;       ACKNOWLEDGEMENTS:
;               GEORGE FLAMMER
;               ROBT. D. VILLWOCK

;
;
;

ORIG    EQU     RF_ORIGIN

;------------------------------------------------------
;
;       FORTH REGISTERS
;
;       FORTH   8080    FORTH PRESERVATION RULES
;       -----   ----    ------------------------
;       IP      BC      SHOULD BE PRESERVED ACROSS
;                         FORTH WORDS
;       W       DE      SOMETIMES OUTPUT FROM NEXT
;                       MAY BE ALTERED BEFORE JMP'ING TO NEXT
;                       INPUT ONLY WHEN 'DPUSH' CALLED
;       SP      SP      SHOULD BE USED ONLY AS DATA STACK
;                         ACROSS FORTH WORDS
;                       MAY BE USED WITHIN FORTH WORDS
;                         IF RESTORED BEFORE 'NEXT'
;               HL      NEVER OUTPUT FROM NEXT
;                         INPUT ONLY WHEN 'HPUSH' CALLED
;
PUBLIC _rf_up
_rf_up:
UP:     DEFW    0       ; USER AREA POINTER
PUBLIC _rf_rp
_rf_rp:
RPP:    DEFW    0       ; RETURN STACK POINTER
;
;--------------------------------------------------------
;
;       COMMENT CONVENTIONS:
;
;       =       MEANS   "IS EQUAL TO"
;       <-      MEANS   ASSIGNMENT
;
;       NAME    =       ADDRESS OF NAME
;       (NAME)  =       CONTENTS AT NAME
;       ((NAME))=       INDIRECT CONTENTS
;       CFA     =       ADDRESS OF CODE FIELD
;       LFA     =       ADDRESS OF LINK FIELD
;       NFA     =       ADDR OF START OF NAME FIELD
;       PFA     =       ADDR OF START OF PARAMETER FIELD
;
;       S1      =       ADDR OF 1ST WORD OF PARAMETER STACK
;       S2      =       ADDR OF 2ND WORD OF PARAMETER STACK
;       R1      =       ADDR OF 1ST WORD OF RETURN STACK
;       R2      =       ADDR OF 2ND WORD OF RETURN STACK
;       ( ABOVE STACK POSITIONS VALID BEFORE & AFTER EXECUTION
;       OF ANY WORD, NOT DURING. )
;
;       LSB     =       LEAST SIGNIFICANT BIT
;       MSB     =       MOST SIGNIFICANT BIT
;       LB      =       LOW BYTE
;       HB      =       HIGH BYTE
;       LW      =       LOW WORD
;       HW      =       HIGH WORD
;       ( MAY BE USED AS SUFFIX TO ABOVE NAMES )
;

SECTION code_user

;
;--------------------------------------------------
;
;       NEXT, THE FORTH ADDRESS INTERPRETER
;         ( POST INCREMENTING VERSION )
;
DPUSH:  PUSH    D
HPUSH:  PUSH    H
PUBLIC _rf_next
_rf_next:
NEXT:   LDAX    B       ;(W) <- ((IP))
        INX     B       ;(IP) <- (IP)+2
IFDEF I8085
        MOV     E,A
        LDAX    B
        INX     B
        MOV     D,A
NEXT1:  LHLX
;       INX     D       ; only where needed
ELSE
        MOV     L,A
        LDAX    B
        INX     B
        MOV     H,A     ; (HL) <- CFA
NEXT1:  MOV     E,M     ;(PC) <- ((W))
        INX     H
        MOV     D,M
        XCHG
ENDIF
        PCHL            ; NOTE: (DE) = CFA+1
;

PUBLIC _rf_code_lit     ; LIT
_rf_code_lit:           ;(S1) <- ((IP))
        LDAX    B       ; (HL) <- ((IP)) = LITERAL
        INX     B       ; (IP) <- (IP) + 2
        MOV     L,A     ; LB
        LDAX    B       ; HB
        INX     B
        MOV     H,A
        JMP     HPUSH   ; (S1) <- (HL)
 ;

PUBLIC _rf_code_exec
_rf_code_exec:
IFDEF I8085
        POP     D
        LHLX
;       INX     D       ; only where needed
        PCHL
ELSE
        POP     H       ; HL <- (S1) = CFA
        JMP     NEXT1
ENDIF
;

PUBLIC _rf_code_bran
_rf_code_bran:          ;(IP) <- (IP) + ((IP))
IFDEF I8085
BRAN1:  MOV     D,B
        MOV     E,C
        LHLX
ELSE
BRAN1:  MOV     H,B     ; (HL) <- (IP)
        MOV     L,C
        MOV     E,M     ; (DE) <- ((IP)) = BRANCH OFFSET
        INX     H
        MOV     D,M
        DCX     H
ENDIF
        DAD     D       ; (HL) <- (HL) + ((IP))
        MOV     C,L     ; (IP) <- (HL)
        MOV     B,H
        JMP     NEXT
;

PUBLIC _rf_code_zbran
_rf_code_zbran:
        POP     H
        MOV     A,L
        ORA     H
        JZ      BRAN1   ; IF (S1)=0 THEN BRANCH
        INX     B       ; ELSE SKIP BRANCH OFFSET
        INX     B
        JMP     NEXT
;

PUBLIC _rf_code_xloop
_rf_code_xloop:
        LXI     D,1     ; (DE) <- INCREMENT
XLOO1:  LHLD    RPP     ; ((HL)) = INDEX
        MOV     A,M     ; INDEX <- INDEX + INCR
        ADD     E
        MOV     M,A
        MOV     E,A
        INX     H
        MOV     A,M
        ADC     D
        MOV     M,A
        INX     H       ; ((HL)) = LIMIT
        INR     D
        DCR     D
        MOV     D,A     ; (DE) <- NEW INDEX
        JM      XLOO2   ; IF INCR > 0
        MOV     A,E
        SUB     M       ; THEN (A) <- INDEX - LIMIT
        MOV     A,D
        INX     H
        SBB     M
        JMP     XLOO3
XLOO2:  MOV     A,M     ; ELSE (A) <- LIMIT - INDEX
        SUB     E
        INX     H
        MOV     A,M
        SBB     D
;                       ; IF (A) < 0
XLOO3:  JM      BRAN1   ; THEN LOOP AGAIN
        INX     H       ; ELSE DONE
        SHLD    RPP     ; DISCARD R1 & R2
        INX     B       ; SKIP BRANCH OFFSET
        INX     B
        JMP     NEXT
;

PUBLIC _rf_code_xploo
_rf_code_xploo:
        POP     D       ; (DE) <- INCR
        JMP     XLOO1
;

PUBLIC _rf_code_xdo
_rf_code_xdo:
        LHLD    RPP     ; (RP) <- (RP) - 4
        DCX     H
        DCX     H
        DCX     H
        DCX     H
        SHLD    RPP
IFDEF I8085
        XCHG
        POP     H
        SHLX
        INX     D
        INX     D
        POP     H
        SHLX
ELSE
        POP     D       ; (R1) <- (S1) = INIT INDEX
        MOV     M,E
        INX     H
        MOV     M,D
        POP     D       ; (R2) <- (S2) = LIMIT
        INX     H
        MOV     M,E
        INX     H
        MOV     M,D
ENDIF
        JMP     NEXT
;

PUBLIC _rf_code_rr
_rf_code_rr:            ;(S1) <- (R1) , (R1) UNCHANGED
        LHLD    RPP
IFDEF I8085
        XCHG
        LHLX
        JMP     HPUSH
ELSE
        MOV     E,M     ; (DE) <- (R1)
        INX     H
        MOV     D,M
        PUSH    D       ; (S1) <- (DE)
        JMP     NEXT
ENDIF
;

PUBLIC _rf_code_digit
_rf_code_digit:
        POP     H       ; (L) <- (S1)LB = ASCII CHR TO BE
;                        CONVERTED
        POP     D       ; (DE) <- (S2) = BASE VALUE
        MOV     A,E
        SUI     30H     ; IF CHR > "O"
        JM      DIGI2
        CPI     0AH     ; AND IF CHR > "9"
        JM      DIGI1
        SUI     7
        CPI     0AH     ; AND IF CHR >= "A"
        JM      DIGI2
;                       ; THEN VALID NUMERIC OR ALPHA CHR
DIGI1:  CMP     L       ; IF < BASE VALUE
        JP      P,DIGI2
;                       ; THEN VALID DIGIT CHR
        MOV     E,A     ; (S2) <- (DE) = CONVERTED DIGIT
        LXI     H,1     ; (S1) <- TRUE
        JMP     DPUSH
;                       ; ELSE INVALID DIGIT CHR
DIGI2:  MOV     L,H     ; (HL) <- FALSE
        JMP     HPUSH   ; (S1) <- FALSE

PUBLIC _rf_code_pfind
_rf_code_pfind:
        POP     D       ; (DE) <- NFA
PFIN1:  POP     H       ; (HL) <- STRING ADDR
        PUSH    H       ; SAVE STRING ADDR FOR NEXT ITERATION
        LDAX    D
        XRA     M       ; CHECK LENGTHS & SMUDGE BIT
        ANI     3FH
        JNZ     PFIN4   ; LENGTHS DIFFERENT
;                       ; LENGTHS MATCH, CHECK EACH CHR
PFIN2:  INX     H       ; (HL) <- ADDR NEXT CHR IN STRING
        INX     D       ; (DE) <- ADDR NEXT CHR IN NF
        LDAX    D
        XRA     M       ; IGNORE MSB
        ADD     A
        JNZ     PFIN3   ; NO MATCH
        JNC     PFIN2   ; MATCH SO FAR, LOOP AGAIN
        LXI     H,5     ; STRING MATCHES
        DAD     D       ; ((SP)) <- PFA
        XTHL
;                       ; BACK UP TO LENGTH BYTE OF NF = NFA
PFIN6:  DCX     D
        LDAX    D
        ORA     A
        JP      P,PFIN6 ; IF MSB = 1 THEN (DE) = NFA
        MOV     E,A     ; (DE) <- LENGTH BYTE
        MVI     D,0
        LXI     H,1     ; (HL) <- TRUE
        JMP     DPUSH  ; RETURN, NF FOUND
;       ABOVE NF NOT A MATCH, TRY ANOTHER
PFIN3:  JC      PFIN5   ; IF NOT END OF NF
PFIN4:  INX     D       ; THEN FIND END OF NF
        LDAX    D
        ORA     A
        JP      P,PFIN4
PFIN5:  INX     D       ; (DE) <- LFA
IFDEF I8085
        LHLX
        XCHG
ELSE
        XCHG
        MOV     E,M     ; (DE) <- (LFA)
        INX     H
        MOV     D,M
ENDIF
        MOV     A,D
        ORA     E       ; IF (LFA) <> 0
        JNZ     PFIN1   ; THEN TRY PREVIOUS DICT. DEF.
;                       ; ELSE END OF DICTIONARY
        POP     H       ; DISCARD STRING ADDR
        LXI     H,0     ; (HL) <- FALSE
        JMP     HPUSH   ; RETURN, NO MATCH FOUND
;

PUBLIC _rf_code_encl
_rf_code_encl:
        POP     D       ; (DE) <- (S1) = DELIMITER CHAR
        POP     H       ; (HL) <- (S2) = ADDR TEXT TO SCAN
        PUSH    H       ; (S4) <- ADDR
        MOV     A,E
        MOV     D,A     ; (D) <- DELIM CHAR
        MVI     E,-1    ; INITIALIZE CHR OFFSET COUNTER
        DCX     H       ; (HL) <- ADDR-1
;                       ; SKIP OVER LEADING DELIMITER CHRS
ENCL1:  INX     H
        INR     E
        CMP     M       ; IF TEXT CHR = DELIM CHR
        JZ      ENCL1   ; THEN LOOP AGAIN
;                       ; ELSE NON-DELIM CHR FOUND
        MVI     D,0     ; (S3) <- (E) = OFFSET TO 1ST NON-DELIM CHR
        PUSH    D
        MOV     D,A     ; (D) <- DELIM CHR
        MOV     A,M     ; IF 1ST NON-DELIM = NULL
        ANA     A
        JNZ     ENCL2
        MVI     D,0     ; THEN (S2) <- OFFSET TO BYTE
        INR     E       ;   FOLLOWING NULL
        PUSH    D
        DCR     E       ; (S1) <- OFFSET TO NULL
        PUSH    D
        JMP     NEXT
;                       ; ELSE TEXT CONTAINS NON-DELIM &
;                         NON-NULL CHR
ENCL2:  MOV     A,D     ; (A) <- DELIM CHR
        INX     H       ; (HL) <- ADDR NEXT CHR
        INR     E       ; (E) <- OFFSET TO NEXT CHR
        CMP     M       ; IF NEXT CHR <> DELIM CHR
        JZ      ENCL4
        MOV     A,M     ; AND IF NEXT CHR <> NULL
        ANA     A
        JNZ     ENCL2   ; THEN CONTINUE SCAN
;                       ; ELSE CHR = NULL
ENCL3:  MVI     D,0     ; (S2) <- OFFSET TO NULL
        PUSH    D
        PUSH    D       ; (S1) <- OFFSET TO NULL
        JMP     NEXT
;                       ; ELSE CHR = DELIM CHR
ENCL4:  MVI     D,0     ; (S2) <- OFFSET TO BYTE
;                         FOLLOWING TEXT
        PUSH    D
        INR     E       ; (S1) <- OFFSE TO 2 BYTES AFTER
;                           END OF WORD
        PUSH    D
        JMP     NEXT
;

PUBLIC _rf_code_cmove
_rf_code_cmove:
        MOV     L,C     ; (HL) <- (IP)
        MOV     H,B
        POP     B       ; (BC) <- (S1) = #CHRS
        POP     D       ; (DE) <- (S2) = DEST ADDR
        XTHL            ; (HL) <- (S3) = SOURCE ADDR
;                       ; (S1) <- (IP)
        JMP     CMOV2   ; RETURN IF #CHRS = 0
CMOV1:  MOV     A,M     ; ((DE)) <- ((HL))
        INX     H       ; INC SOURCE ADDR
        STAX    D
        INX     D       ; INC DEST ADDR
        DCX     B       ; DEC #CHRS
CMOV2:  MOV     A,B
        ORA     C
        JNZ     CMOV1   ; REPEAT IF #CHRS <> 0
        POP     B       ; RESTORE (IP) FROM (S1)
        JMP     NEXT

                        ; U*    16X16 UNSIGNED MULTIPLY
                        ; AVG EXECUTION TIME = 994 CYCLES
;

PUBLIC _rf_code_ustar
_rf_code_ustar:
        POP     D       ; (DE) <- MPLIER
        POP     H       ; (HL) <- MPCAND
        PUSH    B       ; SAVE IP
        MOV     B,H
        MOV     A,L     ; (BA) <- MPCAND
        CALL    MPYX    ; (AHL)1 <- MPCAND.LB * MPLIER
;                              1ST PARTIAL PRODUCT
        PUSH    H       ; SAVE (HL)1
        MOV     H,A
        MOV     A,B
        MOV     B,H     ; SAVE (A)1
        CALL    MPYX    ; (AHL)2 <- MPCAND.HL * MPLIER
;                              2ND PARTIAL PRODUCT
        POP     D       ; (DE) <- (HL)1
        MOV     C,D     ; (BC) <- (AH)1
;       FORM SUM OF PARTIALS:
;                          (AHL) 1
;                       + (AHL)  2
;                       --------
;                         (AHLE)
        DAD     B       ; (HL) <- (HL)2 + (AH)1
        ACI     0       ; (AHLE) <= (BA) * (DE)
        MOV     D,L
        MOV     L,H
        MOV     H,A     ; (HLDE) <- MPLIER * MPCAND
        POP     B       ; RESTORE IP
        PUSH    D       ; (S2) <- PRODUCT.LW
        JMP     HPUSH   ; (S1) <- PRODUCT.HW
;
;       MULTIPLY PRIMITIVE
;               (AHL) <- (A) * (DE)
;       #BITS =  24       8     16
MPYX:   LXI     H,0     ; (HL) <- 0 = PARTIAL PRODUCT.LW
        MVI     C,8     ; LOOP COUNTER
MPYX1:  DAD     H       ; LEFT SHIFT (AHL) 24 BITS
        RAL
        JNC     MPYX2   ; IF NEXT MPLIER BIT = 1
        DAD     D       ; THEN ADD MPCAND
        ACI     0
MPYX2:  DCR     C       ; IF NOT LAST MPLIER BIT
        JNZ     MPYX1   ; THEN LOOP AGAIN
        RET             ; ELSE DONE
;

PUBLIC _rf_code_uslas
_rf_code_uslas:
        LXI     H,4
        DAD     SP      ; ((HL)) <- NUMERATOR.LW
        MOV     E,M     ; (DE) <- NUMER.LW
        MOV     M,C     ; SAVE IP ON STACK
        INX     H
        MOV     D,M
        MOV     M,B
        POP     B       ; (BC) <- DENOMINATOR
        POP     H       ; (HL) <- NUMER.HW
        MOV     A,L
        SUB     C       ; IF NUMER >= DENOM
        MOV     A,H
        SBB     B
        JC      USLA1
        LXI     H,0FFFFH        ; THEN OVERFLOW
        LXI     D,0FFFFH        ; SET REM & QUOT TO MAX
        JMP     USLA7
USLA1:  MVI     A,16    ; LOOP COUNTER
USLA2:  DAD     H       ; LEFT SHIFT (HLDE) THRU CARRY
        RAL
        XCHG
        DAD     H
        JNC     USLA3
        INX     D
        ANA     A
USLA3:  XCHG            ; SHIFT DONE
        RAR             ; RESTORE 1ST CARRY
        PUSH    PSW     ; SAVE COUNTER
        JNC     USLA4   ; IF CARRY = 1
IFDEF I8085
        DSUB
ELSE
        MOV     A,L     ; THEN (HL) <- (HL) - (BC)
        SUB     C
        MOV     L,A
        MOV     A,H
        SBB     B
        MOV     H,A
ENDIF
        JMP     USLA5
IFDEF I8085
USLA4:  DSUB
ELSE
USLA4:  MOV     A,L     ; ELSE TRY (HL) <- (HL) - (BC)
        SUB     C
        MOV     L,A
        MOV     A,H
        SBB     B       ; (HL) <- PARTIAL REMAINDER
        MOV     H,A
ENDIF
        JNC     USLA5
        DAD     B       ; UNDERFLOW RESTORE
        DCX     D
USLA5:  INX     D       ; INC QUOT
USLA6:  POP     PSW     ; RESTORE COUNTER
        DCR     A       ; IF COUNTER > 0
        JNZ     USLA2   ; THEN LOOP AGAIN
USLA7:  POP     B       ; ELSE DONE, RESTORE IP
        PUSH    H       ; (S2) <- REMAINDER
        PUSH    D       ; (S1) <- QUOTIENT
        JMP     NEXT
;

PUBLIC _rf_code_andd
_rf_code_andd:          ; (S1) <- (S1) AND (S2)
        POP     D
        POP     H
        MOV     A,E
        ANA     L
        MOV     L,A
        MOV     A,D
        ANA     H
        MOV     H,A
        JMP     HPUSH
;

PUBLIC _rf_code_orr
_rf_code_orr:           ; (S1) <- (S1) OR (S2)
        POP     D
        POP     H
        MOV     A,E
        ORA     L
        MOV     L,A
        MOV     A,D
        ORA     H
        MOV     H,A
        JMP     HPUSH
;

PUBLIC _rf_code_xorr
_rf_code_xorr:
        POP     D       ; (S1) <- (S1) XOR (S2)
        POP     H
        MOV     A,E
        XRA     L
        MOV     L,A
        MOV     A,D
        XRA     H
        MOV     H,A
        JMP     HPUSH
;

PUBLIC _rf_code_spat
_rf_code_spat:          ;(S1) <- (SP)
IFDEF I8085
        LDSI    0
        PUSH    D
        JMP     NEXT
ELSE
        LXI     H,0
        DAD     SP      ; (HL) <- (SP)
        JMP     HPUSH   ; (S1) <- (HL)
ENDIF
;

PUBLIC _rf_code_spsto   ; STACK POINTER STORE
_rf_code_spsto:         ;(SP) <- (S0) ( USER VARIABLE )
        LHLD    UP      ; (HL) <- USER VAR BASE ADDR
IFDEF I8085
        LDHI    6
        LHLX
ELSE
        LXI     D,6
        DAD     D       ; (HL) <- S0
        MOV     E,M     ; (DE) <- (S0)
        INX     H
        MOV     D,M
        XCHG
ENDIF
        SPHL            ; (SP) <- (S0)
        JMP     NEXT
;

PUBLIC _rf_code_rpsto   ; RETURN STACK POINTER STORE
_rf_code_rpsto:         ;(RP) <- (R0) ( USER VARIABLE )
        LHLD    UP      ; (HL) <- USER VARIABLE BASE ADDR
IFDEF I8085
        LDHI    8
        LHLX
ELSE
        LXI     D,8
        DAD     D       ; (HL) <- R0
        MOV     E,M     ; (DE) <- (R0)
        INX     H
        MOV     D,M
        XCHG
ENDIF
        SHLD    RPP     ; (RP) <- (R0)
        JMP     NEXT
;
PUBLIC _rf_code_semis   ; ;S
_rf_code_semis:         ;(IP) <- (R1)
        LHLD    RPP
        MOV     C,M     ; (BC) <- (R1)
        INX     H
        MOV     B,M
        INX     H
        SHLD    RPP     ; (RP) <- (RP) + 2
        JMP     NEXT
;
PUBLIC _rf_code_leave
_rf_code_leave:         ;LIMIT <- INDEX
        LHLD    RPP
IFDEF I8085
        XCHG
        LHLX
        INX     D
        INX     D
        SHLX
ELSE
        MOV     E,M     ; (DE) <- (R1) = INDEX
        INX     H
        MOV     D,M
        INX     H
        MOV     M,E     ; (R2) <- (DE) = LIMIT
        INX     H
        MOV     M,D
ENDIF
        JMP     NEXT
;
PUBLIC _rf_code_tor     ; >R
_rf_code_tor:           ;(R1) <- (S1)
        POP     D       ; (DE) <- (S1)
        LHLD    RPP
        DCX     H       ; (RP) <- (RP) - 2
        DCX     H
        SHLD    RPP
IFDEF I8085
        XCHG
        SHLX
ELSE
        MOV     M,E     ; ((HL)) <- (DE)
        INX     H
        MOV     M,D
ENDIF
        JMP     NEXT
;
PUBLIC _rf_code_fromr   ; R>
_rf_code_fromr:         ;(S1) <- (R1)
        LHLD    RPP
        MOV     E,M     ; (DE) <- (R1)
        INX     H
        MOV     D,M
        INX     H
        SHLD    RPP     ; (RP) <- (RP) + 2
        PUSH    D       ; (S1) <- (DE)
        JMP     NEXT
;
PUBLIC _rf_code_zequ    ; 0=
_rf_code_zequ:
        POP     H       ; (HL) <- (S1)
        MOV     A,L
        ORA     H       ; IF (HL) = 0
        LXI     H,0     ; THEN (HL) = FALSE
;       JNZ     ZEQU1
;       INX     H       ; ELSE (HL) = TRUE
        JNZ     HPUSH
        INR     L
ZEQU1:  JMP     HPUSH   ; (S1) <- (HL)
;
PUBLIC _rf_code_zless   ; 0<
_rf_code_zless:
        POP     H       ; (HL) <- (S1)
        DAD     H       ; IF (HL) >= 0
        LXI     H,0     ; THEN (HL) <- FALSE
;       JNC     ZLES1
;       INX     H       ; ELSE (HL) <- TRUE
        JNC     HPUSH
        INR     L
ZLES1:  JMP     HPUSH   ; (S1) <- (HL)
;
PUBLIC _rf_code_plus    ; +
_rf_code_plus:          ;(S1) <- (S1) + (S2)
        POP     D
        POP     H
        DAD     D
        JMP     HPUSH
;
                        ; D+    (4-2)
                        ; XLW XHW  YLW YHW  ---  SLW SHW
                        ; S4  S3   S2  S1        S2  S1
PUBLIC _rf_code_dplus
_rf_code_dplus:
IFDEF I8085
        LDSI    6
        XCHG
ELSE
        LXI     H,6
        DAD     SP      ; ((HL)) = XLW
ENDIF
        MOV     E,M     ; (DE) = XLW
        MOV     M,C     ; SAVE IP ON STACK
        INX     H
        MOV     D,M
        MOV     M,B
        POP     B       ; (BC) <- YHW
        POP     H       ; (HL) <- YLW
        DAD     D
        XCHG            ; (DE) <- YLW + XLW = SUM.LW
        POP     H       ; (HL) <- XHW
        MOV     A,L
        ADC     C
        MOV     L,A     ; (HL) <- YHW + XHW + CARRY
        MOV     A,H
        ADC     B
        MOV     H,A
        POP     B       ; RESTORE IP
;       PUSH    D       ; (S2) <- SUM.LW
;       JMP     HPUSH   ; (S1) <- SUM.HW
        JMP     DPUSH
;

PUBLIC _rf_code_minus   ; MINUS
_rf_code_minus:         ; (S1) <- -(S1) ( 2'S COMPLEMENT )
        POP     H
        MOV     A,L
        CMA
        MOV     L,A
        MOV     A,H
        CMA
        MOV     H,A
        INX     H
        JMP     HPUSH
;

PUBLIC _rf_code_dminu   ; DMINUS
_rf_code_dminu:

        POP     H       ; (HL) <- HW
        POP     D       ; (DE) <- DW
        SUB     A
        SUB     E       ; (DE) <- 0 - (DE)
        MOV     E,A
        MVI     A,0
        SBB     D
        MOV     D,A
        MVI     A,0
        SBB     L       ; (HL) <- 0 - (HL)
        MOV     L,A
        MVI     A,0
        SBB     H
        MOV     H,A
;       PUSH    D       ; (S2) <- LW
;       JMP     HPUSH   ; (S1) <- HW
        JMP     DPUSH

PUBLIC _rf_code_over    ; OVER
_rf_code_over:
IFDEF I8085
        LDSI    2
        LHLX
        JMP     HPUSH
ELSE
        POP     D
        POP     H
        PUSH    H
        JMP     DPUSH
ENDIF
;

PUBLIC _rf_code_drop    ; DROP
_rf_code_drop:
        POP     H
        JMP     NEXT
;
PUBLIC _rf_code_swap    ; SWAP
_rf_code_swap:
        POP     H
        XTHL
        JMP     HPUSH
;
PUBLIC _rf_code_dup     ; DUP
_rf_code_dup:
        POP     H
        PUSH    H
        JMP     HPUSH
;
PUBLIC _rf_code_pstor   ; PLUS STORE
_rf_code_pstor:         ;((S1)) <- ((S1)) + (S2)
        POP     H       ; (HL) <- (S1) = ADDR
        POP     D       ; (DE) <- (S2) = INCR
        MOV     A,M     ; ((HL)) <- ((HL)) + DE
        ADD     E
        MOV     M,A
        INX     H
        MOV     A,M
        ADC     D
        MOV     M,A
        JMP     NEXT
;
PUBLIC _rf_code_toggl   ; TOGGLE
_rf_code_toggl:         ;((S2)) <- ((S2)) XOR (S1)LB
        POP     D       ; (E) <- BYTE MASK
        POP     H       ; (HL) <- ADDR
        MOV     A,M
        XRA     E
        MOV     M,A     ; (ADDR) <- (ADDR) XOR (E)
        JMP     NEXT
;
PUBLIC _rf_code_at      ; @
_rf_code_at:            ;(S1) <- ((S1))
IFDEF I8085
        POP     D
        LHLX
        JMP     HPUSH
ELSE
        POP     H       ; (HL) <- ADDR
        MOV     E,M     ; (DE) <- (ADDR)
        INX     H
        MOV     D,M
        PUSH    D       ; (S1) <- (DE)
        JMP     NEXT
ENDIF
;
PUBLIC _rf_code_cat     ; C@
_rf_code_cat:           ;(S1) <- ((S1))LB
        POP     H       ; (HL) <- ADDR
        MOV     L,M     ; (HL) <- (ADDR)LB
        MVI     H,0
        JMP     HPUSH
;

PUBLIC _rf_code_store   ; STORE
_rf_code_store:         ;((S1)) <- (S2)
IFDEF I8085
        POP     D
        POP     H
        SHLX
ELSE
        POP     H       ; (HL) <- (S1) = ADDR
        POP     D       ; (DE) <- (S2) = VALUE
        MOV     M,E     ; ((HL)) <- (DE)
        INX     H
        MOV     M,D
ENDIF
        JMP     NEXT
;
PUBLIC _rf_code_cstor   ; C STORE
_rf_code_cstor:         ;((S1))LB <- (S2)LB
        POP     H       ; (HL) <- (S1) = ADDR
        POP     D       ; (DE) <- (S2) = BYTE
        MOV     M,E     ; ((HL))LB <- (E)
        JMP     NEXT
;

PUBLIC _rf_code_docol   ; :
_rf_code_docol:
DOCOL:  LHLD    RPP
        DCX     H       ; (R1) <- (IP)
        MOV     M,B
        DCX     H       ; (RP) <- (RP) - 2
        MOV     M,C
        SHLD    RPP
IFDEF I8085
        INX     D
ENDIF
        INX     D       ; (DE) <- CFA+2 = (W)
        MOV     C,E     ; (IP) <- (DE) = (W)
        MOV     B,D
        JMP     NEXT
;

PUBLIC _rf_code_docon   ; CONSTANT
_rf_code_docon:
DOCON:  INX     D       ; (DE) <- PFA
IFDEF   I8085
        INX     D
        LHLX
        JMP     HPUSH
ELSE
        XCHG
        MOV     E,M     ; (DE) <- (PFA)
        INX     H
        MOV     D,M
        PUSH    D       ; (S1) <- (PFA)
        JMP     NEXT
ENDIF
;
PUBLIC _rf_code_dovar   ; VARIABLE
_rf_code_dovar:
DOVAR:  INX     D       ; (DE) <- PFA
IFDEF I8085
        INX     D
ENDIF
        PUSH    D       ; (S1) <- PFA
        JMP     NEXT
;
PUBLIC _rf_code_douse   ; USER
_rf_code_douse:
DOUSE:  INX     D       ; (DE) <- PFA
IFDEF I8085
        INX     D
        LHLX
        XCHG
ELSE
        XCHG
        MOV     E,M     ; (DE) <- USER VARIABLE OFFSET
        MVI     D,0
ENDIF
        LHLD    UP      ; (HL) <- USER VARIABLE BASE ADDR
        DAD     D       ; (HL) <- (HL) + (DE)
        JMP     HPUSH   ; (S1) <- BASE + OFFSET
;

PUBLIC _rf_code_dodoe   ; DOES>
_rf_code_dodoe:
DODOE:  LHLD    RPP     ; (HL) <- (RP)
        DCX     H
        MOV     M,B     ; (R1) <- (IP) = PFA = (SUBSTITUTE CFA)
        DCX     H
        MOV     M,C
        SHLD    RPP     ; (RP) <- (RP) - 2
IFDEF I8085
        INX     D
ENDIF
        INX     D       ; (DE) <- PFA = (SUBSTITUTE CFA)
        XCHG
        MOV     C,M     ; (IP) <- (SUBSTITUTE CFA)
        INX     H
        MOV     B,M
        INX     H
        JMP     HPUSH   ; (S1) <- PFA+2 = SUBSTITUTE PFA
;

PUBLIC _rf_code_cold    ; COLD
_rf_code_cold:
IFDEF I8085
        LHLD    ORIG+2AH        ; init FORTH
        XCHG
        LHLD    ORIG+0CH
        SHLX
ELSE
        LHLD    ORIG+0CH        ; init FORTH
        XCHG
        LHLD    ORIG+2AH
        MOV     M,E
        INX     H
        MOV     M,D
ENDIF
        LHLD    ORIG+10H        ; init UP
        SHLD    UP
        XCHG                    ; init USER vars
        LXI     H,ORIG+0CH
        MVI     B,16H
COLD1:  MOV     A,M
        INX     H
        STAX    D
        INX     D
        DCR     B
        JNZ     COLD1
        LHLD    ORIG+2CH        ; init IP (ABORT)
        MOV     B,H
        MOV     C,L
        JMP     _rf_code_rpsto  ; init RP
;
PUBLIC _rf_code_stod    ; S->D
_rf_code_stod:
        POP     D
        LXI     H,0
        MOV     A,D
        ANI     80H
;       JZ      STOD1
        JZ      DPUSH
        DCX     H
STOD1:  JMP     DPUSH
;
