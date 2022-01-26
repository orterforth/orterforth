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
; Modified for orterforth integration in 2021

SECTION code_user

EXTERN _rf_ip                           ; integrates with C based IP, RP, SP, UP, W, trampoline function pointer
EXTERN _rf_rp
EXTERN _rf_sp
EXTERN _rf_trampoline_fp
EXTERN _rf_up
EXTERN _rf_w

_rf_z80_flag:
  defb $00                              ; z when machine is using C variables, nz when it is using registers

_rf_z80_sp:
  defw $0000                            ; register SP saved here 

PUBLIC _rf_start

_rf_start:                              ; C code calls this to switch from registers to C variables

  ld a, (_rf_z80_flag)                  ; nothing to do if if flag is z
  or a
  ret z                                 ; so return to C

  pop hl                                ; get C return address

  ld iy, $5C3A                          ; restore IY and enable interrupts (Spectrum requires this)
  ei
  ld (_rf_sp), sp                       ; switch SP
  ld sp, (_rf_z80_sp)
  dec de                                ; switch W
  ld (_rf_w), de
  ld (_rf_ip), bc                       ; switch IP

  xor a                                 ; set flag to z
  ld (_rf_z80_flag), a

  jp (hl)                               ; return to C

PUBLIC _rf_trampoline

_rf_trampoline:                         ; C code calls this to iterate over a fp, assumes a switch to registers

  ld hl, (_rf_trampoline_fp)            ; returns if fp is null
  ld a, h
  or l
  ret z

  ld de, _rf_trampoline                 ; fp will return to this address
  push de

  ld bc, (_rf_ip)                       ; switch IP
  ld de, (_rf_w)                        ; switch W
  inc de
  ld (_rf_z80_sp), sp                   ; switch SP
  ld sp, (_rf_sp)
  ld ix, next                           ; set IX
  di                                    ; disable interrupts as we use IY (Spectrum requires this)
  ld iy, hpush                          ; set IY

  ld a, $01                             ; set flag to nz
  ld (_rf_z80_flag), a

  jp (hl)                               ; jump to fp, will return to start of trampoline

PUBLIC _rf_z80_hpush                    ; external libs can use this
PUBLIC _rf_next

dpush:
  push de                               ; when pushing DEHL as last action
_rf_z80_hpush:
hpush:
  push hl                               ; when pushing HL as last action
_rf_next:
next:
  ld a, (bc)                            ; W <- *IP, IP++
	ld l, a
	inc bc
	ld a, (bc)
	ld h, a
	inc bc
next1:
  ld e, (hl)
  inc hl
  ld d, (hl)
	ex de, hl                             ; DE = CFA + 1, HL = *W
  jp (hl)                               ; jump to *W

PUBLIC _rf_code_lit

_rf_code_lit:
  ld a, (bc)                            ; HL <- *IP, IP++
	inc bc
	ld l, a
	ld a, (bc)
	inc bc
	ld h, a
	jp (iy)                               ; hpush

PUBLIC _rf_code_exec

_rf_code_exec:
  pop hl                                ; jump to *CFA
  jp next1

PUBLIC _rf_code_bran

_rf_code_bran:
bran1:
  ld h, b                               ; DE <- *IP
  ld l, c
  ld e, (hl)
  inc hl
  ld d, (hl)
  dec hl
  add hl, de                            ; IP += DE
  ld c, l
  ld b, h
  jp (ix)                               ; next

PUBLIC _rf_code_zbran

_rf_code_zbran:
  pop hl                                ; if 0 then branch
  ld a, l
  or h
  jp z, bran1
  inc bc                                ; else IP++
  inc bc
  jp (ix)                               ; next

PUBLIC _rf_code_xloop

_rf_code_xloop:
  ld hl, (_rf_rp)
  inc (hl)        ;/  index(lb) += 1
  ld e, (hl)      ;/
  inc hl          ;/ (hl)-->index(hb)
  jp nz, xloop1   ;/ jump if ((hl)) < 256
  inc (hl)        ;/ else index(hb) += 1
xloop1:
  ld d, (hl)      ;/ (DE)<-- new INDEX
  inc hl          ;/ ((HL))=LIMIT
  ld a, e
  sub (hl)
  ld a, d
  inc hl
  sbc a, (hl)     ;  INDEX<LIMIT?
  jp m, bran1     ;  YES, LOOP AGAIN
  inc hl          ;  NO, DONE
  ld (_rf_rp), hl ;  DISCARD R1 & R2
  inc bc
  inc bc          ;  SKIP BRANCH OFFSET
  jp (ix)                       ; next

PUBLIC _rf_code_xploo

_rf_code_xploo:
  pop de          ;(DE)<--INCR
  ld hl, (_rf_rp) ;((HL))=INDEX
  ld a, (hl)      ;INDEX<--INDEX+INCR
  add a, e
  ld (hl), a
  ld e, a
  inc hl
  ld a, (hl)
  adc a, d
  ld (hl), a
  inc hl          ;((HL))=LIMIT
  inc d
  dec d
  ld d, a         ;(DE)<--NEW INDEX
  jp m, xloo2     ;IF INCR>0
  ld a, e
  sub (hl)        ;THEN (A)<--INDEX - LIMIT
  ld a, d
  inc hl
  sbc a, (hl)
  jp xloo3
xloo2:
  ld a, (hl)      ;ELSE (A)<--LIMIT - INDEX
  sub e
  inc hl
  ld a, (hl)
  sbc a, d
xloo3:
  jp m, bran1     ;THEN LOOP AGN
  inc hl          ;ELSE DONE
  ld (_rf_rp), hl ;DISCARD R1 & R2
  inc bc          ;SKIP BRANCH OFFSET
  inc bc
  jp (ix)                       ; next

PUBLIC _rf_code_xdo

_rf_code_xdo:
  exx                                   ; save IP
  pop de                                ; pop index and limit
  pop bc
  ld hl, (_rf_rp)                       ; push limit and index to RP
  dec hl
  ld (hl), b
  dec hl
  ld (hl), c
  dec hl
  ld (hl), d
  dec hl
  ld (hl), e
  ld (_rf_rp), hl
  exx                                   ; restore IP
  jp (ix)                               ; next

PUBLIC _rf_code_rr

_rf_code_rr:
  ld hl, (_rf_rp)                       ; DE <- RP 
  ld e, (hl)
  inc hl
  ld d, (hl)
  push de                               ; push
  jp (ix)                               ; next

PUBLIC _rf_code_digit

_rf_code_digit:
  pop hl                                ; L <- base
  pop de                                ; E <- char
  ld a, e                               ; index 48
  sub $30
  jp c, digi2                           ; if < 0, invalid char
  cp $0A                                ; if > 9, adjust for A
  jp c, digi1
  sub $07                               ; if < A, invalid char
  cp $0A
  jp c, digi2
digi1:
  cp l                                  ; if >= base, invalid char
  jp nc, digi2
  ld e, a                               ; value
  ld hl, $0001                          ; true
  jp dpush                              ; dpush (d should be 0)
digi2:
  ld l, h                               ; false (h should be 0)
  jp (iy)                               ; hpush

PUBLIC _rf_code_pfind

_rf_code_pfind:
  pop de                                ; DE <- NFA
pfin1: 
  pop hl                                ; HL <- string address
  push hl
  ld a, (de)
  xor (hl)                              ; compare lengths
  and $3F
  jp nz, pfin4
pfin2:
  inc hl                                ; same length, move to first char
  inc de
  ld a, (de)
  xor (hl)                              ; compare char
  add a, a
  jp nz, pfin3
  jp nc, pfin2                          ; match so far, not end, loop back
  ld hl, $0005                          ; found, move to PFA
  add hl, de
  ex (sp), hl
pfin6:
  dec de                                ; get length byte into DE
  ld a, (de)
  or a
  jp p, pfin6
  ld e, a
  ld d, $00
  ld hl, $0001                          ; true into HL
  jp dpush                              ; dpush
;
;ABOVE NF NOT A MATCH, TRY NEXT ONE
;
pfin3:
  jp c, pfin5  ;CARRY=END OF NF
pfin4:
  inc de       ;FIND END OF NF
  ld a, (de)
  or a         ;MSB=1?
  jp p, pfin4  ;NO, LOOP
pfin5:
  inc de       ;(DE)<--LFA
  ex de, hl
  ld e, (hl)
  inc hl
  ld d, (hl)   ;(DE)<--(LFA)
  ld a, d
  or e         ;END OF DICTIONARY? (LFA)=0
  jp nz, pfin1 ;NO, TRY PREVIOUS DEFINITION
  pop hl       ;DROP STRING ADDR
  ld hl, $0000 ;(HL)<--FALSE
  jp (iy)      ;NO MATCH FOUND, RETURN

PUBLIC _rf_code_encl

_rf_code_encl:
  pop de       ;(DE)<--(S1)=DELIMITER CHR
  pop hl       ;(HL)<--(S2)=ADDR OF TEXT TO SCAN
  push hl      ;(S4)<--ADDR
  ld a, e
  ld d, a      ;(D)<--DELIM CHR
  ld e, $FF    ;INIT CHR OFFSET COUNTER
  dec hl       ;(HL)<--ADDR-1
encl1:
  inc hl       ;SKIP OVER LEADING DELIM CHRs
  inc e
  cp (hl)      ;DELIM CHR?
  jp z, encl1  ;YES, LOOP
  ld d, $00
  push de      ;(S3)<--(E)=OFFSET TO 1st NON DELIM
  ld d, a      ;(D)<--DELIM CHR
  ld a, (hl)
  and a        ;1st non-DELIM=NULL?
  jp nz, encl2 ;NO
  ld d, $00    ;YES
  inc e
  push de      ;(S2)<--OFFSET TO BYTE FOLLOWING NULL
  dec e
  push de      ;(S1)<--OFFSET TO NULL
  jp (ix)
encl2:
  ld a, d      ;(A)<--DELIM CHR
  inc hl       ;(HL)<--ADDR NEXT CHR
  inc e        ;(E)<--OFFSET TO NEXT CHR
  cp (hl)      ;DELIM CHR?
  jp z, encl4  ;YES
  ld a, (hl)
  and a        ;NULL?
  jp nz, encl2 ;NO, CONT SCAN
encl3:
  ld d, $00
  push de      ;(S2)<--OFFSET TO NULL
  push de      ;(S1)<--OFFSET TO NULL
  jp (ix)
encl4:
  ld d, $00
  push de      ;(S2)<--OFFSET TO BYTE FOLLOWING TEXT
  inc e
  push de      ;(S1)<--OFFSET TO 2 BYTES AFTER END OF WORD
  jp (ix)

PUBLIC _rf_code_cmove

_rf_code_cmove:
  exx                           ; save IP
  pop bc                        ; size
  pop de                        ; to
  pop hl                        ; from
  ld a, b                       ; no op if size=0
  or c
  jp z, excmov
  ldir                          ; move
excmov:
  exx                           ; restore IP
  jp (ix)                       ; next

PUBLIC _rf_code_ustar

_rf_code_ustar:
  pop de                        ; DE <- multiplier
  pop hl                        ; HL <- multiplicand
  push bc                       ; save IP
  ld b, h
  ld a, l    ;(BA)<--MPCAND
  call mpyx  ;(AHL)1<--MPCAND.LB*MPLIER
             ;       1st PARTIAL PRODUCT
  push hl    ;SAVE (HL)1
  ld h, a
  ld a, b
  ld b, h    ;SAVE (A)1
  call mpyx  ;(AHL)2<--MPCAND.HB*MPLIER
             ; 2nd PARTIAL PRODUCT
  pop de     ;(DE)<--(HL)1
  ld c, d    ;(BC)<--(AH)1
; FORM SUM OF PARTIALS:
;    ; (AHL)1
;    ;+(AHL)2
;    ;-------
;    ; (AHLE)
  add hl, bc ;(HL)<--(HL)2+(AH)1
  adc a, $00 ;(AHLE)<--(BA)*(DE)
  ld d, l
  ld l, h
  ld h, a    ;(HLDE)<--MPLIER*MPCAND
  pop bc     ;RESTORE IP
  push de    ;(S2)<--PRODUCT.LW
  jp (iy)   ;(S1)<--PRODUCT.HW
;
; MULTIPLY PRIMITIVE
;   (AHL)<--(A)*(DE)
; #BITS:   24 8   16
;
mpyx:
  ld hl, $0000      ;(HL)<--0=PARTIAL PRODUCT.LW
  ld c, $08    ;LOOP COUNTER
mpyx1:
  add hl, hl   ;LEFT SHIFT (AHL) 24 BITS
  rla
  jp nc, mpyx2 ;IF NEXT MPLIER BIT = 1
  add hl, de   ;THEN ADD MPCAND
  adc a, $00
mpyx2:
  dec c        ;LAST MPLIER BIT?
  jp nz, mpyx1 ;NO, LOOP AGN
  ret			     ;YES, DONE

PUBLIC _rf_code_uslas

_rf_code_uslas:
  ld hl, $0004
  add hl, sp ;((HL))<--NUMERATOR.LW
  ld e, (hl) ;(DE)<--NUMER.LW
  ld (hl), c ;SAVE IP ON STACK
  inc hl
  ld d, (hl)
  ld (hl), b
  pop bc     ;(BC)<--DENOMINATOR
  pop hl     ;(HL)<--NUMER.HW
  ld a, l
  sub c
  ld a, h
  sbc a, b   ;NUMER >= DENOM?
  jp c, usla1 ;NO, GO AHEAD
  ld hl, $FFFF ;YES, OVERFLOW
  ld d, h
  ld e, l    ;/ SET REM & QUOT TO MAX
  jp usla7
usla1:
  ld a, $10  ;LOOP COUNTER
usla2:
  add hl, hl ;LEFT SHIFT (HLDE) THRU CARRY
  rla        ;ROT CARRY INTO ACCU BIT 0
  ex de, hl
  add hl, hl
  jp nc, usla3
  inc de     ;ADD CARRY
  and a      ;RESET CARRY
usla3:
  ex de, hl  ;SHIFT DONE
  rra        ;RESTORE 1st CARRY & COUNTER
  jp nc, usla4 ;IF CARRY=1
  or a       ;/ RESET CARRY
  sbc hl, bc ;/ THEN (HL)<--(HL)-(BC)
  jp usla5
usla4:
  sbc hl, bc ;/ (HL)<--PARTIAL REMAINDER
  jp nc, usla5
  add hl, bc ;UNDERFLOW, RESTORE
  dec de
usla5:
  inc de     ;INC QUOT
  dec a      ;COUNTER=0?
  jp nz, usla2 ;NO, LOOP AGN
usla7:
  pop bc     ;RESTORE IP
  push hl    ;(S2)<--REMAINDER
  push de    ;(S1)<--QUOTIENT
  jp (ix)

PUBLIC _rf_code_andd

_rf_code_andd:
  pop de
  pop hl
  ld a, e
  and l                         ; bitwise and low byte
  ld l, a
  ld a, d
  and h                         ; bitwise and high byte
  ld h, a
  jp (iy)                       ; hpush

PUBLIC _rf_code_orr

_rf_code_orr:
  pop de
  pop hl
  ld a, e
  or l                          ; bitwise or low byte
  ld l, a
  ld a, d
  or h                          ; bitwise or high byte
  ld h, a
  jp (iy)                       ; hpush

PUBLIC _rf_code_xorr

_rf_code_xorr:
  pop de
  pop hl
  ld a, e
  xor l                         ; bitwise xor low byte
  ld l, a
  ld a, d
  xor h                         ; bitwise xor high byte
  ld h, a
  jp (iy)                       ; hpush

PUBLIC _rf_code_spat

_rf_code_spat:
  ld hl, $0000                  ; get SP
	add hl, sp
  jp (iy)                       ; hpush

PUBLIC _rf_code_spsto

_rf_code_spsto:
  ld hl, (_rf_up)               ; get S0
  ld de, $0006
  add hl, de
  ld e, (hl)
  inc hl
  ld d, (hl)
  ex de, hl
  ld sp, hl                     ; SP <- S0
  jp (ix)                       ; next

PUBLIC _rf_code_rpsto

_rf_code_rpsto:
  ld hl, (_rf_up)               ; get R0
  ld de, $0008
  add hl, de
  ld e, (hl)
  inc hl
  ld d, (hl)
  ld (_rf_rp), de               ; write it to RP
  jp (ix)                       ; next

PUBLIC _rf_code_semis

_rf_code_semis:
  ld hl, (_rf_rp)               ; pop return address into IP (BC)
  ld c, (hl)
  inc hl
  ld b, (hl)
  inc hl
  ld (_rf_rp), hl
  jp (ix)                       ; next

PUBLIC _rf_code_leave

_rf_code_leave:
  ld hl, (_rf_rp)               ; get index from return stack
  ld e, (hl)
  inc hl
  ld d, (hl)
  inc hl
  ld (hl), e                    ; set limit to index
  inc hl
  ld (hl), d
  jp (ix)                       ; next

PUBLIC _rf_code_tor

_rf_code_tor:
  pop de                        ; pop parameter stack
  ld hl, (_rf_rp)               ; push return stack
  dec hl
  ld (hl), d  
  dec hl
  ld (hl), e
  ld (_rf_rp), hl
  jp (ix)                       ; next

PUBLIC _rf_code_fromr

_rf_code_fromr:
  ld hl, (_rf_rp)               ; pop return stack
  ld e, (hl)
  inc hl
  ld d, (hl)
  inc hl
  ld (_rf_rp), hl
  push de                       ; push parameter stack
  jp (ix)                       ; next

PUBLIC _rf_code_zequ

_rf_code_zequ:
  pop hl
  ld a, l
  or h
  ld hl, $0000
  jp nz, hpush                  ; if zero
  inc l                         ; then true
zequ1:
  jp (iy)                       ; hpush

PUBLIC _rf_code_zless

_rf_code_zless:
	pop af		                    ; get high byte into A
	rla			                      ; sign bit into carry
	ld hl, $0000
	jp nc, hpush                  ; if negative
	inc l                         ; then true
zles1:
  jp (iy)                       ; hpush

PUBLIC _rf_code_plus

_rf_code_plus:
	pop	de
	pop	hl
	add	hl, de                    ; add
  jp (iy)                       ; hpush

PUBLIC _rf_code_dplus

_rf_code_dplus:
  exx        ;/ SAVE IP
  pop bc     ;  (BC)<--d2H
  pop hl     ;  (HL)<--d2L
  pop af     ;d (AF)<--d1H
  pop de     ;  (DE)<--d1L
  push af    ;/ (S1)<--d1H
  add hl, de ;  (HL)<--d2L+d1L=d3L
  ex de, hl  ;  (DE)<--d3L
  pop hl     ;  (HL)<--d1H
  adc hl, bc ;/ (HL)<--d1H+d2H+CARRY=d3H
  push de    ;  (S2)<--d3L
  push hl    ;/ (S1)<--d3H
  exx        ;/ RESTORE IP
  jp (ix)

PUBLIC _rf_code_minus

_rf_code_minus:
  pop hl                                ; http://z80-heaven.wikidot.com/optimization#toc18 10t
  xor a                                 ; 4t
  sub l                                 ; 4t
  ld l, a                               ; 4t
  sbc a, a                              ; 4t
  sub h                                 ; 4t
  ld h, a                               ; 4t
                                        ; total 34t

  ; pop de     ;/                          ; 10t
  ; xor a      ;/ RESET CARRY, (A)<--0     ; 4t
  ; ld h, a    ;/                          ; 4t
  ; ld l, a    ;/ LD HL,0                  ; 4t
  ; sbc hl, de ;/ (HL)<--(DE)2's COMPL.    ; 15t
  ; total 37t

  jp (iy)

PUBLIC _rf_code_dminu

_rf_code_dminu:
  pop hl    ;(HL)<--d1H
  pop de    ;(DE)<--d1L
  sub a     ;(A)<--0
  sub e
  ld e, a   ;(E)<--NEG(E)
  ld a, $00
  sbc a, d
  ld d, a   ;(D)<--NEG(D)
  ld a, $00
  sbc a, l
  ld l, a   ;(L)<--NEG(L)
  ld a, $00
  sbc a, h
  ld h, a   ;(H)<--NEG(H)
  jp dpush  ;(S2)<--d2L, (S1)<--d2H

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
  jp (iy)

PUBLIC _rf_code_dup

_rf_code_dup:
  pop hl
  push hl
  jp (iy)

PUBLIC _rf_code_pstor

_rf_code_pstor:
  pop hl       ; address
  pop de       ; number to add
  ld a, (hl)   ; low byte
  add a, e
  ld (hl), a
  inc hl
  ld a, (hl)   ; high byte
  adc a, d
  ld (hl), a
  jp (ix)      ; next

PUBLIC _rf_code_toggl

_rf_code_toggl:
  pop de       ; bit pattern
  pop hl       ; address
  ld a, (hl)
  xor e        ; do xor
  ld (hl), a
  jp (ix)      ; next

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
  jp (iy)

PUBLIC _rf_code_store

_rf_code_store:
	pop	hl
	pop	de
	ld	(hl), e
	inc	hl
	ld	(hl), d
	jp (ix)

PUBLIC _rf_code_cstor

_rf_code_cstor:
  pop hl
  pop de
  ld (hl), e
  jp (ix)

PUBLIC _rf_code_docol

_rf_code_docol:
  ld hl, (_rf_rp)                       ; push IP onto return stack
  dec hl
  ld (hl), b
  dec hl
  ld (hl), c
  ld (_rf_rp), hl
  inc de                                ; set IP to PFA (W + 2)
  ld c, e
  ld b, d
  jp (ix)                               ; next

PUBLIC _rf_code_docon

_rf_code_docon:
  inc de                                ; read PFA (W + 2) and push
  ex de, hl
  ld e, (hl)
  inc hl
  ld d, (hl)
  push de
  jp (ix)

PUBLIC _rf_code_dovar

_rf_code_dovar:
  inc de                                ; push PFA (W + 2)
  push de
  jp (ix)

PUBLIC _rf_code_douse

_rf_code_douse:
  inc de                                ; read PFA
  ex de, hl
  ld e, (hl)
  ld d, $00
  ld hl, (_rf_up)                       ; add to UP
  add hl, de
  jp (iy)                               ; hpush

PUBLIC _rf_code_stod

_rf_code_stod:
  pop de                        ; get single
  ld hl, $0000
  bit 7, d                      ; if negative
  jp z, dpush
  dec hl                        ; then extend sign
stod1:
  jp dpush                      ; push double

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
  jp (iy)

PUBLIC _rf_cold_abort

_rf_cold_abort equ cold2+$0001          ; modify at inst time

PUBLIC _rf_cold_forth

_rf_cold_forth equ cold1+$0001          ; modify at inst time

PUBLIC _rf_code_cold

_rf_code_cold:

  ld hl, RF_ORIGIN+$000C                ; set FORTH vocab to ORIGIN + 6
cold1:
  ld de, $0000                          ; modify at inst time: FORTH + 2
  inc de
  inc de
  inc de
  inc de
  ldi
  ldi

  ld hl, (RF_ORIGIN+$0010)              ; set UP to ORIGIN + 8
  ld (_rf_up), hl

  ld de, $0006                          ; to S0
  add hl, de
  ex de, hl
  ld hl, RF_ORIGIN+$0012                ; from ORIGIN + 9
  ld bc, $0010                          ; copy 8 words
  ldir

cold2:
  ld bc, $0000                          ; modify at inst time: set IP to ABORT
  ld hl, (_rf_up)                       ; set RP to R0
  ld de, $0008
  add hl, de
  ld a, (hl)
  inc hl
  ld h, (hl)
  ld l, a
  ld (_rf_rp), hl

  jp (ix)                               ; next

PUBLIC _rf_code_cell

_rf_code_cell:
  ld hl, $0002                          ; hpush 2
  jp (iy)

PUBLIC _rf_code_cells

_rf_code_cells:
  pop hl                                ; hpush hl * 2
  add hl, hl
  jp (iy)
