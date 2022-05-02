; ZX Spectrum 48K system integration - Z80 assembly, based on ROM routines

SECTION code_user

EXTERN _rf_next                 ; NEXT, when jp (ix) not available
EXTERN _rf_up                   ; UP, for incrementing OUT
EXTERN _rf_z80_hpush            ; HPUSH, for restoring into iy

DEFINE USEIY                    ; to hold HPUSH

PUBLIC _rf_init

_rf_init:
IFDEF USEIY
  di                            ; use of IY means we need interrupts disabled
ENDIF

  ld hl, $5C6B                  ; DF-SZ
  ld (hl), $00                  ; use all 24 rows on screen

IFDEF USEIY
  push iy                       ; clear screen
  ld iy, $5C3A
ENDIF
  call $0DAF                    ; CL_ALL
IFDEF USEIY
  pop iy
ENDIF

  ld hl, $5CC3                  ; BAUD
  ld (hl), $0C                  ; $000C = 9600 ; $0005 = 19200
  inc hl
  ld (hl), $00

IFDEF USEIY
  push iy                       ; open RS-232
  ld iy, $5C3A
ENDIF

  rst $0008
  defb $34                      ; OP-B-CHAN

IFDEF USEIY
  pop iy
ENDIF

  ld hl, $5CC6                  ; IOBORD
  ld (hl), $06                  ; yellow, less disturbing than black

  ret                           ; return to C

PUBLIC _rf_code_emit

_rf_code_emit:
  pop hl                        ; get character
  ld a, $7F                     ; reset scroll
  ld ($5C8C), a                 ; SCR-CT
  and l                         ; use low 7 bits
IFDEF USEIY
  ld iy, $5C3A                  ; print character in l
ENDIF
  rst $0010                     ; PRINT_A_1
IFDEF USEIY
  ld iy, _rf_z80_hpush
ENDIF
  ld hl, (_rf_up)               ; increment OUT
  ld de, $001A
  add hl, de
; ld e, (hl)                    ; 7t
; inc hl                        ; 6t
; ld d, (hl)                    ; 7t
; inc de                        ; 6t
; ld (hl), d                    ; 7t
; dec hl                        ; 6t
; ld (hl), e                    ; 7t = 46t
  inc (hl)                      ; 11t
  jp nz, _rf_next               ; 10t
  inc hl                        ; 6t
  inc (hl)                      ; 11t = 38t max
  jp (ix)                       ; next

PUBLIC _rf_code_key

_rf_code_key:
  push bc                       ; save IP
IFDEF USEIY
  ld iy, $5C3A
ENDIF
key0:
  ld a, (key_cursor)            ; get cursor value 'L' or 'C'
  ld e, a                       ; save for later test
  call $18C1                    ; OUT_FLASH show cursor
  ld a, $08                     ; back up one
  rst $0010                     ; PRINT_A_1

	xor	a                         ; set LAST-K to 0
	ld ($5C08), a
IFDEF USEIY
  ei                            ; enable interrupts to scan keyboard
ENDIF
key1:
  halt                          ; wait for interrupt
  ld a, ($5C08)                 ; loop until LAST-K set
  and	a
  jr z, key1

  cp $06                        ; caps lock? (caps shift + 2)
  jr nz, key2
  ld a, e
  xor $0F                       ; change 'L' to 'C' or vice versa
  ld (key_cursor), a
  jr key0                       ; show changed cursor and scan again
key2:
  bit 1, e                      ; test caps lock
  jr z, key3
  cp $61                        ; 'a'
  jr c, key3
  cp $7B                        ; 'z' + 1
  jr nc, key3
  and $5F                       ; make upper case
key3:
  cp $C6                        ; AND (symbol shift + Y)
  jr nz, key4
  ld a, $5B                     ; [
key4:
  cp $C5                        ; OR (symbol shift + U)
  jr nz, key5
  ld a, $5D                     ; ]
key5:
  cp $E2                        ; STOP (symbol shift + A)
  jr nz, key6
  ld a, $7E                     ; ~
key6:
  cp $C3                        ; NOT (symbol shift + S)
  jr nz, key7
  ld a, $7C                     ; |
key7:
  cp $CD                        ; STEP (symbol shift + D)
  jr nz, key8
  ld a, $5C                     ; \
key8:
  cp $CC                        ; TO (symbol shift + F)
  jr nz, key9
  ld a, $7B                     ; {
key9:
  cp $CB                        ; THEN (symbol shift + G)
  jr nz, key10
  ld a, $7D                     ; }
key10:
  and $7F                       ; now we have the code
  ld h, $00
	ld l, a

  push hl                       ; make key click
  ld d, $00
  ld e, (iy-$01)                ; PIP
  ld hl, $00C8
  push ix
  call $03B5                    ; BEEPER
  pop ix
  pop hl

  ld a, $20                     ; blank out cursor
  rst $0010                     ; PRINT_A_1
  ld a, $08                     ; back up
  rst $0010                     ; PRINT_A_1

IFDEF USEIY
  di                            ; restore regs IP, hpush
  ld iy, _rf_z80_hpush
ENDIF
  pop bc

IFDEF USEIY
  jp (iy)                       ; hpush
ELSE
  jp _rf_z80_hpush
ENDIF

PUBLIC _rf_code_cr

_rf_code_cr:
  ld a, $0D                     ; \r
  ld ($5C8C), a                 ; reset SCR-CT
IFDEF USEIY
  ld iy, $5C3A
ENDIF
  rst $0010                     ; PRINT_A_1
IFDEF USEIY
  ld iy, _rf_z80_hpush
ENDIF
  jp (ix)                       ; next

PUBLIC _rf_code_qterm

_rf_code_qterm:
  ld hl, $0000
  call $1F54                    ; BREAK-KEY
  jp c, _rf_z80_hpush           ; hpush 0 if not pressed
  inc hl                        ; hpush 1 if pressed
IFDEF USEIY
  jp (iy)
ELSE
  jp _rf_z80_hpush
ENDIF

PUBLIC _rf_disc_read

_rf_disc_read:
  pop af
  pop bc                        ; len
  pop hl                        ; addr
  push hl
  push bc
  push af
IFDEF USEIY
  ld iy, $5C3A
ENDIF
  inc c
read0:
  dec c                         ; advance len
  ret z                         ; finished, return to C
  push bc                       ; save len
  push hl                       ; save addr
read1:
  rst $0008                     ; read a byte
  defb $1D                      ; BCHAN-IN
  jr nc, read1                  ; loop back until available
  pop hl                        ; restore addr
  ld (hl), a                    ; write byte to addr
  pop bc                        ; restore len
  inc hl                        ; advance addr
  jp read0                      ; loop back for more bytes

PUBLIC _rf_disc_write

_rf_disc_write:
  pop af
  pop bc                        ; len
  pop hl                        ; addr
  push hl
  push bc
  push af
IFDEF USEIY
  ld iy, $5C3A
ENDIF
  inc c
writ0:
  dec c                         ; advance len
  ret z                         ; finished, return to C
  push bc                       ; save len
  push hl                       ; save addr
  ld a, (hl)                    ; read a byte from addr
  rst $0008                     ; write byte
  defb $1E                      ; BCHAN-OUT
  pop hl                        ; restore addr
  pop bc                        ; restore len
  inc hl                        ; advance addr
  jp writ0                      ; loop back for more bytes

PUBLIC _rf_fin

_rf_fin:
  ld hl, $5C6B                  ; DF-SZ
  ld (hl), $02                  ; restore lower screen area for BASIC
IFDEF USEIY
  ei                            ; re-enable interrupts
ENDIF
  ret                           ; return to C

SECTION data_user

key_cursor:
  defb $4C                      ; 'L'
