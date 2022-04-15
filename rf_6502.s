.import _rf_rp
.import _rf_sp
.import _rf_fp

temps := $76

n := $78                        ; n-1 must be reserved for the length of n in words

.export _rf_ip: near

_rf_ip := $80

.export _rf_w: near

_rf_w := $83

.exportzp _rf_6502_w

_rf_6502_w := $83               ; also as zp for use by other asm

.export _rf_up: near

_rf_up := $85

.exportzp _rf_6502_up

_rf_6502_up := $85              ; also as zp for use by other asm

.exportzp xsave

xsave := $87

.export _rf_trampoline

_rf_trampoline:

	lda     _rf_fp                ; return if FP is null
	ora     _rf_fp+1
	bne     trampoline1
	rts
trampoline1:
	lda     #>(_rf_trampoline-1)  ; put return addr on stack
	pha
	lda     #<(_rf_trampoline-1)
	pha
	tsx                           ; save S to temp
	stx temps
	ldx _rf_rp                    ; set S to RP-1 (high byte is $01)
	dex
	txs
	ldx _rf_sp                    ; set X to SP (high byte is $00)
	ldy #$00                      ; set Y to $00, this is expected
	jmp (_rf_fp)                  ; jump to FP and return to trampoline

.export _rf_start

_rf_start:

	stx _rf_sp                    ; restore SP from X
	pla                           ; save return address (from jsr _rf_start)
	tay
	pla
	tsx                           ; restore RP from S+1
	inx
	stx _rf_rp
	ldx temps                     ; restore S from temp
	txs
	pha                           ; restore return address on stack
	tya
	pha
start1:
	rts                           ; return to C

.export _rf_code_lit

_rf_code_lit:

	lda (_rf_ip),y
	pha
	inc _rf_ip
	bne lit1
	inc _rf_ip+1
lit1:
	lda (_rf_ip),y
	inc _rf_ip
	bne push
	inc _rf_ip+1
push:
	dex
	dex
put:
	sta 1,x
	pla
	sta 0,x

.export _rf_next

_rf_next:

	ldy #$01                      ; W = (IP)
	lda (_rf_ip),y
	sta _rf_w+1
	dey
	lda (_rf_ip),y
	sta _rf_w

	clc                           ; IP++
	lda _rf_ip
	adc #$02
	sta _rf_ip
	bcc next1
	inc _rf_ip+1

next1:
	jmp _rf_w-1                   ; jump to (W)

setup:
	asl                           ; store number of bytes
	sta n-1
setup1:
	lda $00,x                     ; pop words into N
	sta n,y
	inx
	iny
	cpy n-1
	bne setup1
	ldy #$00
	rts

.export _rf_code_exec

_rf_code_exec:

	lda $00,x
	sta _rf_w
	lda $01,x
	sta _rf_w+1
	inx
	inx
	jmp _rf_w-1

.export _rf_code_bran

_rf_code_bran:

	clc
	lda (_rf_ip),y
	adc _rf_ip
	pha
	iny
	lda (_rf_ip),y
	adc _rf_ip+1
	sta _rf_ip+1
	pla
	sta _rf_ip
	jmp _rf_next+2

.export _rf_code_zbran

_rf_code_zbran:

	inx
	inx
	lda $FE,x
	ora $FF,x
	beq _rf_code_bran
bump:
	clc
	lda _rf_ip
	adc #$02
	sta _rf_ip
	bcc zbran1
	inc _rf_ip+1
zbran1:
	jmp _rf_next

.export _rf_code_xloop

_rf_code_xloop:

	stx xsave
	tsx
	inc $0101,x
	bne xloop1
	inc $0102,x
xloop1:
	clc
	lda $0103,x
	sbc $0101,x
	lda $0104,x
	sbc $0102,x
xloop2:
	ldx xsave
	asl
	bcc _rf_code_bran
	pla
	pla
	pla
	pla
	jmp bump

.export _rf_code_xploo

_rf_code_xploo:

	inx
	inx
	stx xsave
	lda $FF,x
	pha
	pha
	lda $FE,x
	tsx
	inx
	inx
	clc
	adc $0101,x
	sta $0101,x
	pla
	adc $0102,x
	sta $0102,x
	pla
	bpl xloop1
	clc
	lda $0101,x
	sbc $0103,x
	lda $0102,x
	sbc $0104,x
	jmp xloop2

.export _rf_code_xdo
.export pop

_rf_code_xdo:

	lda $03,x
	pha
	lda $02,x
	pha
	lda $01,x
	pha
	lda $00,x
	pha
poptwo:
	inx
	inx
_rf_code_drop:
pop:
	inx
	inx
	jmp _rf_next

.export _rf_code_digit

_rf_code_digit:

	sec
	lda 2,x
	sbc #$30
	bmi digit2
	cmp #$0A
	bmi digit1
	sec
	sbc #$07
	cmp #$0A
	bmi digit2
digit1:
	cmp 0,x
	bpl digit2
	sta 2,x
	lda #$01
	pha
	tya
	jmp put
digit2:
	tya
	pha
	inx
	inx
	jmp put

.export _rf_code_pfind

_rf_code_pfind:

	lda #$02
	jsr setup
	stx xsave
pfind1:
	ldy #$00
	lda (n),y
	eor (n+2),y
	and #$3F
	bne pfind4
pfind2:
	iny
	lda (n),y
	eor (n+2),y
	asl
	bne pfind3
	bcc pfind2
	ldx xsave
	dex
	dex
	dex
	dex
	clc
	tya
	adc #$05
	adc n
	sta $02,x
	ldy #$00
	tya
	adc n+1
	sta $03,x
	sty $01,x
	lda (n),y
	sta $00,x
	lda #$01
	pha
	jmp push
pfind3:
	bcs pfind5
pfind4:
	iny
	lda (n),y
	bpl pfind4
pfind5:
	iny
	lda (n),y
	tax
	iny
	lda (n),y
	sta n+1
	stx n
	ora n 
	bne pfind1
	ldx xsave
	lda #$00
	pha
	jmp push

.export _rf_code_encl

_rf_code_encl:

	lda #$02
	jsr setup
	txa
	sec
	sbc #$08
	tax
	sty 3,x
	sty 1,x
	dey
encl1:
	iny
	lda (n+2),y
	cmp n
	beq encl1
	sty 4,x
encl2:
	lda (n+2),y
	bne encl4
	sty 2,x
	sty 0,x
	tya
	cmp 4,x
	bne encl3
	inc 2,x
encl3:
	jmp _rf_next
encl4:
	sty 2,x
	iny
	cmp n
	bne encl2
	sty 0,x
	jmp _rf_next

.export _rf_code_cmove

_rf_code_cmove:

	lda #$03
	jsr setup
cmove1:
	cpy n
	bne cmove2
	dec n+1
	bpl cmove2
	jmp _rf_next
cmove2:
	lda (n+4),y
	sta (n+2),y
	iny
	bne cmove1
	inc n+5
	inc n+3
	jmp cmove1

.export _rf_code_ustar

_rf_code_ustar:

	lda $02,x
	sta n
	sty $02,x
	lda $03,x
	sta n+1
	sty $03,x
	ldy #$10
ustar1:
	asl $02,x
	rol $03,x
	rol $00,x
	rol $01,x
	bcc ustar2
	clc
	lda n
	adc $02,x
	sta $02,x
	lda n+1
	adc $03,x
	sta $03,x
	bcc ustar2
	inc $00,x
	bne ustar2
	inc $01,x
ustar2:
	dey
	bne ustar1
	jmp _rf_next

.export _rf_code_uslas

_rf_code_uslas:

	lda $04,x
	ldy $02,x
	sty $04,x
	asl
	sta $02,x
	lda $05,x
	ldy $03,x
	sty $05,x
	rol
	sta $03,x
	lda #$10
	sta n
uslas1:
	rol $04,x
	rol $05,x
	sec
	lda $04,x
	sbc $00,x
	tay
	lda $05,x
	sbc $01,x
	bcc uslas2
	sty $04,x
	sta $05,x
uslas2:
	rol $02,x
	rol $03,x
	dec n
	bne uslas1
	jmp pop

.export _rf_code_andd

_rf_code_andd:

	lda $00,x
	and $02,x
	pha
	lda $01,x
	and $03,x
binary:
	inx
	inx
	jmp put

.export _rf_code_orr

_rf_code_orr:

	lda $00,x
	ora $02,x
	pha
	lda $01,x
	ora $03,x
	inx
	inx
	jmp put

.export _rf_code_xorr

_rf_code_xorr:

	lda $00,x
	eor $02,x
	pha
	lda $01,x
	eor $03,x
	inx
	inx
	jmp put

.export _rf_code_spat
.export push0a

_rf_code_spat:

	txa
push0a:
	pha
	lda #$00
	jmp push

.export _rf_code_spsto

_rf_code_spsto:

	ldy #$06
	lda (_rf_up),y
	tax
	jmp _rf_next

.export _rf_code_rpsto

_rf_code_rpsto:

	stx xsave
	ldy #$08
	lda (_rf_up),y
	tax
	txs
	ldx xsave
	jmp _rf_next

.export _rf_code_semis

_rf_code_semis:

	pla
	sta _rf_ip
	pla
	sta _rf_ip+1
	jmp _rf_next

.export _rf_code_leave

_rf_code_leave:

	stx xsave
	tsx
	lda $0101,x
	sta $0103,x
	lda $0102,x
	sta $0104,x
	ldx xsave
	jmp _rf_next

.export _rf_code_tor

_rf_code_tor:

	lda $01,x
	pha
	lda $00,x
	pha
	inx
	inx
	jmp _rf_next

.export _rf_code_fromr

_rf_code_fromr:

	dex
	dex
	pla
	sta $00,x
	pla
	sta $01,x
	jmp _rf_next

.export _rf_code_rr

_rf_code_rr:

	stx xsave
	tsx
	lda $0101,x
	pha
	lda $0102,x
	ldx xsave
	jmp push

.export _rf_code_zequ

_rf_code_zequ:

	lda $00,x
	ora $01,x
	sty $01,x
	bne zequ1
	iny
zequ1:
	sty $00,x
	jmp _rf_next

.export _rf_code_zless

_rf_code_zless:

	asl $01,x
	tya
	rol a
	sty $01,x
	sta $00,x
	jmp _rf_next

.export _rf_code_plus

_rf_code_plus:

	clc
	lda $00,x
	adc $02,x
	sta $02,x
	lda $01,x
	adc $03,x
	sta $03,x
	inx
	inx
	jmp _rf_next

.export _rf_code_dplus

_rf_code_dplus:

	clc
	lda $02,x
	adc $06,x
	sta $06,x
	lda $03,x
	adc $07,x
	sta $07,x
	lda $00,x
	adc $04,x
	sta $04,x
	lda $01,x
	adc $05,x
	sta $05,x
	jmp poptwo

.export _rf_code_minus

_rf_code_minus:

	sec
	tya
	sbc $00,x
	sta $00,x
	tya
	sbc $01,x
	sta $01,x
	jmp _rf_next

.export _rf_code_dminu

_rf_code_dminu:

	sec
	tya
	sbc $02,x
	sta $02,x
	tya
	sbc $03,x
	sta $03,x
	jmp _rf_code_minus+1

.export _rf_code_over

_rf_code_over:

	lda $02,x
	pha
	lda $03,x
	jmp push

.export _rf_code_drop

.export _rf_code_swap

_rf_code_swap:

	lda 2,x
	pha
	lda 0,x
	sta 2,x
	lda 3,x
	ldy 1,x
	sty 3,x
	jmp put

.export _rf_code_dup

_rf_code_dup:

	lda 0,x
	pha
	lda 1,x
	jmp push

.export _rf_code_pstor

_rf_code_pstor:

	clc
	lda (0,x)
	adc 2,x
	sta (0,x)
	inc 0,x
	bne pstor1
	inc 1,x
pstor1:
	lda (0,x)
	adc 3,x
	sta (0,x)
	jmp poptwo

.export _rf_code_toggl

_rf_code_toggl:

	lda (2,x)
	eor 0,x
	sta (2,x)
	jmp poptwo

.export _rf_code_at

_rf_code_at:

	lda (0,x)
	pha
	inc 0,x
	bne at1
	inc 1,x
at1:
	lda (0,x)
	jmp put

.export _rf_code_cat

_rf_code_cat:

	lda (0,x)
	sta 0,x
	sty 1,x
	jmp _rf_next

.export _rf_code_store

_rf_code_store:

	lda 2,x
	sta (0,x)
	inc 0,x
	bne store1
	inc 1,x
store1:
	lda 3,x
	sta (0,x)
	jmp poptwo

.export _rf_code_cstor

_rf_code_cstor:

	lda 2,x
	sta (0,x)
	jmp poptwo

.export _rf_code_docol

_rf_code_docol:

	lda _rf_ip+1
	pha
	lda _rf_ip
	pha
	clc
	lda _rf_w
	adc #$02
	sta _rf_ip
	tya
	adc _rf_w+1
	sta _rf_ip+1
	jmp _rf_next

.export _rf_code_docon

_rf_code_docon:

	ldy #$02
	lda (_rf_w),y
	pha
	iny
	lda (_rf_w),y
	jmp push

.export _rf_code_dovar

_rf_code_dovar:

	clc
	lda _rf_w
	adc #$02
	pha
	tya
	adc _rf_w+1
	jmp push

.export _rf_code_douse

_rf_code_douse:

	ldy #$02
	clc
	lda (_rf_w),y
	adc _rf_up
	pha
	lda #$00
	adc _rf_up+1
	jmp push

.export _rf_code_dodoe

_rf_code_dodoe:

	lda _rf_ip+1
	pha
	lda _rf_ip
	pha
	ldy #$02
	lda (_rf_w),y
	sta _rf_ip
	iny
	lda (_rf_w),y
	sta _rf_ip+1
	clc
	lda _rf_w
	adc #$04
	pha
	lda _rf_w+1
	adc #$00
	jmp push

.export _rf_code_rcll

_rf_code_rcll:

	lda #$02
	pha
	lda #$00
	jmp push

.export _rf_code_rcls

_rf_code_rcls:

	asl $00,x
	rol $01,x
	jmp _rf_next
