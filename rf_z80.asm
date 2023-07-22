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
;	Forth Interest Group
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
; Modified for orterforth integration in 2021

SECTION code_user

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
;
;
; COMMENT CONVENTIONS:
;
; =       MEANS "IS EQUAL TO"
; <--     MEANS ASSIGNMENT
; NAME    =     ADDR OF NAME
; (NAME)  =     CONTENTS @ NAME
; ((NAME))=     INDIRECT CONTENTS
; CFA     =     CODE FIELD ADDR
; LFA     =     LINK FIELD ADDR
; NFA     =     NAME FIELD ADDR
; PFA     =     PARAMETER FIELD ADDR
; S1      =     ADDR OF 1st WORD OF PARAMETER STACK
; S2      =     -"-  OF 2nd -"-  OF    -"-     -"-
; R1      =     -"-  OF 1st -"-  OF RETURN STACK
; R2      =     -"-  OF 2nd -"-  OF  -"-    -"-
; ( above Stack posn. valid b4 & after execution of any word, not during)
;
; LSB     =     LEAST SIGNIFICANT BIT
; MSB     =     MOST  SIGNIFICANT BIT
; LB      =     LOW  BYTE
; HB      =     HIGH BYTE
; LW      =     LOW  WORD
; HW      =     HIGH WORD
; (May be used as suffix to above names)

; orterforth interop with C code definitions

DEFINE USEIY                    ; to hold HPUSH

_rf_z80_sp:
  defw $0000                    ; register SP saved here 

PUBLIC _rf_start

_rf_start:                      ; C code calls this to switch from registers to C variables
  pop hl                        ; save C return address
IFDEF USEIY
IFDEF SPECTRUM
  ld iy, $5C3A                  ; restore IY (ZX Spectrum)
ENDIF
ENDIF
  ld (_rf_sp), sp               ; sp to SP
  ld sp, (_rf_z80_sp)
  dec de                        ; de to W
  ld (_rf_w), de
  ld (_rf_ip), bc               ; bc to IP
  jp (hl)                       ; return to C

PUBLIC _rf_trampoline

_rf_trampoline:                 ; C code calls this to iterate over function pointers - assumes a switch into assembler
  ld hl, (_rf_fp)               ; returns if fp is null
  ld a, h
  or l
  ret z
  ld de, _rf_trampoline         ; fp will return to this address
  push de
  ld bc, (_rf_ip)               ; IP to bc
  ld de, (_rf_w)                ; W to de
  inc de
  ld (_rf_z80_sp), sp           ; SP to sp
  ld sp, (_rf_sp)
  ld ix, next                   ; set IX
IFDEF USEIY
  ld iy, hpush                  ; set IY
ENDIF
  jp (hl)                       ; jump to fp, will return to start of trampoline

;	FORTH ADDRESS INTERPRETER
;	POST INCREMENTING VERSION
;
PUBLIC _rf_z80_dpush            ; external libs can use this
PUBLIC _rf_z80_hpush            ; external libs can use this
PUBLIC _rf_next

_rf_z80_dpush:
dpush:
  push de
_rf_z80_hpush:
hpush:
  push hl                       ;		IY points here
_rf_next:
next:
  ld a, (bc)                    ;(W)<--((IP))	IX points here
  ld l, a
  inc bc                        ;INC IP
  ld a, (bc)
  ld h, a                       ;(HL)<--CFA
  inc bc
next1:
  ld e, (hl)                    ;(PC)<--((W))
  inc hl
  ld d, (hl)
  ex de, hl
  jp (hl)                       ;NOTE: (DE)=CFA+1

PUBLIC _rf_code_lit

_rf_code_lit:                   ;(S1)<--((IP))
  ld a, (bc)                    ;(HL)<--((IP))=LITERAL
  inc bc                        ;(IP)<--(IP)+2
  ld l, a                       ;LB
  ld a, (bc)                    ;HB
  inc bc
  ld h, a
IFDEF USEIY
  jp (iy)                       ;(S1)<--(HL)
ELSE
  jp hpush
ENDIF

PUBLIC _rf_code_exec

_rf_code_exec:
  pop hl                        ; jump to *CFA
  jp next1

PUBLIC _rf_code_bran

_rf_code_bran:
bran1:                          ;(IP)<--(IP)+((IP))
  ld h, b                       ;(HL)<--(IP)
  ld l, c
  ld e, (hl)                    ;(DE)<--((IP))=BRANCH OFFSET
  inc hl
  ld d, (hl)
  dec hl
  add hl, de                    ;(HL)<--(HL)+((IP))
  ld c, l                       ;(IP)<--(HL)
  ld b, h
  jp (ix)

PUBLIC _rf_code_zbran

_rf_code_zbran:
  pop hl
  ld a, l
  or h
  jp z, bran1                   ;IF (S1)=0 THEN BRANCH
  inc bc                        ;ELSE SKIP BRANCH OFFSET
  inc bc
  jp (ix)

PUBLIC _rf_code_xloop

_rf_code_xloop:
  ld hl, (_rf_rp)               ;  ((HL))=INDEX=(R1)
  inc (hl)                      ;/  index(lb) += 1
  ld e, (hl)                    ;/
  inc hl                        ;/ (hl)-->index(hb)
  jp nz, xloop1                 ;/ jump if ((hl)) < 256
  inc (hl)                      ;/ else index(hb) += 1
xloop1:
  ld d, (hl)                    ;/ (DE)<-- new INDEX
  inc hl                        ;/ ((HL))=LIMIT
  ld a, e
  sub (hl)
  ld a, d
  inc hl
  sbc a, (hl)                   ;  INDEX<LIMIT?
  jp m, bran1                   ;  YES, LOOP AGAIN
  inc hl                        ;  NO, DONE
  ld (_rf_rp), hl               ;  DISCARD R1 & R2
  inc bc
  inc bc                        ;  SKIP BRANCH OFFSET
  jp (ix)

PUBLIC _rf_code_xploo

_rf_code_xploo:
  pop de                        ;(DE)<--INCR
  ld hl, (_rf_rp)               ;((HL))=INDEX
  ld a, (hl)                    ;INDEX<--INDEX+INCR
  add a, e
  ld (hl), a
  ld e, a
  inc hl
  ld a, (hl)
  adc a, d
  ld (hl), a
  inc hl                        ;((HL))=LIMIT
  inc d
  dec d
  ld d, a                       ;(DE)<--NEW INDEX
  jp m, xloo2                   ;IF INCR>0
  ld a, e
  sub (hl)                      ;THEN (A)<--INDEX - LIMIT
  ld a, d
  inc hl
  sbc a, (hl)
  jp xloo3
xloo2:
  ld a, (hl)                    ;ELSE (A)<--LIMIT - INDEX
  sub e
  inc hl
  ld a, (hl)
  sbc a, d                      ;IF (A)<0
xloo3:
  jp m, bran1                   ;THEN LOOP AGN
  inc hl                        ;ELSE DONE
  ld (_rf_rp), hl               ;DISCARD R1 & R2
  inc bc                        ;SKIP BRANCH OFFSET
  inc bc
  jp (ix)

PUBLIC _rf_code_xdo

_rf_code_xdo:
  exx                           ;/ SAVE IP
  pop de                        ;  (DE)<--INITIAL INDEX
  pop bc                        ;/ (BC)<--LIMIT
  ld hl, (_rf_rp)               ;  (HL)<--(RP)
  dec hl
  ld (hl), b
  dec hl
  ld (hl), c                    ;/ (R2)<--LIMIT
  dec hl
  ld (hl), d
  dec hl
  ld (hl), e                    ;  (R1)<--INITIAL INDEX
  ld (_rf_rp), hl               ;  (RP)<--(RP)-4
  exx                           ;/ RESTORE IP
  jp (ix)

PUBLIC _rf_code_rr

_rf_code_rr:                    ;(S1)<--(R1), (R1) UNCHANGED
  ld hl, (_rf_rp)               ;(DE)<--(R1)
  ld e, (hl)
  inc hl
  ld d, (hl)
  push de                       ;(S1)<--(DE)
  jp (ix)

PUBLIC _rf_code_digit

_rf_code_digit:
  pop hl                        ;(L)<--(S1)LB = BASE VALUE
  pop de                        ;(E)<--(S2)LB = ASCII CHR TO BE CONVERTED
  ld a, e                       ;ACCU<--CHR
  sub $30                       ;>=0?
  jp c, digi2                   ;/ <0 IS INVALID
  cp $0A                        ;>9?
  jp c, digi1                   ;/ NO, TEST BASE VALUE
  sub $07                       ;GAP BETWEEN "9" & "A", NW "A"=0AH
  cp $0A                        ;>="A"?
  jp c, digi2                   ;/ CHRs BETWEEN "9" & "A" ARE INVALID
digi1:
  cp l                          ;<BASE VALUE?
  jp nc, digi2                  ;/ NO, INVALID
  ld e, a                       ;(S2)<--(DE) = CONVERTED DIGIT
  ld hl, $0001                  ;(S1)<--TRUE
  jp dpush
digi2:
  ld l, h                       ;(HL)<--FALSE
IFDEF USEIY
  jp (iy)                       ;(S1)<--FALSE
ELSE
  jp hpush
ENDIF

PUBLIC _rf_code_pfind

_rf_code_pfind:
  pop de                        ;(DE)<--NFA
pfin1: 
  pop hl                        ;(HL)<--STRING ADDR
  push hl                       ;SAVE FOR NEXT ITERATION
  ld a, (de)
  xor (hl)                      ;FILTER DEVIATIONS
  and $3F                       ;MASK MSB & PRECEDENCE BIT
  jp nz, pfin4                  ;LENGTHS DIFFER
pfin2:
  inc hl                        ;(HL)<--ADDR NEXT CHR IN STRING
  inc de                        ;(DE)<--ADDR NEXT CHR IN NF
  ld a, (de)
  xor (hl)                      ;FILTER DEVIATIONS
  add a, a
  jp nz, pfin3                  ;NO MATCH
  jp nc, pfin2                  ;MATCH SO FAR, LOOP AGN
  ld hl, $0005                  ;STRING MATCHES
  add hl, de                    ;((SP))<--PFA
  ex (sp), hl
pfin6:
  dec de                        ;POSN DE ON NFA
  ld a, (de)
  or a                          ;MSB=1? =LENGTH BYTE
  jp p, pfin6                   ;NO, TRY NEXT CHR
  ld e, a                       ;(E)<--LENGTH BYTE
  ld d, $00
  ld hl, $0001                  ;(HL)<--TRUE
  jp dpush                      ;NF FOUND, RETURN
;
;ABOVE NF NOT A MATCH, TRY NEXT ONE
;
pfin3:
  jp c, pfin5                   ;CARRY=END OF NF
pfin4:
  inc de                        ;FIND END OF NF
  ld a, (de)
  or a                          ;MSB=1?
  jp p, pfin4                   ;NO, LOOP
pfin5:
  inc de                        ;(DE)<--LFA
  ex de, hl
  ld e, (hl)
  inc hl
  ld d, (hl)                    ;(DE)<--(LFA)
  ld a, d
  or e                          ;END OF DICTIONARY? (LFA)=0
  jp nz, pfin1                  ;NO, TRY PREVIOUS DEFINITION
  pop hl                        ;DROP STRING ADDR
  ld hl, $0000                  ;(HL)<--FALSE
IFDEF USEIY
  jp (iy)                       ;NO MATCH FOUND, RETURN
ELSE
  jp hpush
ENDIF

PUBLIC _rf_code_encl

_rf_code_encl:
  pop de                        ;(DE)<--(S1)=DELIMITER CHR
  pop hl                        ;(HL)<--(S2)=ADDR OF TEXT TO SCAN
  push hl                       ;(S4)<--ADDR
  ld a, e
  ld d, a                       ;(D)<--DELIM CHR
  ld e, $FF                     ;INIT CHR OFFSET COUNTER
  dec hl                        ;(HL)<--ADDR-1
encl1:
  inc hl                        ;SKIP OVER LEADING DELIM CHRs
  inc e
  cp (hl)                       ;DELIM CHR?
  jp z, encl1                   ;YES, LOOP
  ld d, $00
  push de                       ;(S3)<--(E)=OFFSET TO 1st NON DELIM
  ld d, a                       ;(D)<--DELIM CHR
  ld a, (hl)
  and a                         ;1st non-DELIM=NULL?
  jp nz, encl2                  ;NO
  ld d, $00                     ;YES
  inc e
  push de                       ;(S2)<--OFFSET TO BYTE FOLLOWING NULL
  dec e
  push de                       ;(S1)<--OFFSET TO NULL
  jp (ix)
encl2:
  ld a, d                       ;(A)<--DELIM CHR
  inc hl                        ;(HL)<--ADDR NEXT CHR
  inc e                         ;(E)<--OFFSET TO NEXT CHR
  cp (hl)                       ;DELIM CHR?
  jp z, encl4                   ;YES
  ld a, (hl)
  and a                         ;NULL?
  jp nz, encl2                  ;NO, CONT SCAN
encl3:
  ld d, $00
  push de                       ;(S2)<--OFFSET TO NULL
  push de                       ;(S1)<--OFFSET TO NULL
  jp (ix)
encl4:
  ld d, $00
  push de                       ;(S2)<--OFFSET TO BYTE FOLLOWING TEXT
  inc e
  push de                       ;(S1)<--OFFSET TO 2 BYTES AFTER END OF WORD
  jp (ix)

PUBLIC _rf_code_cmove

_rf_code_cmove:
  exx                           ;/ SAVE IP
  pop bc                        ;  (BC)<--(S1)= #CHRs
  pop de                        ;  (DE)<--(S2)= DEST ADDR
  pop hl                        ;/ (HL)<--(S3)= SOURCE ADDR
  ld a, b
  or c                          ;  BC=0?
  jp z, excmov                  ;  YES, DON'T MOVE ANYTHING
  ldir                          ;/ XFER STRING
excmov:
  exx                           ;/ RESTORE IP
  jp (ix)

PUBLIC _rf_code_ustar

_rf_code_ustar:
  pop de                        ;(DE)<--MPLIER
  pop hl                        ;(HL)<--MPCAND
  push bc                       ;SAVE IP
  ld b, h
  ld a, l                       ;(BA)<--MPCAND
  call mpyx                     ;(AHL)1<--MPCAND.LB*MPLIER
                                ;       1st PARTIAL PRODUCT
  push hl                       ;SAVE (HL)1
  ld h, a
  ld a, b
  ld b, h                       ;SAVE (A)1
  call mpyx                     ;(AHL)2<--MPCAND.HB*MPLIER
                                ; 2nd PARTIAL PRODUCT
  pop de                        ;(DE)<--(HL)1
  ld c, d                       ;(BC)<--(AH)1
; FORM SUM OF PARTIALS:
;    ; (AHL)1
;    ;+(AHL)2
;    ;-------
;    ; (AHLE)
  add hl, bc                    ;(HL)<--(HL)2+(AH)1
  adc a, $00                    ;(AHLE)<--(BA)*(DE)
  ld d, l
  ld l, h
  ld h, a                       ;(HLDE)<--MPLIER*MPCAND
  pop bc                        ;RESTORE IP
  push de                       ;(S2)<--PRODUCT.LW
IFDEF USEIY
  jp (iy)                       ;(S1)<--PRODUCT.HW
ELSE
  jp hpush
ENDIF
;
; MULTIPLY PRIMITIVE
;   (AHL)<--(A)*(DE)
; #BITS:   24 8   16
;
mpyx:
  ld hl, $0000                  ;(HL)<--0=PARTIAL PRODUCT.LW
  ld c, $08                     ;LOOP COUNTER
mpyx1:
  add hl, hl                    ;LEFT SHIFT (AHL) 24 BITS
  rla
  jp nc, mpyx2                  ;IF NEXT MPLIER BIT = 1
  add hl, de                    ;THEN ADD MPCAND
  adc a, $00
mpyx2:
  dec c                         ;LAST MPLIER BIT?
  jp nz, mpyx1                  ;NO, LOOP AGN
  ret                           ;YES, DONE

PUBLIC _rf_code_uslas

_rf_code_uslas:
  ld hl, $0004
  add hl, sp                    ;((HL))<--NUMERATOR.LW
  ld e, (hl)                    ;(DE)<--NUMER.LW
  ld (hl), c                    ;SAVE IP ON STACK
  inc hl
  ld d, (hl)
  ld (hl), b
  pop bc                        ;(BC)<--DENOMINATOR
  pop hl                        ;(HL)<--NUMER.HW
  ld a, l
  sub c
  ld a, h
  sbc a, b                      ;NUMER >= DENOM?
  jp c, usla1                   ;NO, GO AHEAD
  ld hl, $FFFF                  ;YES, OVERFLOW
  ld d, h
  ld e, l                       ;/ SET REM & QUOT TO MAX
  jp usla7
usla1:
  ld a, $10                     ;LOOP COUNTER
usla2:
  add hl, hl                    ;LEFT SHIFT (HLDE) THRU CARRY
  rla                           ;ROT CARRY INTO ACCU BIT 0
  ex de, hl
  add hl, hl
  jp nc, usla3
  inc de                        ;ADD CARRY
  and a                         ;RESET CARRY
usla3:
  ex de, hl                     ;SHIFT DONE
  rra                           ;RESTORE 1st CARRY & COUNTER
  jp nc, usla4                  ;IF CARRY=1
  or a                          ;/ RESET CARRY
  sbc hl, bc                    ;/ THEN (HL)<--(HL)-(BC)
  jp usla5
usla4:
  sbc hl, bc                    ;/ (HL)<--PARTIAL REMAINDER
  jp nc, usla5
  add hl, bc                    ;UNDERFLOW, RESTORE
  dec de
usla5:
  inc de                        ;INC QUOT
  dec a                         ;COUNTER=0?
  jp nz, usla2                  ;NO, LOOP AGN
usla7:
  pop bc                        ;RESTORE IP
  push hl                       ;(S2)<--REMAINDER
  push de                       ;(S1)<--QUOTIENT
  jp (ix)

PUBLIC _rf_code_andd

_rf_code_andd:                  ;(S1)<--(S1) AND (S2)
  pop de
  pop hl
  ld a, e
  and l
  ld l, a
  ld a, d
  and h
  ld h, a
IFDEF USEIY
  jp (iy)
ELSE
  jp hpush
ENDIF

PUBLIC _rf_code_orr

_rf_code_orr:                   ;(S1)<--(S1) OR (S2)
  pop de
  pop hl
  ld a, e
  or l
  ld l, a
  ld a, d
  or h
  ld h, a
IFDEF USEIY
  jp (iy)
ELSE
  jp hpush
ENDIF

PUBLIC _rf_code_xorr

_rf_code_xorr:                  ;(S1)<--(S1) XOR (S2)
  pop de
  pop hl
  ld a, e
  xor l
  ld l, a
  ld a, d
  xor h
  ld h, a
IFDEF USEIY
  jp (iy)
ELSE
  jp hpush
ENDIF

PUBLIC _rf_code_spat

_rf_code_spat:                  ;(S1)<--(SP)
  ld hl, $0000
  add hl, sp                    ;(HL)<--(SP)
IFDEF USEIY
  jp (iy)
ELSE
  jp hpush
ENDIF

PUBLIC _rf_code_spsto

_rf_code_spsto:                 ;(SP)<--(S0) (USER VARIABLE)
  ld hl, (_rf_up)               ;(HL)<--USER VAR BASE ADDR
  ld de, $0006
  add hl, de                    ;(HL)<--S0
  ld e, (hl)
  inc hl
  ld d, (hl)                    ;(DE)<--(S0)
  ex de, hl
  ld sp, hl                     ;(SP)<--(S0)
  jp (ix)

PUBLIC _rf_code_rpsto

_rf_code_rpsto:                 ;(RP)<--(R0) (USER VARIABLE)
  ld hl, (_rf_up)               ;(HL)<--USER VAR BASE ADDR
  ld de, $0008
  add hl, de                    ;(HL)<--R0
  ld e, (hl)
  inc hl
  ld d, (hl)                    ;(DE)<--(R0)
  ld (_rf_rp), de               ;/ (RP)<--(R0)
  jp (ix)

PUBLIC _rf_code_semis

_rf_code_semis:                 ;(IP)<--(R1)
  ld hl, (_rf_rp)
  ld c, (hl)
  inc hl
  ld b, (hl)                    ;(BC)<--(R1)
  inc hl
  ld (_rf_rp), hl               ;(RP)<--(RP)+2
  jp (ix)

PUBLIC _rf_code_leave

_rf_code_leave:                 ;LIMIT<--INDEX
  ld hl, (_rf_rp)
  ld e, (hl)
  inc hl
  ld d, (hl)                    ;(DE)<--(R1)=INDEX
  inc hl
  ld (hl), e
  inc hl
  ld (hl), d                    ;(R2)<--(DE)=LIMIT
  jp (ix)

PUBLIC _rf_code_tor

_rf_code_tor:
  pop de
  ld hl, (_rf_rp)
  dec hl
  ld (hl), d  
  dec hl
  ld (hl), e                    ;/ (R1)<--(DE)
  ld (_rf_rp), hl               ;  (RP)<--(RP)-2
  jp (ix)

PUBLIC _rf_code_fromr

_rf_code_fromr:
  ld hl, (_rf_rp)
  ld e, (hl)
  inc hl
  ld d, (hl)
  inc hl
  ld (_rf_rp), hl
  push de                       ;(S1)<--(R1)
  jp (ix)

PUBLIC _rf_code_zequ

_rf_code_zequ:
  pop hl
  ld a, l
  or h
  ld hl, $0000
  jp nz, hpush
  inc l                         ;(HL)<--TRUE
zequ1:
IFDEF USEIY
  jp (iy)
ELSE
  jp hpush
ENDIF

PUBLIC _rf_code_zless

_rf_code_zless:
  pop af                        ;/ (A)<--(S1)H
  rla                           ;/ (CARRY)<--BIT 7
  ld hl, $0000                  ;  (HL)<--FALSE
  jp nc, hpush
  inc l                         ;  (HL)<--TRUE
zles1:
IFDEF USEIY
  jp (iy)
ELSE
  jp hpush
ENDIF

PUBLIC _rf_code_plus

_rf_code_plus:
  pop de
  pop hl
  add hl, de
IFDEF USEIY
  jp (iy)
ELSE
  jp hpush
ENDIF

PUBLIC _rf_code_dplus

_rf_code_dplus:
  exx                           ;/ SAVE IP
  pop bc                        ;  (BC)<--d2H
  pop hl                        ;  (HL)<--d2L
  pop af                        ;d (AF)<--d1H
  pop de                        ;  (DE)<--d1L
  push af                       ;/ (S1)<--d1H
  add hl, de                    ;  (HL)<--d2L+d1L=d3L
  ex de, hl                     ;  (DE)<--d3L
  pop hl                        ;  (HL)<--d1H
  adc hl, bc                    ;/ (HL)<--d1H+d2H+CARRY=d3H
  push de                       ;  (S2)<--d3L
  push hl                       ;/ (S1)<--d3H
  exx                           ;/ RESTORE IP
  jp (ix)

PUBLIC _rf_code_minus

_rf_code_minus:
; pop de                  ; 10t ;/
; xor a                   ;  4t ;/ RESET CARRY, (A)<--0
; ld h, a                 ;  4t ;/
; ld l, a                 ;  4t ;/ LD HL,0
; sbc hl, de              ; 15t ;/ (HL)<--(DE)2's COMPL.
                          ; 37t total
  pop hl                  ; 10t
  xor a                   ;  4t
  sub l                   ;  4t
  ld l, a                 ;  4t
  sbc a, a                ;  4t
  sub h                   ;  4t
  ld h, a                 ;  4t
                          ; 34t total http://z80-heaven.wikidot.com/optimization#toc18
IFDEF USEIY
  jp (iy)
ELSE
  jp hpush
ENDIF

PUBLIC _rf_code_dminu

_rf_code_dminu:
  pop hl                        ;(HL)<--d1H
  pop de                        ;(DE)<--d1L
  sub a                         ;(A)<--0
  sub e
  ld e, a                       ;(E)<--NEG(E)
  ld a, $00
  sbc a, d
  ld d, a                       ;(D)<--NEG(D)
  ld a, $00
  sbc a, l
  ld l, a                       ;(L)<--NEG(L)
  ld a, $00
  sbc a, h
  ld h, a                       ;(H)<--NEG(H)
  jp dpush                      ;(S2)<--d2L, (S1)<--d2H

PUBLIC _rf_code_over

_rf_code_over:
  pop de
  pop hl
  push hl
  jp dpush

PUBLIC _rf_code_drop

_rf_code_drop:
  pop hl
  jp (ix)

PUBLIC _rf_code_swap

_rf_code_swap:
  pop hl
  ex (sp), hl
IFDEF USEIY
  jp (iy)
ELSE
  jp hpush
ENDIF

PUBLIC _rf_code_dup

_rf_code_dup:
  pop hl
  push hl
IFDEF USEIY
  jp (iy)
ELSE
  jp hpush
ENDIF

PUBLIC _rf_code_pstor

_rf_code_pstor:
  pop hl                        ;(HL)<--VAR ADDR
  pop de                        ;(DE)<--NUMBER
  ld a, (hl)
  add a, e
  ld (hl), a
  inc hl
  ld a, (hl)
  adc a, d
  ld (hl), a                    ;((HL))<--((HL))+NUMBER
  jp (ix)

PUBLIC _rf_code_toggl

_rf_code_toggl:
  pop de                        ;(E)<--BIT PATTERN
  pop hl                        ;(HL)<--ADDR
  ld a, (hl)
  xor e
  ld (hl), a
  jp (ix)

PUBLIC _rf_code_at

_rf_code_at:
  pop hl
  ld e, (hl)
  inc hl
  ld d, (hl)
  push de
  jp (ix)

PUBLIC _rf_code_cat

_rf_code_cat:
  pop hl
  ld l, (hl)
  ld h, $00
IFDEF USEIY
  jp (iy)
ELSE
  jp hpush
ENDIF

PUBLIC _rf_code_store

_rf_code_store:
  pop hl
  pop de
  ld  (hl), e
  inc  hl
  ld  (hl), d
  jp (ix)

PUBLIC _rf_code_cstor

_rf_code_cstor:
  pop hl
  pop de
  ld (hl), e
  jp (ix)

PUBLIC _rf_code_docol

_rf_code_docol:
  ld hl, (_rf_rp)
  dec hl
  ld (hl), b
  dec hl
  ld (hl), c
  ld (_rf_rp), hl
  inc de
  ld c, e
  ld b, d
  jp (ix)

PUBLIC _rf_code_docon

_rf_code_docon:
  inc de
  ex de, hl
  ld e, (hl)
  inc hl
  ld d, (hl)
  push de
  jp (ix)

PUBLIC _rf_code_dovar

_rf_code_dovar:
  inc de
  push de
  jp (ix)

PUBLIC _rf_code_douse

_rf_code_douse:
  inc de
  ex de, hl
  ld e, (hl)
  ld d, $00
  ld hl, (_rf_up)
  add hl, de
IFDEF USEIY
  jp (iy)
ELSE
  jp hpush
ENDIF

PUBLIC _rf_code_stod

_rf_code_stod:
  pop de
  ld hl, $0000
  bit 7, d                      ;/ # NEGATIVE?
  jp z, dpush                   ;  NO
  dec hl                        ;  YES, EXTEND SIGN
stod1:
  jp dpush                      ;  ( n1--d1L d1H)

PUBLIC _rf_code_dodoe

_rf_code_dodoe:
  ld hl, (_rf_rp)
  dec hl
  ld (hl), b
  dec hl
  ld (hl), c
  ld (_rf_rp), hl
  inc de
  ex de, hl
  ld c, (hl)
  inc hl
  ld b, (hl)
  inc hl
IFDEF USEIY
  jp (iy)
ELSE
  jp hpush
ENDIF

PUBLIC _rf_code_cold

_rf_code_cold:

  ld hl, _rf_code_cold          ; COLD vector init
  ld (RF_ORIGIN+$0002), hl
  ld hl, RF_ORIGIN+$000C        ; FORTH vocabulary init
  ld de, (RF_ORIGIN+$0022)
  ldi
  ldi
  ld hl, (RF_ORIGIN+$0010)      ; UP init
  ld (_rf_up), hl
  ex de, hl                     ; USER variables init
  ld hl, RF_ORIGIN+$000C
  ld bc, $0016
  ldir
  ld bc, (RF_ORIGIN+$0024)      ; IP init to ABORT
  ld ix, next                   ; POINTER TO NEXT
IFDEF USEIY
  ld iy, hpush                  ; POINTER TO HPUSH
ENDIF
  jp _rf_code_rpsto             ; jump to RP!

PUBLIC _rf_code_cl

_rf_code_cl:
  ld hl, $0002                  ; push 2
IFDEF USEIY
  jp (iy)
ELSE
  jp hpush
ENDIF

PUBLIC _rf_code_cs

_rf_code_cs:
  pop hl                        ; push hl * 2
  add hl, hl
IFDEF USEIY
  jp (iy)
ELSE
  jp hpush
ENDIF

PUBLIC _rf_code_ln

DEFC _rf_code_ln = _rf_next

PUBLIC _rf_code_xt

_rf_code_xt:
  ld hl, $0000
  ld (_rf_fp), hl
  call _rf_start
  ret

SECTION data_user

PUBLIC _rf_fp

_rf_fp:
  defw $0000

PUBLIC _rf_ip

_rf_ip:
  defw $0000

PUBLIC _rf_rp

_rf_rp:
  defw $0000

PUBLIC _rf_sp

_rf_sp:
  defw $0000

PUBLIC _rf_up

_rf_up:
  defw $0000

PUBLIC _rf_w

_rf_w:
  defw $0000
