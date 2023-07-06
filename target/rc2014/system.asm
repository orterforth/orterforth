SECTION code_user

EXTERN _rf_next                 ; NEXT, when jp (ix) not available
EXTERN _rf_up                   ; UP, for incrementing OUT

PUBLIC _rf_init

_rf_init:
  ret

PUBLIC _rf_code_emit

_rf_code_emit:
  pop hl                        ; get character
  ld a, $7F                     ; use low 7 bits
  and l
  cp $08
  jp nz, emit1
  rst $0008
  ld a, $20
  rst $0008
  ld a, $08
emit1:
  rst $0008
  ld hl, (_rf_up)               ; increment OUT
  ld de, $001A
  add hl, de
  inc (hl)
  jp nz, _rf_next
  inc hl
  inc (hl)
  jp (ix)

PUBLIC _rf_code_key

_rf_code_key:
  rst $0010
  and a
  jp m, _rf_code_key
  ld h, $00
  and $7F
  cp $0A
  jr nz, key1
  ld a, $0D
key1:
  ld l, a
  jp (iy)

PUBLIC _rf_code_cr

_rf_code_cr:
  ld a, $0A
  rst $0008
  jp (ix)

PUBLIC _rf_code_qterm

_rf_code_qterm:
  ld hl, $0000
  jp (iy)

discread:
  rst $0010
  and a
  jp p, discread
  and $7F
  ret

PUBLIC _rf_code_dchar

_rf_code_dchar:
  call discread                 ; read byte
  pop hl                        ; get expected byte
  cp l                          ; set flag if expected
  ld hl, $0001
  jr z, dchar2
  dec l
dchar2:
  push hl                       ; push flag
  ld l, a                       ; now push byte
  jp (iy)

PUBLIC _rf_code_bread

_rf_code_bread:
  pop hl
  push bc
  ld b, $80
bread1:
  push hl
  call discread
  pop hl
  ld (hl), a
  inc hl
  djnz bread1
  pop bc
  jp (ix)

PUBLIC _rf_code_bwrit

_rf_code_bwrit:
  pop de                        ; len
  pop hl                        ; addr
  push bc                       ; save IP
bwrit1:
  push de                       ; save len
  push hl                       ; save addr
  ld a, (hl)                    ; read a byte from addr
  or $80                        ; set bit 7
  rst $0008                     ; write byte
  pop hl                        ; restore addr
  pop de                        ; restore len
  inc hl                        ; advance addr
  dec e                         ; advance len
  jp nz, bwrit1                 ; loop back for more bytes
  ld a, $84                     ; EOT + bit 7
  rst $0008                     ; write byte
  pop bc                        ; restore IP
  jp (ix)

PUBLIC _rf_fin

_rf_fin:
  ret
