; Modified for orterforth integration in 2021

SECTION code_user

; orterforth interop with C code definitions

PUBLIC _rf_start
_rf_start:                      ; C code calls this to switch from registers to C variables
        POP     HL              ; C return address
IFDEF USEIY
IFDEF SPECTRUM
        LD      IY,5C3AH        ; restore IY (ZX Spectrum)
ENDIF
ENDIF
        LD      (_rf_sp),SP     ; SP to SP
        LD      SP,(spsave)
        DEC     DE              ; DE to W
        LD      (_rf_w),DE
        LD      (_rf_ip),BC     ; BC to IP
        JP      (HL)            ; return to C

PUBLIC _rf_trampoline
_rf_trampoline:                 ; C code calls this to iterate over function pointers - assumes a switch into assembler
        LD      HL,(_rf_fp)     ; returns if FP is null
        LD      A,H
        OR      L
        RET     Z
        LD      DE,_rf_trampoline ; fp will return to this address
        PUSH    DE
        LD      BC,(_rf_ip)     ; IP to BC
        LD      DE,(_rf_w)      ; W to DE
        INC     DE
        LD      (spsave),SP     ; SP to SP
        LD      SP,(_rf_sp)
        LD      IX,NEXT         ; set IX
IFDEF USEIY
        LD      IY,HPUSH        ; set IY
ENDIF
        JP      (HL)            ; jump to FP, will return to start of trampoline

PUBLIC _rf_code_cl              ;cl
_rf_code_cl:
        LD      HL,2
IFDEF USEIY
        JP      (IY)
ELSE
        PUSH    HL
        JP      (IX)
ENDIF

PUBLIC _rf_code_cs              ;cs
_rf_code_cs:
        POP     HL
        ADD     HL,HL
IFDEF USEIY
        JP      (IY)
ELSE
        PUSH    HL
        JP      (IX)
ENDIF

PUBLIC _rf_code_ln              ;ln
DEFC _rf_code_ln = _rf_next

PUBLIC _rf_code_mon             ;MON
_rf_code_mon:
        LD      HL,0
        LD      (_rf_fp),HL
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

SECTION code_user

; Modified frm FIG document keyed by Dennis L. Wilson 800907
; Converted frm "8080 FIG-FORTH VERSION A0 15SEP79"
;
; fig-FORTH release 1.1 for the 8080 processor.
;
; ALL PUBLICATIONS OF THE FORTH INTEREST GROUP
; ARE PUBLIC DOMAIN. THEY MAY BE FURTHER
; DISTRIBUTED BY THE INCLUSION OF THIS CREDIT NOTICE:
;
; This publication has been made available by the
; Forth Interest Group
;	P.O.Box 1105
;	San Carlos, CA 94070
;	U.S.A.
;
; Implementation on 8080 by:
;	John Cassady
;	339 15th Street
;	Oakland, CA 94612
;	U.S.A
;	on 790528
; Modified by:
;	Kim Harris
; Acknowledgements:
;	George Flammer
;	Robt. D. Villwock
; ----------------------------------------------------------------------
; Z80 Version for Cromemco CDOS & Digital Research CP/M by:
;	Dennis Lee Wilson c/o
;	Aristotelian Logicians
;	2631 East Pinchot Avenue
;	Phoenix, AZ 85016
;	U.S.A.
; ----------------------------------------------------------------------
; The 2 byte Z80 code for Jump Relative (JR) has been substituted for
; the 3 byte Jump (JP) wherever practical. The port I/O words P@ & P!
; have been made ROMable by use of Z80 instructions.
; ----------------------------------------------------------------------
; Further modifications (marked ;/) by:
;	Edmund Ramm
;	Anderheitsallee 24
;	2000 Hamburg 71
;	Fed. Rep. of Germany	840418
; ----------------------------------------------------------------------

ORIG    EQU     RF_ORIGIN

UPINIT  EQU     ORIG+10H

; REGISTERS
;
; FORTH Z80 FORTH PRESERVATION RULES
; ----- --- -----------------------
; IP    BC  should be preserved
;           accross FORTH words.
; W     DE  sometimes output from
;           NEXT, may be altered
;           b4 JP'ing to NEXT,
;           input only when 
;           "DPUSH" called.
; SP    SP  should be used only as
;           Data Stack accross
;           FORTH words, may be
;           used within FORTH
;           words if restored
;           b4 "NEXT"
; HL        Never output frm NEXT
;           input only when
;           "HPUSH" called
;
;
SECTION data_user
PUBLIC _rf_up
_rf_up:
UP:     DEFW    0               ;/ USER AREA PTR
PUBLIC _rf_rp
_rf_rp:
RPP:    DEFW    0               ;/ RETURN STACK PTR
SECTION code_user
;
;
;       COMMENT CONVENTIONS:
;
;       =       MEANS "IS EQUAL TO"
;       <--     MEANS ASSIGNMENT
;       NAME    =     ADDR OF NAME
;       (NAME)  =     CONTENTS @ NAME
;       ((NAME))=     INDIRECT CONTENTS
;       CFA     =     CODE FIELD ADDR
;       LFA     =     LINK FIELD ADDR
;       NFA     =     NAME FIELD ADDR
;       PFA     =     PARAMETER FIELD ADDR
;       S1      =     ADDR OF 1st WORD OF PARAMETER STACK
;       S2      =     -"-  OF 2nd -"-  OF    -"-     -"-
;       R1      =     -"-  OF 1st -"-  OF RETURN STACK
;       R2      =     -"-  OF 2nd -"-  OF  -"-    -"-
; ( above Stack posn. valid b4 & after execution of any word, not during)
;
;       LSB     =     LEAST SIGNIFICANT BIT
;       MSB     =     MOST  SIGNIFICANT BIT
;       LB      =     LOW  BYTE
;       HB      =     HIGH BYTE
;       LW      =     LOW  WORD
;       HW      =     HIGH WORD
; (May be used as suffix to above names)
;       FORTH ADDRESS INTERPRETER
;       POST INCREMENTING VERSION
;
PUBLIC _rf_z80_dpush
_rf_z80_dpush:
DPUSH:  PUSH    DE
PUBLIC _rf_z80_hpush
_rf_z80_hpush:
HPUSH:  PUSH    HL              ;               IY points here
PUBLIC _rf_next
_rf_next:
NEXT:   LD      A,(BC)          ;(W)<--((IP))   IX points here
        LD      L,A
        INC     BC              ;INC IP
        LD      A,(BC)
        LD      H,A             ;(HL)<--CFA
        INC     BC
NEXT1:  LD      E,(HL)          ;(PC)<--((W))
        INC     HL
        LD      D,(HL)
        EX      DE,HL
        JP      (HL)            ;NOTE: (DE)=CFA+1
;

;       FORTH DICTIONARY
;       DICTIONARY FORMAT:
;
;                               BYTE
;       ADDRESS NAME            CONTENTS
;       ------- ----            --------
;                                               (MSB=1
;                                               (P=PRECEDENCE BIT
;                                               (S=SMUDGE BIT
;       NFA     NAME FIELD      1PS<LEN>        <NAME LENGTH
;                               0<1CHAR>        MSB=0, NAME'S 1st CHAR
;                               0<2CHAR>
;                                 ...
;                               1<LCHAR>        MSB=1, NAME'S LAST CHAR
;       LFA     LINK FIELD      <LINKLB>        =PREVIOUS WORD'S NFA
;                               <LINKHB>
;LABEL: CFA     CODE FIELD      <CODELB>        =ADDR CPU CODE
;                               <CODEHB>
;        PFA    PARAMETER       <1PARAM>        1st PARAMETER BYTE
;               FIELD           <2PARAM>
;                                 ...
;
;
;
PUBLIC _rf_code_lit             ;LIT
                                ;(LFA)=0 MARKS END OF DICTIONARY
_rf_code_lit:                   ;(S1)<--((IP))
        LD      A,(BC)          ;(HL)<--((IP))=LITERAL
        INC     BC              ;(IP)<--(IP)+2
        LD      L,A             ;LB
        LD      A,(BC)          ;HB
        INC     BC
        LD      H,A
IFDEF USEIY
        JP      (IY)            ;(S1)<--(HL)
ELSE
        PUSH    HL
        JP      (IX)
ENDIF
;
PUBLIC _rf_code_exec            ;EXECUTE
_rf_code_exec:
        POP     HL
        JP      NEXT1
;
PUBLIC _rf_code_bran            ;BRANCH
                                ;(IP)<--(IP)+((IP))
_rf_code_bran:
BRAN1:  LD      H,B             ;(HL)<--(IP)
        LD      L,C
        LD      E,(HL)          ;(DE)<--((IP))=BRANCH OFFSET
        INC     HL
        LD      D,(HL)
        DEC     HL
        ADD     HL,DE           ;(HL)<--(HL)+((IP))
        LD      C,L             ;(IP)<--(HL)
        LD      B,H
        JP      (IX)
;
PUBLIC _rf_code_zbran           ;0BRANCH
_rf_code_zbran:
        POP     HL
        LD      A,L
        OR      H
        JR      Z,BRAN1         ;IF (S1)=0 THEN BRANCH
        INC     BC              ;ELSE SKIP BRANCH OFFSET
        INC     BC
        JP      (IX)
;
PUBLIC _rf_code_xloop           ;(LOOP)
_rf_code_xloop:
        LD      HL,(RPP)        ;  ((HL))=INDEX=(R1)
        inc     (hl)            ;/  index(lb) += 1
        LD      E,(HL)          ;/
        INC     HL              ;/ (hl)-->index(hb)
        jr      nz,xloop1       ;/ jump if ((hl)) < 256
        inc     (hl)            ;/ else index(hb) += 1
xloop1: LD      D,(HL)          ;/ (DE)<-- new INDEX
        INC     HL              ;/ ((HL))=LIMIT
        LD      A,E
        SUB     (HL)
        LD      A,D
        INC     HL
        SBC     A,(HL)          ;  INDEX<LIMIT?
        JP      M,BRAN1         ;  YES, LOOP AGAIN
        INC     HL              ;  NO, DONE
        LD      (RPP),HL        ;  DISCARD R1 & R2
        INC     BC
        INC     BC              ;  SKIP BRANCH OFFSET
        JP      (IX)
;
PUBLIC _rf_code_xploo           ;(+LOOP)
_rf_code_xploo:
        POP     DE              ;(DE)<--INCR
        LD      HL,(RPP)        ;((HL))=INDEX
        LD      A,(HL)          ;INDEX<--INDEX+INCR
        ADD     A,E
        LD      (HL),A
        LD      E,A
        INC     HL
        LD      A,(HL)
        ADC     A,D
        LD      (HL),A
        INC     HL              ;((HL))=LIMIT
        INC     D
        DEC     D
        LD      D,A             ;(DE)<--NEW INDEX
        JP      M,XLOO2         ;IF INCR>0
        LD      A,E
        SUB     (HL)            ;THEN (A)<--INDEX - LIMIT
        LD      A,D
        INC     HL
        SBC     A,(HL)
        JP      XLOO3
XLOO2:  LD      A,(HL)          ;ELSE (A)<--LIMIT - INDEX
        SUB     E
        INC     HL
        LD      A,(HL)
        SBC     A,D
;                               ;IF (A)<0
XLOO3:  JP      M,BRAN1         ;THEN LOOP AGN
        INC     HL              ;ELSE DONE
        LD      (RPP),HL        ;DISCARD R1 & R2
        INC     BC              ;SKIP BRANCH OFFSET
        INC     BC
        JP      (IX)
;
PUBLIC _rf_code_xdo             ;  (DO)
_rf_code_xdo:
        EXX                     ;/ SAVE IP
        POP     DE              ;  (DE)<--INITIAL INDEX
        POP     BC              ;/ (BC)<--LIMIT
        LD      HL,(RPP)        ;  (HL)<--(RP)
        DEC     HL
        LD      (HL),B
        DEC     HL
        LD      (HL),C          ;/ (R2)<--LIMIT
        DEC     HL
        LD      (HL),D
        DEC     HL
        LD      (HL),E          ;  (R1)<--INITIAL INDEX
        LD      (RPP),HL        ;  (RP)<--(RP)-4
        EXX                     ;/ RESTORE IP
        JP      (IX)
;
PUBLIC _rf_code_rr              ;I
_rf_code_rr:                    ;(S1)<--(R1), (R1) UNCHANGED
        LD      HL,(RPP)
        LD      E,(HL)          ;(DE)<--(R1)
        INC     HL
        LD      D,(HL)
        PUSH    DE              ;(S1)<--(DE)
        JP      (IX)
;
PUBLIC _rf_code_digit           ;DIGIT
_rf_code_digit:
        POP     HL              ;(L)<--(S1)LB = BASE VALUE
        POP     DE              ;(E)<--(S2)LB = ASCII CHR TO BE CONVERTED
        LD      A,E             ;ACCU<--CHR
        SUB     '0'             ;>=0?
        JR      C,DIGI2         ;/ <0 IS INVALID
        CP      0AH             ;>9?
        JR      C,DIGI1         ;/ NO, TEST BASE VALUE
        SUB     07H             ;GAP BETWEEN "9" & "A", NW "A"=0AH
        CP      0AH             ;>="A"?
        JR      C,DIGI2         ;/ CHRs BETWEEN "9" & "A" ARE INVALID
DIGI1:  CP      L               ;<BASE VALUE?
        JR      NC,DIGI2        ;/ NO, INVALID
        LD      E,A             ;(S2)<--(DE) = CONVERTED DIGIT
        LD      HL,0001H        ;(S1)<--TRUE
        JP      DPUSH
DIGI2:  LD      L,H             ;(HL)<--FALSE
IFDEF USEIY
        JP      (IY)            ;(S1)<--FALSE
ELSE
        PUSH    HL
        JP      (IX)
ENDIF
;
PUBLIC _rf_code_pfind           ;(FIND) (2-1)FAILURE
_rf_code_pfind:                 ;       (2-3)SUCCESS
        POP     DE              ;(DE)<--NFA
PFIN1:  POP     HL              ;(HL)<--STRING ADDR
        PUSH    HL              ;SAVE FOR NEXT ITERATION
        LD      A,(DE)
        XOR     (HL)            ;FILTER DEVIATIONS
        AND     3FH             ;MASK MSB & PRECEDENCE BIT
        JR      NZ,PFIN4        ;LENGTHS DIFFER
PFIN2:  INC     HL              ;(HL)<--ADDR NEXT CHR IN STRING
        INC     DE              ;(DE)<--ADDR NEXT CHR IN NF
        LD      A,(DE)
        XOR     (HL)            ;FILTER DEVIATIONS
        ADD     A,A
        JR      NZ,PFIN3        ;NO MATCH
        JR      NC,PFIN2        ;MATCH SO FAR, LOOP AGN
        LD      HL,0005H        ;STRING MATCHES
        ADD     HL,DE           ;((SP))<--PFA
        EX      (SP),HL
PFIN6:  DEC     DE              ;POSN DE ON NFA
        LD      A,(DE)
        OR      A               ;MSB=1? =LENGTH BYTE
        JP      P,PFIN6         ;NO, TRY NEXT CHR
        LD      E,A             ;(E)<--LENGTH BYTE
        LD      D,00H
        LD      HL,0001H        ;(HL)<--TRUE
        JP      DPUSH           ;NF FOUND, RETURN
;
;ABOVE NF NOT A MATCH, TRY NEXT ONE
;
PFIN3:  JR      C,PFIN5         ;CARRY=END OF NF
PFIN4:  INC     DE              ;FIND END OF NF
        LD      A,(DE)
        OR      A               ;MSB=1?
        JP      P,PFIN4         ;NO, LOOP
PFIN5:  INC     DE              ;(DE)<--LFA
        EX      DE,HL
        LD      E,(HL)
        INC     HL
        LD      D,(HL)          ;(DE)<--(LFA)
        LD      A,D
        OR      E               ;END OF DICTIONARY? (LFA)=0
        JR      NZ,PFIN1        ;NO, TRY PREVIOUS DEFINITION
        POP     HL              ;DROP STRING ADDR
        LD      HL,0            ;(HL)<--FALSE
IFDEF USEIY
        JP      (IY)            ;NO MATCH FOUND, RETURN
ELSE
        PUSH    HL
        JP      (IX)
ENDIF
;
PUBLIC _rf_code_encl            ;ENCLOSE
_rf_code_encl:
        POP     DE              ;(DE)<--(S1)=DELIMITER CHR
        POP     HL              ;(HL)<--(S2)=ADDR OF TEXT TO SCAN
        PUSH    HL              ;(S4)<--ADDR
        LD      A,E
        LD      D,A             ;(D)<--DELIM CHR
        LD      E,-1            ;INIT CHR OFFSET COUNTER
        DEC     HL              ;(HL)<--ADDR-1
ENCL1:  INC     HL              ;SKIP OVER LEADING DELIM CHRs
        INC     E
        CP      (HL)            ;DELIM CHR?
        JR      Z,ENCL1         ;YES, LOOP
        LD      D,0
        PUSH    DE              ;(S3)<--(E)=OFFSET TO 1st NON DELIM
        LD      D,A             ;(D)<--DELIM CHR
        LD      A,(HL)
        AND     A               ;1st non-DELIM=NULL?
        JR      NZ,ENCL2        ;NO
        LD      D,0             ;YES
        INC     E
        PUSH    DE              ;(S2)<--OFFSET TO BYTE FOLLOWING NULL
        DEC     E
        PUSH    DE              ;(S1)<--OFFSET TO NULL
        JP      (IX)
ENCL2:  LD      A,D             ;(A)<--DELIM CHR
        INC     HL              ;(HL)<--ADDR NEXT CHR
        INC     E               ;(E)<--OFFSET TO NEXT CHR
        CP      (HL)            ;DELIM CHR?
        JR      Z,ENCL4         ;YES
        LD      A,(HL)
        AND     A               ;NULL?
        JR      NZ,ENCL2        ;NO, CONT SCAN
ENCL3:  LD      D,0
        PUSH    DE              ;(S2)<--OFFSET TO NULL
        PUSH    DE              ;(S1)<--OFFSET TO NULL
        JP      (IX)
ENCL4:  LD      D,0
        PUSH    DE              ;(S2)<--OFFSET TO BYTE FOLLOWING TEXT
        INC     E
        PUSH    DE              ;(S1)<--OFFSET TO 2 BYTES AFTER END OF WORD
        JP      (IX)
;
PUBLIC _rf_code_cmove           ;CMOVE
_rf_code_cmove:
        EXX                     ;/ SAVE IP
        POP     BC              ;  (BC)<--(S1)= #CHRs
        POP     DE              ;  (DE)<--(S2)= DEST ADDR
        POP     HL              ;/ (HL)<--(S3)= SOURCE ADDR
        LD      A,B
        OR      C               ;  BC=0?
        JR      Z,EXCMOV        ;  YES, DON'T MOVE ANYTHING
        LDIR                    ;/ XFER STRING
EXCMOV: EXX                     ;/ RESTORE IP
        JP      (IX)
;
PUBLIC _rf_code_ustar           ;U*   16*16 unsigned multiply
_rf_code_ustar:                 ;994 T cycles average (8080)
        POP     DE              ;(DE)<--MPLIER
        POP     HL              ;(HL)<--MPCAND
        PUSH    BC              ;SAVE IP
        LD      B,H
        LD      A,L             ;(BA)<--MPCAND
        CALL    MPYX            ;(AHL)1<--MPCAND.LB*MPLIER
                                ;       1st PARTIAL PRODUCT
        PUSH    HL              ;SAVE (HL)1
        LD      H,A
        LD      A,B
        LD      B,H             ;SAVE (A)1
        CALL    MPYX            ;(AHL)2<--MPCAND.HB*MPLIER
                                ;       2nd PARTIAL PRODUCT
        POP     DE              ;(DE)<--(HL)1
        LD      C,D             ;(BC)<--(AH)1
;       FORM SUM OF PARTIALS:
;                               ; (AHL)1
;                               ;+(AHL)2
;                               ;-------
;                               ; (AHLE)
        ADD     HL,BC           ;(HL)<--(HL)2+(AH)1
        ADC     A,00H           ;(AHLE)<--(BA)*(DE)
        LD      D,L
        LD      L,H
        LD      H,A             ;(HLDE)<--MPLIER*MPCAND
        POP     BC              ;RESTORE IP
        PUSH    DE              ;(S2)<--PRODUCT.LW
IFDEF USEIY
        JP      (IY)            ;(S1)<--PRODUCT.HW
ELSE
        PUSH    HL
        JP      (IX)
ENDIF
;
;       MULTIPLY PRIMITIVE
;                (AHL)<--(A)*(DE)
;       #BITS:    24    8   16
;
MPYX:   LD      HL,0            ;(HL)<--0=PARTIAL PRODUCT.LW
        LD      C,08H           ;LOOP COUNTER
MPYX1:  ADD     HL,HL           ;LEFT SHIFT (AHL) 24 BITS
        RLA
        JR      NC,MPYX2        ;IF NEXT MPLIER BIT = 1
        ADD     HL,DE           ;THEN ADD MPCAND
        ADC     A,0
MPYX2:  DEC     C               ;LAST MPLIER BIT?
        JR      NZ,MPYX1        ;NO, LOOP AGN
        RET                     ;YES, DONE
;
PUBLIC _rf_code_uslas           ;U/
_rf_code_uslas:
        LD      HL,0004H
        ADD     HL,SP           ;((HL))<--NUMERATOR.LW
        LD      E,(HL)          ;(DE)<--NUMER.LW
        LD      (HL),C          ;SAVE IP ON STACK
        INC     HL
        LD      D,(HL)
        LD      (HL),B
        POP     BC              ;(BC)<--DENOMINATOR
        POP     HL              ;(HL)<--NUMER.HW
        LD      A,L
        SUB     C
        LD      A,H
        SBC     A,B             ;NUMER >= DENOM?
        JR      C,USLA1         ;NO, GO AHEAD
        LD      HL,0FFFFH       ;YES, OVERFLOW
        LD      D,H
        LD      E,L             ;/ SET REM & QUOT TO MAX
        JP      USLA7
USLA1:  LD      A,10H           ;LOOP COUNTER
USLA2:  ADD     HL,HL           ;LEFT SHIFT (HLDE) THRU CARRY
        RLA                     ;ROT CARRY INTO ACCU BIT 0
        EX      DE,HL
        ADD     HL,HL
        JR      NC,USLA3
        INC     DE              ;ADD CARRY
        AND     A               ;RESET CARRY
USLA3:  EX      DE,HL           ;SHIFT DONE
        RRA                     ;RESTORE 1st CARRY & COUNTER
        JR      NC,USLA4        ;IF CARRY=1
        OR      A               ;/ RESET CARRY
        SBC     HL,BC           ;/ THEN (HL)<--(HL)-(BC)
        JP      USLA5
USLA4:  SBC     HL,BC           ;/ (HL)<--PARTIAL REMAINDER
        JR      NC,USLA5
        ADD     HL,BC           ;UNDERFLOW, RESTORE
        DEC     DE
USLA5:  INC     DE              ;INC QUOT
        DEC     A               ;COUNTER=0?
        JP      NZ,USLA2        ;NO, LOOP AGN
USLA7:  POP     BC              ;RESTORE IP
        PUSH    HL              ;(S2)<--REMAINDER
        PUSH    DE              ;(S1)<--QUOTIENT
        JP      (IX)
;
PUBLIC _rf_code_andd            ;AND
_rf_code_andd:                  ;(S1)<--(S1) AND (S2)
        POP     DE
        POP     HL
        LD      A,E
        AND     L
        LD      L,A
        LD      A,D
        AND     H
        LD      H,A
IFDEF USEIY
        JP      (IY)
ELSE
        PUSH    HL
        JP      (IX)
ENDIF
;
PUBLIC _rf_code_orr             ;OR
_rf_code_orr:                   ;(S1)<--(S1) OR (S2)
        POP     DE
        POP     HL
        LD      A,E
        OR      L
        LD      L,A
        LD      A,D
        OR      H
        LD      H,A
IFDEF USEIY
        JP      (IY)
ELSE
        PUSH    HL
        JP      (IX)
ENDIF
;
PUBLIC _rf_code_xorr            ;XOR
_rf_code_xorr:                  ;(S1)<--(S1) XOR (S2)
        POP     DE
        POP     HL
        LD      A,E
        XOR     L
        LD      L,A
        LD      A,D
        XOR     H
        LD      H,A
IFDEF USEIY
        JP      (IY)
ELSE
        PUSH    HL
        JP      (IX)
ENDIF
;
PUBLIC _rf_code_spat            ;SP@
_rf_code_spat:                  ;(S1)<--(SP)
        LD      HL,0
        ADD     HL,SP           ;(HL)<--(SP)
IFDEF USEIY
        JP      (IY)
ELSE
        PUSH    HL
        JP      (IX)
ENDIF
;
PUBLIC _rf_code_spsto           ;SP!
_rf_code_spsto:                 ;(SP)<--(S0) (USER VARIABLE)
        LD      HL,(UP)         ;(HL)<--USER VAR BASE ADDR
        LD      DE,0006H
        ADD     HL,DE           ;(HL)<--S0
        LD      E,(HL)
        INC     HL
        LD      D,(HL)          ;(DE)<--(S0)
        EX      DE,HL
        LD      SP,HL           ;(SP)<--(S0)
        JP      (IX)
;

PUBLIC _rf_code_rpsto           ;RP!
_rf_code_rpsto:                 ;(RP)<--(R0) (USER VARIABLE)
        LD      HL,(UP)         ;(HL)<--USER VAR BASE ADDR
        LD      DE,0008H
        ADD     HL,DE           ;(HL)<--R0
        LD      E,(HL)
        INC     HL
        LD      D,(HL)          ;(DE)<--(R0)
        LD      (RPP),DE        ;/ (RP)<--(R0)
        JP      (IX)
;
PUBLIC _rf_code_semis           ; ;S
_rf_code_semis:                 ;(IP)<--(R1)
        LD      HL,(RPP)
        LD      C,(HL)
        INC     HL
        LD      B,(HL)          ;(BC)<--(R1)
        INC     HL
        LD      (RPP),HL        ;(RP)<--(RP)+2
        JP      (IX)
;
PUBLIC _rf_code_leave           ;LEAVE
_rf_code_leave:                 ;LIMIT<--INDEX
        LD      HL,(RPP)
        LD      E,(HL)
        INC     HL
        LD      D,(HL)          ;(DE)<--(R1)=INDEX
        INC     HL
        LD      (HL),E
        INC     HL
        LD      (HL),D          ;(R2)<--(DE)=LIMIT
        JP      (IX)
;
PUBLIC _rf_code_tor             ;>R
_rf_code_tor:
        POP     DE
        LD      HL,(RPP)
        DEC     HL
        LD      (HL),D                
        DEC     HL
        LD      (HL),E          ;/ (R1)<--(DE)
        LD      (RPP),HL        ;  (RP)<--(RP)-2
        JP      (IX)
;
PUBLIC _rf_code_fromr           ;R>
_rf_code_fromr:
        LD      HL,(RPP)
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        INC     HL
        LD      (RPP),HL
        PUSH    DE              ;(S1)<--(R1)
        JP      (IX)
;
PUBLIC _rf_code_zequ            ;0=
_rf_code_zequ:
        POP     HL
        LD      A,L
        OR      H
        LD      HL,0
;       JR      NZ,ZEQU1
        JP      NZ,HPUSH
        INC     L               ;(HL)<--TRUE
IFDEF USEIY
ZEQU1:  JP      (IY)
ELSE
ZEQU1:  PUSH    HL
        JP      (IX)
ENDIF
;
PUBLIC _rf_code_zless           ;0<
_rf_code_zless:
        POP     AF              ;/ (A)<--(S1)H
        RLA                     ;/ (CARRY)<--BIT 7
        LD      HL,0            ;  (HL)<--FALSE
;       JR      NC,ZLES1
        JP      NC,HPUSH
        INC     L               ;  (HL)<--TRUE
IFDEF USEIY
ZLES1:  JP      (IY)
ELSE
ZLES1:  PUSH    HL
        JP      (IX)
ENDIF
;
PUBLIC _rf_code_plus            ;+
_rf_code_plus:
        POP     DE
        POP     HL
        ADD     HL,DE
IFDEF USEIY
        JP      (IY)
ELSE
        PUSH    HL
        JP      (IX)
ENDIF
;
PUBLIC _rf_code_dplus           ;D+ ( d1L d1H d2L d2h -- d3L d3H)
_rf_code_dplus:
        EXX                     ;/ SAVE IP
        POP     BC              ;  (BC)<--d2H
        POP     HL              ;  (HL)<--d2L
        POP     AF              ;d (AF)<--d1H
        POP     DE              ;  (DE)<--d1L
        PUSH    AF              ;/ (S1)<--d1H
        ADD     HL,DE           ;  (HL)<--d2L+d1L=d3L
        EX      DE,HL           ;  (DE)<--d3L
        POP     HL              ;  (HL)<--d1H
        ADC     HL,BC           ;/ (HL)<--d1H+d2H+CARRY=d3H
        PUSH    DE              ;  (S2)<--d3L
        PUSH    HL              ;/ (S1)<--d3H
        EXX                     ;/ RESTORE IP
        JP      (IX)
;
PUBLIC _rf_code_minus           ;MINUS
_rf_code_minus:
;       POP     DE              ;/
;       XOR     A               ;/ RESET CARRY, (A)<--0
;       LD      H,A             ;/
;       LD      L,A             ;/ LD HL,0
;       SBC     HL,DE           ;/ (HL)<--(DE)2's COMPL.
; see http://z80-heaven.wikidot.com/optimization#toc18
; 34t vs 37t
        POP     HL
        XOR     A
        SUB     L
        LD      L,A
        SBC     A,A
        SUB     H
        LD      H,A
IFDEF USEIY
        JP      (IY)
ELSE
        PUSH    HL
        JP      (IX)
ENDIF
;
PUBLIC _rf_code_dminu           ;DMINUS
_rf_code_dminu:
        POP     HL              ;(HL)<--d1H
        POP     DE              ;(DE)<--d1L
        SUB     A               ;(A)<--0
        SUB     E
        LD      E,A             ;(E)<--NEG(E)
        LD      A,00H
        SBC     A,D
        LD      D,A             ;(D)<--NEG(D)
        LD      A,00H
        SBC     A,L
        LD      L,A             ;(L)<--NEG(L)
        LD      A,00H
        SBC     A,H
        LD      H,A             ;(H)<--NEG(H)
        JP      DPUSH           ;(S2)<--d2L, (S1)<--d2H
;
PUBLIC _rf_code_over            ;OVER
_rf_code_over:
        POP     DE
        POP     HL
        PUSH    HL
        JP      DPUSH
;
PUBLIC _rf_code_drop            ;DROP
_rf_code_drop:
        POP     HL
        JP      (IX)
;
PUBLIC _rf_code_swap            ;SWAP
_rf_code_swap:
        POP     HL
        EX      (SP),HL
IFDEF USEIY
        JP      (IY)
ELSE
        PUSH    HL
        JP      (IX)
ENDIF
;
PUBLIC _rf_code_dup             ;DUP
_rf_code_dup:
        POP     HL
        PUSH    HL
IFDEF USEIY
        JP      (IY)
ELSE
        PUSH    HL
        JP      (IX)
ENDIF

PUBLIC _rf_code_pstor           ;+!
_rf_code_pstor:
        POP     HL              ;(HL)<--VAR ADDR
        POP     DE              ;(DE)<--NUMBER
        LD      A,(HL)
        ADD     A,E
        LD      (HL),A
        INC     HL
        LD      A,(HL)
        ADC     A,D
        LD      (HL),A          ;((HL))<--((HL))+NUMBER
        JP      (IX)
;
PUBLIC _rf_code_toggl           ;TOGGLE
_rf_code_toggl:
        POP     DE              ;(E)<--BIT PATTERN
        POP     HL              ;(HL)<--ADDR
        LD      A,(HL)
        XOR     E
        LD      (HL),A
        JP      (IX)
;
PUBLIC _rf_code_at              ;@
_rf_code_at:
        POP     HL
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        PUSH    DE
        JP      (IX)
;
PUBLIC _rf_code_cat             ;C@
_rf_code_cat:
        POP     HL
        LD      L,(HL)
        LD      H,0
IFDEF USEIY
        JP      (IY)
ELSE
        PUSH    HL
        JP      (IX)
ENDIF
;

PUBLIC _rf_code_store           ;!
_rf_code_store:
        POP     HL
        POP     DE
        LD      (HL),E
        INC     HL
        LD      (HL),D
        JP      (IX)
;
PUBLIC _rf_code_cstor           ;C!
_rf_code_cstor:
        POP     HL
        POP     DE
        LD      (HL),E
        JP      (IX)
;

PUBLIC _rf_code_docol           ; :
_rf_code_docol:
DOCOL:  LD      HL,(RPP)
        DEC     HL
        LD      (HL),B
        DEC     HL
        LD      (HL),C
        LD      (RPP),HL
        INC     DE
        LD      C,E
        LD      B,D
        JP      (IX)
;

PUBLIC _rf_code_docon           ;CONSTANT
_rf_code_docon:
DOCON:  INC     DE
        EX      DE,HL
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        PUSH    DE
        JP      (IX)
;
PUBLIC _rf_code_dovar           ;VARIABLE
_rf_code_dovar:
DOVAR:  INC     DE
        PUSH    DE
        JP      (IX)
;
PUBLIC _rf_code_douse           ;USER
_rf_code_douse:
DOUSE:  INC     DE
        EX      DE,HL
        LD      E,(HL)
        LD      D,00H
        LD      HL,(UP)
        ADD     HL,DE
IFDEF USEIY
        JP      (IY)
ELSE
        PUSH    HL
        JP      (IX)
ENDIF
;

PUBLIC _rf_code_stod            ;S->D
_rf_code_stod:
        POP     DE
        LD      HL,0
        BIT     7,D             ;/ # NEGATIVE?
        JR      Z,STOD1         ;  NO
        DEC     HL              ;  YES, EXTEND SIGN
STOD1:  JP      DPUSH           ;  ( n1--d1L d1H)
;

PUBLIC _rf_code_dodoe           ;DOES>
_rf_code_dodoe:
DODOE:  LD      HL,(RPP)
        DEC     HL
        LD      (HL),B
        DEC     HL
        LD      (HL),C
        LD      (RPP),HL
        INC     DE
        EX      DE,HL
        LD      C,(HL)
        INC     HL
        LD      B,(HL)
        INC     HL
IFDEF USEIY
        JP      (IY)
ELSE
        PUSH    HL
        JP      (IX)
ENDIF
;

PUBLIC _rf_code_cold            ;COLD
_rf_code_cold:
        LD      HL,ORIG+0CH     ; FORTH vocabulary init
        LD      DE,(ORIG+2AH)
        LDI
        LDI
        LD      HL,(UPINIT)     ; UP init
        LD      (UP),HL
        EX      DE,HL           ; USER variables init
        LD      HL,ORIG+0CH
        LD      BC,16H
        LDIR
        LD      BC,(ORIG+2CH)   ; IP init to ABORT
        LD      IX,NEXT         ; POINTER TO NEXT
IFDEF USEIY
        LD      IY,HPUSH        ; POINTER TO HPUSH
ENDIF
        JP      _rf_code_rpsto  ; jump to RP!
