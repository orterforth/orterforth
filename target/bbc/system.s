.import decsp3
.import incax1
.import incsp1
.import incsp3
.import incsp6
.import ldaxysp
.import pusha
.importzp regsave
.importzp	sp
.import staxysp

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

	lda #$6C                      ; jsr (W) ; TODO this lives in COLD?
	sta _rf_6502_w-1
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

.export _rf_disc_read

_rf_disc_read:

	jsr pusha
	jsr decsp3
	lda #$02                      ; *FX 2,1 (read from RS423)
	ldx #$01
	jsr osbyte
	ldy #$03
read1:
	lda (sp),y
	beq read2
	jsr	osrdch
	ldy #$02
	sta (sp),y
	ldy #$05
	jsr ldaxysp
	sta regsave
	stx regsave+1
	jsr incax1
	ldy #$04
	jsr staxysp
	ldy #$02
	lda (sp),y
	ldy #$00
	sta (regsave),y
	ldy #$03
	lda (sp),y
	sec
	sbc #$01
	sta (sp),y
	jmp read1
read2:
	lda #$02
	tax                           ; *FX 2,2 (read from keyboard)
	jsr osbyte
	jmp incsp6

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
	lda #$02                      ; *FX 2,2 (read from keyboard)
	tax
	jsr osbyte
	ldx xsave
	jmp _rf_next

.export _rf_disc_write

_rf_disc_write:

	jsr pusha
	lda #$03                      ; *FX 3,7 (write to RS423)
	ldx #$07
	jsr osbyte
	ldy #$00
write1:
	lda (sp),y
	beq write2
	ldy #$02
	jsr ldaxysp
	sta regsave
	stx regsave+1
	jsr incax1
	ldy #$01
	jsr staxysp
	ldy #$00
	lda (regsave),y
	jsr oswrch
	ldy #$00
	lda (sp),y
	sec
	sbc #$01
	sta (sp),y
	jmp write1
write2:
	lda #$03                      ; *FX 3,4 (write to screen)
	ldx #$04
	jsr osbyte2
	jsr incsp3
	rts

osbyte2:
	jmp osbyte                    ; workaround for unknown issue
	rts
