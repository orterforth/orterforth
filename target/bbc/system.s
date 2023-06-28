.importzp _rf_6502_n
.importzp _rf_6502_up
.importzp _rf_6502_w
.import pop
.import setup
.import _rf_next
.importzp xsave
.import push0a

osrdch := $FFE0
oswrch := $FFEE
osnewl := $FFE7
osbyte := $FFF4

.export _rf_init

_rf_init:

	lda #$07                      ; *FX 7,7 (9600 baud receive)
	tax
	jsr osbyte
	lda #$08                      ; *FX 8,7 (9600 baud transmit)
	ldx #$07
	jsr osbyte
	lda #$02                      ; *FX 2,2 (enable RS423, input from keyboard)
	tax
	jsr osbyte
	lda #$03                      ; *FX 3,4 (output to screen only)
	ldx #$04
	jsr osbyte
	rts

.export _rf_code_emit

_rf_code_emit:

	tya
	sec
	ldy #$1A
	adc (_rf_6502_up),y
	sta (_rf_6502_up),y
	iny
	lda #$00
	adc (_rf_6502_up),y
	sta (_rf_6502_up),y
	lda $00,x
	and #$7F
	stx xsave
	jsr oswrch
	ldx xsave
	jmp pop

.export _rf_code_key

_rf_code_key:

	stx xsave
	jsr osrdch
	ldx xsave
	jmp push0a

.export _rf_code_cr

_rf_code_cr:

	stx xsave
	jsr osnewl
	ldx xsave
	jmp _rf_next

.export _rf_code_qterm

_rf_code_qterm:

	stx xsave
	lda #$79                      ; *FX 121,240 (scan for escape key)
	ldx #$F0
	jsr osbyte
	lda #$00                      ; return 1 if pressed
	cpx #$00
	bpl qterm1
	lda #01
qterm1:
	ldx xsave
	jmp push0a

.export _rf_fin

_rf_fin:

	lda #$02                      ; *FX 2,0 (use keyboard, disable RS423)
	ldx #$00
	jsr osbyte
	lda #$03                      ; *FX 3,4 (output to screen only)
	ldx #$04
	jmp osbyte

.export _rf_code_dchar

_rf_code_dchar:

	stx xsave
	lda #$02                      ; *FX 2,1 (read from RS423)
	ldx #$01
	jsr osbyte
	jsr	osrdch                    ; read 1 byte and push
	pha
	lda #$02                      ; *FX 2,2 (read from keyboard)
	tax
	jsr osbyte
	ldx xsave
	ldy #$00

	dex
	dex
	sty 1,x                       ; zero high byte
	pla                           ; pull 1 byte
	sta 0,x
	cmp 2,x                       ; return true if equal
	bne dchar1
	iny
dchar1:
	sty 2,x
	jmp _rf_next

.export _rf_code_bread

_rf_code_bread:

	lda #$01                      ; fetch addr into N
	jsr setup
	stx xsave
	lda #$02                      ; *FX 2,1 (read from RS423)
	ldx #$01
	jsr osbyte
	ldy #$00                      ; read 128 bytes
bread1:
	jsr	osrdch
	sta (_rf_6502_n),y
	iny
	bpl bread1
bread2:
	lda #$02                      ; *FX 2,2 (read from keyboard)
	tax
	jsr osbyte
	ldx xsave
	jmp _rf_next

.export _rf_code_bwrit

_rf_code_bwrit:

	lda #$02
	jsr setup
	stx xsave
	lda #$03                      ; *FX 3,7 (write to RS423)
	ldx #$07
	jsr osbyte
	ldy #$00
bwrit1:
  cpy _rf_6502_n
	bne bwrit2
	lda #$04                      ; EOT
	jsr oswrch
	tax                           ; *FX 3,4 (write to screen)
	lda #$03
	jsr osbyte
	ldx xsave
	jmp _rf_next
bwrit2:
  lda (_rf_6502_n+2),y          ; write 1 byte
	jsr oswrch
	iny                           ; loop
	bne bwrit1
