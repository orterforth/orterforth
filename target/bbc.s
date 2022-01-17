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

.importzp _rf_up
.importzp _rf_w
.import pop
.import _rf_next
.importzp xsave
.import push0a

osrdch := $FFE0
oswrch := $FFEE
osnewl := $FFE7
osbyte := $FFF4

.export _rf_init

_rf_init:

	lda #$6C                      ; jsr (W)
	sta _rf_w-1
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

.export _rf_out

_rf_out:

	jsr     pusha
	ldy     #$00
	lda     (sp),y
	jsr     oswrch
	jmp     incsp1

.export _rf_code_emit

_rf_code_emit:

	tya
	sec
	ldy #$1A
	adc (_rf_up),y
	sta (_rf_up),y
	iny
	lda #$00
	adc (_rf_up),y
	sta (_rf_up),y
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
	; TODO handle ESC
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

	lda #$00                      ; TODO link to ESC
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

	jsr     pusha
	jsr     decsp3
	lda #$02                      ; *FX 2,1 (read from RS423)
	ldx #$01
	jsr osbyte
	ldy     #$03
L0025:
	lda     (sp),y
	beq     L0006
	jsr	osrdch
	ldy     #$02
	sta     (sp),y
	ldy     #$05
	jsr     ldaxysp
	sta     regsave
	stx     regsave+1
	jsr     incax1
	ldy     #$04
	jsr     staxysp
	ldy     #$02
	lda     (sp),y
	ldy     #$00
	sta     (regsave),y
	ldy     #$03
	lda     (sp),y
	sec
	sbc     #$01
	sta     (sp),y
	jmp     L0025
L0006:
	lda     #$02
	tax                           ; *FX 2,2 (read from keyboard)
	jsr osbyte
	jmp     incsp6

.export _rf_disc_write

_rf_disc_write:

	jsr     pusha
	lda #$03                      ; *FX 3,7 (write to RS423)
	ldx #$07
	jsr osbyte
	ldy     #$00
L0026:
	lda     (sp),y
	beq     L0019
	ldy     #$02
	jsr     ldaxysp
	sta     regsave
	stx     regsave+1
	jsr     incax1
	ldy     #$01
	jsr     staxysp
	ldy     #$00
	lda     (regsave),y
	jsr oswrch
	ldy     #$00
	lda     (sp),y
	sec
	sbc     #$01
	sta     (sp),y
	jmp     L0026
L0019:
	lda     #$03                  ; *FX 3,4 (write to screen)
	ldx #$04
	jsr osbyte
	jmp     incsp3

.export _rf_disc_flush

_rf_disc_flush:

	rts
